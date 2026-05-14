# Preflight report — UC ALTER deployment queue

- **Run date:** 2026-05-14
- **Mode:** DRY-RUN (no writes)
- **Files scanned:** 249
- **Files that would be auto-fixed:** 4
- **Files BLOCKED:** 0

Blocks = encoding errors, prose-as-target, bogus `Tier N` as column,
unterminated COMMENT literal, or missing `;`. Auto-fixes = mojibake / unicode
punctuation normalization and backtick-wrapping of unsafe column tokens.

## Would auto-fix files

### `knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_Client_Balance_CID_Level_New.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PlayerStatus.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotEquity.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

### `knowledge/synapse/Wiki/DWH_dbo/Views/V_Fact_SnapshotEquity_FromDateID.alter.sql`

- **Mojibake / keyword**: 1 fix(es)

## Clean files: 245
