# Trade.IsMSLRatesEqualsToEndForexRateV2

> Updated version of Trade.IsMSLRatesEqualsToEndForexRate: validates MSL closing rates against History.PositionSlim using the new 2024 rate format (EtoroPriceBid/Ask +/- CfdMarkup/RealMarkup instead of BidSpreaded/AskDiscounted).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID - the mirror whose MSL closing rates to validate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.IsMSLRatesEqualsToEndForexRateV2 is the 2024 successor to Trade.IsMSLRatesEqualsToEndForexRate. It was updated by Ori K. in June 2024 to "align data with new MSL structure" - reflecting a change in how eToro's MSL system records rates in History.MirrorSLCloseLog. The new format stores the eToro base price and separate markup components (CfdMarkup, RealMarkup) instead of pre-computed spread values (BidSpreaded, BidDiscounted).

The procedure validates that all positions closed by an MSL event have their EndForexRate matching the expected value (base price minus/plus the appropriate markup), setting @Result = 1 if all match. It also uses History.PositionSlim instead of History.Position, which is a lighter/narrower view of position history for better query performance.

The core logic (XML parsing, count comparison, rate direction matrix) is identical to V1.

History (DDL comments): V1 created 2015; V2 added June 2024 (Ori K.) for new MSL rate structure.

---

## 2. Business Logic

### 2.1 Rate String to XML Parsing

**What**: Identical XML parsing approach to V1 - same string-to-XML transformation.

**Differences**: #RatesTable has different columns - EtoroPriceAsk, CfdMarkupAsk, RealMarkupAsk, EtoroPriceBid, CfdMarkupBid, RealMarkupBid.

Example new format: `InstrumentID: 100005 EtoroPriceAsk: 103.50 CfdMarkupAsk: 0.30 RealMarkupAsk: 0.49 EtoroPriceBid: 102.74 CfdMarkupBid: 0.27 RealMarkupBid: 0.27`

See Trade.IsMSLRatesEqualsToEndForexRate Section 2.1 for full XML parsing logic.

### 2.2 Position Count Comparison

**What**: Same two-count approach as V1 but with updated source table and rate formula.

**Key differences from V1**:

1. **Source table**: `History.PositionSlim` (not History.Position) - a slimmer position history table for better performance.

2. **Rate formula** (IsBuy + IsRealPosition -> expected EndForexRate):
   - IsBuy=1, IsRealPosition=0 (CFD buy): EndForexRate = EtoroPriceBid - CfdMarkupBid
   - IsBuy=1, IsRealPosition=1 (real buy): EndForexRate = EtoroPriceBid - RealMarkupBid
   - IsBuy=0, IsRealPosition=0 (CFD sell): EndForexRate = EtoroPriceAsk + RealMarkupAsk
   - IsBuy=0, IsRealPosition=1 (real sell): EndForexRate = EtoroPriceAsk + RealMarkupAsk
   Note: Both sell cases (IsBuy=0) use EtoroPriceAsk + RealMarkupAsk. This may be intentional or a minor inconsistency (CfdMarkupAsk unused for sells).

3. **Result logic**: Identical - @Result = 1 if @PositionCount1 = @PositionCount2, else 0.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | int | NO | - | CODE-BACKED | The mirror whose MSL closing rates to validate. FK to History.MirrorSLCloseLog.MirrorID and History.PositionSlim.MirrorID. |
| 2 | @Result | bit OUTPUT | NO | - | CODE-BACKED | OUTPUT. 1 = all positions closed at correct MSL rates (new format). 0 = at least one EndForexRate does not match expected value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (rate string) | History.MirrorSLCloseLog | Reader | Reads RatesList (new format) and CloseOccurred timestamp |
| SELECT COUNT(*) | History.PositionSlim | Reader | Counts MSL-closed positions and rate-matched positions (lighter table than History.Position) |
| JOIN | Trade.ProviderToInstrument | Reader | Instrument-to-provider mapping for position scoping |
| CROSS APPLY | Trade.FnIsRealPosition | Callee (Function) | Determines IsRealPosition from HP.IsSettled + HP.InstrumentID for rate direction |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Replaces V1 in MSL validation jobs for mirrors using the new rate format.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IsMSLRatesEqualsToEndForexRateV2 (procedure)
├── History.MirrorSLCloseLog (table) - MSL rates snapshot (new format)
├── History.PositionSlim (table) - slim position history with EndForexRate
├── Trade.ProviderToInstrument (table) - instrument-to-provider mapping
└── Trade.FnIsRealPosition (function) - real vs CFD position type determination
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.MirrorSLCloseLog | Table | RatesList (new format with EtoroPriceBid/Ask + markups) and CloseOccurred |
| History.PositionSlim | Table | Slim position history; PositionCount1 (total) and PositionCount2 (rate-matched) counts |
| Trade.ProviderToInstrument | Table | JOIN for instrument-provider validation |
| Trade.FnIsRealPosition | Function | CROSS APPLY to determine real vs CFD for rate selection |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MSL reconciliation service | External (Application) | Uses V2 for mirrors using the new rate format (post-2024 MSL structure) |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| New rate format | Business rule | RatesList now contains EtoroPriceAsk/Bid + CfdMarkup/RealMarkup fields instead of BidSpreaded/BidDiscounted |
| History.PositionSlim | Performance | Uses narrower position history table vs History.Position in V1 |
| Both IsBuy=0 cases use same formula | Possible inconsistency | Both CFD and real sell positions use EtoroPriceAsk + RealMarkupAsk; CfdMarkupAsk is unused for sells |
| No error handling | Design | No TRY/CATCH; same as V1 |

---

## 8. Sample Queries

### 8.1 Validate MSL rates for a mirror (new format)

```sql
DECLARE @Valid BIT;
EXEC Trade.IsMSLRatesEqualsToEndForexRateV2 @MirrorID = 123456, @Result = @Valid OUTPUT;
SELECT @Valid AS RatesAreValidV2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.IsMSLRatesEqualsToEndForexRateV2 | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.IsMSLRatesEqualsToEndForexRateV2.sql*
