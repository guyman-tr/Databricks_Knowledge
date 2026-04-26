# Lineage: BI_DB_dbo.Dealing_CryptoRebate

**Writer SP:** `BI_DB_dbo.SP_M_CryptoRebateDiamond` (Author: Tom Boksenbojm original; Eden Winkler migration 2023-12-21; Ofir Chloe Gal updates 2025)
**Grain:** One row per {MonthEndDate × CID × Regulation × Club}. Monthly delete-insert keyed on MonthEndDate.
**Trigger:** Runs monthly (FrequencySP=Monthly, SB_Daily process, Priority 20)

---

## Upstream Sources

| Source | Role |
|--------|------|
| `DWH_dbo.Fact_SnapshotCustomer` | Club membership eligibility: PlayerLevelID IN (6,7) = Platinum Plus/Diamond; IsValidCustomer, GuruStatusID filter; CountryID, RegulationID, Region |
| `DWH_dbo.Dim_Range` | Date range join for snapshot customer (DateRangeID between FromDateID and ToDateID) |
| `DWH_dbo.Dim_PlayerLevel` | Joined to validate PlayerLevelID |
| `DWH_dbo.Dim_Country` | Country.Name |
| `DWH_dbo.Dim_Regulation` | Regulation.Name via DWHRegulationID |
| `BI_DB_dbo.V_GermanBaFin` | German BaFin flag (used in unrealized path only, not in this table) |
| `DWH_dbo.Dim_Position` | Closed crypto positions: AmountInUnitsDecimal, InitForexRate, InitForex_USDConversionRate, EndForexRate, LastOpConversionRate, CID, InstrumentID, IsSettled, IsDiscounted, IsBuy, MirrorID, Leverage, OpenDateID, CloseDateID |
| `DWH_dbo.Dim_Instrument` | InstrumentTypeID = 10 filter (Crypto Currencies only) |

---

## Column Lineage

| Column | Source Expression | Notes |
|--------|-------------------|-------|
| `MonthEndDate` | `EOMONTH(DATEADD(month, DATEDIFF(month, 0, @Date), 0))` | Last calendar day of the month for the input @Date parameter |
| `Club` | `CASE WHEN PlayerLevelID=7 THEN '1 Diamond' WHEN PlayerLevelID=6 THEN '1 Platinum Plus' ELSE 'Error' END` | From `Fact_SnapshotCustomer.PlayerLevelID`. Only 2 values in this table |
| `CID` | `Fact_SnapshotCustomer.RealCID` | Client identifier. Eligibility: PlayerLevelID IN (6,7), IsValidCustomer=1, GuruStatusID NOT IN (2,3,4,5,6), country exclusion list |
| `GuruStatus_ID` | `Fact_SnapshotCustomer.GuruStatusID` | Popular Investor / guru program status ID. Values NOT IN (2,3,4,5,6) are included |
| `Country` | `DWH_dbo.Dim_Country.Name` via `Fact_SnapshotCustomer.CountryID` | Client registered country at month-end snapshot |
| `Region` | `DWH_dbo.Fact_SnapshotCustomer.Region` | Marketing region field from SnapshotCustomer |
| `Regulation` | `DWH_dbo.Dim_Regulation.Name` via `Fact_SnapshotCustomer.RegulationID → DWHRegulationID` | CID's regulatory jurisdiction at month-end |
| `OpenedVolume` | `SUM(AmountInUnitsDecimal * ISNULL(InitForexRate,1) * ISNULL(InitForex_USDConversionRate,1))` | USD value at open for crypto positions closed within the month (Dim_Position: CloseDateID BETWEEN @MonthStart AND @MonthEnd, IsSettled=1, IsDiscounted=0, IsBuy=1, MirrorID=0, Leverage=1, OpenDateID>=20220308, InstrumentTypeID=10) |
| `ClosedVolume` | `SUM(AmountInUnitsDecimal * ISNULL(EndForexRate,1) * ISNULL(LastOpConversionRate,1))` | USD value at close for the same eligible positions |
| `TotalVolume` | `OpenedVolume + ClosedVolume` | Sum of open + close USD values for all eligible closed positions in the month |
| `Markup` | `TotalVolume * 0.01` | Estimated spread revenue (1% of total notional). Approximation of eToro's crypto spread |
| `Bracket1_Volume` | `CASE WHEN TotalVolume>50000 AND TotalVolume<=1000000 THEN TotalVolume-50000 WHEN TotalVolume>1000000 THEN 900000 ELSE 0 END` | Volume in the $50K–$1M bracket (capped at $950K = $1M-$50K) |
| `Bracket2_Volume` | `CASE WHEN TotalVolume>1000000 AND TotalVolume<=5000000 THEN TotalVolume-1000000 WHEN TotalVolume>5000000 THEN 4000000 ELSE 0 END` | Volume in the $1M–$5M bracket (capped at $4M) |
| `Bracket3_Volume` | `CASE WHEN TotalVolume>5000000 THEN TotalVolume-5000000 ELSE 0 END` | Volume above $5M (uncapped) |
| `Bracket1_Rebate` | `Bracket1_Volume * 0.15 / 100` | 0.15% rebate on Bracket 1 volume |
| `Bracket2_Rebate` | `Bracket2_Volume * 0.25 / 100` | 0.25% rebate on Bracket 2 volume |
| `Bracket3_Rebate` | `Bracket3_Volume * 0.5 / 100` | 0.50% rebate on Bracket 3 volume |
| `TotalRebate` | `CASE WHEN Bracket1_Rebate+Bracket2_Rebate+Bracket3_Rebate < 5 THEN 0 ELSE sum END` | Minimum rebate threshold: if total < $5, pays $0. Otherwise sum of all bracket rebates |
| `UPdatedate` | `GETDATE()` | ETL run timestamp |

---

## Position Eligibility Filters (Realized Path)
Positions must meet ALL criteria to count toward volume:
- `InstrumentTypeID = 10` (Crypto Currencies)
- `IsSettled = 1` (spot/custody crypto, not CFD)
- `IsDiscounted = 0` (not discounted)
- `IsBuy = 1` (long positions only)
- `MirrorID = 0` (direct positions only, not CopyTrader mirrors)
- `Leverage = 1` (unlevered)
- `CloseDateID BETWEEN @MonthStartDateID AND @MonthEndDateID` (closed within month)
- `OpenDateID >= 20220308` (rebate plan start date, hardcoded)

## ETL Orchestration (OpsDB)
- **OpsDB Priority:** 20
- **FrequencySP:** Monthly
- **ProcessType:** 1 (SQL)
- **ProcessName:** SB_Daily
- **Pattern:** DELETE WHERE MonthEndDate = @MonthEndDate, then INSERT from #TotalRebate
