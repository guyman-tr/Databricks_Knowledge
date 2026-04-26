# Column Lineage: BI_DB_dbo.BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side` |
| **UC Target** | _Not_Migrated |
| **Primary Source** | `BI_DB_dbo.BI_DB_PositionPnL` (position-level PnL) |
| **ETL SP** | `SP_Finance_IFRS_Automation_KTCD_eToro_Side` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Fact_SnapshotCustomer`, `DWH_dbo.Dim_Country`, `DWH_dbo.Dim_Regulation`, `DWH_dbo.Dim_Position`, `DWH_dbo.Dim_Range` |
| **Generated** | 2026-04-26 |

## Lineage Chain

```
BI_DB_dbo.BI_DB_PositionPnL (position-level PnL for @dateID)
    │
    ├── JOIN DWH_dbo.Dim_Instrument di (instrument metadata, IFR segmentation)
    ├── JOIN DWH_dbo.Fact_SnapshotCustomer fsc (regulation, country, credit validity)
    ├── JOIN DWH_dbo.Dim_Range dr (date range resolution for snapshot)
    ├── JOIN DWH_dbo.Dim_Country dc (country name)
    ├── JOIN DWH_dbo.Dim_Regulation dr1 (regulation name)
    ├── LEFT JOIN DWH_dbo.Dim_Position dp (full commission for adjusted PnL)
    │
    └── SP_Finance_IFRS_Automation_KTCD_eToro_Side @Date
        ├── CTAS #IFRSegmentation (instrument-level supervisory factors & asset class mapping)
        ├── CTAS #pnlPrepPre (raw positions for @dateID)
        ├── CTAS #pnlPrep (enriched positions with regulation, country, adjusted PnL)
        ├── CTAS #ccrPrep (distinct CID+Instrument combinations)
        ├── CTAS #collect (per-position KTCD calculation: CMV, notional, PFE, collateral)
        ├── CTAS #collect1 (RC, effective notional, supervisory delta, own funds)
        ├── CTAS #collect2 (collateral value after adjustments recalculated)
        ├── CTAS #perTXFinalRecord (EV & own funds requirement per position)
        ├── CTAS #perAssetEtc (aggregated per instrument per regulation)
        ├── DELETE WHERE Date = @Date
        └── INSERT → BI_DB_dbo.BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side
              (6 UNION ALL segments: ReportA–ReportF by regulation grouping)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **aggregated** | SUM of per-position values grouped by regulation |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **hardcoded** | Literal value assigned in the SP |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| ReportID | — | — | hardcoded | 'ReportA' through 'ReportF' per UNION ALL segment | Identifies regulation grouping: A=CySEC/FCA/BVI, B=ASIC/GAML, C=FSA Seychelles, D=eToro Trading CIDs, E=FSRA, F=MAS |
| Date | — | — | ETL-computed | `@Date` SP parameter | Business date for the KTCD calculation |
| EV | #perAssetEtc | EV | aggregated | `SUM(CASE WHEN RC + PFE - Collateral < 0 THEN 0 ELSE RC + PFE - Collateral END)` | Exposure Value — floored at zero per position then summed |
| Own_Funds_Requirement | #perAssetEtc | Own Funds Requirement | aggregated | `SUM(1.2 * CVA * RF * EV)` where CVA=1 or 1.5 and RF=0.08 or 0.016 | K-factor capital requirement per CRR |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | SP execution timestamp |
| PFE | #perAssetEtc | PFE | aggregated | `SUM(Supervisory_Factor * Effective_Notional)` | Potential Future Exposure |
| RC | #perAssetEtc | RC | aggregated | `SUM(CMV)` where CMV = -1 * PositionPnL (or AdjustedPnLForRegulations for ASIC/GAML/Sey/FSRA/MAS) | Replacement Cost — negative PnL represents counterparty exposure |
| Collateral_Value_after_adjustments | #perAssetEtc | Collateral Value after adjustments | aggregated | CySEC/FCA/BVI: `(1 - CurrencyMismatch) * InvestedAmount`; others: `RC * (1 - CurrencyMismatch)` if RC > 0 else 0 | Collateral mitigation with 8% FX mismatch for non-USD |

## Summary

| Category | Count |
|----------|-------|
| **Hardcoded** | 1 |
| **ETL-computed** | 2 |
| **Aggregated** | 5 |
| **Total** | 8 |
