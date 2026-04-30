# Billing.GetCustomerLastFundingByFundingType

> Returns all active payment instruments of a given type for a customer, ordered by most recent use (last approved deposit date OR last-used date, whichever is later), with optional filtering for withdraw-blocked and removed-from-deposit instruments. Called by the Deposit Setup service to populate the payment method selection list.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingTypeID; optional @FilterWithdrawBlocked (default 1), @FilterRemovedFromDeposit (default 0) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerLastFundingByFundingType` retrieves all saved payment instruments of a specific type (credit cards, wire accounts, etc.) that are currently usable for deposits by a customer. Unlike the "Last Deposit" family of SPs (which return TOP 1), this procedure returns ALL matching funding instruments and orders them by recency of use - the most recently-used instrument appears first, making it natural for a UI to pre-select the most recent payment method.

The "OrderDate" is the maximum of two dates: when the customer last used the instrument on the system (`CustomerToFunding.LastUsedDate`) versus when the last approved deposit was made through it (`Billing.Deposit.PaymentDate`). This dual-date logic corrects for cases where `LastUsedDate` may be stale.

Key design decisions:
- `CustomerFundingStatusID IN (1, 3, 4)`: Includes Active (1), RemovedFromDeposit (3), and Extended-Active (4). The deposit UI can further filter using `@FilterRemovedFromDeposit`.
- `@FilterWithdrawBlocked=1` (default): Excludes instruments flagged as refund-excluded at either the CID level or system level, AND instruments marked as third-party blocked (`BackOffice.CustomerToThirdPartyFundings`). This is a fraud/compliance filter.
- `@FilterRemovedFromDeposit=0` (default): Does NOT filter out status=3 instruments by default, allowing callers to see them if needed.

Jira history:
- PAYUS-1379 (2020-08-09): Added `@FilterWithdrawBlocked` parameter
- PAYUS-1512 (2020-08-30): Added `@FilterRemovedFromDeposit` parameter
- PAYUSOLA-6470 (2023-03-16, ItayH): Added CustomerFundingStatusID=4 to the IN list

Called exclusively by the Deposit Setup service (`DepositSetupUser` EXECUTE grant).

---

## 2. Business Logic

### 2.1 CTE-Based Active Funding Retrieval with Dual-Date Ordering

**What**: A CTE gathers all active instruments for the CID+FundingType, enriched with last-deposit-date and blocking flags, then the outer SELECT applies optional filters and orders by activity recency.

**Columns/Parameters Involved**: `@CID`, `@FundingTypeID`, `CustomerFundingStatusID`, `LastUsedDate`, `PaymentDate`, `OrderDate`

**Rules**:
- `WHERE BCTF.CustomerFundingStatusID IN (1, 3, 4)`: Only Active, RemovedFromDeposit, and Extended-Active statuses returned by CTE.
- `OUTER APPLY (SELECT TOP 1 PaymentDate FROM Billing.Deposit WHERE CID = @CID AND PaymentStatusID = 2 AND FundingID = BF.FundingID ORDER BY PaymentDate DESC)`: For each instrument, finds its last approved deposit date. OUTER APPLY means if no deposits exist for the instrument, BS.PaymentDate is NULL.
- `IIF(ISNULL(BS.PaymentDate, '20000101') > LastUsedDate, BS.PaymentDate, LastUsedDate) AS OrderDate`: Effective "last activity" date is the later of last deposit or `LastUsedDate`. If no deposits, defaults to a sentinel date (2000-01-01) so `LastUsedDate` wins.
- `ORDER BY OrderDate DESC, FundingID DESC`: Primary sort by recency; secondary by FundingID (consistent tiebreaker).

**Diagram**:
```
@CID + @FundingTypeID
       |
       v
