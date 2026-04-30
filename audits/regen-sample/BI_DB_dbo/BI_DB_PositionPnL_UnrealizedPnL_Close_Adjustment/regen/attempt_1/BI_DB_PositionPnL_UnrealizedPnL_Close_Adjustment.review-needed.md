# Review Needed: BI_DB_dbo.BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment

## Tier 5 Items

| Column | Current Tier | Question |
|--------|-------------|----------|
| IsSettled | Tier 5 — Expert Review | Inherited from Dim_Position wiki which marks IsSettled as Tier 5. The exact business definition of 1=real asset vs 0=CFD asset is understood, but the upstream wiki flags this for expert review. Confirm whether SettlementTypeID has fully replaced IsSettled in downstream logic. |

## Data Freshness Concern

- **Last DateID observed**: 20240706. The table appears to have stopped loading after July 2024. Verify whether this is intentional (table deprecated or replaced) or a load failure. A backup table `BI_DB_PositionPnL_UnrealizedPnL_Close_Adjustment_Backup_20241216` exists in SSDT, suggesting activity continued past the last observed data date.

## JOIN Semantics Clarification

- The SP uses an inner JOIN between prior-day `BI_DB_PositionPnL` and same-day `Dim_Position` (CloseDateID = @dateID). This means:
  - Positions that open and close on the same day (intraday trades) with no prior-day BI_DB_PositionPnL entry will NOT appear in this table.
  - Positions that were already excluded from BI_DB_PositionPnL (e.g., filtered out by the PositionPnL SP) will also be absent.
  - Confirm whether this is the intended behavior or if a LEFT/FULL OUTER JOIN was considered.

## No Downstream Consumers Found

- No SPs, views, or other objects in the SSDT repo reference this table (beyond its own writer SP). Confirm whether this table is consumed externally (e.g., Power BI, Python scripts, or ad-hoc queries) or if it is effectively dormant.
