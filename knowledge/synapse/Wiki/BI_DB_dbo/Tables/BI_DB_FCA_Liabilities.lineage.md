# Lineage: BI_DB_dbo.BI_DB_FCA_Liabilities

Generated: 2026-04-22 | Phase 10B

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (SCD2 daily snapshot, IsValidCustomer/IsCreditReportValidCB/IsDepositor dims)
  + DWH_dbo.V_Liabilities (daily liabilities view, CID-level Liabilities/LiabilitiesCryptoReal)
  + DWH_dbo.Dim_Range (SCD2 range bridge: DateRangeID → current-date rows)
  + DWH_dbo.Dim_Regulation (DWHRegulationID=2 → 'FCA' name only)
    |-- SP_FCA_Liabilities @Date (daily, DELETE WHERE EOM + INSERT) ---|
    v
BI_DB_dbo.BI_DB_FCA_Liabilities (264 rows, Dec 2020 – Apr 2026, 4 rows/month)
  UC Target: Not Migrated
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | EOM | SP_FCA_Liabilities | @Date | EOMONTH(@Date, 0) — end of month for the run date | Tier 2 |
| 2 | Date | SP_FCA_Liabilities | @Date | Direct ETL parameter | Tier 2 |
| 3 | DateID | SP_FCA_Liabilities | @Date | CAST(CONVERT(CHAR(8), @Date, 112) AS INT) — YYYYMMDD | Tier 2 |
| 4 | Regulation | DWH_dbo.Dim_Regulation | Name | Filtered to DWHRegulationID=2 (always 'FCA') | Tier 2 |
| 5 | IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | GROUP BY dimension — passthrough | Tier 1 |
| 6 | IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | GROUP BY dimension — passthrough | Tier 1 |
| 7 | IsDepositor | DWH_dbo.Fact_SnapshotCustomer | IsDepositor | GROUP BY dimension — passthrough | Tier 1 |
| 8 | Total_CIDs | DWH_dbo.V_Liabilities | CID | COUNT(vl.CID) — customer count per segment | Tier 2 |
| 9 | Liabilities | DWH_dbo.V_Liabilities | Liabilities | SUM(ISNULL(vl.Liabilities, 0)) per segment | Tier 2 |
| 10 | LiabilitiesCryptoReal | DWH_dbo.V_Liabilities | LiabilitiesCryptoReal | SUM(ISNULL(vl.LiabilitiesCryptoReal, 0)) per segment | Tier 2 |
| 11 | Total_CIDs_Liabilities_Crypto_Only | SP_FCA_Liabilities | (derived) | CASE WHEN Liabilities - LiabilitiesCryptoReal = 0 THEN 1 → count of pure-crypto customers | Tier 2 |
| 12 | Liabilities_Crypto_Only | SP_FCA_Liabilities | (derived) | CASE WHEN Liabilities - LiabilitiesCryptoReal = 0 THEN LiabilitiesCryptoReal — liabilities of pure-crypto customers | Tier 2 |
| 13 | UpdateDate | SP_FCA_Liabilities | (ETL) | GETDATE() at insert | Tier 2 |

## Tier Summary

- **Tier 1**: 3 columns (IsValidCustomer, IsCreditReportValidCB, IsDepositor — from DWH_dbo.Fact_SnapshotCustomer)
- **Tier 2**: 10 columns (ETL-computed aggregations, date/dimension values)
- **UC Target**: Not Migrated

## Notes

- Table is FCA-only: SP_FCA_Liabilities filters `Dim_Regulation WHERE DWHRegulationID = 2` — `Regulation` column will always be 'FCA'.
- 4 rows per month: fixed combinations of (IsValidCustomer=0/1, IsCreditReportValidCB=0/1, IsDepositor=0/1) — in practice IsValidCustomer always equals IsCreditReportValidCB, yielding 4 distinct combinations.
- Liabilities are bigint (denominated in USD cents from V_Liabilities source).
- DELETE-per-EOM: SP deletes all rows for current month's EOM before re-inserting, enabling intra-month updates.
