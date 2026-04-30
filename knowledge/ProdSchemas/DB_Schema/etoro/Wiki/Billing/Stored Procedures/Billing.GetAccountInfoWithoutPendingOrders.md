# Billing.GetAccountInfoWithoutPendingOrders

> Extended variant of GetAccountInfo that deducts pending order amounts from Balance and adds them to UsedMargin, providing an accurate available-to-withdraw figure when open order requests exist.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INTEGER - single-row result per customer |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetAccountInfoWithoutPendingOrders` is the cashout-safe variant of `Billing.GetAccountInfo`. It adds deduction of pending order amounts so that the `Balance` returned reflects the customer's TRUE available-to-withdraw balance - i.e., cash balance minus amounts already committed to pending buy orders that have not yet been matched.

The name "WithoutPendingOrders" means: balance computed as if the pending orders have already consumed the reserved cash (the balance WITH the orders reserved OUT). This prevents a race condition in cashout processing where a customer submits a cashout request while simultaneously having pending orders that would consume their balance.

Two pending order sources are combined:
1. **`Trade.OrderForOpen` (WITH SNAPSHOT)**: Manual (non-mirror) buy orders awaiting execution. Amounts in DOLLARS. MirrorID=0 filter excludes copy-trade orders.
2. **`Trade.Orders`**: Market/limit orders awaiting execution. Amounts in CENTS.

The dual-table design and unit differences (dollars vs cents) reflect different order pipeline architectures in the Trade schema. Both must be summed and unit-converted to compute the correct balance and margin adjustments.

All other components (NonWithdrawableFunds, RealizedEquity, BonusCredit, BackOffice functions) are identical to `Billing.GetAccountInfo`.

---

## 2. Business Logic

### 2.1 Base Financial Data (identical to GetAccountInfo)

See `Billing.GetAccountInfo` Section 2.1 and 2.2 for:
- `Customer.CustomerMoney` balance fields
- `NonWithdrawableFunds` subquery via `Billing.Deposit` + `Billing.DepotConfig`
- `BackOffice.GetUsedMargin` and `BackOffice.GetUnrealizedPnLNoFunctions`

### 2.2 Pending Order Deductions

**What**: Subtracts pending order amounts from the customer's available balance and adds them to used margin.

**Columns/Parameters Involved**: `Trade.OrderForOpen.Amount` (dollars), `Trade.Orders.Amount` (cents), `Customer.CustomerMoney.Credit`

**Rules**:
- Subquery O (`Trade.OrderForOpen WITH (SNAPSHOT)`): Sums pending open-order amounts in DOLLARS for non-mirror orders (`MirrorID=0`). SNAPSHOT isolation reads a consistent state without blocking the high-frequency trading engine.
- Subquery RO (`Trade.Orders`): Sums pending market/limit order amounts in CENTS for the customer. No isolation hint (implicit read committed).
- `Balance` formula: `Credit - ISNULL(O.TotalOrderAmount, 0) - (ISNULL(RO.TotalOrderAmount, 0)/100)`
  - Subtracts dollar amounts from OrderForOpen directly.
  - Subtracts cent amounts from Orders after dividing by 100 to convert to dollars.
  - Result: Balance in DOLLARS.
- `UsedMargin` formula: `BackOffice.GetUsedMargin(@CID) + (ISNULL(O.TotalOrderAmount, 0)*100) + ISNULL(RO.TotalOrderAmount, 0)`
  - Adds dollar amounts from OrderForOpen multiplied by 100 to convert to cents.
  - Adds cent amounts from Orders directly (already in cents).
  - `BackOffice.GetUsedMargin(@CID)` returns in CENTS.
  - Result: UsedMargin in CENTS.

### 2.3 Unit Inconsistency (Known Design)

**What**: Balance and UsedMargin are denominated in different units.

**Rules**:
- `Balance`: denominated in DOLLARS (confirmed by inline comment `-- In Dollars`)
- `UsedMargin`: denominated in CENTS (confirmed by inline comment `-- In Cents`)
- `UnrealizedPnL`: denominated in CENTS (confirmed by inline comment)
- Callers MUST apply unit conversion before comparing or combining Balance and UsedMargin/UnrealizedPnL.
- This is a pre-existing design from the Trade schema where `OrderForOpen.Amount` is in dollars but `Orders.Amount` is in cents, requiring dual conversion paths.

### 2.4 Isolation Strategy

**What**: Different isolation levels for different order tables.

**Rules**:
- `Trade.OrderForOpen WITH (SNAPSHOT)`: Uses snapshot isolation to get a consistent point-in-time read of in-flight orders without blocking the trading engine's INSERT/UPDATE activity on this hot table.
- `Trade.Orders` (no hint): Read committed. This table has lower write frequency, so snapshot is not needed.
- `Customer.CustomerMoney WITH (NOLOCK)`, `Billing.Deposit WITH (NOLOCK)`, `Billing.DepotConfig WITH (NOLOCK)`: dirty-read acceptable for balance checks.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Used across all five data sources: CustomerMoney, Deposit subquery, OrderForOpen subquery, Orders subquery, BackOffice functions. |

**Return columns**:

| # | Column | Type | Unit | Confidence | Description |
|---|--------|------|------|------------|-------------|
| R1 | NonWithdrawableFunds | DECIMAL(18,2) | Dollars | CODE-BACKED | Same as GetAccountInfo.NonWithdrawableFunds - approved deposits within chargeback lock window. See GetAccountInfo Section 2.2. |
| R2 | RealizedEquity | (CustomerMoney) | Dollars | CODE-BACKED | Cumulative realized P&L from closed positions. From Customer.CustomerMoney. |
| R3 | Balance | DECIMAL | Dollars | CODE-BACKED | Available-to-withdraw balance. Formula: Credit - OrderForOpen.TotalOrderAmount - (Orders.TotalOrderAmount/100). Reflects cash minus amounts committed to pending orders. |
| R4 | BonusCredit | (CustomerMoney) | Dollars | CODE-BACKED | Bonus funds balance. From Customer.CustomerMoney.BonusCredit. |
| R5 | UsedMargin | (BackOffice + orders) | CENTS | CODE-BACKED | Total reserved margin including pending orders. Formula: BackOffice.GetUsedMargin + (OrderForOpen.TotalOrderAmount*100) + Orders.TotalOrderAmount. NOTE: denominated in CENTS, unlike Balance (dollars). |
| R6 | UnrealizedPnL | (BackOffice function) | CENTS | CODE-BACKED | Floating P&L on open positions. From BackOffice.GetUnrealizedPnLNoFunctions(@CID). Denominated in CENTS. ISNULL defaults to 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | Reader | Main balance source: Credit, BonusCredit, RealizedEquity |
| @CID | Billing.Deposit | Reader (subquery) | Approved deposits within chargeback lock window |
| DepotConfig | Billing.DepotConfig | Reader (subquery JOIN) | Lock window config per depot |
| @CID | Trade.OrderForOpen | Reader (SNAPSHOT) | Pending manual open orders in dollars |
| @CID | Trade.Orders | Reader | Pending market/limit orders in cents |
| @CID | BackOffice.GetUsedMargin | Function call | Base used margin for open positions |
| @CID | BackOffice.GetUnrealizedPnLNoFunctions | Function call | Unrealized P&L for open positions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Cashout validation service | External | Caller | Uses the pending-order-adjusted Balance to validate if cashout amount <= available balance |
| Account balance summary | External | Caller | Displays effective balance accounting for pending orders |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetAccountInfoWithoutPendingOrders (procedure)
├── Customer.CustomerMoney (table) [cross-schema]
├── Billing.Deposit (table)
├── Billing.DepotConfig (table)
├── Trade.OrderForOpen (table, SNAPSHOT) [cross-schema]
├── Trade.Orders (table) [cross-schema]
├── BackOffice.GetUsedMargin (function) [cross-schema]
└── BackOffice.GetUnrealizedPnLNoFunctions (function) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table (cross-schema) | Main SELECT: Credit, BonusCredit, RealizedEquity |
| Billing.Deposit | Table | Subquery: SUM(Amount*ExchangeRate) for non-withdrawable funds |
| Billing.DepotConfig | Table | JOIN: DeltaInDays lock window per depot |
| Trade.OrderForOpen | Table (cross-schema, SNAPSHOT) | Subquery: SUM(Amount) in dollars for pending manual orders |
| Trade.Orders | Table (cross-schema) | Subquery: SUM(Amount) in cents for pending market/limit orders |
| BackOffice.GetUsedMargin | Scalar Function (cross-schema) | Base margin in cents |
| BackOffice.GetUnrealizedPnLNoFunctions | Scalar Function (cross-schema) | Unrealized P&L in cents |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Cashout validation service | External | Calls to verify customer has sufficient available balance for cashout request |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. SET NOCOUNT ON. No TRY/CATCH. No transaction. Three LEFT JOINs ensure all results are 0 if subqueries return no rows. Critical unit inconsistency: Balance in Dollars, UsedMargin in Cents, UnrealizedPnL in Cents. SNAPSHOT on Trade.OrderForOpen prevents blocking high-frequency trading writes.

---

## 8. Sample Queries

### 8.1 Get cashout-safe account info

```sql
EXEC [Billing].[GetAccountInfoWithoutPendingOrders]
    @CID = 12345;
