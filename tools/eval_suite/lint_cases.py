"""Lint every case YAML against schema/case.schema.json.

Usage:
    python tools/eval_suite/lint_cases.py
    python tools/eval_suite/lint_cases.py --strict   # fail on PENDING expected_value

Exit codes:
    0 — all cases valid
    1 — schema violations or duplicate ids
    2 — strict mode: at least one case still has expected_value.type == "PENDING"
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import yaml

try:
    import jsonschema
except ImportError:  # pragma: no cover
    print("ERROR: jsonschema not installed. pip install jsonschema pyyaml", file=sys.stderr)
    sys.exit(3)

HERE = Path(__file__).resolve().parent
SCHEMA_PATH = HERE / "schema" / "case.schema.json"
CASES_DIR = HERE / "cases"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true", help="fail when any case is still PENDING")
    parser.add_argument("--cases-dir", default=str(CASES_DIR))
    args = parser.parse_args()

    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    validator = jsonschema.Draft202012Validator(schema)

    cases_dir = Path(args.cases_dir)
    if not cases_dir.exists():
        print(f"[lint] no cases dir at {cases_dir} — nothing to lint")
        return 0

    yaml_files = sorted(cases_dir.glob("*.yaml")) + sorted(cases_dir.glob("*.yml"))
    if not yaml_files:
        print(f"[lint] {cases_dir} is empty — nothing to lint")
        return 0

    seen_ids: dict[str, Path] = {}
    errors = 0
    pending = 0
    for yf in yaml_files:
        try:
            doc = yaml.safe_load(yf.read_text(encoding="utf-8"))
        except yaml.YAMLError as e:
            print(f"[lint] {yf.name}: yaml parse error: {e}")
            errors += 1
            continue
        if not isinstance(doc, dict):
            print(f"[lint] {yf.name}: top-level must be a mapping")
            errors += 1
            continue
        for err in validator.iter_errors(doc):
            path = "/".join(str(p) for p in err.absolute_path) or "<root>"
            print(f"[lint] {yf.name}: {path}: {err.message}")
            errors += 1
        cid = doc.get("id")
        if cid:
            if cid != yf.stem:
                print(f"[lint] {yf.name}: id={cid!r} does not match filename stem={yf.stem!r}")
                errors += 1
            if cid in seen_ids:
                print(f"[lint] duplicate id {cid!r} in {yf} and {seen_ids[cid]}")
                errors += 1
            else:
                seen_ids[cid] = yf
        ev = (doc.get("expected_value") or {})
        if ev.get("type") == "PENDING":
            pending += 1

    print(f"[lint] {len(yaml_files)} cases, {errors} errors, {pending} pending")
    if errors:
        return 1
    if args.strict and pending:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
