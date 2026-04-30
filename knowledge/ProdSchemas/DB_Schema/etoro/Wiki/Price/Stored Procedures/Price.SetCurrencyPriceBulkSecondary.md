# Price.SetCurrencyPriceBulkSecondary

> Bulk UPSERT for Trade.CurrencyPriceSecondary: updates existing rows only when PriceRateID has changed (anti-stale-update guard), inserts new rows for any InstrumentID+FeedID not yet present. Sets UnitMarginBid from the general UnitMargin field; UnitMarginAsk is always NULL.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RatesToUpdate (TVP), @ProviderID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.SetCurrencyPriceBulkSecondary is the bulk price update procedure for the secondary price feed (Trade.CurrencyPriceSecondary). It processes a batch of price ticks from the secondary liquidity provider, applying them to the secondary price store used for backup/fallback pricing or alternative client channel distribution.

Unlike the primary price update procedures (SetCurrencyPriceBulkWithConversionRate/WithUnitMargin which are UPDATE-only), this procedure is a full UPSERT: it can both update existing rows (for instruments already in the secondary store) and insert new rows (first time a secondary feed provides a price for an instrument).

The PriceRateID change guard (`CP.PriceRateID <> RTU.PriceRateID` in the JOIN) prevents redundant updates: if the pricing engine submits the same price tick twice (same PriceRateID), the UPDATE is skipped since the data is already current. This reduces write load on the secondary price table.

The unit margin asymmetry: `UnitMarginBid = RTU.UnitMargin` (uses the general per-instrument unit margin from the TVP) while `UnitMarginAsk = NULL`. This means the secondary feed tracks the bid-side unit margin but not a separate ask-side margin - consistent with the TVP type `Price.CurrencyPriceSeconadryTable` which carries only a single `UnitMargin` column (not separate bid/ask). For separate bid/ask unit margins, use SetCurrencyPriceBulkSecondaryWithUnitMargin.

---

## 2. Business Logic

### 2.1 TVP to Temp Table (with Unique Clustered Index)

**What**: The input TVP is materialized into a temp table with a unique clustered index on (InstrumentID, FeedID) for join performance.

**Columns/Parameters Involved**: `@RatesToUpdate`, `#CurrencyPriceSeconadryTable`

**Rules**:
- `CREATE TABLE #CurrencyPriceSeconadryTable ... INDEX CIX UNIQUE CLUSTERED (InstrumentID, FeedID)`
- `INSERT INTO #CurrencyPriceSeconadryTable SELECT * FROM @RatesToUpdate`: copies all TVP rows
- The UNIQUE constraint on (InstrumentID, FeedID) means duplicate instrument+feed combinations in the TVP would cause an insert error - callers must de-duplicate before passing

### 2.2 UPDATE with PriceRateID Change Guard

**What**: Only updates rows where the PriceRateID has changed (i.e., truly new price data).

**Columns/Parameters Involved**: `PriceRateID`, `ProviderID`, `UnitMarginBid`, `UnitMarginAsk`

**Rules**:
- JOIN condition: `CP.InstrumentID = RTU.InstrumentID AND CP.FeedID = RTU.FeedID AND CP.PriceRateID <> RTU.PriceRateID`
- If the existing PriceRateID matches the incoming one: no UPDATE (price already current, skip)
- If PriceRateID differs: full row update including all price fields, timestamps, market IDs, margins, and skew values
- `UnitMarginBid = RTU.UnitMargin` (general margin -> bid margin), `UnitMarginAsk = NULL`
- Note: WITH (NOLOCK) on the read side of the JOIN is valid since the UPDATE will acquire update locks

### 2.3 INSERT New Rows

**What**: Inserts rows for InstrumentID+FeedID combinations not yet in CurrencyPriceSecondary.

**Columns/Parameters Involved**: `InstrumentID`, `FeedID`

