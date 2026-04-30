# Trade.ManualPositionStopLoss

> Manual-use utility procedure that applies a new stop-loss rate to a single open position, resolving the USD conversion rate before delegating to the standard SL-edit routine.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (the position to update), @StopRate (new SL rate) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a simple manual interface for setting a new stop-loss rate on a specific open position. It is designed for ad-hoc use by operations staff when the application's normal SL-edit flow is not available or when a direct database correction is needed. Unlike `Trade.ManualModifySLForCriptoPositions`, it does not require additional capital from the user - it applies the SL change with zero credit delta (@Amount = 0, @NetProfit = 0).

The procedure exists to give operators a clean, self-contained tool that handles the conversion rate resolution logic (normalizing the instrument's settlement currency to USD), so the caller only needs to supply a position ID and a new rate. Without it, a manual SL edit would require the operator to separately compute the conversion rate and call `Trade.PositionEditStopLoss` directly with the right parameters.

Data flow: The caller provides a @PositionID and @StopRate. The procedure looks up the position's instrument currency pair and provider, then computes the appropriate USD conversion rate using the current price data in `Trade.CurrencyPrice`. It then calls `Trade.PositionEditStopLoss` passing @Amount=0 and @NetProfit=0 (no capital change) and @IsInitiatedByUser=1 (treated as a user-initiated operation).

---

## 2. Business Logic

### 2.1 USD Conversion Rate Resolution

**What**: Determines the rate used to convert the instrument's P&L into USD, required by Trade.PositionEditStopLoss.

**Columns/Parameters Involved**: `@SellCurrencyID`, `@BuyCurrencyID`, `@ProviderID`, `@LastOpConversionRate`, `@LastOpConversionRateID`

**Rules**:
- If `SellCurrencyID = 1` OR `BuyCurrencyID = 1` (USD is one side of the pair - "major instrument"): ConversionRate = 1, no lookup needed
- If cross pair (no USD): look for an instrument where BuyCurrencyID=1 AND SellCurrencyID=SellCurrencyID (inverse pair) - if found: ConversionRate = 1/Bid
- If inverse not found: look for instrument where SellCurrencyID=1 AND BuyCurrencyID=SellCurrencyID - ConversionRate = Bid
- Price is always fetched for the same @ProviderID as the position

**Diagram**:
```
SellCurrencyID = 1 OR BuyCurrencyID = 1
  -> ConversionRate = 1 (USD major pair, no conversion needed)

Else: find instrument (BuyCurrencyID=1, SellCurrencyID=SellCurrencyID)
  -> Found: ConversionRate = 1/Bid (inverse)
  -> Not found: find (SellCurrencyID=1, BuyCurrencyID=SellCurrencyID)
       -> ConversionRate = Bid (direct)
```

### 2.2 Zero-Delta SL Edit

**What**: Applies the new SL rate without any capital adjustment - the operator is simply repositioning the SL level.

**Columns/Parameters Involved**: `@Amount` (= 0), `@NetProfit` (= 0), `@IsInitiatedByUser` (= 1)

**Rules**:
- @Amount is hardcoded to 0: no credit transfer occurs (contrast with ManualModifySLForCriptoPositions which computes a non-zero delta)
- @NetProfit is hardcoded to 0: no P&L change is recorded
- @IsInitiatedByUser is hardcoded to 1: the system treats this as a user-requested change (as opposed to a system-triggered SL hit)
- @LastOpPriceRate is NULL and @LastOpPriceRateID = 1: last operation price rate not tracked in this utility

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | bigint | NO | - | CODE-BACKED | The unique identifier of the open position whose stop-loss rate is to be modified. Looked up in Trade.Position to retrieve instrument, currency, and provider details. |
| 2 | @StopRate | dtPrice | NO | - | CODE-BACKED | The new stop-loss rate to apply, expressed in the instrument's quote currency. Passed directly to Trade.PositionEditStopLoss as the new SL level. dtPrice is a Trade-schema user-defined decimal type for price values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Trade.Position | JOIN (READ) | Reads position details: InstrumentID, ProviderID, CurrencyIDs, Amount |
| Internal | Trade.Instrument | JOIN (READ) | Gets BuyCurrencyID and SellCurrencyID for conversion rate path selection; also queried to find the cross-rate instrument |
| Internal | Trade.CurrencyPrice | JOIN (READ) | Gets current Bid price for USD conversion rate calculation, filtered by ProviderID |
| Internal | Trade.PositionEditStopLoss | EXEC (CALL) | Core delegate: performs the actual SL update with versioning, @Amount=0, @NetProfit=0, @IsInitiatedByUser=1 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| etoro/etoro/UsersPermissions/PROD_BIadmins.sql | GRANT EXECUTE | Permission | PROD_BIadmins role has EXECUTE permission granted on this procedure |

No application code callers found - this is a manual/ad-hoc utility procedure.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ManualPositionStopLoss (procedure)
+-- Trade.Position (view) [READ - position details]
+-- Trade.Instrument (table) [READ - currency IDs for conversion; cross-rate instrument lookup]
+-- Trade.CurrencyPrice (table) [READ - current Bid price for conversion rate]
+-- Trade.PositionEditStopLoss (procedure) [EXEC - applies the actual SL change]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT to get InstrumentID, ProviderID, BuyCurrencyID (via join to Instrument), SellCurrencyID, CurrentAmount for the given @PositionID |
| Trade.Instrument | Table | Joined to Trade.Position for currency IDs; also queried directly to find the cross-rate instrument pair for non-USD instruments |
| Trade.CurrencyPrice | Table | Joined to Trade.Instrument to get current Bid price for the conversion instrument, filtered by @ProviderID |
| Trade.PositionEditStopLoss | Stored Procedure | Called to apply the new @StopRate with Amount=0, NetProfit=0, IsInitiatedByUser=1 and the resolved conversion rate |

### 6.2 Objects That Depend On This

No dependents found - this is a standalone manual utility procedure.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @LastOpConversionRate IS NULL check | Guard | Conversion rate is only resolved if not already set - allows future extension where a caller could pre-supply the rate |
| ProviderID filter on CurrencyPrice | Query filter | Price is always fetched for the specific provider associated with the position, ensuring price consistency |

---

## 8. Sample Queries

### 8.1 Apply a new stop-loss rate to a specific position
```sql
EXEC Trade.ManualPositionStopLoss
    @PositionID = 123456789,
    @StopRate   = 102.5;
```

### 8.2 Verify the position details before running
```sql
SELECT
    p.PositionID,
    p.InstrumentID,
    i.InstrumentDisplayName,
    p.StopRate       AS CurrentSL,
    p.Amount,
    p.StatusID,
    p.MirrorID,
    p.ProviderID
FROM Trade.Position p WITH (NOLOCK)
INNER JOIN Trade.Instrument i WITH (NOLOCK) ON p.InstrumentID = i.InstrumentID
WHERE p.PositionID = 123456789;
```

### 8.3 Check current conversion rate for non-USD instruments before running
```sql
-- For a cross-rate instrument (e.g. EUR/GBP, SellCurrencyID = 2 (GBP))
SELECT
    i.InstrumentDisplayName,
    i.SellCurrencyID,
    i.BuyCurrencyID,
    cp.Bid,
    cp.Ask
FROM Trade.CurrencyPrice cp WITH (NOLOCK)
INNER JOIN Trade.Instrument i WITH (NOLOCK) ON cp.InstrumentID = i.InstrumentID
WHERE (i.SellCurrencyID = 1 AND i.BuyCurrencyID = 2)  -- adjust CurrencyIDs as needed
  AND cp.ProviderID = 1  -- replace with actual ProviderID from position
ORDER BY cp.PriceRateID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (PositionEditStopLoss) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ManualPositionStopLoss | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ManualPositionStopLoss.sql*
