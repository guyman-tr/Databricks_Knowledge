# BI_DB_Compliance_Surveillance_ShortTermTrades

## 1. Purpose
Compliance Daily Market Surveillance: Short Term Trades Report. Identifies all valid customers who made round-trip trades in **Stocks or ETFs** where the position was **opened and closed within 300 minutes (5 hours)** on the last working day. Each row is one closed position meeting this criterion. Compliance uses this to detect patterns such as rapid in-and-out trading, wash-trade-like behavior, or clients exploiting short-term price movements in a manner inconsistent with their declared investment profile. Includes lifetime PnL context in the same instrument and last known login IP for investigative use.

## 2. Grain & Size
| Property | Value |
|----------|-------|
| **Grain** | One row per position (`PositionID`) — closed on last working day, duration ≤ 300 minutes |
| **Row Count** | ~61,282 (as of 2026-04-13, reflecting last working day 2026-04-10) |
| **Unique CIDs** | ~15,772 |
| **Refresh** | Daily, full refresh (TRUNCATE + INSERT) via `SP_D_Compliance_Surveillance_ShortTermTrades` |
| **Last UpdateDate** | 2026-04-13 |

## 3. Key Business Rules
- **Instrument scope**: Stocks and ETFs only (`InstrumentTypeID IN (5, 6)`)
- **Close date**: Positions with `CloseDateID = last working day` (Monday → Friday; all other days → yesterday)
- **Duration threshold**: Round-trip duration must be `≤ 300 minutes` (open to close)
- **Minimum trades gate**: Client must have `≥ 1` position meeting criteria in the same instrument on that day (parameter `@min_num_trades = 1`, changed from 5 on 2024-06-13)
- **Customer filter**: `IsValidCustomer = 1` only
- **Regulation source**: Uses `DesignatedRegulationID` (secondary/override regulation), NOT primary RegulationID. eToro employees show `'Internal'` (Region='eToro')
- **Blank strings not NULLs**: `ClientVerificationLevel3Date`, `ParentVerificationLevel3Date`, and `ParentCID` use empty string `''` instead of NULL when not applicable

## 4. Regulation Distribution
| Regulation | Rows | % |
|------------|------|---|
| CySEC | 37,506 | 61.2% |
| FCA | 14,015 | 22.9% |
| FSA Seychelles | 4,261 | 7.0% |
| FSRA | 3,365 | 5.5% |
| ASIC & GAML | 2,041 | 3.3% |
| Other (FinCEN+FINRA, MAS) | 94 | 0.2% |

