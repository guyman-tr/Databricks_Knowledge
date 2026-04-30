# Billing.CustomerToFunding_UpdateStatus

> Updates `CustomerFundingStatusID` (and optionally `IsRefundExcluded` and `LastUsedDate`) on a customer-funding link; archives prior state to `History.ActiveCustomerToFunding` via OUTPUT.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID (composite PK) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CustomerToFunding_UpdateStatus` is the primary procedure for changing the activation state of a customer's payment instrument. It drives the payment method lifecycle: activating a link (status=1), deactivating it (status=0), marking it as removed from deposits (status=3), or promoting it to extended-active (status=4). It optionally also updates the refund exclusion flag and the last-used date in the same call.

Originally created July 2017 by Geri Reshef (ticket 44716). Extended in 2019 by Adi to add `@IsRefundExcluded`. IsVerified added to history in January 2023 (PAYIL-5743, Shay Oren). @LastUseDate parameter added December 2024 by Elrom B. (PAYIL-8922).

---

## 2. Business Logic

### 2.1 Status Change with Optional Fields (IIF Pattern)

**What**: Always updates `CustomerFundingStatusID`; conditionally updates `IsRefundExcluded` and `LastUsedDate` if non-NULL parameters are supplied.

**Rules**:
- `CustomerFundingStatusID = @StatusID` - always applied (no NULL guard)
- `IsRefundExcluded = IIF(@IsRefundExcluded IS NULL, IsRefundExcluded, @IsRefundExcluded)` - preserved if NULL, overwritten if provided
- `LastUsedDate = IIF(@LastUseDate IS NULL, LastUsedDate, @LastUseDate)` - preserved if NULL, set to caller-supplied date if provided
- `OUTPUT DELETED.*` -> `History.ActiveCustomerToFunding` archives the pre-update state

**Status values** (from `Billing.CustomerToFunding` table doc):
| StatusID | Label | Meaning |
|----------|-------|---------|
| 0 | Deactivated | Payment method inactive for this customer |
| 1 | Active | Payment method active; shown in saved payment methods; eligible for deposits |
| 3 | RemovedFromDeposit | Filtered out of deposit flows when `@FilterRemovedFromDeposit=1` |
| 4 | Extended-Active | Added PAYUSOLA-6470 Mar 2023; treated as visible alongside 1 and 3 |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | Customer ID of the link to update. |
| 2 | @FundingID | INT | NO | - | VERIFIED | Payment instrument ID of the link to update. |
| 3 | @StatusID | INT | NO | - | VERIFIED | New CustomerFundingStatusID. Always applied. Values: 0=Deactivated, 1=Active, 3=RemovedFromDeposit, 4=Extended-Active. |
| 4 | @IsRefundExcluded | BIT | YES | NULL | CODE-BACKED | If supplied (non-NULL), overwrites the refund exclusion flag. If NULL, the existing value is preserved. NULL=preserve, 0=refund eligible, 1=refund excluded. |
| 5 | @LastUseDate | DATETIME | YES | NULL | CODE-BACKED | If supplied (non-NULL), sets LastUsedDate to this value. Added PAYIL-8922 Dec 2024. Allows callers to set a specific last-use date rather than always using GETUTCDATE(). If NULL, LastUsedDate is preserved. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @FundingID | Billing.CustomerToFunding | Write (UPDATE) | Status and optional field update |
| OUTPUT DELETED | History.ActiveCustomerToFunding | Write | Archives pre-update row state |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment service | @CID, @FundingID, @StatusID | Caller | Activates or deactivates a payment method for a customer |
| Refund management service | @CID, @FundingID, @IsRefundExcluded | Caller | Sets refund exclusion flag independently of status |

---

## 6. Dependencies

```
Billing.CustomerToFunding_UpdateStatus (procedure)
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
| Payment lifecycle service | External | Primary activation/deactivation handler |

---

## 7. Technical Details

**IIF vs ISNULL**: This procedure uses `IIF(@param IS NULL, column, @param)` instead of `ISNULL(@param, column)` for conditional field updates. Both patterns are semantically equivalent here.

**@StatusID is mandatory and always applied**: Unlike @IsRefundExcluded and @LastUseDate, @StatusID has no NULL-preservation logic. Calling with @StatusID=0 will deactivate even if that was not intended.

---

## 8. Sample Queries

### 8.1 Activate a payment method

```sql
EXEC Billing.CustomerToFunding_UpdateStatus
    @CID = 24186018,
    @FundingID = 12345,
    @StatusID = 1   -- Active
```

### 8.2 Deactivate and mark as refund-excluded

```sql
EXEC Billing.CustomerToFunding_UpdateStatus
    @CID = 24186018,
    @FundingID = 12345,
    @StatusID = 0,              -- Deactivated
    @IsRefundExcluded = 1       -- No longer a refund destination
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CustomerToFunding_UpdateStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CustomerToFunding_UpdateStatus.sql*
