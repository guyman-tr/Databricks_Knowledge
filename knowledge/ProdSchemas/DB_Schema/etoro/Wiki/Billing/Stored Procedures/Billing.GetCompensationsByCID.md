# Billing.GetCompensationsByCID

> Returns all compensation credit transactions (CreditTypeID=6) for a customer by merging the persistent History.Credit and in-memory History.ActiveCreditRecentMemoryBucket tables, ordered most-recent first. Near-identical to GetBonusesByCID but for CreditTypeID=6 and without SELECT DISTINCT.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetCompensationsByCID` retrieves the complete history of compensation credits for a customer. Compensations in eToro's credit system are `CreditTypeID=6` ("Compensation" per Dictionary.CreditType) — manual credits applied by customer service or automated systems to compensate customers for losses, system errors, or goodwill gestures.

The procedure follows the same dual-source pattern as `Billing.GetBonusesByCID`: reads from both `History.Credit` (persistent disk storage) and `History.ActiveCreditRecentMemoryBucket` (memory-optimized recent cache), inserting both into a clustered temp table `#Result` before returning. The `OPTIMIZE FOR (@startTime = '20090101')` hint forces the CID-based index plan regardless of the actual @startTime value.

One key difference from `GetBonusesByCID`: this procedure does NOT use `SELECT DISTINCT`. If a compensation record exists in both the persistent and in-memory tables simultaneously (during the migration window), it may appear twice in results.

Created by Shay Oren, 03/01/2021 (added in-memory table access). Granted to `CustomerFinanceServiceUser` and `RedeemServiceUser`.

---

## 2. Business Logic

### 2.1 Dual-Source History Query Pattern

**What**: Merges persistent and in-memory credit stores to provide complete compensation history.

**Columns/Parameters Involved**: `History.Credit`, `History.ActiveCreditRecentMemoryBucket`

**Rules**:
- First INSERT: `History.Credit` WHERE CID=@cid AND CreditTypeID=6 AND Occurred >= @startTime (or no date filter if NULL)
- Second INSERT: `History.ActiveCreditRecentMemoryBucket` same filter - recent in-memory records
- Both INSERT into `#Result` table variable with CLUSTERED INDEX on Occurred
- `SELECT * FROM #Result ORDER BY Occurred DESC` - NO DISTINCT, potential duplicates during migration window
- `ORDER BY Occurred DESC` - most recent compensation first

### 2.2 OPTIMIZE FOR Hint

**What**: Forces optimizer to use CID-based index regardless of @startTime value.

**Rules**: Same as GetBonusesByCID - `OPTION (OPTIMIZE FOR (@startTime = '20090101'))` ensures the plan scans by CID first, not by date range. See GetBonusesByCID Section 2.3 for full explanation.

### 2.3 CreditTypeID=6: Compensation

**What**: Returns only Compensation credit records.

**Rules**:
- CreditTypeID=6 = "Compensation" (from Dictionary.CreditType)
- `CompensationReasonID` in the result set identifies the specific reason/program (distinct from `BonusTypeID` in GetBonusesByCID)
- Compensation amounts may be positive (credit) or negative (clawback/reversal)
- Excludes: Deposits (1), Cashouts (2), Open/Close Positions (3/4), Champ (5), Bonus (7), Reverse Cashout (8), etc.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | int | NO | - | VERIFIED | Customer ID to retrieve compensations for. Filters both History.Credit and History.ActiveCreditRecentMemoryBucket. |
| 2 | @startTime | datetime | YES | NULL | VERIFIED | Optional start date filter. Returns compensations with Occurred >= @startTime. NULL (default) returns all compensations. OPTIMIZE FOR hint forces CID index plan regardless of this value. |

**Return Columns (from #Result temp table):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditTypeID | int | NO | - | VERIFIED | Always 6 ("Compensation") for all rows returned by this procedure. |
| 2 | Payment | money | NO | - | VERIFIED | Compensation amount. Positive = credit awarded. Negative = reversal/clawback. |
| 3 | Occurred | datetime | NO | - | VERIFIED | Timestamp when the compensation was applied. Results ordered DESC by this column. |
| 4 | CompensationReasonID | int | YES | - | VERIFIED | Sub-classification of the compensation type. Identifies the specific reason or program that generated this credit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditTypeID=6 filter | Dictionary.CreditType | Lookup (implicit) | CreditTypeID=6 = "Compensation". |
| @cid filter | History.Credit | Read (cross-schema) | Persistent credit history. Source of historical compensation records. |
| @cid filter | History.ActiveCreditRecentMemoryBucket | Read (cross-schema) | Memory-optimized recent credit cache. Source of recent compensations. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CustomerFinanceServiceUser (role) | EXECUTE permission | Permission | Customer finance service retrieves compensation history. |
| RedeemServiceUser (role) | EXECUTE permission | Permission | Redeem service checks compensation history during redemption processing. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCompensationsByCID (procedure)
├── History.Credit (table, cross-schema)
└── History.ActiveCreditRecentMemoryBucket (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table (cross-schema) | SELECT CreditTypeID, Payment, Occurred, CompensationReasonID WHERE CID=@cid AND CreditTypeID=6. |
| History.ActiveCreditRecentMemoryBucket | Table (cross-schema) | Same filter. Memory-optimized recent credits. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CustomerFinanceServiceUser (role) | Permission | Compensation history retrieval |
| RedeemServiceUser (role) | Permission | Compensation check during redemption |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure (temp table #Result creates a CLUSTERED INDEX on Occurred internally).

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all compensations for a customer
```sql
EXEC Billing.GetCompensationsByCID @cid = 12345
-- Returns all compensation credits (CreditTypeID=6), most recent first
```

### 8.2 Get compensations since a date
```sql
EXEC Billing.GetCompensationsByCID @cid = 12345, @startTime = '2024-01-01'
```

### 8.3 Direct query for compensation history
```sql
SELECT CreditTypeID, Payment, Occurred, CompensationReasonID
FROM History.Credit WITH (NOLOCK)
WHERE CID = 12345 AND CreditTypeID = 6
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCompensationsByCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCompensationsByCID.sql*
