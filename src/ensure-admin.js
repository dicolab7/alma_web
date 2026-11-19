import argon2 from 'argon2';
import { pool } from './db.js';

const email = process.env.ADMIN_EMAIL?.trim().toLowerCase();
const password = process.env.ADMIN_PASSWORD;
const name = process.env.ADMIN_NAME?.trim() || 'Administrador';

if (!email || !password) {
  console.log('ADMIN_EMAIL ou ADMIN_PASSWORD não configurado; criação inicial do administrador ignorada.');
  await pool.end();
  process.exit(0);
}

if (password.length < 10) {
  await pool.end();
  throw new Error('ADMIN_PASSWORD deve ter pelo menos 10 caracteres.');
}

const passwordHash = await argon2.hash(password);
const { rowCount } = await pool.query(
  `INSERT INTO users(role,name,email,password_hash,accepted_terms_at,accepted_privacy_at)
   VALUES('admin',$1,$2,$3,now(),now())
   ON CONFLICT(email) DO NOTHING`,
  [name, email, passwordHash]
);

await pool.end();
console.log(rowCount ? `Administrador inicial ${email} criado.` : `Administrador ${email} já existe; senha preservada.`);
