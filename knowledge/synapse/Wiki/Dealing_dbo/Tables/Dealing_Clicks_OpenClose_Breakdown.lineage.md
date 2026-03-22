# Column Lineage: Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `DWH_dbo.Dim_Position` (Synapse DWH) |
| **ETL SP** | `SP_Clicks_OpenClose_Breakdown` |
| **Secondary Sources** | `DWH_dbo.Dim_Instrument`, `DWH_dbo.Fact_SnapshotCustomer`, `DWH_dbo.Dim_Customer`, `DWH_dbo.Dim_Country`, `DWH_dbo.Dim_Regulation`, `DWH_dbo.Dim_PlayerLevel`, `DWH_dbo.Fact_CustomerAction`, `eMoney_dbo.eMoney_Dim_Account`, `BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN`, `BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
DWH_dbo.Dim_Position ─────────────┐
DWH_dbo.Dim_Instrument ───────────┤
DWH_dbo.Fact_SnapshotCustomer ────┤
DWH_dbo.Dim_Customer ─────────────┤
DWH_dbo.Dim_Country ──────────────┼──► SP_Clicks_OpenClose_Breakdown ──► Dealing_Clicks_OpenClose_Breakdown
DWH_dbo.Dim_Regulation ───────────┤
DWH_dbo.Dim_PlayerLevel ──────────┤
DWH_dbo.Fact_CustomerAction ──────┤
eMoney_dbo.eMoney_Dim_Account ────┤
BI_DB_dbo.BI_DB_Positions_*_IBAN ─┘
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **join-enriched** | Joined from a secondary source table during ETL. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | — | — | ETL-computed | `@Date` SP parameter (yesterday) | Report date |
| DateID | — | — | ETL-computed | `CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT)` | YYYYMMDD int |
| SellCurrency | DWH_dbo.Dim_Instrument | SellCurrency | passthrough | Direct: Dim_Instrument.SellCurrency | Denomination currency |
| Club | DWH_dbo.Dim_PlayerLevel | Name | join-enriched | From Dim_PlayerLevel.Name via PlayerLevelID | Player tier name |
| CID | DWH_dbo.Dim_Position | CID | passthrough | Direct: Dim_Position.CID | Customer ID |
| IsBuy | DWH_dbo.Dim_Position | IsBuy | passthrough | Direct: Dim_Position.IsBuy | Trade direction |
| HeldOnReportDate | DWH_dbo.Dim_Position | CloseDateID | ETL-computed | `CASE WHEN CloseDateID > @DateID OR CloseDateID = 0 THEN 1 ELSE 0 END` | Was renamed from IsOpen (SR-325240) |
| HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | passthrough | Direct: Dim_Position.HedgeServerID | Liquidity provider server |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | passthrough | Direct: Dim_Instrument.InstrumentID | Instrument FK |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | passthrough | Direct: Dim_Instrument.InstrumentDisplayName | User-facing name |
| InstrumentName | DWH_dbo.Dim_Instrument | Name | rename | Direct: Dim_Instrument.Name | Internal instrument name |
| InstrumentTypeID | DWH_dbo.Dim_Instrument | InstrumentTypeID | passthrough | Direct: Dim_Instrument.InstrumentTypeID | Asset class ID |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | passthrough | Direct: Dim_Instrument.InstrumentType | Asset class name |
| IsCopy | DWH_dbo.Dim_Position | MirrorID | ETL-computed | `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END` | Copy-trade flag |
| IsCFD | DWH_dbo.Dim_Position | IsSettled | ETL-computed | `CASE WHEN IsSettled = 1 THEN 0 ELSE 1 END` | CFD vs Real flag |
| Symbol | DWH_dbo.Dim_Instrument | Symbol | passthrough | Direct: Dim_Instrument.Symbol | Ticker symbol |
| Leverage | DWH_dbo.Dim_Position | Leverage | passthrough | Direct: Dim_Position.Leverage | Position leverage |
| Exchange | DWH_dbo.Dim_Instrument | Exchange | passthrough | Direct: Dim_Instrument.Exchange | Stock exchange |
| CountryID | DWH_dbo.Dim_Country | CountryID | join-enriched | From Dim_Country.CountryID via Fact_SnapshotCustomer.CountryID | Customer country FK |
| Country | DWH_dbo.Dim_Country | Name | join-enriched | From Dim_Country.Name via CountryID | Country name |
| Region | DWH_dbo.Dim_Country | MarketingRegionManualName | join-enriched | From Dim_Country.MarketingRegionManualName via CountryID | Marketing region |
| RegulationID | DWH_dbo.Fact_SnapshotCustomer | RegulationID | passthrough | Direct: Fact_SnapshotCustomer.RegulationID | Regulatory jurisdiction |
| Regulation | DWH_dbo.Dim_Regulation | Name | join-enriched | From Dim_Regulation.Name via RegulationID | Regulation name |
| IsIslamic | DWH_dbo.Dim_Customer | WeekendFeePrecentage | ETL-computed | `CASE WHEN WeekendFeePrecentage = 0 THEN 1 ELSE 0 END` | Islamic account flag |
| Size of Tickets | — | — | ETL-computed | `CASE WHEN Volume BETWEEN x AND y THEN 'x$-y$'` (16 buckets from 1$-10$ to Over2000000$) | Volume bucket label |
| OpenOrClose | — | — | ETL-computed | Literal: `'Open Click'` or `'Close Click'` | Row type indicator |
| OpenOrCloseID | — | — | ETL-computed | `1` = open, `0` = close | Row type numeric |
| Click | DWH_dbo.Dim_Position | OpenDateID, CloseDateID | ETL-computed | `SUM(NumberofPositionsOpened)` for opens or `SUM(NumberofPositionsClosed)` for closes. NumberofPositionsOpened = `CASE WHEN OpenDateID=@DateID AND ISNULL(IsPartialCloseChild,0)=0 THEN 1 ELSE 0 END` | Trade count |
| Volume | DWH_dbo.Dim_Position | Volume, VolumeOnClose | ETL-computed | `SUM(CAST(VolumeOpened AS BIGINT))` for opens, `SUM(VolumeClosed)` for closes. VolumeOpened = SUM of Dim_Position.Volume over OriginalPositionID partition. VolumeClosed = VolumeOnClose. | USD volume |
| Units | DWH_dbo.Dim_Position | InitialUnits, AmountInUnitsDecimal | ETL-computed | `SUM(UnitsOpened)` for opens, `SUM(UnitsClosed)` for closes. UnitsOpened = InitialUnits WHERE OpenDateID=@DateID. UnitsClosed = AmountInUnitsDecimal WHERE CloseDateID=@DateID. | Instrument units |
| FullCommission | DWH_dbo.Dim_Position | FullCommission, FullCommissionOnClose, FullCommissionByUnits | ETL-computed | Opens: `SUM(FullCommissionOnOpenInit)` — FullCommissionByUnits for same-day open or accumulated from partial close children. Closes: `SUM(FullCommissionOnClose - FullCommissionByUnits)` for older positions, `SUM(FullCommissionOnClose)` for same-day. | Commission amount |
| InitialAmountUSDOnOpen | DWH_dbo.Dim_Position | InitialAmountCents | ETL-computed | `SUM(InitialAmountCents/100) WHERE NumberofPositionsOpened=1` | Open amount in USD |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL load timestamp |
| IsPI | DWH_dbo.Fact_SnapshotCustomer | GuruStatusID | ETL-computed | `CASE WHEN GuruStatusID >= 2 THEN 1 ELSE 0 END` | Popular Investor flag |
| IsTicketFee | DWH_dbo.Fact_CustomerAction | Amount | ETL-computed | `CASE WHEN ticket_fee_Amount IS NULL THEN 0 ELSE 1 END`. Ticket fee from Fact_CustomerAction WHERE ActionTypeID=35 AND IsFeeDividend=4. | Has ticket fee flag |
| TicketFee | DWH_dbo.Fact_CustomerAction | Amount | ETL-computed | `SUM(Amount)` from Fact_CustomerAction WHERE ActionTypeID=35 AND IsFeeDividend=4 AND DateID=@DateID, joined on PositionID+OpenOrCloseID | Ticket fee amount |
| IsAirDrop | DWH_dbo.Dim_Position | IsAirDrop | ETL-computed | `CASE WHEN dp.IsAirDrop = 1 THEN 1 ELSE 0 END` | AirDrop position flag |
| IsFuture | DWH_dbo.Dim_Instrument | IsFuture | passthrough | Direct: Dim_Instrument.IsFuture | Futures instrument flag |
| HaseMoneyAccount | eMoney_dbo.eMoney_Dim_Account | CID | join-enriched | `CASE WHEN eMoney_Dim_Account.CID IS NOT NULL THEN 1 ELSE 0 END` WHERE GCID_Unique_Count=1 AND IsValidETM=1 | Has eMoney account |
| IsIBANClick | BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN / BI_DB_Positions_Closed_To_IBAN | PositionID | join-enriched | Open: `CASE WHEN BI_DB_Positions_Opened_From_IBAN.PositionID IS NOT NULL THEN 1 ELSE 0 END`. Close: same logic with BI_DB_Positions_Closed_To_IBAN. | IBAN-originated trade |
| IsFTDClick | DWH_dbo.Dim_Position, DWH_dbo.Dim_Customer | PositionID | ETL-computed | `CASE WHEN dp.PositionID = dc.PositionID THEN 1 ELSE 0 END`. dc.PositionID = first non-airdrop position after first deposit. | First Trade After Deposit |
| IsLowTouch | DWH_dbo.Dim_Instrument | OperationMode | rename | Direct: Dim_Instrument.OperationMode | Low-touch instrument flag |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 13 |
| **Rename** | 2 |
| **ETL-computed** | 19 |
| **Join-enriched** | 8 |
| **Total** | 42 |
