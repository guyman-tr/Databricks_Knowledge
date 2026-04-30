# Trade.DebugSplitwithError

> Debug table capturing position and tree data when stock split processing fails, used for troubleshooting and manual recovery of split-by-job operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | PartitionCol, ID (composite PK) |
| **Partition** | Yes (PS_PositionTbl, PartitionCol) |
| **Indexes** | 3 |

---

## 1. Business Meaning

Trade.DebugSplitwithError is a **diagnostic table** that stores a snapshot of position and tree data when Trade.SplitbyJob encounters an error during stock split processing. The table is truncated at the start of Trade.SplitOpenPositions, then populated only in the CATCH block of SplitbyJob when processing fails—specifically when NtilePositionID=11 (special batch) and stepID is 1 (position updates) or 2 (tree info updates). The "-999999999999999" default values on numeric columns serve as sentinels to identify unpopulated fields.

Data flows one way: **INSERT only** from SplitbyJob's CATCH block. No procedure reads from this table for business logic; it exists purely for debugging and post-mortem analysis. The table may not exist in all environments (e.g., demo vs. production); the connected database returned "Invalid object name" at documentation time.

---

## 2. Business Logic

### 2.1 Error Capture for Position Row Updates (Step 1)

**What**: When SplitbyJob fails during position row updates (AmountInUnitsDecimal, LotCountDecimal, InitialUnits, InitialLotCount, InitForexRate, SpreadedPipBid/Ask, OrderPriceRate, MarketPriceRate, LastOpPriceRate), the CATCH block inserts one row per failed position with the *intended* post-split values.

**Columns/Parameters Involved**: SplitID, PositionID, AmountInUnitsDecimal, LotCountDecimal, InitialUnits, InitialLotCount, InitForexRate, SpreadedPipBid, SpreadedPipAsk, OrderPriceRate, MarketPriceRate, LastOpPriceRate.

**Rules**:
- Two branches: IsUsCustomer=0 uses @UnitsPrecision; IsUsCustomer=1 uses @UsUnitsPrecision and adds UnitsToAdd from Trade.UsUnitsToAddByPositionToSplitByJob.
- AmountRatio and PriceRatio from History.SplitRatio drive the calculations.
- Rows come from Trade.PositionTbl INNER JOIN #PositionToSplitByJob.

### 2.2 Error Capture for Tree Info Updates (Step 2)

**What**: When SplitbyJob fails during tree info updates (LimitRate, StopRate, NextThresHold, SLManualVer, LimitRate_PriceRatio, SLManualVerTimestamp), the CATCH block inserts one row per failed tree with the *intended* post-split values.

**Columns/Parameters Involved**: SplitID, TreeID, LimitRate, StopRate, NextThresHold, SLManualVer, LimitRate_PriceRatio, SLManualVerTimestamp.

**Rules**:
- LimitRate and StopRate use Trade.RoundByPrecisions_ForDebug when not equal to @OnePip.
- SLManualVer is incremented by 1.
- SLManualVerTimestamp = GETUTCDATE().
- Data from Trade.PositionTreeInfo INNER JOIN #PositionToSplitByJob.

### 2.3 Partitioning and Sentinel Values

**What**: PartitionCol = ID % 10 enables partition elimination. Numeric columns use -999999999999999 (or -9999999 for SLManualVer) as defaults to distinguish "not populated" from actual values.

**Columns/Parameters Involved**: PartitionCol, AmountInUnitsDecimal, LotCountDecimal, etc.

**Rules**:
- PartitionCol is a computed persisted column.
- All nullable decimal columns have DEFAULT -999999999999999.

---

## 3. Data Overview

Table did not exist in the connected database at documentation time. Representative structure from DDL and SplitbyJob/SplitOpenPositions logic:

