# Billing.GetCustomerLastAttemptedDeposit

> Returns the single most recent deposit attempt for a customer that matches both a specific payment status and funding type - enabling callers to check the last attempt in any deposit state (failed, pending, approved, etc.) for a given payment method.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingTypeID + @PaymentStatusID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerLastAttemptedDeposit` retrieves the most recent deposit record matching a specific CID, funding type, and payment status. The word "Attempted" distinguishes this from `GetCustomerLastDeposit` (which hardcodes PaymentStatusID=2/Approved): this procedure lets the caller query for ANY status - most critically, failed or pending attempts.

Typical use cases:
- Check if a customer's last credit card (FundingTypeID=1) deposit attempt failed (PaymentStatusID=3/Declined) - to offer retry flows or alternative payment methods.
- Look up the most recent pending wire transfer (PaymentStatusID=1/New) to determine if one is already in progress.
- Retrieve the last declined deposit to log the decline data for fraud analysis or customer support.

The result always includes `PaymentData` (the XML/structured payment payload), which contains provider-specific response data useful for diagnosing declined transactions.

Called by application services (deposit service, payment service). Only VIEW DEFINITION is granted to PROD_BIadmins in the permissions file - no EXECUTE grant to reporting users, indicating this is exclusively for real-time service use.

---

## 2. Business Logic

### 2.1 Status-Parameterized Latest-Record Lookup

**What**: Returns TOP 1 deposit ordered by PaymentDate DESC, filtered by all three criteria simultaneously.

**Columns/Parameters Involved**: `@CID`, `@FundingTypeID`, `@PaymentStatusID`, `Billing.Deposit.PaymentStatusID`, `Billing.Funding.FundingTypeID`

**Rules**:
- `WHERE BDEP.CID = @CID AND BDEP.PaymentStatusID = @PaymentStatusID AND BFUN.FundingTypeID = @FundingTypeID`
- `TOP 1 ... ORDER BY BDEP.PaymentDate DESC`: returns only the single most recent qualifying record. If no deposits match all three filters, returns zero rows (not an error).
- INNER JOIN `Billing.Funding` on FundingID: the join is used ONLY to apply the `FundingTypeID` filter - no extra columns are selected from Funding.
- `NOLOCK` hints on both tables: high-read-frequency, accepts dirty reads for latency. Consistent with all other deposit-related SPs.

**Diagram**:
```
@CID + @PaymentStatusID         @FundingTypeID
        |                              |
        v                              v
Billing.Deposit (NOLOCK) ---- INNER JOIN Billing.Funding (NOLOCK)
  WHERE CID = @CID                 WHERE FundingTypeID = @FundingTypeID
    AND PaymentStatusID = @PaymentStatusID
        |
  ORDER BY PaymentDate DESC
        |
      TOP 1 -> single result row (or empty)
