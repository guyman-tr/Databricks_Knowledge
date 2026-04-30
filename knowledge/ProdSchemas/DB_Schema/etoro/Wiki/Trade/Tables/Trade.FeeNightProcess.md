# Trade.FeeNightProcess

> Working table for nightly fee calculation batch jobs; holds positions and calculated fee data during overnight/weekend processing. Truncated after each run.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | CID, PositionID, PartitionCol (composite PK) |
| **Partition** | PS_PositionTbl(PartitionCol), PartitionCol = CID % 10 |
| **Indexes** | 2 (PK nonclustered, IX_StatusID) |

---

## 1. Business Meaning

**WHAT**: Trade.FeeNightProcess is a transient working table that holds positions eligible for overnight or weekend fee charges, along with pre-calculated fee amounts, during the nightly fee batch. Trade.GetPositionsForFeeProcess populates it via Trade.SYN_FeeNightProcess (synonym to FeesProcess database); Trade.PayForFeeProcess consumes rows partition-by-partition, deducting fees and updating StatusID. Failed rows (StatusID=-1) are copied to History.FeeNightProcessFail before Trade.TruncateFeeNightProcess clears the table for the next run.

**WHY**: The fee process runs once per night (after New York close). It identifies open positions, calculates fees using Trade.InstrumentToFeeConfigV2 and Trade.CalculatePositionOvernightFee, and charges customers. Staging in a table allows partition-parallel processing (PayForFeeProcess runs per PartitionCol) and error isolation. Truncation keeps the table empty between runs.

**HOW**: GetPositionsForFeeProcess: (1) Truncates via SYN_TruncateFeeNightProcess, (2) selects eligible positions, (3) calculates FeeInDollars via CalculatePositionOvernightFee, (4) inserts into SYN_FeeNightProcess with StatusID=0. Trade.SYN_ExecuteAllFeeJobs invokes PayForFeeProcess for each partition. PayForFeeProcess reads StatusID=0 rows, applies fees, sets StatusID=1 (success) or -1 (error with ErrorMessage). If any StatusID=-1, rows are copied to History.FeeNightProcessFail and RAISERROR is thrown.

---

## 2. Business Logic

### 2.1 StatusID and Fee

StatusID: 0=pending (not yet charged), 1=success (fee applied), -1=error (ErrorMessage set, row copied to History.FeeNightProcessFail). Fee: 1=overnight fee, 2=weekend fee. IsBuy: 1=long, 0=short.

### 2.2 Partitioning

PartitionCol = CID % 10 (computed, persisted). PayForFeeProcess is called with @Partition 0..9. Each partition processes its rows independently for parallelism.

### 2.3 Lifecycle

Populate (GetPositionsForFeeProcess) -> Process (PayForFeeProcess per partition) -> On error: copy to History.FeeNightProcessFail -> Truncate (TruncateFeeNightProcess) before next run.

---

## 3. Data Overview

| PositionID | CID | PartitionCol | IsBuy | FeeInDollars | EndOfWeekFee | Amount | StatusID | Fee |
|-----------|-----|--------------|-------|--------------|--------------|--------|----------|-----|
| 2152357309 | 3739190 | 0 | 1 | 0.53 | 2.65 | 3000 | 1 | 1 |
| 2152358279 | 3739190 | 0 | 1 | 0.53 | 2.65 | 3000 | 1 | 1 |
| 2152358281 | 3739190 | 0 | 1 | 0.53 | 2.65 | 3000 | 1 | 1 |
| 2152358321 | 3739190 | 0 | 1 | 0.53 | 2.65 | 3000 | 1 | 1 |
| 2152358341 | 3739190 | 0 | 1 | 0.65 | 3.25 | 1190 | 1 | 1 |

StatusID=1 (processed). Fee=1 (overnight). Table typically empty between runs; data shown from mid-run state.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | VERIFIED | FK to Trade.PositionTbl. |
| 2 | CID | int | NO | - | VERIFIED | Customer ID. |
| 3 | PartitionCol | int | NO | (computed) | VERIFIED | CID % 10; used for partition key. |
| 4 | IsBuy | bit | NO | - | VERIFIED | 1=long, 0=short. |
| 5 | MirrorID | int | YES | - | CODE-BACKED | Mirror position; for mirror credit. |
| 6 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent for split/partial positions. |
| 7 | FeeInDollars | decimal(38,7) | YES | - | VERIFIED | Calculated fee amount. |
| 8 | EndOfWeekFee | money | NO | - | CODE-BACKED | End-of-week fee threshold/rate. |
| 9 | Amount | money | NO | - | CODE-BACKED | Position amount for fee context. |
| 10 | CustomerCredit | money | YES | - | CODE-BACKED | Customer credit for fee deduction. |
| 11 | MirrorCredit | decimal(16,8) | YES | - | CODE-BACKED | Mirror credit amount. |
| 12 | IsActive | tinyint | NO | - | CODE-BACKED | Mirror active flag. |
| 13 | Fee | tinyint | YES | - | VERIFIED | 1=overnight, 2=weekend. |
| 14 | ErrorMessage | varchar(500) | YES | - | VERIFIED | Set when StatusID=-1. |
| 15 | StatusID | int | YES | - | VERIFIED | 0=pending, 1=success, -1=error. |

