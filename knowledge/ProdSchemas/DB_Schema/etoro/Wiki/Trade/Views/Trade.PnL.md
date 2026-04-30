# Trade.PnL

> Core real-time PnL (profit and loss) calculation view that computes live unrealized PnL for every open position by CROSS APPLYing Trade.FnCalculatePnLWrapper with NULL end rates, which triggers live market rate fetching through a 5-level function chain down to Trade.CurrencyPrice.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.PositionTbl) |
| **Partition** | PartitionCol (inherited from PositionTbl, computed as PositionID % 50) |
| **Indexes** | N/A (view, no indexed view) |
| **Status** | Active / core infrastructure view |

---

## 1. Business Meaning

Trade.PnL is one of the most critical views in the eToro trading platform. It answers a single, essential question: **"How much unrealized profit or loss does each open position have right now?"** The view produces one row per open position (StatusID = 1) containing the real-time PnL in both dollars and cents, along with the live market rates used for the calculation and the PriceRateIDs for audit trails. It covers every position type: manual trades, CopyTrader positions, CFD contracts, real stock positions, and all instrument classes (forex, stocks, crypto, commodities, indices).

This view exists because dozens of consumers across the platform need live PnL but should not each independently implement the complex rate-fetching and multi-currency PnL calculation logic. Without Trade.PnL, every procedure that needs unrealized PnL — withdrawal validation, equity calculations, copy-trading copier profit display, position reopening, risk monitoring — would need to replicate the 5-level function chain that converts position parameters into a live PnL figure. Centralizing it in a view ensures consistency: every consumer sees the same PnL number for the same position at the same point in time.

Data flows: The view reads from Trade.PositionTbl (filtered to StatusID = 1, open positions only) and passes 10 position-level parameters to Trade.FnCalculatePnLWrapper with all four end rate parameters set to NULL. The NULL end rates cause the wrapper to route to Trade.FnCalculateCurrentPnL, which chains Trade.FnGetCurrentConversionRate (live currency conversion from instrument currency to account currency), Trade.FnGetCurrentClosingRate (live bid/ask based on direction and real/CFD classification), and Trade.FnCalculatePnL (the core formula). The rates are read from Trade.CurrencyPrice with NOLOCK. Consumers join to this view via PositionID + PartitionCol (partition-aligned), or via CID, or via MirrorID for copy-trading aggregations.

---

## 2. Business Logic

### 2.1 Live Rate PnL Calculation via NULL End Rates

**What**: Passing NULL for all four end rate parameters forces the PnL function chain to fetch current live market rates instead of using pre-supplied historical rates.

**Columns/Parameters Involved**: `FnCalculatePnLWrapper(@EndClosingRate=NULL, @EndClosingRateID=NULL, @EndConversionRate=NULL, @EndConversionRateID=NULL)`

**Rules**:
- All four end rate parameters are hardcoded to NULL in the view definition
- NULL @EndClosingRate AND NULL @EndConversionRate → wrapper routes to FnCalculateCurrentPnL (live branch)
- FnCalculateCurrentPnL chains: FnGetCurrentConversionRate → FnGetCurrentClosingRate → FnCalculatePnL
- Live closing rate selection depends on direction and real/CFD: Buy+CFD=Bid, Buy+Real=BidDiscounted, Sell+CFD=Ask, Sell+Real=AskDiscounted
- Live conversion rate depends on account currency, conversion instrument (may be reciprocal), direction, and real/CFD
- Returns both PnLInDollars (money, ROUND to 2 decimals) and PnLInCents (PnLInDollars × 100, for cent-precision systems)
- The PnL formula has two variants based on PnLVersion and IsSettled — see Section 2.2