```

### 2.2 Amount Scaling (x100, INTEGER)

**What**: Amount returned as integer cents (x100), consistent with other deposit retrieval SPs.

**Rules**:
- `CAST(BDEP.Amount*100 AS INTEGER)`: converts decimal USD amount to integer cents representation.
- Uses INTEGER (not BIGINT as in `GetCustomerLastDeposit` post-2022 update). For very large deposit amounts (>$21 million), INTEGER overflow is theoretically possible.
- ExchangeRate returned at full DECIMAL precision - not scaled.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Filters Billing.Deposit.CID. |
| 2 | @FundingTypeID | INTEGER | NO | - | CODE-BACKED | Payment method type. Filters Billing.Funding.FundingTypeID via JOIN (1=CreditCard, 2=Wire, 3=PayPal, etc.). Determines which payment channel's last attempt to retrieve. |
| 3 | @PaymentStatusID | INTEGER | NO | - | CODE-BACKED | Target deposit status. Filters Billing.Deposit.PaymentStatusID. Common values: 1=New/Pending, 2=Approved, 3=Declined. Caller controls which status to inspect. |

**Returns** (SELECT output columns - same schema as GetCustomerLastDeposit):

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | DepositID | INTEGER | NO | CODE-BACKED | Primary key of the matching Billing.Deposit record. |
| 2 | DepotID | INTEGER | YES | CODE-BACKED | Depot/server routing identifier. Inherited from Billing.Deposit. |
| 3 | CID | INTEGER | NO | CODE-BACKED | Customer ID (same as @CID). Inherited from Billing.Deposit. |
| 4 | FundingID | INTEGER | YES | CODE-BACKED | Payment instrument used for this deposit attempt. FK to Billing.Funding. Caller can use this to retrieve full payment method details. |
| 5 | CurrencyID | INTEGER | NO | CODE-BACKED | Currency of the deposit. 1=USD, 2=EUR, 3=GBP, etc. FK to Dictionary.Currency. |
| 6 | PaymentStatusID | INTEGER | NO | CODE-BACKED | Status of the deposit (same as @PaymentStatusID filter). 1=New, 2=Approved, 3=Declined. |
| 7 | Amount | INTEGER | NO | CODE-BACKED | Deposit amount scaled x100 (CAST(Amount*100 AS INTEGER)). A $50.00 deposit returns 5000. Caller divides by 100 to recover dollars. |
| 8 | ExchangeRate | DECIMAL(16,8) | YES | CODE-BACKED | Exchange rate at the time of the deposit attempt. Not scaled - full decimal precision. |
| 9 | PaymentDate | DATETIME | YES | CODE-BACKED | Date and time of the deposit attempt. The ORDER BY column - the returned record has the latest PaymentDate for all matching criteria. |
| 10 | TransactionID | CHAR(6) | YES | CODE-BACKED | 6-character payment provider transaction reference. May be NULL for failed attempts where the provider did not assign a transaction ID. |
| 11 | PaymentData | XML/NVARCHAR | YES | CODE-BACKED | Provider-specific payment response payload. Contains detailed decline reason codes, fraud flags, or approval data from the payment gateway. Most useful for failed attempts to diagnose decline reasons. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, PaymentStatusID, PaymentDate | Billing.Deposit | Direct read (SELECT TOP 1) | Source of deposit records - filtered by CID + status, ordered by PaymentDate DESC |
| FundingID -> FundingTypeID | Billing.Funding | INNER JOIN (filter only) | Used to apply FundingTypeID filter - no columns selected from this table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | EXECUTE (implicit) | Runtime caller | Called by deposit/payment services - no EXECUTE grant in permissions file, called via service DB user |
| PROD_BIadmins | VIEW DEFINITION grant | Permission | BI admins can inspect procedure definition but cannot execute it directly |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerLastAttemptedDeposit (procedure)
├── Billing.Deposit (table)
└── Billing.Funding (table - join for FundingTypeID filter only)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | SELECT TOP 1 WHERE CID + PaymentStatusID filter, ORDER BY PaymentDate DESC |
| Billing.Funding | Table | INNER JOIN on FundingID to apply FundingTypeID filter |

### 6.2 Objects That Depend On This

No stored procedures found calling this in the SSDT repo. Called by application services via their own DB users.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| Amount type | CAST to INTEGER (not BIGINT); overflow possible for amounts > ~$21M. Compare to GetCustomerLastDeposit which was updated to BIGINT in 2022. |
| Zero rows | Returns empty result set (0 rows) if no deposit matches all three filters - callers must handle this case. |
| NOLOCK | Both Billing.Deposit and Billing.Funding read with NOLOCK - accepts dirty reads for latency. |

---

## 8. Sample Queries

### 8.1 Find the last declined credit card deposit for a customer

```sql
-- FundingTypeID=1 (CreditCard), PaymentStatusID=3 (Declined)
EXEC [Billing].[GetCustomerLastAttemptedDeposit]
    @CID = 1234567,
    @FundingTypeID = 1,
    @PaymentStatusID = 3
-- Returns: most recent declined CC deposit, including PaymentData with decline reason
```

### 8.2 Check for pending wire transfer

```sql
-- FundingTypeID=2 (Wire), PaymentStatusID=1 (New/Pending)
EXEC [Billing].[GetCustomerLastAttemptedDeposit]
    @CID = 1234567,
    @FundingTypeID = 2,
    @PaymentStatusID = 1
-- Returns: in-progress wire deposit if one exists; empty set if none pending
```

### 8.3 Compare to approved deposit (same as GetCustomerLastDeposit when status=2)

```sql
-- PaymentStatusID=2 (Approved) produces equivalent result to GetCustomerLastDeposit
EXEC [Billing].[GetCustomerLastAttemptedDeposit]
    @CID = 1234567,
    @FundingTypeID = 1,
    @PaymentStatusID = 2
-- NOTE: GetCustomerLastDeposit returns BIGINT for Amount; this SP returns INTEGER
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.6/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerLastAttemptedDeposit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerLastAttemptedDeposit.sql*
