const { Octokit } = require("@octokit/rest");
const semver = require("semver");
const fs = require("fs");
const path = require("path");
const { load } = require("js-yaml");


const CONFIG = {
  owner: "codefresh-io",
  repo: "gitops-runtime-helm",
  latestPattern: /^(\d{2})\.(\d{1,2})-(\d+)$/, // Format: YY.MM-patch (e.g., 25.04-1)
  minStableVersion: "1.0.0", // Stable versions start from 1.0.0
  securityFixesString: process.env.SECURITY_FIXES_STRING || "### Security Fixes:",
  maxReleasesPerChannel: 10,
  maxGithubReleases: 1000,
  chartPath: "charts/gitops-runtime/Chart.yaml",
  defaultAppVersion: "0.0.0",
};

class VersionManager {
  constructor(latestPattern, minStableVersion) {
    this.latestPattern = latestPattern;
    this.minStableVersion = minStableVersion;
  }

  /**
   * Detect channel based on version format
   * - Latest: YY.MM-patch format (e.g., 25.04-1)
   * - Stable: Semver format starting from 1.0.0 (e.g., 1.2.3)
   */
  detectChannel(version) {
    const match = version.match(this.latestPattern);
    if (match) {
      const month = Number(match[2]);
      // Validate month is 1-12
      if (month >= 1 && month <= 12) {
        return "latest";
      }
    }
    return "stable";
  }

  /**
   * Normalize version for semver validation
   * - Latest channel: 25.01-1 → 25.1.1
   * - Stable channel: 1.2.3 → 1.2.3 (no change)
   */
  normalizeVersion(version, channel) {
    if (channel === "latest") {
      const match = version.match(this.latestPattern);
      if (match) {
        const year = match[1];
        const month = Number(match[2]);
        const patch = match[3];
        return `${year}.${month}.${patch}`;
      }
    }
    // Stable versions are already in semver format
    return version;
  }

  isValidChannelVersion(normalized, channel) {
    if (!semver.valid(normalized)) {
      return false;
    }

    if (channel === "stable") {
      return semver.gte(normalized, this.minStableVersion);
    }

    return true;
  }

  compareVersions(normA, normB) {
    try {
      return semver.compare(normA, normB);
    } catch (error) {
      console.warn(`Failed to compare versions:`, error.message);
      return 0;
    }
  }
}

class GitHubReleaseClient {
  constructor(octokit, owner, repo, chartPath, defaultAppVersion) {
    this.octokit = octokit;
    this.owner = owner;
    this.repo = repo;
    this.chartPath = chartPath;
    this.defaultAppVersion = defaultAppVersion;
  }

