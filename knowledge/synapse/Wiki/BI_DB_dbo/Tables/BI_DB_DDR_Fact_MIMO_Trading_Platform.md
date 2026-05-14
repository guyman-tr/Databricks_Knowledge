# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform

> ~68.6M-row (Synapse `sys.partitions`) transaction-level DDR MIMO fact for the Trading Platform covering daily Money-In (`ActionTypeID` 7, 44) and Money-Out (`ActionTypeID` 8, 45) sourced from `DWH_dbo.Fact_CustomerAction` with billing enrichment, deduped unions, FTD coercion from `Dim_Customer`, assembled by `SP_DDR_Fact_MIMO_Trading_Platform` (`DELETE`/INSERT per `DateID`; `SB_Daily`). History spans DateID **20070827** through loads through **April 2026** (UpdateDate watermark sample).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (DDR MIMO — Trading Platform) |
| **Production Source** | Indirect multi-source billing/credit lineage — `Fact_CustomerAction`, `Fact_BillingDeposit`, `Fact_BillingWithdraw`, `Dim_Currency`, `Dim_Customer`, `BI_DB_DepositWithdrawFee` |
| **Refresh** | Daily — OpsDB orchestration `SB_Daily` feeds `BI_DB_dbo.SP_DDR_Fact_MIMO_Trading_Platform` `@date`; `DELETE BI_DB_ddr… WHERE DateID=@dateID` then `INSERT` + optional FTD `UPDATE` |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform` — **Databricks read not verified this session** (try `SHOW TABLES IN main.bi_db LIKE '*ddr*mimo*'`) |
| **UC Format** | delta (typical BI_DB gold export pattern) |
| **UC Partitioned By** | _Not enumerated here — rely on `_generic_pipeline_mapping.json` / live UC metadata_ |
| **UC Table Type** | Managed / EXTERNAL per environment mapping |

---

## 1. Business Meaning

`BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform` is the **DDR (Daily Data Report) Money-In/Money-Out capture for the Trading Platform (TP)**. Each row is one deposit-or-withdraw ledger hit on `@date`: external deposits (`ActionTypeID` 7), IBAN-linked internal deposits / sweeps (`44`), outbound cashouts (`8`), IBAN internal withdrawals (`45`). Amounts expose both ledger USD (`AmountUSD`) and operational currency amounts (`AmountOrigCurrency`). The table anchors analytics that later unify with eMoney/Apex/MoneyFarm siblings inside `BI_DB_DDR_Fact_MIMO_AllPlatforms`.

Row scale is inferred from **`sys.partitions` row counts ~68 562 958** (`SUM(rows)` aggregated on `OBJECT_ID`; **preferred warehouse DMV returned permission error** in MCP). Sampling shows heavy use of FundingType **`33`** (internal transfer funding), plus recurring deposit flags surfaced by `Fact_BillingDeposit.IsRecurring`.

The procedure body (SSD **DataPlatform**) stages `#depositsTP`/`#cashoutTP`, UNIONs them into `#mimoTP` with **`ROW_NUMBER … PARTITION BY MIMOAction, TransactionID`** to strip duplicate fallout from correlated joins, wipes the business date partition, inserts the merged rowset, then applies a guarded FTD **`UPDATE`** for late-arriving Dim_Customer reconciliation.

---

## 2. Business Logic

### 2.1 Action-Type Grain (Deposits vs Withdrawals)

**What**: The SP filters `Fact_CustomerAction` strictly to **`ActionTypeID IN (7,44)` for deposits** and **`IN (8,45)` for withdrawals** tied to `@dateID`.  
**Columns Involved**: `MIMOAction`, `TransactionID`, `OrigIdentifier`, core measures.  
**Rules**:
- `7`/`8` encode standard deposit/cashout; `44`/`45` cover IBAN / internal-money-movement parallels per SP changelog (May 2025 IBAN fixes).
- UNION ALL aligns columns; withdraw branch resets `IsFTD`/`IsRecurring` defaults before inserting.

### 2.2 First-Time Deposit (FTD) Handling

