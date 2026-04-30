# History.GetPositionInfo

> Fully-enriched position info view - joins History.Position with Customer.Customer (username), Trade.GetInstrument (name), Dictionary.GameServer (name), Dictionary.Currency (abbreviation), and Trade.Provider (name), plus unified hedge data - providing human-readable position context for back-office and reporting. No current SQL procedure consumers in SSDT codebase.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | PositionID (bigint) from History.Position |
| **Partition** | N/A |
| **Indexes** | N/A (view - base table indexes used) |

---

## 1. Business Meaning

History.GetPositionInfo is the most enriched of the GetPosition* view family. While History.GetPosition provides hedge enrichment and History.GetPositionForXML adds XML formatting, GetPositionInfo adds human-readable name resolutions for all reference IDs: customer username, instrument name, currency abbreviation, game server name, and provider name.

This view was designed for back-office and reporting use cases where humans (operators, support staff) need to see position records with descriptive context rather than raw IDs. The INNER JOINs to Customer.Customer, Trade.GetInstrument, Dictionary.GameServer, Dictionary.Currency, and Trade.Provider mean that a position row is only returned if it has valid, resolvable values for all reference IDs.

**ForexResultID aliased as ActionID**: The ForexResultID column is exposed as `ActionID`, an older naming convention that treated positions as forex game "actions".

**No SQL procedure consumers** found in the SSDT codebase. This view was likely used directly by SSRS reports or legacy BI tools.

---

## 2. Business Logic

### 2.1 Name Resolution JOINs

**What**: Multiple INNER JOINs resolve reference IDs to human-readable names.

**Columns/Parameters Involved**: `UserName`, `InstrumentName`, `GameServerName`, `CurrencyAbbreviation`, `ProviderName`

**Rules**:
- `Customer.Customer CCST` on `HPOS.CID = CCST.CID` -> UserName
- `Trade.GetInstrument TISR` on `HPOS.InstrumentID = TISR.InstrumentID` -> InstrumentName
  - Note: uses `Trade.GetInstrument` (a view), not `Trade.Instrument` (the base table)
- `Dictionary.GameServer DGMS` on `HPOS.GameServerID = DGMS.GameServerID` -> GameServerName
- `Dictionary.Currency DCUR` on `HPOS.CurrencyID = DCUR.CurrencyID` -> CurrencyAbbreviation
- `Trade.Provider TPRV` on `HPOS.ProviderID = TPRV.ProviderID` -> ProviderName
- All are INNER JOINs (using comma syntax) - positions with unresolvable reference IDs are excluded

### 2.2 Unified Hedge Source (History + Trade)

**What**: Same LEFT OUTER JOIN on History.Hedge UNION ALL Trade.Hedge as GetPosition and GetPositionForXML.

**Rules**:
- Provides TradeID, AccountID, HedgeServerID (from hedge side), HedgedLotCountDecimal
- No Commission selected from hedge branch
- NULL for positions without hedge records

### 2.3 Money in Cents

**What**: Money values are INTEGER cents, same as other GetPosition* views.

**Rules**:
- Amount: CAST(Amount*100 AS INTEGER)
- NetProfit: CAST(NetProfit*100 AS INTEGER)
- Commission: CAST(Commission*100 AS INTEGER)
- CommissionOnClose: CAST(CommissionOnClose*100 AS INTEGER)

---

## 3. Data Overview

Subset of History.Position (all closed positions where all reference IDs are resolvable). Same data characteristics as History.Position but with name context added.

---

## 4. Elements