  async fetchReleases(maxReleases) {
    console.log("📦 Fetching releases from GitHub using Octokit...");

    const allReleases = [];
    let page = 0;

    try {
      for await (const response of this.octokit.paginate.iterator(
        this.octokit.rest.repos.listReleases,
        {
          owner: this.owner,
          repo: this.repo,
          per_page: 100,
        }
      )) {
        page++;
        const releases = response.data;

        allReleases.push(...releases);
        console.log(`  Fetched page ${page} (${releases.length} releases)`);

        if (allReleases.length >= maxReleases) {
          console.log(`  Reached ${maxReleases} releases limit, stopping...`);
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

  /**
   * Get appVersion from Chart.yaml for a specific tag
   */
  async getAppVersionFromChart(tag) {
    try {
      const { data } = await this.octokit.repos.getContent({
        owner: this.owner,
        repo: this.repo,
        path: this.chartPath,
        ref: tag,
        mediaType: {
          format: "raw",
        },
      });

      const chart = load(data);
      return chart.appVersion || this.defaultAppVersion;
    } catch (error) {
      console.warn(`  ⚠️  Failed to get appVersion for ${tag}:`, error.message);
      return this.defaultAppVersion;
    }
  }
}
class ReleaseProcessor {
  constructor(versionManager, securityFixesString) {
    this.versionManager = versionManager;
    this.securityFixesString = securityFixesString;
  }

  processReleases(rawReleases) {
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
        console.log(`  ⚠️  Skipping release without version: ${release.tag_name}`);
        continue;
      }

      const channel = this.versionManager.detectChannel(version);
      const normalized = this.versionManager.normalizeVersion(version, channel);

      if (!this.versionManager.isValidChannelVersion(normalized, channel)) {
        const reason = channel === "stable"
          ? `not valid semver >= ${this.versionManager.minStableVersion}`
          : "not valid semver";
        console.log(`  ⚠️  Skipping invalid ${channel} version: ${version} (${reason})`);
        skipped++;
        continue;
      }

      const hasSecurityFixes = release.body?.includes(this.securityFixesString) || false;

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

    console.log(`✅ Processed ${releases.length} valid releases (skipped ${skipped})`);
    console.log(`   Stable: ${channels.stable.length}`);
    console.log(`   Latest: ${channels.latest.length}`);

    return { releases, channels };
  }

  async buildChannelData(channelReleases, channelName, githubClient, maxReleases) {
    const sorted = channelReleases.sort((a, b) => {
      return this.versionManager.compareVersions(b.normalized, a.normalized);
    });

    const latestWithSecurityFixes = sorted.find((r) => r.hasSecurityFixes)?.version || null;
    
    const topReleases = sorted.slice(0, maxReleases);

    console.log(`  Fetching appVersion for ${topReleases.length} ${channelName} releases...`);
    for (const release of topReleases) {
      release.appVersion = await githubClient.getAppVersionFromChart(release.version);
    }

    // Mark upgrade availability and security vulnerabilities
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
}

class ReleaseIndexBuilder {
  constructor(config, githubClient, releaseProcessor, versionManager) {
    this.config = config;
    this.githubClient = githubClient;
    this.releaseProcessor = releaseProcessor;
    this.versionManager = versionManager;
  }

  async build() {
    console.log("🚀 Building release index...\n");
    console.log(`📍 Repository: ${this.config.owner}/${this.config.repo}\n`);

    try {
      const rawReleases = await this.githubClient.fetchReleases(this.config.maxGithubReleases);

      const { releases, channels } = this.releaseProcessor.processReleases(rawReleases);

      console.log("\n📊 Building channel data...");
      const stable = await this.releaseProcessor.buildChannelData(
        channels.stable,
        "stable",
        this.githubClient,
        this.config.maxReleasesPerChannel
      );
      const latest = await this.releaseProcessor.buildChannelData(
        channels.latest,
        "latest",
        this.githubClient,
        this.config.maxReleasesPerChannel
      );

      this.logChannelSummary(stable, latest);

      const index = this.buildIndexObject(releases, stable, latest);

      this.writeIndexFile(index);

      this.logFinalSummary(index);

      return index;
    } catch (error) {
      console.error("\n❌ Error building index:", error.message);
      if (error.status) {
        console.error(`   GitHub API Status: ${error.status}`);
      }
      console.error(error.stack);
      throw error;
    }
  }

  buildIndexObject(releases, stable, latest) {
    return {
      generatedAt: new Date().toISOString(),
      repository: `${this.config.owner}/${this.config.repo}`,
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
  }

  writeIndexFile(index) {
    console.log("\n💾 Writing index file...");
    const outDir = path.join(process.cwd(), "releases");
    if (!fs.existsSync(outDir)) {
      fs.mkdirSync(outDir, { recursive: true });
    }

    const outputPath = path.join(outDir, "releases.json");
    fs.writeFileSync(outputPath, JSON.stringify(index, null, 2));
    console.log(`   ${outputPath}`);
  }

  logChannelSummary(stable, latest) {
    console.log(`   Stable latest: ${stable.latestRelease?.version || "none"}`);
    console.log(`   Latest latest: ${latest.latestRelease?.version || "none"}`);
    if (stable.latestWithSecurityFixes) {
      console.log(`   🔒 Stable security: ${stable.latestWithSecurityFixes}`);
    }
    if (latest.latestWithSecurityFixes) {
      console.log(`   🔒 Latest security: ${latest.latestWithSecurityFixes}`);
    }
  }


  logFinalSummary(index) {
    console.log("\n✅ Release index built successfully!");
    console.log("\n📋 Summary:");
    console.log(`   Total releases: ${index.stats.totalReleases}`);
    
    console.log(`\n   🟢 Stable Channel:`);
    console.log(`      Latest chart: ${index.channels.stable.latestRelease?.version || "none"}`);
    console.log(`      Latest app: ${index.channels.stable.latestRelease?.appVersion || "none"}`);
    console.log(`      Latest secure: ${index.channels.stable.latestWithSecurityFixes || "none"}`);
    
    console.log(`\n   🔵 Latest Channel:`);
    console.log(`      Latest chart: ${index.channels.latest.latestRelease?.version || "none"}`);
    console.log(`      Latest app: ${index.channels.latest.latestRelease?.appVersion || "none"}`);
    console.log(`      Latest secure: ${index.channels.latest.latestWithSecurityFixes || "none"}`);
  }
}

async function main() {
  // Validate token
  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    console.error("❌ GITHUB_TOKEN environment variable is required");
    process.exit(1);
  }

  // Initialize dependencies
  const octokit = new Octokit({ auth: token });
  const versionManager = new VersionManager(CONFIG.latestPattern, CONFIG.minStableVersion);
  const githubClient = new GitHubReleaseClient(
    octokit,
    CONFIG.owner,
    CONFIG.repo,
    CONFIG.chartPath,
    CONFIG.defaultAppVersion
  );
  const releaseProcessor = new ReleaseProcessor(versionManager, CONFIG.securityFixesString);
  const builder = new ReleaseIndexBuilder(CONFIG, githubClient, releaseProcessor, versionManager);

  // Build index
  try {
    await builder.build();
  } catch (error) {
    process.exit(1);
  }
}

// Export for testing
module.exports = {
  VersionManager,
  GitHubReleaseClient,
  ReleaseProcessor,
  ReleaseIndexBuilder,
  CONFIG,
};

if (require.main === module) {
  main();
}
