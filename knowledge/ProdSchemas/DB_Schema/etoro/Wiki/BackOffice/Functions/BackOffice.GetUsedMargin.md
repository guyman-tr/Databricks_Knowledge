# BackOffice.GetUsedMargin

> Scalar function returning the total used margin in cents (INTEGER) for a customer, summing open trading position amounts and mirror/copy-trading cash from Trade tables.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INTEGER - total used margin in cents |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetUsedMargin` calculates the total amount of a customer's funds currently tied up in open trading positions and copy-trading (mirror) allocations, expressed in cents as an INTEGER. "Used margin" represents funds that are actively deployed in trades - money the customer cannot withdraw because it is collateralizing open positions.

This function is the original version of the used margin calculation. It was superseded by `BackOffice.GetUsedMarginBigInt` in March 2020 (Adi) to fix an INTEGER overflow issue for high-value accounts on the Cyprus entity. `GetCustomerByCID` comments show the migration: "Modified all references of BackOffice.GetUsedMargin UDF to BackOffice.GetUsedMarginBigInt". The function may still be called by legacy code or external consumers.

**Change history**:
- Adi (24/01/2019): Removed reference to Stocks.GetOrders (stock pending orders no longer included)
- Itay (26/08/2024): Added StatusID=1 filter (MIMOPSA-13899) - now only counts OPEN positions

The StatusID=1 filter addition in 2024 was a significant behavioral change: before this fix, the function counted all positions including closed ones. This was incorrect - closed positions should not contribute to used margin. The fix aligned the function with correct margin calculation semantics.

---

## 2. Business Logic

### 2.1 Used Margin Components

**What**: Used margin = open position amounts + mirror/copy-trade cash allocations, all in cents.

**Columns/Parameters Involved**: `@CID`, `@AmountInOpenPositions`, `@TotalMirrorCash`, `@UsedMargin`

**Rules**:
- Component 1 (Open Positions): `CAST(SUM(Amount) * 100 AS INTEGER)` from `Trade.PositionTbl` WHERE CID=@CID AND **StatusID=1** (open only). Amount is in dollars; multiplied by 100 for cents.
- Component 2 (Mirror Cash): `CAST(SUM(Amount) * 100 AS INTEGER)` from `Trade.Mirror` WHERE CID=@CID. No status filter - all mirror cash allocations.
- Component 3 (Pending Stock Orders): **COMMENTED OUT** - originally included `Stocks.GetOrders WHERE IsPending=1`. Removed by Adi (24/01/2019). No longer part of used margin.
- Final: `ISNULL(@AmountInOpenPositions, 0) + ISNULL(@TotalMirrorCash, 0)`
- Result is INTEGER - subject to overflow for very large accounts (fixed in GetUsedMarginBigInt)

**Diagram**:
```
@CID
  |
  +-- Trade.PositionTbl WHERE CID=@CID AND StatusID=1
  |   SUM(Amount)*100 -> @AmountInOpenPositions (INTEGER, cents)
  |
  +-- Trade.Mirror WHERE CID=@CID
  |   SUM(Amount)*100 -> @TotalMirrorCash (INTEGER, cents)
  |
  +-- [Stocks.GetOrders - REMOVED 2019]
  |
  v
ISNULL(@AmountInOpenPositions,0) + ISNULL(@TotalMirrorCash,0)
= @UsedMargin (INTEGER, cents)
```

### 2.2 StatusID=1 Filter (Added MIMOPSA-13899)

**What**: Only open positions (StatusID=1) contribute to used margin. Closed positions do not tie up funds.

**Columns/Parameters Involved**: `@AmountInOpenPositions`, StatusID

**Rules**:
- StatusID=1 = Open position (funds are locked as margin collateral)
- Closed/expired positions (StatusID=2+) already released their funds; including them would overstate used margin
- The filter was added by Itay Hay (26/08/2024) per MIMOPSA-13899 - prior to this fix the function could overstate margin for customers with many closed positions

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID of the customer whose total used margin to calculate. Filters both Trade.PositionTbl and Trade.Mirror by CID. |

### Return Value

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UsedMargin | INTEGER | NO | 0 | CODE-BACKED | Total used margin in cents (INTEGER). Sum of: (1) all open position amounts (StatusID=1) from Trade.PositionTbl * 100, plus (2) all mirror/copy-trade cash allocations from Trade.Mirror * 100. Returns 0 if the customer has no open positions or mirror allocations. WARNING: INTEGER overflow risk for very large accounts - use GetUsedMarginBigInt instead for production use. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.PositionTbl | Table read | SUM(Amount) WHERE CID=@CID AND StatusID=1. Only open positions contribute to margin. Amount is in dollars; converted to cents by *100. |
| @CID | Trade.Mirror | Table read | SUM(Amount) WHERE CID=@CID. All copy-trade cash allocations. Amount in dollars; converted to cents by *100. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Superseded by BackOffice.GetUsedMarginBigInt; GetCustomerByCID migrated to BigInt version.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetUsedMargin (function)
├── Trade.PositionTbl (table) [cross-schema]
└── Trade.Mirror (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SUM(Amount)*100 WHERE CID=@CID AND StatusID=1. Open trading position collateral. |
| Trade.Mirror | Table | SUM(Amount)*100 WHERE CID=@CID. Mirror/copy-trading cash allocations. |

### 6.2 Objects That Depend On This

Legacy callers only. GetCustomerByCID migrated to GetUsedMarginBigInt to fix INTEGER overflow.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function. Note: returns INTEGER - potential overflow (MAX_INT ~$21M) for high-value accounts. Use GetUsedMarginBigInt for safety.

---

## 8. Sample Queries

### 8.1 Get used margin for a customer (cents)

```sql
SELECT BackOffice.GetUsedMargin(12345) AS UsedMarginCents,
       BackOffice.GetUsedMargin(12345) / 100.0 AS UsedMarginUSD;
```

### 8.2 Compare with BigInt version (recommended)

```sql
SELECT
    BackOffice.GetUsedMargin(12345) AS GetUsedMargin_INT,
    BackOffice.GetUsedMarginBigInt(12345) AS GetUsedMarginBigInt_BIGINT;
-- Results should match for normal account sizes; BigInt is safer for large accounts
```

### 8.3 Get used margin directly from source tables (recommended for production)

```sql
SELECT
    ISNULL(CAST(SUM(Amount) * 100 AS BIGINT), 0) AS OpenPositionMarginCents
FROM Trade.PositionTbl WITH (NOLOCK)
WHERE CID = 12345 AND StatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [MIMOPSA-13899: function BackOffice.GetUsedMargin - Add Status=1](https://etoro-jira.atlassian.net/browse/MIMOPSA-13899) | Jira Story | Added StatusID=1 filter to restrict calculation to open positions only (Aug 2024, Itay Hay). Prior to this fix, the function included closed positions in the margin sum, overstating used margin. Part of MIMOPSA-9598 "Backoffice enhancements". |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetUsedMargin | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetUsedMargin.sql*
