# Billing.GetBonusesByCID

> Returns all bonus credit transactions for a customer (CreditTypeID=7) by merging the persistent History.Credit table with the in-memory History.ActiveCreditRecentMemoryBucket, deduplicating and ordering chronologically.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetBonusesByCID` retrieves the complete history of bonus credits awarded to a specific customer. Bonuses in eToro's credit system are identified by `CreditTypeID = 7` (Name: "Bonus" per Dictionary.CreditType). The procedure covers the full timeline by reading from two sources: the persistent `History.Credit` table (historical records) and the in-memory `History.ActiveCreditRecentMemoryBucket` (recent active credits cached for performance). The results are merged, deduplicated, and returned in reverse chronological order.

This dual-source pattern is eToro's standard approach for high-throughput credit history queries: recent data lives in a memory-optimized table for fast reads, while older data is stored in the disk-based History.Credit table. By querying both and using `SELECT DISTINCT` on the combined temp table, the procedure ensures complete, non-duplicated bonus history regardless of whether records have been migrated from the in-memory store to disk.

The `@startTime` parameter allows filtering to bonuses on or after a given date. The query hint `OPTION (OPTIMIZE FOR (@startTime = '20090101'))` forces the optimizer to plan for the worst case (no date filter, full CID scan), ensuring the CID-based index is always used even when a narrow @startTime is supplied.

This procedure is granted to `CustomerFinanceServiceUser`, indicating it is called by the customer finance service when displaying or processing a customer's bonus history.

---

## 2. Business Logic

### 2.1 Dual-Source History Query Pattern

**What**: Merges two data sources — persistent disk storage and in-memory recent cache — to provide complete bonus history without gaps.

**Columns/Parameters Involved**: `History.Credit`, `History.ActiveCreditRecentMemoryBucket`

**Rules**:
- `History.Credit`: persistent table storing all credit transactions (disk-based). Queried with WHERE CreditTypeID=7 (bonus) AND CID=@cid
- `History.ActiveCreditRecentMemoryBucket`: memory-optimized table holding recent active credits for fast access. Contains the same columns but for recency window
- Both inserts target the same `#Result` temp table with a CLUSTERED index on Occurred for performance
- `SELECT DISTINCT *` removes duplicates that could arise if the same record exists in both sources (during the migration window when a record is still in the memory table but has also been persisted to disk)
- `ORDER BY Occurred DESC`: most recent bonus first

### 2.2 CreditTypeID=7 Bonus Filter

**What**: Only "Bonus" credit type records are returned.

**Columns/Parameters Involved**: `CreditTypeID`, `@cid`

**Rules**:
- CreditTypeID=7 = "Bonus" (from Dictionary.CreditType)
- Other credit types (deposits, withdrawals, fees, etc.) are excluded
- BonusTypeID in the result set provides further sub-classification of the bonus type (specific bonus programs/campaigns)
- `Payment` (MONEY type) is the bonus amount — positive value = bonus credited, negative = reversal

### 2.3 Query Optimizer Hint

**What**: The OPTIMIZE FOR hint overrides default optimizer behavior to ensure efficient query plans regardless of @startTime value.

**Columns/Parameters Involved**: `@startTime`

**Rules**:
- `OPTION (OPTIMIZE FOR (@startTime = '20090101'))`: tells the optimizer to plan as if @startTime is '2009-01-01' (very old date)
- This forces a plan that scans by CID first (using the CID-based index), not by date
- Without this hint, the optimizer might choose a date-based plan when a narrow @startTime is supplied, which would be less efficient for large customer histories
- `@startTime = NULL` (default): no date filter, returns all bonuses for the customer

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | int | NO | - | VERIFIED | Customer ID to retrieve bonuses for. Filters both History.Credit and History.ActiveCreditRecentMemoryBucket by CID. |
| 2 | @startTime | datetime | YES | NULL | CODE-BACKED | Optional start date filter: returns bonuses with Occurred >= @startTime. NULL (default) returns all bonuses with no date restriction. The OPTIMIZE FOR hint forces the CID index plan regardless of this value. |

**Return Columns (from #Result temp table):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditTypeID | int | NO | - | VERIFIED | Always 7 ("Bonus") for all rows returned by this procedure. Identifies the credit transaction category. (Dictionary.CreditType) |
| 2 | Payment | money | NO | - | CODE-BACKED | The monetary value of the bonus credit. Positive = bonus amount awarded. Negative = bonus reversal/clawback. Stored in the customer's account currency. |
| 3 | Occurred | datetime | NO | - | VERIFIED | Timestamp when the bonus credit was applied to the customer's account. Result set is ordered by this column DESC (most recent first). |
| 4 | BonusTypeID | int | YES | - | CODE-BACKED | Sub-classification of the bonus type within CreditTypeID=7. Identifies the specific bonus program or campaign that generated this credit. References a bonus type lookup (not further detailed in this SP). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditTypeID=7 filter | Dictionary.CreditType | Lookup (implicit) | Filters to bonus credits only. CreditTypeID=7 = "Bonus". |
| @cid filter | History.Credit | Read (cross-schema) | Persistent credit history table. Source of historical bonus records. |
| @cid filter | History.ActiveCreditRecentMemoryBucket | Read (cross-schema) | Memory-optimized recent credit cache. Source of recent bonus records. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CustomerFinanceServiceUser (role) | EXECUTE permission | Permission | Customer finance service retrieves bonus history for display and processing. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetBonusesByCID (procedure)
├── History.Credit (table, cross-schema)
└── History.ActiveCreditRecentMemoryBucket (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table (cross-schema) | SELECT CreditTypeID, Payment, Occurred, BonusTypeID WHERE CID=@cid AND CreditTypeID=7. Persistent credit transaction history. |
| History.ActiveCreditRecentMemoryBucket | Table (cross-schema) | SELECT CreditTypeID, Payment, Occurred, BonusTypeID WHERE CID=@cid AND CreditTypeID=7. Memory-optimized table for recent active credits. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CustomerFinanceServiceUser (role) | Permission | Customer finance service bonus history retrieval |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure (temp table #Result creates a CLUSTERED INDEX on Occurred internally).

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all bonuses for a customer
```sql
EXEC Billing.GetBonusesByCID @cid = 12345
-- Returns all bonus credits (CreditTypeID=7) for customer 12345, most recent first
```

### 8.2 Get bonuses since a specific date
```sql
EXEC Billing.GetBonusesByCID @cid = 12345, @startTime = '2024-01-01'
-- Returns bonuses awarded from 2024-01-01 onwards
```

### 8.3 Direct query for bonus credits (bypasses SP dual-source merge)
```sql
SELECT CreditTypeID, Payment, Occurred, BonusTypeID
FROM History.Credit WITH (NOLOCK)
WHERE CID = 12345
  AND CreditTypeID = 7
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetBonusesByCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetBonusesByCID.sql*