---

## 5. Relationships

### 5.1 References To

| Referenced Object | Key | Relationship |
|------------------|-----|--------------|
| Trade.PositionTbl | PositionID | Position being charged |
| Customer.Customer | CID | Customer being charged |
| Trade.Mirror | MirrorID | Mirror position credit |

### 5.2 Referenced By

| Object | Usage |
|--------|-------|
| Trade.GetPositionsForFeeProcess | Inserts via SYN_FeeNightProcess |
| Trade.PayForFeeProcess | Reads StatusID=0; updates StatusID |
| Trade.TruncateFeeNightProcess | TRUNCATE |
| Trade.ExecuteAllFeeJobs | Invokes PayForFeeProcess per partition |
| History.FeeNightProcessFail | Copy of failed rows |
| Monitor.AlertFeeProcess_DataDog | Reads History.FeeNightProcessFail |
| Trade.SYN_FeeNightProcess | Synonym (FeesProcess DB) |
| Trade.SYN_TruncateFeeNightProcess | Synonym for truncate |

---

## 6. Dependencies

### 6.0 Dependency Chain

Trade.PositionTbl, Trade.InstrumentToFeeConfigV2 -> Trade.GetPositionsForFeeProcess -> Trade.FeeNightProcess
Trade.FeeNightProcess -> Trade.PayForFeeProcess -> History.FeeNightProcessFail (on error)
Trade.FeeNightProcess -> Trade.TruncateFeeNightProcess (after run)

### 6.1 Objects This Depends On

| Object | Type | Purpose |
|--------|------|---------|
| Trade.PositionTbl | Table | PositionID |
| Trade.InstrumentToFeeConfigV2 | Table | Fee rates |
| Customer.Customer | Table | CID, WeekendFeePrecentage |
| Trade.Mirror | Table | MirrorID, MirrorCredit |

### 6.2 Objects That Depend On This

| Object | Type | Purpose |
|--------|------|---------|
| Trade.PayForFeeProcess | Procedure | Consumes rows, updates StatusID |
| Trade.TruncateFeeNightProcess | Procedure | Clears table |
| History.FeeNightProcessFail | Table | Failed row archive |

---

## 7. Technical Details

### 7.1 Indexes

| Name | Type | Key Columns | Purpose |
|-----|------|-------------|---------|
| PK_CIDnightFee | Nonclustered PK | CID, PositionID, PartitionCol | Primary key |
| IX_StatusID | Nonclustered | StatusID, PartitionCol | Filter pending (0) rows |

### 7.2 Constraints

| Name | Type | Definition |
|-----|------|------------|
| PK_CIDnightFee | PRIMARY KEY | CID, PositionID, PartitionCol |
| DATA_COMPRESSION | PAGE | On PRIMARY and index |
| Partition scheme | PS_PositionTbl | PartitionCol (0-9) |

---

## 8. Sample Queries

```sql
-- Pending positions for a partition
SELECT PositionID, CID, IsBuy, FeeInDollars, EndOfWeekFee, Amount
FROM Trade.FeeNightProcess WITH (NOLOCK)
WHERE PartitionCol = 0 AND StatusID = 0;

-- Fee totals by Fee type
SELECT Fee, StatusID, COUNT(*) AS Cnt, SUM(FeeInDollars) AS TotalFee
FROM Trade.FeeNightProcess WITH (NOLOCK)
GROUP BY Fee, StatusID;

-- Failed positions (after copy to History)
SELECT PositionID, CID, ErrorMessage, FeeInDollars
FROM History.FeeNightProcessFail WITH (NOLOCK)
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.8/10 | Sources: DDL, MCP live data, Trade.GetPositionsForFeeProcess, Trade.PayForFeeProcess, Trade.TruncateFeeNightProcess*