## 5. Column Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | InstrumentDisplayName | varchar(100) | YES | Human-readable instrument label (e.g., "CoreWeave Inc"). Used in UI and reports. (Tier 1 — DWH_dbo.Dim_Instrument.InstrumentDisplayName) |
| 2 | Instrument | varchar(50) | YES | Instrument ticker/code as displayed on eToro platform (e.g., "CRWV/USD"). (Tier 1 — DWH_dbo.Dim_Instrument.Name) |
| 3 | InstrumentID | int | YES | Numeric instrument identifier. FK to DWH_dbo.Dim_Instrument. (Tier 1 — DWH_dbo.Dim_Instrument.InstrumentID) |
| 4 | InstrumentType | varchar(50) | YES | Instrument category name. In this table always "Stocks" or ETF type — filtered to InstrumentTypeID IN (5, 6). (Tier 1 — DWH_dbo.Dim_Instrument.InstrumentType) |
| 5 | ISINCode | varchar(30) | YES | International Securities Identification Number. 12-character alphanumeric. NULL if instrument has no ISIN. (Tier 1 — DWH_dbo.Dim_Instrument.ISINCode) |
| 6 | CUSIP | varchar(500) | YES | 9-character CUSIP identifier (North American securities). Empty string `''` if not assigned (ISNULL→''). (Tier 1 — DWH_dbo.Dim_Instrument.CUSIP via ISNULL) |
| 7 | PositionID | bigint | YES | Unique position key. 1:1 row grain for this table. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position) |
| 8 | IsReal | int | YES | 1 = real underlying asset (stock settlement), 0 = CFD. From `Dim_Position.IsSettled`. Stocks can be traded as real or CFD on eToro. (Tier 1 — DWH_dbo.Dim_Position.IsSettled) |
| 9 | IsBuy | varchar(30) | YES | Trade direction: 'TRUE' = long (buy), 'FALSE' = short (sell). Derived from Dim_Position.IsBuy (int) converted to string. (Tier 1 — DWH_dbo.Dim_Position.IsBuy via CASE) |
| 10 | CID | int | YES | Customer ID — platform-internal primary key. HASH distribution key. (Tier 1 — Customer.CustomerStatic via DWH_dbo.Dim_Customer.RealCID) |
| 11 | Regulation | varchar(50) | YES | Regulatory entity from `DesignatedRegulationID` (secondary/override regulation). 'Internal' for eToro employee accounts (Region='eToro'). (Tier 1 — DWH_dbo.Dim_Regulation.Name via Dim_Customer.DesignatedRegulationID) |
| 12 | ClientVerificationLevel3Date | varchar(50) | YES | Date client reached KYC verification level 3 (fully verified). From BI_DB_CIDFirstDates. Stored as varchar(50) format YYYY-MM-DD HH:MM:SS. Empty string `''` if date = 1900-01-01 or record missing. (Tier 2 — BI_DB_dbo.BI_DB_CIDFirstDates.VerificationLevel3Date) |
| 13 | IsCopy | int | YES | Trade type: 0 = self-directed (MirrorID = 0), 1 = copy trade (MirrorID > 0). 64.4% copy, 35.6% self-directed in current data. (Tier 1 — DWH_dbo.Dim_Position.MirrorID via CASE) |
| 14 | ParentCID | int | YES | CID of the Popular Investor being copied, resolved from Dim_Mirror.ParentCID via Dim_Position.MirrorID. Empty string `''` (via ISNULL) for non-copy positions. (Tier 1 — DWH_dbo.Dim_Mirror.ParentCID) |
| 15 | ParentVerificationLevel3Date | varchar(50) | YES | KYC Level 3 verification date of the Popular Investor being copied. Sourced from BI_DB_CIDFirstDates for the ParentCID. Empty string `''` if not applicable or missing. (Tier 2 — BI_DB_dbo.BI_DB_CIDFirstDates.VerificationLevel3Date for ParentCID) |
| 16 | OpenOccurred | varchar(50) | YES | Position open timestamp as varchar(50) using CONVERT(varchar, OpenOccurred, 120). (Tier 1 — DWH_dbo.Dim_Position.OpenOccurred) |
| 17 | CloseOccurred | varchar(50) | YES | Position close timestamp as varchar(50). The difference `CloseOccurred - OpenOccurred` in minutes = RoundTripDurationMins. (Tier 1 — DWH_dbo.Dim_Position.CloseOccurred) |
| 18 | Leverage | int | YES | Leverage multiplier applied to the position (e.g., 1 = no leverage, 5 = 5x, 10 = 10x). (Tier 1 — DWH_dbo.Dim_Position.Leverage) |
| 19 | UnleveragedTradeSize | money | YES | Actual capital invested in the position before leverage, in USD. Corresponds to Dim_Position.Amount — the raw position size. (Tier 1 — DWH_dbo.Dim_Position.Amount) |
| 20 | FullNotionalTradeSize | money | YES | Total notional exposure = `UnleveragedTradeSize × Leverage`. Represents the full market exposure of the position. SP-computed: `dp.Amount * dp.Leverage`. (Tier 2 — SP_D_Compliance_Surveillance_ShortTermTrades) |
| 21 | RealisedNetProfit | money | YES | Realized PnL for this specific position (set on close). From Dim_Position.NetProfit. Negative = loss. (Tier 1 — DWH_dbo.Dim_Position.NetProfit) |
| 22 | InitForexRate | decimal(16,8) | YES | Opening price/exchange rate at position open. (Tier 1 — DWH_dbo.Dim_Position.InitForexRate) |
| 23 | EndForexRate | decimal(16,8) | YES | Closing price/exchange rate at position close. The delta EndForexRate − InitForexRate drives RealisedNetProfit. (Tier 1 — DWH_dbo.Dim_Position.EndForexRate) |
| 24 | Units_Closed | decimal(16,6) | YES | Position size in instrument units/shares at close. From Dim_Position.AmountInUnitsDecimal. (Tier 1 — DWH_dbo.Dim_Position.AmountInUnitsDecimal) |
| 25 | IsPartialCloseChild | int | YES | 1 = this position is a partial-close child (spawned when a position was partially closed). 0 = full position. (Tier 1 — DWH_dbo.Dim_Position.IsPartialCloseChild) |
| 26 | CountryOfResidence | varchar(50) | YES | Customer country of residence name resolved from Dim_Country via Dim_Customer.CountryID. (Tier 1 — DWH_dbo.Dim_Country.Name via DWH_dbo.Dim_Customer.CountryID) |
| 27 | Postcode | nvarchar(50) | YES | Customer postal code from Dim_Customer.Zip. PII field. May contain "99999" or "00000" as placeholder/unknown values (observed in samples). (Tier 1 — Customer.CustomerStatic via DWH_dbo.Dim_Customer.Zip) |
| 28 | LastName | nvarchar(50) | YES | Customer last name. PII field. (Tier 1 — Customer.CustomerStatic via DWH_dbo.Dim_Customer.LastName) |
| 29 | LastIPAddress | varchar(15) | YES | Most recent login IP address (ActionTypeID=14) from Fact_CustomerAction within last 365 days, converted from integer storage to dotted-quad format via `DWH_dbo.IPNumToIPAddress()`. NULL if no login found in window. (Tier 2 — DWH_dbo.Fact_CustomerAction, ActionTypeID=14, DWH_dbo.IPNumToIPAddress()) |
| 30 | RoundTripDurationMins | decimal(16,6) | YES | Duration from position open to close in minutes: `DATEDIFF(MINUTE, OpenOccurred, CloseOccurred)`. Maximum value = 300 (hard cap from SP filter). 0.000000 for positions opened and closed within the same minute. (Tier 2 — SP_D_Compliance_Surveillance_ShortTermTrades) |
| 31 | PositionsMeetingCriteria | int | YES | Count of distinct positions meeting the short-term criteria for this CID + InstrumentID combination on this day. Always ≥ 1. Higher values indicate more repeated short-term trades. (Tier 2 — SP_D_Compliance_Surveillance_ShortTermTrades, COUNT DISTINCT PositionID per CID+InstrumentID) |
| 32 | Lifetime_RealisedPnL | money | YES | Lifetime realized PnL for this customer in this specific instrument. Self-directed trades: SUM(NetProfit WHERE MirrorID=0); Copy trades: SUM(NetProfit WHERE MirrorID≠0) per CID+ParentCID+InstrumentID. `COALESCE(manual_pnl, copy_pnl)` — only one is non-NULL per row based on IsCopy. (Tier 2 — SP_D_Compliance_Surveillance_ShortTermTrades, DWH_dbo.Dim_Position.NetProfit lifetime aggregation) |
| 33 | UpdateDate | varchar(50) | YES | ETL metadata: SP execution timestamp (GETDATE()) stored as varchar(50). (Tier 3 — ETL metadata, SP_D_Compliance_Surveillance_ShortTermTrades) |

