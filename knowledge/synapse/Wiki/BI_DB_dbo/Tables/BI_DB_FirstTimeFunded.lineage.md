# BI_DB_dbo.BI_DB_FirstTimeFunded — Column Lineage

Generated: 2026-04-21 | Pipeline: Phase 10B

## Source Objects

| Source Type | Object | Role |
|-------------|--------|------|
| DWH Fact Table | DWH_dbo.Fact_SnapshotCustomer | Customer verification status + deposit flag per day |
| DWH Dimension | DWH_dbo.Dim_Range | Maps DateRangeID to FromDateID |
| DWH Dimension | DWH_dbo.Dim_Date | Resolves DateKey to calendar date |
| DWH Dimension | DWH_dbo.Dim_Position | First trade date per customer (MIN OpenDateID) |
| ETL Writer | BI_DB_dbo.SP_FirstTimeFunded | Computes the FTF milestone and loads this table |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough — group-by key in all three sub-queries. Original source: Customer.CustomerStatic | Tier 1 |
| 2 | FirstTimeFundedDateID | DWH_dbo.Dim_Date + Dim_Position | DateKey / OpenDateID | ETL-computed: MAX(first_deposit_datekey, first_traded_datekey, first_verified_datekey) where all three are non-null. The date is the LAST of the three first-event dates. | Tier 2 |
| 3 | FirstTimeFundedDate | — | — | ETL-computed: CONVERT(date, CONVERT(varchar(10), MaxDate)) — human-readable equivalent of FirstTimeFundedDateID | Tier 2 |
| 4 | UpdateDate | — | — | GETDATE() at TRUNCATE+INSERT time. Reflects when SP_FirstTimeFunded last ran. | Tier 2 |

## FTF Milestone Logic

The three criteria for FirstTimeFunded (all must be met):

| # | Criterion | Source | SP Logic |
|---|-----------|--------|----------|
| 1 | KYC Verified | Fact_SnapshotCustomer.VerificationLevelID = 3 | MIN DateKey where VerificationLevelID = 3 per RealCID |
| 2 | First Deposit | Fact_SnapshotCustomer.IsDepositor = 1 | MIN DateKey where IsDepositor = 1 per RealCID |
| 3 | First Trade | Dim_Position.OpenDateID | MIN OpenDateID per CID |

`HAVING COUNT(RealCID) = 3` — all three must be non-null. `FirstTimeFundedDateID = MAX(first_deposit, first_traded, first_verified)` — the date the LAST criterion was satisfied.

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer  ──────────────────────────┐
  + DWH_dbo.Dim_Range + Dim_Date                          │ (verified + depositor dates)
  MIN(date WHERE VerificationLevelID=3) → #firstVerified   │
  MIN(date WHERE IsDepositor=1)         → #firstDeposited  │
                                                           ├─→ #all (UNION ALL)
DWH_dbo.Dim_Position                                       │
  MIN(OpenDateID) per CID               → #firstTraded     │
                                                           │
#all GROUP BY RealCID HAVING COUNT=3                       │
  MAX(first_deposit) AS MaxDate         → #ftf             │
  (only new CIDs not yet in target)                        │
                                                           │
TRUNCATE + INSERT INTO BI_DB_dbo.BI_DB_FirstTimeFunded ◄──┘
  (since SR-295058: full reload with ROW_NUMBER dedup)
    ↓
(consumed by SP_DDR as FTFDate join for DDR_CID_Level + DDR_Daily_Aggregated)
```

## UC External Lineage

UC Target: Not in generic pipeline mapping. No Databricks Gold layer target identified.
