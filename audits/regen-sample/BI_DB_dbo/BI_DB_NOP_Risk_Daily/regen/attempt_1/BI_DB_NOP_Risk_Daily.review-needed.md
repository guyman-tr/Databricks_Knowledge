# Review Needed: BI_DB_dbo.BI_DB_NOP_Risk_Daily

## 1. Stale Data

- **Last load date**: 2024-01-17 (UpdateDate). Most recent DateID is 20240116.
- **Action**: Confirm whether SP_NOP_TradingActivity_Risk_Daily is still actively scheduled. The table appears to have stopped receiving updates in January 2024. If deprecated, consider adding to blacklist.

## 2. IsSettled Tier Classification

- **IsSettled** is tagged Tier 5 (Expert Review), inherited from BI_DB_PositionPnL and ultimately Dim_Position. The upstream wikis describe it as "1 = real asset, 0 = CFD asset" but note it as expert-confirmed. Confirm this semantic is still accurate for the NOP context.

## 3. "Indecies" Typo

- The SP hardcodes `'Indecies'` (misspelling of "Indices") in the CASE statement for InstrumentTypeID=4. This is preserved as-is in the wiki. Confirm whether this is intentional or should be corrected in the SP.

## 4. UC Target Not Mapped

- No entry found in `_generic_pipeline_mapping.json` for this table. Confirm whether this table has a Databricks UC target or is Synapse-only.

## 5. Referenced By — Incomplete

- The "Referenced By" section lists only risk dashboards generically. A repo-wide grep for `BI_DB_NOP_Risk_Daily` would identify specific downstream consumers (SPs, views, reports).
