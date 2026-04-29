"""
Regression suite for `preload_upstream.py`.

Pins the contracts of the deterministic-resolution layer so future edits
don't silently regress the bundle quality (which would silently regress
every wiki the writer produces). Every test that asserts on a discovered
mirror traces back to a specific past failure mode in the audit trail.
"""
from __future__ import annotations

from pathlib import Path

import pytest


# ───────────────────────────── split_identifier ─────────────────────────────


def test_split_identifier_three_part(mock_tree):
    pu = mock_tree["pu"]
    assert pu.split_identifier("etoro.Customer.CustomerStatic") == (
        "etoro", "Customer", "CustomerStatic"
    )


def test_split_identifier_two_part_synapse_schema(mock_tree):
    pu = mock_tree["pu"]
    assert pu.split_identifier("BI_DB_dbo.BI_DB_X") == (None, "BI_DB_dbo", "BI_DB_X")


def test_split_identifier_strips_brackets(mock_tree):
    pu = mock_tree["pu"]
    assert pu.split_identifier("[Dealing_dbo].[Dealing_X]") == (None, "Dealing_dbo", "Dealing_X")


def test_split_identifier_one_part(mock_tree):
    pu = mock_tree["pu"]
    assert pu.split_identifier("LonelyTable") == (None, None, "LonelyTable")


# ──────────────────────────── _extract_ddl_columns ──────────────────────────


def test_extract_ddl_columns_basic(mock_tree):
    pu = mock_tree["pu"]
    ddl = mock_tree["write_ddl"]("BI_DB_dbo", "BI_DB_T", ["A", "B", "C"])
    cols = pu._extract_ddl_columns(ddl)
    assert cols == {"a", "b", "c"}


def test_extract_ddl_columns_skips_constraint_lines(mock_tree, tmp_path):
    pu = mock_tree["pu"]
    p = tmp_path / "constraint.sql"
    p.write_text(
        "CREATE TABLE [s].[t]\n(\n"
        "    [Id] [int] NOT NULL,\n"
        "    [Name] [varchar](50) NULL,\n"
        "    CONSTRAINT [PK_t] PRIMARY KEY CLUSTERED ([Id])\n"
        ")\nWITH (DISTRIBUTION = HASH ([Id]));\n",
        encoding="utf-8",
    )
    cols = pu._extract_ddl_columns(p)
    assert cols == {"id", "name"}, "constraint line must not be misread as a column"


def test_extract_ddl_columns_strips_comments(mock_tree, tmp_path):
    pu = mock_tree["pu"]
    p = tmp_path / "comments.sql"
    p.write_text(
        "-- header comment with FAKECOL [int] NULL\n"
        "/* block /* comment */\n"
        "CREATE TABLE [s].[t]\n(\n"
        "    [RealCol] [int] NOT NULL\n"
        ")\nWITH (DISTRIBUTION = ROUND_ROBIN);\n",
        encoding="utf-8",
    )
    cols = pu._extract_ddl_columns(p)
    assert cols == {"realcol"}


def test_extract_ddl_columns_missing_file(mock_tree, tmp_path):
    pu = mock_tree["pu"]
    assert pu._extract_ddl_columns(None) == set()
    assert pu._extract_ddl_columns(tmp_path / "does_not_exist.sql") == set()


# ───────────────────────── find_migration_mirrors ───────────────────────────


def test_find_migration_mirrors_full_overlap_accepts(mock_tree):
    """The classic Phase 5 issue #1 case: BI_DB_X mirrors Dealing_X with
    identical column lists and Dealing has a wiki -> mirror discovered."""
    pu = mock_tree["pu"]
    cols = ["RepDate", "GCID", "InstrumentID", "Quantity", "OpenPositionValue"]
    mock_tree["write_ddl"]("BI_DB_dbo",   "BI_DB_DailyZeroPnL_Stocks",   cols)
    mock_tree["write_ddl"]("Dealing_dbo", "Dealing_DailyZeroPnL_Stocks", cols)
    mock_tree["write_wiki"]("Dealing_dbo", "Dealing_DailyZeroPnL_Stocks")
    mirrors = pu.find_migration_mirrors("BI_DB_dbo", "BI_DB_DailyZeroPnL_Stocks")
    assert mirrors == ["Dealing_dbo.Dealing_DailyZeroPnL_Stocks"]


