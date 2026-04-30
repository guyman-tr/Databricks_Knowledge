# Hedge.CalculateAccountStatusFromNetting

> Computes the aggregate mark-to-market P&L for all open hedge positions of a single liquidity account by joining Hedge.Netting to live bid prices in Trade.CurrencyPrice.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT-only - aggregates P&L across Hedge.Netting for one LiquidityAccountID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.CalculateAccountStatusFromNetting` is a real-time P&L calculator for a single liquidity provider account. Given a `@LiquidityAccountID`, it scans all open net hedge positions in `Hedge.Netting` and computes the total unrealized (floating) P&L by multiplying position size against the spread between the current market bid price and the average entry rate.

This procedure is the "read" complement to `Hedge.AddOrUpdateNetting`: AddOrUpdateNetting maintains the current net position state, while this procedure converts that state into a dollar P&L figure using live market data from `Trade.CurrencyPrice`.

The result is a single aggregate PnL value across all instruments for the given LP account. It is used for account-level risk monitoring and status reporting, allowing the hedge engine to assess the financial position of the LP account without reading from a snapshot table.

The formula encodes the standard mark-to-market P&L calculation:
- **Long positions** (IsBuy=1): P&L = (Bid - AvgRate) * Units * UnitMargin/Bid
- **Short positions** (IsBuy=0): P&L = -(Bid - AvgRate) * Units * UnitMargin/Bid = (AvgRate - Bid) * Units * UnitMargin/Bid

The `UnitMargin/Bid` factor converts notional position value to margin-adjusted dollar P&L in the account's base currency.

---

## 2. Business Logic

### 2.1 Mark-to-Market P&L Formula

**What**: Computes aggregate unrealized P&L across all open positions for the LP account.

**Columns/Parameters Involved**: `@LiquidityAccountID`, `HN.Units`, `TCP.Bid`, `HN.AvgRate`, `TCP.UnitMargin`, `HN.IsBuy`

**Rules**:
- P&L per position = `Units * (Bid - AvgRate) * UnitMargin/Bid * CASE WHEN IsBuy=0 THEN -1 ELSE 1 END`
- For long (IsBuy=1): positive if Bid > AvgRate (price moved in favor)
- For short (IsBuy=0): multiply by -1, so profit when Bid < AvgRate (price moved in favor of short)
- `UnitMargin/Bid` converts from price-spread units to USD value per unit (margin normalization factor from Trade.CurrencyPrice)
- SUM aggregates all instruments into one total PnL figure
- Returns NULL if no positions exist (SUM of empty set)
- Returns a single row, single column: `PnL`

### 2.2 Join - Netting to Live Price

**What**: Positions are joined to live bid prices to get current market value.

**Columns/Parameters Involved**: `HN.InstrumentID`, `TCP.InstrumentID`, `HN.LiquidityAccountID`

**Rules**:
- JOIN Hedge.Netting HN ON HN.InstrumentID = TCP.InstrumentID AND HN.LiquidityAccountID = @LiquidityAccountID
- Both tables use WITH (NOLOCK) - dirty reads acceptable for real-time P&L estimation
- Join is INNER, so positions without a current price in Trade.CurrencyPrice are silently excluded
- Trade.CurrencyPrice is the live market data feed - Bid is the current market bid price

**Diagram**:
```
Hedge.CalculateAccountStatusFromNetting(@LiquidityAccountID)
      |
      SELECT SUM(PnL per position) FROM:
      |
      Hedge.Netting HN (NOLOCK)         -> Units, IsBuy, AvgRate per InstrumentID
      JOIN Trade.CurrencyPrice TCP (NOLOCK) -> Bid, UnitMargin per InstrumentID
      ON HN.InstrumentID = TCP.InstrumentID
         AND HN.LiquidityAccountID = @LiquidityAccountID
      |
      PnL = Units * (Bid - AvgRate) * UnitMargin/Bid * (IsBuy=0 ? -1 : 1)
      |
      -> Single row: AS PnL
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityAccountID | int | NO | - | CODE-BACKED | LP account whose open positions to aggregate. Filters Hedge.Netting AND is part of the JOIN condition with Trade.CurrencyPrice. FK to Trade.LiquidityAccounts. |

**Output column:**

| Column | Type | Description |
|--------|------|-------------|
| PnL | DECIMAL (derived) | Sum of mark-to-market unrealized P&L across all open positions for this LP account. Positive = net profit, negative = net loss. NULL if no positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HN | Hedge.Netting | SELECT (NOLOCK) | Source of net positions: Units, IsBuy, AvgRate per InstrumentID |
| TCP | Trade.CurrencyPrice | SELECT (NOLOCK) | Source of live market prices: Bid, UnitMargin per InstrumentID |
| @LiquidityAccountID | Trade.LiquidityAccounts | Implicit | LP account being evaluated |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by hedge monitoring or account status computation pipelines needing real-time P&L.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.CalculateAccountStatusFromNetting (procedure)
|- Hedge.Netting (table) - position source
+-- Trade.CurrencyPrice (table) - live price source
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.Netting | Table | SELECT - Units, IsBuy, AvgRate, InstrumentID for the LP account |
| Trade.CurrencyPrice | Table | SELECT - Bid, UnitMargin for each InstrumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Hedge monitoring/account status pipeline) | External | Reads aggregate P&L for LP account |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- No SET NOCOUNT ON - will emit row counts to caller
- No TRY/CATCH - errors propagate naturally
- INNER JOIN silently drops instruments missing from Trade.CurrencyPrice
- WITH (NOLOCK) on both tables - P&L is an estimate, not a transactionally consistent value
- Returns NULL (not 0) if the account has no open positions in Hedge.Netting
- No currency normalization beyond UnitMargin/Bid - all positions assumed to be in same base currency

---

## 8. Sample Queries

### 8.1 Execute: Get total P&L for LP account 101

```sql
EXEC Hedge.CalculateAccountStatusFromNetting @LiquidityAccountID = 101
```

### 8.2 Inline: Use result in a larger account status query

```sql
DECLARE @PnL DECIMAL(18,4)
EXEC @PnL = Hedge.CalculateAccountStatusFromNetting @LiquidityAccountID = 101
-- Note: actual result is a resultset, not a return value - use INSERT EXEC pattern:

CREATE TABLE #PnL (PnL DECIMAL(18,4))
INSERT INTO #PnL EXEC Hedge.CalculateAccountStatusFromNetting @LiquidityAccountID = 101
SELECT PnL FROM #PnL
```

### 8.3 Verify: Manual P&L check for one instrument

```sql
-- Manual per-instrument breakdown for verification
SELECT
    HN.InstrumentID,
    HN.Units,
    HN.IsBuy,
    HN.AvgRate,
    TCP.Bid,
    TCP.UnitMargin,
    HN.Units * (TCP.Bid - HN.AvgRate) * TCP.UnitMargin / TCP.Bid
        * CASE WHEN HN.IsBuy = 0 THEN -1 ELSE 1 END AS InstrumentPnL
FROM Hedge.Netting HN WITH (NOLOCK)
JOIN Trade.CurrencyPrice TCP WITH (NOLOCK) ON HN.InstrumentID = TCP.InstrumentID
WHERE HN.LiquidityAccountID = 101
ORDER BY InstrumentPnL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.CalculateAccountStatusFromNetting | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.CalculateAccountStatusFromNetting.sql*
