# Trade.InsertActiveCredit

> Flushes a single batch of ActiveCredit records from the in-memory recent-bucket table into the permanent BIGINT history table, used as a scheduled single-threaded migration step.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Numrows INT - controls batch size per execution |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertActiveCredit is a **data lifecycle management SP** that migrates active credit records out of the high-speed in-memory bucket (`History.ActiveCreditRecentMemoryBucket`) into the permanent disk-based history table (`History.ActiveCredit_BIGINT`). This is the core flush operation for the two-tier ActiveCredit storage architecture.

This SP exists because `History.ActiveCreditRecentMemoryBucket` is an in-memory (likely memory-optimized) table designed for high-speed inserts from the live trading system. To prevent unbounded growth and ensure durability in permanent storage, a scheduled process calls this SP to drain the oldest records from the memory bucket into the persistent BIGINT table in controlled batches.

The single-execution model: starts at the current minimum CreditID in the bucket and deletes exactly @Numrows consecutive records (by CreditID range), outputting them to ActiveCredit_BIGINT atomically. For parallelized/partitioned migration with loop semantics, see the companion `Trade.InsertActiveCreditPartition` which adds a modulo partition (@Mod) and a WHILE loop for continuous flushing.

---

## 2. Business Logic

### 2.1 Memory Bucket Drain Pattern (DELETE-OUTPUT)

**What**: Atomically removes records from the in-memory buffer and inserts them into permanent history in one statement.

**Columns/Parameters Involved**: `@Numrows`, `@i` (internal MIN CreditID), `CreditID`

**Rules**:
- `@i = MIN(CreditID) FROM History.ActiveCreditRecentMemoryBucket` - anchors to the oldest unprocessed record
- `DELETE ... WHERE CreditID BETWEEN @i AND @i+@Numrows` - processes one contiguous range per execution
- `OUTPUT deleted.*` - captures all deleted columns and routes them to ActiveCredit_BIGINT
- Single DELETE-OUTPUT is atomic: no record can be lost or duplicated - either both the delete and insert succeed or neither does
- If @Numrows is larger than the remaining rows in the range, fewer rows are moved (not an error)

**Diagram**:
```
History.ActiveCreditRecentMemoryBucket (in-memory, high-speed writes)
  [CreditID=1001 ... CreditID=9999]
           |
           | EXEC Trade.InsertActiveCredit @Numrows=1000
           | @i = MIN(CreditID) = 1001
           | DELETE WHERE CreditID BETWEEN 1001 AND 2001
           | OUTPUT deleted.* INTO History.ActiveCredit_BIGINT
           |
           v
History.ActiveCredit_BIGINT (disk-based, permanent storage)
  [CreditID=1001 ... CreditID=2001] now persisted

Next run: @i = MIN = 2002, moves next batch
```

### 2.2 Relationship to InsertActiveCreditPartition

**What**: This SP is the simple single-pass version; InsertActiveCreditPartition adds parallelism via modulo partitioning.

**Rules**:
- `InsertActiveCredit @Numrows=N` - one execution, one batch, single-threaded
- `InsertActiveCreditPartition @Numrows=N, @Mod=M` (0-9) - loops through all CreditIDs where CreditID%10=M, processing them in batches
- Running InsertActiveCreditPartition with @Mod 0-9 in parallel across 10 sessions is equivalent to a parallelized full flush
- Both SPs move the exact same columns to the exact same destination table

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Numrows | INT | NO | - | CODE-BACKED | Batch size - the size of the CreditID range to migrate in one execution. Defines how many records are moved: CreditID BETWEEN MIN(CreditID) AND MIN(CreditID)+@Numrows. Larger values move more records per call; typical values are thousands to tens of thousands depending on scheduled job frequency. |

**Columns moved (DELETE-OUTPUT, all columns transferred from source to destination):**

