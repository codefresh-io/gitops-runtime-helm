const { Octokit } = require("@octokit/rest");
const semver = require("semver");
const fs = require("fs");
const path = require("path");
const { load } = require("js-yaml");

const OWNER = "codefresh-io";
const REPO = "gitops-runtime-helm";
const LATEST_PATTERN = /^(\d{2})\.(\d{1,2})-(\d+)$/; // Format: YY.MM-patch (e.g., 25.04-1)
const MIN_STABLE_VERSION = "1.0.0";
const TOKEN = process.env.GITHUB_TOKEN;
const SECURITY_FIXES_STRING =
  process.env.SECURITY_FIXES_STRING || "### Security Fixes:";
const MAX_RELEASES_PER_CHANNEL = 10;
const MAX_GITHUB_RELEASES = 1000;
const CHART_PATH = "charts/gitops-runtime/Chart.yaml";
const DEFAULT_APP_VERSION = "0.0.0";

if (!TOKEN) {
  console.error("❌ GITHUB_TOKEN environment variable is required");
  process.exit(1);
}

const octokit = new Octokit({ auth: TOKEN });

/**
 * Detect channel based on version format
 * - Latest: YY.MM-patch format (e.g., 25.04-1)
 * - Stable: Semver format starting from 1.0.0 (e.g., 1.2.3)
 */
function detectChannel(version) {
  const match = version.match(LATEST_PATTERN);
  if (match) {
    const month = Number(match[2]);
    if (month >= 1 && month <= 12) {
      return "latest";
    }
  }
  
  return "stable";
}

function isValidChannelVersion(normalized, channel) {
  if (!semver.valid(normalized)) {
    return false;
  }
  
  if (channel === "stable") {
    return semver.gte(normalized, MIN_STABLE_VERSION);
  }
  
  return true;
}

/**
 * Normalize version for semver validation
 * - Latest channel: 25.01-1 → 25.1.1
 * - Stable channel: 1.2.3 → 1.2.3 (no change)
 */
function normalizeVersion(version, channel) {
  if (channel === "latest") {
    const match = version.match(LATEST_PATTERN);
    if (match) {
      const year = match[1];
      const month = Number(match[2]);
      const patch = match[3];
      return `${year}.${month}.${patch}`;
    }
  }
  return version;
}

function compareVersions(normA, normB) {
  try {
    return semver.compare(normA, normB);
  } catch (error) {
    console.warn(`Failed to compare versions:`, error.message);
    return 0;
  }
}

async function getAppVersionFromChart(tag) {
  try {
    const { data } = await octokit.repos.getContent({
      owner: OWNER,
      repo: REPO,
      path: CHART_PATH,
      ref: tag,
      mediaType: {
        format: "raw",
      },
    });

    const chart = load(data);
    return chart.appVersion || DEFAULT_APP_VERSION;
  } catch (error) {
    console.warn(`  ⚠️  Failed to get appVersion for ${tag}:`, error.message);
    return DEFAULT_APP_VERSION;
  }
}

async function fetchReleases() {
  console.log("📦 Fetching releases from GitHub using Octokit...");

  const allReleases = [];
  let page = 0;

  try {
    for await (const response of octokit.paginate.iterator(
      octokit.rest.repos.listReleases,
      {
        owner: OWNER,
        repo: REPO,
        per_page: 100,
      }
    )) {
      page++;
      const releases = response.data;

      allReleases.push(...releases);
      console.log(`  Fetched page ${page} (${releases.length} releases)`);

      if (allReleases.length >= MAX_GITHUB_RELEASES) {
        console.log(
          `  Reached ${MAX_GITHUB_RELEASES} releases limit, stopping...`
        );
        break;
      }
    }
  } catch (error) {
    console.error("Error fetching releases:", error.message);
    throw error;
  }

  console.log(`✅ Fetched ${allReleases.length} total releases`);
  return allReleases;
}

function processReleases(rawReleases) {
  console.log("\n🔍 Processing releases...");

  const releases = [];
  const channels = { stable: [], latest: [] };

  let skipped = 0;

  for (const release of rawReleases) {
    if (release.draft || release.prerelease) {
      skipped++;
      console.log(`  ⚠️  Skipping draft or prerelease: ${release.tag_name}`);
      continue;
    }

    const version = release.tag_name || release.name;
    if (!version) {
      skipped++;
      console.log(
        `  ⚠️  Skipping release without version: ${release.tag_name}`
      );
      continue;
    }

    const channel = detectChannel(version);
    const normalized = normalizeVersion(version, channel);

    if (!isValidChannelVersion(normalized, channel)) {
      const reason =
        channel === "stable"
          ? `not valid semver >= ${MIN_STABLE_VERSION}`
          : "not valid semver";
      console.log(`  ⚠️  Skipping invalid ${channel} version: ${version} (${reason})`);
      skipped++;
      continue;
    }

    const hasSecurityFixes =
      release.body?.includes(SECURITY_FIXES_STRING) || false;

    const releaseData = {
      version,
      normalized,
      channel,
      hasSecurityFixes,
      publishedAt: release.published_at,
      url: release.html_url,
      createdAt: release.created_at,
    };

    releases.push(releaseData);
    channels[channel].push(releaseData);
  }

  console.log(
    `✅ Processed ${releases.length} valid releases (skipped ${skipped})`
  );
  console.log(`   Stable: ${channels.stable.length}`);
  console.log(`   Latest: ${channels.latest.length}`);

  return { releases, channels };
}

