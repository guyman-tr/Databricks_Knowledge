# Review Needed: BI_DB_dbo.BI_DB_EY_Audit_ChangeLog

## Tier 4 Items Requiring Expert Review

### 1. ChangeTypeID Values (Tier 4)

- **ChangeTypeID=12** is labelled "Amount adjustment" based on SP code patterns in `SP_Dim_PositionChangeLog_DL_To_Synapse` and `SP_Dim_Position_DL_To_Synapse`. Confirm this is the official name.
- **ChangeTypeID=13** has no confirmed label. The SP applies IsSettled/unit backfill logic specifically for this type, suggesting it is settlement-related. Only ~12.9K rows exist (vs 85.95M for type 12). Expert should confirm the meaning.
- No official Dictionary or lookup table for ChangeTypeID exists in the DWH. If one exists in production (`etoro.Dictionary.*` or similar), this column could be upgraded to Tier 1.

## Tier 5 Items (Expert-Confirmed, Inherited)

### 2. IsSettled / PreviousIsSettled Semantics

- Descriptions inherited from Dim_PositionChangeLog Tier 5 (Expert Review): "1 = real asset, 0 = CFD asset."
- Both columns are NULL in ~85% of recent rows, meaning the change event did not involve settlement modification.
- Confirm that this interpretation remains accurate for the EY audit context.

## Questions for Domain Expert

### 3. Table Dormancy

- Data ends at 2025-10-27. The SP may no longer be scheduled in OpsDB. Confirm whether this table is still actively loaded or has been retired.

### 4. ChangeTypeID=13 Purpose

- Only 12,940 rows exist for ChangeTypeID=13 across the entire table (2023-2025). The SP applies specific NULL-backfill logic for PreviousAmountInUnits and AmountInUnits on this type. Is this a settlement status change event? Should these rows be distinguished in reporting?

### 5. EODPrice Formula

- The USD conversion logic mirrors the BI_DB_PositionPnL NOP calculation pattern. Confirm whether this is the correct price for EY audit purposes or whether a different price source (e.g., Close_CalculationRate from Dim_Position) would be more appropriate.

---

*Generated: 2026-04-29 | Object: BI_DB_dbo.BI_DB_EY_Audit_ChangeLog*
