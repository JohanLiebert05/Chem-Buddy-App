"""Publish an explicitly partial, credential-free live spectroscopy report."""
import html
import json
import pathlib
import sys

rows = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
out = pathlib.Path("docs/reports")
out.mkdir(parents=True, exist_ok=True)
published = []
fixtures = []
for row in rows:
    clean = {k: v for k, v in row.items() if k != "service_invocations"}
    clean["outcome"] = ("validated_prediction" if row["status"] == "predicted" else
                        "quota_blocked" if "Daily AI request limit" in row.get("reason", "") else
                        "response_rejected")
    published.append(clean)
    if row["status"] == "predicted":
        response = next(c for c in reversed(row["service_invocations"]) if c["status"] == "response")
        fixtures.append({"name": row["name"], "formula": row["expected_formula"],
                         "smiles": row["input_smiles"], "model": row["model"], "text": response["text"]})
summary = {
    "date": "2026-11-01", "cases": len(rows), "gemini_response_cases": 10,
    "validated_predictions": sum(r["outcome"] == "validated_prediction" for r in published),
    "rejected_responses": sum(r["outcome"] == "response_rejected" for r in published),
    "quota_blocked": sum(r["outcome"] == "quota_blocked" for r in published),
    "model": "gemini-3.6-flash", "reported_configured_key_slots": 1,
    "conditions": "CDCl3, 298 K, 400 MHz proton frequency",
    "limitation": "Partial live run. Formula/connectivity and assignment consistency checks are not experimental NMR accuracy validation. No measured spectra benchmark or multi-key failover test was completed.",
    "cases_detail": published,
}
(out / "live-40-report.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
pathlib.Path("test/fixtures/gemini_live_2026_11_01.json").write_text(json.dumps(fixtures, indent=2), encoding="utf-8")
escape = lambda value: html.escape(str(value))
parts = ['''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>ChemBuddy — partial live Gemini review</title><style>
body{font:16px/1.6 system-ui;color:#182738;background:#f4f7fa;max-width:1100px;padding:24px;margin:auto}
article,header{background:white;border:1px solid #dce3ea;border-radius:18px;padding:24px;margin:20px 0}
svg{width:100%;height:auto}.plots{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:12px}
code{overflow-wrap:anywhere}table{width:100%;border-collapse:collapse}td,th{text-align:left;padding:8px;border-bottom:1px solid #ddd}
.warning{background:#fff1d6;padding:16px;border-radius:12px}</style>
<header><h1>40-case live Gemini review</h1><p>Revised ChemBuddy 3.5.6 · Prajwal A Kambar · 1 November 2026</p>
<p><strong>7 validated predictions · 3 rejected responses · 30 blocked by the daily AI quota</strong></p>
<p class="warning">This is a partial live run, not 40 completed Gemini predictions. Ten molecules received model responses. The account quota prevented the other thirty from reaching prediction. The user chose to finish this partial report.</p>
<p>Model: gemini-3.6-flash. Server metadata reported one configured key slot. Multi-key failover was not tested. Conditions: CDCl3, 298 K, 400 MHz (¹H).</p>
<p>All 40 inputs use distinct PubChem molecular formulas and specified connectivity. Formula alone cannot identify an isomer. Seven accepted responses passed local formula, connectivity, DBE, proton integration and carbon assignment checks. Their 21 SVGs are generated locally.</p>
<p><strong>No experimental NMR accuracy percentage is claimed.</strong> PubChem verifies formula/connectivity, not measured chemical shifts. Solubility, exchange, tautomerism and solvent effects need experimental assessment. Structure drawings show constitutional connectivity.</p></header>''']
for i, row in enumerate(published, 1):
    parts.append(f'<article><h2>{i}. {escape(row["name"])}</h2><p>{escape(row["expected_formula"])} · <strong>{escape(row["outcome"].replace("_", " "))}</strong></p><code>{escape(row["input_smiles"])}</code>')
    parts.append(f'<p><a href="{escape(row["source"])}">PubChem source</a></p>')
    if row["status"] == "predicted":
        parts.append(f'<p>Formula matches PubChem: {escape(row["formula_matches_pubchem"])} · DBE {escape(row["dbe"])}</p><div class="plots">')
        for key in ("structure_svg", "proton_svg", "carbon_svg"):
            svg = row[key]
            # SVGs originate from the local renderer, not from Gemini markup.
            if "<script" in svg.lower() or "javascript:" in svg.lower():
                raise ValueError("Unexpected executable SVG")
            parts.append(svg)
        parts.append('</div><details><summary>Assignments, explanation and uncertainties</summary>')
        for key in ("proton_signals", "carbon_signals", "explanation", "uncertainties"):
            parts.append(f'<h3>{escape(key.replace("_", " "))}</h3><pre style="white-space:pre-wrap;overflow-wrap:anywhere">{escape(json.dumps(row[key], indent=2, ensure_ascii=False))}</pre>')
        parts.append('</details>')
    else:
        parts.append(f'<p>{escape(row["reason"])}</p>')
    parts.append('</article>')
parts.append('</html>')
(out / "live-40-report.html").write_text("".join(parts), encoding="utf-8")
print({k: v for k, v in summary.items() if k != "cases_detail"})
