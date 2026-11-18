import { config } from './config.js';
async function call(path, init) {
  if (!config.ASAAS_API_KEY) throw new Error('ASAAS_API_KEY não configurada.');
  const response = await fetch(`${config.ASAAS_BASE_URL}${path}`, { ...init, headers:{'Content-Type':'application/json','access_token':config.ASAAS_API_KEY,...init.headers} });
  const body = await response.json(); if (!response.ok) throw new Error(body.errors?.[0]?.description ?? 'Erro no Asaas'); return body;
}
export async function ensureAsaasCustomer(user) {
  return call('/customers',{method:'POST',body:JSON.stringify({name:user.name,email:user.email,cpfCnpj:user.document,mobilePhone:user.phone,externalReference:user.email})});
}
export async function createAsaasPayment(input) {
  return call('/payments',{method:'POST',body:JSON.stringify({customer:input.customer,value:input.amountCents/100,billingType:input.billingType,dueDate:input.dueDate,externalReference:input.purchaseId,description:'Créditos de metragem Alma'})});
}
