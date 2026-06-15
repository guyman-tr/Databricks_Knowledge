# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms

> ~95.4M-row Synapse MIMO (**Money-In / Money-Out**) fact unifying **`TradingPlatform`**, **`eMoney`**, **`Options`**, and synthetic **`MoneyFarm`** FTD rows from `Function_MIMO_First_Deposit_All_Platforms`, keyed by **`DateID`** on **HASH(`RealCID`)** CCI (`sys.partitions` row sum **95 381 704**); history **20070827–20260425** (daily partition refresh via `DELETE`/`INSERT`). Primary writer **`SP_DDR_Fact_Fact_MIMO_AllPlatforms`**.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Indirect union of `BI_DB_DDR_Fact_MIMO_Trading_Platform`, `BI_DB_DDR_Fact_MIMO_eMoney_Platform`, `BI_DB_DDR_Fact_MIMO_Options_Platform`, plus **`Function_MIMO_First_Deposit_All_Platforms`**‑driven **`MoneyFarm`** slice |
| **Refresh** | Daily — `MERGE`-exported Gold table (**1440** min cadence); `DELETE`/scoped reload per platform rules inside `SP_DDR_Fact_Fact_MIMO_AllPlatforms` |
| | |
| **Synapse Distribution** | HASH(`RealCID`) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | **`main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms`** (**`DESCRIBE` verified 2026‑05‑14**; matches **`_generic_pipeline_mapping.json`** `uc_table`) |
| **UC Format** | delta |
| **UC Partitioned By** | `etr_y`, `etr_ym`, `etr_ymd` (Databricks-only surrogate keys appended on export — **absent from Synapse DDL**) |
| **UC Table Type** | Managed/external Gold mirror (**Merge** strategy) |

---

## 1. Business Meaning

`BI_DB_DDR_Fact_MIMO_AllPlatforms` is the **DDR (Daily Data Report) cross-platform ledger** combining platform-specific DDR MIMO tables into one CCI fact so analysts filter by `MIMOPlatform` while sharing the same numeric schema. Two FTD notions coexist: **`IsPlatformFTD`** (**first-ever deposit per platform lineage**) inherits each sibling fact’s **`IsFTD`** semantics (`FTDPlatformID` 1=TP, 3=eMoney, etc.). **`IsGlobalFTD`** answers whether a **deposit row** aligns with **`Function_MIMO_First_Deposit_All_Platforms`** (TVF parameterized `@OnlyValidCustomers = 0` inside **`#globalFTDs`**) keyed on **`DepositID`/`RealCID`/`FTDPlatformID` matches**.

The Trading + eMoney population for a **`@date`** partition is **`DELETE … WHERE DateID=@dateID`**, **`INSERT`** from **`#final`** merging **`#globalMIMO`** (**`#TP_Mimo` UNION ALL `#IBAN_Mimo`**) with a **`LEFT JOIN`** to **`#globalFTDs`**. **Options** data are **daily `DELETE WHERE MIMOPlatform='Options'` plus full INSERT** sourced from **`BI_DB_DDR_Fact_MIMO_Options_Platform`** (best‑effort feed). **`MoneyFarm`** adds **FTD‑only deposits** synthesized from **`#globalFTDs WHERE FTDPlatform='MoneyFarm'`** with explicit GBP placeholders. Post-insert **`UPDATE`** blocks recover latent FTDs (eMoney `>=20250901`, TradingPlatform `>=20250901`) and uplift **`IsCryptoToFiat`** when **`FundingTypeID=27`** on TP deposits (**`>=20250701`**).

Representative **`MIMOPlatform` counts** (**Synapse MCP**): **`WHERE DateID >= 20260101 AND DateID < 20260201` GROUP BY **`MIMOPlatform`** → **`TradingPlatform` 1 870 374**, **`eMoney` 1 773 732**, **`Options` 3 723**, **`MoneyFarm` 644**.

---

## 2. Business Logic

