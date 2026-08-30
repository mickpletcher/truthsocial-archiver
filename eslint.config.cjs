const js = require('@eslint/js');
const globals = require('globals');

module.exports = [
  {
    ignores: [
      'docs/data/**',
      'node_modules/**',
      'out/**',
      'output/**'
    ]
  },
  js.configs.recommended,
  {
    files: [
      'desktop/**/*.js',
      'forge.config.js',
      'scripts/**/*.mjs',
      'tests/**/*.js'
    ],
    languageOptions: {
      ecmaVersion: 'latest',
      globals: globals.node
    },
    rules: {
      eqeqeq: 'error',
      'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'no-var': 'error',
      'prefer-const': 'error'
    }
  },
  {
    files: ['docs/**/*.js'],
    languageOptions: {
      ecmaVersion: 'latest',
      globals: globals.browser,
      sourceType: 'script'
    },
    rules: {
      eqeqeq: 'error',
      'no-var': 'error',
      'prefer-const': 'error'
    }
  },
  {
    files: ['scripts/test-electron.mjs'],
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node
      }
    }
  }
];
