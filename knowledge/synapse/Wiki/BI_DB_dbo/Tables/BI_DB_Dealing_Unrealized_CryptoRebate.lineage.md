# Lineage: BI_DB_dbo.Dealing_Unrealized_CryptoRebate

**Writer SP:** `BI_DB_dbo.SP_M_CryptoRebateDiamond` (same SP as Dealing_CryptoRebate; second INSERT block, lines 542–595)
**Grain:** One row per {MonthEndDate × CID × Regulation × Club × IsCreditReportValidCB × IsGermanBaFin}. Monthly delete-insert keyed on MonthEndDate.
**Trigger:** Monthly (FrequencySP=Monthly, SB_Daily process, Priority 20)

---

## Upstream Sources

| Source | Role |
|--------|------|
| `DWH_dbo.Fact_SnapshotCustomer` | Club membership eligibility (same as realized path) |
| `DWH_dbo.Dim_Range` | Date range join for snapshot customer |
| `DWH_dbo.Dim_Country` | Country.Name |
| `DWH_dbo.Dim_Regulation` | Regulation.Name |
| `BI_DB_dbo.V_GermanBaFin` | German BaFin flag for client (used in this table; not in realized table) |
| `BI_DB_dbo.BI_DB_PositionPnL` | Open positions at month-end: CID, PositionID, InstrumentID, AmountInUnitsDecimal, InitForexRate, IsSettled, DateID = @MonthEndDateID |
| `DWH_dbo.Dim_Position` | InitForex_USDConversionRate, IsDiscounted, IsBuy, MirrorID, Leverage, OpenDateID (for open position volume calculations) |
| `DWH_dbo.Dim_Instrument` | InstrumentTypeID = 10 filter (Crypto Currencies only) |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | EOM market prices: BidSpreaded, ConvertRateIsBuy_1 for unrealized close valuation (OccurredDateID = @MonthEndDateID) |

---

## Column Lineage

| Column | Source Expression | Notes |
|--------|-------------------|-------|
| `MonthEndDate` | `EOMONTH(...)` from @Date parameter | Last calendar day of the reporting month |
| `Club` | `CASE WHEN PlayerLevelID=7 THEN '1 Diamond' WHEN PlayerLevelID=6 THEN '1 Platinum Plus' ELSE 'Error' END` | Same as realized table |
| `CID` | `Fact_SnapshotCustomer.RealCID` | Same eligibility filters as realized path |
| `IsCreditReportValidCB` | `Fact_SnapshotCustomer.IsCreditReportValidCB` | Additional column vs realized table. Credit balance report validity flag at month-end |
| `IsGermanBaFin` | `CASE WHEN V_GermanBaFin.CID IS NOT NULL THEN 1 ELSE 0 END` from `BI_DB_dbo.V_GermanBaFin` at @MonthEndDateID | Additional column vs realized table. German BaFin client flag |
| `GuruStatus_ID` | `Fact_SnapshotCustomer.GuruStatusID` | Same as realized table |
| `Country` | `DWH_dbo.Dim_Country.Name` | Same as realized table |
| `Region` | `Fact_SnapshotCustomer.Region` | Same as realized table |
| `Regulation` | `DWH_dbo.Dim_Regulation.Name` | Same as realized table |
| `OpenedVolume` | `SUM(BI_DB_PositionPnL.AmountInUnitsDecimal * ISNULL(InitForexRate,1) * ISNULL(Dim_Position.InitForex_USDConversionRate,1))` | USD open-date notional for still-open positions at month-end. Source: BI_DB_PositionPnL (not Dim_Position) for the position list |
| `ClosedVolume` | `SUM(BI_DB_PositionPnL.AmountInUnitsDecimal * ISNULL(Fact_CurrencyPriceWithSplit.BidSpreaded,1) * ISNULL(Fact_CurrencyPriceWithSplit.ConvertRateIsBuy_1,1))` | Hypothetical close value at EOM market prices from Fact_CurrencyPriceWithSplit (OccurredDateID = @MonthEndDateID). Represents mark-to-market close value |
| `TotalVolume` | `OpenedVolume + ClosedVolume` | Same formula as realized; represents total unrealized notional |
| `Markup` | `TotalVolume * 0.01` | 1% of total notional (same as realized) |
| `Bracket1_Volume` | Same CASE expression as realized table | Volume in $50K–$1M bracket |
| `Bracket2_Volume` | Same CASE expression as realized table | Volume in $1M–$5M bracket |
| `Bracket3_Volume` | Same CASE expression as realized table | Volume above $5M |
| `Bracket1_Rebate` | `Bracket1_Volume * 0.15 / 100` | 0.15% on Bracket 1 |
| `Bracket2_Rebate` | `Bracket2_Volume * 0.25 / 100` | 0.25% on Bracket 2 |
| `Bracket3_Rebate` | `Bracket3_Volume * 0.5 / 100` | 0.50% on Bracket 3 |
| `TotalRebate` | `CASE WHEN sum < 5 THEN 0 ELSE sum END` | Same minimum threshold as realized |
| `UPdatedate` | `GETDATE()` | ETL run timestamp |

---

## Position Eligibility Filters (Unrealized Path)
- `BI_DB_PositionPnL.DateID = @MonthEndDateID` (open at month-end snapshot)
- `InstrumentTypeID = 10` (Crypto Currencies)
- `BI_DB_PositionPnL.IsSettled = 1`
- `Dim_Position.IsDiscounted = 0`
- `Dim_Position.IsBuy = 1`
- `Dim_Position.MirrorID = 0`
- `Dim_Position.Leverage = 1`
- `Dim_Position.OpenDateID >= 20220308`

## ETL Orchestration (OpsDB)
- **OpsDB Priority:** 20
- **FrequencySP:** Monthly
- **ProcessType:** 1 (SQL)
- **ProcessName:** SB_Daily
- **Pattern:** DELETE WHERE MonthEndDate = @MonthEndDate, then INSERT from #UnrealizedTotalRebate
- **Same SP run:** Written in the same execution as Dealing_CryptoRebate — both DELETE-INSERTs happen in the same SP call
