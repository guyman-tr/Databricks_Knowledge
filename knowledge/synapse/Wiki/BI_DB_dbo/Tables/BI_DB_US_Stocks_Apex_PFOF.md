# BI_DB_US_Stocks_Apex_PFOF

**Schema:** BI_DB_dbo  
**Type:** Table  
**Distribution:** ROUND_ROBIN  
**Index:** CLUSTERED INDEX (TradeDate ASC)  
**Writer SP:** `SP_US_Stocks_Apex_PFOF`  
**Author:** Artyom Bogomolsky (2022-01-13)  
**Frequency:** Daily (SB_Daily, Priority 20)

---

## 1. Summary

Daily Payment For Order Flow (PFOF) ledger for eToro US customers trading via Apex Clearing. Each row represents one trade order's PFOF record — the payment received by eToro from market makers (Jane Street, Citadel, SIG, etc.) for routing customer orders to their liquidity pools, and the corresponding rebate passed back to customers. Covers both US equity trades and options trades, despite the "US_Stocks" name.

Used for US regulatory PFOF reporting, revenue tracking, and compliance disclosure (SEC Rule 606 / PFOF transparency requirements).

---

## 2. Business Context

- **Domain**: US equities + options / Apex Clearing PFOF reporting
- **What is PFOF**: Payment For Order Flow — market makers pay brokers for the right to execute customer orders. eToro receives this payment from Apex's market makers and passes a portion back to customers as `CustomerPFOFPayback`.
- **Population**: All US customer equity and options trades routed through Apex Clearing on the given trade date, as reported in Apex's EXT1047 Revenue Reports.
- **Coverage**: Both `Equity` (82% of rows) and `Option` (18%) instrument types. Options have ~30× higher average PFOF per trade (-$0.42 vs -$0.014).
- **Market makers**: JANE (Jane Street), SIG (Susquehanna), Citadel, WATERSHED, LIQPOINT, and others — identified in the `Description` column.
- **Producers**: `SP_US_Stocks_Apex_PFOF` (Artyom Bogomolsky, 2022-01-13). Calls `SP_STG_Sodreconciliation_apex` to stage the source data first.
- **Consumers**: US regulatory PFOF disclosure reports, revenue analytics, compliance.

**Scale**: ~3.98M rows (2021-12-17 to 2026-04-09). ~982 distinct trade dates; ~2.93M distinct orders; ~4,486 distinct symbols.

---

## 3. Column Descriptions

