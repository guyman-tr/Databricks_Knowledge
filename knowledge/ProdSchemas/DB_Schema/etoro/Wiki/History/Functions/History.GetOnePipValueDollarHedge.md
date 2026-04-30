# History.GetOnePipValueDollarHedge

> Scalar function that computes the USD value of one pip for hedge position reporting - the hedge-specific variant of GetOnePipValueDollar: uses XML price snapshot, no spread parameters, no customer ID, simplified cross-pair calculation.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Scalar Function |
| **Signature** | `GetOnePipValueDollarHedge(@InstrumentID, @ProviderID, @IsBuy, @pPercision, @PriceXML) RETURNS MONEY` |
| **Purpose** | One-pip USD value for hedge positions - no spread, no customer context |

---

## 1. Business Meaning

`History.GetOnePipValueDollarHedge` is the hedge-specific variant of the GetOnePipValueDollar family. It computes the USD value of one pip for reporting on hedged positions (Trade.Hedge / History.Hedge), where:
- No customer is involved (no `@CID` parameter - hedges are LP-level, not per-customer)
- No spread adjustment is applied (hedges use raw market prices, no customer spread)
- No spread parameters exist (@pSpreadedPipBid, @pSpreadedPipAsk removed)
- Uses XML price snapshot (`@PriceXML`) like the base `GetOnePipValueDollar`
- Cross-pair calculation is simplified: just `DollarRatio / Bid` or `DollarRatio * Bid` without SpreadGroup lookup

The function has EXECUTE permission granted to the Dealing role (`UsersPermissions/Dealing.sql`), indicating it is called from the Dealing application for hedge analytics. No SSDT stored procedures reference it directly.

**For the full one-pip value formula explanation and variant comparison, see `History.GetOnePipValueDollar.md`.**

---

## 2. Business Logic

### 2.1 One-Pip USD Value Formula (Simplified for Hedge Context)

Same three-case structure as `History.GetOnePipValueDollar`, but simplified:

**Case 1 (SellCurrencyAbbr = 'USD')**: `DollarRatio` directly - identical to base function.

**Case 2 (BuyCurrencyAbbr = 'USD')**: `DollarRatio / Bid` (long) or `DollarRatio / Ask` (short) - from @PriceXML table. **No spread added** (no @pSpreadedPipBid/Ask parameters).

**Case 3 (cross pair)**:
- Sub-case 3a (USD/Sell exists): `DollarRatio / Bid` - raw Bid from @PriceXML, no spread
- Sub-case 3b (Sell/USD exists): `DollarRatio * Bid` - raw Bid from @PriceXML, no spread
- No SpreadGroup, no ProviderToInstrument, no Customer joins needed

**Final**: `ROUND(@Result, @Occuracy)` where Occuracy = Trade.Provider.Occuracy.

### 2.2 XML Price Parsing

Same as `History.GetOnePipValueDollar`: `@PriceXML` is parsed into `@PriceTable (ProviderID INT, InstrumentID INT, Bid dtPrice, Ask dtPrice)` via `.nodes('Prices/Instrument')`. ProviderID filter IS applied (`AND TCRP.ProviderID = @ProviderID`).

---

## 3. Data Overview

Execution blocked (EXECUTE permission not granted to McpUserRO; function called from Dealing application). Behavior follows the same formula as GetOnePipValueDollar with spread = 0 and no SpreadGroup.

---

## 4. Elements

### Parameters

| # | Parameter | Type | Description |
|---|-----------|------|-------------|
| 1 | @InstrumentID | INTEGER | Trading instrument. Used for BuyCurrencyID, SellCurrencyID, DollarRatio lookup. |
| 2 | @ProviderID | INTEGER | Liquidity provider. Used for Occuracy (rounding) AND ProviderID filter on @PriceTable. |
| 3 | @IsBuy | INTEGER | Position direction: 1=buy (uses Bid), 0=sell (uses Ask). |
| 4 | @pPercision | TINYINT | Decimal precision (used for spread conversion only - no spread in this variant, but parameter retained for signature consistency). NULL treated as 0. |
| 5 | @PriceXML | XML | XML price snapshot. Format: `<Prices><Instrument @ID="..." @RateAsk="..." @RateBid="..." /></Prices>`. |

### Return Value

| Type | Description |
|------|-------------|
| MONEY | USD value of one pip for the hedge position. No spread adjustment. Returns 0 if no currency mapping. Rounded to Trade.Provider.Occuracy. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderID | Trade.Provider | Query (cross-schema) | Occuracy for rounding |
| @InstrumentID | Trade.Instrument | Query (cross-schema) | BuyCurrencyID, SellCurrencyID, DollarRatio |
| @InstrumentID | Dictionary.Currency | Query (cross-schema) | Currency abbreviation for case detection |
| @PriceXML | @PriceTable (in-memory) | XML parse | Price snapshot |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| Dealing application | Application code | EXECUTE GRANT to Dealing role - called for hedge position pip value calculation |

No SSDT stored procedures reference this function.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetOnePipValueDollarHedge (scalar function)
|--> Trade.Provider (cross-schema)
|--> Trade.Instrument (cross-schema)
+--> Dictionary.Currency (cross-schema)
```

---

## 7. Technical Details

Simpler than `GetOnePipValueDollar` due to no spread/SpreadGroup/Customer dependencies for cross pairs. This makes it more performant when called for hedge position reporting where customer context is irrelevant.

---

## 8. Sample Queries

### 8.1 Compute hedge pip value for EUR/USD

```sql
DECLARE @PriceXML XML = '<Prices><Instrument ID="1" RateAsk="110000" RateBid="109990" /></Prices>'
SELECT History.GetOnePipValueDollarHedge(
    1,         -- @InstrumentID
    1,         -- @ProviderID
    1,         -- @IsBuy
    4,         -- @pPercision
    @PriceXML  -- @PriceXML
) AS HedgePipValueUSD
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 8.3/10, Logic: 8.5/10, Relationships: 8.3/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 10, 11) - live data blocked*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 direct SSDT consumers (Dealing app via GRANT) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetOnePipValueDollarHedge | Type: Scalar Function | Source: etoro/etoro/History/Functions/History.GetOnePipValueDollarHedge.sql*
