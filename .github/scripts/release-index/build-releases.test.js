jest.mock("@octokit/rest", () => {
  return {
    Octokit: jest.fn().mockImplementation(() => ({
      rest: {}
    }))
  };
});

const {
  VersionManager,
  ReleaseProcessor,
  ReleaseIndexBuilder,
} = require('./build-releases');

describe('VersionManager', () => {
  let vm;

  beforeEach(() => {
    const latestPattern = /^(\d{2})\.(\d{1,2})-(\d+)$/;
    const minStableVersion = '1.0.0';
    vm = new VersionManager(latestPattern, minStableVersion);
  });

  describe('detectChannel', () => {
    it('should detect latest channel for YY.MM-patch format', () => {
      expect(vm.detectChannel('25.04-1')).toBe('latest');
      expect(vm.detectChannel('25.1-5')).toBe('latest');
      expect(vm.detectChannel('24.12-10')).toBe('latest');
    });

    it('should detect stable channel for semver format', () => {
      expect(vm.detectChannel('1.0.0')).toBe('stable');
      expect(vm.detectChannel('1.2.3')).toBe('stable');
      expect(vm.detectChannel('2.0.0-beta.1')).toBe('stable');
      expect(vm.detectChannel('0.24.7')).toBe('stable');
    });

    it('should treat invalid month as stable', () => {
      expect(vm.detectChannel('25.13-1')).toBe('stable'); // month 13
      expect(vm.detectChannel('25.0-1')).toBe('stable'); // month 0
    });

    it('should handle edge cases', () => {
      expect(vm.detectChannel('invalid')).toBe('stable');
      expect(vm.detectChannel('')).toBe('stable');
    });
  });

  describe('normalizeVersion', () => {
    it('should normalize latest channel versions', () => {
      expect(vm.normalizeVersion('25.04-1', 'latest')).toBe('25.4.1');
      expect(vm.normalizeVersion('25.1-5', 'latest')).toBe('25.1.5');
      expect(vm.normalizeVersion('24.12-10', 'latest')).toBe('24.12.10');
    });

    it('should not modify stable channel versions', () => {
      expect(vm.normalizeVersion('1.0.0', 'stable')).toBe('1.0.0');
      expect(vm.normalizeVersion('1.2.3', 'stable')).toBe('1.2.3');
      expect(vm.normalizeVersion('2.0.0-beta.1', 'stable')).toBe('2.0.0-beta.1');
    });

    it('should handle invalid latest format', () => {
      expect(vm.normalizeVersion('invalid', 'latest')).toBe('invalid');
      expect(vm.normalizeVersion('25-04-1', 'latest')).toBe('25-04-1');
    });
  });

  describe('isValidChannelVersion', () => {
    it('should validate stable versions >= 1.0.0', () => {
      expect(vm.isValidChannelVersion('1.0.0', 'stable')).toBe(true);
      expect(vm.isValidChannelVersion('1.2.3', 'stable')).toBe(true);
      expect(vm.isValidChannelVersion('2.0.0', 'stable')).toBe(true);
    });

    it('should reject stable versions < 1.0.0', () => {
      expect(vm.isValidChannelVersion('0.9.9', 'stable')).toBe(false);
      expect(vm.isValidChannelVersion('0.24.7', 'stable')).toBe(false);
      expect(vm.isValidChannelVersion('0.1.0', 'stable')).toBe(false);
    });

    it('should validate latest channel versions', () => {
      expect(vm.isValidChannelVersion('25.4.1', 'latest')).toBe(true);
      expect(vm.isValidChannelVersion('24.12.10', 'latest')).toBe(true);
    });

    it('should reject invalid semver', () => {
      expect(vm.isValidChannelVersion('invalid', 'stable')).toBe(false);
      expect(vm.isValidChannelVersion('1.2', 'stable')).toBe(false);
      expect(vm.isValidChannelVersion('', 'stable')).toBe(false);
    });
  });

  describe('compareVersions', () => {
    it('should compare versions correctly', () => {
      expect(vm.compareVersions('1.2.3', '1.2.2')).toBeGreaterThan(0);
      expect(vm.compareVersions('1.2.2', '1.2.3')).toBeLessThan(0);
      expect(vm.compareVersions('1.2.3', '1.2.3')).toBe(0);
    });
  });
});