31 columns combining position data with human-readable resolutions:

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | ActionID | int | CODE-BACKED | HPOS.ForexResultID aliased as ActionID - legacy "action" naming |
| 2 | PositionID | bigint | CODE-BACKED | Position identifier |
| 3 | CID | int | CODE-BACKED | Customer ID |
| 4 | UserName | varchar | CODE-BACKED | Customer.Customer.UserName - human-readable customer identifier |
| 5 | CurrencyID | int | CODE-BACKED | Account denomination currency ID |
| 6 | CurrencyAbbreviation | varchar | CODE-BACKED | Dictionary.Currency.Abbreviation (e.g., 'USD', 'EUR') |
| 7 | ProviderID | int | CODE-BACKED | Liquidity provider ID |
| 8 | HedgeID | int | CODE-BACKED | Hedge record reference |
| 9 | PositionHedgeServerID | int | CODE-BACKED | HPOS.HedgeServerID - from position record |
| 10 | HedgeServerID | int | CODE-BACKED | HHDG.HedgeServerID - from hedge record |
| 11 | ProviderName | varchar | CODE-BACKED | Trade.Provider.Name - liquidity provider display name |
| 12 | GameServerID | int | CODE-BACKED | Game server ID |
| 13 | GameServerName | varchar | CODE-BACKED | Dictionary.GameServer.Name - game server display name |
| 14 | InstrumentID | int | CODE-BACKED | Traded instrument ID |
| 15 | InstrumentName | varchar | CODE-BACKED | Trade.GetInstrument.Name - instrument display name |
| 16 | Amount | int | CODE-BACKED | CAST(Amount*100 AS INTEGER) - investment in cents |
| 17 | AmountInUnitsDecimal | decimal(16,6) | CODE-BACKED | Units-based position size |
| 18 | InitForexRate | dbo.dtPrice | CODE-BACKED | Open rate |
| 19 | InitDateTime | datetime | CODE-BACKED | Position open datetime |
| 20 | NetProfit | int | CODE-BACKED | CAST(NetProfit*100 AS INTEGER) - P&L in cents |
| 21 | LimitRate | dbo.dtPrice | CODE-BACKED | Take profit rate |
| 22 | StopRate | dbo.dtPrice | CODE-BACKED | Stop loss rate |
| 23 | IsBuy | bit | CODE-BACKED | Direction: 1=Buy, 0=Sell (bit, not string like GetPositionForXML) |
| 24 | CloseOnEndOfWeek | bit | CODE-BACKED | End-of-week close flag (bit) |
| 25 | Commission | int | CODE-BACKED | CAST(Commission*100 AS INTEGER) - cents |
| 26 | CommissionOnClose | int | CODE-BACKED | CAST(CommissionOnClose*100 AS INTEGER) - cents |
| 27 | SpreadedCommission | money | CODE-BACKED | Spread-adjusted commission |
| 28 | LotCountDecimal | decimal(16,6) | CODE-BACKED | Position lot count |
| 29 | HedgedLotCountDecimal | decimal(16,6) | CODE-BACKED | Hedge-side lot count |
| 30 | EndForexRate | dbo.dtPrice | CODE-BACKED | Close rate |
| 31 | EndDateTime | datetime | CODE-BACKED | Position close datetime |
| (additional) | ActionType, TradeID, AccountID, Occurred, ForexPriceRateIDs, ParentPositionID, OrigParentPositionID, MirrorID | Various | CODE-BACKED | Operational metadata - same as GetPosition |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (base) | History.Position | View (source) | All closed positions |
| HedgeID | History.Hedge | LEFT JOIN (UNION ALL) | Historical hedge records |
| HedgeID | Trade.Hedge | LEFT JOIN (UNION ALL) | Live hedge records |
| InstrumentID | Trade.GetInstrument | INNER JOIN | Instrument name (via GetInstrument view) |
| CID | Customer.Customer | INNER JOIN | Customer username |
| GameServerID | Dictionary.GameServer | INNER JOIN | Game server name |
| CurrencyID | Dictionary.Currency | INNER JOIN | Currency abbreviation |
| ProviderID | Trade.Provider | INNER JOIN | Provider name |

### 5.2 Referenced By (other objects point to this)

No SQL procedure consumers found in SSDT codebase. Legacy view for back-office/reporting.

---

## 6. Dependencies

```
History.GetPositionInfo (view)
|- History.Position (view - full position history)
|- History.Hedge (table)
|- Trade.Hedge (table)
|- Customer.Customer (table - cross-schema)
|- Trade.GetInstrument (view - cross-schema)
|- Dictionary.GameServer (table - cross-schema)
|- Dictionary.Currency (table - cross-schema)
+- Trade.Provider (table - cross-schema)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for History.GetPositionInfo.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.4/10 (Elements: 8.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 31 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 consumers found | App Code: 0 repos | Corrections: 0 applied*
*Object: History.GetPositionInfo | Type: View | Source: etoro/etoro/History/Views/History.GetPositionInfo.sql*