Billing.CustomerToFunding (BCTF)
  WHERE CID=@CID AND FundingTypeID=@FundingTypeID AND StatusID IN (1,3,4)
       |
  INNER JOIN Billing.Funding (BF) on FundingID
       |
  LEFT JOIN BackOffice.CustomerToThirdPartyFundings (CTTPF) -> IsThirdPartBlocked flag
       |
  OUTER APPLY Billing.Deposit -> last approved deposit date per instrument (BS.PaymentDate)
       |
  OrderDate = MAX(LastUsedDate, BS.PaymentDate or '20000101')
       |
  --> MyCTE (all instruments with enriched dates and blocking flags)
              |
       Apply outer filters (@FilterWithdrawBlocked, @FilterRemovedFromDeposit)
              |
       ORDER BY OrderDate DESC, FundingID DESC
              |
       Result set (all qualifying instruments)
```

### 2.2 Withdraw-Block Filter (@FilterWithdrawBlocked)

**What**: When enabled (default=1), excludes instruments that are blocked for refund/withdrawal use.

**Rules**:
- `@FilterWithdrawBlocked = 1` triggers: `WHERE cidIsRefundExcluded = 0 AND sysIsRefundExcluded = 0 AND IsThirdPartBlocked = 0`
- `cidIsRefundExcluded = BCTF.IsRefundExcluded`: per-customer refund exclusion flag. Set by `Billing.FundingBlock`.
- `sysIsRefundExcluded = BF.IsRefundExcluded`: system-level refund exclusion on the Funding record itself.
- `IsThirdPartBlocked = IIF(CTTPF.CID IS NULL, 0, 1)`: 1 if a row exists in `BackOffice.CustomerToThirdPartyFundings` for this CID+FundingID combination (third-party funding is blocked).
- When `@FilterWithdrawBlocked = 0`: all instruments returned regardless of exclusion/blocking state.

### 2.3 Removed-From-Deposit Filter (@FilterRemovedFromDeposit)

**What**: Optionally hides instruments with CustomerFundingStatusID=3 (RemovedFromDeposit).

**Rules**:
- `@FilterRemovedFromDeposit = 1` triggers: `WHERE CustomerFundingStatusID != 3`
- Default is 0 (do not filter) - callers that want only deposit-eligible instruments pass 1.
- The CTE still includes status=3 instruments; this filter is applied in the outer SELECT.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters Billing.CustomerToFunding.CID. |
| 2 | @FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type. Filters Billing.Funding.FundingTypeID (1=CreditCard, 2=Wire, 3=PayPal, etc.). Determines which payment channel's instruments to list. |
| 3 | @FilterWithdrawBlocked | BIT | NO | 1 | CODE-BACKED | When 1 (default), excludes instruments where cidIsRefundExcluded=1, sysIsRefundExcluded=1, or IsThirdPartBlocked=1. Set to 0 to see all instruments including blocked ones. Added PAYUS-1379. |
| 4 | @FilterRemovedFromDeposit | BIT | NO | 0 | CODE-BACKED | When 1, excludes instruments with CustomerFundingStatusID=3 (RemovedFromDeposit). Default 0 - includes them. Pass 1 to get only deposit-eligible instruments. Added PAYUS-1512. |

**Returns** (SELECT output columns from MyCTE outer query):

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | LastUsedDate | DATETIME | YES | CODE-BACKED | Date the customer last used this payment instrument on the platform. From Billing.CustomerToFunding.LastUsedDate. |
| 2 | PaymentDate | DATETIME | YES | CODE-BACKED | Date of the last APPROVED deposit made through this instrument. NULL if no approved deposits exist. From OUTER APPLY on Billing.Deposit. |
| 3 | FundingTypeID | INT | NO | CODE-BACKED | Always equal to @FundingTypeID. Returned for convenience (set to @FundingTypeID literal in the CTE SELECT). |
| 4 | FundingData | NVARCHAR(MAX) | YES | CODE-BACKED | Payment instrument details as NVARCHAR (CAST from Billing.Funding.FundingData XML/binary). Contains card number (masked/encrypted), expiry, bank account details, etc. |
| 5 | FundingID | INT | NO | CODE-BACKED | Payment instrument primary key. FK to Billing.Funding. Unique identifier for this payment method. |
| 6 | CustomerFundingStatusID | INT | NO | CODE-BACKED | Per-customer status of this instrument (1=Active, 3=RemovedFromDeposit, 4=Extended-Active). From Billing.CustomerToFunding. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, FundingID, StatusID, LastUsedDate | Billing.CustomerToFunding | INNER JOIN (primary source) | Source of per-customer payment method links and status |
| FundingID, FundingData, FundingTypeID, IsRefundExcluded | Billing.Funding | INNER JOIN | Payment instrument details and system-level block flags |
| FundingID, CID | BackOffice.CustomerToThirdPartyFundings | LEFT JOIN | Third-party funding block check; presence of row = IsThirdPartBlocked=1 |
| CID, FundingID, PaymentStatusID=2, PaymentDate | Billing.Deposit | OUTER APPLY (TOP 1) | Last approved deposit date per instrument for OrderDate calculation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositSetupUser | EXECUTE grant | Permission | Deposit Setup service uses this to populate payment method selection in deposit flows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerLastFundingByFundingType (procedure)
├── Billing.CustomerToFunding (table - primary join)
├── Billing.Funding (table - instrument details + IsRefundExcluded)
├── BackOffice.CustomerToThirdPartyFundings (table - third-party block check)
└── Billing.Deposit (table - OUTER APPLY for last deposit date)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | CTE base: WHERE CID + FundingTypeID + StatusID IN (1,3,4) |
| Billing.Funding | Table | INNER JOIN for FundingData, IsRefundExcluded, FundingTypeID filter |
| BackOffice.CustomerToThirdPartyFundings | Table | LEFT JOIN to detect third-party blocking |
| Billing.Deposit | Table | OUTER APPLY: last approved deposit date per instrument |

### 6.2 Objects That Depend On This

No stored procedures found calling this in the SSDT repo. Called by DepositSetupUser application service.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| CTE without TOP/ORDER | KateM removed TOP 1000000 and ORDER BY from the CTE body; ORDER BY is now only in the outer SELECT. This avoids optimizer hints and non-standard behavior. |
| Returns multiple rows | Unlike GetCustomerLastDeposit (TOP 1), this returns ALL matching instruments. May return 0 rows if customer has no active instruments of this type. |
| DISTINCT in CTE | CTE uses SELECT DISTINCT to prevent duplicate rows if a customer has multiple CustomerToFunding entries for the same FundingID (edge case). |
| No NOLOCK hints | Billing.CustomerToFunding and Billing.Funding are NOT read with NOLOCK (to get consistent payment method state); only the OUTER APPLY Deposit read uses NOLOCK. |

---

## 8. Sample Queries

### 8.1 Get all active credit cards for a customer (default filters)

```sql
-- FundingTypeID=1, FilterWithdrawBlocked=1 (default), FilterRemovedFromDeposit=0 (default)
EXEC [Billing].[GetCustomerLastFundingByFundingType]
    @CID = 1234567,
    @FundingTypeID = 1
