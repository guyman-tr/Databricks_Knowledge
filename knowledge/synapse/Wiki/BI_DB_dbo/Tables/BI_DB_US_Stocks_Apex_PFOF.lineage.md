# Lineage: BI_DB_US_Stocks_Apex_PFOF

**Schema:** BI_DB_dbo  
**Writer SP:** `SP_US_Stocks_Apex_PFOF`  
**Author:** Artyom Bogomolsky (2022-01-13; 7-day backfill loop added 2022-10-25)  
**ETL Pattern:** 7-day loop (DELETE WHERE TradeDate=@Date → INSERT SELECT) per day; also calls `SP_STG_Sodreconciliation_apex` first  
**Frequency:** Daily (SB_Daily, Priority 20)

## Column Lineage

| Target Column | Source Table | Source Column | Transformation |
|---|---|---|---|
| TradeDate | STG_Sodreconciliation_apex_EXT1047_RevenueReports | TradeDate | Direct; filtered WHERE TradeDate=@Date in each loop iteration |
| OrderID | STG_Sodreconciliation_apex_EXT1047_RevenueReports | OrderID | Direct; Apex order identifier (format: '!' prefix) |
| Side | STG_Sodreconciliation_apex_EXT1047_RevenueReports | Side | Direct; 'B'=Buy, 'S'=Sell |
| InstrumentType | STG_Sodreconciliation_apex_EXT1047_RevenueReports | InstrumentType | Direct; 'Equity' or 'Option' |
| Symbol | STG_Sodreconciliation_apex_EXT1047_RevenueReports | Symbol | Direct; ticker for equities, option contract descriptor for options |
| Description | STG_Sodreconciliation_apex_EXT1047_RevenueReports | Description | Direct; market maker + routing strategy descriptor (e.g., "JANE_Simple_Penny") |
| ClearingAccount | STG_Sodreconciliation_apex_EXT1047_RevenueReports | ClearingAccount | Direct; Apex account that cleared the trade |
| PriceFiller | STG_Sodreconciliation_apex_EXT1047_RevenueReports | PriceFiller | Direct; PFOF rate / price improvement per unit |
| Total_Amount | STG_Sodreconciliation_apex_EXT1047_RevenueReports | TotalQuantity | ABS(TotalQuantity) — absolute share/contract count |
| CustomerPFOFPayback | STG_Sodreconciliation_apex_EXT1047_RevenueReports | CustomerPFOFPayback | Direct; PFOF rebate amount passed to customer (always ≤ 0) |
| Cusip | STG_Sodreconciliation_apex_EXT872_TradeActivity | Cusip | Via #cusip CTE: DISTINCT Cusip/Symbol from EXT872; LEFT JOIN to PFOF on Symbol COLLATE Latin1_General_BIN; NULL for options and some equities |
| InstrumentName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | CASE: InstrumentDisplayName when not NULL; else Symbol COLLATE Latin1_General_BIN (option contract descriptor for options) |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | LEFT JOIN via Cusip → Dim_Instrument.CUSIP; NULL for all options (no CUSIP) and ~3.9% of equities |
| UpdateDate | ETL runtime | GETDATE() | Always current ETL run timestamp |

## Source Tables

| Table | Role | Filter |
|---|---|---|
| `BI_DB_staging.STG_Sodreconciliation_apex_EXT1047_RevenueReports` | Driver — PFOF revenue report (format 1047) | TradeDate=@Date, most recent SodFile |
| `BI_DB_staging.STG_Sodreconciliation_apex_EXT872_TradeActivity` | CUSIP lookup | ProcessDate=@Date, most recent SodFile; provides Symbol→Cusip mapping |
| `BI_DB_staging.STG_Sodreconciliation_apex_SodFiles` | File validation | ApexFormat IN(1047,872), Status=2, ProcessDate=@Date — max ImportEndDate |
| `DWH_dbo.Dim_Instrument` | Instrument dimension | LEFT JOIN on CUSIP; provides InstrumentDisplayName and InstrumentID |

## ETL Notes

- **7-day loop**: SP processes @Date-7 through @Date in a daily loop. Each day is individually deleted and re-inserted. This backfill ensures late-arriving EXT1047 files (delivered after market close) are captured.
- **Staging tables not External tables**: Unlike most Apex SPs, this SP reads from `BI_DB_staging.*` tables (populated by `SP_STG_Sodreconciliation_apex` called at SP start), not from External_* tables directly.
- **EXT1047 = Revenue Reports**: Apex format 1047 is the PFOF revenue/payment report, distinct from EXT869 (cash journals) and EXT872 (trade activity).
- **Options coverage**: Despite the table name "US_Stocks_Apex_PFOF", the table includes both equities (~82%) and options (~18%). Options have significantly higher per-trade PFOF values (avg -$0.42 vs -$0.014 for equities in 2026 YTD).
- **InstrumentName fallback**: For options, `Dim_Instrument.InstrumentDisplayName` is NULL (options not in Dim_Instrument by CUSIP), so InstrumentName = Symbol (the full option contract descriptor, e.g., "IWM 04/09/2026 P 257.00").
- **CustomerPFOFPayback always ≤ 0**: This is the PFOF amount passed back to the customer — a cost to eToro. Value of 0 means no payback; negative values represent actual customer rebates.
- **Collation handling**: Symbol matching uses COLLATE Latin1_General_BIN to handle case-sensitive ticker symbols from different Apex formats.
