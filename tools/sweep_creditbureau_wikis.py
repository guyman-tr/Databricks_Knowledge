"""Sweep the CreditBureau→Client_Balance fabrication out of wiki files.

Mirrors the UC sweep (tools/sweep_creditbureau_to_client_balance.py) so the
source-of-truth wikis stop producing the fabrication on future redeploys.

Operates on:
  knowledge/synapse/Wiki/**/*.md          (source wikis — primary)
  knowledge/synapse/Wiki/**/*.alter.sql   (generated; refreshed anyway, but
                                            keep in sync now for consistency)

Skips:
  knowledge/skills/**                     (skills are hand-curated, already
                                            corrected manually weeks ago)
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import shutil
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIKI_DIR = ROOT / "knowledge" / "synapse" / "Wiki"

_KEEP_PREFIX = "<<<KEEP_CB_"
_KEEP_SUFFIX = ">>>"


# Phrase-level subs (sorted LONGEST first so they consume the more-specific
# variant before a shorter prefix-match runs).
PHRASE_SUBS = [
    # Bold rolling-slice sentence — MUST be tried before the un-bold prefix
    ("**1 if customer is eligible for CreditBureau credit report validation (CB = CreditBureau context).**",
     "**Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau); ≈ IsValidCustomer with AccountTypeID != 2 and 6 hardcoded CID exceptions for CountryID=250 — subsidiary eToro-EU accounts counted in regulatory capital reports.**"),
    # Non-bold variant with full trailing paren
    ("1 if customer is eligible for CreditBureau credit report validation (CB = CreditBureau context).",
     "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau)."),
    # Other long-form phrasings
    ("1 if customer is eligible for CreditBureau credit report validation",
     "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau)"),
    ("1 if the customer is eligible for credit bureau reporting",
     "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau)"),
    ("1 if the customer has a valid credit report (cb=Credit Bureau)",
     "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau)"),
    ("Credit Bureau reporting eligibility flag. 1 = eligible for credit reporting.",
     "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau)."),
    ("Credit bureau report validity flag at conversion time",
     "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau); captured at conversion time"),
    ("Credit report validity flag for US credit bureau reporting.",
     "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau)."),
    ("Credit bureau validity flag (1=credit report validated against external credit bureau)",
     "Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau)"),
    ("Legacy column tracking prior credit bureau validity",
     "Legacy column tracking prior Client_Balance validity (CB = Client_Balance, NOT CreditBureau)"),
    # Section-1 / What summaries
    ("(CB = CreditBureau context)",
     "(CB = Client_Balance, NOT CreditBureau)"),
    ("tighter CreditBureau eligibility gate",
     "tighter Client_Balance eligibility gate"),
]

# Protected anchors: any occurrence of 'CreditBureau' wrapped in these idioms
# is intentional corrective text (e.g., "NOT CreditBureau", italicized
# call-outs in Tier-5 footers, quoted-fabrication narratives). These get
# swapped out before token-level subs and restored at the end.
PROTECTED_ANCHORS = [
    # Tier 5 corrective callouts
    "NOT CreditBureau",
    "NOT *CreditBureau*",
    "*CreditBureau*",
    '"CreditBureau"',
    "'CreditBureau'",
    "`CreditBureau`",
    # Quoted-fabrication narratives (kept verbatim so reviewers understand
    # what was purged on 2026-05-29)
    '"CreditBureau credit report validation"',
    "'CreditBureau credit report validation'",
    "`CreditBureau credit report validation`",
    "CreditBureau credit report validation narrative",
    "CreditBureau credit report validation\" narrative",
    # Wider corrective-history sentences sometimes embed the bare token
    "fabricated CreditBureau",
    "fabrication: CreditBureau",
]

# Token-level fallbacks (applied after protecting anchors above)
TOKEN_SUBS = [
    ("CreditBureau", "Client_Balance"),
    ("Credit Bureau", "Client_Balance"),
    ("credit bureau", "Client_Balance"),
    ("Credit bureau", "Client_Balance"),
    ("credit-bureau", "Client_Balance"),
]


def transform_text(text: str) -> tuple[str, int]:
    if not text:
        return text, 0
    if "credit" not in text.lower() and "creditbureau" not in text.lower():
        return text, 0

    original = text
    out = text

    # Sort PHRASE_SUBS by length of the source string DESCENDING so the most
    # specific (longest) pattern always wins over a shorter prefix-match.
    for old, new in sorted(PHRASE_SUBS, key=lambda kv: -len(kv[0])):
        out = out.replace(old, new)

    # Protect intentional anchors so they survive token-level subs.
    placeholders: list[tuple[str, str]] = []
    for i, anchor in enumerate(PROTECTED_ANCHORS):
        if anchor in out:
            ph = f"{_KEEP_PREFIX}{i}{_KEEP_SUFFIX}"
            out = out.replace(anchor, ph)
            placeholders.append((ph, anchor))

    for old, new in TOKEN_SUBS:
        out = out.replace(old, new)

    # Restore protected anchors verbatim.
    for ph, anchor in placeholders:
        out = out.replace(ph, anchor)

    # Residue check — strip ALL protected anchors before scanning leftover.
    residue_test = out
    for _, anchor in placeholders:
        residue_test = residue_test.replace(anchor, "")
    if "creditbureau" in residue_test.lower() or "credit bureau" in residue_test.lower():
        return out, -1

    changed = 0 if out == original else 1
    return out, changed


def file_targets() -> list[Path]:
    files: list[Path] = []
    for ext in (".md", ".alter.sql"):
        files.extend(WIKI_DIR.rglob(f"*{ext}"))
    return sorted(files)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    if not args.dry_run and not args.apply:
        print("Specify --dry-run or --apply")
        return 2

    backup_dir = ROOT / "audits" / "_convergence_gap" / "wiki_sweep_backup"
    if args.apply:
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_dir = backup_dir / ts
        backup_dir.mkdir(parents=True, exist_ok=True)

    summary = {"files_scanned": 0, "files_changed": 0,
               "files_residue": 0, "files_skipped": 0, "details": []}

    for path in file_targets():
        try:
            raw = path.read_text(encoding="utf-8", errors="replace")
        except Exception as e:
            summary["files_skipped"] += 1
            summary["details"].append({"path": str(path.relative_to(ROOT)),
                                       "status": "READ_FAIL", "error": str(e)})
            continue
        summary["files_scanned"] += 1

        new_text, status = transform_text(raw)
        if status == 0:
            continue
        if status == -1:
            summary["files_residue"] += 1
            print(f"  RESIDUE  {path.relative_to(ROOT)}")
            summary["details"].append({"path": str(path.relative_to(ROOT)),
                                       "status": "RESIDUE"})
            continue

        summary["files_changed"] += 1
        diff_count = sum(
            1 for line_a, line_b in zip(raw.splitlines(), new_text.splitlines())
            if line_a != line_b
        )
        if args.dry_run:
            print(f"  DRY      {path.relative_to(ROOT)}   (~{diff_count} changed lines)")
        else:
            # Backup
            rel = path.relative_to(WIKI_DIR)
            bk = backup_dir / rel
            bk.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, bk)
            path.write_text(new_text, encoding="utf-8")
            print(f"  OK       {path.relative_to(ROOT)}   (backup: {bk.relative_to(ROOT)})")
        summary["details"].append({
            "path": str(path.relative_to(ROOT)),
            "status": "DRY" if args.dry_run else "APPLIED",
            "lines_changed": diff_count,
        })

    print(f"\nScanned: {summary['files_scanned']}  "
          f"Changed: {summary['files_changed']}  "
          f"Residue: {summary['files_residue']}  "
          f"Skipped: {summary['files_skipped']}")

    log_path = ROOT / "audits" / "_convergence_gap" / (
        "wiki_sweep_dry.json" if args.dry_run else "wiki_sweep_apply.json"
    )
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"Summary: {log_path.relative_to(ROOT)}")
    return 0 if summary["files_residue"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
