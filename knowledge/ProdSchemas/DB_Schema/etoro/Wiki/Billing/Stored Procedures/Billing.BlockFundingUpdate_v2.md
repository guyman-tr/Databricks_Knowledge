# Billing.BlockFundingUpdate_v2

> Successor to Billing.BlockFundingUpdate that supports filtering by either @FundingID or @CID (or both), with a validation guard preventing accidental bulk-updates and a hardcoded protection against modifying the system funding record (FundingID=1).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No explicit RETURN (falls through with 0) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BlockFundingUpdate_v2` is the second version of the funding block update procedure. It extends the original `Billing.BlockFundingUpdate` by making both @FundingID and @CID optional, allowing operations to block either:
- A specific customer's access to a specific funding instrument (`WHERE CID = @CID AND FundingID = @FundingID`)
- All customers' access to a specific instrument (`WHERE FundingID = @FundingID`, leaving @CID null)
- A specific customer's access to all their instruments (`WHERE CID = @CID`, leaving @FundingID null)

Two safety guards are added:
1. A mathematical validation that prevents both @FundingID and @CID from being zero simultaneously (guards against accidental full-table updates).
2. An explicit guard that returns 0 (no-op) if @FundingID = 1 (the system/default funding record that must not be modified).

The same ISNULL-based selective field update and History.ActiveCustomerToFunding audit trail as v1 apply.

---

## 2. Business Logic

### 2.1 Validation Guards

**What**: Two guards prevent unintended mass updates or modification of the system funding record.

**Rules**:
- **Guard 1 - Both-null check**: `IF ISNULL(@FundingID,0) = ((-1) * ISNULL(@CID,0))` -> RETURN 0.
  - When both are NULL: `ISNULL(NULL,0)=0` and `(-1)*ISNULL(NULL,0)=0` -> 0=0 -> triggers guard.
  - When both have the same absolute value but opposite sign: e.g., @FundingID=5 and @CID=-5 -> also triggers (unusual edge case).
  - Intended to catch the case where both params are null and the WHERE clause would match all rows.
- **Guard 2 - System record protection**: `IF @FundingID = 1 -> RETURN 0`. FundingID=1 is the system/default funding record, consistent with the FundingBlock guard documented in Billing.CustomerToFunding.

### 2.2 Flexible WHERE Clause

**What**: The WHERE clause uses ISNULL to allow either or both parameters to be used as filters.

**Pattern**: `WHERE ISNULL(@FundingID, FundingID) = FundingID AND ISNULL(@CID, CID) = CID`
- `ISNULL(@FundingID, FundingID) = FundingID` - if @FundingID IS NULL, matches all rows (tautology); if provided, matches only that FundingID.
- Same for @CID.
- Net effect: filter is applied only for non-null parameters.

### 2.3 Selective Field Update (same as v1)

**What**: ISNULL pattern allows partial updates - null parameters preserve existing values.

**Rules** (same as BlockFundingUpdate):
- `IsRefundExcluded = ISNULL(@BlockWithdraw, IsRefundExcluded)` - NULL preserves
- `IsBlocked = ISNULL(@BlockDeposit, IsBlocked)` - NULL preserves
- `ManagerID = ISNULL(@ManagerID, ManagerID)` - NULL preserves
- `BlockedDescription = ISNULL(@BlockedDescription, BlockedDescription)` - NULL preserves
- `BlockManagerID = @BlockManagerID` - always set
- `BlockedAt = GETUTCDATE()` - always updated

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INT | YES | NULL | CODE-BACKED | Payment instrument to filter on. If NULL, matches all instruments for the given @CID. If 1, returns 0 immediately (system record protection). Combined with @CID via ISNULL flexible filter. |
| 2 | @CID | INT | YES | NULL | CODE-BACKED | Customer ID to filter on. If NULL, matches all customers for the given @FundingID. Combined with @FundingID via ISNULL flexible filter. Both @FundingID and @CID being NULL triggers the safety guard and returns 0. |
| 3 | @BlockDeposit | BIT | YES | NULL | CODE-BACKED | 1 = block deposits for this customer-funding combination (sets IsBlocked=1). 0 = unblock. NULL = preserve existing value. |
| 4 | @BlockWithdraw | BIT | YES | NULL | CODE-BACKED | 1 = exclude from refunds/withdrawals (sets IsRefundExcluded=1). 0 = re-enable. NULL = preserve existing value. |
| 5 | @ManagerID | INT | YES | NULL | CODE-BACKED | Manager authorizing the block. NULL preserves existing value. |
| 6 | @BlockedDescription | VARCHAR(255) | YES | NULL | CODE-BACKED | Reason for the block. Max 255 chars. NULL preserves existing value. |
| 7 | @BlockManagerID | INT | YES | NULL | CODE-BACKED | Alternative manager ID (added PAYIL-5743). Always set to provided value (including NULL). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @FundingID | Billing.CustomerToFunding | MODIFIER | Updates block flags with flexible WHERE matching |
| - | History.ActiveCustomerToFunding | Write (OUTPUT) | Before-image written for audit trail |

### 5.2 Referenced By (other objects point to this)

No callers found in Billing schema SP files.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BlockFundingUpdate_v2 (procedure)
+-- Billing.CustomerToFunding (table)       [UPDATE + OUTPUT]
+-- History.ActiveCustomerToFunding (table) [INSERT via OUTPUT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | UPDATE target with flexible WHERE |
| History.ActiveCustomerToFunding | Table | OUTPUT INTO - audit trail |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **Guard 1 math**: `ISNULL(@FundingID,0) = ((-1)*ISNULL(@CID,0))` - when both are NULL, 0 = (-1)*0 = 0 = TRUE -> guard fires. Unusual implementation of a null-check.
- **FundingID=1 protection**: Hardcoded guard for the system funding record, consistent with Billing.FundingBlock and CustomerToFunding documentation.
- **No TRY-CATCH**: Errors propagate to caller.
- **PAYIL-5743 (Jan 2023)**: Added IsVerified and BlockManagerID to OUTPUT clause.
- **vs v1**: v2 adds both-null guard, FundingID=1 guard, flexible single-parameter filtering. Otherwise identical logic.

---

## 8. Sample Queries

### 8.1 Block a specific customer-funding pair
```sql
EXEC Billing.BlockFundingUpdate_v2
    @FundingID          = 590850,
    @CID                = 98765,
    @BlockDeposit       = 1,
    @BlockWithdraw      = 1,
    @ManagerID          = 12345,
    @BlockedDescription = 'Blocked per risk review 2026-001';
```

### 8.2 Block all customers' access to a specific instrument
```sql
EXEC Billing.BlockFundingUpdate_v2
    @FundingID    = 590850,
    @CID          = NULL,   -- all customers
    @BlockDeposit = 1;
```

### 8.3 Verify block state
```sql
SELECT CID, FundingID, IsBlocked, IsRefundExcluded, BlockedAt, BlockedDescription
FROM Billing.CustomerToFunding WITH (NOLOCK)
WHERE FundingID = 590850
ORDER BY CID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Block Funding Api](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/11578968620/Block+Funding+Api) | Confluence (MG space, Mar 2022) | Background context for the BlockFundingUpdate SP family (PAYIL-3790); v2 is the flexible-filter successor |

---

*Generated: 2026-03-17 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 1 Confluence (context) + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.BlockFundingUpdate_v2 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BlockFundingUpdate_v2.sql*
