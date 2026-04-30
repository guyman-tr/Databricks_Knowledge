# Billing.FundingTypeStatusLimitList

> Table-valued parameter type carrying per-funding-type transaction limit rules, used by `Billing.CountTransactionsWithTimeLimitForStatus` to count transactions against time-window thresholds.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | User Defined Type |
| **Key Identifier** | (FundingTypeId, StatusId) composite - uniqueness enforced by consumer |
| **Partition** | N/A |
| **Indexes** | N/A - inline table type, no persistent indexes |

---

## 1. Business Meaning

`Billing.FundingTypeStatusLimitList` is a table-valued parameter (TVP) type used to pass a set of funding-type/status limit configurations to the `Billing.CountTransactionsWithTimeLimitForStatus` stored procedure. Each row defines a single rule: for a specific payment method (`FundingTypeId`) and transaction status (`StatusId`), count transactions that fall within a configurable lookback window (`Limit`) to determine if a threshold is being approached or exceeded.

This type exists to allow the limit-checking logic to be called with an arbitrary set of funding-type/status combinations in one batch, rather than issuing separate queries per rule. This supports quota enforcement and rate-limiting for deposit and withdrawal processing.

Data flows from the calling service: the application constructs the rule set as a `FundingTypeStatusLimitList` TVP and passes it to `CountTransactionsWithTimeLimitForStatus`, which joins it against `Billing.WithdrawToFunding` (withdrawals) and `Billing.Deposit` (deposits) to return the transaction counts per rule.

---

## 2. Business Logic

### 2.1 Time-Window Count Configuration

**What**: Each row defines one limit rule: count transactions of a specific funding type with a specific status within a time window.

**Columns/Parameters Involved**: `FundingTypeId`, `StatusId`, `Limit`, `IsByDays`, `IsDeposit`

**Rules**:
- `Limit` is the number of time units (days or hours) defining the lookback window
- `IsByDays=1` means the window is in calendar days (with weekend non-working day adjustment); `IsByDays=0` means hours
- `IsDeposit=1` means count Deposit records matching `StatusId = PaymentStatusID`; `IsDeposit=0` means count WithdrawToFunding records matching `StatusId = CashoutStatusID`
- Accounts with `PlayerLevelID=4` (internal/test accounts) are excluded from all counts
- Weekend adjustment: the SP calculates `NotWorkingDaysCount` (0, 1, or 2) and adds it to the window to account for non-trading days

