# History.GetPositionForXML

> XML-serialization-friendly position view - joins History.Position with a unified hedge source (History.Hedge UNION ALL Trade.Hedge) and Trade.Instrument + Trade.ProviderToInstrument, formatting IsBuy and CloseOnEndOfWeek as 'true'/'false' strings, hardcoding IsOpened=0, and adding instrument unit size. No current SQL procedure consumers in SSDT codebase.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | PositionID (bigint) from History.Position |
| **Partition** | N/A |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

History.GetPositionForXML is a legacy view designed to produce closed position data in a format suitable for XML serialization - typically for SOAP/web service endpoints that consumed position data in XML format. The key formatting differences from History.GetPosition are:

1. **IsBuy and CloseOnEndOfWeek as string 'true'/'false'**: XML boolean serialization convention; avoids ambiguity between integer 0/1 and boolean true/false in XML schemas
2. **IsOpened = 0**: Hardcoded to indicate these are closed positions (as opposed to open positions from a hypothetical companion view)
3. **Financial values in cents (INTEGER)**: NetProfit, Amount, Commission, CommissionOnClose, EndOfWeekFee all multiplied by 100 and cast to INTEGER
4. **TPVI.Unit**: The lot/unit size for this instrument-provider combination from Trade.ProviderToInstrument - required for lot-size calculations in position value computations

The additional JOIN to Trade.ProviderToInstrument (on ProviderID + InstrumentID) means that for a position to appear in this view, it must have a matching provider-to-instrument mapping. This makes the view a stricter filter than History.GetPosition.

**No SQL procedure consumers** found in the SSDT codebase. This view was likely consumed by an external application or a SOAP service layer that has since been retired or migrated.

---

## 2. Business Logic

### 2.1 XML Boolean Formatting

**What**: Boolean fields are returned as string 'true'/'false' rather than bit 1/0.

**Columns/Parameters Involved**: `IsBuy`, `CloseOnEndOfWeek`

**Rules**:
```sql
CASE HPOS.IsBuy WHEN 1 THEN 'true' ELSE 'false' END AS IsBuy
CASE HPOS.CloseOnEndOfWeek WHEN 1 THEN 'true' ELSE 'false' END AS CloseOnEndOfWeek
```
This produces XML-compatible boolean literals when the result is serialized to XML.

### 2.2 IsOpened Hardcoded = 0

**What**: IsOpened is always 0 (closed) in this view.

**Columns/Parameters Involved**: `IsOpened`

**Rules**:
- `0 AS IsOpened` - hardcoded; all rows from History.Position are closed positions
- A companion view for open positions would return IsOpened = 1
- This field allows a consumer to distinguish open vs closed positions when both are serialized into the same XML document

### 2.3 ProviderToInstrument JOIN (Unit Size)

**What**: Adds TPVI.Unit from Trade.ProviderToInstrument.

**Columns/Parameters Involved**: `Unit`, `ProviderID`, `InstrumentID`

**Rules**:
- `Trade.ProviderToInstrument TPVI` joined on `HPOS.ProviderID = TPVI.ProviderID AND HPOS.InstrumentID = TPVI.InstrumentID`
- This is an INNER JOIN (using comma syntax): if a position has no matching provider-instrument mapping, it is EXCLUDED from results
- TPVI.Unit provides the lot/pip/unit size for this instrument under this provider configuration

### 2.4 Unified Hedge Source (History + Trade, without Commission)

**What**: Hedge data from History.Hedge UNION ALL Trade.Hedge - but this version does NOT include Commission from the hedge side.

**Rules**:
- Both branches select: HedgeID, TradeID, AccountID, HedgeServerID, LotCountDecimal
- Commission is NOT selected from either hedge branch (unlike History.GetPosition which includes NULL AS Commission for Trade.Hedge)
- LEFT OUTER JOIN on HedgeID; NULL hedge columns for positions without hedge records

---

## 3. Data Overview

Same underlying data as History.Position, but INNER JOIN to Trade.ProviderToInstrument means positions with no provider-instrument mapping are excluded. All boolean values are returned as strings.

---

## 4. Elements

