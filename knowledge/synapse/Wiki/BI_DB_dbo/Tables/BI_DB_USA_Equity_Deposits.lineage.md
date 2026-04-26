---
table: BI_DB_dbo.BI_DB_USA_Equity_Deposits
schema: BI_DB_dbo
type: lineage
generated_by: batch-37
---

# Lineage: BI_DB_USA_Equity_Deposits

## ETL Writer

| Property | Value |
|----------|-------|
| Stored Procedure | `BI_DB_dbo.SP_USA_Equity_Deposits` |
| Input Parameter | `@Date DATE` |
| ETL Pattern | DELETE WHERE DateID = @DateID, then INSERT from `#Pop_Full_Data_Agg` |
| OpsDB Priority | 20 (third wave — depends on P0 and P15 outputs) |
| Schedule | Daily · ProcessType=SQL · SB_Daily |
| SP Dependency | `BI_DB_dbo.SP_DDR` (writes BI_DB_DDR_CID_Level, now decommissioned) |

## Production Source Mapping

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| DateID | ETL parameter @Date | — | `CAST(CONVERT(CHAR(8), @Date, 112) AS INT)` |
| Date | ETL parameter @Date | — | Direct passthrough |
| RegulationName | `DWH_dbo.Dim_Regulation` | Name | Passthrough — filtered to `DWHRegulationID IN (6, 7, 8)` |
| CountryName | `DWH_dbo.Dim_Country` | Name | Passthrough via JOIN on `CountryID` |
| StateName | `DWH_dbo.Dim_State_and_Province` | Name | `CASE WHEN dc.CountryID = 219 THEN dsap.Name ELSE 'NULL' END` (LEFT JOIN on `RegionID = RegionByIP_ID`) |
| RealizedEquity | `DWH_dbo.V_Liabilities` | RealizedEquity | `SUM(ISNULL(..., 0))` — grouped by segment |
| TotalCash | `DWH_dbo.V_Liabilities` | TotalCash | `SUM(ISNULL(..., 0))` — grouped by segment |
| Total_FreeCreditBalance | `DWH_dbo.V_Liabilities` | Credit | `SUM(ISNULL(..., 0))` — renamed from `Credit` |
| Total_Deposits_Amount | `DWH_dbo.Fact_CustomerAction` | Amount | `SUM(ISNULL(Amount, 0)) WHERE ActionTypeID = 7` |
| Total_Deposits | `DWH_dbo.Fact_CustomerAction` | Amount | `COUNT(Amount >= 0) WHERE ActionTypeID = 7` |
| Total_Cashouts_Amount | `DWH_dbo.Fact_CustomerAction` | Amount | `SUM(ISNULL(Amount, 0)) WHERE ActionTypeID = 8` |
| Total_Cashouts | `DWH_dbo.Fact_CustomerAction` | Amount | `COUNT(Amount >= 0) WHERE ActionTypeID = 8` |
| Revenue | `BI_DB_dbo.BI_DB_DDR_CID_Level` | Revenue | `ISNULL(Revenue, 0)` — ⚠️ **DEPRECATED SOURCE** |
| UpdateDate | — | — | ETL-computed: `GETDATE()` |

## Population Filter

```sql
-- #Pop temp table: US-regulated active customers as of @Date
FROM DWH_dbo.Fact_SnapshotCustomer dc
  INNER JOIN DWH_dbo.Dim_Range dr ON dc.DateRangeID = dr.DateRangeID
    AND @DateID BETWEEN dr.FromDateID AND dr.ToDateID
  INNER JOIN DWH_dbo.Dim_Regulation dr1 ON dc.RegulationID = dr1.DWHRegulationID
  INNER JOIN DWH_dbo.Dim_Country dc1 ON dc.CountryID = dc1.CountryID
  LEFT JOIN DWH_dbo.Dim_State_and_Province dsap ON dc.RegionID = dsap.RegionByIP_ID
WHERE dc.RegulationID IN (6, 7, 8)   -- eToroUS, FinCEN, FinCEN+FINRA
  AND dr.ToDateID >= @DateID
```

## Aggregation Filter (HAVING)

Rows where the combined sum of equity + deposits + deposit count + revenue equals zero are excluded:

```sql
HAVING SUM(ISNULL(RealizedEquity, 0) + ISNULL(Total_Deposits_Amount, 0)
         + ISNULL(Total_Deposits, 0) + ISNULL(DDR_Revenue, 0)) > 0
```

Because `DDR_Revenue` is always 0 (deprecated source), this effectively filters out segments with no equity and no deposit activity on the date.

## ⚠️ Deprecated Column: Revenue

`Revenue` is sourced from `BI_DB_dbo.BI_DB_DDR_CID_Level`, which is permanently decommissioned (explicit blacklist entry in `dwh-semantic-doc-config.json`). The SP still references it via the `SP_DDR` dependency, but the decommissioned table produces no rows — Revenue is always 0. **Do not use Revenue in analytics.**

## Grain

One row per `DateID × RegulationName × CountryName × StateName`. US-regulated customers only.
Segments with zero equity and zero deposit activity on the date are excluded (HAVING filter).