| SplitID | PositionID | TreeID | AmountInUnitsDecimal | InitialUnits | OrderPriceRate | LimitRate | StopRate | Meaning |
|---------|------------|--------|---------------------|--------------|----------------|-----------|---------|---------|
| 123 | 9876543 | 88888 | 0.000012 | 0.000012 | 1.08500 | 1.09000 | 1.08000 | Failed position split: intended values for debugging. |
| 123 | NULL | 88889 | -999999999999999 | -999999999999999 | -999999999999999 | 163.50 | 162.00 | Failed tree split: only tree columns populated. |

**Selection criteria**: Inferred from procedure INSERT logic. Step 1 populates position columns; Step 2 populates tree columns. NULL or -999999... indicates unused column.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate key. Part of PK. |
| 2 | SplitID | int | NO | - | CODE-BACKED | FK to History.SplitRatio (implicit). Identifies which split failed. |
| 3 | PositionID | bigint | YES | - | CODE-BACKED | FK to Trade.PositionTbl (implicit). Populated in step 1 only. |
| 4 | TreeID | bigint | YES | - | CODE-BACKED | FK to Trade.PositionTreeInfo (implicit). Populated in step 2 only. |
| 5 | PartitionCol | int | NO | ID%10 PERSISTED | CODE-BACKED | Partition key. Part of PK. PERSISTED computed. |
| 6 | AmountInUnitsDecimal | decimal(38,15) | YES | -999999999999999 | CODE-BACKED | Intended post-split amount in units. Step 1. |
| 7 | LotCountDecimal | decimal(38,15) | YES | -999999999999999 | CODE-BACKED | Intended lot count. Step 1. |
| 8 | InitialUnits | decimal(38,15) | YES | -999999999999999 | CODE-BACKED | Intended initial units. Step 1. |
| 9 | InitialLotCount | decimal(38,15) | YES | -999999999999999 | CODE-BACKED | Intended initial lot count. Step 1. |
| 10 | InitForexRate | decimal(38,15) | YES | -999999999999999 | CODE-BACKED | Intended init forex rate. Step 1. |
| 11 | SpreadedPipBid | decimal(38,15) | YES | -999999999999999 | CODE-BACKED | Intended spreaded pip bid. Step 1. |
| 12 | SpreadedPipAsk | decimal(38,15) | YES | -999999999999999 | CODE-BACKED | Intended spreaded pip ask. Step 1. |
| 13 | OrderPriceRate | decimal(38,15) | YES | -999999999999999 | CODE-BACKED | Intended order price rate. Step 1. |
| 14 | MarketPriceRate | decimal(38,15) | YES | -999999999999999 | CODE-BACKED | Intended market price rate. Step 1. |
| 15 | LastOpPriceRate | decimal(38,15) | YES | -999999999999999 | CODE-BACKED | Intended last op price rate. Step 1. |
| 16 | LimitRate | decimal(38,15) | YES | -999999999999999 | CODE-BACKED | Intended limit rate. Step 2. |
| 17 | StopRate | decimal(38,15) | YES | -999999999999999 | CODE-BACKED | Intended stop rate. Step 2. |
| 18 | NextThresHold | decimal(38,10) | YES | -999999999999999 | CODE-BACKED | Intended next threshold. Step 2. |
| 19 | SLManualVer | int | YES | -9999999 | CODE-BACKED | Intended SL manual version. Step 2. |
| 20 | LimitRate_PriceRatio | decimal(38,15) | YES | -999999999999999 | CODE-BACKED | Limit rate × price ratio. Step 2. |
| 21 | SLManualVerTimestamp | datetime | YES | - | CODE-BACKED | When SLManualVer was computed. Step 2. |

---

## 5. Relationships

### 5.1 References To
| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SplitID | History.SplitRatio | Implicit | Split being processed. |
| PositionID | Trade.PositionTbl | Implicit | Position that failed to update. |
| TreeID | Trade.PositionTreeInfo | Implicit | Tree that failed to update. |

### 5.2 Referenced By
| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SplitOpenPositions | TRUNCATE | Truncate | Clears table at start of split job. |
| Trade.SplitbyJob | INSERT | Writer | Populates in CATCH when step 1 or 2 fails. |

---

## 6. Dependencies

