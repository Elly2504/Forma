import { defineCollection, z } from 'astro:content';

// Blog/Guide collection
const guides = defineCollection({
    type: 'content',
    schema: z.object({
        title: z.string(),
        description: z.string(),
        publishDate: z.coerce.date(),
        updatedDate: z.coerce.date().optional(),
        author: z.string().default('KitTicker Team'),
        brand: z.string().optional(),
        category: z.enum(['brand', 'tutorial', 'explainer']).default('explainer'),
        image: z.string().optional(),
        tags: z.array(z.string()).default([]),
        featured: z.boolean().default(false),
        readingTime: z.number().optional(),
    }),
});

// Product Code database collection
const codes = defineCollection({
    type: 'content',
    schema: z.object({
        code: z.string(),
        brand: z.enum(['Nike', 'Adidas', 'Umbro', 'Puma', 'Kappa', 'Other']),
        team: z.string(),
        year: z.number(),
        season: z.string(),
        type: z.enum(['Home', 'Away', 'Third', 'GK', 'Training', 'Special']),
        features: z.array(z.string()).default([]),
        verified: z.boolean().default(false),
        verifiedBy: z.enum(['community', 'official', 'ai']).optional(),
        image: z.string().optional(),
        valueRange: z.object({
            low: z.number(),
            high: z.number(),
            currency: z.string().default('GBP'),
        }).optional(),
    }),
});

export const collections = {
    guides,
    codes,
};
