import { test } from 'node:test';
import assert from 'node:assert/strict';
import { keyHealth } from '../supabase/functions/gemini-key-health/handler.ts';

const env = name => ({SUPABASE_SERVICE_ROLE_KEY: 'project-service-credential',
  GEMINI_KEY_1: 'new-private-key', GEMINI_API_KEY: 'existing-private-key'}[name]);
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
  assert.deepEqual(result.results.map(r => r.status), ['generation_ok', 'generation_ok']);
  assert.ok(!JSON.stringify(result).includes('private-key'));
});
test('provider rate limits and permission errors remain distinct and sanitized', async () => {
  let calls = 0;
  const response = await keyHealth(request('project-service-credential'), env, async () =>
    new Response(JSON.stringify({error:{status: calls === 0 ? 'RESOURCE_EXHAUSTED' : 'PERMISSION_DENIED',
      message:'sensitive provider details new-private-key'}}), {status: calls++ === 0 ? 429 : 403}));
  const result = await response.json();
  assert.deepEqual(result.results.map(r => r.status), ['quota_or_rate_limited', 'authentication_or_permission_failed']);
  assert.ok(!JSON.stringify(result).includes('private-key'));
});
test('network exceptions cannot disclose credentials', async () => {
  const response = await keyHealth(request('project-service-credential'), env,
    async () => {throw Error('URL contains new-private-key');});
  const result = await response.json();
  assert.ok(result.results.every(r => r.status === 'network_or_timeout'));
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
