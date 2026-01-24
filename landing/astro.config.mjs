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
  output: 'server',
  adapter: vercel(),
  trailingSlash: 'always',
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
    sitemap({
      filter: (page) => {
        // Exclude /blog/[slug] pages (they redirect to /guides/[slug])
        // Keep /blog/ index page
        const isBlogSlugPage = page.includes('/blog/') && page !== 'https://kitticker.com/blog/';
        return !isBlogSlugPage;
      }
    })
  ],
  redirects: {
    // Legacy blog URLs redirect to guides (301 permanent)
    '/blog/nike-product-codes-guide': '/guides/nike-product-codes-guide/',
    '/blog/nike-authentication-guide': '/guides/nike-authentication-guide/',
    '/blog/adidas-authentication-guide': '/guides/adidas-authentication-guide/',
    '/blog/puma-authentication-guide': '/guides/puma-authentication-guide/',
    '/blog/umbro-authentication-guide': '/guides/umbro-authentication-guide/',
    '/blog/how-to-date-umbro-shirts': '/guides/how-to-date-umbro-shirts/',
    '/blog/kit-types-explained': '/guides/kit-types-explained/',
    '/blog/marketplace-safety-guide': '/guides/marketplace-safety-guide/',
  }
});