**Diagram**:
```
Trade.PnL (view)
    │
    ├── FROM Trade.PositionTbl (NOLOCK, StatusID=1)
    │     └── 10 parameters: InstrumentID, IsBuy, AmountInUnitsDecimal, IsSettled,
    │         InitForexRate, InitConversionRate, PnLVersion, EstimatedMarkupRatio,
    │         EstimatedConversionMarkupRatio, CurrencyID
    │
    └── CROSS APPLY Trade.FnCalculatePnLWrapper(... NULL, NULL, NULL, NULL)
          │
          └── [Both NULLs] → Trade.FnCalculateCurrentPnL
                │
                ├── CROSS APPLY FnGetCurrentConversionRate
                │     ├── FnGetConversionInstrument → Trade.Instrument
                │     ├── FnIsRealPosition → Trade.InstrumentMetaData
                │     └── FROM Trade.CurrencyPrice (NOLOCK)
                │
                ├── CROSS APPLY FnGetCurrentClosingRate
                │     ├── FnIsRealPosition → Trade.InstrumentMetaData
                │     └── FROM Trade.CurrencyPrice (NOLOCK)
                │
                └── CROSS APPLY FnCalculatePnL (pure formula, no table access)
                      └── Returns: PnLInDollars, PnLInCents, CurrentClosingRate,
                          CurrentClosingRateID, ConversionRate, ConversionRateID
```

### 2.2 Dual PnL Formulas (Inherited from Trade.FnCalculatePnL)

**What**: Two distinct PnL formulas exist based on PnLVersion and IsSettled, reflecting a historical evolution in multi-currency PnL computation.

**Columns/Parameters Involved**: `TPOS.PnLVersion`, `TPOS.IsSettled`, `TPOS.InitForexRate`, `TPOS.InitConversionRate`, `FCP.CurrentClosingRate`, `FCP.ConversionRate`, `TPOS.AmountInUnitsDecimal`, `TPOS.IsBuy`

**Rules**:
- **Legacy formula** (PnLVersion=1 AND IsSettled=1 — real stock positions on v1): `ROUND((EndRate × EndConvRate - InitRate × InitConvRate) × Units × Direction, 2)` — conversion rate movement between open and close affects PnL
- **Standard formula** (all other cases — CFDs, v2+ positions): `ROUND((EndRate - InitRate) × EndConvRate × Units × Direction, 2)` — only the current conversion rate matters
- Direction multiplier: Buy=+1 (profit when price rises), Sell=-1 (profit when price falls)
- Result always rounded to 2 decimal places (cents precision)

**Diagram**:
```
PnLVersion=1 AND IsSettled=1 (Legacy Real Stock):
  PnL = (EndRate × EndConvRate - InitRate × InitConvRate) × Units × Dir
        ├── Close value in account currency
        └── Open value in account currency (both conversion-embedded)

All other cases (Standard — CFDs, v2+):
  PnL = (EndRate - InitRate) × EndConvRate × Units × Dir
        ├── Price difference in instrument currency
        └── Convert to account currency using current rate only
```

### 2.3 Partition-Aligned Join Pattern

**What**: Exposes PartitionCol enabling consumers to perform partition-aligned joins back to Trade.PositionTbl.

**Columns/Parameters Involved**: `PartitionCol`, `PositionID`

**Rules**:
- PartitionCol = PositionID % 50 (inherited from PositionTbl computed column)
- Consumers MUST include PartitionCol in JOIN predicates for partition elimination (e.g., `PnL.PartitionCol = TPOS.PartitionCol`)
- All major consumer procedures and views follow this pattern — see Section 5.2
- Without PartitionCol in the join, queries scan all 50 partitions instead of 1

### 2.4 Multi-Currency Conversion

**What**: Positions traded in non-account-currency instruments require conversion. ConversionRate bridges from instrument currency to account currency.

**Columns/Parameters Involved**: `ConversionRate`, `ConversionRateID`, `TPOS.CurrencyID` (passed as @AccountCurrencyID)

**Rules**:
- When instrument trades directly in account currency → ConversionRate = 1.0 (no conversion needed, most common for USD accounts)
- When conversion is needed → FnGetConversionInstrument finds the bridge instrument via Trade.Instrument currency pair matching
- Conversion may be reciprocal (1/rate) depending on the currency pair direction
- ConversionRate reflects bid/ask/discounted pricing based on direction and real/CFD classification — same matrix as closing rate but applied to the conversion instrument

