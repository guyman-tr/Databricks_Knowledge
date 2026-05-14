# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform` |
| **UC Target (Databricks nominal)** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_options_platform` — **`SHOW TABLES IN main.bi_db LIKE '*mimo*options*'` returned 0 rows** (Databricks MCP, 2026-05-14); treat as governance target until export appears in mapping. |
| **Primary derivation** | `BI_DB_dbo.Function_MIMO_Options_Platform` over lake-backed externals |
| **ETL SP** | `BI_DB_dbo.SP_DDR_Fact_MIMO_Options_Platform` (**no `@date`; full-table reload**) |
| **Lake / production mapping (CSV)** | `Sodreconciliation.apex.EXT869_CashActivity` → Bronze `finance.bronze_sodreconciliation_apex_ext869_cashactivity` (**Append**, 1440m); `USABroker.apex.Options` → Bronze `general.bronze_usabroker_apex_options` (**Override**, 1440m) — `_generic_pipeline_mapping.json` generic_id **76**, **993** |
| **`IsRedeem` column** | **Absent from this Synapse table** (`sys.columns` count **15**). Consolidated **`IsRedeem`** for Options rows is **`0` literal** inside `SP_DDR_Fact_Fact_MIMO_AllPlatforms` secondary INSERT (`BI_DB_ddr…Options_Platform`) — canonical **transfer-to-coin (`IsRedeem`)** narrative stays on **`BI_DB_DDR_Fact_MIMO_Trading_Platform`** + `Fact_CustomerAction` / **`Function_Revenue_TransferCoinFee`**. |
| **Generated** | 2026-05-14 |

## Source Objects

| Source Object | Role |
|---------------|------|
| `BI_DB_dbo.External_Sodreconciliation_apex_EXT869_CashActivity` | Apex / Gatsby **cash ledger** parquet external (`Bronze/Sodreconciliation/apex/EXT869_CashActivity/`); feeds `PayTypeCode`, `Amount`, `ProcessDate`, `ACATSControlNumber`, `OfficeCode`, `AccountNumber`, `EnteredBy`, `TerminalID`, `RegisteredRepCode`, filters |
| `BI_DB_dbo.External_USABroker_Apex_Options` | **`USABroker.apex.Options`** mirror; **`OptionsApexID`** ↔ **`AccountNumber`**, **`GCID`** for customer linkage |
| `DWH_dbo.Dim_Customer` | **`MIMORecords`** CTE: **`JOIN … ON op.GCID = dc.GCID`** emits `RealCID`; **`GLOBAL_FTD`** sub-query uses **`FirstDepositDate` / `FirstDepositAmount` / `FTDPlatformID = 2`** for **`IsGlobalFTD`** uplift |
| `DWH_dbo.Fact_SnapshotCustomer` | Final TVF **`JOIN`** on **`op.GCID = dc.GCID`** supplies **`IsValidCustomer`/`IsCreditReportValidCB`** filter columns when `@OnlyValidCustomers` applies — **these attributes are TVF outputs only**, not persisted in `BI_DB_DDR_Fact_MIMO_Options_Platform` |
| `BI_DB_dbo.Function_MIMO_Options_Platform` | Authoritative row grain + FTD/Global-FTD logic before loader SP |

## Lineage Chain

```
Sodreconciliation.apex.EXT869_CashActivity (Production)
      -> Generic Pipeline (Append, parquet) ---
      --> BI_DB_dbo.External_Sodreconciliation_apex_EXT869_CashActivity

USABroker.apex.Options (Production)
      -> Generic Pipeline (Override, parquet) ---
      --> BI_DB_dbo.External_USABroker_Apex_Options

DWH_dbo.Dim_Customer (+ Fact_SnapshotCustomer for TVF filter)

      |
      └-- BI_DB_dbo.Function_MIMO_Options_Platform(@sdateInt, @edateInt, @OnlyValidCustomers):
             MIMORecords (DISTINCT Apex cash filtered / joined GCID→RealCID)
             + GLOBAL_FTD / FINRA FO1-first-deposit ladders -> FinalFTD join
             + DISTINCT selective output DISTINCT

      └-- BI_DB_dbo.SP_DDR_Fact_MIMO_Options_Platform:
             #fromfunc <- TVF(
                20000101,
                CAST(FORMAT(CAST(GETDATE() AS DATE),'yyyyMMdd') AS INT),
                0  -- OnlyValidCustomers
             )
             TRUNCATE BI_DB_ddr…Options_Platform
             INSERT ... SELECT literals for OrigIdentifier/Funding/Currency dup

      v
BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform (~105K Synapse rows, 2026-05-14)

