import {test} from 'node:test';
import assert from 'node:assert/strict';

test('actual Ask ChemBuddy handler refuses unrelated questions before reading secrets or calling APIs',async()=>{
  let handler,secretReads=0,networkCalls=0;
  const previousDeno=globalThis.Deno,previousFetch=globalThis.fetch;
  globalThis.Deno={serve:fn=>{handler=fn;},env:{get:()=>{secretReads++;return undefined;}}};
  globalThis.fetch=async()=>{networkCalls++;throw Error('No API call should occur');};
  try {
    await import('../supabase/functions/ask-chembuddy/index.ts');
    for(const question of ['who won the Ballon Dor in 2026','Who won the cricket match?']) {
      const response=await handler(new Request('https://example.test',{method:'POST',body:JSON.stringify({question,mode:'general'})}));
      const body=await response.json();
      assert.equal(response.status,200);assert.equal(body.status,'out_of_scope');
      assert.equal(body.model,'local-policy');assert.ok(body.answer.includes('chemistry-related'));
    }
    assert.equal(secretReads,0);assert.equal(networkCalls,0);
  } finally {globalThis.Deno=previousDeno;globalThis.fetch=previousFetch;}
});