| # | Column | Source/Dest | Confidence | Description |
|---|--------|-------------|------------|-------------|
| 2 | CreditID | BIGINT PK | CODE-BACKED | Primary key of the credit record. Identifies the specific financial transaction being migrated. |
| 3 | CID | - | CODE-BACKED | Customer ID. The customer whose balance was affected by this credit event. |
| 4 | CreditTypeID | - | CODE-BACKED | Type of credit operation (e.g., trade P&L, bonus, withdrawal, deposit). Categorizes the financial event. |
| 5 | PositionID | - | CODE-BACKED | Associated trading position if the credit relates to a position event (P&L, dividend, etc.). NULL for non-position credits. |
| 6 | ChampionshipID | - | CODE-BACKED | Associated championship/competition ID if the credit is part of a trading competition reward. |
| 7 | CashoutID | - | CODE-BACKED | Associated cashout event ID if this credit relates to a customer cashout operation. |
| 8 | PaymentID | - | CODE-BACKED | Associated payment ID for payment-related credits. |
| 9 | WithdrawID | - | CODE-BACKED | Associated withdrawal ID if the credit is linked to a withdrawal transaction. |
| 10 | DepositID | - | CODE-BACKED | Associated deposit ID if the credit originated from a customer deposit. |
| 11 | UpdateID | - | CODE-BACKED | Associated update/correction ID for credit adjustments. |
| 12 | CampaignID | - | CODE-BACKED | Associated marketing campaign ID if the credit is a campaign bonus. |
| 13 | BonusTypeID | - | CODE-BACKED | Type of bonus (if credit is a bonus payment). |
| 14 | CompensationReasonID | - | CODE-BACKED | Reason code for customer compensation credits. |
| 15 | ManagerID | - | CODE-BACKED | Manager/admin who authorized or triggered this credit (if applicable). |
| 16 | Credit | - | CODE-BACKED | The monetary amount of the credit transaction. Positive = credit to customer, negative = debit. |
| 17 | Payment | - | CODE-BACKED | Payment amount associated with this credit record. |
| 18 | Description | - | CODE-BACKED | Free-text description of the credit event for audit and display purposes. |
| 19 | Occurred | - | CODE-BACKED | Timestamp when the credit event occurred in the system. |
| 20 | WithdrawProcessingID | - | CODE-BACKED | Processing ID for withdrawal-related credits. |
| 21 | MirrorID | - | CODE-BACKED | Copy-trade relationship ID; non-zero indicates the credit is related to a copy-trade (mirrored) position. |
| 22 | TotalCash | - | CODE-BACKED | Customer total cash balance snapshot at the time of this credit. |
| 23 | TotalCashChange | - | CODE-BACKED | The change in total cash resulting from this credit event. |
| 24 | BonusCredit | - | CODE-BACKED | Bonus credit component of the total credit amount (if applicable). |
| 25 | RealizedEquity | - | CODE-BACKED | Customer realized equity snapshot at the time of the credit. |
| 26 | MirrorCash | - | CODE-BACKED | Cash balance in the copy-trade mirror account context. |
| 27 | StocksOrderID | - | CODE-BACKED | Associated stocks order ID for real-stock related credits. |
| 28 | MirrorEquity | - | CODE-BACKED | Equity in the copy-trade mirror account context at time of credit. |
| 29 | MirrorDividendID | - | CODE-BACKED | Associated dividend ID if the credit is a copy-trade dividend distribution. |
| 30 | MoveMoneyReasonID | - | CODE-BACKED | Reason code for internal money movement operations. |
| 31 | BSLRealFunds | - | CODE-BACKED | Amount related to Better Stop Loss (BSL) real funds adjustment. |
| 32 | OriginalPositionID | - | CODE-BACKED | The original position ID when a position was transferred, split, or rolled over. |
| 33 | SubCreditTypeID | - | CODE-BACKED | Sub-classification of credit type for more granular categorization within a CreditTypeID. |
| 34 | DepositRollbackID | - | CODE-BACKED | Associated deposit rollback ID if the credit is a rollback of a prior deposit. |
| 35 | InterestMonthlyID | - | CODE-BACKED | Associated monthly interest calculation ID if the credit is an interest payment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads/deletes from) | History.ActiveCreditRecentMemoryBucket | DELETER (cross-schema) | Source: in-memory recent credit bucket; records are permanently removed from here |
| (inserts into) | History.ActiveCredit_BIGINT | WRITER (cross-schema) | Destination: permanent disk-based history table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job (external) | EXEC Trade.InsertActiveCredit | Scheduled call | Called by a scheduled SQL Agent job on a recurring interval to drain the memory bucket |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertActiveCredit (procedure)
├── History.ActiveCreditRecentMemoryBucket (table - cross-schema, source)
└── History.ActiveCredit_BIGINT (table - cross-schema, destination)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCreditRecentMemoryBucket | Table (cross-schema) | Source table - reads MIN(CreditID) and deletes the batch range |
| History.ActiveCredit_BIGINT | Table (cross-schema) | Destination table - receives all deleted records via OUTPUT clause |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External SQL Agent Job | Scheduled job | Calls this SP on a schedule to drain the memory bucket |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CreditID BETWEEN range | WHERE clause | Only moves @Numrows records starting from current MIN(CreditID); processes one range per execution |
| Atomic DELETE-OUTPUT | T-SQL guarantee | Cannot partially migrate; either all records in range are moved or none |
| NOLOCK on MIN query | Hint | @i is read with NOLOCK - may read slightly stale MIN but safe since CreditIDs are monotonically increasing |

---

## 8. Sample Queries

### 8.1 Check how many records are pending migration

```sql
SELECT COUNT(*) AS PendingRecords,
       MIN(CreditID) AS OldestCreditID,
       MAX(CreditID) AS NewestCreditID
FROM History.ActiveCreditRecentMemoryBucket WITH (NOLOCK)
```

### 8.2 Execute a migration batch of 5000 records

```sql
EXEC Trade.InsertActiveCredit @Numrows = 5000
```

### 8.3 Verify records were migrated to permanent storage

```sql
-- Check recent records in the destination table
SELECT TOP 10 CreditID, CID, CreditTypeID, Credit, Occurred
FROM History.ActiveCredit_BIGINT WITH (NOLOCK)
ORDER BY CreditID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. No dedicated Confluence page or Jira ticket found for Trade.InsertActiveCredit.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 8/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 34 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (InsertActiveCreditPartition) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertActiveCredit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertActiveCredit.sql*