-- Returns: all active CC instruments for this customer, ordered by most recent use
```

### 8.2 Get only deposit-eligible cards (excluding removed-from-deposit)

```sql
EXEC [Billing].[GetCustomerLastFundingByFundingType]
    @CID = 1234567,
    @FundingTypeID = 1,
    @FilterRemovedFromDeposit = 1
-- Excludes CustomerFundingStatusID=3 instruments
```

### 8.3 Get all cards including blocked ones (admin/support view)

```sql
EXEC [Billing].[GetCustomerLastFundingByFundingType]
    @CID = 1234567,
    @FundingTypeID = 1,
    @FilterWithdrawBlocked = 0
-- Returns ALL instruments including refund-excluded and third-party-blocked
```

---

## 9. Atlassian Knowledge Sources

Jira tickets referenced in DDL comments:
- **PAYUS-1379**: Added @FilterWithdrawBlocked parameter (2020-08-09)
- **PAYUS-1512**: Added @FilterRemovedFromDeposit parameter (2020-08-30)
- **PAYUSOLA-6470**: Added CustomerFundingStatusID=4 to IN list (2023-03-16, ItayH)

No Confluence sources found for this specific procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 3 Jira (from DDL comments) | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerLastFundingByFundingType | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerLastFundingByFundingType.sql*