---

## 3. Data Overview

| CID | PositionID | PartitionCol | MirrorID | PnLInDollars | CurrentClosingRate | ConversionRate | Meaning |
|---|---|---|---|---|---|---|---|
| 18 | 2152547500 | 0 | 0 | 5,564.44 | 74.3103 | 1 | Manual trade (MirrorID=0) in a USD-denominated account (ConversionRate=1). Significant unrealized profit. |
| 889924 | 2152042400 | 0 | 0 | -36.78 | 2108.99 | 1 | Manual trade with moderate unrealized loss. High closing rate suggests a high-priced instrument (e.g., crypto or index). |
| 16513524 | 2152604600 | 0 | 1851517 | -255.66 | 233.68 | 1 | CopyTrader position (MirrorID=1851517 > 0) — opened automatically when a copied leader traded. Currently at a loss. |
| 9783471 | 2148242400 | 0 | 0 | 4,158.98 | 129.19 | 0.894 | Non-USD account position (ConversionRate=0.894, likely GBP). PnL is converted from instrument currency to account currency. |
| 9783623 | 2148245250 | 0 | 0 | 37,652.92 | 2786.34 | 1.0095 | Non-USD account (ConversionRate=1.0095, likely EUR). Large unrealized profit on a high-priced instrument. |

