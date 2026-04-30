# Billing.GetCustomerLastDeposit

> Returns the single most recent APPROVED deposit (PaymentStatusID=2) for a customer filtered by funding type, with Amount scaled to integer cents (BIGINT) - the canonical "last successful deposit by payment method" lookup.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingTypeID (PaymentStatusID=2 hardcoded) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerLastDeposit` retrieves the most recently APPROVED deposit for a customer using a specific payment method type. Unlike `GetCustomerLastAttemptedDeposit`, the PaymentStatusID=2 (Approved) filter is hardcoded - this SP only ever returns successful deposits.

This is the standard "last deposit" lookup used to:
- Verify that a customer has successfully deposited using a particular payment method (eligibility checks).
- Retrieve the most recent approved deposit details for customer support views, account summaries, and withdrawal routing (route withdrawal back to the same payment method as the last deposit).
- Check the last known currency and exchange rate for a funding type to assist with FX calculations.

Updated 2022-09-18 by Shay Oren to cast Amount to BIGINT (from INTEGER) to prevent integer overflow for very large deposit amounts (> ~$21M USD).

Only VIEW DEFINITION granted to PROD_BIadmins - called exclusively by application services via their own DB users (deposit service, withdrawal service, account service).

---

## 2. Business Logic

### 2.1 Approved-Only Latest Deposit Lookup

**What**: Returns the most recent deposit with PaymentStatusID=2 (Approved) for a given CID and FundingTypeID.

**Columns/Parameters Involved**: `@CID`, `@FundingTypeID`, hardcoded `PaymentStatusID = 2`

**Rules**:
- `WHERE BDEP.CID = @CID AND BDEP.PaymentStatusID = 2 AND BFUN.FundingTypeID = @FundingTypeID`
- `PaymentStatusID = 2` is hardcoded with comment `-- Approves` (a typo for "Approved"). This is NOT parameterized - the procedure always finds the last approved deposit.
- `TOP 1 ... ORDER BY BDEP.PaymentDate DESC`: returns the single most recent qualifying deposit. If no approved deposits exist for this customer and funding type, returns zero rows.
- Uses old-style comma-join syntax `FROM Billing.Deposit BDEP, Billing.Funding BFUN WHERE ... AND BDEP.FundingID = BFUN.FundingID` (functionally equivalent to INNER JOIN).
- `NOLOCK` hints on both tables: consistent with all deposit-retrieval SPs.

**Diagram**:
```
@CID + FundingTypeID + PaymentStatusID=2 (hardcoded)
        |
        v
Billing.Deposit (NOLOCK) ---- comma-join ---- Billing.Funding (NOLOCK)
  WHERE CID = @CID                           WHERE FundingTypeID = @FundingTypeID
    AND PaymentStatusID = 2 (Approved)
        |
  ORDER BY PaymentDate DESC
        |
      TOP 1 -> most recent approved deposit (or empty)