**Diagram**:
```
Input TVP rows (one per rule):
  (FundingTypeId=1, StatusId=3, Limit=7, IsByDays=1, IsDeposit=0)
  -> count WTF records WHERE FundingType=1 AND CashoutStatus=3
     AND ModificationDate in last (7 + weekendDays) days
  -> returns: (IsDeposit=0, FundingTypeId=1, StatusId=3, RowsNumber=42)

  (FundingTypeId=1, StatusId=2, Limit=24, IsByDays=0, IsDeposit=1)
  -> count Deposit records WHERE FundingType=1 AND PaymentStatus=2
     AND ModificationDate in last 24 hours
  -> returns: (IsDeposit=1, FundingTypeId=1, StatusId=2, RowsNumber=15)
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeId | int | NO | - | CODE-BACKED | Payment method being checked. Joined to `Billing.Funding.FundingTypeID` by the SP. See [Funding Type](_glossary.md#funding-type) for values (e.g., 1=CreditCard, 2=WireTransfer, 3=PayPal). |
| 2 | StatusId | int | NO | - | CODE-BACKED | Transaction status to count against. For withdrawals (IsDeposit=0): maps to `CashoutStatusID` in `Billing.WithdrawToFunding`. For deposits (IsDeposit=1): maps to `PaymentStatusID` in `Billing.Deposit`. See [Cashout Status](_glossary.md#cashout-status) and [Payment Status](_glossary.md#payment-status). |
| 3 | Limit | int | NO | - | CODE-BACKED | Time window size. Meaning depends on `IsByDays`: if 1, this is a number of calendar days; if 0, this is a number of hours. Also used in the weekend adjustment calculation (`IIF(L.Limit - @endPeriodWeekDay >= 0, 2, 0)`). |
| 4 | IsByDays | bit | NO | - | CODE-BACKED | Time unit for the `Limit` field. 1 = window is in calendar days (weekend non-working days are added to extend the window); 0 = window is in hours (no weekend adjustment). |
| 5 | IsDeposit | bit | NO | - | CODE-BACKED | Determines which transaction table to query. 1 = count `Billing.Deposit` records (deposit direction); 0 = count `Billing.WithdrawToFunding` records (withdrawal direction). Controls which UNION branch is executed in `CountTransactionsWithTimeLimitForStatus`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeId | Billing.Funding | Implicit | Joined to FundingTypeID to find relevant funding records |
| StatusId (IsDeposit=0) | Dictionary.CashoutStatus | Lookup | Status code for withdrawal transactions |
| StatusId (IsDeposit=1) | Dictionary.PaymentStatus | Lookup | Status code for deposit transactions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CountTransactionsWithTimeLimitForStatus | @FundingTypeStatusLimits | TVP Parameter | Sole consumer - joins this TVP against Billing.Funding, Billing.Deposit, and Billing.WithdrawToFunding to count matching transactions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CountTransactionsWithTimeLimitForStatus | Stored Procedure | Receives as READONLY TVP; defines which funding-type/status combinations to count within time windows |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Inspect type column definitions

```sql
SELECT c.name, t.name AS type_name, c.max_length, c.is_nullable
FROM sys.table_types tt WITH (NOLOCK)
JOIN sys.columns c WITH (NOLOCK) ON c.object_id = tt.type_table_object_id
JOIN sys.types t WITH (NOLOCK) ON t.user_type_id = c.user_type_id
WHERE tt.schema_id = SCHEMA_ID('Billing')
  AND tt.name = 'FundingTypeStatusLimitList'
ORDER BY c.column_id
```

### 8.2 Simulate a limit check - withdrawals processed in last 7 days for credit card

```sql
-- This shows how the SP uses the TVP to count WTF records
SELECT
    F.FundingTypeID,
    WF.CashoutStatusID,
    COUNT(WF.ID) AS RowsNumber
FROM Billing.Funding F WITH (NOLOCK)
JOIN Billing.WithdrawToFunding WF WITH (NOLOCK)
    ON F.FundingID = WF.FundingID
    AND WF.CashoutStatusID = 3  -- Processed
    AND WF.ModificationDate > DATEADD(DAY, -7, GETUTCDATE())
JOIN Billing.Withdraw W WITH (NOLOCK) ON W.WithdrawID = WF.WithdrawID
JOIN Customer.CustomerStatic CS WITH (NOLOCK) ON CS.CID = W.CID
WHERE F.FundingTypeID = 1  -- CreditCard
  AND CS.PlayerLevelID != 4  -- Exclude test accounts
GROUP BY F.FundingTypeID, WF.CashoutStatusID
```

### 8.3 Simulate a limit check - deposits approved in last 24 hours for credit card

```sql
SELECT
    F.FundingTypeID,
    D.PaymentStatusID,
    COUNT(D.DepositID) AS RowsNumber
FROM Billing.Funding F WITH (NOLOCK)
JOIN Billing.Deposit D WITH (NOLOCK)
    ON F.FundingID = D.FundingID
    AND D.PaymentStatusID = 2  -- Approved
    AND D.ModificationDate > DATEADD(HOUR, -24, GETUTCDATE())
JOIN Customer.CustomerStatic CS WITH (NOLOCK) ON CS.CID = D.CID
WHERE F.FundingTypeID = 1
  AND CS.PlayerLevelID != 4
GROUP BY F.FundingTypeID, D.PaymentStatusID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingTypeStatusLimitList | Type: User Defined Type | Source: etoro/etoro/Billing/User Defined Types/Billing.FundingTypeStatusLimitList.sql*
