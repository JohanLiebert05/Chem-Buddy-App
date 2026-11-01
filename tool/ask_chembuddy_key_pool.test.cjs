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
test('Ask ChemBuddy recognizes all five saved credential names',()=>{
  const names=['GEMINI_KEY_1','GEMINI_KEY_2','GEMINI_KEY_3','GEMINI_KEY_4','GEMINI_API_KEY'];
  const env=Object.fromEntries(names.map(name=>[name,`fixture-${name}`]));
  assert.deepEqual(readPool(env),names.map(name=>`fixture-${name}`));
});
test('existing aliases and CSV remain supported without duplicate credentials',()=>{
  assert.deepEqual(readPool({GEMINI_API_KEYS:'fixture-first-key,fixture-second-key',
    GEMINI_API_KEY_1:'fixture-first-key',GEMINI_KEY_4:'  fixture-third-key  ',
    GEMINI_API_KEY:'fixture-second-key'}),
    ['fixture-first-key','fixture-second-key','fixture-third-key']);
});
