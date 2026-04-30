# Billing.FundingBlock

> Blocks (or updates block/refund-exclusion status of) a funding instrument and atomically archives all associated CustomerToFunding records to History.ActiveCustomerToFunding - the back-office funding block/unblock operation.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Billing.Funding + UPDATE Billing.CustomerToFunding (OUTPUT INTO History.ActiveCustomerToFunding) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingBlock` is used by back-office operators (and risk systems) to block a payment instrument - preventing it from being used for future deposits or withdrawals. When a funding instrument is blocked, all customer-funding associations (`Billing.CustomerToFunding`) are also updated, with the previous state archived to `History.ActiveCustomerToFunding` via the OUTPUT clause.

The SP supports fine-grained control: `@IsBlocked` and `@IsRefundExcluded` are both ISNULL-pattern parameters, meaning each can be updated independently without affecting the other. This allows operations to separately flag a funding instrument as "blocked for new deposits" vs. "excluded from refund eligibility" without touching both flags.

FundingID=1 is permanently protected (system-wide internal funding) - the SP hard-fails if an operator tries to block it.

Version history: initial (Avraham Lahmi, 24/02/2019), FundingID=1 guard (Shay Oren, 24/01/2022), @IsRefundExcluded parameter + optional @IsBlocked/@Description (PAYIL-5724, 16/01/2023), IsVerified in History (PAYIL-5743, 23/01/2023).

---

## 2. Business Logic

### 2.1 FundingID=1 Guard

**Rules**: `IF @FundingID = 1 -> RAISERROR('Billing.FundingBlock Trying to block FundingID Number 1', 16, 1) + RETURN 6000`. FundingID=1 is a reserved/internal funding record that must never be blocked.

### 2.2 Funding Record Update

**Rules**:
- `SET IsBlocked = ISNULL(@IsBlocked, IsBlocked)` - only changes if @IsBlocked is provided (non-NULL).
- `SET IsRefundExcluded = ISNULL(@IsRefundExcluded, IsRefundExcluded)` - same pattern.
- `SET BlockedDescription = ISNULL(@Description, BlockedDescription)` - same pattern.
- `SET ManagerID = @ManagerID` (always overwritten).
- `SET BlockedAt = @Now` (always updated to current UTC time).
- @@ROWCOUNT=0 OR @@ERROR!=0 -> RAISERROR(60000).

### 2.3 CustomerToFunding Archive and Update (OUTPUT clause)

**What**: Archives pre-update state of all CustomerToFunding records for this funding to History, then updates them.

**Rules**:
- `UPDATE Billing.CustomerToFunding ... OUTPUT DELETED.* INTO History.ActiveCustomerToFunding WHERE FundingID = @FundingID`.
- The OUTPUT clause captures the DELETED (pre-update) values. This gives a complete history of each association's state before this block operation.
- Same ISNULL pattern for IsBlocked, IsRefundExcluded, BlockedDescription.
- `BlockManagerID = @BlockManagerID` - captures which manager performed the block specifically on CustomerToFunding rows (separate from the general @ManagerID).
- `IsVerified` preserved from DELETED (not changed by block operation, written as-is to history).

```
FundingID=1 guard
BEGIN TRANSACTION:
  -> UPDATE Billing.Funding (IsBlocked, IsRefundExcluded, BlockedDescription, ManagerID, BlockedAt)
  -> If Funding update succeeds:
     -> UPDATE Billing.CustomerToFunding (same ISNULL fields)
        OUTPUT DELETED.* INTO History.ActiveCustomerToFunding
COMMIT
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INTEGER | NO | - | CODE-BACKED | PK of the funding instrument to block. FK to Billing.Funding.FundingID. Must not be 1 (reserved internal funding). |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | Manager/system user performing the block. Written to Billing.Funding.ManagerID and Billing.CustomerToFunding.ManagerID (always overwritten, not ISNULL-pattern). |
| 3 | @IsBlocked | BIT | YES | NULL | CODE-BACKED | Block flag for the funding instrument. ISNULL-pattern: NULL = don't change existing value. 1=blocked (prevents use), 0=unblocked. Applied to both Billing.Funding and Billing.CustomerToFunding. Added optional PAYIL-5724. |
| 4 | @Description | VARCHAR(255) | YES | NULL | CODE-BACKED | Reason for blocking. ISNULL-pattern: NULL = preserve existing. Written to Billing.Funding.BlockedDescription and Billing.CustomerToFunding.BlockedDescription. |
| 5 | @IsRefundExcluded | BIT | YES | NULL | CODE-BACKED | Refund exclusion flag. ISNULL-pattern: NULL = don't change. 1=this funding instrument cannot receive refunds. 0=refund eligible. Allows blocking refunds independently of blocking deposits. Added PAYIL-5724. |
| 6 | @BlockManagerID | INT | YES | NULL | CODE-BACKED | Block-specific manager ID written only to Billing.CustomerToFunding.BlockManagerID (not to Billing.Funding). Separate from @ManagerID for granular tracking of who performed the customer-funding block. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID | Billing.Funding | MODIFIER (UPDATE) | Sets IsBlocked, IsRefundExcluded, ManagerID, BlockedAt, BlockedDescription. |
| @FundingID | Billing.CustomerToFunding | MODIFIER (UPDATE + OUTPUT) | Updates block fields; archives DELETED rows to History. |
| DELETED from CustomerToFunding | History.ActiveCustomerToFunding | WRITER (INSERT via OUTPUT) | Archives pre-block state of all customer-funding associations. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office / risk management | @FundingID | EXEC | Called when a payment instrument must be blocked (fraud, expired card, etc.). |

---

## 6. Dependencies

```
Billing.FundingBlock (procedure)
+-- Billing.Funding (table)
+-- Billing.CustomerToFunding (table)
+-- History.ActiveCustomerToFunding (table) [cross-schema, OUTPUT target]
```

---

## 7. Technical Details

**OUTPUT clause**: The `OUTPUT DELETED.* INTO History.ActiveCustomerToFunding` pattern captures the pre-update state of all affected CustomerToFunding rows atomically within the transaction. This is more efficient than a separate INSERT+SELECT pattern.

**IsVerified in History**: Added PAYIL-5743 (23/01/2023) - the `IsVerified` column is now included in the OUTPUT to History.ActiveCustomerToFunding, preserving KYC verification state at the time of blocking.

**Error codes**: 6000 for FundingID=1 guard, 60000 for DML failures.

---

## 8. Sample Queries

### 8.1 Block a funding instrument

```sql
EXEC [Billing].[FundingBlock]
    @FundingID = 67890,
    @ManagerID = 999,
    @IsBlocked = 1,
    @Description = 'Blocked due to fraud investigation case #12345',
    @BlockManagerID = 999;
```

### 8.2 Mark as refund-excluded only (without blocking deposits)

```sql
EXEC [Billing].[FundingBlock]
    @FundingID = 67890,
    @ManagerID = 999,
    @IsBlocked = NULL,      -- don't change block status
    @IsRefundExcluded = 1,  -- only update refund exclusion
    @Description = 'Excluded from refunds per compliance directive';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found directly for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingBlock | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingBlock.sql*