def test_find_migration_mirrors_low_overlap_rejects(mock_tree):
    """Same base name but only 1/5 columns overlap -> NOT a mirror, rejected."""
    pu = mock_tree["pu"]
    mock_tree["write_ddl"]("BI_DB_dbo",   "BI_DB_AbuseAPI", ["A", "B", "C", "D", "E"])
    mock_tree["write_ddl"]("Dealing_dbo", "Dealing_AbuseAPI", ["A", "Q", "R", "S", "T"])
    mock_tree["write_wiki"]("Dealing_dbo", "Dealing_AbuseAPI")
    mirrors = pu.find_migration_mirrors("BI_DB_dbo", "BI_DB_AbuseAPI")
    assert mirrors == [], "1/5 overlap is below the 70% threshold"


def test_find_migration_mirrors_threshold_at_70_pct(mock_tree):
    """Boundary: 7/10 overlap is exactly 70% -> accepted (the implementation
    uses `< 0.7` for rejection, so 0.700 stays accepted)."""
    pu = mock_tree["pu"]
    cols_shared = ["A", "B", "C", "D", "E", "F", "G"]
    # mirror has 7 same + 3 diff -> overlap 7 / smaller(10,10) = 0.7 -> accepted
    # NB: base name must be >= 3 chars or short-base guard short-circuits to []
    mock_tree["write_ddl"]("BI_DB_dbo",   "BI_DB_Mirror_Sample",   cols_shared + ["X1", "X2", "X3"])
    mock_tree["write_ddl"]("Dealing_dbo", "Dealing_Mirror_Sample", cols_shared + ["Y1", "Y2", "Y3"])
    mock_tree["write_wiki"]("Dealing_dbo", "Dealing_Mirror_Sample")
    assert pu.find_migration_mirrors("BI_DB_dbo", "BI_DB_Mirror_Sample") == [
        "Dealing_dbo.Dealing_Mirror_Sample"
    ]


def test_find_migration_mirrors_short_base_via_one_char_obj(mock_tree):
    """Stripping the prefix yields a 1-char base ("T") -> short-base guard fires
    -> empty result. Documents the contract that mirror discovery requires a
    base name with semantic substance (>=3 chars)."""
    pu = mock_tree["pu"]
    cols = ["A", "B", "C", "D", "E"]
    mock_tree["write_ddl"]("BI_DB_dbo",   "BI_DB_T", cols)
    mock_tree["write_ddl"]("Dealing_dbo", "Dealing_T", cols)
    mock_tree["write_wiki"]("Dealing_dbo", "Dealing_T")
    assert pu.find_migration_mirrors("BI_DB_dbo", "BI_DB_T") == []


def test_find_migration_mirrors_no_sibling_wiki(mock_tree):
    """Mirror DDL exists but no wiki file -> not returned (we need the wiki content)."""
    pu = mock_tree["pu"]
    cols = ["A", "B", "C", "D"]
    mock_tree["write_ddl"]("BI_DB_dbo",   "BI_DB_Lonely", cols)
    mock_tree["write_ddl"]("Dealing_dbo", "Dealing_Lonely", cols)
    # ... but no wiki for Dealing_Lonely
    assert pu.find_migration_mirrors("BI_DB_dbo", "BI_DB_Lonely") == []


def test_find_migration_mirrors_unknown_self_schema(mock_tree):
    """Self-schema not in SCHEMA_TABLE_PREFIXES (e.g. DWH_dbo with mixed prefixes)
    -> base = obj as-is, attempts mirrors from prefixed schemas using full obj name."""
    pu = mock_tree["pu"]
    # DWH isn't in the prefix map; obj has no Dim_/Fact_ prefix to strip
    mock_tree["write_ddl"]("DWH_dbo",     "MysteryTable", ["A", "B", "C"])
    # No mirror should match the full name in any other schema
    assert pu.find_migration_mirrors("DWH_dbo", "MysteryTable") == []


def test_find_migration_mirrors_short_base_skipped(mock_tree):
    """Base name <3 chars -> skipped (avoids matching every "BI_DB_X" to noise)."""
    pu = mock_tree["pu"]
    mock_tree["write_ddl"]("BI_DB_dbo",   "BI_DB_X", ["A", "B", "C"])
    mock_tree["write_ddl"]("Dealing_dbo", "Dealing_X", ["A", "B", "C"])
    mock_tree["write_wiki"]("Dealing_dbo", "Dealing_X")
    assert pu.find_migration_mirrors("BI_DB_dbo", "BI_DB_X") == []


