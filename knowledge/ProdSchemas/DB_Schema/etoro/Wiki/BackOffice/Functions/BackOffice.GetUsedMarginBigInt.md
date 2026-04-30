# BackOffice.GetUsedMarginBigInt

> Scalar function returning the total used margin in cents (BIGINT) for a customer, created to fix integer overflow in GetUsedMargin for high-value accounts. The production-standard used margin function called by GetCustomerByCID.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns BIGINT - total used margin in cents |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetUsedMarginBigInt` is the production-standard function for calculating a customer's total used margin. It returns the same value as `BackOffice.GetUsedMargin` but uses BIGINT instead of INTEGER to prevent overflow errors that occurred for Cyprus entity customers with very large account balances.

Created by Adi on 29/03/2020 after a critical incident: Cyprus customers were unable to process card payments because `GetUsedMargin` returned incorrect (overflowed) values for accounts with positions totaling more than ~$21M (MAX_INT / 100). The BIGINT version was deployed as the fix, and `BackOffice.GetCustomerByCID` was immediately migrated to use this version.

Key difference from `GetUsedMargin`: This function reads from `Trade.Position` (the view, not `Trade.PositionTbl` directly) and does NOT filter by StatusID. This means it includes positions of ALL statuses, not just open ones. This is a behavioral difference introduced as part of the overflow fix - the 2024 StatusID=1 fix was applied to `GetUsedMargin` but not retroactively to this function. Callers should be aware that this function may include closed positions in its sum.

---

## 2. Business Logic

### 2.1 BIGINT Used Margin Components

**What**: Used margin = all-status position amounts + mirror/copy-trade cash allocations, all in cents as BIGINT.

**Columns/Parameters Involved**: `@CID`, `@AmountInOpenPositions`, `@TotalMirrorCash`, `@UsedMargin`

**Rules**:
- Component 1 (Positions): `CAST(SUM(Amount) * 100 AS BIGINT)` from `Trade.Position` WHERE CID=@CID. **No StatusID filter** - includes all positions regardless of status. Trade.Position is the view over Trade.PositionTbl.
- Component 2 (Mirror Cash): `CAST(SUM(Amount) * 100 AS BIGINT)` from `Trade.Mirror` WHERE CID=@CID.
- Component 3 (Pending Stock Orders): **COMMENTED OUT** - same commented-out Stocks.GetOrders logic as GetUsedMargin.
- Final: `ISNULL(@AmountInOpenPositions, 0) + ISNULL(@TotalMirrorCash, 0)` (BIGINT arithmetic)
- BIGINT supports values up to ~$92 quadrillion in cents - effectively no overflow risk.

**Diagram**:
```
@CID
  |
  +-- Trade.Position WHERE CID=@CID (ALL statuses - no filter)
  |   SUM(Amount)*100 -> @AmountInOpenPositions (BIGINT, cents)
  |
  +-- Trade.Mirror WHERE CID=@CID
  |   SUM(Amount)*100 -> @TotalMirrorCash (BIGINT, cents)
  |
  v
ISNULL(@AmountInOpenPositions,0) + ISNULL(@TotalMirrorCash,0)
= @UsedMargin (BIGINT, cents)
```

### 2.2 Role in Customer Equity Calculation

**What**: Combined with GetUnrealizedPnL to compute total customer equity in GetCustomerByCID.

**Columns/Parameters Involved**: @CID (return used in equity formula)

**Rules**:
- Equity formula: `CAST(((Credit*100 + GetUnrealizedPnL(CID) + GetUsedMarginBigInt(CID)) / 100.0 + PendingCashoutAdjustments) AS DECIMAL(16,2))`
- All three components in cents; divided by 100 for dollar display
- Also output as standalone `UsedMargin` column: `CAST((GetUsedMarginBigInt(@CID)/100.0) AS DECIMAL(16,2)) AS UsedMargin`

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID of the customer whose total used margin to calculate. Filters both Trade.Position and Trade.Mirror by CID. |

### Return Value

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UsedMargin | BIGINT | NO | 0 | CODE-BACKED | Total used margin in cents (BIGINT). Sum of: (1) ALL positions (any status) from Trade.Position * 100, plus (2) all mirror/copy-trade cash allocations from Trade.Mirror * 100. Returns 0 if the customer has no positions or mirror allocations. BIGINT prevents overflow for large accounts. Note: unlike GetUsedMargin (StatusID=1 only), this version includes ALL position statuses. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.Position | View read | SUM(Amount) WHERE CID=@CID (all statuses). Trade.Position is the public view over Trade.PositionTbl. Amount in dollars; *100 for cents. |
| @CID | Trade.Mirror | Table read | SUM(Amount) WHERE CID=@CID. Copy-trading cash allocations. Amount in dollars; *100 for cents. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetCustomerByCID | Equity, UsedMargin | Function call | Primary caller. Used twice: in equity computation expression (with GetUnrealizedPnL) and as standalone UsedMargin output column. Migration from GetUsedMargin happened 29/03/2020. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetUsedMarginBigInt (function)
├── Trade.Position (view) [cross-schema]
└── Trade.Mirror (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SUM(Amount)*100 WHERE CID=@CID, all statuses. View layer over Trade.PositionTbl. |
| Trade.Mirror | Table | SUM(Amount)*100 WHERE CID=@CID. Mirror/copy-trading cash. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCustomerByCID | Stored Procedure | READER - calls function twice per customer: in equity formula and as standalone UsedMargin output. This is the primary consumer and was the driver for the BigInt migration. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function. BIGINT return type prevents the overflow issue that affected the INTEGER version (GetUsedMargin) for Cyprus entity customers with large account balances.

---

## 8. Sample Queries

### 8.1 Get used margin in dollars for a customer

```sql
SELECT
    BackOffice.GetUsedMarginBigInt(12345) AS UsedMarginCents,
    CAST(BackOffice.GetUsedMarginBigInt(12345) / 100.0 AS DECIMAL(16,2)) AS UsedMarginUSD;
```

### 8.2 Calculate customer equity using the same formula as GetCustomerByCID

```sql
DECLARE @CID INT = 12345;
SELECT
    CAST((
        CAST(Credit * 100 AS BIGINT) +
        BackOffice.GetUnrealizedPnL(@CID) +
        BackOffice.GetUsedMarginBigInt(@CID)
    ) / 100.0 AS DECIMAL(16,2)) AS CalculatedEquity
FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE CID = @CID;
```

### 8.3 Direct table query (avoids scalar function overhead)

```sql
SELECT
    ISNULL(CAST(SUM(p.Amount) * 100 AS BIGINT), 0) +
    ISNULL(CAST(SUM(m.Amount) * 100 AS BIGINT), 0) AS UsedMarginCents
FROM (SELECT Amount FROM Trade.Position WITH (NOLOCK) WHERE CID = 12345) p
CROSS JOIN (SELECT ISNULL(SUM(Amount), 0) AS Amount FROM Trade.Mirror WITH (NOLOCK) WHERE CID = 12345) m;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Created 29/03/2020 by Adi as emergency fix for INTEGER overflow in GetUsedMargin for Cyprus entity high-value accounts (documented in DDL comment).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetUsedMarginBigInt | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetUsedMarginBigInt.sql*