**Selection criteria**: Mix of manual vs copy-trade, USD vs non-USD accounts, profit vs loss, low vs high closing rates.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID who owns the position. Inherited from Trade.PositionTbl.CID. References Customer.Customer. Clustered index key on PositionTbl. Used by consumers to filter PnL to a specific customer (e.g., Trade.GetMaxAmountToWithdraw joins on PnL.CID = TPOS.CID). |
| 2 | PositionID | bigint | NO | - | VERIFIED | Unique position identifier. Inherited from Trade.PositionTbl.PositionID. Part of the composite PK on PositionTbl (PositionID, PartitionCol). Primary join key for all consumers — every downstream view and procedure joins on PositionID. |
| 3 | PartitionCol | int | NO | - | VERIFIED | Partition alignment column. Inherited from Trade.PositionTbl.PartitionCol (computed as PositionID % 50, PERSISTED). PositionTbl is partitioned on PS_PositionTbl_BIGINT using this column. Consumers MUST include PartitionCol in their JOIN predicates for partition elimination — all major consumers (PositionForExternalUseWithPnL, GetMaxAmountToWithdraw, PositionReopen, GetUnrealizedCustomersData) do this. |
| 4 | MirrorID | int | YES | - | VERIFIED | Copy trading mirror relationship identifier. Inherited from Trade.PositionTbl.MirrorID. 0 or NULL = manual trade (customer-initiated). Positive value = CopyTrader position — references Trade.Mirror which links copier to leader. Used by TDAPI_GetLeaderJoinedCopiers to join PnL by MirrorID for copier profit display. Used by GetUsersUnrealizedEquityDataJunk to aggregate PnL per mirror. |
| 5 | UnrealizedTime | datetime | NO | - | CODE-BACKED | Timestamp of PnL calculation. Computed as GETUTCDATE() — not inherited from any table, generated fresh on every query execution. Represents the exact moment the live rates were fetched. Consumers can use this to verify PnL freshness. |
| 6 | PnLInCents | bigint | YES | - | VERIFIED | Real-time unrealized PnL in minor currency units (cents). Computed by Trade.FnCalculatePnLWrapper → FnCalculateCurrentPnL → FnCalculatePnL as `PnLInDollars × 100`. Exists because downstream systems (trading engine, settlement) operate in minor currency units to avoid floating-point precision issues. Used by Trade.PositionReopen to calculate `@MirrorPnL = SUM(PnL.PnLInCents)` for mirror equity before reopening. Positive = unrealized profit, negative = unrealized loss. |
| 7 | PnLInDollars | money | YES | - | VERIFIED | Real-time unrealized PnL in major currency units (dollars/euros/etc.). This is the primary PnL output column used by most consumers. Computed by FnCalculatePnL using the dual formula (standard or legacy based on PnLVersion/IsSettled), then ROUND'd to 2 decimal places. Used by Trade.GetMaxAmountToWithdraw for withdrawal validation, Trade.GetUnrealizedCustomersData for unrealized equity, Trade.TDAPI_GetLeaderJoinedCopiers for copier PnL display. Positive = unrealized profit, negative = unrealized loss. |
| 8 | CurrentClosingRate | decimal | YES | - | CODE-BACKED | Live closing rate used for PnL calculation. Fetched from Trade.CurrencyPrice by FnGetCurrentClosingRate. The rate at which the position would close right now: Buy positions → Bid (or BidDiscounted for real stocks), Sell positions → Ask (or AskDiscounted for real stocks). The selection matrix depends on IsBuy and IsRealPosition (determined by FnIsRealPosition from IsSettled + InstrumentTypeID). |
| 9 | CurrentClosingRateID | bigint | YES | - | CODE-BACKED | PriceRateID of the closing rate record from Trade.CurrencyPrice. Provides audit trail — the exact price tick used for PnL calculation can be traced back. Used for rate reconciliation and dispute resolution. |
| 10 | ConversionRate | money | YES | - | VERIFIED | Live currency conversion rate from instrument currency to customer's account denomination currency. Fetched from Trade.CurrencyPrice by FnGetCurrentConversionRate via FnGetConversionInstrument. Value = 1.0 when instrument already trades in account currency (most common for USD accounts). Non-1.0 values appear for non-USD accounts (e.g., 0.894 for GBP, 1.0095 for EUR). Selection uses a 9-way CASE matrix based on reciprocal flag, real/CFD, and direction. |
| 11 | ConversionRateID | bigint | YES | - | CODE-BACKED | PriceRateID of the conversion rate record from Trade.CurrencyPrice. Provides audit trail for the conversion rate. When ConversionRate = 1.0 (self-conversion), this still references a valid CurrencyPrice record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TPOS.* | Trade.PositionTbl | FROM (NOLOCK) | Core positions table. Only StatusID=1 (open positions). Provides CID, PositionID, PartitionCol, MirrorID, and 10 parameters for PnL calculation. |
| FCP.* | Trade.FnCalculatePnLWrapper | CROSS APPLY | Unified PnL calculation entry point. Receives 10 position parameters + 4 NULL end rates. Routes to FnCalculateCurrentPnL (live rates) because all end rates are NULL. |
| (indirect) | Trade.FnCalculateCurrentPnL | Function chain | Live PnL pipeline: chains FnGetCurrentConversionRate → FnGetCurrentClosingRate → FnCalculatePnL. |
| (indirect) | Trade.FnGetCurrentConversionRate | Function chain | Resolves live conversion rate via FnGetConversionInstrument (Trade.Instrument) + FnIsRealPosition (Trade.InstrumentMetaData) + Trade.CurrencyPrice. |
| (indirect) | Trade.FnGetCurrentClosingRate | Function chain | Resolves live closing rate via FnIsRealPosition (Trade.InstrumentMetaData) + Trade.CurrencyPrice. |
| (indirect) | Trade.FnCalculatePnL | Function chain | Core PnL formula. Pure calculation, no table access. Dual formula based on PnLVersion/IsSettled. |
| (indirect) | Trade.CurrencyPrice | Table (via functions) | Source of all live bid/ask/discounted prices. Read with NOLOCK by both rate functions. |
| (indirect) | Trade.Instrument | Table (via FnGetConversionInstrument) | Currency pair definitions (SellCurrencyID, BuyCurrencyID) for conversion instrument resolution. |
| (indirect) | Trade.InstrumentMetaData | Table (via FnIsRealPosition) | InstrumentTypeID determines real vs CFD classification (TypeID=10 always CFD). |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used | JOIN Pattern |
|--------|------|----------|-------------|
| Trade.PositionForExternalUseWithPnL | View | INNER JOIN — enriches external position data with PnLInCents, ConversionRate, CurrentClosingRate, CurrentClosingRateID | ON PnL.PositionID = TPOS.PositionID AND PnL.PartitionCol = TPOS.PositionPartitionCol |
| Trade.GetPositionInfo | View | Comma JOIN — provides PnL alongside position, customer, and instrument data for legacy position info endpoint | AND TFPO.PositionID = PnL.PositionID |
| Trade.GetMaxAmountToWithdraw | Stored Procedure | INNER JOIN — reads PnLInDollars for each open position to calculate maximum withdrawal amount (unrealized PnL affects available balance) | ON PnL.PositionID = TPOS.PositionID AND PnL.CID = TPOS.CID AND TPOS.PartitionCol = PnL.PartitionCol |
| Trade.GetUnrealizedCustomersData | Stored Procedure | INNER JOIN — reads PnLInDollars + Commission for customer-level unrealized equity calculation | ON TP.PositionID = PnL.PositionID AND TP.PositionPartitionCol = PnL.PartitionCol |
| Trade.PositionReopen | Stored Procedure | INNER JOIN — SUM(PnL.PnLInCents) for mirror positions to calculate mirror equity before reopening a position | ON Tpos.PositionID = PnL.PositionID AND Tpos.PositionPartitionCol = PnL.PartitionCol AND Tpos.CID = PnL.CID |
| Trade.GetUsersUnrealizedEquityDataJunk | Stored Procedure | INNER JOIN — SUM(PnLInDollars) grouped by CID + MirrorID for unrealized equity per copier | ON PnL.CID = CUST.CID, then PnL.MirrorID = C.MirrorID |
| Trade.TDAPI_GetLeaderJoinedCopiers | Stored Procedure | INNER JOIN — reads PnLInDollars per MirrorID into #MirrorPnL temp table for copier profit display in leader's copier list | ON PnL.MirrorID = tm.MirrorID |
| Trade.TDAPI_GetLeaderJoinedCopiers_After_2025 | Stored Procedure | INNER JOIN — post-2025 variant of copier PnL display | ON PnL.MirrorID = tm.MirrorID |
| Trade.TDAPI_GetLeaderJoinedCopiers_OLD | Stored Procedure | INNER JOIN — legacy copier PnL | ON MirrorID |
| Trade.TDAPI_GetLeaderJoinedCopiers_TestVersion | Stored Procedure | INNER JOIN — test variant | ON MirrorID |
| Trade.TDAPI_GetLeaderJoinedCopiers_MirrorTest | Stored Procedure | INNER JOIN — mirror test variant | ON MirrorID |
| Trade.TDAPI_GetLeaderJoinedCopiersElad | Stored Procedure | INNER JOIN — dev variant | ON MirrorID |
| Trade.TDAPI_GetLeaderJoinedCopiers_Dynamic | Stored Procedure | INNER JOIN — dynamic SQL variant | ON MirrorID |
| Trade.TDAPI_GetLeaderJoinedCopiers_ForDebugB4_2025 | Stored Procedure | INNER JOIN — debug variant | ON MirrorID |