def test_find_migration_mirrors_too_few_self_columns_rejected(mock_tree):
    """Self DDL exists but has <3 columns -> mirror REJECTED outright (mode 2).
    Trivial Dim_X (Code, Description) tables would otherwise inflate overlap
    artificially across schemas; safer to skip the discovery entirely."""
    pu = mock_tree["pu"]
    mock_tree["write_ddl"]("BI_DB_dbo",   "BI_DB_TwoCol", ["A", "B"])
    mock_tree["write_ddl"]("Dealing_dbo", "Dealing_TwoCol", ["A", "B"])
    mock_tree["write_wiki"]("Dealing_dbo", "Dealing_TwoCol")
    assert pu.find_migration_mirrors("BI_DB_dbo", "BI_DB_TwoCol") == []


def test_find_migration_mirrors_finds_multiple(mock_tree):
    """One self-table can mirror BOTH Dealing AND eMoney variants."""
    pu = mock_tree["pu"]
    cols = ["RepDate", "GCID", "Amount", "Currency", "Status"]
    mock_tree["write_ddl"]("BI_DB_dbo",   "BI_DB_Deposits",   cols)
    mock_tree["write_ddl"]("Dealing_dbo", "Dealing_Deposits", cols)
    mock_tree["write_ddl"]("eMoney_dbo",  "eMoney_Deposits",  cols)
    mock_tree["write_wiki"]("Dealing_dbo", "Dealing_Deposits")
    mock_tree["write_wiki"]("eMoney_dbo",  "eMoney_Deposits")
    mirrors = sorted(pu.find_migration_mirrors("BI_DB_dbo", "BI_DB_Deposits"))
    assert mirrors == [
        "Dealing_dbo.Dealing_Deposits",
        "eMoney_dbo.eMoney_Deposits",
    ]


def test_find_migration_mirrors_no_self_ddl_falls_back_to_name_match(mock_tree):
    """When self DDL is missing, still accept mirror on name match alone (low risk)."""
    pu = mock_tree["pu"]
    # No self DDL written
    mock_tree["write_ddl"]("Dealing_dbo", "Dealing_Phantom", ["A", "B", "C", "D"])
    mock_tree["write_wiki"]("Dealing_dbo", "Dealing_Phantom")
    mirrors = pu.find_migration_mirrors("BI_DB_dbo", "BI_DB_Phantom")
    assert mirrors == ["Dealing_dbo.Dealing_Phantom"], (
        "Without self DDL we trust the name match — better to over-include than "
        "miss a real mirror."
    )


# ────────────────────────── discover_writer_sps ─────────────────────────────


def test_discover_writer_sps_finds_insert(mock_tree):
    pu = mock_tree["pu"]
    mock_tree["write_sp"](
        "BI_DB_dbo", "SP_BI_DB_Loads",
        "INSERT INTO [BI_DB_dbo].[BI_DB_T] (a, b) SELECT a, b FROM upstream;",
    )
    sps = pu.discover_writer_sps("BI_DB_dbo", "BI_DB_T")
    assert len(sps) == 1
    assert sps[0].name == "BI_DB_dbo.SP_BI_DB_Loads.sql"


def test_discover_writer_sps_finds_merge_and_truncate(mock_tree):
    pu = mock_tree["pu"]
    mock_tree["write_sp"](
        "BI_DB_dbo", "SP_Merge",
        "MERGE INTO [BI_DB_dbo].[BI_DB_M] AS tgt USING src AS s ON tgt.k = s.k;",
    )
    mock_tree["write_sp"](
        "BI_DB_dbo", "SP_Trunc",
        "TRUNCATE TABLE [BI_DB_dbo].[BI_DB_M]; SELECT 1;",
    )
    sps = pu.discover_writer_sps("BI_DB_dbo", "BI_DB_M")
    names = sorted(p.name for p in sps)
    assert names == ["BI_DB_dbo.SP_Merge.sql", "BI_DB_dbo.SP_Trunc.sql"]


def test_discover_writer_sps_skips_non_writers(mock_tree):
    pu = mock_tree["pu"]
    mock_tree["write_sp"](
        "BI_DB_dbo", "SP_Reads",
        "SELECT * FROM [BI_DB_dbo].[BI_DB_T] WHERE a = 1;",
    )
    assert pu.discover_writer_sps("BI_DB_dbo", "BI_DB_T") == []


def test_discover_writer_sps_handles_unbracketed(mock_tree):
    pu = mock_tree["pu"]
    mock_tree["write_sp"](
        "BI_DB_dbo", "SP_Unbracketed",
        "INSERT INTO BI_DB_dbo.BI_DB_T SELECT * FROM src;",
    )
    sps = pu.discover_writer_sps("BI_DB_dbo", "BI_DB_T")
    assert len(sps) == 1


