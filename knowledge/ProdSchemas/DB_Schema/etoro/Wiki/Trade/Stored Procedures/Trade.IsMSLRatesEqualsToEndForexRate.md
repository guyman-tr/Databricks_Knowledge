# Trade.IsMSLRatesEqualsToEndForexRate

> Validates that all positions closed by a mirror stop loss (MSL) event were closed at the correct forex rates: parses the rate snapshot from History.MirrorSLCloseLog and compares it against actual EndForexRate values on the closed positions, setting @Result = 1 if all rates match.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID - the mirror whose MSL closing rates to validate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.IsMSLRatesEqualsToEndForexRate is a validation procedure for the Mirror Stop Loss (MSL) workflow. When a copy trading mirror hits its stop loss threshold, the system closes all open positions in that mirror at the current market rates. These rates are logged as a compressed string in History.MirrorSLCloseLog.RatesList. After the close, this procedure verifies that the actual closing rates recorded on each position (History.Position.EndForexRate) match the rates that were supposed to be used (from MirrorSLCloseLog).

This acts as a reconciliation check: if all positions were correctly closed at the logged MSL rates, @Result = 1. If any positions have a different EndForexRate than expected, @Result = 0, indicating a discrepancy that may require investigation or retry.

The RatesList format is a custom key-value string (e.g., "InstrumentID: 100005 BidSpreaded: 102.74 BidDiscounted: 103.01 AskSpreaded: 104.70 AskDiscounted: 103.50, ..."). The procedure converts this string to XML for parsing (changed from loop-based parsing in June 2019). Rate selection depends on IsBuy direction and whether the position is "real" (as determined by Trade.FnIsRealPosition).

Data flow: MSL closing job -> History.MirrorSLCloseLog (logs rates snapshot) -> positions closed -> Trade.IsMSLRatesEqualsToEndForexRate (validates closing rates) -> result drives retry or acceptance.

History (from DDL comments): Created 2015 (Adi); modified 2015 (Mor) to add ActionType=13 condition; redesigned 2019 (Yitzchak) from loop-based to XML parsing, added BidDiscounted/AskDiscounted support.

---

## 2. Business Logic

### 2.1 Rate String to XML Parsing

**What**: The RatesList string from History.MirrorSLCloseLog is transformed into XML and parsed into a temp table.

**Columns/Parameters Involved**: `History.MirrorSLCloseLog.RatesList`, `#RatesTable`

**Rules**:
- SELECT RatesList WHERE MirrorID = @MirrorID from History.MirrorSLCloseLog.
- String cleanup: LTRIM/RTRIM, remove trailing comma if present.
- XML construction:
  1. Replace `,` with `"/><Info####` (separates entries)
  2. Replace `: ` with `="` (key-value separator)
  3. Replace ` ` (spaces) with `" ` (attribute separator)
  4. Replace `####` with ` ` (restore the info element separator)
  5. Wrap in `<root><Info .../>...</root>`
- Parse XML via `.nodes('/root/Info')` with `.value('@AttributeName', 'type')` for each field.
- Parsed columns: InstrumentID, BidSpreaded, AskSpreaded, BidDiscounted, AskDiscounted.

**Example input**: `InstrumentID: 100005 BidSpreaded: 102.74 BidDiscounted: 103.01 AskSpreaded: 104.70 AskDiscounted: 103.50`
**Becomes XML**: `<root><Info InstrumentID="100005" BidSpreaded="102.74" BidDiscounted="103.01" AskSpreaded="104.70" AskDiscounted="103.50"/></root>`

### 2.2 Position Count Comparison

**What**: Compares total MSL-closed positions against positions whose EndForexRate exactly matches the expected rate.

**Columns/Parameters Involved**: `@PositionCount1`, `@PositionCount2`, `History.Position`, `#RatesTable`, `Trade.FnIsRealPosition`

**@PositionCount1 (all MSL-closed positions)**:
- Count of History.Position WHERE MirrorID = @MirrorID AND (EndDateTime >= MSL CloseOccurred OR ActionType = 13).
- Includes both regular MSL closures (EndDateTime at or after the stop loss trigger) and action type 13 positions.

