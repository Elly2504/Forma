// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import react from '@astrojs/react';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';
import vercel from '@astrojs/vercel';
import remarkGfm from 'remark-gfm';

// https://astro.build/config
export default defineConfig({
  site: 'https://kitticker.com',
  output: 'server', // Enable server mode for SSR API routes
  adapter: vercel(),
  vite: {
    plugins: [tailwindcss()]
  },
  markdown: {
    remarkPlugins: [remarkGfm]
  },
  integrations: [
    react(),
    mdx({
      remarkPlugins: [remarkGfm]
    }),
    sitemap()
  ]
});