| # | Column | Type | Nullable | Description |
|---|---|---|---|---|
| 1 | TradeDate | date | NOT NULL | Date the trade was executed at Apex Clearing. Primary filter column; equals the @Date SP parameter for the primary day (loop also processes the preceding 6 days for late-arriving data). |
| 2 | OrderID | varchar(100) | YES | Apex-assigned order identifier. Format: '!' prefix followed by numeric string (e.g., "!1260408154866167"). Unique per order within Apex systems. (Tier 2 — EXT1047_RevenueReports) |
| 3 | Side | varchar(50) | YES | Trade direction: 'B' (Buy) or 'S' (Sell). (Tier 2 — EXT1047_RevenueReports) |
| 4 | InstrumentType | varchar(100) | YES | Asset class of the instrument: 'Equity' (stock) or 'Option' (options contract). Despite the table name, options are included (~18% of rows). (Tier 2 — EXT1047_RevenueReports) |
| 5 | Symbol | varchar(50) | YES | Ticker symbol for equities (e.g., "NVDA", "AAPL") or full option contract descriptor for options (e.g., "IWM 04/09/2026 P 257.00" = IWM, April 9 expiry, Put, $257 strike). (Tier 2 — EXT1047_RevenueReports) |
| 6 | Description | varchar(200) | YES | Market maker and routing strategy descriptor from Apex EXT1047. Format: "MAKER_Strategy_Type" where MAKER is the market maker code (JANE=Jane Street, SIG=Susquehanna, Citadel, WATERSHED, LIQPOINT, etc.), Strategy is the routing approach (Simple, etc.), and Type indicates options pricing class (Penny=options priced under $3, NonPenny=options over $3). Example: "JANE_Simple_Penny". (Tier 2 — EXT1047_RevenueReports) |
| 7 | ClearingAccount | varchar(50) | YES | Apex Clearing account number that executed and cleared this trade. Identifies the customer's Apex account (format: 4GS, 5GU prefix). (Tier 2 — EXT1047_RevenueReports) |
| 8 | PriceFiller | decimal(16,8) | YES | PFOF rate or price improvement per unit received by eToro from the market maker for routing this order. Units depend on instrument type. (Tier 2 — EXT1047_RevenueReports) |
| 9 | Total_Amount | decimal(16,6) | YES | Absolute number of shares (for equities) or contracts (for options) traded in this order. Computed as ABS(EXT1047.TotalQuantity). (Tier 2 — EXT1047_RevenueReports.TotalQuantity) |
| 10 | CustomerPFOFPayback | decimal(16,6) | YES | PFOF rebate amount paid back to the customer. Always ≤ 0 when present (negative = cost to eToro / payment to customer). Value of 0 means no customer rebate for this order. Range: -$253.47 to $0.00. (Tier 2 — EXT1047_RevenueReports) |
| 11 | Cusip | varchar(100) | YES | CUSIP identifier for the instrument, sourced from EXT872 TradeActivity via Symbol match. NULL for all options rows (options don't have stock CUSIPs) and for ~3.9% of equity rows (newer instruments not yet in Apex trade data). (Tier 2 — EXT872_TradeActivity via Symbol) |
| 12 | InstrumentName | varchar(200) | YES | Human-readable instrument name. For equities: `Dim_Instrument.InstrumentDisplayName` (e.g., "NVIDIA Corporation") when CUSIP match exists; falls back to Symbol (e.g., "NVDA") for unmatched equities. For options: always falls back to Symbol (the full contract descriptor, e.g., "IWM 04/09/2026 P 257.00"). (Tier 3 — DWH_dbo.Dim_Instrument.InstrumentDisplayName or EXT1047 Symbol fallback) |
| 13 | InstrumentID | int | YES | eToro internal instrument ID from DWH_dbo.Dim_Instrument, matched via CUSIP. NULL for all options (no CUSIP match) and for equities with no CUSIP or CUSIP not in Dim_Instrument. (Tier 1 — DWH_dbo.Dim_Instrument) |
| 14 | UpdateDate | datetime | NOT NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Always set to GETDATE() at ETL run time. |

---

## 4. Distribution & Partitioning

- **Distribution**: ROUND_ROBIN — rows spread evenly; no hash key.
- **Index**: CLUSTERED INDEX on TradeDate ASC — aligned with the 7-day backfill ETL pattern.
- **ETL Pattern**: 7-day loop — for each date from @Date-7 to @Date: DELETE WHERE TradeDate=@Date, then INSERT SELECT. Enables late-arriving Apex files to be captured retroactively.

---

## 5. Relationships

**Upstream (inputs to this table):**

| Source Table | Join Type | Role |
|---|---|---|
| `BI_DB_staging.STG_Sodreconciliation_apex_EXT1047_RevenueReports` | INNER (driver) | All rows come from EXT1047 PFOF revenue reports |
| `BI_DB_staging.STG_Sodreconciliation_apex_EXT872_TradeActivity` | LEFT JOIN (via #cusip) | Provides CUSIP via Symbol match |
| `BI_DB_staging.STG_Sodreconciliation_apex_SodFiles` | INNER | File validation: latest Status=2 import for each format |
| `DWH_dbo.Dim_Instrument` | LEFT JOIN | InstrumentDisplayName and InstrumentID via CUSIP |

**Downstream (tables that read from this table):**
- US PFOF regulatory disclosure reports (SEC Rule 606)
- Revenue analytics
- No confirmed downstream SP references found in BI_DB_dbo SP set.

---

## 6. ETL & Lifecycle

- **Frequency**: Daily, run via SB_Daily scheduler.
- **Priority**: 20 (third wave).
- **ProcessType**: 1 (SQL stored procedure).
- **Pre-step**: SP calls `SP_STG_Sodreconciliation_apex` with @Date and @limitdate to stage source data before the main loop.
- **7-day backfill**: Each SP run processes 8 dates (today and preceding 7). This handles Apex's practice of delivering revised EXT1047 files for prior days. The loop was added 2022-10-25.
- **File selection**: Per date, uses the most recently imported EXT1047/EXT872 files (max ImportEndDate, Status=2).
- **Data start**: 2021-12-17 (US trading launch).
- **Latest data**: 2026-04-09 (confirmed via live Synapse query).

---

## 7. Known Caveats & Gotchas

- **"US_Stocks" is a misnomer**: The table contains both US equity and **options** PFOF records. Options represent ~18% of rows but have ~30× higher average PFOF value (-$0.42 vs -$0.014). Any equity-only analysis must filter `WHERE InstrumentType = 'Equity'`.
- **CustomerPFOFPayback is always ≤ 0**: The negative sign is correct — it represents eToro's cost (payment out to customers). A value of 0 means no customer rebate on that order.
- **Options have NULL InstrumentID and CUSIP**: Options are not in DWH_dbo.Dim_Instrument (which covers eToro's position-based instruments). Use Symbol for option identification.
- **InstrumentName for options = full contract descriptor**: "IWM 04/09/2026 P 257.00" is both the Symbol and the InstrumentName — it contains expiry, type (P/C), and strike.
- **7-day backfill means rows may be updated**: The same TradeDate can be re-inserted on up to 7 subsequent SP runs. UpdateDate reflects the most recent run.
- **Staging layer dependency**: Requires `STG_Sodreconciliation_apex_EXT1047_RevenueReports` to be populated first via `SP_STG_Sodreconciliation_apex`. If staging fails, this SP will run but produce no rows.
- **Collation joins**: Symbol matching uses COLLATE Latin1_General_BIN — required for case-sensitive ticker matching between EXT1047 and EXT872 data.
- **Description format**: "MAKER_Strategy_Type" is not documented in the SP. It comes directly from Apex's EXT1047 file format. Common values: JANE=Jane Street, SIG=Susquehanna International Group, Citadel, WATERSHED, LIQPOINT.

---

## 8. Sample Data (2026-04-09, top PFOF paybacks)

| Symbol | InstrumentType | Side | Description | Total_Amount | CustomerPFOFPayback |
|---|---|---|---|---|---|
| IWM 04/09/2026 P 257.00 | Option | S | JANE_Simple_Penny | 224 | -41.89 |
| SPY 04/10/2026 C 696.00 | Option | B | SIG_Simple_Penny | 213 | -39.83 |
| PLTR 04/10/2026 C 148.00 | Option | B | Citadel_Simple_Penny | 156 | -39.78 |
| DG 04/17/2026 C 135.00 | Option | B | WATERSHED_Simple_NonPenny | 50 | -31.88 |

Options dominate the largest PFOF payback rows. JANE (Jane Street), SIG, and Citadel are the primary market makers.