**@PositionCount2 (positions closed at correct rate)**:
- Same filter + JOIN to #RatesTable on InstrumentID + JOIN Trade.ProviderToInstrument + CROSS APPLY Trade.FnIsRealPosition.
- Rate match condition (IsBuy + IsRealPosition determines which rate to check):
  - IsBuy=1, IsRealPosition=0 (CFD): EndForexRate = BidSpreaded
  - IsBuy=1, IsRealPosition=1 (real stock): EndForexRate = BidDiscounted
  - IsBuy=0, IsRealPosition=0 (CFD): EndForexRate = AskSpreaded
  - IsBuy=0, IsRealPosition=1 (real stock): EndForexRate = AskDiscounted

**Result**: SET @Result = CASE WHEN (@PositionCount1 - @PositionCount2 = 0) THEN 1 ELSE 0 END
- @Result = 1: all positions closed at correct MSL rates.
- @Result = 0: at least one position has a mismatched closing rate.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | int | NO | - | CODE-BACKED | The mirror whose MSL closing rates to validate. FK to History.MirrorSLCloseLog.MirrorID and History.Position.MirrorID. |
| 2 | @Result | bit OUTPUT | NO | - | CODE-BACKED | OUTPUT. 1 = all positions for this mirror were closed at the correct MSL rates. 0 = one or more positions have a different EndForexRate than the logged MSL rates. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (rate string) | History.MirrorSLCloseLog | Reader | Reads RatesList (key-value string) and CloseOccurred timestamp for the mirror |
| SELECT COUNT(*) | History.Position | Reader | Counts MSL-closed positions (PositionCount1) and rate-matched positions (PositionCount2) |
| JOIN | Trade.ProviderToInstrument | Reader | Joins to validate instrument is in provider mapping; required for CROSS APPLY |
| CROSS APPLY | Trade.FnIsRealPosition | Callee (Function) | Determines IsRealPosition flag from HP.IsSettled + HP.InstrumentID; controls rate selection |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Called by MSL validation/reconciliation jobs after MSL positions are closed.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IsMSLRatesEqualsToEndForexRate (procedure)
├── History.MirrorSLCloseLog (table) - MSL rates snapshot + close timestamp
├── History.Position (table) - closed position records with EndForexRate
├── Trade.ProviderToInstrument (table) - instrument-to-provider mapping
└── Trade.FnIsRealPosition (function) - determines real vs CFD position type
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.MirrorSLCloseLog | Table | RatesList string (parsed to XML) + CloseOccurred timestamp for window filter |
| History.Position | Table | Position records to count and validate EndForexRate |
| Trade.ProviderToInstrument | Table | JOIN required to scope positions to valid instrument-provider pairs |
| Trade.FnIsRealPosition | Function | CROSS APPLY per position to determine IsRealPosition (real stock vs CFD) for rate selection |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MSL reconciliation service | External (Application) | Calls after MSL close to validate all positions were closed at correct rates |
| Trade.IsMSLRatesEqualsToEndForexRateV2 | Stored Procedure | Successor variant using updated rate format and History.PositionSlim |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| XML string parsing | Design | RatesList is a semi-structured string converted to XML ad-hoc; format must match expected key-value pattern |
| ActionType = 13 | Business rule | Positions with ActionType=13 are always included in the MSL close group regardless of EndDateTime |
| Rate selection logic | Business rule | 4-way CASE on (IsBuy, IsRealPosition): CFD uses Spreaded rates, real positions use Discounted rates |
| No error handling | Design | No TRY/CATCH; XML parse errors or missing MirrorID propagate to caller |
| Superseded by V2 | Lifecycle | V2 added in 2024 for new MSL rate structure; this V1 may be retained for backward compatibility with older MirrorSLCloseLog records |

---

## 8. Sample Queries

### 8.1 Validate MSL rates for a mirror

```sql
DECLARE @Valid BIT;
EXEC Trade.IsMSLRatesEqualsToEndForexRate @MirrorID = 123456, @Result = @Valid OUTPUT;
SELECT @Valid AS RatesAreValid;
-- 1 = all closing rates match, 0 = discrepancy found
```

### 8.2 View the rate snapshot for a mirror

```sql
SELECT MirrorID, RatesList, CloseOccurred
FROM History.MirrorSLCloseLog WITH (NOLOCK)
WHERE MirrorID = 123456;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.IsMSLRatesEqualsToEndForexRate | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.IsMSLRatesEqualsToEndForexRate.sql*
