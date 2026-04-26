# Lineage: BI_DB_dbo.BI_DB_CMR_Phase2_CycleGap

**Writer SP**: `BI_DB_dbo.SP_CMR_Phase2_CycleGap`
**Refresh**: Daily (OpsDB Priority 15). Takes @date parameter; processes one date per execution.
**Load Pattern**: DELETE WHERE Date = @date + INSERT (daily full-refresh per date)
**UC Target**: _Not_Migrated

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | DateID | BI_DB_dbo.BI_DB_CB_CycleGap_Categorization | DateID | Passthrough from source group key | Tier 2 |
| 2 | Date | ETL-derived | DateID | `CONVERT(date, convert(varchar(10), DateID))` -- derived from DateID | Tier 2 |
| 3 | GapCategory | ETL-hardcoded | -- | Hardcoded string per UNION branch: 'As per Cycle Gap' (OutlierTransition = '0') or 'As per Outliers' (OutlierTransition <> '0') | Tier 2 |
| 4 | Regulation | ETL-hardcoded | -- | Hardcoded group label: 'ASIC' (source Regulation IN 'ASIC','ASIC & GAML') or 'EU' (source Regulation IN 'CySEC','BVI','NFA','None') | Tier 2 |
| 5 | Gap | BI_DB_dbo.BI_DB_CB_CycleGap_Categorization | OutlierCycleCalculation, ClosingBalance, CycleCalculation | `SUM(CASE WHEN OutlierCycleCalculation <> 0 THEN OutlierCycleCalculation ELSE ClosingBalance - CycleCalculation END)` per ASIC/EU group | Tier 2 |
| 6 | UpdateDate | ETL-computed | -- | GETDATE() on INSERT | Propagation |

## Tier Summary

| Tier | Count | Description |
|------|-------|-------------|
| Tier 2 | 5 | All data columns from BI_DB_CB_CycleGap_Categorization or hardcoded in SP |
| Propagation | 1 | UpdateDate (ETL GETDATE() on insert) |

## Source Objects

- `BI_DB_dbo.BI_DB_CB_CycleGap_Categorization` -- sole data source; provides CID-level cycle gap, outlier, and closing balance data per date

## SP Logic Notes

- 4 UNION branches producing (GapCategory x Regulation) combinations
- Self-join on CBCGC: `a.DailyCBGap = -b.DailyCBGap` to identify offsetting gaps between dates
- 'As per Cycle Gap' filter: `OutlierTransition = '0' AND IsCreditReportValidCB = 1`
- 'As per Outliers' filter: `OutlierTransition <> '0'` (no IsCreditReportValidCB filter)
- ASIC branch: Regulation IN ('ASIC', 'ASIC & GAML')
- EU branch: Regulation IN ('CySEC', 'BVI', 'NFA', 'None')

## ETL Pipeline

```
BI_DB_dbo.BI_DB_CB_CycleGap_Categorization (DateID = @dateID)
  SELF-JOIN on CID where DailyCBGap = -DailyCBGap (offsetting gap detection)
  4 UNION branches split by Regulation group (ASIC/EU) and GapCategory type (Cycle/Outlier)
  SUM(Cycle Gap formula) per DateID group

SP_CMR_Phase2_CycleGap(@date) -- daily execution
  DELETE FROM BI_DB_CMR_Phase2_CycleGap WHERE Date = @date
  INSERT INTO BI_DB_dbo.BI_DB_CMR_Phase2_CycleGap
      (1,209 rows; 927 dates: 2022-01-03 to 2026-04-10)
  UC: _Not_Migrated
```