describe('ReleaseProcessor', () => {
  let processor;
  let mockVersionManager;

  beforeEach(() => {
    mockVersionManager = {
      detectChannel: jest.fn((v) => (v.includes('-') ? 'latest' : 'stable')),
      normalizeVersion: jest.fn((v) => v),
      isValidChannelVersion: jest.fn(() => true),
      compareVersions: jest.fn((a, b) => a.localeCompare(b)),
      minStableVersion: '1.0.0',
    };

    processor = new ReleaseProcessor(mockVersionManager, '### Security Fixes:');
  });

  describe('processReleases', () => {
    it('should process valid releases', () => {
      const rawReleases = [
        {
          tag_name: '1.0.0',
          draft: false,
          prerelease: false,
          body: 'Release notes',
          published_at: '2025-01-01',
          html_url: 'https://github.com/test/test/releases/tag/1.0.0',
          created_at: '2025-01-01',
        },
        {
          tag_name: '25.04-1',
          draft: false,
          prerelease: false,
          body: 'Release notes',
          published_at: '2025-04-01',
          html_url: 'https://github.com/test/test/releases/tag/25.04-1',
          created_at: '2025-04-01',
        },
      ];

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
      const result = processor.processReleases(rawReleases);

      expect(result.releases).toHaveLength(2);
      expect(result.channels.stable).toHaveLength(1);
      expect(result.channels.latest).toHaveLength(1);
      consoleSpy.mockRestore();
    });

    it('should skip draft and prerelease', () => {
      const rawReleases = [
        { tag_name: '1.0.0', draft: true, prerelease: false },
        { tag_name: '1.0.1', draft: false, prerelease: true },
      ];

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
      const result = processor.processReleases(rawReleases);

      expect(result.releases).toHaveLength(0);
      consoleSpy.mockRestore();
    });

    it('should detect security fixes', () => {
      const rawReleases = [
        {
          tag_name: '1.0.0',
          draft: false,
          prerelease: false,
          body: '### Security Fixes:\n- Fixed vulnerability',
          published_at: '2025-01-01',
          html_url: 'https://github.com/test/test/releases/tag/1.0.0',
          created_at: '2025-01-01',
        },
      ];

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
      const result = processor.processReleases(rawReleases);

      expect(result.releases[0].hasSecurityFixes).toBe(true);
      consoleSpy.mockRestore();
    });

    it('should skip invalid versions', () => {
      mockVersionManager.isValidChannelVersion.mockReturnValue(false);

      const rawReleases = [
        {
          tag_name: '0.9.0',
          draft: false,
          prerelease: false,
          body: 'Release',
          published_at: '2025-01-01',
          html_url: 'https://github.com/test/test/releases/tag/0.9.0',
          created_at: '2025-01-01',
        },
      ];

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
      const result = processor.processReleases(rawReleases);

      expect(result.releases).toHaveLength(0);
      consoleSpy.mockRestore();
    });
  });

  describe('buildChannelData', () => {
    it('should build channel data with sorted releases', async () => {
      const releases = [
        { version: '1.0.0', normalized: '1.0.0', hasSecurityFixes: false },
        { version: '1.0.2', normalized: '1.0.2', hasSecurityFixes: true },
        { version: '1.0.1', normalized: '1.0.1', hasSecurityFixes: false },
      ];

      const mockGithubClient = {
        getAppVersionFromChart: jest.fn().mockResolvedValue('1.2.3'),
      };

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
      const result = await processor.buildChannelData(
        releases,
        'stable',
        mockGithubClient,
        10
      );

      expect(result.releases[0].version).toBe('1.0.2'); // Sorted desc
      expect(result.latestWithSecurityFixes).toBe('1.0.2');
      expect(result.latestRelease.version).toBe('1.0.2');
      consoleSpy.mockRestore();
    });

    it('should mark upgrade available correctly', async () => {
      const releases = [
        { version: '1.0.2', normalized: '1.0.2', hasSecurityFixes: false },
        { version: '1.0.1', normalized: '1.0.1', hasSecurityFixes: false },
      ];

      const mockGithubClient = {
        getAppVersionFromChart: jest.fn().mockResolvedValue('1.2.3'),
      };

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
      const result = await processor.buildChannelData(
        releases,
        'stable',
        mockGithubClient,
        10
      );

      expect(result.releases[0].upgradeAvailable).toBe(false); // Latest
      expect(result.releases[1].upgradeAvailable).toBe(true); // Not latest
      consoleSpy.mockRestore();
    });

    it('should mark security vulnerabilities correctly', async () => {
      const releases = [
        { version: '1.0.3', normalized: '1.0.3', hasSecurityFixes: false },
        { version: '1.0.2', normalized: '1.0.2', hasSecurityFixes: true },
        { version: '1.0.1', normalized: '1.0.1', hasSecurityFixes: false },
      ];

      const mockGithubClient = {
        getAppVersionFromChart: jest.fn().mockResolvedValue('1.2.3'),
      };

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
      const result = await processor.buildChannelData(
        releases,
        'stable',
        mockGithubClient,
        10
      );

      expect(result.releases[0].hasSecurityVulnerabilities).toBe(false);
      expect(result.releases[1].hasSecurityVulnerabilities).toBe(false);
      expect(result.releases[2].hasSecurityVulnerabilities).toBe(true);
      consoleSpy.mockRestore();
    });

    it('should limit releases to maxReleases', async () => {
      const releases = Array(20)
        .fill(0)
        .map((_, i) => ({
          version: `1.0.${i}`,
          normalized: `1.0.${i}`,
          hasSecurityFixes: false,
        }));

      const mockGithubClient = {
        getAppVersionFromChart: jest.fn().mockResolvedValue('1.2.3'),
      };

      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
      const result = await processor.buildChannelData(
        releases,
        'stable',
        mockGithubClient,
        5
      );

      expect(result.releases).toHaveLength(5);
      consoleSpy.mockRestore();
    });
  });
});

