---
table: BI_DB_dbo.BI_DB_User_Segment_Snapshot
schema: BI_DB_dbo
type: lineage
generated_by: batch-37
---

# Lineage: BI_DB_User_Segment_Snapshot

## ETL Writer

| Property | Value |
|----------|-------|
| Stored Procedure | `BI_DB_dbo.SP_User_Segment_Snapshot` |
| Input Parameter | `@Yesterday DateTime` |
| ETL Pattern | DELETE WHERE Date = @Date, then INSERT |
| Monthly Extension | End-of-month UPDATE to `ActivitySegment` only |
| OpsDB Priority | 20 (third wave — depends on P0 and P15 outputs) |
| Schedule | Daily · ProcessType=SQL · SB_Daily |
| SP Dependency | `BI_DB_dbo.SP_DailyCommisionReport` (for monthly ActivitySegment update) |

## Intermediate Tables Written by Same SP

This SP also writes three staging/snapshot tables used to build the final output:

| Table | Purpose |
|-------|---------|
| `BI_DB_dbo.BI_DB_EquitySnapshots` | Daily equity snapshot per CID (DateID, CID, RealizedEquity) — sourced from `DWH_dbo.Fact_SnapshotEquity` |
| `BI_DB_dbo.BI_DB_STDSnapshots` | Daily standard deviation per CID (DateID, CID, PositionPnL, StandardDeviation) — sourced from `DWH_dbo.Fact_CustomerUnrealized_PnL` |
| `BI_DB_dbo.BI_DB_DepositSnapshots` | Daily deposit amounts per CID (DateID, CID, TotalDeposit) — sourced from `DWH_dbo.Fact_CustomerAction WHERE ActionTypeID=7` |

## Production Source Mapping

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| Date | ETL parameter @Yesterday | — | `CONVERT(VARCHAR, @Yesterday, 112)` as INT |
| RealCID | `#ABCModelCID` (from `BI_DB_EquitySnapshots` + `BI_DB_STDSnapshots`) | CID | Direct — only CIDs with `RealizedEquity + PositionPnL >= 50` AND deposits |
| RiskIndex | ABC model: weighted AvgSTD from `BI_DB_EquitySnapshots` + `BI_DB_STDSnapshots` | RealizedEquity × StandardDeviation | `CASE WHEN AvgSTD < 0.0011 THEN 1 ... WHEN AvgSTD >= 0.0475 THEN 10` — ISNULL to 0 |
| LTDeposit | `BI_DB_DepositSnapshots` (→ `DWH_dbo.Fact_CustomerAction ActionTypeID=7`) | TotalDeposit | `SUM(TotalDeposit) WHERE DateID <= @Date` — cumulative lifetime |
| RiskGroup | Derived from RiskIndex | — | `CASE: <=3→'A', <=7→'B', >7→'C'` |
| DepositGroup | Derived from LTDeposit | — | `CASE: 0→'ND', <=500→'Low', <=5000→'Mid', >5000→'High'` |
| ActivitySegment | Previous day's `BI_DB_User_Segment_Snapshot.ActivitySegment` (daily carry-forward) | ActivitySegment | Daily: carry-forward from `Date = @BeforeYesterdayINT`. End-of-month: UPDATE from commission + equity + position analysis |
| UpdateDate | — | — | `GETDATE()` |

## ABC Risk Model Computation

```sql
-- Step 1: Qualifying population (equity >= $50 AND has STD measurement)
#pre2 = BI_DB_EquitySnapshots JOIN BI_DB_STDSnapshots
  WHERE RealizedEquity + ISNULL(PositionPnL,0) >= 50

-- Step 2: Weighted-average standard deviation per CID across all qualifying dates
#ABCModel:
  AvgSTD = CASE WHEN SUM(RealizedEquity) > 0
           THEN SUM(RealizedEquity * StandardDeviation) / SUM(RealizedEquity)
           ELSE 0 END

-- Step 3: Map AvgSTD to RiskIndex (1=lowest, 10=highest)
#ABCModelCID:
  RiskIndex = CASE WHEN AvgSTD < 0.0011 THEN 1
                   WHEN AvgSTD < 0.0024 THEN 2
                   WHEN AvgSTD < 0.004  THEN 3
                   WHEN AvgSTD < 0.0055 THEN 4
                   WHEN AvgSTD < 0.0079 THEN 5
                   WHEN AvgSTD < 0.0111 THEN 6
                   WHEN AvgSTD < 0.0158 THEN 7
                   WHEN AvgSTD < 0.0316 THEN 8
                   WHEN AvgSTD < 0.0475 THEN 9
                   WHEN AvgSTD >= 0.0475 THEN 10
```

## ActivitySegment Monthly Update Logic

Runs only on the last day of the month (`IF @Yesterday = EOMONTH(@Yesterday)`):

```
Sources: BI_DB_DailyCommisionReport (6-month window) + Fact_SnapshotEquity (last month avg) + Dim_Position (last month FX)

Segment rules (priority order):
  1. AllComm = 0 AND SumAllAmount != 0:
     - AvgDailyCrypto / SumAllAmount >= 0.6 → 'Crypto'
     - else → 'Investor'
  2. AllComm != 0 AND SumAllAmount != 0:
     - CryptoComm / AllComm >= 0.8 → 'Crypto'
     - FxComm / AllComm >= 0.5 → 'Trader'
     - else: apply same crypto/investor split as rule 1
  3. AllComm = 0 AND SumAllAmount = 0 → excluded (no UPDATE)
```

## Population Filter

Only customers satisfying ALL of the following appear in the output:
1. Appeared in `#ABCModelCID` (had RealizedEquity + PositionPnL >= $50 and a StandardDeviation on at least one qualifying date)
2. Have at least one deposit record in `BI_DB_DepositSnapshots` (`WHERE D.CID IS NOT NULL`)

Customers with zero equity or no deposits are excluded.

## Grain

One row per `Date × RealCID`. HASH distributed on `RealCID`, CLUSTERED INDEX on `(Date, RealCID)`.
