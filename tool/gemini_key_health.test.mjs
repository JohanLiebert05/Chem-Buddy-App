import { test } from 'node:test';
import assert from 'node:assert/strict';
import { keyHealth } from '../supabase/functions/gemini-key-health/handler.ts';

const env = name => ({SUPABASE_SERVICE_ROLE_KEY: 'project-service-credential',
  GEMINI_KEY_1: 'new-private-key', GEMINI_KEY_6: 'existing-private-key'}[name]);
const request = token => new Request('https://example.test', {
  method: 'POST', headers: {Authorization: `Bearer ${token}`},
});
test('unauthorized requests never call the provider', async () => {
  for (const token of ['', 'ordinary-user-jwt']) {
    const response = await keyHealth(request(token), env, () => {throw Error('Must not call');});
    assert.equal(response.status, 401);
  }
});
test('key checks use headers and return status without credential values', async () => {
  let calls = 0;
  const response = await keyHealth(request('project-service-credential'), env, async (url, init) => {
    assert.ok(!url.includes('private-key'));
    assert.equal(init.headers['x-goog-api-key'], calls++ === 0 ? 'new-private-key' : 'existing-private-key');
    return new Response(JSON.stringify({candidates:[{content:{parts:[{text:'OK'}]}}]}));
  });
  const result = await response.json();
  assert.equal(calls, 2);
  assert.deepEqual(result.results.filter(r => r.status !== 'not_configured').map(r => r.status), ['generation_ok', 'generation_ok']);
  assert.ok(!JSON.stringify(result).includes('private-key'));
});
test('provider rate limits and permission errors remain distinct and sanitized', async () => {
  let calls = 0;
  const response = await keyHealth(request('project-service-credential'), env, async () =>
    new Response(JSON.stringify({error:{status: calls === 0 ? 'RESOURCE_EXHAUSTED' : 'PERMISSION_DENIED',
      message:'sensitive provider details new-private-key'}}), {status: calls++ === 0 ? 429 : 403}));
  const result = await response.json();
  assert.deepEqual(result.results.filter(r => r.status !== 'not_configured').map(r => r.status), ['quota_or_rate_limited', 'authentication_or_permission_failed']);
  assert.ok(!JSON.stringify(result).includes('private-key'));
});
test('network exceptions cannot disclose credentials', async () => {
  const response = await keyHealth(request('project-service-credential'), env,
    async () => {throw Error('URL contains new-private-key');});
  const result = await response.json();
  assert.ok(result.results.filter(r => r.status !== 'not_configured').every(r => r.status === 'network_or_timeout'));
  assert.ok(!JSON.stringify(result).includes('private-key'));
});
test('modern project secret keys authorize; publishable keys do not', async () => {
  const modernEnv = name => name === 'SUPABASE_SECRET_KEYS'
    ? JSON.stringify({default:'server-only-secret'}) : env(name);
  const provider = async () => new Response(JSON.stringify({candidates:[{content:{parts:[{text:'OK'}]}}]}));
  for (const [key, expected] of [['server-only-secret', 200], ['publishable-key', 401]]) {
    const response = await keyHealth(new Request('https://example.test', {
      method:'POST', headers:{apikey:key},
    }), modernEnv, provider);
    assert.equal(response.status, expected);
  }
});
test('all six configured credentials receive an independent generation check', async () => {
  const names = Array.from({length:6},(_,i)=>`GEMINI_KEY_${i+1}`);
  const fiveEnv = name => names.includes(name) ? `private-${name}` : env(name);
  const checked = [];
  const response = await keyHealth(request('project-service-credential'), fiveEnv, async (_url, init) => {
    checked.push(init.headers['x-goog-api-key']);
    return new Response(JSON.stringify({candidates:[{content:{parts:[{text:'OK'}]}}]}));
  });
  const result = await response.json();
  assert.deepEqual(checked, names.map(n => `private-${n}`));
  assert.ok(result.results.every(r => r.status === 'generation_ok'));
  assert.ok(!JSON.stringify(result).includes('private-'));
});

test('targeted diagnostics classify provider errors without leaking their messages or metadata', async () => {
  const req = new Request('https://example.test', {method:'POST',
    headers:{Authorization:'Bearer project-service-credential'},
    body:JSON.stringify({key_names:['GEMINI_KEY_1','GEMINI_KEY_1']})});
  let calls = 0;
  const response = await keyHealth(req, env, async () => {
    calls++;
    return new Response(JSON.stringify({error:{message:'Key expired private-key SECRET_PROJECT', details:[
      {reason:'API_KEY_EXPIRED', metadata:{key:'private-key'}},
      {violations:[{quotaId:'GenerateRequestsPerDayPerProjectPerModel', quotaValue:'0',
        quotaDimensions:{project:'SECRET_PROJECT'}}]}, {retryDelay:'42.5s'}
    ]}}), {status:401});
  });
  const result = await response.json();
  assert.equal(calls, 1);
  assert.deepEqual(result.results[0].diagnostics, {credential_issue:'expired', reason:'API_KEY_EXPIRED',
    quota_scope:'daily', zero_quota:true, retry_after_seconds:42.5});
  assert.ok(!JSON.stringify(result).includes('private-key'));
  assert.ok(!JSON.stringify(result).includes('SECRET_PROJECT'));
});

test('targeted diagnostics reject arbitrary secret names before calling Google', async () => {
  const req = new Request('https://example.test', {method:'POST',
    headers:{Authorization:'Bearer project-service-credential'},
    body:JSON.stringify({key_names:['SUPABASE_SERVICE_ROLE_KEY']})});
  const response = await keyHealth(req, env, () => {throw Error('Must not call');});
  assert.equal(response.status, 400);
});