37 columns (one more than History.GetPosition due to IsOpened and Unit, but no HedgeCommission column):

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | CID | int | CODE-BACKED | Customer ID |
| 2 | PositionID | bigint | CODE-BACKED | Position identifier |
| 3 | ForexResultID | int | CODE-BACKED | Game result reference |
| 4 | IsOpened | int | CODE-BACKED | Hardcoded 0 = closed position |
| 5 | Currency | int | CODE-BACKED | HPOS.CurrencyID - account denomination currency |
| 6 | ProviderID | int | CODE-BACKED | Liquidity provider |
| 7 | InstrumentID | int | CODE-BACKED | Traded instrument |
| 8 | HedgeID | int | CODE-BACKED | Hedge record reference |
| 9 | PositionHedgeServerID | int | CODE-BACKED | HPOS.HedgeServerID - position's hedge server |
| 10 | HedgeServerID | int | CODE-BACKED | HHDG.HedgeServerID - from hedge record |
| 11 | Leverage | int | CODE-BACKED | Position leverage multiplier |
| 12 | ForexBuy | int | CODE-BACKED | Trade.Instrument.BuyCurrencyID |
| 13 | ForexSell | int | CODE-BACKED | Trade.Instrument.SellCurrencyID |
| 14 | InitForexRate | dbo.dtPrice | CODE-BACKED | Open rate (not cast to DOUBLE unlike GetPosition) |
| 15 | EndForexRate | dbo.dtPrice | CODE-BACKED | Close rate |
| 16 | InitDateTime | datetime | CODE-BACKED | Position open datetime |
| 17 | ActionType | tinyint | CODE-BACKED | Close reason code |
| 18 | EndDateTime | datetime | CODE-BACKED | Position close datetime |
| 19 | NetProfit | int | CODE-BACKED | CAST(NetProfit*100 AS INTEGER) - cents |
| 20 | LimitRate | dbo.dtPrice | CODE-BACKED | Take profit rate |
| 21 | StopRate | dbo.dtPrice | CODE-BACKED | Stop loss rate |
| 22 | PositionAmountCents | int | CODE-BACKED | CAST(Amount*100 AS INTEGER) |
| 23 | AmountInUnitsDecimal | decimal(16,6) | CODE-BACKED | Units-based position size |
| 24 | CommissionCents | int | CODE-BACKED | CAST(Commission*100 AS INTEGER) |
| 25 | CommissionOnCloseCents | int | CODE-BACKED | CAST(CommissionOnClose*100 AS INTEGER) |
| 26 | SpreadedCommission | money | CODE-BACKED | Spread-adjusted commission |
| 27 | IsBuy | varchar | CODE-BACKED | 'true' or 'false' (XML boolean string) |
| 28 | CloseOnEndOfWeek | varchar | CODE-BACKED | 'true' or 'false' (XML boolean string) |
| 29 | EndOfWeekFee | int | CODE-BACKED | CAST(EndOfWeekFee*100 AS INTEGER) - cents |
| 30 | Unit | decimal | CODE-BACKED | Trade.ProviderToInstrument.Unit - lot/unit size |
| 31 | LotCountDecimal | decimal(16,6) | CODE-BACKED | Position lot count |
| 32 | HedgedLotCountDecimal | decimal(16,6) | CODE-BACKED | Hedge-side lot count |
| 33 | AdditionalParam | varchar | CODE-BACKED | Additional position parameters |
| 34 | TradeID | int | CODE-BACKED | LP trade ID from hedge |
| 35 | AccountID | int | CODE-BACKED | LP account ID from hedge |
| 36 | InitForexPriceRateID | bigint | CODE-BACKED | Open price rate ID |
| 37 | EndForexPriceRateID | bigint | CODE-BACKED | Close price rate ID |
| 38 | OrderPriceRateID | bigint | CODE-BACKED | Order price rate ID |
| 39 | Occurred | datetime | CODE-BACKED | HPOS.OpenOccurred (aliased) |
| 40 | ParentPositionID | bigint | CODE-BACKED | Copy trade parent position ID |
| 41 | OrigParentPositionID | bigint | CODE-BACKED | Original parent before detachment |
| 42 | LastOpPriceRate | dbo.dtPrice | CODE-BACKED | Last operation price rate |
| 43 | LastOpPriceRateID | bigint | CODE-BACKED | Last operation price rate ID |
| 44 | LastOpConversionRate | dbo.dtPrice | CODE-BACKED | Last operation conversion rate |
| 45 | LastOpConversionRateID | bigint | CODE-BACKED | Last operation conversion rate ID |
| 46 | MirrorID | int | CODE-BACKED | Copy portfolio ID |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (base) | History.Position | View (source) | All closed positions |
| HedgeID | History.Hedge | LEFT JOIN (UNION ALL) | Historical hedge records |
| HedgeID | Trade.Hedge | LEFT JOIN (UNION ALL) | Live hedge records |
| InstrumentID | Trade.Instrument | INNER JOIN (implicit) | Instrument currency IDs |
| ProviderID+InstrumentID | Trade.ProviderToInstrument | INNER JOIN (implicit) | Instrument unit size per provider |

### 5.2 Referenced By (other objects point to this)

No SQL procedure consumers found in SSDT codebase. Likely a legacy view for SOAP/XML service consumption.

---

## 6. Dependencies

```
History.GetPositionForXML (view)
|- History.Position (view - full position history)
|- History.Hedge (table - historical hedge records)
|- Trade.Hedge (table - live hedge records)
|- Trade.Instrument (table - instrument currencies)
+- Trade.ProviderToInstrument (table - unit size per provider-instrument)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for History.GetPositionForXML.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.3/10 (Elements: 8.0/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 46 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 consumers found | App Code: 0 repos | Corrections: 0 applied*
*Object: History.GetPositionForXML | Type: View | Source: etoro/etoro/History/Views/History.GetPositionForXML.sql*
