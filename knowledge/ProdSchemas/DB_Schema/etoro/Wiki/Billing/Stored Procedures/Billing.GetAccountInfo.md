# Billing.GetAccountInfo

> Returns a customer's financial summary: balance, bonus, realized equity, unrealized P&L, used margin, and non-withdrawable funds locked by ACH/digital wallet chargeback policy.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INTEGER - single-row result per customer |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetAccountInfo` is the customer account financial summary endpoint. It assembles six financial metrics needed by the application to present or validate a customer's account status:

1. **Balance** (`Credit` from `Customer.CustomerMoney`) - the customer's available cash balance in USD
2. **BonusCredit** - bonus funds (may have withdrawal restrictions)
3. **RealizedEquity** - realized profits/losses from closed positions
4. **UsedMargin** - the margin currently reserved for open leveraged positions (via `BackOffice.GetUsedMargin`)
5. **UnrealizedPnL** - the floating P&L from open positions (via `BackOffice.GetUnrealizedPnLNoFunctions`)
6. **NonWithdrawableFunds** - the amount of deposited funds that cannot yet be withdrawn due to chargeback lock-up periods

The `NonWithdrawableFunds` calculation is the most complex element. It sums approved deposits (`PaymentStatusID=2`) made via depots configured in `Billing.DepotConfig`, where the deposit was recent enough to still be within the lock window (`PaymentDate >= DATEADD(day, DeltaInDays, GETUTCDATE())`). Each depot has a different lock duration (2-7 days, per `Billing.DepotConfig`). The amount is converted to USD using `Amount * ExchangeRate`. This prevents customers from depositing via a high-chargeback method (ACH, crypto, digital wallet) and immediately withdrawing.

History:
- MIMOPS-2600 (Oct 2020, Irit R.): Added `Billing.DepotConfig` JOIN to compute non-withdrawable funds dynamically per depot's configured lock window. Previously used a simpler fixed calculation.
- MIMOPS-2600 (Nov 2020, Irit R.): Added CAST for `NonWithdrawableFunds` precision and recalculated `ACHNonWithdrawableFunds` formula.

---

## 2. Business Logic

### 2.1 Balance Fields from Customer.CustomerMoney

**What**: Retrieves authoritative balance data for the customer.

**Columns/Parameters Involved**: `CUST.Credit`, `CUST.BonusCredit`, `CUST.RealizedEquity`, `@CID`

**Rules**:
- `Customer.CustomerMoney` is the authoritative balance source (superseded `Billing.Account`).
- `Credit AS Balance`: the customer's cash balance in USD dollars.
- `BonusCredit`: bonus funds - may have withdrawal restrictions set elsewhere.
- `RealizedEquity`: sum of all realized trade gains/losses for this customer.
- Filter: `WHERE CUST.CID = @CID` - single customer lookup. Returns at most one row.
- `WITH (NOLOCK)` on CustomerMoney - dirty-read for performance; balance checks accept minor inconsistency.

### 2.2 Non-Withdrawable Funds Calculation

**What**: Computes the amount of approved deposits that are locked within their depot's chargeback window.

**Columns/Parameters Involved**: `Billing.Deposit.Amount`, `Billing.Deposit.ExchangeRate`, `Billing.Deposit.PaymentDate`, `Billing.Deposit.PaymentStatusID`, `Billing.DepotConfig.DeltaInDays`, `Billing.DepotConfig.IsNonWithdrawableFunds`

**Rules**:
- Only deposits where `PaymentStatusID = 2` (Approved) are included.
- Only depots where `dc.IsNonWithdrawableFunds = 1` are included (all 9 rows in DepotConfig qualify).
- Lock window: `PaymentDate >= CAST(DATEADD(DAY, dc.DeltaInDays, GETUTCDATE()) AS DATE)` - since DeltaInDays is negative (e.g., -6), this means "deposits made in the last 6 days".
- Amount is converted to USD: `Amount * ExchangeRate` - deposit amounts may be in the customer's native currency; ExchangeRate brings them to USD.
- Result is `CAST` to `DECIMAL(18,2)` and wrapped in `ISNULL(..., 0)` - if no locked deposits exist, returns 0.
- LEFT JOIN - if the subquery returns no rows, NonWithdrawableFunds = 0 (not NULL).

### 2.3 Used Margin and Unrealized P&L from BackOffice Functions

**What**: Delegates margin and unrealized P&L calculations to cross-schema BackOffice scalar functions.

**Columns/Parameters Involved**: `BackOffice.GetUsedMargin(@CID)`, `BackOffice.GetUnrealizedPnLNoFunctions(@CID)`

**Rules**:
- `BackOffice.GetUsedMargin(@CID)`: returns the total margin reserved for open leveraged positions. Denominated in CENTS (see `Billing.GetAccountInfoWithoutPendingOrders` for unit detail).
- `BackOffice.GetUnrealizedPnLNoFunctions(@CID)`: returns the unrealized P&L for all open positions. Wrapped in `ISNULL(..., 0)` to handle customers with no open positions.
- These are cross-schema function calls that query Trade-side data; they are read-only and add no DML.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Used in all four data retrieval paths: CustomerMoney lookup, Deposit subquery, GetUsedMargin, GetUnrealizedPnLNoFunctions. |