**What**: FTD coherence across global FTD refactors drove multiple hotfixes logged in SP comments (`20250904`, `20251023`).  
**Columns Involved**: `IsFTD`, `RealCID`, `TransactionID`.  
**Rules**:
- Deposit branch while selecting: `CASE WHEN dc1.FTDTransactionID = fca.DepositID THEN 1 ELSE 0 END` with `JOIN Dim_Customer dc1 … FTDPlatformID = 1`.
- Withdraw branch inherits `fca.IsFTD` upstream but UNION forces output `IsFTD` to **0 for withdraw rows**.
- INSERT finalizes via `ISNULL(t.IsFTD,0)`; post-insert `UPDATE` promotes remaining deposit misses when `JOIN Dim_Customer … FTDPlatformID=1` and `TransactionID = FTDTransactionID` (`DateID >= 20250901`).

### 2.3 `IsRedeem` — Transfer-to-Coin Indicator (Withdraw Grain)

**What**: Flags withdrawals that originate as **transfer-to-coin (“transfercoin”)** movements funded from fiat wallet balance toward on-chain/eToro-custodied crypto—not a generic billing “cash to bank account” shorthand. Revenue analytics bind the paired fee slice via `Fact_CustomerAction` filters referenced in **`Function_Revenue_TransferCoinFee`**.  
**Columns Involved**: `IsRedeem`, `MIMOAction`.  
**Rules**:
- Deposit branch assigns `NULL` then union emits literal **`0`**.
- Withdraw branch carries **`fca.IsRedeem`** from `Fact_CustomerAction` filtered to `ActionTypeID IN (8,45)`; INSERT uses **`ISNULL(IsRedeem,0)`**.
- For revenue cross-check see `BI_DB_dbo.Function_Revenue_TransferCoinFee`: **ActionTypeID 30 AND IsRedeem = 1** (TVF selects transfercoin commissions). DDR trading fact still surfaces `IsRedeem` on `8/45` rows where billing marks the cashout accordingly.

### 2.4 Deduplication (ROW_NUMBER)

**What**: Dec-2025 note — historic duplicate `Fact_CustomerAction`/`History Credit` fallout multiplied joins; RN dedupe trims duplicate `(MIMOAction, TransactionID)` pairs.  
**Columns Involved**: all inserted columns.  
**Rules**: `WHERE RN = 1` after `PARTITION BY a.MIMOAction, a.TransactionID ORDER BY a.TransactionID`.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse** the table hashes on **`RealCID`** with CLUSTERED COLUMNSTORE. Filter or join by `RealCID` + constrain `DateID` to prune distributions; analytical scans remain heavy—never `SELECT *` unbounded across all history.

### 3.1b UC (Databricks) Storage & Partitioning

