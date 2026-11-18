import { config as loadEnv } from 'dotenv';
import { z } from 'zod';
loadEnv({ path: new URL('../../../.env', import.meta.url) });
export const config = z.object({
  WEB_PORT: z.coerce.number().default(3000), WEB_DATABASE_URL: z.string().min(1),
  JWT_SECRET: z.string().min(32), PUBLIC_URL: z.string().url().default('http://localhost:3000'),
  ASAAS_BASE_URL: z.string().url().default('https://api-sandbox.asaas.com/v3'), ASAAS_API_KEY: z.string().default(''),
  ASAAS_WEBHOOK_TOKEN: z.string().default(''), PRICE_PER_METER_CENTS: z.coerce.number().int().positive().default(250),
  NODE_ENV: z.enum(['development','test','production']).default('development')
}).parse(process.env);
