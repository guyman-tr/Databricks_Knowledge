# BI_DB_Compliance_Surveillance_Snapshot

## 1. Purpose
Compliance Daily Market Surveillance: Snapshot Report. Captures all positions that were **open at the end of the last working day** (the snapshot moment) for a specific set of instruments designated by Compliance each morning. The instrument list is supplied daily by Compliance via a Google Sheets document synced through Fivetran. Unlike the ShortTermTrades report (which looks at positions closed yesterday), this report shows **open positions at a point in time** — providing Compliance with a real-time picture of client exposure in flagged instruments. Two unrealized PnL columns allow comparison of position value at the snapshot moment versus the current day's valuation.

## 2. Grain & Size
| Property | Value |
|----------|-------|
| **Grain** | One row per open position (`PositionID`) at snapshot moment |
| **Row Count** | ~53,215 (as of 2026-04-12, reflecting snapshot 2026-04-10) |
| **Unique CIDs** | ~21,011 |
| **Unique Instruments** | ~98 (changes daily per Compliance instrument list) |
| **Refresh** | Daily, full refresh (TRUNCATE + INSERT) via `SP_D_Compliance_Surveillance_Snapshot` |
| **Last UpdateDate** | 2026-04-12 |

## 3. Key Business Rules
- **Instrument scope**: Dynamic daily list from Fivetran-synced Google Sheets (`External_Fivetran_compliance_snapshot_report_instrumentids`). Only positions in listed instruments are included. 98 instruments in current snapshot.
- **Open at snapshot**: Position must satisfy `OpenOccurred ≤ @snapshot` AND `(CloseOccurred > @snapshot OR CloseDateID = 0)` — i.e., was open at end of last working day.
- **Lookback window**: Position must have been opened within `@lookbackdays` days before snapshot (default 13 days, Compliance-configurable). Positions opened more than 13 days ago are excluded.
- **Snapshot time**: End of last working day (23:59:59). Monday/Tuesday runs snap to Friday 23:59:59; all other days snap to yesterday 23:59:59.
- **Customer validity**: Non-eToro customers require `IsValidCustomer = 1`. eToro employees (Region='eToro') are included even with `IsValidCustomer = 0` — this inclusion was added 2024-05-10 for UK Compliance.
- **Regulation source**: Uses `DesignatedRegulationID` (secondary/override), not primary RegulationID. eToro employees show 'Internal'.
- **CloseOccurred sentinel**: Open positions show '1900-01-01 00:00:00' as CloseOccurred (from CloseDateID=0 in Dim_Position).
- **Blank string sentinels**: `ClientVerificationLevel3Date`, `ParentVerificationLevel3Date`, and `ParentCID` use empty string `''` when not applicable.

## 4. Regulation Distribution
| Regulation | Rows | % |
|------------|------|---|
| CySEC | 34,850 | 65.5% |
| FCA | 11,211 | 21.1% |
| FSA Seychelles | 2,953 | 5.5% |
| ASIC & GAML | 2,754 | 5.2% |
| FSRA | 1,342 | 2.5% |
| Other (Internal, FinCEN+FINRA, ASIC, MAS) | 105 | 0.2% |

