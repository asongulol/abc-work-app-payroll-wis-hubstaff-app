// Flat ESLint config. Scope:
//   - Supabase Deno edge functions (TypeScript)
//   - tools/*.mjs Node scripts (NOT the *.workflow.mjs files — those run inside
//     the Workflow harness with injected globals + top-level return, which plain
//     ESLint would mis-flag)
// The single-file in-browser-Babel apps (app/index.html, portal/index.html) are
// syntax-checked separately via `npm run lint:html` (esbuild) — ESLint can't
// sanely lint JSX embedded in HTML with all its implicit runtime globals.
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import globals from 'globals';

export default tseslint.config(
  {
    ignores: [
      '**/node_modules/**',
      'tools/.modal-width-repro.html',
      'tools/*.workflow.mjs',
      'tools/playwright/**',
    ],
  },
  // Deno edge functions
  {
    files: ['supabase/functions/**/*.ts'],
    extends: [js.configs.recommended, ...tseslint.configs.recommended],
    languageOptions: {
      globals: { ...globals.node, Deno: 'readonly' },
    },
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_', varsIgnorePattern: '^_', caughtErrorsIgnorePattern: '^_' }],
    },
  },
  // Node tool scripts (plain .mjs). These are puppeteer drivers, so they also
  // contain browser-context code inside page.evaluate() callbacks — allow both
  // Node and browser globals.
  {
    files: ['tools/**/*.mjs'],
    extends: [js.configs.recommended],
    languageOptions: {
      ecmaVersion: 2023,
      sourceType: 'module',
      globals: { ...globals.node, ...globals.browser },
    },
    rules: {
      'no-unused-vars': ['warn', { argsIgnorePattern: '^_', varsIgnorePattern: '^_', caughtErrorsIgnorePattern: '^_' }],
    },
  },
);
