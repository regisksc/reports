import { defineConfig } from 'vitest/config';
export default defineConfig({ test: {
  environment: 'happy-dom',
  coverage: { provider: 'v8', include: ['animation.js'], thresholds: {
    statements: 100, branches: 100, functions: 100, lines: 100,
  } },
} });
