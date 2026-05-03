#!/usr/bin/env python3
"""
Preflight checks for UC ALTER deployments.

Consolidates encoding, mojibake, identifier, escape, and termination audits across
the queue of `.alter.sql` files (and the downstream monolith). Auto-fixes what is
safely fixable and writes a markdown report.

Checks performed (in order):
  1. UTF-8 encoding validity (block on failure)
  2. Mojibake / `C OMMENT` keyword breaks (auto-fix via _uc_comment_sanitize)
  3. Structural ALTER TABLE target validity (block: prose pasted as table name,
     bogus `Tier N` as column, etc.) — delegates to audit_alter_uc_mapping.
  4. Identifier wrapping for unsafe column names (auto-fix: wrap in backticks)
       Triggers when the bare token after `ALTER COLUMN` contains any of:
       `-`, `/`, `%`, `+`, ` `, or starts with a digit.
  5. Apostrophe-escape audit for `COMMENT '...'` literals (block on odd quote count)
  6. Statement termination — every ALTER must end with `;` (block)

Usage:
  python tools/preflight_alters.py --schemas Dealing_dbo eMoney_dbo EXW_dbo \\
      --downstream knowledge/synapse/Wiki/_downstream_column_comments.sql \\
      --apply

Without `--apply` the run is dry; auto-fixes are reported but not written.
"""
from __future__ import annotations

import argparse
import importlib.util
import re
import sys
from datetime import date
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"

# ----- mojibake sanitizer (reuse the wiki module) ----------------------------
_san_path = WIKI / "_uc_comment_sanitize.py"
_spec = importlib.util.spec_from_file_location("_uc_comment_sanitize", _san_path)
assert _spec and _spec.loader
_san_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_san_mod)
sanitize_uc_sql_comment_text = _san_mod.sanitize_uc_sql_comment_text


# ----- regexes ---------------------------------------------------------------
ALTER_COLUMN_RE = re.compile(
    r"(ALTER\s+COLUMN\s+)(\S(?:.*?\S)?)(\s+(?:COMMENT|SET\s+TAGS)\b)",
    re.IGNORECASE,
)
# Match `ALTER TABLE <target>` and capture the raw target token.
# Supports targets like `a.b.c-123` (will be backtick-fixed by fix_unsafe_table_targets).
ALTER_TABLE_TARGET_RE = re.compile(
    r"^(\s*ALTER\s+(?:TABLE|VIEW)\s+)([^\s(;]+)(.*)$",
    re.IGNORECASE,
)
# For audit only: lines starting with `ALTER TABLE` / `ALTER VIEW`.
ALTER_TABLE_RE = re.compile(r"^\s*ALTER\s+(TABLE|VIEW)\s+(\S+)", re.IGNORECASE)
COMMENT_LITERAL_RE = re.compile(r"COMMENT\s+'((?:[^']|'')*)'", re.DOTALL)
VALID_DOTTED_ID = re.compile(r"^[A-Za-z_][A-Za-z0-9_.]*$")
SAFE_IDENT_SEGMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
BOGUS_TIER = re.compile(r"ALTER\s+COLUMN\s+Tier\s+\d+\b", re.IGNORECASE)
BROKEN_COMMENT_KW = re.compile(r"\bC\s+OMMENT\b", re.IGNORECASE)


def _is_unsafe_column_token(tok: str) -> bool:
    """Return True if the bare (un-backticked) column token needs backticking."""
    if not tok:
        return False
    if tok.startswith("`") and tok.endswith("`"):
        return False
    if tok.startswith("[") and tok.endswith("]"):
        return False  # SQL Server brackets — out of scope here
    if tok[0].isdigit():
        return True
    for ch in tok:
        if ch in "-/%+ @":
            return True
    return False


def _split_dotted(target: str) -> list[str]:
    """Split a dotted SQL identifier on `.` while honoring backtick segments.

    Returns the list of segments (with backticks stripped from quoted ones if any).
    Any trailing non-segment characters cause an empty/garbage segment which the
    caller can detect.
    """
    out: list[str] = []
    i = 0
    while i < len(target):
        if target[i] == "`":
            # find matching backtick
            j = target.find("`", i + 1)
            if j < 0:
                # unterminated backtick — treat rest as one bad segment
                out.append(target[i:])
                return out
            out.append(target[i : j + 1])
            i = j + 1
            if i < len(target) and target[i] == ".":
                i += 1
            continue
        # plain segment up to next .
        j = target.find(".", i)
        if j < 0:
            out.append(target[i:])
            return out
        out.append(target[i:j])
        i = j + 1
    return out


