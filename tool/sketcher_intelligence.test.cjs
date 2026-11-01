const test = require('node:test');
const assert = require('node:assert/strict');
const {analyze} = require('../assets/web/sketcher_intelligence.js');
const atom = (id, element, charge = 0) => ({id, element, charge, x:id*55, y:0});
const bond = (a,b,order=1) => ({atom1:a,atom2:b,order});
test('ethanol inventory and mass are computed from connectivity', () => {
  const result = analyze({atoms:[atom(1,'C'),atom(2,'C'),atom(3,'O')],bonds:[bond(1,2),bond(2,3)]});
  assert.equal(result.formula,'C2H6O'); assert.equal(result.dbe,0); assert.equal(result.fragments,1);
  assert.ok(Math.abs(result.molarMass-46.069)<.001);
});
test('carbonyl oxygen does not acquire a false hydrogen', () => {
  const result = analyze({atoms:[atom(1,'C'),atom(2,'C'),atom(3,'O'),atom(4,'C')],bonds:[bond(1,2),bond(2,3,2),bond(2,4)]});
  assert.equal(result.formula,'C3H6O'); assert.equal(result.dbe,1);
});
test('hypervalent carbon is flagged and its formula is withheld', () => {
  const result = analyze({atoms:[atom(1,'C'),...Array.from({length:5},(_,i)=>atom(i+2,'H'))],bonds:Array.from({length:5},(_,i)=>bond(1,i+2))});
  assert.equal(result.isValid,false); assert.ok(result.invalidAtomIds.includes(1)); assert.equal(result.formula,null);
});
test('charged oxygen and nitrogen follow ordinary valence rules', () => {
  const result = analyze({atoms:[atom(1,'N',1),atom(2,'O',-1),atom(3,'O'),atom(4,'C')],bonds:[bond(1,2),bond(1,3,2),bond(1,4)]});
  assert.equal(result.isValid,true); assert.equal(result.formula,'CH3NO2');
});
test('unknown metal chemistry is not presented as fully validated', () => {
  const result = analyze({atoms:[atom(1,'Fe')],bonds:[]}); assert.equal(result.fullyChecked,false); assert.equal(result.formula,null);
});
test('missing, duplicate and self bonds are reported', () => {
  for (const bonds of [[bond(1,99)],[bond(1,1)],[bond(1,2),bond(1,2)]]) {
    assert.equal(analyze({atoms:[atom(1,'C'),atom(2,'O')],bonds}).isValid,false);
  }
});
test('mixture DBE is not reported as though it were one molecule', () => {
  const result = analyze({atoms:[atom(1,'C'),atom(2,'O')],bonds:[]}); assert.equal(result.fragments,2); assert.equal(result.dbe,null); assert.ok(result.warnings.length);
});
test('validation does not mutate the drawing', () => {
  const input = {atoms:[atom(1,'C'),atom(2,'O')],bonds:[bond(1,2)]}; const copy=JSON.stringify(input); analyze(input); assert.equal(JSON.stringify(input),copy);
});
