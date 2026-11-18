import argon2 from 'argon2';
import { pool } from './db.js';
const [email, password, name = 'Administrador'] = process.argv.slice(2);
if (!email || !password || password.length < 10) throw new Error('Uso: admin:create -- email senha-com-10+-caracteres nome');
const hash = await argon2.hash(password);
await pool.query(`INSERT INTO users(role,name,email,password_hash,accepted_terms_at,accepted_privacy_at)
 VALUES('admin',$1,lower($2),$3,now(),now()) ON CONFLICT(email) DO UPDATE SET role='admin', password_hash=$3`, [name,email,hash]);
await pool.end(); console.log(`Administrador ${email} criado.`);