def _segment_needs_backticks(seg: str) -> bool:
    if not seg:
        return False
    if seg.startswith("`") and seg.endswith("`"):
        return False
    return SAFE_IDENT_SEGMENT.match(seg) is None


def _wrap_dotted_target(target: str) -> tuple[str, bool]:
    """Wrap any unsafe segments of a dotted target in backticks.

    Returns (new_target, changed)."""
    parts = _split_dotted(target)
    changed = False
    new_parts: list[str] = []
    for p in parts:
        if _segment_needs_backticks(p):
            new_parts.append(f"`{p}`")
            changed = True
        else:
            new_parts.append(p)
    return ".".join(new_parts), changed


def _wrap_backticks(tok: str) -> str:
    if tok.startswith("`") and tok.endswith("`"):
        return tok
    return f"`{tok}`"


# ----- per-check handlers ----------------------------------------------------
def check_utf8(path: Path) -> str | None:
    """Return error message if file is not strict UTF-8."""
    try:
        path.read_bytes().decode("utf-8", errors="strict")
    except UnicodeDecodeError as e:
        return f"non-utf8 at byte {e.start}: {e.reason}"
    return None


def fix_mojibake(text: str) -> tuple[str, int]:
    """Apply unicode/mojibake sanitization and `C OMMENT` keyword repair."""
    fixed = sanitize_uc_sql_comment_text(text)
    fixed, n_kw = BROKEN_COMMENT_KW.subn("COMMENT", fixed)
    return fixed, (1 if fixed != text else 0) + n_kw


def fix_unsafe_columns(text: str) -> tuple[str, list[tuple[int, str]]]:
    """Wrap unsafe column tokens in backticks. Returns new text and list of (line, before->after)."""
    changes: list[tuple[int, str]] = []
    out_lines: list[str] = []
    for line_no, line in enumerate(text.splitlines(keepends=True), 1):
        m = ALTER_COLUMN_RE.search(line)
        if not m:
            out_lines.append(line)
            continue
        prefix, tok, suffix = m.group(1), m.group(2), m.group(3)
        if not _is_unsafe_column_token(tok):
            out_lines.append(line)
            continue
        wrapped = _wrap_backticks(tok)
        new_line = line[: m.start()] + prefix + wrapped + suffix + line[m.end() :]
        changes.append((line_no, f"{tok} -> {wrapped}"))
        out_lines.append(new_line)
    return "".join(out_lines), changes


def fix_unsafe_table_targets(text: str) -> tuple[str, list[tuple[int, str]]]:
    """Wrap unsafe segments of `ALTER TABLE <target>` in backticks.

    Skips lines whose target is `Tier N` etc. (those are bogus and stay flagged
    by audit_structural). Returns new text and list of (line, before->after).
    """
    changes: list[tuple[int, str]] = []
    out_lines: list[str] = []
    for line_no, line in enumerate(text.splitlines(keepends=True), 1):
        # Strip line-ending so the regex tail-anchor `$` doesn't eat across newlines.
        if line.endswith("\r\n"):
            stripped, eol = line[:-2], "\r\n"
        elif line.endswith("\n"):
            stripped, eol = line[:-1], "\n"
        else:
            stripped, eol = line, ""
        m = ALTER_TABLE_TARGET_RE.match(stripped)
        if not m:
            out_lines.append(line)
            continue
        prefix, target, rest = m.group(1), m.group(2), m.group(3)
        new_target, changed = _wrap_dotted_target(target)
        if not changed:
            out_lines.append(line)
            continue
        out_lines.append(prefix + new_target + rest + eol)
        changes.append((line_no, f"{target} -> {new_target}"))
    return "".join(out_lines), changes