describe('ReleaseIndexBuilder', () => {
  let builder;
  let mockConfig;
  let mockGithubClient;
  let mockReleaseProcessor;
  let mockVersionManager;

  beforeEach(() => {
    mockConfig = {
      owner: 'test-owner',
      repo: 'test-repo',
      maxGithubReleases: 1000,
      maxReleasesPerChannel: 10,
    };

    mockGithubClient = {
      fetchReleases: jest.fn(),
    };

    mockReleaseProcessor = {
      processReleases: jest.fn(),
      buildChannelData: jest.fn(),
    };

    mockVersionManager = {};

    builder = new ReleaseIndexBuilder(
      mockConfig,
      mockGithubClient,
      mockReleaseProcessor,
      mockVersionManager
    );
  });

  describe('buildIndexObject', () => {
    it('should build correct index structure', () => {
      const releases = [
        { version: '1.0.0' },
        { version: '25.04-1' },
      ];

      const stable = {
        releases: [{ version: '1.0.0' }],
        latestRelease: { version: '1.0.0' },
        latestWithSecurityFixes: null,
      };

      const latest = {
        releases: [{ version: '25.04-1' }],
        latestRelease: { version: '25.04-1' },
        latestWithSecurityFixes: null,
      };

      const index = builder.buildIndexObject(releases, stable, latest);

      expect(index).toHaveProperty('generatedAt');
      expect(index.repository).toBe('test-owner/test-repo');
      expect(index.channels.stable).toEqual(stable);
      expect(index.channels.latest).toEqual(latest);
      expect(index.stats.totalReleases).toBe(2);
    });
  });
});

