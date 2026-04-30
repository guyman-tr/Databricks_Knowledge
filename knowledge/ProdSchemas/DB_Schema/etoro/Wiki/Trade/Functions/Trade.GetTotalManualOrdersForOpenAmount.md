# Trade.GetTotalManualOrdersForOpenAmount

> Scalar function that returns the total reserved amount from manual (non-copy) open orders for a customer. Used for balance and withdrawal calculations. Natively compiled for performance.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Return value (MONEY) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetTotalManualOrdersForOpenAmount computes the sum of (FrozenAmount or Amount minus FilledAmount) for a customer's open manual orders—orders that are not yet filled (FilledAmount=0), are not copy-trade orders (MirrorID=0), are non-terminal (still active), and are computed for balance (IsComputedForBalance=1 or NULL). This represents the amount of cash "reserved" by pending open orders that should be deducted from available balance when evaluating withdrawal eligibility or copy allocation.

This function exists because Trade.OrderForOpen holds active entry orders that reserve margin. When a customer has pending buy orders, that amount is not available for withdrawal. GetMaxAmountToWithdraw, GetOrderForOpenContextData, and GetUserInfo all need this value to correctly compute available balance = TotalCash - reserved order amount. Without it, the system would overstate available funds.

Data flows: Callers pass @CID. The function aggregates from Trade.OrderForOpen joined to Dictionary.OrderForExecutionStatus (filtering IsTerminal=0), where FilledAmount=0 (position not yet created), MirrorID=0 (manual only), and IsComputedForBalance in (1, NULL). Uses ISNULL(FrozenAmount, Amount) - FilledAmount per order. Returns 0 if no matching orders. NATIVE_COMPILATION and SCHEMABINDING optimize for frequent calls.

---

## 2. Business Logic

### 2.1 Manual vs Copy-Trade Filter

**What**: Only manual orders (MirrorID=0) are included. Copy-trade orders are excluded.

**Columns/Parameters Involved**: `MirrorID`, `FilledAmount`, `IsTerminal`

**Rules**:
- MirrorID=0: Manual orders only. Copy-trade orders (MirrorID>0) have different allocation logic.
- FilledAmount=0: Order has not yet resulted in a position. Code comment: "FilledAmount=0 indicates whether the parent's position was handled or not."
- IsTerminal=0: Order status is not terminal (still active, e.g., pending execution).

### 2.2 Amount Calculation

**What**: Per order, reserved amount = FrozenAmount if set, else Amount, minus FilledAmount. Only orders with IsComputedForBalance=1 or NULL are included.

**Columns/Parameters Involved**: `FrozenAmount`, `Amount`, `FilledAmount`, `IsComputedForBalance`

**Rules**:
- FrozenAmount: If set, use it (frozen/reserved amount for the order). Else use Amount.
- FilledAmount: Subtracted to get unfilled portion. When FilledAmount=0, full (FrozenAmount|Amount) is reserved.
- IsComputedForBalance: 1 or NULL = include in balance calc. 0 = exclude (e.g., system/test orders).

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID. References Customer.Customer. The customer whose manual open order amount is summed. |
| 2 | (return) | money | NO | - | CODE-BACKED | Sum of (ISNULL(FrozenAmount, Amount) - FilledAmount) for manual, non-terminal, unfilled orders with IsComputedForBalance in (1, NULL). Returns 0 when no matching orders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Implicit | Filter OrderForOpen by CID. |
| StatusID | Dictionary.OrderForExecutionStatus | JOIN | Filter IsTerminal=0. |
| (OrderForOpen columns) | Trade.OrderForOpen | FROM | Source of order amounts. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetOrderForOpenContextData | @TotalOrdersAmount | Reader | Balance context for open orders. |
| Trade.GetMaxAmountToWithdraw | @TotalOrdersAmount | Reader | Withdrawal eligibility—reserved amount deduction. |
| Trade.GetUserInfo | @TotalOrdersAmount | Reader | User info balance display. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetTotalManualOrdersForOpenAmount (function)
├── Trade.OrderForOpen (table)
└── Dictionary.OrderForExecutionStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table | FROM — manual open orders, amount columns |
| Dictionary.OrderForExecutionStatus | Table | JOIN — filter IsTerminal=0 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOrderForOpenContextData | Procedure | Calls function |
| Trade.GetMaxAmountToWithdraw | Procedure | Calls function |
| Trade.GetUserInfo | Procedure | Calls function |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None. Function uses WITH NATIVE_COMPILATION, SCHEMABINDING, and ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'English').

---

## 8. Sample Queries

### 8.1 Get reserved amount for a customer
```sql
SELECT Trade.GetTotalManualOrdersForOpenAmount(14952810) AS ReservedAmount;
```

### 8.2 Available for withdrawal (TotalCash minus reserved)
```sql
DECLARE @CID INT = 14952810;
SELECT Trade.GetTotalCash(@CID) AS TotalCash,
       Trade.GetTotalManualOrdersForOpenAmount(@CID) AS ReservedByOrders,
       Trade.GetTotalCash(@CID) - Trade.GetTotalManualOrdersForOpenAmount(@CID) AS AvailableForWithdrawal;
```

### 8.3 Compare reserved amounts across customers
```sql
SELECT C.CID, C.UserName,
       Trade.GetTotalManualOrdersForOpenAmount(C.CID) AS ReservedAmount,
       Trade.GetTotalCash(C.CID) AS TotalCash
FROM   Customer.Customer C WITH (NOLOCK)
WHERE  C.CID IN (14952810, 24713264)
       AND Trade.GetTotalManualOrdersForOpenAmount(C.CID) > 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 7.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetTotalManualOrdersForOpenAmount | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.GetTotalManualOrdersForOpenAmount.sql*