Assume **Databricks `main.bi_db`** gold mirror with lowercase long table name identical to `_generic_pipeline_mapping.json`. **Explicit partition columns were not enumerated** (`DESCRIBE TABLE` MCP failed). Typical exports add `etr_y`/`etr_ym`/`etr_ymd` surrogate partition keys—confirm before large scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily TP MIMO totals | `WHERE DateID BETWEEN @start AND @end GROUP BY DateID,MIMOAction` |
| Internal-transfer heavy flows | Filter `FundingTypeID = 33` (per SP CASE) vs other funding types |
| IBAN-linked activity | Combine `IsIBANTrade`, `IsIBANQuickTransfer` with `FundingTypeID` context |
| Cross-platform totals | UNION this table AFTER joining `Dim_Customer` filters; better: read `BI_DB_DDR_Fact_MIMO_AllPlatforms` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_Customer` | `RealCID` | Geography, segmentation, FTD attributes |
| `DWH_dbo.Dim_FundingType` | `FundingTypeID` | Decode instrument / funding channel |
| `DWH_dbo.Fact_CustomerAction` | `TransactionID = DepositID` / `WithdrawPaymentID` AND same `DateID`,`RealCID` | Trace original credit ledger row |
| `BI_DB_ddr…AllPlatforms` | composite keys downstream | Harmonized dashboards |

### 3.4 Gotchas

- **Withdraw FTD zeroed**: `IsFTD` on withdraw rows forced to 0 regardless of Fact payload—analyze FTD only via deposit semantics or sibling global FTD function.
- **IsCryptoToFiat always 0**: placeholder retained for DDR schema symmetry; TP-specific C2F handled elsewhere (`BI_DB_DDR_Fact_MIMO_eMoney_Platform` etc.).
- **Amount orig currency path**: Withdraw uses `BI_DB_DepositWithdrawFee` override when Fee table row exists (`TransactionID` strips leading `W`); else fallback `Amount_WithdrawToFunding`÷`ExchangeRate` stack.
- **Permission-sensitive catalog stats**: DMV row aggregates may fail for some MCP users — rely on `sys.partitions` approximations documented here.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Typical meaning |
|-------|------|-----------------|
| **** | Tier 1 | Borrowed verbatim tag from upstream Dimension/Fact wiki (origin preserved) |
| *** | Tier 2 | Stored-procedure formula / multi-branch mapping |
| * | Tier 4 | Inference / ambiguity — flagged in `.review-needed.md` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Ledger business date partition key duplicated from `@date`. `CAST(CONVERT(varchar(8),@date,112) AS int)` seeded into `#depositsTP`/`#cashoutTP`, carried through UNION. DELETE partition uses same `@dateID`. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 2 | Date | date | YES | Calendar counterpart to `DateID`; INSERT selects `@date`. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 3 | RealCID | int | YES | Global Real Customer Identifier on the ledger row (`fca.RealCID`). (Tier 1 — Customer.CustomerStatic) |
| 4 | MIMOAction | varchar(100) | YES | Stable label `'Deposit'` or `'Withdraw'` from UNION halves. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 5 | OrigIdentifier | varchar(100) | YES | Literal discriminator `'DepositID'` vs `'WithdrawPaymentID'` aligning `TransactionID` grain. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 6 | TransactionID | int | YES | `DepositID` for deposits (`ActionTypeID` 7/44) OR `WithdrawPaymentID` for withdraw rows (`ActionTypeID` 8/45). ROW_NUMBER dedupes collisions. (Tier 2 — Fact_CustomerAction) |
| 7 | AmountUSD | decimal(16,6) | YES | `fca.Amount` from `Fact_CustomerAction WHERE ActionTypeID IN (7,44)` (deposits) or `IN (8,45)` (withdrawals) at `@dateID`. (Tier 2 — Fact_CustomerAction) |
| 8 | AmountOrigCurrency | decimal(16,6) | YES | Deposit: `fbd.Amount`. Withdraw: `COALESCE(bddwf.Amount, ROUND( ROUND(fbw.Amount_WithdrawToFunding,6) / NULLIF(ROUND(fbw.ExchangeRate,6),0), 6))` with joins defined in `#cashoutTP`. (Tier 2 — Fact_BillingDeposit / Fact_BillingWithdraw) |
| 9 | FundingTypeID | int | YES | Deposit: `fbd.FundingTypeID`. Withdraw: `fbw.FundingTypeID_Funding`. Type of funding instrument powering the payout leg. Deposit description reference: Fact_BillingDeposit column #17 semantics. Withdraw description reference: `FundingTypeID_Funding` semantics in `Fact_BillingWithdraw`. (Tier 2 — Fact_BillingDeposit / Billing.Funding) |
| 10 | CurrencyID | int | YES | Deposit: `fbd.CurrencyID` — “Currency of the deposit amount…” (Billing upstream). Withdraw: `fbw.ProcessCurrencyID` — “Currency used for the actual payment processing…” (Billing.WithdrawToFunding upstream). Same column merges both semantics via SP branch. (Tier 1 — upstream wiki, Billing.Deposit / Billing.WithdrawToFunding) |
| 11 | Currency | varchar(20) | YES | Ticker symbol (`dc.Abbreviation`) joined on `CurrencyID`/`ProcessCurrencyID`. `"USD","EUR"` forex; equities/crypto codes per dictionary. Passthrough from `Dim_Currency`. (Tier 1 — Dictionary.Currency) |
| 12 | IsFTD | int | YES | Deposits: `CASE WHEN dc1.FTDTransactionID = fca.DepositID THEN 1 ELSE 0` with `JOIN Dim_Customer dc1 … FTDPlatformID=1`. Withdraw half forces `IsFTD=0` inside UNION despite `fca.IsFTD` select in `#cashoutTP`. INSERT `ISNULL`; late recoveries via `UPDATE` against `Dim_Customer` FTD linkage (`DateID>=20250901`). (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 13 | IsInternalTransfer | int | YES | `CASE WHEN FundingTypeID = 33 THEN 1 ELSE 0` (deposit branch on `fbd.FundingTypeID`; withdraw branch on `fbw.FundingTypeID_Funding`). Mirrors IBAN/quick-transfer interplay described in changelog. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 14 | IsRedeem | int | YES | **Transfer-to-coin / transfercoin flag on Money-Out.** Withdraw leg reads `fca.IsRedeem` with `WHERE fca.ActionTypeID IN (8,45)`. Deposit UNION hard-codes literal `0` after `#depositsTP` seeded `NULL`. INSERT applies `ISNULL(IsRedeem,0)`. Interpret `1` as customer movement from TP fiat wallet into on-chain/crypto custody—not “redeem to bank.” Cross-surface: revenue TVF **`Function_Revenue_TransferCoinFee`** documents `Fact_CustomerAction` rows **`ActionTypeID = 30` AND `IsRedeem = 1`** for TransferCoinFee commissions tied to transfercoin redemption. (Tier 2 — Fact_CustomerAction) |
| 15 | UpdateDate | datetime | YES | ETL watermark `GETDATE()` on INSERT. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 16 | IsIBANTrade | int | YES | Deposit: `CASE WHEN fca.ActionTypeID = 44 THEN 1 ELSE 0`; Withdraw: `CASE WHEN fca.ActionTypeID = 45 THEN 1 ELSE 0`. Flags sweep-style IBAN internal deposit/withdraw events. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 17 | IsCryptoToFiat | int | YES | Explicit literal `0` — reserved column (C2F captured on other DDR MIMO siblings). `INSERT SELECT … , 0 AS IsCryptoToFiat`. (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |
| 18 | IsRecurring | int | YES | `1=deposit is part of a recurring schedule (OUTER APPLY on Billing.RecurringDeposit). 0=one-time deposit.` carries only on deposit UNION; `'Withdraw'` half injects literal `0`. Final `INSERT` uses `ISNULL(t.IsRecurring,0)`. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse) |
| 19 | IsIBANQuickTransfer | int | YES | Internal transfer discriminator `CASE WHEN fca.MoveMoneyReasonID = 6 THEN 1 ELSE 0` on both halves (SP changelog `20250611`). (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) |

---

## 5. Lineage

### 5.1 Production Sources

Fact columns ultimately tie to Billing + History ingestion feeding `Fact_CustomerAction`/`Fact_Billing*`. Detailed hop lives in sibling DWH wikis; this table inherits them post-consolidation.

| Synapse Column | Production Story | Immediate DWH Inputs | Transform |
|----------------|------------------|----------------------|-----------|
| Core IDs / amounts | History.Credit + Billing Deposit/Withdraw | `Fact_CustomerAction`, billing facts | Filter + JOIN + UNION |
| Currency display | Dictionary.Currency | `Dim_Currency.Abbreviation` | FK join |
| FTD overlays | Customer master | `Dim_Customer.FTD*` | CASE + UPDATE |
| Alternate withdraw amount | Finance fee staging | `BI_DB_DepositWithdrawFee` | Optional join overriding payout amount |

Upstream documentation pointers: **`Fact_CustomerAction.md`**, **`Fact_BillingDeposit.md`**, **`Fact_BillingWithdraw.md`**, **`Dim_Currency.md`**, **`Dim_Customer` UC comments / wiki**, **`BI_DB_Dbo.Functions/Function_Revenue_TransferCoinFee.md`** (business confirmation for TransferCoin linkage).

### 5.2 ETL Pipeline

```
History.Credit + Billing.Deposit/Funding (+Withdraw chain)
 → DWH Fact_CustomerAction / Fact_BillingDeposit / Fact_BillingWithdraw (+Dims)
 → SP_DDR_Fact_MIMO_Trading_Platform(#depositsTP+#cashoutTP → #mimoTP dedupe → DELETE day → INSERT → FTD UPDATE)
 → BI_DB_DDR_Fact_MIMO_Trading_Platform (~68M rows)
 → Consumers: SP_DDR_Fact_Fact_MIMO_AllPlatforms (SB_Daily dependency)
 → Unity Catalog BI_DB mirror (table name unresolved in MCP DESCRIBE)
```

| Step | Object | Purpose |
|------|--------|---------|
| 1 | Fact_CustomerAction | Authoritative ledger rows for ledger actions filtered by IDs |
| 2 | Billing facts | Recover bank amounts, recurring flags, payout currency |
| 3 | Temp stack + UNION | Harmonize schemas + ROW_NUMBER cleanup |
| 4 | INSERT + UPDATE | Materialize Synapse CCI fact |
| 5 | Downstream | AllPlatforms + DDR panel TVFs/views |

```text
UPSTREAM SEARCH LOG — BI_DB_DDR_Fact_MIMO_Trading_Platform:
  Lineage source objects (from .lineage.md):
    1. DWH_dbo.Fact_CustomerAction (fact source / filters)
       (a) Local wiki: …/Fact_CustomerAction.md → FOUND (Read YES)
       (b) prod wiki incremental via History wiki (not reopened — rely on Fact doc)
       Effective upstream: Fact_CustomerAction.md + SSDT SP
    2. DWH_dbo.Fact_BillingDeposit
       → FOUND Read YES (Fact_BillingDeposit.md excerpts)
    3. DWH_dbo.Fact_BillingWithdraw
       → FOUND Read YES (Fact_BillingWithdraw.md excerpts)
    4. DWH_dbo.Dim_Currency
       → FOUND Read YES (Dim_Currency.md excerpts)
    5. DWH_dbo.Dim_Customer (FTD join & UPDATE only)
       (a) Local wiki …/Dim_Customer.md → FOUND (Read YES — header/overview for FTD context)
    6. BI_DB_dbo.BI_DB_DepositWithdrawFee
       → No dedicated sibling wiki consulted — rely on SSDT predicate (**gap**, Tier review)
  Tier-1-eligible columns leveraged: RealCID ; CurrencyAbbreviation lineage ; Billing currency semantics for CurrencyID
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | `DWH_dbo.Dim_Customer` | Attribute enrichment |
| FundingTypeID | `DWH_dbo.Dim_FundingType` | Decode rails |
| CurrencyID | `DWH_dbo.Dim_Currency` | Already joined but re-join permissible |
| TransactionID | `DWH_dbo.Fact_CustomerAction` | Ledger trace |

### 6.2 Referenced By

| Source Object | Source Element | Notes |
|--------------|----------------|-------|
| `BI_DB_DDR_Fact_MIMO_AllPlatforms` | Whole row union | Consolidated DDR MIMO |
| DDR panel TVFs / Genie readiness | Depends on consolidated tables | PRDs cite MIMO lineage |

---

## 7. Sample Queries

### 7.1 Daily deposit vs withdrawal counts (Trading Platform DDR)
```sql
SELECT DateID,
       MIMOAction,
       COUNT(*) AS events,
       SUM(AmountUSD) AS amt_usd
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform
WHERE DateID BETWEEN 20260101 AND 20260331
GROUP BY DateID, MIMOAction
ORDER BY DateID DESC, MIMOAction;
```

### 7.2 Internal-transfer rail concentration
```sql
SELECT FundingTypeID,
       SUM(CASE WHEN IsInternalTransfer=1 THEN 1 ELSE 0 END) AS internal_cnt,
       COUNT(*) AS all_cnt
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform
WHERE DateID >= 20260101
GROUP BY FundingTypeID
ORDER BY all_cnt DESC;
```

### 7.3 Transfer-to-coin withdraw slice (paired with Amount checks)
```sql
SELECT TOP 100 DateID,
       RealCID,
       TransactionID AS WithdrawPaymentID,
       AmountUSD,
       AmountOrigCurrency,
       FundingTypeID
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform
WHERE MIMOAction = 'Withdraw'
  AND IsRedeem = 1
  AND DateID >= 20250101;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Knowledge captured |
|--------|------|-------------------|
| [DDR Tables](https://etoro-jira.atlassian.net/wiki/spaces/~164971827/pages/13596884995/DDR+Tables) | Confluence | Enumerates DDR MIMO table family incl. `_AllPlatforms` vs per-platform splits |
| [PRD: Genie Space — MIMO (Money In / Money Out)](https://etoro-jira.atlassian.net/wiki/spaces/BIA/pages/14330691721/PRD+Genie+Space+MIMO+Money+In+Money+Out) | Confluence | Product rationale for consolidated MIMO fact consumption |

---

*Generated: 2026-05-14 | Quality: 8.4/10 (★★★★☆) | Phases: Full 1–11 + adversarial Phase 16*  
*Tiers: 3 T1, 16 T2, 0 T3, 0 T4-unverified; Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 8/10*  
*Object: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform | Writer SP: BI_DB_dbo.SP_DDR_Fact_MIMO_Trading_Platform*