def audit_apostrophe_escapes(text: str, path: Path) -> list[str]:
    """Find COMMENT '...' literals where inside-quote escaping is broken.

    Heuristic: walk the file line-by-line; when we see `COMMENT '`, find the
    closing quote. Inside, every `'` must be doubled (`''`). If we hit a line end
    or end-of-statement (`;`) with an odd count of unescaped quotes, flag it.
    """
    issues: list[str] = []
    lines = text.splitlines()
    for line_no, line in enumerate(lines, 1):
        # Find each COMMENT ' on this line
        idx = 0
        while True:
            m = re.search(r"COMMENT\s+'", line[idx:], re.IGNORECASE)
            if not m:
                break
            start = idx + m.end()  # first char after opening '
            # Find matching closing quote on same line: the literal ends at the first
            # unpaired single quote. '' is escape; ' alone is end.
            i = start
            terminated = False
            while i < len(line):
                if line[i] == "'":
                    if i + 1 < len(line) and line[i + 1] == "'":
                        i += 2
                        continue
                    terminated = True
                    break
                i += 1
            if not terminated:
                snippet = line[max(0, start - 20) : min(len(line), start + 80)].strip()
                issues.append(f"line {line_no}: unterminated COMMENT literal: ...{snippet}...")
                break  # stop scanning this line
            idx = i + 1
    return issues


def audit_statement_termination(text: str) -> list[str]:
    """Every ALTER must terminate with ';' before the next ALTER or EOF.
    Walk lines, group from one ALTER to the next; strip footer first."""
    body = re.sub(
        r"\n*-- == LAST EXECUTION ==.*?-- ====================",
        "",
        text,
        flags=re.DOTALL,
    ).rstrip()
    issues: list[str] = []
    current: list[tuple[int, str]] = []
    start_line = 0

    def _close(group: list[tuple[int, str]], start: int) -> None:
        if not group:
            return
        # Find last non-blank, non-comment line
        last_meaningful = ""
        for _ln, ll in reversed(group):
            s = ll.strip()
            if s and not s.startswith("--"):
                last_meaningful = s
                break
        if last_meaningful and not last_meaningful.endswith(";"):
            issues.append(f"line {start}: ALTER block missing terminating `;`")

    for line_no, line in enumerate(body.splitlines(), 1):
        s = line.strip()
        if s.upper().startswith("ALTER TABLE") or s.upper().startswith("ALTER VIEW"):
            _close(current, start_line)
            current = [(line_no, line)]
            start_line = line_no
        elif current:
            current.append((line_no, line))
    _close(current, start_line)
    return issues


def audit_structural(text: str) -> list[str]:
    """Invalid table targets (prose) and bogus `Tier N` as column.

    A target is "valid" when each dotted segment is either a safe ANSI ident
    or a backtick-quoted segment. So `main.emoney.\u0060bronze-foo-1\u0060` passes,
    but a prose value like `Tier N` does not.
    """
    issues: list[str] = []
    for line_no, line in enumerate(text.splitlines(), 1):
        m = ALTER_TABLE_RE.match(line)
        if m:
            tgt = m.group(2)
            parts = _split_dotted(tgt)
            for seg in parts:
                if not seg:
                    issues.append(f"line {line_no}: invalid table target `{tgt}` (empty segment)")
                    break
                if seg.startswith("`") and seg.endswith("`") and len(seg) >= 2:
                    continue
                if not SAFE_IDENT_SEGMENT.match(seg):
                    issues.append(f"line {line_no}: invalid table target `{tgt}`")
                    break
        if BOGUS_TIER.search(line):
            issues.append(f"line {line_no}: `ALTER COLUMN Tier N` (bogus tier-as-column)")
    return issues