async function buildChannelData(channelReleases, channelName) {
  const sorted = channelReleases.sort((a, b) => {
    return compareVersions(b.normalized, a.normalized);
  });

  const latestWithSecurityFixes =
    sorted.find((r) => r.hasSecurityFixes)?.version || null;
  const topReleases = sorted.slice(0, MAX_RELEASES_PER_CHANNEL);

  console.log(
    `  Fetching appVersion for ${topReleases.length} ${channelName} releases...`
  );
  for (const release of topReleases) {
    release.appVersion = await getAppVersionFromChart(release.version);
  }

  const latestRelease = sorted[0] || null;
  const latestVersion = latestRelease?.version;
  const latestSecureIndex = latestWithSecurityFixes
    ? sorted.findIndex((r) => r.version === latestWithSecurityFixes)
    : -1;

  topReleases.forEach((release, index) => {
    release.upgradeAvailable = release.version !== latestVersion;
    release.hasSecurityVulnerabilities =
      latestSecureIndex >= 0 && index > latestSecureIndex;
  });

  return {
    releases: topReleases,
    latestWithSecurityFixes,
    latestRelease,
  };
}

async function buildIndex() {
  console.log("🚀 Building release index...\n");
  console.log(`📍 Repository: ${OWNER}/${REPO}\n`);

  try {
    const rawReleases = await fetchReleases();

    const { releases, channels } = processReleases(rawReleases);

    console.log("\n📊 Building channel data...");
    const stable = await buildChannelData(channels.stable, "stable");
    const latest = await buildChannelData(channels.latest, "latest");

    console.log(`   Stable latest: ${stable.latest || "none"}`);
    console.log(`   Latest latest: ${latest.latest || "none"}`);
    if (stable.latestWithSecurityFixes) {
      console.log(`   🔒 Stable security: ${stable.latestWithSecurityFixes}`);
    }
    if (latest.latestWithSecurityFixes) {
      console.log(`   🔒 Latest security: ${latest.latestWithSecurityFixes}`);
    }

    const index = {
      generatedAt: new Date().toISOString(),
      repository: `${OWNER}/${REPO}`,
      channels: {
        stable: {
          releases: stable.releases,
          latestRelease: stable.latestRelease,
          latestWithSecurityFixes: stable.latestWithSecurityFixes,
        },
        latest: {
          releases: latest.releases,
          latestRelease: latest.latestRelease,
          latestWithSecurityFixes: latest.latestWithSecurityFixes,
        },
      },
      stats: {
        totalReleases: releases.length,
        stableSecure: stable.latestWithSecurityFixes || null,
        latestSecure: latest.latestWithSecurityFixes || null,
      },
    };

    console.log("\n💾 Writing index file...");
    const outDir = path.join(process.cwd(), "releases");
    if (!fs.existsSync(outDir)) {
      fs.mkdirSync(outDir, { recursive: true });
    }

    const outputPath = path.join(outDir, "releases.json");
    fs.writeFileSync(outputPath, JSON.stringify(index, null, 2));

    console.log("\n✅ Release index built successfully!");
    console.log("\n📋 Summary:");
    console.log(`   Total releases: ${index.stats.totalReleases}`);
    console.log(`\n   🟢 Stable Channel:`);
    console.log(
      `      Latest chart: ${index.channels.stable.latestRelease?.version || "none"}`
    );
    console.log(
      `      Latest app: ${
        index.channels.stable.latestRelease?.appVersion || "none"
      }`
    );
    console.log(
      `      Latest secure: ${
        index.channels.stable.latestWithSecurityFixes || "none"
      }`
    );
    console.log(`\n   🔵 Latest Channel:`);
    console.log(
      `      Latest chart: ${index.channels.latest.latestRelease?.version || "none"}`
    );
    console.log(
      `      Latest app: ${
        index.channels.latest.latestRelease?.appVersion || "none"
      }`
    );
    console.log(
      `      Latest secure: ${
        index.channels.latest.latestWithSecurityFixes || "none"
      }`
    );
    console.log(`\n📁 Files created:`);
    console.log(`   ${outputPath}`);
  } catch (error) {
    console.error("\n❌ Error building index:", error.message);
    if (error.status) {
      console.error(`   GitHub API Status: ${error.status}`);
    }
    console.error(error.stack);
    process.exit(1);
  }
}

buildIndex();
