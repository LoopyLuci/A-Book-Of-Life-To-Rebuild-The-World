#!/usr/bin/env python3
"""
Render a survey as HTML, collect responses (from a JSON file), and report.
"""

from __future__ import annotations

import argparse
import json
import statistics
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
SURVEYS_DIR = ROOT / "surveys"
REPORTS_DIR = ROOT / "build" / "surveys"


HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{title}</title>
<style>
body {{ font-family: system-ui, sans-serif; max-width: 44rem; margin: 2rem auto;
        padding: 1rem; background: #fafaf7; color: #1a1a1a; }}
h1 {{ border-bottom: 2px solid #8b5a2b; padding-bottom: .5rem; }}
.question {{ margin: 1.5rem 0; }}
.prompt {{ font-weight: 600; }}
label {{ display: block; margin: .3rem 0; }}
input[type=text], textarea {{ width: 100%; padding: .5rem; font-size: 1rem; }}
button {{ padding: .75rem 1.5rem; font-size: 1rem; cursor: pointer;
          background: #8b5a2b; color: #fff; border: none; border-radius: 4px; }}
</style>
</head>
<body>
<h1>{title}</h1>
<p>Opens {opens} — closes {closes}.</p>
<form id="survey">
{questions}
<button type="submit">Submit</button>
</form>
<script>
document.getElementById('survey').addEventListener('submit', (e) => {{
  e.preventDefault();
  const form = new FormData(e.target);
  const response = {{}};
  for (const [k, v] of form.entries()) {{
    if (response[k]) {{
      response[k] = [].concat(response[k], v);
    }} else {{
      response[k] = v;
    }}
  }}
  const blob = new Blob([JSON.stringify(response, null, 2)], {{ type: 'application/json' }});
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'response.json';
  a.click();
}});
</script>
</body>
</html>
"""


def _render_question(q: dict) -> str:
    qid = q["id"]
    prompt = q["prompt"]
    qtype = q["type"]
    html = f'<div class="question"><div class="prompt">{prompt}</div>'

    if qtype == "single":
        for opt in q["options"]:
            html += f'<label><input type="radio" name="{qid}" value="{opt}"> {opt}</label>'
    elif qtype == "multiple":
        for opt in q["options"]:
            html += f'<label><input type="checkbox" name="{qid}" value="{opt}"> {opt}</label>'
    elif qtype == "scale":
        for n in range(q["min"], q["max"] + 1):
            html += f'<label><input type="radio" name="{qid}" value="{n}"> {n}</label>'
    elif qtype == "freeform":
        html += f'<textarea name="{qid}" rows="4"></textarea>'

    html += "</div>"
    return html


def render(survey: dict) -> str:
    questions = "\n".join(_render_question(q) for q in survey["questions"])
    return HTML_TEMPLATE.format(
        title=survey["title"],
        opens=survey["opens"],
        closes=survey["closes"],
        questions=questions,
    )


def analyze(survey: dict, responses: list[dict]) -> dict:
    out: dict = {"count": len(responses), "questions": {}}

    for q in survey["questions"]:
        qid = q["id"]
        values = [r.get(qid) for r in responses if qid in r]

        if q["type"] == "single":
            tally: dict[str, int] = {}
            for v in values:
                tally[v] = tally.get(v, 0) + 1
            out["questions"][qid] = {"type": "single", "tally": tally}
        elif q["type"] == "multiple":
            tally = {}
            for v in values:
                items = v if isinstance(v, list) else [v]
                for item in items:
                    tally[item] = tally.get(item, 0) + 1
            out["questions"][qid] = {"type": "multiple", "tally": tally}
        elif q["type"] == "scale":
            nums = [int(v) for v in values if str(v).isdigit()]
            out["questions"][qid] = {
                "type": "scale",
                "mean": statistics.mean(nums) if nums else None,
                "median": statistics.median(nums) if nums else None,
                "count": len(nums),
            }
        elif q["type"] == "freeform":
            out["questions"][qid] = {"type": "freeform", "responses": values}

    return out


def main() -> int:
    parser = argparse.ArgumentParser(prog="abook-survey")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_render = sub.add_parser("render")
    p_render.add_argument("survey_id")

    p_analyze = sub.add_parser("analyze")
    p_analyze.add_argument("survey_id")
    p_analyze.add_argument("responses_json")

    args = parser.parse_args()

    survey_path = SURVEYS_DIR / f"{args.survey_id.split('-')[-1]}.yaml"
    if not survey_path.exists():
        print(f"Survey not found: {survey_path}", file=sys.stderr)
        return 1
    with survey_path.open("r", encoding="utf-8") as f:
        survey = yaml.safe_load(f)

    REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    if args.cmd == "render":
        html = render(survey)
        out = REPORTS_DIR / f"{args.survey_id}.html"
        out.write_text(html, encoding="utf-8")
        print(f"Rendered: {out}")
        return 0

    if args.cmd == "analyze":
        responses = json.loads(Path(args.responses_json).read_text(encoding="utf-8"))
        if isinstance(responses, dict):
            responses = [responses]
        report = analyze(survey, responses)
        out = REPORTS_DIR / f"{args.survey_id}-report.json"
        out.write_text(json.dumps(report, indent=2), encoding="utf-8")
        print(f"Report: {out}")
        return 0

    return 1


if __name__ == "__main__":
    sys.exit(main())
