# Dealing_dbo.Dealing_CloseOnly_Recon

## 1. Overview

**Daily reconciliation table monitoring changes in close-only instrument positions**. Tracks instruments that have been placed in "close-only" mode (both `AllowBuy=0` and `AllowSell=0` — meaning clients can only close existing positions, not open new ones). For each such instrument, the table compares today's vs yesterday's units and amounts on both the client side and eToro's hedge side, surfacing any movement in positions for instruments that should theoretically only be decreasing.

**Row grain**: One row per `HedgeServerID` + `InstrumentID` combination where the instrument is in close-only mode (AllowClosePosition=1 in source, meaning close-only instruments).

---

## 2. Business Context

`SP_CloseOnly_Recon` (Author: Gili Goldbaum 2023-03-28) skips Sundays and reads from `Dealing_Duco_EODRecon` filtered for instruments where `AllowBuy=0 AND AllowSell=0` (close-only mode from the instrument configuration).

**Logic**: The SP computes the day-over-day delta in units and amounts for close-only instruments:
- `Change_in_Units_Clients` = ClientUnits (today) − ClientUnits_Previous (yesterday)
- `Change_in_Units_eToro` = eToro_Units (today) − eToro_Units_Previous (yesterday)

For a properly closed position, both should be decreasing (negative deltas). Positive deltas indicate new positions were opened despite the instrument being in close-only mode — a potential compliance/risk flag.

**Weekend handling**: `@Previous_Date` skips weekends — Friday's date is used as the previous date when today is Monday.

**AllowClosePosition**: The column in this table reflects whether the instrument had AllowClosePosition=1 in `Dealing_Duco_EODRecon` on the current date (meaning close-only instruments are the focus, not all instruments).

**Key business rules**:

- **Scope**: Only instruments with AllowBuy=0 AND AllowSell=0 in the instrument configuration.
- **Skips Sundays**: No data generated on Sunday.
- **Weekend-aware previous date**: Correctly handles Mon→Fri (not Mon→Sun) for previous date.
- **DELETE-INSERT by current date**.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 23 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Current_Date ASC |

---

## 4. Live Data Verification (prod `sql_dp_prod_we`)

Read-only checks executed **2026-03-21**.

| Check | Result |
|--------|--------|
| **Row count** | ~314,000 |
| **Date range** | Active and current (daily refresh confirmed) |
| **AllowClosePosition** | All rows = 1 (close-only mode flag consistent) |

---

