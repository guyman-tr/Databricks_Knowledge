# Trade.PositionToSplitByJob

> Transient staging table for positions queued for stock split processing; populated by SplitOpenPositions, consumed by parallel SplitbyJob workers, then truncated.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | NtilePositionID, ID, PositionPartitionCol, PositionID |
| **Partition** | PS_splitT(NtilePositionID) |
| **Indexes** | 2 |

---

## 1. Business Meaning

**WHAT:** Trade.PositionToSplitByJob is a partitioned staging table that holds positions eligible for a stock split. It is populated by Trade.SplitOpenPositions from History.SplitRatio and Trade.Position, then processed in parallel by SQL Server Agent jobs (etoro/tradonomi Split Positions 1-10) that call Trade.SplitbyJob per NtilePositionID. Each row tracks one position's split state (PositionWasSplit: 0=pending, 1=done, -1/-2=error) and the split ratios (AmountRatio, PriceRatio) from History.SplitRatio.

**WHY:** Stock splits require updating position units and prices for all open positions in the instrument before the split date. The work is partitioned by NtilePositionID (1-10) so ten jobs can run in parallel. The table is transient: TRUNCATE at start of SplitOpenPositions, INSERT, process until all PositionWasSplit=1 or errors, then TRUNCATE again. Trade.UsUnitsToAddByPositionToSplitByJob holds US-customer unit adjustments for APEX reconciliation.

**HOW:** SplitOpenPositions reads History.SplitRatio for SplitID, gets @AmountRatio and @PriceRatio, selects open positions from Trade.Position with InitDateTime < @MinDate and InstrumentID match, excludes already-split (History.PositionSplit), assigns NtilePositionID (1-10) by PositionPartitionCol, and inserts into PositionToSplitByJob. SplitbyJob processes its NtilePositionID batch: updates Trade.PositionTbl (AmountInUnitsDecimal, LotCountDecimal, rates), Trade.PositionTreeInfo, History.PositionSplit. PositionWasSplit=1 on success; -1 or -2 on error with ErrorMessage. Trade.AnalyseSplitwithError reads ErrorMessage for failed rows.

---

## 2. Business Logic

### 2.1 PositionWasSplit Status

0 = Pending (not yet processed). 1 = Success (position updated). -1 = Error (general failure). -2 = Error (specific failure; ErrorMessage from Trade.AnalyseSplitwithError). SplitOpenPositions loops while PositionWasSplit in (0,-1,-2) exists; on completion it RAISERRORs if any remain, else TRUNCATEs.

### 2.2 IsBuy

1 = Buy (long), 0 = Sell (short). Used by SplitbyJob for position logic. From Dictionary rule: IsBuy 1=Buy, 0=Sell.

### 2.3 Ratios and Partitioning

AmountRatio and PriceRatio from History.SplitRatio. NtilePositionID (1-10) maps to parallel jobs. PositionPartitionCol = PositionID % 50 for partition alignment with Trade.PositionTbl. TreePartitionCol for tree-level processing.

### 2.4 US Customer Handling

IsUsCustomer from Trade.IsUsUser(CID). US customers get special rounding (5 decimals) and Trade.UsUnitsToAddByPositionToSplitByJob stores UnitsToAdd for APEX reconciliation (eToroCalc vs ApexCalc).

---

## 3. Data Overview