**Return columns**:

| # | Column | Type | Confidence | Description |
|---|--------|------|------------|-------------|
| R1 | NonWithdrawableFunds | DECIMAL(18,2) | CODE-BACKED | USD amount of approved deposits still within their depot's chargeback lock window (DeltaInDays). ISNULL defaults to 0. Computed from Billing.Deposit + Billing.DepotConfig. Added MIMOPS-2600. |
| R2 | RealizedEquity | (from CustomerMoney) | CODE-BACKED | Cumulative realized profit/loss from all closed positions. From Customer.CustomerMoney.RealizedEquity. |
| R3 | Balance | (from CustomerMoney.Credit) | CODE-BACKED | Customer's available cash balance in USD. Aliased from Credit in Customer.CustomerMoney. Denominated in Dollars. |
| R4 | BonusCredit | (from CustomerMoney) | CODE-BACKED | Bonus funds balance. From Customer.CustomerMoney.BonusCredit. May have withdrawal restrictions. |
| R5 | UsedMargin | (from BackOffice function) | CODE-BACKED | Margin reserved for open leveraged positions. From BackOffice.GetUsedMargin(@CID). Note: denominated in CENTS (see GetAccountInfoWithoutPendingOrders). |
| R6 | UnrealizedPnL | (from BackOffice function) | CODE-BACKED | Floating P&L on open positions. From BackOffice.GetUnrealizedPnLNoFunctions(@CID). ISNULL defaults to 0 for customers with no open positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | Reader | Main balance source: Balance, BonusCredit, RealizedEquity |
| @CID | Billing.Deposit | Reader (subquery) | Filters approved deposits within chargeback lock windows |
| DepotConfig | Billing.DepotConfig | Reader (subquery JOIN) | Provides DeltaInDays lock window and IsNonWithdrawableFunds flag per depot |
| @CID | BackOffice.GetUsedMargin | Function call | Returns used margin for open positions |
| @CID | BackOffice.GetUnrealizedPnLNoFunctions | Function call | Returns unrealized P&L for open positions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application cashout flow | External | Caller | Called to validate account financial state before processing a cashout |
| Back-office account summary | External | Caller | Called to display a customer's financial position |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetAccountInfo (procedure)
├── Customer.CustomerMoney (table) [cross-schema]
├── Billing.Deposit (table)
├── Billing.DepotConfig (table)
├── BackOffice.GetUsedMargin (function) [cross-schema]
└── BackOffice.GetUnrealizedPnLNoFunctions (function) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table (cross-schema) | Main SELECT source: Balance (Credit), BonusCredit, RealizedEquity |
| Billing.Deposit | Table | Subquery: SUM(Amount*ExchangeRate) for non-withdrawable funds |
| Billing.DepotConfig | Table | JOIN in subquery: provides DeltaInDays and IsNonWithdrawableFunds per depot |
| BackOffice.GetUsedMargin | Scalar Function (cross-schema) | Returns used margin for @CID |
| BackOffice.GetUnrealizedPnLNoFunctions | Scalar Function (cross-schema) | Returns unrealized P&L for @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetAccountInfoWithoutPendingOrders | Stored Procedure | Extends this logic with pending order deductions |
| Application cashout/account services | External | Calls for financial state validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Uses SET NOCOUNT ON. No TRY/CATCH. No transaction. LEFT JOIN for NonWithdrawableFunds (safe - 0 if no locked deposits). Unit note: Balance (R3) is in Dollars; UsedMargin (R5) is in Cents (mismatch - callers must convert; see GetAccountInfoWithoutPendingOrders for context).

---

## 8. Sample Queries

### 8.1 Get account info for a customer

```sql
EXEC [Billing].[GetAccountInfo]
    @CID = 12345;
-- Returns: NonWithdrawableFunds, RealizedEquity, Balance, BonusCredit, UsedMargin, UnrealizedPnL
```

### 8.2 Check non-withdrawable funds directly

```sql
SELECT
    d.CID,
    SUM(d.Amount * d.ExchangeRate) AS NonWithdrawableFunds,
    dc.DeltaInDays,
    DATEADD(DAY, dc.DeltaInDays, GETUTCDATE()) AS LockWindowStart
FROM [Billing].[Deposit] d WITH (NOLOCK)
INNER JOIN [Billing].[DepotConfig] dc ON d.DepotID = dc.DepotID
WHERE d.CID = 12345
  AND d.PaymentStatusID = 2           -- Approved
  AND dc.IsNonWithdrawableFunds = 1
  AND d.PaymentDate >= CAST(DATEADD(DAY, dc.DeltaInDays, GETUTCDATE()) AS DATE)
GROUP BY d.CID, dc.DeltaInDays;
```

### 8.3 Check current balance source

```sql
SELECT CID, Credit AS Balance, BonusCredit, RealizedEquity
FROM [Customer].[CustomerMoney] WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPS-2600 (Oct-Nov 2020) | Jira (code comment) | Added DepotConfig JOIN for per-depot non-withdrawable funds lock window; CAST NonWithdrawableFunds to DECIMAL(18,2) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 1 Jira (code comment) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetAccountInfo | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetAccountInfo.sql*