```

### 2.2 Amount Scaling (x100, BIGINT)

**What**: Amount returned as BIGINT cents - upgraded from INTEGER in 2022 to prevent overflow.

**Rules**:
- `CAST(BDEP.Amount*100 AS BIGINT)`: converts decimal USD amount to integer cents.
- BIGINT supports amounts up to ~$92 quadrillion before overflow - effectively unlimited for any real deposit.
- This was changed from INTEGER by Shay Oren on 2022-09-18 to fix a potential overflow bug for large deposits.
- Compare to `GetCustomerLastAttemptedDeposit` which still uses INTEGER (not yet updated).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Filters Billing.Deposit.CID. |
| 2 | @FundingTypeID | INTEGER | NO | - | CODE-BACKED | Payment method type. Filters Billing.Funding.FundingTypeID via comma-join (1=CreditCard, 2=Wire, 3=PayPal, etc.). Determines which payment channel's last approved deposit to retrieve. |

**Returns** (SELECT output columns):

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | DepositID | INTEGER | NO | CODE-BACKED | Primary key of the matching Billing.Deposit record. |
| 2 | DepotID | INTEGER | YES | CODE-BACKED | Depot/server routing identifier. Inherited from Billing.Deposit. |
| 3 | CID | INTEGER | NO | CODE-BACKED | Customer ID (same as @CID). Inherited from Billing.Deposit. |
| 4 | FundingID | INTEGER | YES | CODE-BACKED | Payment instrument used for this approved deposit. FK to Billing.Funding. Used for withdrawal routing (return funds to same method). |
| 5 | CurrencyID | INTEGER | NO | CODE-BACKED | Currency of the deposit. 1=USD, 2=EUR, 3=GBP, etc. FK to Dictionary.Currency. Used to infer the customer's preferred deposit currency. |
| 6 | PaymentStatusID | INTEGER | NO | CODE-BACKED | Always 2 (Approved) due to hardcoded filter. Returned for interface consistency with other deposit retrieval SPs. |
| 7 | Amount | BIGINT | NO | CODE-BACKED | Approved deposit amount scaled x100 (CAST(Amount*100 AS BIGINT)). A $100.00 deposit returns 10000. Updated to BIGINT in 2022 to handle large deposits without overflow. Caller divides by 100 to recover the original dollar amount. |
| 8 | ExchangeRate | DECIMAL(16,8) | YES | CODE-BACKED | Exchange rate applied at the time of the approved deposit. Not scaled - full decimal precision. Useful for FX calculations referencing the last deposit. |
| 9 | PaymentDate | DATETIME | YES | CODE-BACKED | Date and time of the approved deposit. The ORDER BY column - returned record has the latest PaymentDate among all approved deposits for this CID + FundingType. |
| 10 | TransactionID | CHAR(6) | YES | CODE-BACKED | 6-character payment provider transaction reference for the approved deposit. |
| 11 | PaymentData | XML/NVARCHAR | YES | CODE-BACKED | Provider-specific payment response payload for the approved transaction. Contains approval codes, card details (encrypted), or bank references. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, PaymentStatusID=2, PaymentDate | Billing.Deposit | Direct read (SELECT TOP 1) | Source of approved deposit records, ordered by PaymentDate DESC |
| FundingID -> FundingTypeID | Billing.Funding | Comma-join (filter only) | Used to apply FundingTypeID filter - no columns selected from Funding |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | EXECUTE (implicit) | Runtime caller | Called by deposit/withdrawal/account services via their own DB users |
| PROD_BIadmins | VIEW DEFINITION grant | Permission | BI admins can inspect procedure definition but not execute directly |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerLastDeposit (procedure)
├── Billing.Deposit (table)
└── Billing.Funding (table - comma-join for FundingTypeID filter only)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | SELECT TOP 1 WHERE CID + PaymentStatusID=2 filter, ORDER BY PaymentDate DESC |
| Billing.Funding | Table | Comma-join on FundingID to apply FundingTypeID filter |

### 6.2 Objects That Depend On This

No stored procedures found calling this in the SSDT repo. Called by application services via their own DB users.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Feature | Details |
|---------|---------|
| Amount type | CAST to BIGINT (updated 2022-09-18). Prevents INTEGER overflow for deposits > ~$21M. See comment in DDL: "Shay Oren 18/09/2022 Cast amount to BIGINT instead of INT". |
| PaymentStatusID hardcoded | Always filters PaymentStatusID=2 (Approved). To query other statuses, use GetCustomerLastAttemptedDeposit instead. |
| Comma-join syntax | Uses deprecated comma-join syntax (FROM t1, t2 WHERE t1.id = t2.id) instead of explicit INNER JOIN. Functionally identical but less readable. Not updated during the BIGINT fix. |
| Zero rows | Returns empty result set if no approved deposits exist for this CID + FundingType combination. |

---

## 8. Sample Queries

### 8.1 Last approved credit card deposit

```sql
-- FundingTypeID=1 (CreditCard), PaymentStatusID=2 hardcoded
EXEC [Billing].[GetCustomerLastDeposit]
    @CID = 1234567,
    @FundingTypeID = 1
-- Returns: most recent approved CC deposit with BIGINT Amount (cents)
```

### 8.2 Check if customer has ever deposited via wire

```sql
-- FundingTypeID=2 (Wire)
EXEC [Billing].[GetCustomerLastDeposit]
    @CID = 1234567,
    @FundingTypeID = 2
-- Empty result = no approved wire deposits; non-empty = last wire deposit details
```

### 8.3 Compare to GetCustomerLastAttemptedDeposit (approved variant)

```sql
-- These return equivalent data when @PaymentStatusID=2, with one key difference:
-- GetCustomerLastDeposit.Amount = BIGINT; GetCustomerLastAttemptedDeposit.Amount = INTEGER

-- GetCustomerLastDeposit (approved only, BIGINT amount):
EXEC [Billing].[GetCustomerLastDeposit] @CID = 1234567, @FundingTypeID = 1

-- GetCustomerLastAttemptedDeposit (any status, INTEGER amount):
EXEC [Billing].[GetCustomerLastAttemptedDeposit] @CID = 1234567, @FundingTypeID = 1, @PaymentStatusID = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.7/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerLastDeposit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerLastDeposit.sql*
