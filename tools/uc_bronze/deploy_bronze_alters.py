"""Deploy UC bronze ALTER COMMENT scripts produced by generate_bronze_alters.py.

Reads a per-database deploy index at
  knowledge/ProdSchemas/{repo}/{db}/_deploy-index.md

For each row with status 'Generated' the deployer:
  1. Locates the corresponding .alter.sql via the markdown link in the row
  2. Executes only the ALTER statements that target the row's UC table
     (a single .alter.sql may cover multiple UC targets)
  3. Updates the row's status to 'Deployed (Batch N) - DATE' or
     'Failed (Batch N) - <error>'
  4. Refreshes the frontmatter counts (generated / deployed / failed /
     last_deploy_batch / last_updated)

The Synapse deploy_alter_batch.py is intentionally left untouched; the bronze
layout (per-db deploy index, multi-target alter files, UC target embedded in
each row) doesn't fit its assumptions.

Usage:
  python -m tools.uc_bronze.deploy_bronze_alters --db CalendarDB --dry-run
  python -m tools.uc_bronze.deploy_bronze_alters --db CalendarDB --deploy-batch 1 -v
  python -m tools.uc_bronze.deploy_bronze_alters --db DB_Schema/CalendarDB --batch-size 50

Auth (see ~/.cursor/skills/databricks-connection/SKILL.md):
  DATABRICKS_TOKEN (PAT) for headless. If unset, uses databricks-oauth (browser).
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
PRODSCHEMAS_DIR = REPO_ROOT / "knowledge" / "ProdSchemas"

ROW_RE = re.compile(
    r"^\|\s*\[(?P<label>[^\]]+)\]\((?P<link>[^)]+)\)\s*\|\s*`(?P<uc>[^`]+)`\s*\|\s*(?P<status>[^|]+?)\s*\|\s*$"
)
ALTER_TABLE_RE = re.compile(r"^\s*ALTER\s+TABLE\s+([^\s(]+)", re.IGNORECASE)
FOOTER_RE = re.compile(
    r"\n*-- == LAST EXECUTION ==.*?-- ====================",
    re.DOTALL,
)


# ---- Index parsing ---------------------------------------------------------

@dataclass
class IndexRow:
    line_idx: int
    raw_line: str
    label: str
    link: str
    uc_target: str
    status: str


def find_deploy_index(db_arg: str) -> Path:
    """Resolve --db argument to a deploy-index.md path.

    Accepts either the full key 'DB_Schema/CalendarDB' or just 'CalendarDB'.
    """
    if "/" in db_arg:
        candidate = PRODSCHEMAS_DIR / db_arg / "_deploy-index.md"
        if candidate.is_file():
            return candidate
        sys.exit(f"deploy index not found: {candidate}")
    matches = list(PRODSCHEMAS_DIR.glob(f"*/{db_arg}/_deploy-index.md"))
    if not matches:
        sys.exit(f"no deploy index found for db '{db_arg}' under {PRODSCHEMAS_DIR}")
    if len(matches) > 1:
        sys.exit(f"ambiguous --db '{db_arg}', matches: {[str(m) for m in matches]}")
    return matches[0]


def parse_index(text: str) -> list[IndexRow]:
    rows: list[IndexRow] = []
    for i, line in enumerate(text.splitlines()):
        m = ROW_RE.match(line)
        if not m:
            continue
        rows.append(IndexRow(
            line_idx=i,
            raw_line=line,
            label=m.group("label"),
            link=m.group("link"),
            uc_target=m.group("uc"),
            status=m.group("status").strip(),
        ))
    return rows


# ---- Statement parsing -----------------------------------------------------

def strip_footer(content: str) -> str:
    return FOOTER_RE.sub("", content).rstrip()


def parse_statements(content: str) -> list[str]:
    body = strip_footer(content)
    statements: list[str] = []
    current: list[str] = []
    for line in body.splitlines():
        if ALTER_TABLE_RE.match(line):
            if current:
                statements.append("\n".join(current).strip())
            current = [line]
        elif current:
            current.append(line)
            if line.rstrip().endswith(";"):
                statements.append("\n".join(current).strip())
                current = []
    if current:
        statements.append("\n".join(current).strip())
    return [s for s in statements if s]


def statement_target(stmt: str) -> str | None:
    m = ALTER_TABLE_RE.match(stmt)
    if not m:
        return None
    # Normalize backticks: index rows store unquoted (e.g. `main.emoney.bronze-foo-1`)
    # while the alter file may have quoted segments (e.g. `main.emoney.\`bronze-foo-1\``).
    # Strip backticks for comparison.
    return m.group(1).strip().replace("`", "")


SAFE_IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def quote_target_for_sql(target: str) -> str:
    """Wrap unsafe segments of a dotted UC target in backticks for SQL execution.

    Index rows are stored unquoted (e.g. ``main.emoney.bronze_x-509416``) for
    readability, but Databricks SQL needs hyphens, leading digits, and other
    non-ANSI tokens quoted. This produces ``main.emoney.\u0060bronze_x-509416\u0060``.
    """
    out_parts: list[str] = []
    for p in target.split("."):
        if p.startswith("`") and p.endswith("`"):
            out_parts.append(p)
        elif SAFE_IDENT.match(p):
            out_parts.append(p)
        else:
            out_parts.append(f"`{p}`")
    return ".".join(out_parts)


# ---- Index update ----------------------------------------------------------

def sanitize_one_line(s: str, max_len: int = 120) -> str:
    s = (s or "").replace("\r", " ").replace("\n", " ").replace("|", "/")
    s = " ".join(s.split())
    return s[:max_len]


def render_row(row: IndexRow, new_status: str) -> str:
    return f"| [{row.label}]({row.link}) | `{row.uc_target}` | {new_status} |"


def update_frontmatter(text: str, *, generated: int, deployed: int, failed: int, batch: int, ts_short: str) -> str:
    text = re.sub(r"^generated:\s*\d+", f"generated: {generated}", text, count=1, flags=re.MULTILINE)
    text = re.sub(r"^deployed:\s*\d+", f"deployed: {deployed}", text, count=1, flags=re.MULTILINE)
    text = re.sub(r"^failed:\s*\d+", f"failed: {failed}", text, count=1, flags=re.MULTILINE)
    if "last_deploy_batch:" in text:
        text = re.sub(r"^last_deploy_batch:\s*\d+", f"last_deploy_batch: {batch}", text, count=1, flags=re.MULTILINE)
    else:
        text = re.sub(r"^source_tool:", f"last_deploy_batch: {batch}\nsource_tool:", text, count=1, flags=re.MULTILINE)
    if "last_deployed:" in text:
        text = re.sub(r'^last_deployed:\s*"[^"]+"', f'last_deployed: "{ts_short}"', text, count=1, flags=re.MULTILINE)
    else:
        text = re.sub(r"^source_tool:", f'last_deployed: "{ts_short}"\nsource_tool:', text, count=1, flags=re.MULTILINE)
    return text


def recount(rows: list[IndexRow]) -> tuple[int, int, int]:
    g = d = f = 0
    for r in rows:
        s = r.status
        if s.startswith("Deployed"):
            d += 1
        elif s.startswith("Failed"):
            f += 1
        else:
            g += 1
    return g, d, f


# ---- Main ------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--db", required=True, help="db key under ProdSchemas (e.g. CalendarDB or DB_Schema/CalendarDB)")
    ap.add_argument("--batch-size", type=int, default=25, help="max rows to deploy this run")
    ap.add_argument("--deploy-batch", type=int, default=1, help="batch number recorded in status / footer")
    ap.add_argument("--dry-run", action="store_true", help="preview which alters would run, no DB connection")
    ap.add_argument("-v", "--verbose", action="store_true")
    args = ap.parse_args()

    deploy_index = find_deploy_index(args.db)
    db_root = deploy_index.parent
    print(f"deploy index: {deploy_index.relative_to(REPO_ROOT)}")
    text = deploy_index.read_text(encoding="utf-8")
    rows = parse_index(text)
    if not rows:
        sys.exit("no rows parsed from index")

    generated = [r for r in rows if r.status == "Generated"]
    if not generated:
        print("no Generated rows; nothing to deploy")
        return 0

    batch = generated[: args.batch_size]
    print(f"plan: deploy {len(batch)} of {len(generated)} Generated rows (batch={args.deploy_batch})")
    for r in batch[:8]:
        print(f"  - {r.label}  ->  {r.uc_target}")
    if len(batch) > 8:
        print(f"  ... +{len(batch) - 8} more")

    if args.dry_run:
        print("\n(dry-run: no DB connection)")
        return 0

    from databricks import sql  # type: ignore

    host = os.environ.get("DATABRICKS_SERVER_HOSTNAME", "adb-5142916747090026.6.azuredatabricks.net")
    http_path = os.environ.get("DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/208214768b0e0308")
    token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()

    if token:
        print("auth: PAT (DATABRICKS_TOKEN)")
        conn = sql.connect(server_hostname=host, http_path=http_path, access_token=token)
    else:
        print("auth: databricks-oauth (browser)")
        conn = sql.connect(server_hostname=host, http_path=http_path, auth_type="databricks-oauth")
    cur = conn.cursor()

    ts_short = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    ts_full = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    deployed_tag = f"Deployed (Batch {args.deploy_batch}) - {ts_short}"
    failed_prefix = f"Failed (Batch {args.deploy_batch})"

    results: list[tuple[IndexRow, bool, str, int, int]] = []
    file_cache: dict[Path, list[str]] = {}

    for i, row in enumerate(batch, start=1):
        alter_path = (db_root / row.link).resolve()
        try:
            alter_path = alter_path.with_name(alter_path.name.removesuffix(".md") + ".alter.sql")
        except AttributeError:
            name = alter_path.name
            if name.lower().endswith(".md"):
                name = name[:-3]
            alter_path = alter_path.with_name(name + ".alter.sql")

        if args.verbose:
            print(f"[{i}/{len(batch)}] {row.label} -> {row.uc_target}")
            print(f"      alter: {alter_path.relative_to(REPO_ROOT)}")

        if not alter_path.is_file():
            results.append((row, False, "alter file not found", 0, 0))
            if args.verbose:
                print(f"      MISS: alter file not found")
            continue

        if alter_path not in file_cache:
            content = alter_path.read_text(encoding="utf-8")
            file_cache[alter_path] = parse_statements(content)
        all_stmts = file_cache[alter_path]
        target_stmts = [s for s in all_stmts if statement_target(s) == row.uc_target]
        if not target_stmts:
            results.append((row, False, f"no statements for target {row.uc_target}", 0, 0))
            if args.verbose:
                print(f"      MISS: no ALTER lines targeting {row.uc_target}")
            continue

        try:
            cur.execute(f"DESCRIBE TABLE {quote_target_for_sql(row.uc_target)}")
            cur.fetchall()
        except Exception as exc:
            results.append((row, False, f"DESCRIBE: {sanitize_one_line(str(exc), 300)}", 0, 0))
            if args.verbose:
                print(f"      DESCRIBE failed: {exc}")
            continue

        ok = fail = 0
        err_msg = ""
        for stmt in target_stmts:
            try:
                cur.execute(stmt)
                ok += 1
            except Exception as exc:
                fail += 1
                err_msg = sanitize_one_line(str(exc), 400)
                if args.verbose:
                    print(f"      stmt fail: {err_msg[:120]}")
        success = fail == 0
        results.append((row, success, err_msg, ok, fail))
        if args.verbose:
            tag = "OK" if success else "FAIL"
            print(f"      {tag} {ok}/{ok + fail} statements")

    cur.close()
    conn.close()

    new_lines = text.splitlines()
    for row, success, msg, ok, fcnt in results:
        if success:
            new_status = deployed_tag
        else:
            new_status = f"{failed_prefix} - {sanitize_one_line(msg, 120)}" if msg else f"{failed_prefix} - 0/{ok + fcnt}"
        new_lines[row.line_idx] = render_row(row, new_status)
        row.status = new_status

    final_text = "\n".join(new_lines) + ("\n" if text.endswith("\n") else "")
    g, d, f = recount(rows)
    final_text = update_frontmatter(
        final_text,
        generated=g,
        deployed=d,
        failed=f,
        batch=args.deploy_batch,
        ts_short=ts_short,
    )
    deploy_index.write_text(final_text, encoding="utf-8")

    for alter_path, _ in file_cache.items():
        try:
            content = alter_path.read_text(encoding="utf-8")
            stripped = strip_footer(content)
            footer = "\n".join([
                "",
                "-- == LAST EXECUTION ==",
                f"-- Timestamp: {ts_full}",
                f"-- Bronze deploy: {args.db} batch {args.deploy_batch}",
                "-- ====================",
            ])
            alter_path.write_text(stripped + footer + "\n", encoding="utf-8")
        except Exception:
            pass

    print("\n=== RESULT ===")
    deployed_n = failed_n = 0
    for row, success, msg, ok, fcnt in results:
        if success:
            print(f"  [OK]   {row.label}  ({ok} stmts)")
            deployed_n += 1
        else:
            print(f"  [FAIL] {row.label}  -> {msg[:200]}")
            failed_n += 1
    print(f"\nThis batch: deployed +{deployed_n}, failed +{failed_n}")
    print(f"Index now: generated={g}, deployed={d}, failed={f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
