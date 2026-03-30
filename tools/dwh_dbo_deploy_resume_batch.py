"""
Resume deploy: next N objects with status Generated in _deploy-index.md.
Single databricks.sql session. Updates _deploy-index.md.

Default schema is DWH_dbo; use --schema Dealing_dbo for Dealing.

Usage:
  python tools/dwh_dbo_deploy_resume_batch.py --batch-size 25 --deploy-batch 2
  python tools/dwh_dbo_deploy_resume_batch.py --schema Dealing_dbo --batch-size 50 --deploy-batch 1 -v
  python tools/dwh_dbo_deploy_resume_batch.py --redo-batch 5 --deploy-batch 5
    # reset Deployed (Batch 5) -> Generated, then re-execute ALTER for those objects only

Auth (see ~/.cursor/skills/databricks-connection/SKILL.md):
  Set DATABRICKS_TOKEN (PAT) for headless / no browser. Optional overrides:
  DATABRICKS_SERVER_HOSTNAME, DATABRICKS_HTTP_PATH.
  If DATABRICKS_TOKEN is unset, uses databricks-oauth (browser).
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]


def reset_deployed_batch_to_generated(
    text: str, batch_num: int, schema: str
) -> tuple[str, list[tuple[str, str]]]:
    """Replace | Deployed (Batch N) | rows with | Generated |. Returns new text and object list."""
    rows: list[tuple[str, str]] = []
    new_lines: list[str] = []
    for line in text.splitlines():
        if f"Deployed (Batch {batch_num})" in line and line.strip().startswith("|"):
            m = re.search(
                rf"\[{re.escape(schema)}\.([^\]]+)\]\((Tables|Views|Functions)/[^\)]+\.md\)",
                line,
            )
            if m:
                name = m.group(1)
                folder = m.group(2)
                new_lines.append(f"| [{schema}.{name}]({folder}/{name}.md) | Generated |")
                rows.append((name, folder))
                continue
        new_lines.append(line)
    return "\n".join(new_lines), rows


def parse_generated_objects(deploy_index: Path, schema: str) -> list[tuple[str, str]]:
    text = deploy_index.read_text(encoding="utf-8")
    prefix = f"[{schema}."
    out: list[tuple[str, str]] = []
    for line in text.splitlines():
        if prefix not in line or not line.strip().startswith("|"):
            continue
        parts = line.split("|")
        if len(parts) < 4:
            continue
        status = parts[2].strip()
        if status != "Generated":
            continue
        for folder in ("Tables", "Views", "Functions"):
            m = re.search(rf"\]\({folder}/([^)]+\.md)\)", line)
            if m:
                out.append((m.group(1).replace(".md", ""), folder))
                break
    return out


def strip_footer(raw: str) -> str:
    return re.sub(
        r"\n*-- == LAST EXECUTION ==.*?-- ====================",
        "",
        raw,
        flags=re.DOTALL,
    ).rstrip()


def parse_statements(content: str) -> list[str]:
    content = strip_footer(content)
    statements: list[str] = []
    current: list[str] = []
    for line in content.splitlines():
        if line.strip().startswith("ALTER TABLE"):
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


def is_stub(content: str) -> bool:
    body = strip_footer(content)
    for line in body.splitlines():
        s = line.strip()
        if not s or s.startswith("--"):
            continue
        if s.startswith("ALTER TABLE") or s.startswith("ALTER VIEW"):
            return False
    return True


def sanitize_one_line(s: str, max_len: int = 120) -> str:
    """Avoid breaking markdown tables: no newlines or pipe chars."""
    s = (s or "").replace("\r", " ").replace("\n", " ").replace("|", "/")
    s = " ".join(s.split())
    return s[:max_len]


def extract_uc_table(content: str) -> str | None:
    m = re.search(r"-- UC Target:\s*(main\.[\w.]+)", content)
    if m:
        return m.group(1).strip()
    m = re.search(r"ALTER TABLE\s+(main\.[\w.]+)\s", content)
    if m:
        return m.group(1).strip()
    return None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--batch-size", type=int, default=25)
    ap.add_argument("--deploy-batch", type=int, default=2)
    ap.add_argument(
        "--redo-batch",
        type=int,
        metavar="N",
        help="Reset rows 'Deployed (Batch N)' to Generated, then deploy only those objects",
    )
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Print each object as it starts/finishes (otherwise quiet until batch end)",
    )
    ap.add_argument(
        "--schema",
        default="DWH_dbo",
        help="Wiki folder under knowledge/synapse/Wiki/ (default: DWH_dbo)",
    )
    args = ap.parse_args()

    wiki = REPO / "knowledge" / "synapse" / "Wiki" / args.schema
    deploy_index = wiki / "_deploy-index.md"
    if not deploy_index.is_file():
        print(f"Missing deploy index: {deploy_index}", file=sys.stderr)
        sys.exit(1)

    batch: list[tuple[str, str]]
    if args.redo_batch is not None:
        idx_pre = deploy_index.read_text(encoding="utf-8")
        idx_new, batch = reset_deployed_batch_to_generated(
            idx_pre, args.redo_batch, args.schema
        )
        if not batch:
            print(f"No rows with Deployed (Batch {args.redo_batch}) in _deploy-index.md")
            sys.exit(1)
        n_reset = len(batch)
        if args.dry_run:
            print(
                f"[dry-run] Would reset {n_reset} objects from Deployed (Batch {args.redo_batch}) "
                "to Generated and update index metrics (no writes)."
            )
        else:
            dm = re.search(r"^deployed: (\d+)", idx_new, re.MULTILINE)
            gm = re.search(r"^generated: (\d+)", idx_new, re.MULTILINE)
            old_d = int(dm.group(1)) if dm else 0
            old_g = int(gm.group(1)) if gm else 0
            idx_out = idx_new
            idx_out = re.sub(
                r"^deployed: \d+",
                f"deployed: {max(0, old_d - n_reset)}",
                idx_out,
                count=1,
                flags=re.MULTILINE,
            )
            idx_out = re.sub(
                r"^generated: \d+",
                f"generated: {old_g + n_reset}",
                idx_out,
                count=1,
                flags=re.MULTILINE,
            )
            idx_out = re.sub(
                r"(\| \*\*Generated \(awaiting UC deploy\)\*\* \|) [^|]+(\|)",
                rf"\1 {old_g + n_reset} \2",
                idx_out,
                count=1,
            )
            idx_out = re.sub(
                r"(\| \*\*Deployed \(UC\)\*\* \|) [^|]+(\|)",
                rf"\1 {max(0, old_d - n_reset)} \2",
                idx_out,
                count=1,
            )
            deploy_index.write_text(idx_out, encoding="utf-8")
            print(f"Redo batch {args.redo_batch}: reset {n_reset} objects to Generated")
    else:
        generated = parse_generated_objects(deploy_index, args.schema)
        batch = generated[: args.batch_size]

    if not batch:
        print("No Generated objects in _deploy-index.md")
        sys.exit(0)

    gen_total = (
        len(parse_generated_objects(deploy_index, args.schema))
        if args.redo_batch is None
        else len(batch)
    )
    print(
        f"Resume deploy batch {args.deploy_batch}: {len(batch)} objects "
        f"(of {gen_total} Generated total)"
    )
    for n, f in batch[:8]:
        print(f"  {f}/{n}")
    if len(batch) > 8:
        print(f"  ... +{len(batch) - 8} more")

    if args.dry_run:
        sys.exit(0)

    from databricks import sql

    host = os.environ.get(
        "DATABRICKS_SERVER_HOSTNAME", "adb-5142916747090026.6.azuredatabricks.net"
    )
    http_path = os.environ.get(
        "DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/208214768b0e0308"
    )
    token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()

    if token:
        print("Auth: PAT (DATABRICKS_TOKEN)", flush=True)
        conn = sql.connect(
            server_hostname=host,
            http_path=http_path,
            access_token=token,
        )
    else:
        print("Auth: databricks-oauth (browser)", flush=True)
        conn = sql.connect(
            server_hostname=host,
            http_path=http_path,
            auth_type="databricks-oauth",
        )
    cur = conn.cursor()

    results: list[tuple[str, str, bool, str, int, int]] = []

    for i, (name, folder) in enumerate(batch, start=1):
        alter_path = wiki / folder / f"{name}.alter.sql"
        if args.verbose:
            print(f"[{i}/{len(batch)}] {folder}/{name} ...", flush=True)
        if not alter_path.is_file():
            results.append((name, folder, False, "missing .alter.sql", 0, 0))
            if args.verbose:
                print(f"    -> missing .alter.sql", flush=True)
            continue
        raw = alter_path.read_text(encoding="utf-8")
        if is_stub(raw):
            results.append((name, folder, True, "skipped stub", 0, 0))
            if args.verbose:
                print(f"    -> skip stub", flush=True)
            continue
        uc = extract_uc_table(raw)
        stmts = parse_statements(raw)
        if not stmts:
            results.append((name, folder, False, "no executable ALTER", 0, 0))
            if args.verbose:
                print(f"    -> no executable ALTER", flush=True)
            continue
        if uc:
            try:
                cur.execute(f"DESCRIBE TABLE {uc}")
                cur.fetchall()
            except Exception as e:
                results.append((name, folder, False, f"DESCRIBE: {sanitize_one_line(str(e), 400)}", 0, 0))
                if args.verbose:
                    print(f"    -> DESCRIBE failed", flush=True)
                continue
        ok, fail = 0, 0
        err_msg = ""
        for stmt in stmts:
            try:
                cur.execute(stmt)
                ok += 1
            except Exception as e:
                fail += 1
                err_msg = sanitize_one_line(str(e), max_len=500)
        success = fail == 0
        results.append((name, folder, success, err_msg if not success else "", ok, fail))
        if args.verbose:
            tag = "OK" if success else "FAIL"
            print(f"    -> {tag} {ok}/{ok + fail} statements", flush=True)

        ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
        footer_lines = [
            "",
            "-- == LAST EXECUTION ==",
            f"-- Timestamp: {ts}",
            f"-- Batch deploy resume: {args.schema} deploy batch {args.deploy_batch}",
            f"-- Statements: {ok}/{ok + fail} succeeded",
        ]
        if err_msg:
            footer_lines.append(f"-- Error: {err_msg}")
        footer_lines.append("-- ====================")
        alter_path.write_text(strip_footer(raw) + "\n" + "\n".join(footer_lines) + "\n", encoding="utf-8")

    cur.close()
    conn.close()

    ts_short = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    deployed_tag = f"Deployed (Batch {args.deploy_batch}) — {ts_short}"
    failed_prefix = f"Failed (deploy Batch {args.deploy_batch})"

    def recount_object_statuses(md: str) -> tuple[int, int, int]:
        """Count Generated / Deployed / Failed rows in object tables (source of truth)."""
        prefix = f"[{args.schema}."
        gen = dep = fail = 0
        for line in md.splitlines():
            if prefix not in line or not line.strip().startswith("|"):
                continue
            segs = line.split("|")
            if len(segs) < 4:
                continue
            st = segs[2].strip()
            if st == "Generated":
                gen += 1
            elif st.startswith("Deployed"):
                dep += 1
            elif st.startswith("Failed"):
                fail += 1
        return gen, dep, fail

    idx_text = deploy_index.read_text(encoding="utf-8")
    deployed_n = 0
    failed_n = 0

    for name, folder, success, msg, ok, fcnt in results:
        if msg == "skipped stub":
            continue
        link_re = re.escape(f"[{args.schema}.{name}]({folder}/{name}.md)")
        row_pat = re.compile(
            rf"^(\|\s*{link_re}\s*\|\s*)([^\|]+)(\|\s*)$",
            re.MULTILINE,
        )
        if success:
            new_status = deployed_tag
            deployed_n += 1
        else:
            esc = sanitize_one_line(msg or "error", max_len=120)
            new_status = f"{failed_prefix} — {esc}"
            failed_n += 1
        new_text, n_sub = row_pat.subn(
            lambda m, ns=new_status: m.group(1) + ns + m.group(3),
            idx_text,
            count=1,
        )
        if n_sub == 0:
            print(f"WARN: row not found for update: {name}", file=sys.stderr)
            continue
        idx_text = new_text

    # YAML + metrics from table body (avoids drift when frontmatter was stale)
    new_g, new_d, new_f = recount_object_statuses(idx_text)

    idx_text = re.sub(r"^deployed: \d+", f"deployed: {new_d}", idx_text, count=1, flags=re.MULTILINE)
    idx_text = re.sub(r"^generated: \d+", f"generated: {new_g}", idx_text, count=1, flags=re.MULTILINE)
    idx_text = re.sub(r"^failed: \d+", f"failed: {new_f}", idx_text, count=1, flags=re.MULTILINE)
    idx_text = re.sub(
        r"^last_deploy_batch: \d+",
        f"last_deploy_batch: {args.deploy_batch}",
        idx_text,
        count=1,
        flags=re.MULTILINE,
    )
    idx_text = re.sub(
        r'^last_updated: "[^"]+"',
        f'last_updated: "{ts_short}"',
        idx_text,
        count=1,
        flags=re.MULTILINE,
    )

    # Metrics table: allow variable spacing after leading |
    idx_text = re.sub(
        r"(\|\s+\*\*Generated \(awaiting UC deploy\)\*\*\s+\|)\s*[^|]+(\|)",
        rf"\1 {new_g}        \2",
        idx_text,
        count=1,
    )
    idx_text = re.sub(
        r"(\|\s+\*\*Deployed \(UC\)\*\*\s+\|)\s*[^|]+(\|)",
        rf"\1 {new_d}         \2",
        idx_text,
        count=1,
    )
    idx_text = re.sub(
        r"(\|\s+\*\*Failed\*\*\s+\|)\s*[^|]+(\|)",
        rf"\1 {new_f}         \2",
        idx_text,
        count=1,
    )
    idx_text = re.sub(
        r"(\|\s+\*\*Last deploy batch\*\*\s+\|)\s*[^|]+(\|)",
        rf"\1 {args.deploy_batch}          \2",
        idx_text,
        count=1,
    )

    deploy_index.write_text(idx_text, encoding="utf-8")

    print("\n=== RESULT ===")
    for name, folder, success, msg, ok, fcnt in results:
        if msg == "skipped stub":
            print(f"  [SKIP] {name}: stub")
        elif success:
            print(f"  [OK]   {name}: {ok} stmts")
        else:
            print(f"  [FAIL] {name}: {msg[:200]}")

    print(
        f"\nThis batch: deployed +{deployed_n}, failed +{failed_n}. "
        f"Index totals (from table): generated={new_g}, deployed={new_d}, failed={new_f}"
    )


if __name__ == "__main__":
    main()