Consumers (SSD snapshot):
      SP_DDR_Fact_Fact_MIMO_AllPlatforms  (daily DELETE WHERE MIMOPlatform='Options' + INSERT)
      SP_DDR_Customer_Daily_Status
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Value carried from upstream column / TVF output without change in loader SP |
| **ETL-computed** | Literal, CASE, duplication, **`GETDATE()`**, or truncation-only loader |
| **SP-discarded upstream** | TVF emits a richer column (**`FundingTypeID` CASE 42/29/2**) that loader **forces to `0`** |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|--------------|---------------|-----------|-------|
| DateID | `External_Sodreconciliation_apex_EXT869_CashActivity` | ProcessDate → `CONVERT(nvarchar(8), ProcessDate, 112)` | passthrough TVF | YYYYMMDD int surfaced as `varchar`→int in TVF SELECT |
| Date | Same | ProcessDate (`CONVERT(date, …)`) | passthrough TVF | Business **`ProcessDate`** on Apex posting |
| RealCID | `Dim_Customer` via TVF | RealCID | join-enriched | `MIMORecords`: `JOIN External_USABroker_Apex_Options op … JOIN Dim_Customer dc ON op.GCID = dc.GCID` |
| MIMOAction | External cash | PayTypeCode | ETL-computed TVF | `CASE WHEN 'C' THEN 'Deposit' WHEN 'D' THEN 'Withdraw' END`; filters restrict eligible cash rows |
| OrigIdentifier | `SP_DDR_Fact_MIMO_Options_Platform` | — | ETL-computed loader | Literal **`'ApexTxID'`** — not read from Apex feed |
| TransactionID | External cash | ACATSControlNumber | rename TVF | Exposed as `TransactionID` in TVF; Synapse DDL **`varchar(50)`**. **Different** from `AllPlatforms.Int` coercion (see **`SP_DDR_Fact_Fact_MIMO_AllPlatforms`**: `0 AS TransactionID` + comment *cannot use the varchar …*) |
| AmountUSD | External cash | Amount | ETL-computed TVF | **`ABS(ca.Amount)`** after ACH/WRD/`OMJNL` filters (**both Deposit & Withdraw numeric magnitudes remain positive**) |
| AmountOrigCurrency | `SP_DDR_Fact_MIMO_Options_Platform` / TVF AmountUSD | AmountUSD | ETL-computed loader | **`f.AmountUSD AS AmountOrigCurrency`** — duplicate `AmountUSD` (USD operational book); not multi-ccy fidelity |
| FundingTypeID | TVF emits CASE (42/29/2) … | — | SP-discarded + literal | Loader **`0 AS FundingTypeID`** destroys TVF discriminator — **DDR schema placeholder** aligning AllPlatforms UNION |
| CurrencyID | `SP_DDR_Fact_MIMO_Options_Platform` | — | ETL-computed loader | Literal **`1` — aligns `Dim_Currency` / `Dictionary.Currency` semantics for majors** |
| Currency | `SP_DDR_Fact_MIMO_Options_Platform` | — | ETL-computed loader | Literal **`'USD'`** — Apex cash book is modeled USD-only downstream |
| IsFTD | TVF **`FinalFTD` join footprint** | — | passthrough TVF | `CASE WHEN f.TransactionID IS NOT NULL THEN 1 ELSE 0 END` keyed to FINRA `RegisteredRepCode='FO1'` ladder + **`ROW_NUMBER` tie-break when multiple FTD suspects** (`FTDMultiple WHERE rn = 1`) |
| IsGlobalFTD | `Dim_Customer` subselect + **`GLOBAL_FTD` CTE** | FirstDeposit*` / Amount match | passthrough TVF | `LEFT JOIN` where `FirstDepositDate >= '20250901'` & `FTDPlatformID = 2`, amount/date keyed to **`DEPOSIT_UNIQUE_FOR_FTDJOIN`**; **`ISNULL(gftd.IsGlobalFTD,0)`** on output |
| IsInternalTransfer | External cash | TerminalID | passthrough TVF | `CASE WHEN TerminalID='OMJNL' THEN 1 ELSE 0 END` (**journal / internal-move flag**) |
| UpdateDate | `SP_DDR_Fact_MIMO_Options_Platform` | — | ETL-computed loader | **`GETDATE()` stamp** per reload |

## Summary

| Category | Count |
|---------|-------|
| passthrough TVF → target | 6 |
| ETL loader literals / duplication / timestamp | 5 |
| join-enriched (RealCID branch) | 1 |
| TVF-derived ETL Amount sign rule | 1 |
| **Total columns documented** | **15** |
