const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('supabase/functions/ask-chembuddy/index.ts','utf8');
const fn = source.match(/function getGeminiKeyPool\(\): string\[\] \{[\s\S]*?\n\}/)[0]
  .replace('(): string[]', '()').replace(/: string\[\]/g, '');
function readPool(env) {
  return Array.from(vm.runInNewContext(`const GEMINI_API_KEYS_FALLBACK=[];${fn};getGeminiKeyPool()`,
    {Deno:{env:{get:name=>env[name]}}}));
}
test('Ask ChemBuddy recognizes all six numbered credentials',()=>{
  const names=Array.from({length:6},(_,i)=>`GEMINI_KEY_${i+1}`);
  const env=Object.fromEntries(names.map(name=>[name,`fixture-${name}`]));
  assert.deepEqual(readPool(env),names.map(name=>`fixture-${name}`));
  env.GEMINI_API_KEY=env.GEMINI_KEY_5;
  assert.deepEqual(readPool(env),names.map(name=>`fixture-${name}`));
});
test('existing aliases and CSV remain supported without duplicate credentials',()=>{
  assert.deepEqual(readPool({GEMINI_API_KEYS:'fixture-first-key,fixture-second-key',
    GEMINI_API_KEY_1:'fixture-first-key',GEMINI_KEY_4:'  fixture-third-key  ',
    GEMINI_API_KEY:'fixture-second-key'}),
    ['fixture-first-key','fixture-second-key','fixture-third-key']);
});
test('spectroscopy orchestrator recognizes all six slots and deduplicates the legacy alias',()=>{
  const orchestrator=fs.readFileSync('supabase/functions/ask-gemini-orchestrator/index.ts','utf8');
  const pool=orchestrator.match(/function getAvailableGeminiKeys\(\): string\[\] \{[\s\S]*?\n\}/)[0]
    .replace('(): string[]','()').replace(/: string\[\]/g,'');
  const names=Array.from({length:6},(_,i)=>`GEMINI_KEY_${i+1}`);
  const env=Object.fromEntries(names.map(name=>[name,`fixture-${name}`]));
  env.GEMINI_API_KEY=env.GEMINI_KEY_5;
  const actual=vm.runInNewContext(`${pool};getAvailableGeminiKeys()`,{Deno:{env:{get:name=>env[name]}}});
  assert.deepEqual(Array.from(actual),names.map(name=>`fixture-${name}`));
});