---

## 6. Dependencies

### 6.0 Dependency Chain (Full 5-Level Deep)

```
Trade.PnL (view) ← TARGET
├── Trade.PositionTbl (table)
│     └── (leaf — 100+ columns, partitioned on PositionID%50)
└── Trade.FnCalculatePnLWrapper (function) [NULL rates → live branch]
      ├── Trade.FnCalculateCurrentPnL (function)
      │     ├── Trade.FnGetCurrentConversionRate (function)
      │     │     ├── Trade.CurrencyPrice (table) — live bid/ask/discounted prices
      │     │     ├── Trade.FnGetConversionInstrument (function)
      │     │     │     └── Trade.Instrument (table) — currency pair definitions
      │     │     └── Trade.FnIsRealPosition (function)
      │     │           └── Trade.InstrumentMetaData (table) — InstrumentTypeID
      │     ├── Trade.FnGetCurrentClosingRate (function)
      │     │     ├── Trade.CurrencyPrice (table) — same as above
      │     │     └── Trade.FnIsRealPosition (function) — same as above
      │     └── Trade.FnCalculatePnL (function) — pure formula, no table access
      └── Trade.FnCalculatePnLByRates (function) [NOT used by this view — end rates are NULL]
            ├── Trade.FnGetCurrentConversionRate (conditional)
            ├── Trade.FnGetCurrentClosingRate (conditional)
            └── Trade.FnCalculatePnL
```

