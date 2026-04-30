# Review Needed: BI_DB_dbo.BI_DB_NOP_Risk_Daily

## 1. Typo Preservation

- **InstrumentType value 'Indecies'**: The SP uses the spelling 'Indecies' (typo for 'Indices'). Preserved as-is in documentation since downstream consumers may filter on this exact string. Confirm if this should be corrected in the SP.

## 2. Data Staleness

- **Max DateID = 20240116**: The most recent data is from January 2024. The SP may not be running currently or the table may have been superseded. Confirm whether this table is still actively refreshed.

## 3. UC Migration

- **No UC target found**: This table is not in `_generic_pipeline_mapping.json`. Confirm whether migration to Unity Catalog is planned.

## 4. InstrumentDisplayName Width

- **DDL declares varchar(200)** but the upstream source (Dim_Instrument.InstrumentDisplayName) is varchar(100). The wider column in the target is safe (no truncation risk) but the discrepancy may indicate a planned schema change or oversight.

## 5. Rolling Window Scope

- **1-month retention only**: The SP purges rows older than 1 month. If longer historical NOP analysis is needed, a separate archive or the upstream BI_DB_PositionPnL table must be queried. Confirm this retention policy is intentional.
