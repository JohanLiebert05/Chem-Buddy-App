(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.ChemBuddySketcherIntelligence = api;
})(typeof window === 'object' ? window : globalThis, function () {
  'use strict';
  const weights = {B:10.81,C:12.011,H:1.008,N:14.007,O:15.999,F:18.998,P:30.974,S:32.06,Cl:35.45,Br:79.904,I:126.904};
  function analyze(graph) {
    const atoms = graph.atoms || [], bonds = graph.bonds || [];
    const errors = [], warnings = [], invalidAtomIds = new Set();
    const byId = new Map(), valence = new Map(), adjacency = new Map();
    const fail = (message, ids = []) => { errors.push(message); ids.forEach(id => invalidAtomIds.add(id)); };
    for (const atom of atoms) {
      if (byId.has(atom.id)) fail('Duplicate atom identifier.', [atom.id]);
      if (!Number.isFinite(atom.x) || !Number.isFinite(atom.y)) fail('An atom has invalid coordinates.', [atom.id]);
      if (!Number.isInteger(atom.charge || 0)) fail('Formal charges must be integers.', [atom.id]);
      byId.set(atom.id, atom); valence.set(atom.id, 0); adjacency.set(atom.id, []);
    }
    const pairs = new Set();
    for (const bond of bonds) {
      if (!byId.has(bond.atom1) || !byId.has(bond.atom2)) { fail('A bond has a missing endpoint.'); continue; }
      if (bond.atom1 === bond.atom2) { fail('An atom cannot bond to itself.', [bond.atom1]); continue; }
      const key = [bond.atom1, bond.atom2].sort().join(':');
      if (pairs.has(key)) fail('Duplicate bond: change its bond order instead.', [bond.atom1, bond.atom2]);
      pairs.add(key);
      const order = bond.order === 'wedge' || bond.order === 'dash' ? 1 : bond.order;
      if (![1, 2, 3, 1.5].includes(order)) { fail('Unsupported bond order.', [bond.atom1, bond.atom2]); continue; }
      valence.set(bond.atom1, valence.get(bond.atom1) + order);
      valence.set(bond.atom2, valence.get(bond.atom2) + order);
      adjacency.get(bond.atom1).push(bond.atom2); adjacency.get(bond.atom2).push(bond.atom1);
    }
    const counts = {}, implicitHydrogens = {}, unknown = new Set();
    let charge = 0;
    for (const atom of atoms) {
      const el = atom.element, q = atom.charge || 0;
      // A fused aromatic carbon has three neighbours and no H; three drawn
      // aromatic edges do not mean a literal 4.5-valent carbon.
      let used = valence.get(atom.id);
      if (atom.aromatic && el === 'C' && used === 4.5 && adjacency.get(atom.id).length === 3) used = 4;
      // Furan oxygen contributes a lone pair; two aromatic drawing edges do
      // not make it a three-valent neutral oxygen.
      if (atom.aromatic && el === 'O' && used === 3 && adjacency.get(atom.id).length === 2) used = 2;
      charge += q;
      const allowed = el === 'C' ? [q ? 3 : 4] : el === 'N' ? [q > 0 ? 4 : q < 0 ? 2 : 3] :
        el === 'O' ? [q > 0 ? 3 : q < 0 ? 1 : 2] : ['H','F','Cl','Br','I'].includes(el) ? [1] :
        el === 'B' ? [q < 0 ? 4 : 3] : el === 'P' ? [3,5] : el === 'S' ? [2,4,6] : null;
      counts[el] = (counts[el] || 0) + 1;
      if (!allowed) { unknown.add(el); continue; }
      if (used > Math.max(...allowed) + 0.01) fail(`${el} atom ${atom.id}: bond-order sum ${used} exceeds its ordinary valence.`, [atom.id]);
      const target = allowed.find(n => n >= used) || used;
      const h = atom.explicitHs != null ? atom.explicitHs : el === 'H' || ['F','Cl','Br','I'].includes(el) || (atom.aromatic && el !== 'C') ? 0 : Math.max(0, Math.floor(target - used + .01));
      if (used + h > Math.max(...allowed) + .01 && !atom.aromatic) fail(`${el} atom ${atom.id}: explicit hydrogens exceed ordinary valence.`, [atom.id]);
      counts.H = (counts.H || 0) + h;
      implicitHydrogens[atom.id] = h;
    }
    let fragments = 0;
    const visited = new Set();
    for (const atom of atoms) {
      if (visited.has(atom.id)) continue;
      fragments++;
      const queue = [atom.id]; visited.add(atom.id);
      while (queue.length) for (const next of adjacency.get(queue.pop()) || []) if (!visited.has(next)) { visited.add(next); queue.push(next); }
    }
    if (fragments > 1) warnings.push(`${fragments} disconnected fragments: verify whether this is a reactant mixture or an accidentally missing bond.`);
    if (unknown.size) warnings.push(`Valence and implicit-H checks are unavailable for ${[...unknown].join(', ')}.`);
    if (atoms.some(a => a.element === 'S' || a.element === 'P')) warnings.push('Variable-valence S/P requires chemical review.');
    if (!atoms.length) warnings.push('Draw or import a molecule first.');
    if (atoms.length <= 300) {
      const overlaps = atoms.some((a, i) => atoms.slice(i + 1).some(b => Math.hypot(a.x - b.x, a.y - b.y) < 8 && !pairs.has([a.id,b.id].sort().join(':'))));
      if (overlaps) warnings.push('Some non-bonded atoms overlap. Move them apart and check the intended bonds.');
    }
    const formula = ['C','H',...Object.keys(counts).filter(e => !['C','H'].includes(e)).sort()]
      .filter(e => counts[e] > 0).map(e => e + (counts[e] === 1 ? '' : counts[e])).join('');
    const fullyChecked = atoms.length > 0 && errors.length === 0 && unknown.size === 0;
    const molarMass = fullyChecked && Object.keys(counts).every(e => weights[e])
      ? Object.entries(counts).reduce((sum, [e,n]) => sum + weights[e] * n, 0) : null;
    const dbe = fullyChecked && fragments === 1 && charge === 0 && !counts.S && !counts.P
      ? (2 * (counts.C || 0) + 2 + (counts.N || 0) - (counts.H || 0) - (counts.F || 0) - (counts.Cl || 0) - (counts.Br || 0) - (counts.I || 0)) / 2 : null;
    return {isValid: errors.length === 0, fullyChecked, errors, warnings, invalidAtomIds:[...invalidAtomIds], fragments,
      formula: fullyChecked ? formula : null, molarMass, dbe, netCharge: charge, implicitHydrogens};
  }
  // Deliberately bounded importer. Unsupported stereochemistry/isotopes are
  // rejected rather than silently discarded by the educational 2D editor.
  function parseSmiles(input) {
    const s = input.trim(), atoms = [], bonds = [], branches = [], rings = new Map();
    let current = null, pending = null, i = 0;
    if (!s) throw Error('Enter a SMILES string.');
    const connect = (a,b,order) => bonds.push({atom1:a.id,atom2:b.id,order:order == null ? (a.aromatic && b.aromatic ? 1.5 : 1) : order});
    while (i < s.length) {
      const ch = s[i];
      if ('-=#:'.includes(ch)) {
        if (!current || pending != null) throw Error('Bond has no valid starting atom.');
        pending = {'-':1,'=':2,'#':3,':':1.5}[ch]; i++; continue;
      }
      if (ch === '(') { if (!current || pending != null) throw Error('Invalid branch.'); branches.push({atom:current,size:atoms.length}); i++; continue; }
      if (ch === ')') { if (!branches.length || pending != null || !current) throw Error('Unbalanced branch.'); const branch=branches.pop(); if(atoms.length===branch.size) throw Error('Empty branch.'); current=branch.atom; i++; continue; }
      if (ch === '.') { if (!current || pending != null) throw Error('Invalid fragment separator.'); current=null; i++; if(i===s.length) throw Error('Missing fragment.'); continue; }
      if (/\d/.test(ch) || ch === '%') {
        if (!current) throw Error('Ring label needs an atom.');
        const label = ch === '%' ? s.slice(i+1,i+3) : ch;
        if (!/^\d{1,2}$/.test(label) || (ch === '%' && label.length !== 2)) throw Error('Invalid ring label.');
        i += ch === '%' ? 3 : 1;
        if (rings.has(label)) {
          const previous=rings.get(label);
          if (previous.atom===current || (pending != null && previous.order != null && pending!==previous.order)) throw Error('Invalid ring closure.');
          connect(previous.atom,current,pending == null ? previous.order : pending); rings.delete(label);
        } else rings.set(label,{atom:current,order:pending});
        pending=null; continue;
      }
      let element, aromatic=false, charge=0, explicitHs=null;
      if (ch === '[') {
        const end=s.indexOf(']',i), token=end<0?'':s.slice(i+1,end);
        const m=/^([A-Z][a-z]?|[bcnops])(H\d*)?([+-]\d*|\+\+|--)?$/.exec(token);
        if (!m) throw Error('This editor cannot preserve that bracket atom, isotope or stereochemistry.');
        element=m[1]; if (m[2]) explicitHs=Number(m[2].slice(1)||1); else explicitHs=0;
        if(m[3]) charge=m[3][0]==='+' ? Number(m[3].slice(1)||1) : -Number(m[3].slice(1)||1);
        if(m[3]==='++') charge=2; if(m[3]==='--') charge=-2;
        i=end+1;
      } else {
        const m=/^(Cl|Br|[BCNOPSFIbcnops])/.exec(s.slice(i));
        if (!m) throw Error('Unsupported SMILES syntax: stereochemistry and isotopes require a full molecular editor.');
        element=m[1]; i+=element.length;
      }
      aromatic=/^[bcnops]$/.test(element); element=element[0].toUpperCase()+element.slice(1);
      const atom={id:atoms.length+1,element,aromatic,charge,explicitHs,x:60+atoms.length*50,y:120+(atoms.length%2)*28};
      atoms.push(atom); if(current) connect(current,atom,pending); current=atom; pending=null;
      if(atoms.length>300) throw Error('Import is limited to 300 atoms.');
    }
    if(branches.length || rings.size || pending!=null) throw Error('Incomplete SMILES: close all branches and rings.');
    const graph={atoms,bonds}; const report=analyze(graph);
    if(!report.isValid) throw Error(report.errors.join(' '));
    return graph;
  }
  function layout(graph) {
    // Relax coordinates together, so closing a ring cannot move just one end
    // of a previously regularized bond. Connectivity and charges stay intact.
    const atoms = graph.atoms, bonds = graph.bonds;
    if (atoms.length > 300) return;
    const byId = new Map(atoms.map(a => [a.id,a]));
    for (let step=0; step<160; step++) {
      const force = new Map(atoms.map(a=>[a.id,{x:0,y:0}]));
      for(let i=0;i<atoms.length;i++) for(let j=i+1;j<atoms.length;j++) {
        const a=atoms[i],b=atoms[j]; let dx=b.x-a.x,dy=b.y-a.y;
        if(Math.hypot(dx,dy)<.1) {dx=.2;dy=.3;}
        const d=Math.max(4,Math.hypot(dx,dy)), f=Math.min(12,1500/(d*d));
        force.get(a.id).x-=dx/d*f;force.get(a.id).y-=dy/d*f;
        force.get(b.id).x+=dx/d*f;force.get(b.id).y+=dy/d*f;
      }
      for(const bond of bonds) {
        const a=byId.get(bond.atom1),b=byId.get(bond.atom2);if(!a||!b) continue;
        const dx=b.x-a.x,dy=b.y-a.y,d=Math.max(.1,Math.hypot(dx,dy)),f=(d-55)*.12;
        force.get(a.id).x+=dx/d*f;force.get(a.id).y+=dy/d*f;
        force.get(b.id).x-=dx/d*f;force.get(b.id).y-=dy/d*f;
      }
      for(const atom of atoms) {const f=force.get(atom.id);atom.x+=Math.max(-8,Math.min(8,f.x));atom.y+=Math.max(-8,Math.min(8,f.y));}
    }
  }
  return {analyze, parseSmiles, layout};
});
