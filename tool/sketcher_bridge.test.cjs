const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const chemistry=require('../assets/web/sketcher_intelligence.js');

function browser(width=800,height=600) {
  const nodes=new Map(), messages=[];
  let offsetX=0,offsetY=0,scale=1;
  const context=new Proxy({}, {get:(o,k)=> k==='measureText' ? ()=>({width:12}) : k==='translate' ? (x,y)=>{offsetX=x;offsetY=y;} : k==='scale' ? (x)=>{scale=x;} : ()=>{}});
  function node(id) {
    if(!nodes.has(id)) nodes.set(id,{style:{},dataset:{},listeners:{},classList:{add(){},remove(){},contains(){return false;}},children:[],
      getContext:()=>context,getBoundingClientRect:()=>({width,height,left:0,top:0}),
      addEventListener(type,fn){this.listeners[type]=fn;},appendChild(child){this.children.push(child);},querySelectorAll(){return [];},setAttribute(){},textContent:'',innerHTML:''});
    return nodes.get(id);
  }
  const window={ChemBuddySketcherIntelligence:chemistry,devicePixelRatio:1,addEventListener(){},ChemBridge:{postMessage:s=>messages.push(JSON.parse(s))}};
  const templates=['aspirin','benzene','acetophenone'].map(name=>{const entry=node('template-'+name);entry.dataset.template=name;return entry;});
  const document={getElementById:node,querySelectorAll:selector=>selector==='.template-item'?templates:[],querySelector:()=>null,createElement:()=>node(Symbol()),addEventListener(){}};
  const html=fs.readFileSync(require.resolve('../assets/web/sketcher.html'),'utf8');
  const script=[...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].at(-1)[1];
  vm.runInNewContext(script,{window,document,console,setTimeout(){},requestAnimationFrame:f=>f()});
  return {window,node,messages,html,view:()=>({offsetX,offsetY,scale})};
}

test('actual bundled browser script imports, checks and exports ethanol',()=>{
  const {window,node,messages,html}=browser();
  window.loadSmiles('CCO');
  assert.equal(window.checkStructure().formula,'C2H6O');
  assert.equal(window.getSmiles(),'CCO');
  assert.match(node('structure-feedback').textContent,/C2H6O/);
  assert.equal(messages.at(-1).data.atomCount,3);
  assert.match(html,/:root \{ color-scheme: light/);
});
test('import/export preserves two positional isomers rather than guessing by atom counts',()=>{
  const {window}=browser();
  window.loadSmiles('CCOc1ccccc1'); const ethoxy=window.getSmiles();
  window.loadSmiles('COc1ccccc1C'); const methoxy=window.getSmiles();
  assert.notEqual(ethoxy,methoxy);
  for(const text of [ethoxy,methoxy]) assert.equal(chemistry.analyze(chemistry.parseSmiles(text)).formula,'C8H10O');
});
test('aromaticity and charges survive molfile export',()=>{
  const {window}=browser();
  window.loadSmiles('C[N+](=O)[O-]');
  assert.equal(window.checkStructure().formula,'CH3NO2');
  assert.match(window.getMolfile(),/M  CHG/);
  window.loadSmiles('c1ccccc1');
  assert.equal(window.checkStructure().formula,'C6H6');
  assert.match(window.getMolfile(),/  4  0  0  0  0/);
  window.cleanUpStructure();
  assert.equal(window.checkStructure().formula,'C6H6');
});
test('deleting an atom renumbers molfile endpoints without changing surviving bonds',()=>{
  const {window,node,view}=browser();window.loadSmiles('CCCO');
  const first=window.getMolfile().split('\n')[4];
  const x=Number(first.slice(0,10))*40,y=-Number(first.slice(10,20))*40;
  node('btn-eraser').onclick();
  const transform=view();
  node('canvas-viewport').listeners.mousedown({preventDefault(){},clientX:x*transform.scale+transform.offsetX,clientY:y*transform.scale+transform.offsetY});
  const lines=window.getMolfile().split('\n');
  assert.equal(Number(lines[3].slice(0,3)),3);
  assert.equal(Number(lines[3].slice(3,6)),2);
  for(const line of lines.slice(7,9)) {
    assert.ok(Number(line.slice(0,3))>=1 && Number(line.slice(0,3))<=3);
    assert.ok(Number(line.slice(3,6))>=1 && Number(line.slice(3,6))<=3);
  }
  assert.equal(window.checkStructure().formula,'C2H6O');
});
test('mobile template additions fit every fragment without changing connectivity',()=>{
  const {window,node,view}=browser(360,420);
  node('template-aspirin').onclick({stopPropagation(){}});
  node('template-benzene').onclick({stopPropagation(){}});
  const before=window.getMolfile(),smiles=window.getSmiles();
  const lines=before.split('\n'),count=Number(lines[3].slice(0,3));
  const transform=view();assert.ok(transform.scale<1);
  for(const line of lines.slice(4,4+count)) {
    const x=Number(line.slice(0,10))*40*transform.scale+transform.offsetX;
    const y=-Number(line.slice(10,20))*40*transform.scale+transform.offsetY;
    assert.ok(x>=35 && x<=325,`clipped atom x=${x}`);
    assert.ok(y>=35 && y<=385,`clipped atom y=${y}`);
  }
  window.fitDrawing();assert.equal(window.getMolfile(),before);assert.equal(window.getSmiles(),smiles);
  const check=window.checkStructure();assert.equal(check.fragments,2);
  assert.match(node('structure-review-summary').textContent,/2 fragments/);
  assert.equal(node('structure-review').open,false);
  node('btn-check').onclick();assert.equal(node('structure-review').style.display,'none');
});
test('drawing after Clear then Undo keeps atom identifiers unique',()=>{
  const {window,node}=browser();window.loadSmiles('CCO');window.clearCanvas();window.undo();
  node('canvas-viewport').listeners.mousedown({preventDefault(){},clientX:40,clientY:40});
  const report=window.checkStructure();
  assert.deepEqual(report.errors,[]);assert.equal(report.fragments,2);
});
test('unsupported or malformed imports leave the existing molecule intact',()=>{
  const {window}=browser();window.loadSmiles('CCO');
  for(const input of ['C1CC','CC(','C=','C()','C(C.)','F/C=C/F','[13CH4]','CC@O']) assert.throws(()=>window.loadSmiles(input));
  assert.equal(window.getSmiles(),'CCO');
  window.clearCanvas();window.undo();assert.equal(window.getSmiles(),'CCO');
});
test('solver references retain their formula or explicitly reject unsupported stereochemistry',()=>{
  const source=fs.readFileSync(require.resolve('../lib/data/services/spectroscopy_service.dart'),'utf8');
  const entries=[...source.matchAll(/formula:\s*'([^']+)'[\s\S]*?commonName:\s*'([^']+)'[\s\S]*?smiles:\s*'([^']+)'/g)];
  assert.ok(entries.length>=40);
  const {window}=browser();
  for(const [,formula,name,smiles] of entries) {
    if (/[\\/@]/.test(smiles)) {
      assert.throws(()=>window.loadSmiles(smiles), /stereochemistry/);
      continue;
    }
    window.loadSmiles(smiles);
    assert.equal(window.checkStructure().formula?.toUpperCase(),formula.toUpperCase(),name);
    const exported=chemistry.analyze(chemistry.parseSmiles(window.getSmiles()));
    assert.equal(exported.formula?.toUpperCase(),formula.toUpperCase(),name+' exported graph');
  }
});
