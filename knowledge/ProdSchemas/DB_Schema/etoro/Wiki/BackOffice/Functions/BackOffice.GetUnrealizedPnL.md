# BackOffice.GetUnrealizedPnL

> Scalar function returning the total unrealized profit and loss (in cents) for all open positions of a customer, read from the pre-computed PnL view with current market rates.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns BIGINT - total PnL in cents |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetUnrealizedPnL` returns the total unrealized profit and loss for all open trading positions of a customer, expressed in cents (integer). Unrealized PnL is the hypothetical gain or loss if the customer were to close all positions at current market prices - a positive value means the customer's portfolio is in profit, a negative value means it is in loss.

This function is a critical component of the customer equity calculation in `BackOffice.GetCustomerByCID`, the main procedure that loads a customer's financial summary in BackOffice. It is used alongside `BackOffice.GetUsedMarginBigInt` to compute the customer's total equity:

`Equity = Credit + GetUnrealizedPnL(CID) + GetUsedMarginBigInt(CID) + PendingCashoutAdjustments`

The function reads from `Trade.PositionForExternalUseWithPnL`, a view that pre-computes PnL using current market rates. This view encapsulates the complex PnL calculation logic (including conversion rates, leverage, and position direction).

**Change history**:
- Ran Ovadia (19/07/2020): Removed dependency on other functions - simplified to direct view read
- Yitzchak Wahnon (23/07/2023): Added NOLOCK to fix interference with instrument addition operations
- KateM (19/12/2023): PnL calculation change (updated view dependency or calculation method)

The companion function `BackOffice.GetUnrealizedPnLNoFunctions` was created in 2024 (MIMOPSA-13954) as a performance-optimized alternative reading from `Trade.PnL` table instead of the view.

---

## 2. Business Logic

### 2.1 PnL Summation from Pre-Computed View

**What**: Sums PnLInCents across all open positions for the customer from the pre-computed PnL view.

**Columns/Parameters Involved**: `@CID`, `@RetVal`

**Rules**:
- `SELECT @RetVal = SUM(PnLInCents) FROM Trade.PositionForExternalUseWithPnL WHERE CID = @CID`
- No NOLOCK hint in the FROM clause (added per Yitzchak's 2023 fix - though the comment says "added nolock" the DDL shows no explicit hint on this view query; the view itself may handle NOLOCK internally).
- `RETURN(ISNULL(@RetVal, 0))` - returns 0 if no positions exist (SUM of empty set = NULL -> ISNULL -> 0).
- PnLInCents is in integer cents (BIGINT). Callers divide by 100.0 for display: `CAST((BackOffice.GetUnrealizedPnL(@CID)/100.0) AS DECIMAL(16,2)) AS UnrealizedPnL`.
- The view `Trade.PositionForExternalUseWithPnL` filters to open positions and includes real-time PnL per position.

### 2.2 Role in Customer Equity Calculation

**What**: One of three components in the BackOffice customer equity formula.

**Columns/Parameters Involved**: `@CID` (return used in GetCustomerByCID equity expression)

**Rules**:
- Equity formula in BackOffice.GetCustomerByCID: `CAST(((Credit*100 + GetUnrealizedPnL(CID) + GetUsedMarginBigInt(CID)) / 100.0 + PendingCashoutAdjustments) AS DECIMAL(16,2))`
- All three components (Credit, UnrealizedPnL, UsedMargin) are in cents and summed before dividing by 100
- Also returned as a standalone column: `CAST((GetUnrealizedPnL(@CID)/100.0) AS DECIMAL(16,2)) AS UnrealizedPnL`
- Negative PnL (losing positions) reduces equity; positive PnL increases it

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the customer whose total unrealized PnL to calculate. Filters Trade.PositionForExternalUseWithPnL by CID to sum only that customer's open positions. |

### Return Value

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (return value) | BIGINT | NO | 0 | CODE-BACKED | Total unrealized PnL in cents (integer) for all open positions of the customer. Positive = customer is in profit, negative = customer is in loss. Returns 0 if the customer has no open positions. Callers divide by 100.0 to convert to dollars for display. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.PositionForExternalUseWithPnL | View read | SUM(PnLInCents) WHERE CID = @CID. This view pre-computes per-position PnL using current market rates and exposes it to external consumers like BackOffice. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetCustomerByCID | Equity (computed), UnrealizedPnL | Function call | Called twice per customer: once in the equity computation expression, once as a standalone UnrealizedPnL column output. Central caller for this function. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetUnrealizedPnL (function)
└── Trade.PositionForExternalUseWithPnL (view) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionForExternalUseWithPnL | View | SUM(PnLInCents) WHERE CID = @CID. Encapsulates real-time PnL computation with market rates. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCustomerByCID | Stored Procedure | READER - calls function twice per customer: in equity formula and as standalone UnrealizedPnL output column. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Get unrealized PnL for a specific customer in dollars

```sql
SELECT CAST(BackOffice.GetUnrealizedPnL(12345) / 100.0 AS DECIMAL(16,2)) AS UnrealizedPnLUSD;
```

### 8.2 Compare PnL from both function variants

```sql
SELECT
    BackOffice.GetUnrealizedPnL(12345) AS PnLFromView,
    BackOffice.GetUnrealizedPnLNoFunctions(12345) AS PnLFromTable;
-- Results should be identical; GetUnrealizedPnLNoFunctions is the newer performance-optimized version
```

### 8.3 Get unrealized PnL directly from the source view (avoids scalar function overhead)

```sql
SELECT SUM(PnLInCents) / 100.0 AS UnrealizedPnLUSD
FROM Trade.PositionForExternalUseWithPnL WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetUnrealizedPnL | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetUnrealizedPnL.sql*