# ───────────────────────── parse_sp_join_sources ────────────────────────────


def test_parse_sp_join_sources_collects_from_and_join(mock_tree):
    pu = mock_tree["pu"]
    sp = mock_tree["write_sp"](
        "BI_DB_dbo", "SP_X",
        "INSERT INTO [BI_DB_dbo].[BI_DB_T]\n"
        "SELECT a, b\n"
        "FROM [DWH_dbo].[Dim_Customer] c\n"
        "JOIN [Dealing_dbo].[Dealing_PnL] p ON p.CID = c.CID\n"
        "LEFT JOIN #temp_local t ON t.k = p.k\n"
        "INNER JOIN @tvp_var v ON v.id = c.id;",
    )
    sources = pu.parse_sp_join_sources(sp)
    assert "DWH_dbo.Dim_Customer" in sources
    assert "Dealing_dbo.Dealing_PnL" in sources
    assert all("#temp" not in s for s in sources), "temp tables must be skipped"
    assert all(not s.startswith("@") for s in sources), "table variables must be skipped"


def test_parse_sp_join_sources_skips_block_comments(mock_tree):
    pu = mock_tree["pu"]
    sp = mock_tree["write_sp"](
        "BI_DB_dbo", "SP_Comments",
        "INSERT INTO [BI_DB_dbo].[BI_DB_T]\n"
        "SELECT * FROM [Real_dbo].[RealTable] r\n"
        "/* dead code: FROM [Fake_dbo].[FakeTable] f */\n"
        "WHERE r.x = 1;",
    )
    sources = pu.parse_sp_join_sources(sp)
    assert "Real_dbo.RealTable" in sources
    assert "Fake_dbo.FakeTable" not in sources


# ──────────────────────────────── resolve_one ───────────────────────────────


def test_resolve_one_synapse_local(mock_tree):
    pu = mock_tree["pu"]
    mock_tree["write_wiki"]("BI_DB_dbo", "BI_DB_X")
    r = pu.resolve_one("BI_DB_dbo.BI_DB_X", routing={})
    assert r.kind == "synapse"
    assert r.schema == "BI_DB_dbo"
    assert r.object == "BI_DB_X"
    assert r.wiki_path is not None
    assert "BI_DB_X.md" in r.wiki_path


def test_resolve_one_unknown_returns_unresolved(mock_tree):
    pu = mock_tree["pu"]
    r = pu.resolve_one("Mystery_dbo.MysteryT", routing={})
    assert r.kind == "unresolved"


def test_resolve_one_sp_kind_when_sp_exists(mock_tree):
    pu = mock_tree["pu"]
    mock_tree["write_sp"]("BI_DB_dbo", "SP_HereIAm", "SELECT 1")
    r = pu.resolve_one("BI_DB_dbo.SP_HereIAm", routing={})
    assert r.kind == "synapse_sp"
    assert r.sp_path is not None


def test_resolve_one_schemaless_search_finds_wiki(mock_tree):
    """Bare object name (no schema) -> resolver tries every Synapse schema."""
    pu = mock_tree["pu"]
    mock_tree["write_wiki"]("Dealing_dbo", "Dealing_Solo")
    r = pu.resolve_one("Dealing_Solo", routing={})
    assert r.kind == "synapse"
    assert r.schema == "Dealing_dbo"


# ───────────────────── looks_like_sp / find_synapse_sp ──────────────────────


@pytest.mark.parametrize("name,expected", [
    ("SP_DailyZero",   True),
    ("usp_X",          True),
    ("proc_load",      True),
    ("uspUp_load",     True),
    ("Dim_Customer",   False),
    ("",               False),
    ("Fact_Trades",    False),
])
def test_looks_like_sp(mock_tree, name, expected):
    pu = mock_tree["pu"]
    assert pu.looks_like_sp(name) is expected


def test_find_synapse_sp_handles_alt_dirname(mock_tree):
    """SSDT exports can use 'Stored Procedures' or 'StoredProcedures' (no space)."""
    pu = mock_tree["pu"]
    # Write under the no-space variant directly
    p = mock_tree["ssdt"] / "BI_DB_dbo" / "StoredProcedures" / "BI_DB_dbo.SP_AltDir.sql"
    p.parent.mkdir(parents=True)
    p.write_text("SELECT 1", encoding="utf-8")
    found = pu.find_synapse_sp("BI_DB_dbo", "SP_AltDir")
    assert found is not None
    assert found.name == "BI_DB_dbo.SP_AltDir.sql"