| ID | NtilePositionID | PositionWasSplit | PositionID | InstrumentID | AmountRatio | Meaning |
|----|-----------------|------------------|------------|--------------|-------------|---------|
| 1 | 3 | 0 | 12345 | 100 | 4.0 | Pending split (4:1) in job 3 |
| 2 | 5 | 1 | 12346 | 100 | 4.0 | Successfully split in job 5 |
| 3 | 2 | -2 | 12347 | 100 | 4.0 | Failed with ErrorMessage |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Row number within NtilePositionID; ROW_NUMBER() in SplitOpenPositions. |
| 2 | NtilePositionID | int | NO | - | VERIFIED | Partition key (1-10); maps to parallel Split Positions jobs. |
| 3 | PositionWasSplit | int | YES | - | VERIFIED | 0=pending, 1=success, -1/-2=error. Indexed for loop exit. |
| 4 | CID | int | YES | - | CODE-BACKED | Customer ID from Trade.Position. |
| 5 | IsUsCustomer | int | YES | - | CODE-BACKED | 1=US user (from Trade.IsUsUser); affects rounding and UsUnitsToAddByPositionToSplitByJob. |
| 6 | AmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Position units before split; updated in PositionTbl by split ratio. |
| 7 | PositionPartitionCol | bigint | NO | - | CODE-BACKED | PositionID % 50; aligns with Trade.PositionTbl.PartitionCol. |
| 8 | TreePartitionCol | bigint | YES | - | CODE-BACKED | For tree-level split processing. |
| 9 | PositionID | bigint | NO | - | VERIFIED | Links to Trade.PositionTbl. |
| 10 | IsBuy | bit | YES | - | VERIFIED | 1=Buy (long), 0=Sell (short). |
| 11 | TreeID | bigint | YES | - | CODE-BACKED | Position tree identifier. |
| 12 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position in tree. |
| 13 | InstrumentID | int | YES | - | VERIFIED | Instrument; links to Trade.Instrument. |
| 14 | AmountRatio | decimal(38,19) | YES | - | CODE-BACKED | Units multiplier from History.SplitRatio (e.g. 4 for 4:1 split). |
| 15 | OnePip | decimal(8,6) | YES | - | CODE-BACKED | 1/POWER(10, Precision) from Trade.ProviderToInstrument. |
| 16 | PriceRatio | decimal(38,19) | YES | - | CODE-BACKED | Price divisor from History.SplitRatio. |
| 17 | SplitID | int | YES | - | CODE-BACKED | Links to History.SplitRatio. |
| 18 | MinDate | datetime | YES | - | CODE-BACKED | Split effective date; positions with InitDateTime < MinDate are split. |
| 19 | DateCreated | datetime | YES | getutcdate() | CODE-BACKED | When row was inserted. |
| 20 | ErrorMessage | varchar(8000) | YES | - | CODE-BACKED | Error details when PositionWasSplit = -1 or -2. |

---

## 5. Relationships

### 5.1 References To

| Column | Target | Relationship |
|--------|--------|---------------|
| PositionID | Trade.PositionTbl | Logical (join key) |
| InstrumentID | Trade.Instrument | Logical |
| CID | Customer.CustomerStatic | Logical |
| SplitID | History.SplitRatio | Logical |
| TreeID, ParentPositionID | Trade.PositionTreeInfo, Trade.PositionTbl | Logical |

### 5.2 Referenced By

- Trade.SplitOpenPositions (TRUNCATE, INSERT, loop checks)
- Trade.SplitbyJob (SELECT, UPDATE PositionWasSplit)
- Trade.AnalyseSplitwithError (SELECT ErrorMessage)
- Trade.UsUnitsToAddByPositionToSplitByJob (sibling table for US units)

---

## 6. Dependencies

### 6.0 Dependency Chain

PositionToSplitByJob <- History.SplitRatio, Trade.Position, Trade.IsUsUser. -> Trade.PositionTbl, Trade.PositionTreeInfo, History.PositionSplit, Trade.UsUnitsToAddByPositionToSplitByJob.

### 6.1 Objects This Depends On

- History.SplitRatio (AmountRatio, PriceRatio, MinDate, SplitID)
- Trade.Position / Trade.PositionTbl
- Trade.ProviderToInstrument (Precision, OnePip)
- Trade.IsUsUser (IsUsCustomer)

### 6.2 Objects That Depend On This

- Trade.SplitbyJob, Trade.SplitOpenPositions
- Trade.AnalyseSplitwithError (view)
- Trade.UsUnitsToAddByPositionToSplitByJob
- Trade.ActivateSplit, Trade.ActivateSplit_Inner (orchestrate split)

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Columns | Notes |
|------------|------|---------|-------|
| PK_PositionToSplitByJob | CLUSTERED PK | NtilePositionID, ID, PositionPartitionCol, PositionID | Partitioned on PS_splitT(NtilePositionID); FILLFACTOR 90; DATA_COMPRESSION PAGE. |
| ix | NONCLUSTERED | PositionWasSplit | For loop exit and error checks. |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| PK_PositionToSplitByJob | PRIMARY KEY | NtilePositionID, ID, PositionPartitionCol, PositionID |
| DF_PositionToSplitByJob_DateCreated | DEFAULT | DateCreated = getutcdate() |

---

## 8. Sample Queries

```sql
SELECT TOP 5 ID, NtilePositionID, PositionWasSplit, PositionID, InstrumentID, AmountRatio, SplitID
FROM   Trade.PositionToSplitByJob WITH (NOLOCK);
```

```sql
SELECT PositionWasSplit, COUNT(*) AS Cnt
FROM   Trade.PositionToSplitByJob WITH (NOLOCK)
GROUP BY PositionWasSplit;
```

```sql
SELECT TOP 1 ErrorMessage
FROM   Trade.PositionToSplitByJob WITH (NOLOCK)
WHERE  PositionWasSplit = -2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.8/10 | Sources: DDL, SplitOpenPositions, SplitbyJob, ActivateSplit, AnalyseSplitwithError*
