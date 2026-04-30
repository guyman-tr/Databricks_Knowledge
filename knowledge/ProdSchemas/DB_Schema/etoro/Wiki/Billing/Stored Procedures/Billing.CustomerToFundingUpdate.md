# Billing.CustomerToFundingUpdate

> Full ISNULL partial-update of any/all columns in a `Billing.CustomerToFunding` row; the general-purpose modifier for the customer-funding association, including blocking fields; archives prior state to history.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingID + @CID (composite PK) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CustomerToFundingUpdate` is the general-purpose updater for `Billing.CustomerToFunding`. While the other `CustomerToFunding_Update*` procedures each modify a specific subset of columns, this procedure can modify any or all columns in a single call using the ISNULL partial-update pattern (NULL parameters preserve existing values).

Created November 2022 by Elrom B. (PAYIL-5319). IsVerified and BlockManagerID columns were added/updated in January 2023 (PAYIL-5743, Shay Oren).

This procedure is used when multiple fields need to be updated atomically - for example, setting both `IsBlocked=1` and `BlockedDescription` and `BlockManagerID` in one operation without calling separate procedures.

---

## 2. Business Logic

### 2.1 ISNULL Partial-Update Pattern

**What**: Updates all mutable columns, using `ISNULL(@param, column)` to preserve existing values for any NULL parameter.

**Parameters and preservation rules**:
| Column | Parameter | Behavior |
|--------|-----------|----------|
| Occurred | @Occurred | ISNULL preserved |
| DepositTypeID | @DepositTypeID | ISNULL preserved |
| ReasonID | @ReasonID | ISNULL preserved |
| LastUsedDate | @LastUsedDate | ISNULL preserved |
| CustomerFundingStatusID | @CustomerFundingStatusID | ISNULL preserved |
| IsBlocked | @IsBlocked | ISNULL preserved |
| IsRefundExcluded | @IsRefundExcluded | ISNULL preserved |
| ManagerID | @ManagerID | ISNULL preserved |
| BlockedAt | @BlockedAt | ISNULL preserved |
| BlockedDescription | @BlockedDescription | ISNULL preserved |
| IsVerified | @IsVerified | ISNULL preserved |
| BlockManagerID | @BlockManagerID | **Always overwritten** (no ISNULL!) - `BlockManagerID = @BlockManagerID` |

**Critical exception**: `BlockManagerID` is always overwritten, even when NULL. Calling this procedure with `@BlockManagerID=NULL` clears the existing `BlockManagerID` value. All other parameters preserve existing values when NULL.

**Rules**:
- `OUTPUT DELETED.*` -> `History.ActiveCustomerToFunding` archives pre-update state
- WHERE clause: `FundingID = @FundingID AND CID = @CID`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INTEGER | NO | - | VERIFIED | Payment instrument ID. Composite PK component. |
| 2 | @CID | INTEGER | NO | - | VERIFIED | Customer ID. Composite PK component. |
| 3 | @Occurred | DATETIME | YES | NULL | CODE-BACKED | If supplied, overrides the link creation date. NULL preserves existing. |
| 4 | @DepositTypeID | INTEGER | YES | NULL | CODE-BACKED | If supplied, overrides deposit type. NULL preserves existing. Values: 1=Regular, 2=Instant, 3=RecurringDeposit. |
| 5 | @ReasonID | INTEGER | YES | NULL | CODE-BACKED | If supplied, overrides reason code. NULL preserves existing. |
| 6 | @LastUsedDate | DATETIME | YES | NULL | CODE-BACKED | If supplied, sets LastUsedDate to this value. NULL preserves existing. |
| 7 | @CustomerFundingStatusID | INTEGER | YES | NULL | CODE-BACKED | If supplied, overrides status. NULL preserves existing. Values: 0=Deactivated, 1=Active, 3=RemovedFromDeposit, 4=Extended-Active. |
| 8 | @IsBlocked | BIT | YES | NULL | CODE-BACKED | If supplied, sets block flag. NULL preserves existing. |
| 9 | @IsRefundExcluded | BIT | YES | NULL | CODE-BACKED | If supplied, sets refund exclusion. NULL preserves existing. |
| 10 | @ManagerID | INTEGER | YES | NULL | CODE-BACKED | If supplied, records the manager performing a block/unblock. NULL preserves existing. |
| 11 | @BlockedAt | DATETIME | YES | NULL | CODE-BACKED | If supplied, sets block timestamp. NULL preserves existing. |
| 12 | @BlockedDescription | VARCHAR(255) | YES | NULL | CODE-BACKED | If supplied, sets block description. NULL preserves existing. |
| 13 | @IsVerified | BIT | YES | NULL | CODE-BACKED | If supplied, sets verification flag. NULL preserves existing. |
| 14 | @BlockManagerID | INT | YES | NULL | CODE-BACKED | ALWAYS overwritten (no ISNULL). Records the manager who applied the block operation. Passing NULL clears the existing BlockManagerID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID + @CID | Billing.CustomerToFunding | Write (UPDATE) | Partial update of any/all columns |
| OUTPUT DELETED | History.ActiveCustomerToFunding | Write | Archives prior row state |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment/blocking services | All params | Caller | General-purpose CTF updater for multi-field updates (PAYIL-5319) |

---

## 6. Dependencies

```
Billing.CustomerToFundingUpdate (procedure)
+-- Billing.CustomerToFunding (table) [UPDATE target]
+-- History.ActiveCustomerToFunding (table) [OUTPUT target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | UPDATE target |
| History.ActiveCustomerToFunding | Table | History OUTPUT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment/blocking service | External | General-purpose multi-field update (PAYIL-5319) |

---

## 7. Technical Details

**BlockManagerID not ISNULL-protected**: This is the only column in the UPDATE that lacks `ISNULL(@param, column)`. It may be intentional (to allow explicit clearing of the field) or a code oversight. Callers who do not intend to modify `BlockManagerID` should be aware that passing NULL clears it.

**Comparison to other procedures in this family**: This procedure is the most flexible but also the most dangerous for accidental overwrites. For targeted updates, prefer the dedicated procedures (`_UpdateStatus`, `_UpdateDate`, `_UpdateType`, etc.) which have narrower scope.

---

## 8. Sample Queries

### 8.1 Block a customer's funding (multi-field update)

```sql
EXEC Billing.CustomerToFundingUpdate
    @FundingID = 12345,
    @CID = 24186018,
    @IsBlocked = 1,
    @BlockedAt = GETUTCDATE(),
    @BlockedDescription = 'Fraud investigation',
    @ManagerID = 9999,
    @BlockManagerID = 9999
-- All other params NULL: CustomerFundingStatusID, IsRefundExcluded, etc. preserved
```

### 8.2 Set verification status only

```sql
EXEC Billing.CustomerToFundingUpdate
    @FundingID = 12345,
    @CID = 24186018,
    @IsVerified = 1,
    @BlockManagerID = NULL  -- WARNING: this clears BlockManagerID if it was set
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CustomerToFundingUpdate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CustomerToFundingUpdate.sql*
