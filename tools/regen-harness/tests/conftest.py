"""
Shared pytest fixtures for regen-harness tests.

Builds a self-contained mock SSDT + Wiki tree under a tmp_path and monkey-
patches preload_upstream's module-level path constants to point at it.
This lets us exercise the resolver / mirror-discovery / SP-scan logic
without touching the real DataPlatform / knowledge directories.
"""
from __future__ import annotations

import sys
from pathlib import Path

import pytest

# Make the parent dir importable so tests can `import preload_upstream`
HARNESS_ROOT = Path(__file__).resolve().parent.parent
if str(HARNESS_ROOT) not in sys.path:
    sys.path.insert(0, str(HARNESS_ROOT))


def _write_ddl(ssdt_root: Path, schema: str, table: str, columns: list[str]) -> Path:
    """Write a minimal CREATE TABLE DDL with the given column list."""
    body_lines = [f"    [{c}] [int] NOT NULL," for c in columns[:-1]]
    body_lines.append(f"    [{columns[-1]}] [int] NOT NULL")
    text = (
        f"CREATE TABLE [{schema}].[{table}]\n"
        f"(\n"
        + "\n".join(body_lines)
        + f"\n)\n"
        f"WITH (DISTRIBUTION = HASH ([{columns[0]}]));\n"
    )
    p = ssdt_root / schema / "Tables" / f"{schema}.{table}.sql"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding="utf-8")
    return p


def _write_wiki(wiki_root: Path, schema: str, table: str, body: str = "") -> Path:
    """Write a minimal Wiki .md file (Tables sub-dir)."""
    p = wiki_root / schema / "Tables" / f"{table}.md"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(body or f"# {schema}.{table}\n\nSample wiki body.\n", encoding="utf-8")
    return p


def _write_sp(ssdt_root: Path, schema: str, sp_name: str, body: str) -> Path:
    """Write an SP under SSDT/{schema}/Stored Procedures/."""
    p = ssdt_root / schema / "Stored Procedures" / f"{schema}.{sp_name}.sql"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(body, encoding="utf-8")
    return p


@pytest.fixture
def mock_tree(tmp_path, monkeypatch):
    """
    Build a tmp_path tree:

        tmp_path/
            DataPlatform/SynapseSQLPool1/sql_dp_prod_we/
                BI_DB_dbo/
                    Tables/             (DDLs)
                    Stored Procedures/  (SPs)
                Dealing_dbo/...
                eMoney_dbo/...
            knowledge/synapse/Wiki/
                BI_DB_dbo/Tables/       (wiki .md)
                Dealing_dbo/Tables/...
            audits/regen-sample/        (TARGET_ROOT for process_one)

    Returns a dict of helpers + roots so each test can populate what it needs.
    """
    ssdt_root = tmp_path / "DataPlatform" / "SynapseSQLPool1" / "sql_dp_prod_we"
    wiki_root = tmp_path / "knowledge" / "synapse" / "Wiki"
    target_root = tmp_path / "audits" / "regen-sample"
    ssdt_root.mkdir(parents=True)
    wiki_root.mkdir(parents=True)
    target_root.mkdir(parents=True)

    import preload_upstream as pu

    # Repoint every module-level path constant at the temp tree.
    monkeypatch.setattr(pu, "SSDT_ROOT", ssdt_root)
    monkeypatch.setattr(pu, "WIKI_ROOT", wiki_root)
    monkeypatch.setattr(pu, "TARGET_ROOT", target_root)
    monkeypatch.setattr(pu, "REPO_ROOT", tmp_path)
    monkeypatch.setattr(pu, "ROUTING_JSON", wiki_root / "_upstream_wiki_routing.json")

    return {
        "tmp": tmp_path,
        "ssdt": ssdt_root,
        "wiki": wiki_root,
        "targets": target_root,
        "pu": pu,
        "write_ddl": lambda schema, table, cols: _write_ddl(ssdt_root, schema, table, cols),
        "write_wiki": lambda schema, table, body="": _write_wiki(wiki_root, schema, table, body),
        "write_sp": lambda schema, name, body: _write_sp(ssdt_root, schema, name, body),
    }