## 5. Column Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | InstrumentDisplayName | varchar(100) | YES | Human-readable instrument label (e.g., "China Railway Group"). (Tier 1 — DWH_dbo.Dim_Instrument.InstrumentDisplayName) |
| 2 | Instrument | varchar(50) | YES | Instrument ticker/code as displayed on eToro platform (e.g., "0390.HK/HKD", "FDP/USD"). (Tier 1 — DWH_dbo.Dim_Instrument.Name) |
| 3 | InstrumentID | int | YES | Numeric instrument identifier. FK to DWH_dbo.Dim_Instrument. Subset of the daily Fivetran instrument list. (Tier 1 — DWH_dbo.Dim_Instrument.InstrumentID) |
| 4 | InstrumentType | varchar(50) | YES | Instrument category name. Typically "Stocks" in this surveillance context. (Tier 2 — DWH_dbo.Dim_Instrument.InstrumentType) |
| 5 | ISINCode | varchar(30) | YES | International Securities Identification Number. NULL for instruments without ISIN assignment. (Tier 1 — DWH_dbo.Dim_Instrument.ISINCode) |
| 6 | CUSIP | varchar(500) | YES | 9-character CUSIP identifier. Empty string `''` when not assigned (ISNULL→''). Common for non-US instruments (e.g., HK-listed stocks have empty CUSIP). (Tier 1 — DWH_dbo.Dim_Instrument.CUSIP via ISNULL) |
| 7 | PositionID | bigint | YES | Unique position key. 1:1 row grain for this table — each row is one open position. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position) |
| 8 | IsReal | int | YES | 1 = real underlying asset (stock settlement), 0 = CFD. From Dim_Position.IsSettled. (Tier 1 — DWH_dbo.Dim_Position.IsSettled) |
| 9 | IsBuy | varchar(30) | YES | Trade direction: 'TRUE' = long (buy), 'FALSE' = short (sell). Derived from Dim_Position.IsBuy (int) via CASE. (Tier 1 — DWH_dbo.Dim_Position.IsBuy via CASE) |
| 10 | CID | int | YES | Customer ID — platform-internal primary key. HASH distribution key. (Tier 1 — Customer.CustomerStatic via DWH_dbo.Dim_Customer.RealCID) |
| 11 | Regulation | varchar(50) | YES | Regulatory entity from `DesignatedRegulationID`. 'Internal' for eToro employees (Region='eToro'). CySEC=65.5%, FCA=21.1% in current snapshot. (Tier 1 — DWH_dbo.Dim_Regulation.Name via Dim_Customer.DesignatedRegulationID) |
| 12 | ClientVerificationLevel3Date | varchar(50) | YES | Date client reached KYC verification level 3. From BI_DB_CIDFirstDates.VerificationLevel3Date. Stored as varchar(50) in YYYY-MM-DD HH:MM:SS format. Empty string `''` if date = 1900-01-01 or record missing. (Tier 2 — BI_DB_dbo.BI_DB_CIDFirstDates.VerificationLevel3Date) |
| 13 | IsCopy | int | YES | Trade type: 0 = self-directed (MirrorID = 0), 1 = copy trade (MirrorID > 0). 88.9% copy, 11.1% self-directed in current snapshot. (Tier 1 — DWH_dbo.Dim_Position.MirrorID via CASE) |
| 14 | ParentCID | int | YES | CID of the Popular Investor being copied. Resolved from Dim_Mirror.ParentCID. Empty string `''` (ISNULL→'') for non-copy positions. (Tier 1 — DWH_dbo.Dim_Mirror.ParentCID) |
| 15 | ParentVerificationLevel3Date | varchar(50) | YES | KYC Level 3 verification date of the Popular Investor being copied. Sourced from BI_DB_CIDFirstDates for ParentCID. Empty string `''` when not applicable. (Tier 2 — BI_DB_dbo.BI_DB_CIDFirstDates.VerificationLevel3Date for ParentCID) |
| 16 | OpenOccurred | varchar(50) | YES | Position open timestamp stored as varchar(50) using CONVERT(varchar, OpenOccurred, 120). All rows have OpenOccurred ≤ @snapshot. (Tier 1 — DWH_dbo.Dim_Position.OpenOccurred) |
| 17 | CloseOccurred | varchar(50) | YES | Position close timestamp as varchar(50). '1900-01-01 00:00:00' sentinel for open/unclosed positions (CloseDateID = 0 in Dim_Position). Closed positions in the lookback window may appear here if they closed after the snapshot moment. (Tier 1 — DWH_dbo.Dim_Position.CloseOccurred) |
| 18 | Leverage | int | YES | Leverage multiplier (e.g., 1 = fully funded, 5 = 5×). (Tier 1 — DWH_dbo.Dim_Position.Leverage) |
| 19 | UnleveragedTradeSize | money | YES | Capital invested in the position before leverage, in USD. Corresponds to Dim_Position.Amount. (Tier 1 — DWH_dbo.Dim_Position.Amount) |
| 20 | FullNotionalTradeSize | money | YES | Total notional exposure = `UnleveragedTradeSize × Leverage`. SP-computed: `dp.Amount * dp.Leverage`. (Tier 2 — SP_D_Compliance_Surveillance_Snapshot) |
| 21 | RealisedNetProfit | money | YES | Realized PnL for the position. 0.0000 for positions that are still open (NetProfit set on close only). (Tier 1 — DWH_dbo.Dim_Position.NetProfit) |
| 22 | UnrealisedPositionPnL_Snapshot | decimal(16,4) | YES | Unrealized PnL of the position at the snapshot moment (last working day end). From BI_DB_PositionPnL WHERE DateID = @snapshotid. 0 if no PnL record found for that date. (Tier 2 — BI_DB_dbo.BI_DB_PositionPnL.PositionPnL, DateID=@snapshotid) |
| 23 | UnrealisedPositionPnL_ReportDate | decimal(16,4) | YES | Unrealized PnL of the position as of yesterday (report run date − 1). From BI_DB_PositionPnL WHERE DateID = @yesterdayid. Allows Compliance to see how the position's value changed from snapshot to today. 0 if no PnL record for that date. (Tier 2 — BI_DB_dbo.BI_DB_PositionPnL.PositionPnL, DateID=@yesterdayid) |
| 24 | CountryOfResidence | varchar(50) | YES | Customer country of residence name from Dim_Country. (Tier 1 — DWH_dbo.Dim_Country.Name via DWH_dbo.Dim_Customer.CountryID) |
| 25 | Postcode | nvarchar(50) | YES | Customer postal code from Dim_Customer.Zip. PII field. Placeholder values "99999"/"00000"/"85010" observed. (Tier 1 — Customer.CustomerStatic via DWH_dbo.Dim_Customer.Zip) |
| 26 | LastName | nvarchar(50) | YES | Customer last name. PII field. (Tier 1 — Customer.CustomerStatic via DWH_dbo.Dim_Customer.LastName) |
| 27 | LastIPAddress | varchar(15) | YES | Most recent login IP address (ActionTypeID=14) from Fact_CustomerAction within last 365 days, converted from integer to dotted-quad format via `DWH_dbo.IPNumToIPAddress()`. NULL if no login found in window. (Tier 2 — DWH_dbo.Fact_CustomerAction, ActionTypeID=14, DWH_dbo.IPNumToIPAddress()) |
| 28 | UpdateDate | varchar(50) | YES | ETL metadata: SP execution timestamp (GETDATE()) stored as varchar(50). (Tier 3 — ETL metadata, SP_D_Compliance_Surveillance_Snapshot) |