### 2.1 `MIMOPlatform` literals (UNION source of truth)

**What**: Discriminator values are **not** looked up — they are **hard-coded literals** in the SP.
**Columns Involved**: `MIMOPlatform`
**Rules**:
- Trading branch sets `'TradingPlatform'` (`#globalMIMO` SELECT from `#TP_Mimo`).
- eMoney branch sets `'eMoney'`.
- Options **reinsert** uses `'Options'` literal.
- MoneyFarm **`#moneyfarmFTDs`** uses `'MoneyFarm'`.

### 2.2 Dual FTD semantics (`IsPlatformFTD` vs `IsGlobalFTD`)

**What**: **`IsPlatformFTD`** relays sibling fact **`IsFTD`** (**`CASE WHEN … THEN IsFTD AS IsPlatformFTD`** in `#final`). **`IsGlobalFTD`** is **`CASE WHEN f.RealCID IS NOT NULL THEN 1 ELSE 0`** after **`LEFT JOIN #globalFTDs f`** with **`m.MIMOAction='Deposit'` AND `m.IsFTD = 1` AND matched `FTDPlatformID`**.
**Columns Involved**: `IsPlatformFTD`, `IsGlobalFTD`, `MIMOAction`
**Rules**:
- **Options INSERT bypass** uses **`bddfmop.IsGlobalFTD`** directly (**second INSERT block** — no `#globalFTDs` join inside that INSERT).
- **MoneyFarm slice** carries **`IsGlobalFTD = 1`** synthetic rows (**all rows originate from **`#globalFTDs`****) while still flagging **`IsPlatformFTD = 1`**.
- **Recovery UPDATEs** (late-arriving **`Dim_Customer`** / **`eMoney_Fact_Transaction_Status`** evidence) coerce both flags **to 1** when join predicates hit.

### 2.3 `IsRedeem` & transfer‑to‑coin alignment

