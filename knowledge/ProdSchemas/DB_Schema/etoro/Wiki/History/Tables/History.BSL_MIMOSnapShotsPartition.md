# History.BSL_MIMOSnapShotsPartition

> Balance Stop Loss (BSL) snapshot table storing MIMO (Multi-Instrument Multi-Order) credit calculation records with associated price rates at the time of each BSL execution; serves as a partition-based replacement for History.BSL_MIMOSnapShotsOld.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (ID, Occurred) - composite PK CLUSTERED |
| **Partition** | No (PRIMARY filegroup; partition scheme applied to related tables via PS_ManageBSL_Partitions) |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.BSL_MIMOSnapShotsPartition stores point-in-time snapshots of MIMO (Multi-Instrument Multi-Order) credit calculations captured during Balance Stop Loss (BSL) equity monitoring runs. BSL is eToro's automated system that periodically evaluates customer account equity across all open positions and triggers warnings or account closures when equity falls below defined thresholds.

For each BSL execution run (identified by ExecutionID), this table records the MIMO credit event and price rate in effect for each position at the time of the snapshot. This enables the BSL verification procedure (Trade.CheckBSL) to reconstruct the exact equity state that triggered a BSL warning - using the historical Bid/Ask prices captured here alongside position data, rather than current live prices.

This is a "Partition" generation table - the suffix indicates it replaced the older History.BSL_MIMOSnapShotsOld table, likely as part of a partitioning re-architecture to manage the high-volume BSL snapshot data. The IDENTITY starts at 11,717,500,000 - confirming continuation from a prior table's ID space.

---

## 2. Business Logic

### 2.1 BSL Execution Snapshot Pattern

**What**: Each row captures one position's MIMO credit state at a specific BSL check execution.

**Columns/Parameters Involved**: `MimoCreditID`, `BSLChangeCreditID`, `PositionID`, `PriceRateID`, `Bid`, `Ask`, `Occurred`

**Rules**:
- One row per position per BSL execution run
- MimoCreditID links to the MIMO credit calculation (from History.ActiveCredit or similar) active at snapshot time
- BSLChangeCreditID records the specific credit change event that triggered recording this snapshot
- Bid/Ask are the instrument prices at the exact time of the BSL check - essential for equity verification
- Occurred defaults to getdate() (server time) at insert

**Diagram**:
```
BSL Execution Run (ExecutionID = N):
  Trade.ManageBSL processes positions ->
    Per position:
      INSERT History.BSL_MIMOSnapShotsPartition
        MimoCreditID = active MIMO credit ID
        BSLChangeCreditID = latest change credit
        PositionID = position being evaluated
        PriceRateID = price rate used
        Bid/Ask = prices at snapshot time
        Occurred = GETDATE()

  Trade.CheckBSL(@ExecutionID) later uses these snapshots
  to verify/audit the equity calculation
```

---

## 3. Data Overview

The table is empty (0 rows). The partition-based design suggests records may have been migrated, partitioned out, or the system has not yet inserted into this generation of the table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(11717500000,1) | CODE-BACKED | Surrogate primary key. IDENTITY starts at 11,717,500,000 - continuation from prior BSL_MIMOSnapShots table ID space. PK component with Occurred. |
| 2 | MimoCreditID | bigint | NO | - | CODE-BACKED | References the MIMO (Multi-Instrument Multi-Order) credit calculation event active for this position at snapshot time. Links to History.ActiveCredit CreditID. |
| 3 | BSLChangeCreditID | bigint | NO | - | CODE-BACKED | References the credit change event that triggered recording this BSL snapshot. Distinguishes the specific equity-affecting event within the BSL run. |
| 4 | PositionID | int | NO | - | CODE-BACKED | The trading position being evaluated in this BSL snapshot. Implicit FK to Trade.PositionTbl/History.Position. |
| 5 | PriceRateID | bigint | NO | - | CODE-BACKED | References the price rate record used for this position's equity calculation. Links to the instrument pricing system. |
| 6 | Bid | decimal(16,8) | NO | - | CODE-BACKED | Instrument bid price at the time of the BSL snapshot. Used to calculate unrealized PnL for short positions. 8 decimal places provides pip-level precision. |
| 7 | Ask | decimal(16,8) | NO | - | CODE-BACKED | Instrument ask price at the time of the BSL snapshot. Used to calculate unrealized PnL for long positions. |
| 8 | Occurred | datetime | NO | getdate() | CODE-BACKED | Server timestamp when this BSL snapshot was recorded. PK component. Default = getdate() (local server time, not UTC). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MimoCreditID | History.ActiveCredit (CreditID) | Implicit | MIMO credit calculation active at snapshot time |
| PositionID | Trade.PositionTbl / History.Position | Implicit | Position evaluated in this BSL snapshot |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ManageBSL (table) | ExecutionID | Related | BSL execution that produced these snapshots |
| Trade.CheckBSL | ExecutionID | Reader | Uses MIMO snapshots to verify equity calculations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BSL_MIMOSnapShotsPartition (table)
```

---

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CheckBSL | Stored Procedure | Reads MIMO snapshots to reconstruct BSL equity state |
| Trade.AcknowledgeMessagesBSL | Stored Procedure | Processes BSL results referencing snapshot data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryBSLMIMOSnapShots_newPartition | CLUSTERED PK | ID ASC, Occurred ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryBSLMIMOSnapShots_newPartition | PRIMARY KEY | (ID, Occurred) composite |
| DF_BSL_MIMOSnapShotsNEWPartition | DEFAULT | Occurred = getdate() |

---

## 8. Sample Queries

### 8.1 Get MIMO snapshots for a specific BSL execution
```sql
SELECT ID, MimoCreditID, BSLChangeCreditID, PositionID, PriceRateID, Bid, Ask, Occurred
FROM [History].[BSL_MIMOSnapShotsPartition] WITH (NOLOCK)
WHERE Occurred BETWEEN @ExecutionStart AND @ExecutionEnd
ORDER BY ID
```

### 8.2 Find snapshots for a specific position
```sql
SELECT ID, MimoCreditID, BSLChangeCreditID, Bid, Ask, Occurred
FROM [History].[BSL_MIMOSnapShotsPartition] WITH (NOLOCK)
WHERE PositionID = @PositionID
ORDER BY Occurred DESC
```

### 8.3 Check row count and date range
```sql
SELECT COUNT(*) AS RowCount, MIN(Occurred) AS Earliest, MAX(Occurred) AS Latest
FROM [History].[BSL_MIMOSnapShotsPartition] WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BSL_MIMOSnapShotsPartition | Type: Table | Source: etoro/etoro/History/Tables/History.BSL_MIMOSnapShotsPartition.sql*