## 6. ETL Summary

```
External_Fivetran_compliance_snapshot_report_instrumentids (daily instrument list + @lookbackdays)
    + DWH_dbo.Dim_Position (open at snapshot, lookback window)
    + DWH_dbo.Dim_Instrument, Dim_Customer, Dim_Country, Dim_Regulation (DesignatedRegulationID)
    + DWH_dbo.Dim_Mirror (ParentCID for copy trades)
    + BI_DB_dbo.BI_DB_CIDFirstDates (L3 dates for client + parent)
    + BI_DB_dbo.BI_DB_PositionPnL (×2: snapshot DateID + yesterday DateID)
    + DWH_dbo.Fact_CustomerAction (last login IP, last 365d)
        ↓  TRUNCATE + INSERT (full daily refresh)
BI_DB_Compliance_Surveillance_Snapshot
```

- **OpsDB**: Priority 0, `SP_D_Compliance_Surveillance_Snapshot`, daily

## 7. Usage Notes
- **Dynamic instrument list**: The 98 instruments in today's snapshot differ from yesterday's. Cross-day comparison requires joining on a common instrument set or using the PositionID to track the same position across runs.
- **Dual PnL columns**: `UnrealisedPositionPnL_Snapshot` = position value at end of last trading day; `UnrealisedPositionPnL_ReportDate` = position value as of yesterday (report day). When run the same day as the snapshot, these will be equal. Divergence indicates price movement between the snapshot and report dates.
- **Open position sentinel**: `CloseOccurred = '1900-01-01 00:00:00'` means the position was still open at snapshot time. Use `WHERE CloseOccurred = '1900-01-01 00:00:00'` (not IS NULL) to filter open positions.
- **Regulation vs. ShortTermTrades**: Both surveillance tables use DesignatedRegulationID. "Internal" rows = eToro employees, included specifically to support UK Compliance monitoring of employee accounts.
- **RealisedNetProfit = 0**: Nearly all rows will have 0 here since the position was open at snapshot. Closed positions in the lookback window that closed after the snapshot moment are also included; these may have non-zero NetProfit.
- **Empty string sentinels**: `ClientVerificationLevel3Date`, `ParentVerificationLevel3Date`, `ParentCID` use `''` not NULL. Use `WHERE col <> ''` for non-null checks.
- **Lookback configurability**: Compliance can adjust the lookback window by placing a value < 100 as the minimum entry in the Fivetran instrument sheet. Default is 13 days.

## 8. Tier Breakdown
| Tier | Column Count | Source |
|------|-------------|--------|
| Tier 1 | 18 | Dim_Instrument (6), Dim_Position (8: PositionID, IsReal, IsBuy, Leverage, UnleveragedTradeSize, RealisedNetProfit, OpenOccurred, CloseOccurred), Dim_Customer (CID, LastName, Postcode), Dim_Country (CountryOfResidence), Dim_Regulation (Regulation), Dim_Mirror (ParentCID) |
| Tier 2 | 9 | BI_DB_CIDFirstDates (ClientVerificationLevel3Date, ParentVerificationLevel3Date), BI_DB_PositionPnL×2 (UnrealisedPositionPnL_Snapshot, UnrealisedPositionPnL_ReportDate), Fact_CustomerAction+IP (LastIPAddress), SP-computed (FullNotionalTradeSize, IsCopy), Fivetran external table (instrument filter + @lookbackdays) |
| Tier 3 | 1 | UpdateDate (ETL metadata) |