**What**: Consolidated **`IsRedeem`** applies **`ISNULL(f.IsRedeem,0)`** in the main **`INSERT`** sourced from **`#final`**, which itself passes through Trading (`tm.IsRedeem`) vs eMoney (`im.IsRedeem` — factically always **0** placeholder) before **Options/MoneyFarm literals** force **0**.
**Columns Involved**: `IsRedeem`, `MIMOAction`, `MIMOPlatform`
**Rules**:
- **Never document** outdated “bank redemption” shorthand — transfer‑to‑coin semantics are grounded in **`Function_Revenue_TransferCoinFee`** ( **`ActionTypeID = 30` ∧ `IsRedeem = 1`** fee slice ).
- Detailed narrative **verbatim** retained in **`§4 Elements` row **`IsRedeem`** (Element #14 **`BI_DB_DDR_Fact_MIMO_Trading_Platform.md`** text).

### 2.4 MoneyFarm & Options literal substitutions (**Phase 9 excerpts**)

**What**: Dedicated branches coerce schema for lake merge friendliness (**per SP comments 2025‑10 / 2025‑11**).
**Columns Involved**: Booleans / numeric sentinels on synthetic MoneyFarm deposits; deterministic zeros on Options re-load.
**Rules** (**verbatim excerpts from **`BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms` SQL** SSDT `/ Synapse`**):

MoneyFarm **`#moneyfarmFTDs`** select list (excluding join keys echoed downstream):

```
	 , 0 AS TransactionID -- cannot use the varchar it will break current schemas on move to lake.
	 , gf.FirstDepositAmount AS AmountUSD
	 , -1 AS AmountOrigCurrency
	 , -1 AS FundingTypeID
	 , 3 AS CurrencyID
	 , 'GBP' AS Currency
	 , 1 AS IsPlatformFTD
	 , 0 AS IsInternalTransfer
	 , 0 AS IsRedeem
	 , 0 IsTradeFromIBAN
	 , 'MoneyFarm' AS MIMOPlatform
	 , 1 AS IsGlobalFTD
	 , @updatedate AS UpdateDate
	 , 0 AS IsCryptoToFiat
	 , 0 AS IsRecurring
	 , 0 AS IsIBANQuickTransfer
FROM #globalFTDs gf
WHERE gf.FTDPlatform = 'MoneyFarm'
```

☞ **Correction vs legacy wording**: **MoneyFarm FTD rows are NOT “all booleans hard-coded 0”—`IsPlatformFTD`/`IsGlobalFTD` literals are **`1`**; operational placeholders (`IsInternalTransfer`, **`IsRedeem`**, **`IsTradeFromIBAN`**, **`IsCryptoToFiat`**, **`IsRecurring`**, **`IsIBANQuickTransfer`**) **`0`**; monetary / dimension sentinels use **`-1` / `GBP` / `CurrencyID=3`**.

Options **second INSERT** literals:

```
SELECT bddfmop.DateID
...
	 , 0 AS TransactionID -- cannot use the varchar it will break current schemas on move to lake.
...
	 , 0 AS IsRedeem
	 , 0
	 , 'Options' AS MIMOPlatform
...
	 , 0
	 , 0
	 , 0
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform bddfmop
```

(Second **`0`** column pair = **`IsTradeFromIBAN`**, **`IsCryptoToFiat`** / **`IsRecurring`** / **`IsIBANQuickTransfer`** per column order in INSERT list.)

Supporting **`UPDATE`** prior to **`INSERT`**:

```
UPDATE #final
SET TransactionID = NULL
WHERE MIMOPlatform = 'Options'
```

### 2.5 Crypto-to-fiat uplift for Trading deposits

**What**: Overrides **`IsCryptoToFiat`** on TP crypto-wallet deposit funding (**`FundingTypeID=27`**), effective **July 2025+**.

```
UPDATE BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms
SET IsCryptoToFiat = 1
WHERE DateID >= 20250701
AND MIMOPlatform = 'TradingPlatform'
AND MIMOAction = 'Deposit'
AND FundingTypeID = 27
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

In **Synapse** the table is **HASH‑distributed on `RealCID`** with a **CCI**. Always constrain **`RealCID`** and **`DateID`** to avoid full **~95M**‑row scans (`sys.partitions`).

### 3.1b UC (Databricks) Storage & Partitioning

**Databricks `DESCRIBE` (2026‑05‑14)** shows **partition surrogates `etr_y` / `etr_ym` / `etr_ymd`** appended for Gold exports (**not modeled in Synapse DDL**); filter partitions when querying UC‑native copies.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Cross‑platform totals by day | `WHERE DateID=@d GROUP BY DateID,MIMOPlatform,MIMOAction` |
| Isolate IBAN‑initiated trades | `WHERE IsTradeFromIBAN=1` (meaning differs TP vs eMoney — see **`IsIBANQuickTransfer`**) |
| Global vs platform FTDs | Compare **`IsPlatformFTD`** vs **`IsGlobalFTD`** (**limit to `MIMOAction='Deposit'`** when interpreting **`IsGlobalFTD`**) |
| Options-only slice | **`WHERE MIMOPlatform='Options'`** — **`TransactionID` forced `0`/NULL coercion** upstream |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_Customer` | `RealCID` | Geography / regulation |
| `DWH_dbo.Dim_FundingType` | `FundingTypeID` | Decode funding channel (**sentinel `-1`** = MoneyFarm placeholder) |
| `DWH_dbo.Dim_Currency` | `CurrencyID` | Currency metadata (**MoneyFarm CurrencyID = 3**) |
| `BI_DB_ddr…MIMO_Trading_Platform` / `_eMoney_Platform` | `DateID`,`RealCID`,`TransactionID`,`MIMOPlatform` | Drill‑down from unified to native facts |

### 3.4 Gotchas

- **`TransactionID`** on **Options** is **`NULL`/0 coercion** (**lake schema guard**); **`MoneyFarm`** uses **`TransactionID`** literal **`0`** / outer **`ISNULL(...,-1)`** — **semantic keys degrade** vs TP/eMoney.
- **`OrigIdentifier`** **values diverge**: TP uses **`DepositID`** vs **`WithdrawPaymentID`** text; **eMoney** emits literal **`TransactionID`** (confirmed live sample rows **April 2026**); **MoneyFarm** **`DepositID`**; **Options source facts **`ApexTxID`** before **lake‑friendly** truncation.
- **Do not confuse `IsGlobalFTD` logic** across **main merge** vs **`Options`** second INSERT (**different code paths**).
- **Partition exports**: UC shows **six extra partition metadata rows** versus Synapse DDL — lineage drift flagged in **`BI_DB_DDR_Fact_MIMO_AllPlatforms.review-needed.md`**.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Typical meaning |
|-------|------|-----------------|
| ★★★★ | Tier 1 | Canonical dimension / ledger wiki origin (tier tag preserved) |
| ★★★ | Tier 2 | Stored procedure / UNION / sentinel injection |
| ★ | Tier 4 | Inference / ambiguity — see review sidecar |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Ledger business date partition key duplicated from `@date`. `CAST(CONVERT(varchar(8),@date,112) AS int)` seeded into `#depositsTP`/`#cashoutTP`, carried through UNION. DELETE partition uses same `@dateID`. **AllPlatforms transforms:** `#globalMIMO` passes sibling `DateID`; MoneyFarm uses `CAST(FORMAT(gf.FirstDepositDate,'yyyyMMdd') AS int)` from **`#moneyfarmFTDs`**. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 2 | Date | date | YES | Calendar counterpart to `DateID`; **`INSERT`** uses `@date AS [Date]` for **`#final` rows**; **`MoneyFarm`** uses `CAST(gf.FirstDepositDate AS date)`. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 3 | RealCID | int | YES | Global Real Customer Identifier on the ledger row (`fca.RealCID`). (Tier 1 — Customer.CustomerStatic) |
| 4 | MIMOAction | varchar(100) | YES | Stable label `'Deposit'` or `'Withdraw'` from UNION halves. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 5 | OrigIdentifier | varchar(100) | YES | **Trading Platform (verbatim Element #5 `BI_DB_DDR_Fact_MIMO_Trading_Platform.md`):** Literal discriminator `'DepositID'` vs `'WithdrawPaymentID'` aligning `TransactionID` grain. **eMoney (verbatim Element #5 `BI_DB_DDR_Fact_MIMO_eMoney_Platform.md`):** Source ID type label — Always `'TransactionID'` for all eMoney transactions. **Options (verbatim Element #5 `BI_DB_DDR_Fact_MIMO_Options_Platform.md`):** Hardcoded `'ApexTxID'` in source facts (coerced Transactions may null out). **MoneyFarm (SP literals):** `'DepositID'` inside `#moneyfarmFTDs`. (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) |
| 6 | TransactionID | int | YES | `DepositID` for deposits (`ActionTypeID` 7/44) OR `WithdrawPaymentID` for withdraw rows (`ActionTypeID` 8/45). ROW_NUMBER dedupe trims duplicate `(MIMOAction, TransactionID)` pairs (`BI_DB_DDR_Fact_MIMO_Trading_Platform` lineage baseline). **AllPlatforms transforms:** `CAST(f.TransactionID AS varchar(50))` persisted into `INT` from `#final`; `UPDATE #final SET TransactionID=NULL WHERE MIMOPlatform='Options'`; Options **`INSERT`** uses literal `0 AS TransactionID`; MoneyFarm literals `0` with outer **`isnull(TransactionID,-1)`** guard. **Not all platforms joinable naïvely.** (Tier 2 — Fact_CustomerAction) |
| 7 | AmountUSD | decimal(16,6) | YES | `fca.Amount` from `Fact_CustomerAction WHERE ActionTypeID IN (7,44)` (deposits) or `IN (8,45)` (withdrawals) at `@dateID`. **AllPlatforms:** passthrough **`#final`** (see sibling facts); **`MoneyFarm`** uses `gf.FirstDepositAmount` (**`#moneyfarmFTDs`**). **eMoney negatives** retained from sibling negatives for withdrawals (**see **`BI_DB_DDR_Fact_MIMO_eMoney_Platform.md §2.5`**)**. (Tier 2 — Fact_CustomerAction) |
| 8 | AmountOrigCurrency | decimal(16,6) | YES | Deposit: `fbd.Amount`. Withdraw: `COALESCE(bddwf.Amount, ROUND( ROUND(fbw.Amount_WithdrawToFunding,6) / NULLIF(ROUND(fbw.ExchangeRate,6),0), 6))` with joins defined in `#cashoutTP`. **MoneyFarm sentinel `-1`** (no original-ccy fidelity in synthetic FTD stitch). Options equals USD per sibling fact. **(Tier 2 — Fact_BillingDeposit / Fact_BillingWithdraw)** |
| 9 | FundingTypeID | int | YES | Deposit: `fbd.FundingTypeID`. Withdraw: `fbw.FundingTypeID_Funding`. Type of funding instrument powering the payout leg. Deposit description reference: Fact_BillingDeposit column #17 semantics. Withdraw description reference: `FundingTypeID_Funding` semantics in `Fact_BillingWithdraw`. **`MoneyFarm` sentinel `-1`**. **`Options`** generally `0`. **Tier attribution preserved from TP wiki mix.** **(Tier 2 — Fact_BillingDeposit / Billing.Funding)** |
| 10 | CurrencyID | int | YES | Deposit: `fbd.CurrencyID` — “Currency of the deposit amount…” (Billing upstream). Withdraw: `fbw.ProcessCurrencyID` — “Currency used for the actual payment processing…” (Billing.WithdrawToFunding upstream). Same column merges both semantics via SP branch. **`MoneyFarm` literal `3`**. **`Options`** **`1`** (USD). **(Tier 1 — upstream wiki, Billing.Deposit / Billing.WithdrawToFunding)** |
| 11 | Currency | varchar(20) | YES | Ticker symbol (`dc.Abbreviation`) joined on `CurrencyID`/`ProcessCurrencyID`. `"USD","EUR"` forex; equities/crypto codes per dictionary. Passthrough from `Dim_Currency`. **`MoneyFarm` literal `'GBP'`**. **(Tier 1 — Dictionary.Currency)** |
| 12 | IsPlatformFTD | int | YES | **`IsFTD` relay from sibling facts surfaced as **`IsPlatformFTD` in **`#final` (`m.IsFTD AS IsPlatformFTD`) with `INSERT ISNULL(IsPlatformFTD,0)`.** Recoveries per SP blocks **JOIN `Dim_Customer` / `eMoney_Fact_Transaction_Status` when `DateID>=20250901`.** Interpret per-platform using sibling docs (**`TradingPlatform`** vs **`eMoney`** **`FTDPlatformID` expectations** vs **`MoneyFarm` synthetic **`1`**). **(Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms)** |
| 13 | IsInternalTransfer | int | YES | `CASE WHEN FundingTypeID = 33 THEN 1 ELSE 0` (deposit branch on `fbd.FundingTypeID`; withdraw branch on `fbw.FundingTypeID_Funding`). Mirrors IBAN/quick-transfer interplay described in changelog. **`INSERT ISNULL`; Options inherits `bddfmop.IsInternalTransfer`; MoneyFarm literal `0`.** **(Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform)** |
| 14 | IsRedeem | int | YES | **Transfer-to-coin / transfercoin flag on Money-Out.** Withdraw leg reads `fca.IsRedeem` with `WHERE fca.ActionTypeID IN (8,45)`. Deposit UNION hard-codes literal `0` after `#depositsTP` seeded `NULL`. INSERT applies `ISNULL(IsRedeem,0)`. Interpret `1` as customer movement from TP fiat wallet into on-chain/crypto custody—not “redeem to bank.” Cross-surface: revenue TVF **`Function_Revenue_TransferCoinFee`** documents `Fact_CustomerAction` rows **`ActionTypeID = 30` AND `IsRedeem = 1`** for TransferCoinFee commissions tied to transfercoin redemption. (Tier 2 — Fact_CustomerAction) |
| 15 | IsTradeFromIBAN | int | YES | Deposit: `CASE WHEN fca.ActionTypeID = 44 THEN 1 ELSE 0`; Withdraw: `CASE WHEN fca.ActionTypeID = 45 THEN 1 ELSE 0`. Flags sweep-style IBAN internal deposit/withdraw events. **AllPlatforms mapping:** **`f.IsIBANTrade` from **`#final`** (`tm.IsIBANTrade` ∪ `im.IsTradeFromIBAN`) with **`INSERT ISNULL(f.IsIBANTrade,0)` targeting column `IsTradeFromIBAN`.** **Options / MoneyFarm literal `0`.** **(Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform)** |
| 16 | MIMOPlatform | varchar(20) | YES | **ETL literals** `'TradingPlatform'`, `'eMoney'`, `'Options'`, `'MoneyFarm'` (see §2.1). Jan‑2026 sample distribution on single day partition enumerated in §1. **(Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms)** |
| 17 | IsGlobalFTD | int | YES | **Primary path (#final INSERT):** `CASE WHEN f.RealCID IS NOT NULL THEN 1 ELSE 0` after `LEFT JOIN #globalFTDs f` on **`m.MIMOAction='Deposit' AND m.RealCID=f.RealCID AND m.IsFTD=1 AND m.FTDPlatformID=f.FTDPlatformID`** where **`f` originates from **`BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms(0)`** ( **`#globalFTDs`** ). **MoneyFarm synthetic rows forced `1`.** **`INSERT ISNULL` + recovery UPDATE overlays.** **`Options`** second INSERT **`SELECT bddfmop.IsGlobalFTD` (no `#globalFTDs` JOIN in that block). Interpret per **`Function_MIMO_First_Deposit_All_Platforms` §1 business meaning**: date‑routed spine across IBAN / TP extracts with **`REMOVE_BAD_FTDS`** handling. **(Tier 2 — Function_MIMO_First_Deposit_All_Platforms / SP_DDR_Fact_Fact_MIMO_AllPlatforms)** |
| 18 | UpdateDate | datetime | YES | ETL watermark `GETDATE()` on INSERT. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 19 | IsCryptoToFiat | int | YES | Explicit literal `0` — reserved column (C2F captured on other DDR MIMO siblings). `INSERT SELECT … , 0 AS IsCryptoToFiat`. **PLUS `UPDATE`** sets **`1`** for **`FundingTypeID=27` TP deposits `DateID>=20250701` (see §2.5). **eMoney** uses **`TxTypeID=14`** per sibling (**`BI_DB_ddr…eMoney`**). **`Options`/MoneyFarm forced `0` on insert.** **(Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform)** |
| 20 | IsRecurring | int | YES | `1=deposit is part of a recurring schedule (OUTER APPLY on Billing.RecurringDeposit). 0=one-time deposit.` carries only on deposit UNION; `'Withdraw'` half injects literal `0`. Final `INSERT` uses `ISNULL(t.IsRecurring,0)`. **`Options`/MoneyFarm insert literal `0`.** **eMoney sibling remains placeholder zeros.** **(Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse)** |
| 21 | IsIBANQuickTransfer | int | YES | Internal transfer discriminator `CASE WHEN fca.MoveMoneyReasonID = 6 THEN 1 ELSE 0` on both halves (SP changelog `20250611`). **AllPlatforms** `INSERT` applies `ISNULL`; **Options** / **MoneyFarm** literals `0`. **eMoney** wiring caveat: sibling fact still hard‑codes **`0`** — enrichment may occur only downstream — cross‑check **`BI_DB_DDR_Fact_MIMO_eMoney_Platform.md` §3.4**. **(Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform)** |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Story | Immediate Synapse Inputs | Transform |
|----------------|-----------------|----------------------------|-----------|
| Core ledger keys/measures | Billing + Customer + History ingestion | **`BI_DB_ddr…MIMO_*`** sibling facts | Union + sentinel fills |
| Global FTDs | **`Function_MIMO_First_Deposit_All_Platforms`** | **`#globalFTDs` temp** | **`LEFT JOIN` / MoneyFarm synth |
| Options platform | Apex cash ingest | **`BI_DB_ddr…Options_Platform`** | Secondary INSERT + deterministic zeros |

### 5.2 ETL Pipeline

```
BI_DB_ddr…MIMO_Trading_Platform  ─┐
BI_DB_ddr…MIMO_eMoney_Platform   ─┼─► #globalMIMO ► LEFT JOIN #globalFTDs (TVF output)
                                  │
BI_DB_ddr…MIMO_Options_Platform ◄─┴── separate DELETE + INSERT (+ NULL TransactionID coercion)
MoneyFarm synth rows (#moneyfarmFTDs, filtered gf.FTDPlatform='MoneyFarm')
         │        daily SP_DDR_Fact_Fact_MIMO_AllPlatforms
         ▼
BI_DB_ddr…AllPlatforms (~95M rows Synapse CCI)
        │ Generic Pipeline Merge (daily)
        ▼
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms (+ etr_* partitions)
```

| Step | Object | Notes |
|------|--------|------|
| 1 | Sibling **`MIMO_*`** tables | Already DDR-scrubbed feeds |
| 2 | **`Function_MIMO_First_Deposit_All_Platforms(0)`** | Cross-platform **`DepositID` join spine** (`#globalFTDs`) |
| 3 | **`SP_DDR_Fact_Fact_MIMO_AllPlatforms`** | **Multi-stage DELETE/INSERT + recovery UPDATE stack** |

```text
UPSTREAM SEARCH LOG — BI_DB_DDR_Fact_MIMO_AllPlatforms:
  Lineage source objects (from .lineage.md):
    1. BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform (TP feed)
       (a) Local wiki: knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Fact_MIMO_Trading_Platform.md → FOUND (Read YES)
       (b) Production wiki incremental via Fact_CustomerAction (not reopened here) → reliance on sibling doc
       Effective upstream: BI_DB_DDR_Fact_MIMO_Trading_Platform.md
    2. BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform
       (a) Local wiki: …/BI_DB_DDR_Fact_MIMO_eMoney_Platform.md → FOUND (Read YES)
       Effective upstream: BI_DB_DDR_Fact_MIMO_eMoney_Platform.md
    3. BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Options_Platform
       (a) Local wiki: …/BI_DB_DDR_Fact_MIMO_Options_Platform.md → FOUND (Read YES)
       Effective upstream: BI_DB_DDR_Fact_MIMO_Options_Platform.md
    4. BI_DB_dbo.Function_MIMO_First_Deposit_All_Platforms
       (a) Local wiki: …/Functions/Function_MIMO_First_Deposit_All_Platforms.md → FOUND (Read YES)
       Effective upstream: Function_MIMO_First_Deposit_All_Platforms.md
    5. eMoney_dbo.eMoney_Fact_Transaction_Status (recovery JOIN)
       (a) Local wiki search (Tables/eMoney Fact) → NOT enumerated (Ops recovery only; rely SP text)
       Effective upstream: SP recovery block only
    6. DWH_dbo.Dim_Customer (recovery JOIN)
       (a) Local wiki: knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md → KNOWN_EXISTS (prior batch standard; DIM read deferred for footprint)
       Effective upstream: Recovery subset only — full FTD semantics see Dim_Customer + Function TVF linkage
    7. DWH_dbo.Fact_CustomerAction (tier origin for redeemed flag description)
       (a) Local wiki: …/Fact_CustomerAction.md → FOUND snippets via grep earlier (dual semantics anchoring TransferCoin coupling)
       Effective upstream: Fact_CustomerAction.md corroborates ActionType 30 linkage
    8. DWH_dbo.Dim_Currency / Dim_FundingType (dictionary joins referenced in sibling wikis)
       → FOUND via sibling inheritance paths (Abbreviation / FundingType semantics)
  Tier-1-eligible columns identified in THIS table via inheritance: **`RealCID`**, **`Currency`**, **`CurrencyID`** (billing text block), foundational billing semantics mirrored from TP sibling for shared columns — remainder largely **Tier 2 union transforms**.
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| `RealCID` | `DWH_dbo.Dim_Customer` | Customer spine |
| `FundingTypeID` | `DWH_dbo.Dim_FundingType` | Decode rails (**`-1`** sentinel ignores join) |
| `CurrencyID` | `DWH_dbo.Dim_Currency` | Fiat/crypto codes (**MoneyFarm `CurrencyID=3`=GBP per SP**) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Purpose |
|---------------|---------|
| `Function_MIMO_First_Deposit_All_Platforms` | **`BI_DB_DDR_Fact_MIMO_AllPlatforms`** listed as source object in TVF doc (recursive analytics) |
| DDR panel views / Genie spaces | High-level MIMO consumption — see Confluence **`DDR Tables`** & **`PRD: Genie Space – MIMO`** |

---

## 7. Sample Queries

### 7.1 Daily platform mix vs monitoring ticket **DQT-834**

```sql
SELECT DateID,
       COUNT(*) AS RowCnt,
       SUM(AmountUSD) AS SumUsd
FROM [BI_DB_dbo].[BI_DB_DDR_Fact_MIMO_AllPlatforms]
WHERE DateID BETWEEN 20260101 AND 20260131
GROUP BY DateID
ORDER BY DateID;
```

### 7.2 Global FTD deposits that are not platform‑local anomalies

```sql
SELECT COUNT(*) AS Cnt
FROM [BI_DB_dbo].[BI_DB_DDR_Fact_MIMO_AllPlatforms]
WHERE MIMOAction = 'Deposit'
  AND IsGlobalFTD = 1
  AND IsPlatformFTD = 0
  AND DateID >= 20250901;
```

### 7.3 Transfer‑to‑coin withdraw evidence (Trading platform)

```sql
SELECT TOP 100 *
FROM [BI_DB_dbo].[BI_DB_DDR_Fact_MIMO_AllPlatforms]
WHERE MIMOPlatform = 'TradingPlatform'
  AND MIMOAction = 'Withdraw'
  AND IsRedeem = 1
  AND DateID >= 20260101;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|-------------------------|
| [DDR Tables](https://etoro-jira.atlassian.net/wiki/spaces/~164971827/pages/13596884995/DDR+Tables) | Confluence | Example SQL grouping **`MIMOPlatform`**, references **`BI_DB_ddr…AllPlatforms`** in DDR dashboard context (**`GlobalFTD` mention** snippet). |
| [PRD: Genie Space – MIMO (Money In / Money Out)](https://etoro-jira.atlassian.net/wiki/spaces/BIA/pages/14330691721/PRD+Genie+Space+MIMO+Money+In+Money+Out) | Confluence | Positions **`MIMO` fact foundation** narrative for downstream Genie. |
| [DQT‑834 DDR Monitoring Notebook](https://etoro-jira.atlassian.net/browse/DQT-834) | Jira | Monitoring **`SELECT … FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms`** sample for QA checks. |

---

*Generated: 2026-05-14 | Quality: 8.4/10 (★★★★☆) | Phases: 14/14 (incl. P16 heuristic self‑score)*  
*Tiers: 3 T1, 18 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | DDL parity: 21/21 element rows vs Synapse `INFORMATION_SCHEMA` | Logic: 10/10, Relationships: 6/10, Sources: 9/10*  
*Object: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | Type: Table | Production Source: Multi-branch BI_DB DDR facts + FTD TVF*
