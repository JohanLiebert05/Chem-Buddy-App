import {test} from 'node:test';
import assert from 'node:assert/strict';
import {isChemistryQuestion,chemistryRefusal,aiUnavailableNotice} from '../supabase/functions/_shared/chemistry_scope.ts';

test('chemistry questions, named rules, formulas and grounded study requests remain allowed',()=>{
  for(const q of ['Explain SN1 versus SN2','Predict NMR for ethyl acetate','What is ethyl acetate?','Calculate normality','Calculate moles of H2SO4','Explain Markovnikov rule','What is entropy?','Calculate DBE for C8H8O','Compare aspirin and paracetamol']) assert.equal(isChemistryQuestion(q),true,q);
  assert.equal(isChemistryQuestion('Summarize this PDF',[], 'Aldol reactions and organic synthesis'),true);
  assert.equal(isChemistryQuestion('Why?', [{role:'user',content:'Explain ester hydrolysis'}]),true);
  assert.equal(isChemistryQuestion('Why?', [{role:'user',content:'Explain ester hydrolysis'},{role:'user',content:'Why?'}]),true);
});
test('sports and other unrelated questions are refused even in a chemistry conversation or wrapper',()=>{
  for(const q of ['who won the Ballon Dor in 2026','Who won the cricket match?','Write Python code for a website','Tell me a movie story','[Format as a 5-Mark MSc Chemistry Answer]: who won the Ballon Dor in 2026']) assert.equal(isChemistryQuestion(q,[{role:'user',content:'Explain ester hydrolysis'}],'chemistry notes'),false,q);
  assert.equal(isChemistryQuestion('What is happiness?'),false);
});
test('refusals and exhaustion responses are explicit local notices, never offline or model answers',()=>{
  assert.equal(chemistryRefusal().model,'local-policy');
  const notice=aiUnavailableNotice();
  assert.equal(notice.status,'unavailable');assert.equal(notice.model,'unavailable');
  assert.ok(!notice.answer.includes('Offline Mode'));
  assert.equal(aiUnavailableNotice(true).reason,'account_limit');
});
