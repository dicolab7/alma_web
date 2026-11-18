import { SignJWT, jwtVerify } from 'jose';
import { config } from './config.js';
const key = new TextEncoder().encode(config.JWT_SECRET);
export async function issueSession(reply, user) {
  const token = await new SignJWT(user).setProtectedHeader({alg:'HS256'}).setIssuedAt().setExpirationTime('12h').sign(key);
  reply.setCookie('alma_session', token, { httpOnly:true, sameSite:'lax', secure:config.NODE_ENV==='production', path:'/', maxAge:43200 });
}
export async function requireUser(request, reply) {
  try { const { payload } = await jwtVerify(request.cookies.alma_session ?? '', key); request.user = payload; }
  catch { return reply.code(401).send({error:'Sessão inválida ou expirada.'}); }
}
export async function requireAdmin(request, reply) {
  await requireUser(request, reply); if (reply.sent) return; if (request.user.role !== 'admin') return reply.code(403).send({error:'Acesso restrito ao administrador.'});
}