### 6.1 Objects This Depends On

| Object | Type | How Used | Documentation |
|--------|------|----------|---------------|
| Trade.PositionTbl | Table | FROM — all open positions (StatusID=1). Provides 10 parameters for PnL calculation + 4 output columns (CID, PositionID, PartitionCol, MirrorID). | [Trade.PositionTbl](../Tables/Trade.PositionTbl.md) |
| Trade.FnCalculatePnLWrapper | Function | CROSS APPLY — unified PnL entry point. Routes to live branch because all end rates are NULL. | [Trade.FnCalculatePnLWrapper](../Functions/Trade.FnCalculatePnLWrapper.md) |
| Trade.FnCalculateCurrentPnL | Function | Called by wrapper — chains conversion rate + closing rate + PnL formula. | [Trade.FnCalculateCurrentPnL](../Functions/Trade.FnCalculateCurrentPnL.md) |
| Trade.FnGetCurrentConversionRate | Function | Called by FnCalculateCurrentPnL — resolves live conversion rate. | [Trade.FnGetCurrentConversionRate](../Functions/Trade.FnGetCurrentConversionRate.md) |
| Trade.FnGetCurrentClosingRate | Function | Called by FnCalculateCurrentPnL — resolves live closing rate. | [Trade.FnGetCurrentClosingRate](../Functions/Trade.FnGetCurrentClosingRate.md) |
| Trade.FnCalculatePnL | Function | Called by FnCalculateCurrentPnL — core PnL formula (dual version). | [Trade.FnCalculatePnL](../Functions/Trade.FnCalculatePnL.md) |
| Trade.FnGetConversionInstrument | Function | Called by FnGetCurrentConversionRate — resolves conversion instrument from Trade.Instrument. | [Trade.FnGetConversionInstrument](../Functions/Trade.FnGetConversionInstrument.md) |
| Trade.FnIsRealPosition | Function | Called by FnGetCurrentConversionRate and FnGetCurrentClosingRate — determines real vs CFD from Trade.InstrumentMetaData. | [Trade.FnIsRealPosition](../Functions/Trade.FnIsRealPosition.md) |
| Trade.CurrencyPrice | Table | Read by FnGetCurrentConversionRate and FnGetCurrentClosingRate — live bid/ask/discounted prices. | [Trade.CurrencyPrice](../Tables/Trade.CurrencyPrice.md) |
| Trade.Instrument | Table | Read by FnGetConversionInstrument — currency pair definitions for conversion. | [Trade.Instrument](../Tables/Trade.Instrument.md) |
| Trade.InstrumentMetaData | Table | Read by FnIsRealPosition — InstrumentTypeID for real/CFD classification. | [Trade.InstrumentMetaData](../Tables/Trade.InstrumentMetaData.md) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionForExternalUseWithPnL | View | INNER JOIN for enriched position data |
| Trade.GetPositionInfo | View | JOIN for legacy position info endpoint |
| Trade.GetMaxAmountToWithdraw | Procedure | PnL for withdrawal validation |
| Trade.GetUnrealizedCustomersData | Procedure | Customer-level unrealized equity |
| Trade.PositionReopen | Procedure | Mirror PnL for reopen calculations |
| Trade.GetUsersUnrealizedEquityDataJunk | Procedure | Unrealized equity per copier |
| Trade.TDAPI_GetLeaderJoinedCopiers (+7 variants) | Procedures | Copier PnL display in leader's copier list |

---

## 7. Technical Details

### 7.1 Performance Considerations