## 6. ETL Summary

```
DWH_dbo.Dim_Position (closed yesterday, Stocks/ETFs, ≤300 min round trip)
    + DWH_dbo.Dim_Instrument, Dim_Customer, Dim_Country, Dim_Regulation (DesignatedRegulationID)
    + DWH_dbo.Dim_Mirror (ParentCID for copy trades)
    + BI_DB_dbo.BI_DB_CIDFirstDates (L3 dates for client + parent)
    + DWH_dbo.Fact_CustomerAction (last login IP, last 365d)
    + DWH_dbo.Dim_Position (lifetime PnL per CID+Instrument, manual+copy)
        ↓  TRUNCATE + INSERT (full daily refresh)
BI_DB_Compliance_Surveillance_ShortTermTrades
```

- **OpsDB**: Priority 0, `SP_D_Compliance_Surveillance_ShortTermTrades`, daily

## 7. Usage Notes
- **Rolling daily window**: Table always reflects only the **last working day's** qualifying positions. No historical accumulation — older data is replaced on each run. For trend analysis, downstream aggregation into a separate history table would be needed.
- **Empty string sentinel**: `ClientVerificationLevel3Date`, `ParentVerificationLevel3Date`, and `ParentCID` use `''` instead of NULL. Use `WHERE col <> ''` or `LEN(col) > 0` rather than `IS NOT NULL`.
- **Regulation uses DesignatedRegulationID**: Unlike most BI_DB tables that use the primary RegulationID, this table uses the secondary/designated regulation. For clients with both, this reflects the override regulation.
- **Copy trade context**: Compliance can cross-reference `ParentCID` with `ParentVerificationLevel3Date` to assess whether a popular investor generating copy trades is KYC-verified, which may be relevant for front-running or market abuse investigations.
- **Lifetime_RealisedPnL scope**: Covers all-time historical positions in that instrument — not just the current day. Useful for identifying systematic profitability or losses in the specific instrument flagged.
- **PositionsMeetingCriteria**: With `@min_num_trades = 1`, all qualifying positions are included. Value > 1 indicates the client made multiple short-term trades in the same instrument that day.
- **Date fields as varchar**: OpenOccurred, CloseOccurred, UpdateDate, ClientVerificationLevel3Date are varchar — cast to DATETIME before date arithmetic.

## 8. Tier Breakdown
| Tier | Column Count | Source |
|------|-------------|--------|
| Tier 1 | 21 | Dim_Instrument (5), Dim_Position (10: PositionID, IsReal, IsBuy, Leverage, UnleveragedTradeSize, RealisedNetProfit, InitForexRate, EndForexRate, Units_Closed, IsPartialCloseChild), Dim_Customer (CID, LastName, Postcode), Dim_Country (CountryOfResidence), Dim_Regulation (Regulation), Dim_Mirror (ParentCID) |
| Tier 2 | 11 | BI_DB_CIDFirstDates (ClientVerificationLevel3Date, ParentVerificationLevel3Date), Fact_CustomerAction+IPNumToIPAddress (LastIPAddress), SP-computed (FullNotionalTradeSize, RoundTripDurationMins, PositionsMeetingCriteria, Lifetime_RealisedPnL, IsCopy, OpenOccurred/CloseOccurred as varchar) |
| Tier 3 | 1 | UpdateDate (ETL metadata) |
