# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform

> Synapse CCI fact (**HASH(`RealCID`)**) — **DDR Money-In/Money-Out** for US **Options (Gatsby/Apex Clearing)** fiat cash postings: **104 694** rows (`COUNT_BIG(*)` MCP 2026-05-14), **`~13 724`** distinct **`RealCID`**, **`DateID` span 20221031–20260424**. Writer **`SP_DDR_Fact_MIMO_Options_Platform`** performs **`TRUNCATE` + single `INSERT` from `#fromfunc ← Function_MIMO_Options_Platform(20000101, todayYYYYMMDD, OnlyValidCustomers=0)`** so the footprint is rebuilt daily (broader than per-`DateID` delete used on TP/eMoney loaders). Consolidated consumption = **`BI_DB_DDR_Fact_MIMO_AllPlatforms`** secondary branch (`DELETE … WHERE MIMOPlatform='Options'`) citing broker arrival timing risk.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Fact (DDR MIMO — Options / Apex clearing) |
| **Production lineage** | `Sodreconciliation.apex.EXT869_CashActivity` (**Apex EXT869 CashActivity**) exported to **`External_Sodreconciliation_apex_EXT869_CashActivity`** + **`USABroker.apex.Options`** parquet export to **`External_USABroker_Apex_Options`**; assembly via **`BI_DB_dbo.Function_MIMO_Options_Platform`** (**Guy Manova 20250924** header notes Gatsby DDR + local/global FTD) |
| **Refresh** | **Daily TRUNCATE/INSERT entire table — no `@date`** (full-history TVF sweep through business-day end `GETDATE()`), because broker feed timing is unreliable for DDR cut-offs (see **`SP_DDR_Fact_Fact_MIMO_AllPlatforms` comment block** echoed in **`BI_DB_DDR_Fact_MIMO_AllPlatforms.md §1**). |
| | |
| **Synapse Distribution** | `HASH(RealCID)` |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target (nominal)** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_options_platform` — **Databricks MCP `SHOW TABLES … '*mimo*options*'` → 0 rows (2026-05-14)** |
| **UC Format** | delta (**expected BI_DB mirror pattern**) |
| **UC Partitioned By** | `_Not enumerated (export absent)_` |
| **UC Table Type** | Gold merge target **TBD until export manifests** |

---

## 1. Business Meaning

`BI_DB_DDR_Fact_MIMO_Options_Platform` is the **Options-platform sibling** to **`BI_DB_DDR_Fact_MIMO_Trading_Platform`** and **`BI_DB_DDR_Fact_MIMO_eMoney_Platform`**: DDR-grade **deposit vs withdraw labeling** keyed on Apex cash postings for US options accounts gated by firm/office filters. Each persisted row summarizes one filtered cash **credit (`PayTypeCode = 'C'`) / debit (`'D'`)** hit with **USD magnitudes**, **APEX identifiers** routed through **`USABroker.apex.Options` → `Dim_Customer.RealCID`**.

The ingest path traces **broker cash activity parquet** (`finance.bronze_sodreconciliation_apex_ext869_cashactivity` per `_generic_pipeline_mapping.json`) landed as **`Bronze/Sodreconciliation/apex/EXT869_CashActivity/`**, hydrated in Synapse as **`External_Sodreconciliation_apex_EXT869_CashActivity`**. Customer ↔ Apex account bridging uses **`Bronze/USABroker/apex/Options`** / **`general.bronze_usabroker_apex_options`** / **`External_USABroker_Apex_Options`** (PK semantics & join keys summarized in **`Apex.Options.md`** – **GCID** + **`OptionsApexID`**).

**Operational volume (Synapse MCP, 2026-05-14):**

| Slice | Rows |
|-------|-----:|
| `MIMOAction = 'Deposit'` | 76 884 |
| `MIMOAction = 'Withdraw'` | 27 810 |
| `FundingTypeID` (persisted, always **`0`** after loader coercion) | 104 694 |
| **`IsInternalTransfer = 1`** | 65 934 |
| Platform FTDs (`IsFTD = 1`) | 1 189 |
| Global FTDs (`IsGlobalFTD = 1` per TVF linkage) | 699 |

**PII stance:** keyed on **`RealCID`** (dimension master / indirect customer reference). Apex cash external columns may carry operational strings (checks/ACATS) — treat upstream lake paths under finance/compliance confidentiality; no email/phone/name fields in this CCI projection.

---

## 2. Business Logic

### 2.1 `Function_MIMO_Options_Platform` filters (production grain)

**What**: Distinct Apex cash postings limited to ACH/withdraw rails + Omni journal internals for two offices (`4GS`, `5GU`), excluding enumerated house/account sentinels, `EnteredBy ∈ ('ACH','WRD')` **OR** **`TerminalID = 'OMJNL'`**.  
**Columns Involved**: all TVF-visible columns flowing to loader.  
**Rules** (SSD **DataPlatform** `BI_DB_dbo.Function_MIMO_Options_Platform.sql`):
- **`PayTypeCode`**: **`'C'` → `Deposit`**, **`'D'` → `Withdraw`** (`CASE`).
- **`AmountUSD`** = **`ABS(ca.Amount)`** — withdrawals remain positive magnitudes (**not TP/eMoney sign flip** semantics).
- **`IsInternalTransfer`**: **`CASE WHEN ca.TerminalID = 'OMJNL' THEN 1 ELSE 0 END`** (**internal journal discriminator** mirroring ACH/transfer rails alongside literal funding CASE `42 / 29 / 2`, **later stripped by loader** — §2.3).
- **`DateID` / `[Date]`** derive directly from Apex **`ProcessDate`**.

### 2.2 Options-specific FTDs (`IsFTD`, `IsGlobalFTD`)

**What**: Thin **FINRA registrar (`RegisteredRepCode = 'FO1'`) ladder** distinguishes first deposits per account versus **later `Dim_Customer` platform-FTD uplift** keyed to **`FTDPlatformID = 2`**.  
**Columns Involved**: `IsFTD`, `IsGlobalFTD`, `RealCID`.  
**Rules** (`Function_MIMO_Options_Platform` CTEs):
1. **`DEPOSIT_UNIQUE_FOR_FTDJOIN`** → unique `(RealCID, DateID, AmountUSD)` deposit tuples (`RN=1`).
2. **`GLOBAL_FTD`** overlays **`CASE WHEN DimCustomerMatch THEN 1 ELSE 0`** when **`FirstDepositDate ≥ 20250901`** & **`FirstDepositAmount/Date`** match deposit tuple (**`LEFT JOIN`**).
3. **`FINRAONLY_*` + `FTDSingle` / `FTDMultiple`** isolate first qualifying deposit dates per **`AccountNumber`**, collapsing duplicates (`ROW_NUMBER` tie-break **`ORDER BY TransactionID`** when multiple rows fire same day/account).
4. Final SELECT uses **`CASE WHEN f.TransactionID IS NOT NULL THEN 1 ELSE 0 END AS IsFTD`** keyed to **`LEFT JOIN FinalFTD f`** aligning **`AccountNumber` + `Date` + `TransactionID`**.
5. **`IsGlobalFTD`** output = **`ISNULL(f.IsGlobalFTD, 0)`** from **`GLOBAL_FTD` join**.

### 2.3 Loader literals — why `FundingTypeID` / `Currency` disagree with raw TVF

**What**: Loader normalizes narrower DDR schema placeholders for UNION compatibility with **`SP_DDR_Fact_Fact_MIMO_AllPlatforms`**.  
**Columns Involved**: `OrigIdentifier`, `FundingTypeID`, `CurrencyID`, `Currency`, `AmountOrigCurrency`.  
**Rules** (`SP_DDR_Fact_MIMO_Options_Platform.sql`):
- Overrides TVF-coded funding rail (`CASE 42 / 29 / 2`) with **`0 AS FundingTypeID`** — **DDR placeholder** (**100% persisted zeros** MCP 2026-05-14). Analysts decoding rails must query TVF/external directly.
- Locks **`CurrencyID = 1`**, **`Currency = 'USD'`**, **`AmountOrigCurrency = AmountUSD`** (**USD bookkeeping only** SP-side).
- Injects **`'ApexTxID' AS OrigIdentifier`** aligning consolidated narrative in **`BI_DB_DDR_Fact_MIMO_AllPlatforms.md §4 Element #5`**.

### 2.4 **No `IsRedeem`, no transfercoin column on this Synapse projection**

**What**: **`IsRedeem` does not exist** in SSDT DDL (15-column layout). Canonical **transfer-to-coin (“transfercoin”) `IsRedeem` semantics remain on **`BI_DB_DDR_Fact_MIMO_Trading_Platform`** (**verbatim excerpt for consolidated rows still references **`Fact_CustomerAction` withdraw path / `Function_Revenue_TransferCoinFee` pattern** reproduced inside **`BI_DB_DDR_Fact_MIMO_AllPlatforms.md §2.3 / §4 Element #14**).  
**Rules**:
- **Do not** narrate dormant “billing bank redeem” language on Options — there is literally **no persisted column**.
- Consolidated **`IsRedeem`** for Options branch is injected as **`0` literal** in **`SP_DDR_Fact_Fact_MIMO_AllPlatforms` secondary INSERT**.

### 2.5 **`SP_DDR_Fact_MIMO_Options_Platform` — SSDT verbatim skeleton (Phase 9)**

Loader body (SSD **DataPlatform** `BI_DB_dbo.SP_DDR_Fact_MIMO_Options_Platform.sql`):

```sql
IF OBJECT_ID('tempdb..#fromfunc') IS NOT NULL DROP TABLE #fromfunc
CREATE TABLE #fromfunc
    WITH (HEAP,DISTRIBUTION = HASH(RealCID))
AS
SELECT * FROM [BI_DB_dbo].[Function_MIMO_Options_Platform] (
        20000101,
        CAST(FORMAT(CAST(GETDATE() AS DATE),'yyyyMMdd') as INT),
        0 )

TRUNCATE TABLE [BI_DB_dbo].[BI_DB_DDR_Fact_MIMO_Options_Platform]

INSERT INTO [BI_DB_dbo].[BI_DB_DDR_Fact_MIMO_Options_Platform] (
	   DateID
	 , [Date]
	 , RealCID
	 , MIMOAction
	 , OrigIdentifier
	 , TransactionID
	 , AmountUSD
	 , AmountOrigCurrency
	 , FundingTypeID
	 , CurrencyID
	 , Currency
	 , IsFTD
	 , IsGlobalFTD
	 , IsInternalTransfer
	 , UpdateDate
)
SELECT 
	   f.DateID
	 , f.Date
	 , f.RealCID
	 , f.MIMOAction
	 , 'ApexTxID' AS OrigIdentifier
	 , f.TransactionID
	 , f.AmountUSD
	 , f.AmountUSD AS AmountOrigCurrency
	 , 0 AS FundingTypeID
	 , 1 AS CurrencyID
	 , 'USD' AS Currency
	 , f.IsFTD
	 , f.IsGlobalFTD
	 , f.IsInternalTransfer
	 , GETDATE() AS UpdateDate
FROM #fromfunc f
```

**AllPlatforms** merge excerpt (SSD **DataPlatform** `BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms.sql`) clarifies **varchar key suppression** downstream:

```
DELETE FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms WHERE MIMOPlatform = 'Options'

INSERT INTO BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms (
   ...
) 
SELECT bddfmop.DateID
     , bddfmop.Date
     , bddfmop.RealCID
     , bddfmop.MIMOAction
     , bddfmop.OrigIdentifier
     , 0 AS TransactionID -- cannot use the varchar it will break current schemas on move to lake.
     ...
     , bddfmop.IsFTD AS IsPlatformFTD
     , bddfmop.IsInternalTransfer
     , 0
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

`HASH(RealCID)` CCI — predicates on **`RealCID`**, narrow **`DateID` windows**. Table is small (**~105K rows**) relative to **`AllPlatforms` (~95M)**, yet **preferred** dashboards should still hit **`BI_DB_ddr…AllPlatforms`** for cross-platform KPIs consistent with **`MIMOPlatform='Options'`**.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|-----------------------|
| Options-only daily deposit vs withdraw totals | Filter `WHERE MIMOAction IN ('Deposit','Withdraw') GROUP BY DateID` |
| Internal journal vs ACH-style flows | Separate `IsInternalTransfer` vs rest (recognize ACH still **money movement** alongside `EnteredBy='ACH'` semantics upstream) |
| First-deposit uplift QA | Jointly review `IsFTD` **AND** **`IsGlobalFTD`** versus **`Dim_Customer` FTD fields (`FTDPlatformID = 2`)** |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_Customer` | `RealCID` | Regulation / acquisition attributes |
| `DWH_dbo.Dim_Currency` | `CurrencyID` (**always `1`**) | Canonical decode / analyst familiarity |
| `BI_DB_dbo.External_USABroker_Apex_Options` | **`OptionsApexID` textual join** bridging (not stored) | Reverse engineer **`GCID`/enrollment metadata** |

### 3.4 Gotchas

- **`FundingTypeID` always zero in table — TVF-derived 42 / 29 / 2 erased** loader-side (§2.3).  
- **`AmountUSD` positives even on withdraw** — differentiate with **`MIMOAction = 'Withdraw'`** label, not algebraic sign (differs vs eMoney withdraw branch).  
- **`TransactionID` stored as alphanumeric `varchar(50)` here** but **`0` coercion** lands in **`AllPlatforms`** (merge SP comment quoted §2.5).  
- **No `IsRedeem` projection** → **never** reconcile transfercoin KPIs solely from Options fact (**use **`Trading_Platform`** / consolidated **`AllPlatforms`**).  
- **Single daily `UPDATE` stamp** (**`UpdateDate`**) lacks intra-day versioning — diagnosing reload windows requires **`Function_MIMO_Options_Platform` re-run auditing outside this table**.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Typical meaning |
|-------|------|-----------------|
| **** | Tier 1 | Canonical dimension/production dictionary lineage — suffix preserved verbatim |
| *** | Tier 2 | TVF formula / BI_DB loader coercion / sentinel constant |
| * | Tier 4 | Inference / ambiguity — captured in `.review-needed.md` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Business calendar key mirrored from Apex **`External_Sodreconciliation_apex_EXT869_CashActivity.ProcessDate`** via TVF **`CONVERT(nvarchar(8), … ,112)`**. Full **`TRUNCATE` reload** rewinds historical partitions daily (not **`DELETE WHERE DateID=@dt`** semantics). (Tier 2 — Sodreconciliation.apex.EXT869_CashActivity) |
| 2 | Date | date | YES | Calendar **`ProcessDate`** from same **`External_Sodreconciliation_apex_EXT869_CashActivity`** payload surfaced through **`Function_MIMO_Options_Platform`**. (Tier 2 — Sodreconciliation.apex.EXT869_CashActivity) |
| 3 | RealCID | int | YES | Global Real Customer Identifier on the ledger row (`fca.RealCID`). (Tier 1 — Customer.CustomerStatic) |
| 4 | MIMOAction | varchar(20) | YES | Stable label `'Deposit'` or `'Withdraw'` from UNION halves. Options path swaps TP UNION halves for Apex `CASE` on **`PayTypeCode`** **`C`**/**`D`** inside **`Function_MIMO_Options_Platform`**, emitting the same DDR-facing literals. (Tier 2 — Function_MIMO_Options_Platform) |
| 5 | OrigIdentifier | varchar(20) | YES | Hardcoded `'ApexTxID'` in source facts (coerced Transactions may null out downstream AllPlatforms merges). **`BI_DB_ddr…AllPlatforms`** quotes this verbatim in consolidated Element glossary. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |
| 6 | TransactionID | varchar(50) | YES | Apex cash **`ACATSControlNumber`** carried as alphanumeric **`varchar`**. Consolidated ingest applies **`SP_DDR_Fact_Fact_MIMO_AllPlatforms` literal `0 AS TransactionID`** with comment *cannot use the varchar it will break current schemas on move to lake.* — reconcile broker keys **only while still in this CCI fact.** (Tier 2 — Sodreconciliation.apex.EXT869_CashActivity) |
| 7 | AmountUSD | decimal(16,6) | YES | **`ABS(Amount)`** from Apex **`EXT869`** cash postings after ACH/withdraw/journal filter stack — **deposit & withdraw retain positive magnitude** (**sign semantics differ from **`BI_DB_DDR_Fact_MIMO_eMoney_Platform`** negatives** — filter on **`MIMOAction`**). (Tier 2 — Sodreconciliation.apex.EXT869_CashActivity`) |
| 8 | AmountOrigCurrency | decimal(16,6) | YES | Loader duplicates **`AmountUSD`** (`AmountOrigCurrency = AmountUSD`) enforcing **USD bookkeeping** symmetry for DDR UNION schema — **no multi-ccy fidelity** persisted. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform`) |
| 9 | FundingTypeID | int | YES | **`0` literal on INSERT (`0 AS FundingTypeID`) despite TVF-coded rail hints (`42`=Omni journal, `29`=ACH, `2`=wire per CASE). Function emits richer codes but loader zeroes **for UNION compatibility** (**100% persisted zero** MCP 2026-05-14). Analyst decode requires TVF/external, not CCI column. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform`) |
| 10 | CurrencyID | int | YES | Primary key. Universal instrument identifier. 0=NULL placeholder, 1-8=major forex currencies, ~1000+=stocks (AAPL, GOOG, etc.), ~100000+=crypto (BTC, ETH). Referenced by virtually all DWH fact tables. Legacy name: eToro originated as forex-only. DDR loader forces literal **`CurrencyID = 1`** (USD Apex book; no **`Dim_Currency` join**) matching the **`Dictionary.Currency` major-key semantics** for **`1 = USD/EUR majors bucket`**. (Tier 1 — Dictionary.Currency) |
| 11 | Currency | varchar(20) | YES | **`'USD'` constant** injected by `SP_DDR_Fact_MIMO_Options_Platform` (no runtime `Dim_Currency` join) — aligns with Dictionary/Currency shorthand for **`CurrencyID = 1`**. Parallels `Dim_Currency.Abbreviation` usage on sibling MIMO tables but materialized SP-side. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |
| 12 | IsFTD | int | YES | Platform Options **FINRA-assisted first deposit** flag from **`CASE WHEN FinalFTD.TransactionID IS NOT NULL THEN 1 ELSE 0 END`** (see **`FINRAONLY_FTD_records`/`FTDSingle`/`FTDMultiple` CTEs**). Distribution snapshot: **`1 189`** flagged rows MCP 2026-05-14. (Tier 2 — Function_MIMO_Options_Platform`) |
| 13 | IsGlobalFTD | int | YES | Outputs **`ISNULL(gftd.IsGlobalFTD, 0)`** after **`GLOBAL_FTD` LEFT JOIN`: deposit tuple must match **`Dim_Customer`** `FirstDepositAmount` / `CAST(FirstDepositDate AS date)` while **`FirstDepositDate ≥ 20250901`** and **`FTDPlatformID = 2`** (**`DEPOSIT_UNIQUE_FOR_FTDJOIN`** supplies candidate deposits). MCP snapshot (**2026-05-14**): **`699`** rows with **`IsGlobalFTD = 1`**. (Tier 2 — Function_MIMO_Options_Platform`) |
| 14 | IsInternalTransfer | int | YES | Omni/internal journal discriminator `CASE WHEN ca.TerminalID = 'OMJNL' THEN 1 ELSE 0` inside **`Function_MIMO_Options_Platform`** (**~63%** of rows MCP 2026-05-14). **Not** TP `FundingTypeID = 33` billing semantics — persists alongside loader-zeroed **`FundingTypeID`** (§2.3). (Tier 2 — Function_MIMO_Options_Platform) |
| 15 | UpdateDate | datetime | YES | ETL watermark `GETDATE()` on INSERT. (Tier 2 — SP_DDR_Fact_MIMO_Options_Platform) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Immediate Synapse Inputs | Notes |
|----------------|-------------------------|-------|
| DateID / `[Date]` | `External_Sodreconciliation_apex_EXT869_CashActivity.ProcessDate` | TVF derives `YYYYMMDD` partition int |
| RealCID | `External_USABroker_Apex_Options.GCID → Dim_Customer.RealCID` | Customer master join footprint |
| MIMOAction / AmountUSD / IsInternalTransfer | Same external cash payload | ACH / WRD / Omni journal filters |
| IsFTD / IsGlobalFTD | TVF ladders + **`Dim_Customer` FTD fields (`FTDPlatformID = 2`)** | See §2.2 narrative |
| OrigIdentifier / FundingTypeID / Currency* / AmountOrigCurrency | `SP_DDR_Fact_MIMO_Options_Platform` literals | Union-friendly normalization |

Upstream documentation pointers: **`knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Apex/Tables/Apex.Options.md`**; sibling **`BI_DB_DDR_Fact_MIMO_AllPlatforms.md`**, **`BI_DB_DDR_Fact_MIMO_Trading_Platform.md`**, **`Function_Revenue_TransferCoinFee`** (cross-surface narrative for **`IsRedeem`** absent here).

### 5.2 ETL Pipeline

```
Sodreconciliation.apex.EXT869_CashActivity (Production)
 -> Generic Pipeline (Append / parquet daily)
 -> Bronze/* → External_Sodreconciliation_apex_EXT869_CashActivity

USABroker.apex.Options (Production)
 -> Generic Pipeline (Override / parquet daily)
 -> External_USABroker_Apex_Options

DWH Dim_Customer + Fact_SnapshotCustomer (TVF filter context)
 -> BI_DB_dbo.Function_MIMO_Options_Platform(@s,@e,OnlyValidCustomers)
 -> #fromfunc HASH(RealCID)
 -> BI_DB_dbo.SP_DDR_Fact_MIMO_Options_Platform (TRUNCATE + INSERT literals)
 -> BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform (~105K rows MCP 2026-05-14)

Downstream merges:
 BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms (DELETE Options + INSERT 0 TransactionID literals)
 BI_DB_dbo.SP_DDR_Customer_Daily_Status (DDR customer panels)
 Nominal UC: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_options_platform (Databricks export **not verified** MCP 2026-05-14)
```

```text
UPSTREAM SEARCH LOG — BI_DB_DDR_Fact_MIMO_Options_Platform:
  Lineage objects (see .lineage.md):
    1. External_Sodreconciliation_apex_EXT869_CashActivity
       (a) Local Synapse DDL: EXISTS (SSD external table READ)
       (b) Routing wiki Sodreconciliation.apex.* — knowledge/ProdSchemas scan → EXT869 wiki NOT_FOUND (Read skipped)
       Effective upstream: finance.bronze_sodreconciliation_apex_ext869_cashactivity (generic pipeline)
    2. External_USABroker_Apex_Options / USABroker.apex.Options
       (a) Apex.Options.md → FOUND (Read YES) under knowledge/ProdSchemas/ComplianceDBs/USABroker/Wiki/Apex/Tables/Apex.Options.md
       Effective upstream: general.bronze_usabroker_apex_options parquet + wiki context
    3. DWH_dbo.Dim_Customer → FOUND Dim_Customer.md (Read YES) — FTD + RealCID excerpts
    4. DWH_dbo.Fact_SnapshotCustomer → FOUND Fact_SnapshotCustomer.md (Read YES header) — valid-customer semantics (TVF only)
    5. BI_DB_dbo.Function_MIMO_Options_Platform.sql — SSD READ (fact logic)
    6. Canonical sibling wikis: BI_DB_DDR_Fact_MIMO_Trading_Platform.md → FOUND Read YES ; BI_DB_DDR_Fact_MIMO_eMoney_Platform.md → FOUND Read YES ; BI_DB_DDR_Fact_MIMO_AllPlatforms.md → FOUND Read YES ; Dim_Currency.md → FOUND (CurrencyID verbatim) ;
  Columns inheriting verbatim / aligned semantics vs siblings:
    RealCID (Trading §4 verbatim), CurrencyID baseline text (Dim_Currency / eMoney), MIMOAction phrasing anchored on Trading UNION language, TransactionID caveat cross-links AllPlatforms excerpt
  Tier-1-eligible fields honored: RealCID (+ Dictionary.Currency text for CurrencyID with loader literal note)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | `DWH_dbo.Dim_Customer` | Canonical customer enrichment |
| CurrencyID | `DWH_dbo.Dim_Currency` | Optional decode (**always major key `1`**) |
| (implicit GCID linkage) | `BI_DB_dbo.External_USABroker_Apex_Options` | Enrollment / Apex account bridging |

### 6.2 Referenced By

| Consumer | Notes |
|----------|-------|
| `BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms` | Daily **`DELETE`** `MIMOPlatform='Options'` **+ INSERT** (**`TransactionID`** forced **`0`**) |
| `BI_DB_dbo.SP_DDR_Customer_Daily_Status` | DDR-facing customer rollup reference |

---

## 7. Sample Queries

### 7.1 Options deposit vs withdrawal trend
```sql
SELECT DateID, MIMOAction, COUNT(*) AS rows_cnt, SUM(AmountUSD) AS amt_usd
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform
WHERE DateID BETWEEN 20260101 AND 20260331
GROUP BY DateID, MIMOAction
ORDER BY DateID DESC, MIMOAction;
```

### 7.2 Internal journal-heavy customers
```sql
SELECT TOP 50 RealCID, SUM(CASE WHEN IsInternalTransfer=1 THEN 1 ELSE 0 END) AS omj_rows, COUNT(*) AS all_rows
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform
WHERE DateID >= 20250101
GROUP BY RealCID
ORDER BY omj_rows DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Knowledge captured |
|--------|------|-------------------|
| [DDR Tables](https://etoro-jira.atlassian.net/wiki/spaces/~164971827/pages/13596884995/DDR+Tables) | Confluence | Enumerates DDR MIMO table families incl. consolidated vs per-platform |
| [PRD: Genie Space — MIMO (Money In / Money Out)](https://etoro-jira.atlassian.net/wiki/spaces/BIA/pages/14330691721/PRD+Genie+Space+MIMO+Money+In+Money+Out) | Confluence | Product rationale for **`AllPlatforms`** consumption surfaces |
| [MIMO Tables Fields](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/8599240947/MIMO+Tables+Fields) | Confluence | Legacy field inventory + terminology cross-check (**Options/Apex nuances still require SSDT grounding**) |

Phase 10 CQL **`text ~ "MIMO" AND text ~ "Options"`** surfaced **164** loosely scored hits (2026-05-14); prioritized curated trio above versus noisy ops procedures.

---

*Generated: 2026-05-14 | Quality: provisional 8.2/10 (Phase 16 — see parent deliverables) | Phases: Structure 1, Live MCP 2, Distribution 3, Lookup 4, JOIN 5 skipped (TVF-internal), Biz 6 heuristic, Views 7 none surfaced, SP-scan 8, SP-logic 9, ETL orch 9B soft-unresolved OpsDB lookup, Atlas 10, Lineage10B ✅, Doc 11*  
*Tiers: 2 T1, 13 T2, 0 T3, 0 T4, 0 T5 | Elements: 15/15, Logic: 9/10, Relationships: 7/10, Sources: 8/10*  
*Object: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform | Writer SP: BI_DB_dbo.SP_DDR_Fact_MIMO_Options_Platform*