- **Live rate fetching per row**: Every query triggers CROSS APPLY to FnCalculatePnLWrapper for each matching position. The function chain reads Trade.CurrencyPrice twice per row (once for closing rate, once for conversion rate). For customer-scoped queries this is efficient; for full-table scans this is expensive.
- **NOLOCK on PositionTbl**: Applied to avoid locking contention with the high-frequency position open/close operations that constantly INSERT/UPDATE/DELETE PositionTbl.
- **NOLOCK propagation**: All functions in the chain also use NOLOCK on Trade.CurrencyPrice and Trade.InstrumentMetaData/Instrument reads.
- **No WHERE optimization beyond StatusID=1**: The view's only filter is StatusID=1. Consumers MUST add CID, PositionID, or MirrorID filters to avoid scanning all open positions.
- **Partition-aligned joins critical**: Consumers joining back to PositionTbl must include PartitionCol to enable partition elimination across 50 partitions.
- **No SCHEMABINDING**: View is not schema-bound, cannot be indexed.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| StatusID = 1 | WHERE filter | Only open positions included (not pending, closed, or cancelled) |
| NOLOCK | Table hint | Non-blocking reads on PositionTbl |
| CROSS APPLY | Join type | Per-row function evaluation — no rows returned if function returns empty (impossible for valid positions) |

---

## 8. Sample Queries

### 8.1 Get live PnL for a specific customer

```sql
SELECT  PositionID,
        PnLInDollars,
        PnLInCents,
        CurrentClosingRate,
        ConversionRate,
        UnrealizedTime
FROM    Trade.PnL WITH (NOLOCK)
WHERE   CID = 12345;
```

### 8.2 Total unrealized PnL across all open positions for a customer

```sql
SELECT  CID,
        SUM(PnLInDollars) AS TotalUnrealizedPnL,
        COUNT(*)           AS OpenPositionCount,
        MIN(UnrealizedTime) AS CalculatedAt
FROM    Trade.PnL WITH (NOLOCK)
WHERE   CID = 12345
GROUP BY CID;
```

### 8.3 Copier PnL aggregation by mirror (CopyTrader use case)

```sql
SELECT  MirrorID,
        SUM(PnLInDollars) AS MirrorPnL,
        COUNT(*)           AS MirrorPositions
FROM    Trade.PnL WITH (NOLOCK)
WHERE   MirrorID > 0
        AND CID = 12345
GROUP BY MirrorID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | ID | Key Findings | Validation |
|--------|------|-----|-------------|-----------|
| Trade.PnL | Confluence page | 13795688455 | Confirms: view calculates real-time PnL for open positions using FnCalculatePnLWrapper with NULL end rates. Lists all 11 columns with types. Documents the dependency chain (Wrapper → CurrentPnL → GetCurrentClosingRate → GetCurrentConversionRate). Notes usage in PositionReopen, manual close, fee calculations, risk assessments. Includes Mermaid data flow diagram. | HIGH — fully aligns with code. All claims verified against SSDT DDL and function chain analysis. |
| Trade.Position | Confluence page | 13794967614 | Cross-reference to position data. Linked from Trade.PnL page as related documentation. | MEDIUM — contextual reference only. |
| Supporting Services — Multi-Currency Changes | Confluence page | 14039679011 | Documents multi-currency conversion architecture. Relevant to ConversionRate column and FnGetCurrentConversionRate logic. | MEDIUM — architecture context for conversion rate path. |
| DWH View Fact_CustomerUnrealized_PnL | Confluence page | 12942934066 | DWH consumption of Trade.PnL data for customer unrealized PnL fact table. Confirms Trade.PnL is the upstream source. | MEDIUM — downstream consumer documentation. |

Jira search returned 410 Gone (API unavailable during this scan).

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.6/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7 (1+2+5+7+8+10+11)*
*Sources: Atlassian: 4 Confluence + 0 Jira | Procedures: 14 referencing | Dependencies: 11 documented (all fresh) | Corrections: 0 applied*
*Object: Trade.PnL | Type: View | Source: etoro/etoro/Trade/Views/Trade.PnL.sql*