**Rules**:
- `WHERE NOT EXISTS (SELECT 1 FROM Trade.CurrencyPriceSecondary CPS WITH (NOLOCK) WHERE CPS.InstrumentID=RTU.InstrumentID AND CPS.FeedID=RTU.FeedID)`
- First-time instrument+feed: no existing row -> INSERT with ProviderID from @ProviderID parameter, UnitMarginBid=UnitMargin, UnitMarginAsk=NULL
- Subsequent ticks for the same instrument+feed: handled by the UPDATE path

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RatesToUpdate | Price.CurrencyPriceSeconadryTable READONLY | NOT NULL | - | CODE-BACKED | TVP of secondary feed price ticks to upsert. Type: Price.CurrencyPriceSeconadryTable (InstrumentID, Bid, Ask, Occurred, OccurredOnServer, PriceRateID, ReceivedOnPriceServer, MarketPriceRateID, LastPrice, BidMarketPriceRateID, AskMarketPriceRateID, MarkupPips, UnitMargin, FeedID, SkewValueBid, SkewValueAsk). Note: "Seconadry" typo in type name is in the original schema. |
| 2 | @ProviderID | INT | NOT NULL | - | CODE-BACKED | The secondary liquidity provider ID. Written to Trade.CurrencyPriceSecondary.ProviderID for all updated/inserted rows. Identifies which secondary feed source produced these prices. |

**Result set**: None. (No SELECT statement.)

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RatesToUpdate | Price.CurrencyPriceSeconadryTable | TVP type | Input price tick batch type |
| InstrumentID + FeedID | Trade.CurrencyPriceSecondary | WRITER (UPSERT) | UPDATE existing rows (PriceRateID-change guard) + INSERT new rows |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (secondary pricing engine) | @RatesToUpdate | CALLER | Called on each secondary feed price tick batch |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.SetCurrencyPriceBulkSecondary (procedure)
+-- Price.CurrencyPriceSeconadryTable (UDT) - TVP type
+-- Trade.CurrencyPriceSecondary (table) - UPSERT target
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.CurrencyPriceSeconadryTable | User Defined Type | TVP parameter type |
| Trade.CurrencyPriceSecondary | Table | UPSERT target - UPDATE existing (PriceRateID-changed) + INSERT new |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (secondary pricing engine) | External | Calls to bulk-update the secondary price store |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Creates temp table with UNIQUE CLUSTERED INDEX (InstrumentID, FeedID) at runtime.

### 7.2 Constraints

No SET NOCOUNT ON. No explicit transaction (UPDATE and INSERT are separate implicit transactions). PriceRateID change guard on UPDATE prevents redundant writes. Note "Seconadry" typo in TVP type name (`Price.CurrencyPriceSeconadryTable`) and temp table name - this is in the original schema and must be preserved for compatibility. UnitMarginBid is set from the general UnitMargin field; UnitMarginAsk is always NULL. For independent bid/ask unit margins use Price.SetCurrencyPriceBulkSecondaryWithUnitMargin.

---

## 8. Sample Queries

### 8.1 Update secondary prices for a provider

```sql
DECLARE @Rates Price.CurrencyPriceSeconadryTable;
INSERT INTO @Rates (InstrumentID, Bid, Ask, Occurred, PriceRateID, FeedID, SkewValueBid, SkewValueAsk)
VALUES (1, 1.10500000, 1.10520000, GETUTCDATE(), 99999, 1, 0, 0);

EXEC Price.SetCurrencyPriceBulkSecondary
    @RatesToUpdate = @Rates,
    @ProviderID = 2;
```

### 8.2 Check what's in secondary price store

```sql
SELECT InstrumentID, FeedID, Bid, Ask, PriceRateID, ProviderID, UnitMarginBid, UnitMarginAsk
FROM Trade.CurrencyPriceSecondary WITH (NOLOCK)
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.SetCurrencyPriceBulkSecondary | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.SetCurrencyPriceBulkSecondary.sql*