-- Returns adjusted Balance (dollars), UsedMargin (cents), UnrealizedPnL (cents)
-- Caller must divide UsedMargin/UnrealizedPnL by 100 to compare with Balance
```

### 8.2 Check pending orders for a customer

```sql
-- OrderForOpen (dollars)
SELECT SUM(Amount) AS PendingAmountDollars
FROM [Trade].[OrderForOpen] WITH (SNAPSHOT)
WHERE CID = 12345 AND MirrorID = 0;

-- Orders (cents)
SELECT SUM(Amount) AS PendingAmountCents
FROM [Trade].[Orders]
WHERE CID = 12345;
```

### 8.3 Reproduce the Balance calculation

```sql
DECLARE @credit DECIMAL(18,2), @ofo DECIMAL(18,2), @ord DECIMAL(18,2);
SELECT @credit = Credit FROM [Customer].[CustomerMoney] WITH (NOLOCK) WHERE CID = 12345;
SELECT @ofo = ISNULL(SUM(Amount),0) FROM [Trade].[OrderForOpen] WITH (SNAPSHOT) WHERE CID = 12345 AND MirrorID = 0;
SELECT @ord = ISNULL(SUM(Amount),0) FROM [Trade].[Orders] WHERE CID = 12345;
SELECT @credit - @ofo - (@ord/100) AS EffectiveBalanceDollars;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (GetAccountInfo) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetAccountInfoWithoutPendingOrders | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetAccountInfoWithoutPendingOrders.sql*
