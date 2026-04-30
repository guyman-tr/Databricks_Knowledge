# Price.SetCurrencyPriceBulkSecondaryWithUnitMargin

> Bulk UPSERT for Trade.CurrencyPriceSecondary with independent bid/ask unit margins: identical to SetCurrencyPriceBulkSecondary but uses Price.CurrencyPriceSeconadryTableWithUnitMargin (which carries separate UnitMarginBid and UnitMarginAsk columns), enabling asymmetric margin tracking per side.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RatesToUpdate (TVP), @ProviderID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.SetCurrencyPriceBulkSecondaryWithUnitMargin is the unit-margin-aware variant of SetCurrencyPriceBulkSecondary. It performs the same bulk UPSERT on Trade.CurrencyPriceSecondary (with the same PriceRateID change guard and INSERT-new-rows logic), but uses a richer TVP type that carries separate `UnitMarginBid` and `UnitMarginAsk` columns.

The key difference from the base variant:
- `SetCurrencyPriceBulkSecondary`: `UnitMarginBid = RTU.UnitMargin` (general), `UnitMarginAsk = NULL`
- `SetCurrencyPriceBulkSecondaryWithUnitMargin`: `UnitMarginBid = RTU.UnitMarginBid`, `UnitMarginAsk = RTU.UnitMarginAsk`

This allows the caller to provide distinct unit margin values for buy-side and sell-side transactions - enabling asymmetric margin pricing for the secondary feed. This is used when the secondary feed provider specifies different margin requirements for long vs short positions on the same instrument.

All other behavior is identical: temp table with UNIQUE CLUSTERED INDEX (InstrumentID, FeedID), PriceRateID change guard on UPDATE, INSERT for new instrument+feed combinations.

---

## 2. Business Logic

### 2.1 TVP to Temp Table

**What**: Same pattern as SetCurrencyPriceBulkSecondary - TVP materialized into temp table with unique clustered index.

**Columns/Parameters Involved**: `@RatesToUpdate`, `#CurrencyPriceSeconadryTable`

**Rules**:
- Temp table has additional columns vs. base variant: `UnitMarginBid DECIMAL(16,8) NULL`, `UnitMarginAsk DECIMAL(16,8) NULL`
- `INSERT INTO #CurrencyPriceSeconadryTable SELECT * FROM @RatesToUpdate`
- UNIQUE CLUSTERED INDEX (InstrumentID, FeedID) for join optimization

### 2.2 UPDATE with PriceRateID Change Guard

**What**: Same PriceRateID <> guard as base variant, but reads UnitMarginBid/UnitMarginAsk independently from TVP.

**Columns/Parameters Involved**: `UnitMarginBid`, `UnitMarginAsk`

**Rules**:
- `UnitMarginBid = RTU.UnitMarginBid` (from TVP directly - not derived from general UnitMargin)
- `UnitMarginAsk = RTU.UnitMarginAsk` (from TVP directly - not NULL)
- All other UPDATE fields are identical to SetCurrencyPriceBulkSecondary
- JOIN: `CP.InstrumentID = RTU.InstrumentID AND CP.FeedID = RTU.FeedID AND CP.PriceRateID <> RTU.PriceRateID`

### 2.3 INSERT New Rows

**What**: Inserts rows for new instrument+feed combinations - same logic as base variant.

**Rules**:
- `WHERE NOT EXISTS (SELECT 1 FROM Trade.CurrencyPriceSecondary CPS WITH (NOLOCK) WHERE CPS.InstrumentID=RTU.InstrumentID AND CPS.FeedID=RTU.FeedID)`
- INSERT includes `UnitMarginBid, UnitMarginAsk` from the temp table (independent values)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RatesToUpdate | Price.CurrencyPriceSeconadryTableWithUnitMargin READONLY | NOT NULL | - | CODE-BACKED | TVP with independent bid/ask unit margins. Extends Price.CurrencyPriceSeconadryTable by splitting the single UnitMargin column into separate UnitMarginBid DECIMAL(16,8) and UnitMarginAsk DECIMAL(16,8). Note: "Seconadry" typo in type name is in the original schema. |
| 2 | @ProviderID | INT | NOT NULL | - | CODE-BACKED | The secondary liquidity provider ID. Written to Trade.CurrencyPriceSecondary.ProviderID for all updated/inserted rows. |

**Result set**: None.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RatesToUpdate | Price.CurrencyPriceSeconadryTableWithUnitMargin | TVP type | Input price tick batch with independent bid/ask unit margins |
| InstrumentID + FeedID | Trade.CurrencyPriceSecondary | WRITER (UPSERT) | Same as SetCurrencyPriceBulkSecondary but with independent UnitMarginBid/Ask |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (secondary pricing engine - asymmetric margin mode) | @RatesToUpdate | CALLER | Called when secondary feed provides separate bid/ask unit margins |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.SetCurrencyPriceBulkSecondaryWithUnitMargin (procedure)
+-- Price.CurrencyPriceSeconadryTableWithUnitMargin (UDT) - TVP type
+-- Trade.CurrencyPriceSecondary (table) - UPSERT target
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.CurrencyPriceSeconadryTableWithUnitMargin | User Defined Type | TVP parameter type (adds UnitMarginBid, UnitMarginAsk vs. base type) |
| Trade.CurrencyPriceSecondary | Table | UPSERT target - same as SetCurrencyPriceBulkSecondary |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (secondary pricing engine) | External | Calls when asymmetric bid/ask unit margins are available from secondary feed |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Creates temp table with UNIQUE CLUSTERED INDEX (InstrumentID, FeedID) at runtime.

### 7.2 Constraints

No SET NOCOUNT ON. No explicit transaction. Identical to SetCurrencyPriceBulkSecondary in all respects except the TVP type and UnitMarginBid/Ask population. "Seconadry" typo in the TVP type name is inherited from the schema (must be preserved). The only behavioral difference is that UnitMarginAsk is now populated from the TVP (not NULL), enabling accurate margin calculations for short/ask-side positions on the secondary feed.

---

## 8. Sample Queries

### 8.1 Update secondary prices with separate bid/ask unit margins

```sql
DECLARE @Rates Price.CurrencyPriceSeconadryTableWithUnitMargin;
INSERT INTO @Rates
    (InstrumentID, Bid, Ask, Occurred, PriceRateID, FeedID,
     SkewValueBid, SkewValueAsk, UnitMarginBid, UnitMarginAsk)
VALUES (1, 1.10500000, 1.10520000, GETUTCDATE(), 99999, 1, 0, 0, 0.0100, 0.0095);

EXEC Price.SetCurrencyPriceBulkSecondaryWithUnitMargin
    @RatesToUpdate = @Rates,
    @ProviderID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.SetCurrencyPriceBulkSecondaryWithUnitMargin | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.SetCurrencyPriceBulkSecondaryWithUnitMargin.sql*