## 5. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Current_Date | date | YES | Today's report date (the monitoring date). (Tier 2 -SP_CloseOnly_Recon, @Date) |
| 2 | Previous_Date | date | YES | Previous business day date (skipping weekends). (Tier 2 -SP_CloseOnly_Recon, @Previous_Date — weekend-aware) |
| 3 | HedgeServerID | int | YES | Hedge server associated with the instrument position. (Tier 2 -SP_CloseOnly_Recon, Dealing_Duco_EODRecon.HedgeServerID) |
| 4 | InstrumentID | int | YES | eToro instrument identifier. (Tier 2 -SP_CloseOnly_Recon, Dealing_Duco_EODRecon.InstrumentID) |
| 5 | InstrumentDisplayName | varchar(100) | YES | Instrument display name. (Tier 2 -SP_CloseOnly_Recon, Dealing_Duco_EODRecon.InstrumentDisplayName) |
| 6 | Symbol | varchar(250) | YES | Instrument ticker symbol. (Tier 2 -SP_CloseOnly_Recon, Dealing_Duco_EODRecon.Symbol) |
| 7 | ISINCode | varchar(30) | YES | ISIN code for the instrument. (Tier 2 -SP_CloseOnly_Recon, Dealing_Duco_EODRecon.ISINCode) |
| 8 | CurrencyPrimary | varchar(50) | YES | Primary currency of the instrument (SellCurrency). (Tier 2 -SP_CloseOnly_Recon, Dealing_Duco_EODRecon.SellCurrency) |
| 9 | Exchange | varchar(80) | YES | Exchange where the instrument is listed. (Tier 2 -SP_CloseOnly_Recon, Dealing_Duco_EODRecon.Exchange) |
| 10 | AllowClosePosition | bit | YES | 1 = instrument is in close-only mode (AllowBuy=0 AND AllowSell=0). (Tier 2 -SP_CloseOnly_Recon, instrument configuration in Dealing_Duco_EODRecon) |
| 11 | Change_in_Units_Clients | decimal(38,15) | YES | Delta in client units: ClientUnits(today) − ClientUnits(yesterday). Negative = positions closing as expected; positive = new positions opened (flag). (Tier 2 -SP_CloseOnly_Recon, computed: current.ClientUnits − previous.ClientUnits) |
| 12 | Change_in_Units_eToro | decimal(38,15) | YES | Delta in eToro LP units: eToro_Units(today) − eToro_Units(yesterday). Should mirror client change for a properly hedged instrument. (Tier 2 -SP_CloseOnly_Recon, computed: current.eToro_Units − previous.eToro_Units) |
| 13 | ClientUnits | decimal(38,15) | YES | Total client NOP units for this instrument today. (Tier 2 -SP_CloseOnly_Recon, Dealing_Duco_EODRecon.ClientUnits on Current_Date) |
| 14 | ClientUnits_Previous | decimal(38,15) | YES | Total client NOP units for this instrument yesterday. (Tier 2 -SP_CloseOnly_Recon, Dealing_Duco_EODRecon.ClientUnits on Previous_Date) |
| 15 | eToro_Units | decimal(38,15) | YES | eToro LP hedge units for this instrument today. (Tier 2 -SP_CloseOnly_Recon, Dealing_Duco_EODRecon.eToro_Units on Current_Date) |
| 16 | eToro_Units_Previous | decimal(38,15) | YES | eToro LP hedge units for this instrument yesterday. (Tier 2 -SP_CloseOnly_Recon, Dealing_Duco_EODRecon.eToro_Units on Previous_Date) |
| 17 | Change_in_Amount_Clients | money | YES | Delta in client USD amount: ClientAmount(today) − ClientAmount(yesterday). (Tier 2 -SP_CloseOnly_Recon, computed: current.ClientAmount − previous.ClientAmount) |
| 18 | Change_in_USDAmount_eToro | money | YES | Delta in eToro LP USD amount: eToroUSDAmount(today) − eToroUSDAmount(yesterday). (Tier 2 -SP_CloseOnly_Recon, computed: current.eToroUSDAmount − previous.eToroUSDAmount) |
| 19 | ClientAmount | money | YES | Client position USD value today. (Tier 2 -SP_CloseOnly_Recon, Dealing_Duco_EODRecon.ClientAmount on Current_Date) |
| 20 | ClientAmount_Previous | money | YES | Client position USD value yesterday. (Tier 2 -SP_CloseOnly_Recon, Dealing_Duco_EODRecon.ClientAmount on Previous_Date) |
| 21 | eToroUSDAmount | money | YES | eToro LP USD amount today. (Tier 2 -SP_CloseOnly_Recon, Dealing_Duco_EODRecon.eToroUSDAmount on Current_Date) |
| 22 | eToroUSDAmount_Previous | money | YES | eToro LP USD amount yesterday. (Tier 2 -SP_CloseOnly_Recon, Dealing_Duco_EODRecon.eToroUSDAmount on Previous_Date) |
| 23 | UpdateDate | datetime | YES | Batch execution timestamp (GETDATE()). (Tier 3 -SP_CloseOnly_Recon, GETDATE()) |

---

## 6. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|--------------|
| Dealing_Duco_EODRecon | Dealing_dbo | Primary source: both current and previous date rows (self-join by date) |

---

## 7. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_CloseOnly_Recon |
| **Author** | Gili Goldbaum (2023-03-28) |
| **ETL Pattern** | DELETE WHERE Current_Date=@Date + INSERT |
| **Schedule** | Daily — SB_Daily (P0); skips Sundays |
| **Parameter** | @Date (DATE) |
| **Delete Scope** | `DELETE WHERE Current_Date = @Date` |
| **Dependencies** | Requires Dealing_Duco_EODRecon (SP_DataForDuco) for both Current_Date and Previous_Date |

---

## 8. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Clustered index** | Filter on `Current_Date` for optimal performance. |
| **Positive change = alert** | `Change_in_Units_Clients > 0` for a close-only instrument indicates unauthorized new positions were opened. |
| **No Sunday data** | Sunday is skipped; Monday's Previous_Date will be Friday (weekend-aware). |
| **Weekend previous date** | For Monday runs, Previous_Date = Friday (not Sunday). |
| **Depends on Duco freshness** | This table is only meaningful if `Dealing_Duco_EODRecon` has been populated for both Current_Date and Previous_Date. |

---

## 9. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Dealing / LP Reconciliation |
| **Sub-domain** | Close-only instrument position monitoring |
| **Sensitivity** | Aggregated LP/instrument data (no individual customer data) |
| **Quality Score** | 7.8 |

---

*Generated by DWH Semantic Documentation Pipeline -- Batch 5*
