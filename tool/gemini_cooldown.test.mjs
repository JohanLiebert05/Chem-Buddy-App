import {test} from 'node:test';
import assert from 'node:assert/strict';
import {isGeminiCoolingDown,recordGeminiFailure} from '../supabase/functions/_shared/gemini_cooldown.ts';

for(const status of [403,404,429]) {
  test(`HTTP ${status} for one model cannot disable another model`,()=>{
    const cooldowns=new Map();
    recordGeminiFailure(cooldowns,'models/embedding:embedContent','fixture-key',status,1000);
    assert.equal(isGeminiCoolingDown(cooldowns,'models/embedding:embedContent','fixture-key',1001),true);
    assert.equal(isGeminiCoolingDown(cooldowns,'models/chat:generateContent','fixture-key',1001),false);
    assert.equal(isGeminiCoolingDown(cooldowns,'models/embedding:embedContent','different-key',1001),false);
  });
}
test('invalid credentials remain blocked across models until cooldown expires',()=>{
  const cooldowns=new Map();
  recordGeminiFailure(cooldowns,'embedding','fixture-key',401,1000);
  assert.equal(isGeminiCoolingDown(cooldowns,'chat','fixture-key',1001),true);
  assert.equal(isGeminiCoolingDown(cooldowns,'chat','fixture-key',301000),false);
});
test('quota cooldown expires and transient failures do not blacklist a key',()=>{
  const cooldowns=new Map();
  recordGeminiFailure(cooldowns,'chat','fixture-key',429,1000);
  assert.equal(isGeminiCoolingDown(cooldowns,'chat','fixture-key',61000),false);
  recordGeminiFailure(cooldowns,'chat','fixture-key',503,62000);
  assert.equal(isGeminiCoolingDown(cooldowns,'chat','fixture-key',62001),false);
});