### 6.0 Dependency Chain
```
Trade.DebugSplitwithError (table)
├── History.SplitRatio (table) [implicit]
├── Trade.PositionTbl (table) [implicit]
├── Trade.PositionTreeInfo (table) [implicit]
├── Trade.PositionToSplitByJob (table) [implicit]
└── Trade.UsUnitsToAddByPositionToSplitByJob (table) [implicit, step 1 US only]
```

### 6.1 Objects This Depends On
| Object | Type | How Used |
|--------|------|----------|
| History.SplitRatio | Table | SplitID, AmountRatio, PriceRatio, MinDate. |
| Trade.PositionTbl | Table | Source of position data for step 1. |
| Trade.PositionTreeInfo | Table | Source of tree data for step 2. |
| Trade.ProviderToInstrument | Table | Precision, AboveDollarPrecision. |
| PS_PositionTbl | Partition Scheme | Table partitioning. |

### 6.2 Objects That Depend On This
| Object | Type | How Used |
|--------|------|----------|
| Trade.SplitOpenPositions | Procedure | TRUNCATE at start. |
| Trade.SplitbyJob | Procedure | INSERT in CATCH. |

---

## 7. Technical Details

### 7.1 Indexes
| Index Name | Type | Key Columns | Partition Scheme | Status |
|-----------|------|-------------|------------------|--------|
| PK_DebugSplitwithError | NONCLUSTERED PK | PartitionCol, ID | PS_PositionTbl(PartitionCol) | Active |
| CIX | NC | SplitID | PS_PositionTbl(PartitionCol) | Active |
| IX_PositionID | NC | PositionID | PS_PositionTbl(PartitionCol) | Active |

### 7.2 Constraints
| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DebugSplitwithError | PK | (PartitionCol, ID) |
| DF_AmountInUnitsDecimal | DEFAULT | -999999999999999 |
| DF_LotCountDecimal | DEFAULT | -999999999999999 |
| DF_InitialUnits | DEFAULT | -999999999999999 |
| DF_InitialLotCount | DEFAULT | -999999999999999 |
| DF_InitForexRate | DEFAULT | -999999999999999 |
| DF_SpreadedPipBid | DEFAULT | -999999999999999 |
| DF_SpreadedPipAsk | DEFAULT | -999999999999999 |
| DF_OrderPriceRate | DEFAULT | -999999999999999 |
| DF_MarketPriceRate | DEFAULT | -999999999999999 |
| DF_LastOpPriceRate | DEFAULT | -999999999999999 |
| DF_LimitRate | DEFAULT | -999999999999999 |
| DF_StopRate | DEFAULT | -999999999999999 |
| DF_NextThresHold | DEFAULT | -999999999999999 |
| DF_SLManualVer | DEFAULT | -9999999 |
| DF_LimitRate_PriceRatio | DEFAULT | -999999999999999 |

---

## 8. Sample Queries

### 8.1 List recent split errors by SplitID
```sql
SELECT SplitID, COUNT(*) AS ErrorCount, MAX(ID) AS MaxID
  FROM Trade.DebugSplitwithError WITH (NOLOCK)
 GROUP BY SplitID
 ORDER BY SplitID DESC;
```

### 8.2 Inspect position-level errors for a split
```sql
SELECT ID, SplitID, PositionID, AmountInUnitsDecimal, InitialUnits, OrderPriceRate, MarketPriceRate
  FROM Trade.DebugSplitwithError WITH (NOLOCK)
 WHERE SplitID = 123 AND PositionID IS NOT NULL
 ORDER BY PositionID;
```

### 8.3 Inspect tree-level errors for a split
```sql
SELECT ID, SplitID, TreeID, LimitRate, StopRate, NextThresHold, SLManualVer, SLManualVerTimestamp
  FROM Trade.DebugSplitwithError WITH (NOLOCK)
 WHERE SplitID = 123 AND TreeID IS NOT NULL
 ORDER BY TreeID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| - | - | No Atlassian sources linked. |

---

*Generated: 2026-03-14 | Quality: 7.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Note: Table may not exist in all environments. Documented from DDL and procedure logic.*
