import {test} from 'node:test';
import assert from 'node:assert/strict';
import {rotateGemini} from '../supabase/functions/_shared/gemini_rotation.ts';
const state=()=>({activeIndex:0,cooldowns:new Map()});
const ok=()=>new Response(JSON.stringify({candidates:[{content:{parts:[{text:'answer'}]}}]}));

test('429 immediately advances from key 1 to 2 to 3 and retains the successful key',async()=>{
  const calls=[], pool=state();let active=0,maxActive=0;
  const send=async(_url,init)=>{active++;maxActive=Math.max(active,maxActive);const key=init.headers['x-goog-api-key'];calls.push(key);active--;return key==='key3'?ok():new Response('{}',{status:429});};
  const result=await rotateGemini(['key1','key2','key3'],'chat',{},pool,{send});
  assert.equal(result.ok,true);assert.deepEqual(calls,['key1','key2','key3']);assert.equal(maxActive,1);assert.equal(pool.activeIndex,2);
  calls.length=0;await rotateGemini(['key1','key2','key3'],'chat',{},pool,{send});assert.deepEqual(calls,['key3']);
});
test('invalid keys are skipped across models without retry sleeps',async()=>{
  const pool=state(),calls=[];
  const send=async(_url,init)=>{calls.push(init.headers['x-goog-api-key']);return calls.at(-1)==='bad'?new Response('{}',{status:401}):ok();};
  await rotateGemini(['bad','good'],'model1',{},pool,{send});pool.activeIndex=0;
  await rotateGemini(['bad','good'],'model2',{},pool,{send});assert.deepEqual(calls,['bad','good','good']);
});
test('slow request is aborted before the next key is attempted',async()=>{
  const calls=[];
  const send=async(_url,init)=>{calls.push(init.headers['x-goog-api-key']);if(calls.length===2)return ok();return new Promise((_resolve,reject)=>init.signal.addEventListener('abort',()=>reject(Error('aborted'))));};
  const result=await rotateGemini(['slow','good'],'chat',{},state(),{send,attemptTimeoutMs:5});
  assert.equal(result.ok,true);assert.deepEqual(calls,['slow','good']);
});
test('all exhausted keys yield a sanitized failure; deadline prevents extra calls',async()=>{
  const result=await rotateGemini(['a','b'],'chat',{},state(),{send:async()=>new Response('private-provider-details',{status:429})});
  assert.equal(result.ok,false);assert.equal(result.status,429);assert.ok(!JSON.stringify(result).includes('private-provider-details'));
  const timed=await rotateGemini(['a'],'chat',{},state(),{deadline:0,now:()=>100,send:async()=>{throw Error('must not call');}});assert.equal(timed.status,504);
});