# ----- per-file driver -------------------------------------------------------
def process_file(
    path: Path, apply: bool
) -> dict:
    """Run all checks on a single file. Returns dict with summary + actions."""
    res: dict = {
        "path": str(path.relative_to(REPO)).replace("\\", "/"),
        "encoding": "ok",
        "mojibake_fixes": 0,
        "identifier_fixes": [],
        "structural_blocks": [],
        "escape_blocks": [],
        "termination_blocks": [],
        "modified": False,
    }
    enc_err = check_utf8(path)
    if enc_err:
        res["encoding"] = enc_err
        return res  # do not attempt further checks

    text = path.read_text(encoding="utf-8")

    # Auto-fix layers: mojibake first, then identifier wrapping (column + table target)
    new_text = text
    new_text, n_moji = fix_mojibake(new_text)
    res["mojibake_fixes"] = n_moji

    new_text, id_changes = fix_unsafe_columns(new_text)
    new_text, tgt_changes = fix_unsafe_table_targets(new_text)
    res["identifier_fixes"] = id_changes + tgt_changes

    if apply and new_text != text:
        path.write_text(new_text, encoding="utf-8")
        res["modified"] = True
        text = new_text  # subsequent audits look at the fixed content
    elif new_text != text:
        text = new_text  # still audit the would-be-fixed content (dry run)

    # Blocking audits (no auto-fix)
    res["structural_blocks"] = audit_structural(text)
    res["escape_blocks"] = audit_apostrophe_escapes(text, path)
    res["termination_blocks"] = audit_statement_termination(text)

    return res


# ----- queue collection ------------------------------------------------------
PRODSCHEMAS = REPO / "knowledge" / "ProdSchemas"


def collect_queue(schemas: list[str], extra_files: list[Path]) -> list[Path]:
    out: list[Path] = []
    for sch in schemas:
        d = WIKI / sch
        if not d.is_dir():
            print(f"WARN: schema dir not found: {d}", file=sys.stderr)
            continue
        for sub in ("Tables", "Views", "Functions"):
            sd = d / sub
            if not sd.is_dir():
                continue
            for p in sorted(sd.glob("*.alter.sql")):
                if ".downstream." in p.name:
                    continue
                out.append(p)
    for p in extra_files:
        if p.is_file():
            out.append(p)
    return out


def collect_bronze_queue(dbs: list[str] | None) -> list[Path]:
    """Collect .alter.sql files from knowledge/ProdSchemas/{repo}/{db}/Tables/.

    If ``dbs`` is None, every db under PRODSCHEMAS that has a _deploy-index.md
    is scanned. Otherwise only the named db folders are scanned.
    """
    out: list[Path] = []
    if not PRODSCHEMAS.is_dir():
        return out
    for idx in sorted(PRODSCHEMAS.rglob("_deploy-index.md")):
        db_root = idx.parent
        db_name = db_root.name
        if dbs is not None and db_name not in dbs:
            continue
        for p in sorted(db_root.rglob("*.alter.sql")):
            if ".downstream." in p.name:
                continue
            out.append(p)
    return out


