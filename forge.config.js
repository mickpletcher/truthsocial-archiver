module.exports = {
  packagerConfig: {
    asar: true,
    appBundleId: 'com.mickpletcher.truthsocialarchive',
    appCategoryType: 'public.app-category.reference',
    executableName: 'TruthSocialArchive',
    win32metadata: {
      CompanyName: 'Mick Pletcher',
      FileDescription: 'Truth Social Archive',
      InternalName: 'TruthSocialArchive',
      OriginalFilename: 'TruthSocialArchive.exe',
      ProductName: 'Truth Social Archive'
    },
    ignore: [
      /^[\\/](?:\.git|\.github|config|output|out|prompts|scripts|tests)(?:[\\/]|$)/,
      /^[\\/](?:assessment|changelog|completed-upgrades|future-upgrades|README)\.md$/i,
      /^[\\/](?:forge\.config\.js|package-lock\.json)$/,
      /^[\\/]node_modules[\\/]\.package-lock\.json$/
    ]
  },
  makers: [
    {
      name: '@electron-forge/maker-squirrel',
      platforms: ['win32'],
      config: {
        name: 'TruthSocialArchive',
        authors: 'Mick Pletcher',
        description: 'Searchable desktop archive of Donald J. Trump\'s public Truth Social posts.',
        setupExe: 'TruthSocialArchiveSetup.exe'
      }
    },
    {
      name: '@electron-forge/maker-dmg',
      platforms: ['darwin'],
      config: {
        name: 'Truth Social Archive',
        format: 'ULFO'
      }
    }
  ]
};
