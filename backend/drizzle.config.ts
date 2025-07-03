import "dotenv/config"
import { defineConfig } from 'drizzle-kit';

const DB_URL = process.env.DB_URL!
console.log("DB_URL: ", DB_URL)
const NETWORK = process.env.NETWORK

export default defineConfig({
  out: './db/migrations',
  schema: './db/schema/index.ts',
  dialect: NETWORK == "testnet" ? 'turso' : 'sqlite',
  dbCredentials: NETWORK == "testnet" ? {
    url: DB_URL,
    authToken: process.env.DB_TOKEN
  } : {
    url: "./local-store/sqlite/sqlite.db"
  },
});