# ----- report writer ---------------------------------------------------------
def write_report(report_path: Path, results: list[dict], apply: bool) -> dict:
    n_total = len(results)
    n_blocked = sum(
        1
        for r in results
        if r["encoding"] != "ok"
        or r["structural_blocks"]
        or r["escape_blocks"]
        or r["termination_blocks"]
    )
    n_modified = sum(1 for r in results if r["modified"])
    n_would_modify = sum(
        1
        for r in results
        if not r["modified"] and (r["mojibake_fixes"] or r["identifier_fixes"])
    )

    lines: list[str] = [
        "# Preflight report — UC ALTER deployment queue",
        "",
        f"- **Run date:** {date.today().isoformat()}",
        f"- **Mode:** {'APPLY (writes)' if apply else 'DRY-RUN (no writes)'}",
        f"- **Files scanned:** {n_total}",
        f"- **Files auto-fixed:** {n_modified}" if apply else f"- **Files that would be auto-fixed:** {n_would_modify}",
        f"- **Files BLOCKED:** {n_blocked}",
        "",
        "Blocks = encoding errors, prose-as-target, bogus `Tier N` as column,",
        "unterminated COMMENT literal, or missing `;`. Auto-fixes = mojibake / unicode",
        "punctuation normalization and backtick-wrapping of unsafe column tokens.",
        "",
    ]

    blocked = [r for r in results if r["encoding"] != "ok" or r["structural_blocks"] or r["escape_blocks"] or r["termination_blocks"]]
    if blocked:
        lines.append("## Blocked files")
        lines.append("")
        for r in blocked:
            lines.append(f"### `{r['path']}`")
            lines.append("")
            if r["encoding"] != "ok":
                lines.append(f"- **Encoding**: {r['encoding']}")
            for b in r["structural_blocks"]:
                lines.append(f"- **Structural**: {b}")
            for b in r["escape_blocks"]:
                lines.append(f"- **Apostrophe**: {b}")
            for b in r["termination_blocks"]:
                lines.append(f"- **Termination**: {b}")
            lines.append("")

    fixed = [r for r in results if r["mojibake_fixes"] or r["identifier_fixes"]]
    if fixed:
        verb = "Auto-fixed" if apply else "Would auto-fix"
        lines.append(f"## {verb} files")
        lines.append("")
        for r in fixed:
            lines.append(f"### `{r['path']}`")
            lines.append("")
            if r["mojibake_fixes"]:
                lines.append(f"- **Mojibake / keyword**: {r['mojibake_fixes']} fix(es)")
            if r["identifier_fixes"]:
                lines.append(f"- **Identifier backtick wrap**: {len(r['identifier_fixes'])} change(s)")
                for ln, change in r["identifier_fixes"][:20]:
                    lines.append(f"    - line {ln}: `{change}`")
                if len(r["identifier_fixes"]) > 20:
                    lines.append(f"    - … +{len(r['identifier_fixes']) - 20} more")
            lines.append("")

    clean = n_total - n_blocked - len(fixed)
    lines.append(f"## Clean files: {clean}")
    lines.append("")

    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text("\n".join(lines), encoding="utf-8")
    return {
        "total": n_total,
        "blocked": n_blocked,
        "auto_fixed": n_modified if apply else n_would_modify,
        "clean": clean,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--schemas",
        nargs="*",
        default=[],
        help="Schema folders under knowledge/synapse/Wiki/ to scan (optional)",
    )
    ap.add_argument(
        "--bronze",
        action="store_true",
        help="Scan all .alter.sql under knowledge/ProdSchemas/* with a _deploy-index.md",
    )
    ap.add_argument(
        "--bronze-dbs",
        nargs="*",
        default=None,
        help="If --bronze, restrict to these db folder names (e.g. CalendarDB etoro)",
    )
    ap.add_argument(
        "--downstream",
        type=Path,
        default=None,
        help="Optional downstream SQL monolith to include",
    )
    ap.add_argument(
        "--apply",
        action="store_true",
        help="Write auto-fixes (default: dry-run, only report)",
    )
    ap.add_argument(
        "--report",
        type=Path,
        default=WIKI / f"_preflight_report_{date.today().isoformat()}.md",
    )
    args = ap.parse_args()

    extra: list[Path] = []
    if args.downstream and args.downstream.is_file():
        extra.append(args.downstream)

    queue: list[Path] = []
    if args.schemas:
        queue.extend(collect_queue(args.schemas, extra))
    elif extra:
        queue.extend(extra)
    if args.bronze:
        queue.extend(collect_bronze_queue(args.bronze_dbs))
    if not queue:
        print(
            "No files to scan. Pass --schemas, --bronze, or --downstream.",
            file=sys.stderr,
        )
        return 1

    print(f"Scanning {len(queue)} file(s); apply={args.apply}", flush=True)
    results: list[dict] = []
    for p in queue:
        r = process_file(p, apply=args.apply)
        results.append(r)
        marks: list[str] = []
        if r["encoding"] != "ok":
            marks.append("ENC")
        if r["mojibake_fixes"]:
            marks.append(f"moji+{r['mojibake_fixes']}")
        if r["identifier_fixes"]:
            marks.append(f"id+{len(r['identifier_fixes'])}")
        if r["structural_blocks"]:
            marks.append("STRUCT")
        if r["escape_blocks"]:
            marks.append("ESC")
        if r["termination_blocks"]:
            marks.append("TERM")
        tag = "[" + ",".join(marks) + "]" if marks else "[ok]"
        print(f"  {tag} {r['path']}", flush=True)

    summary = write_report(args.report, results, args.apply)
    print("", flush=True)
    print(
        f"Preflight: {summary['total']} files; "
        f"auto-fixed={summary['auto_fixed']}; "
        f"blocked={summary['blocked']}; "
        f"clean={summary['clean']}",
        flush=True,
    )
    abs_report = args.report.resolve()
    try:
        print(f"Report: {abs_report.relative_to(REPO)}", flush=True)
    except ValueError:
        print(f"Report: {abs_report}", flush=True)
    return 1 if summary["blocked"] > 0 else 0


if __name__ == "__main__":
    raise SystemExit(main())
