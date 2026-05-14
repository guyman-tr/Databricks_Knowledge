# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms — Review Needed

> Lightweight sidecar for Tier 4 / structural follow-ups discovered during **2026‑05‑14** speckit run. **`IsRedeem` bank‑redemption wording is explicitly forbidden** — confirm no regressions.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

| Column | Why |
|--------|-----|
| _None flagged `[UNVERIFIED]`_ — all rows carry coded tier suffixes |

## Columns Needing Clarification

| Column | Question |
|--------|----------|
| `CurrencyID = 3` on **MoneyFarm** rows | **GBP literal** aligns with **`'GBP'`** currency code — validate against **`Dictionary.Currency`** / **`Dim_Currency`** authoritative ID for GBP (staging drift risk). |
| `TransactionID` semantics | **`CAST(... AS VARCHAR(50))`** in SP vs **`INT`** column implies historical lake typing constraints — numeric overflow risk remains if IDs exceed `INT` range (currently none observed). |

## Structural Questions

| # | Topic | Detail |
|---|-------|--------|
| 1 | **UC vs Synapse column drift** | **Databricks UC** **`DESCRIBE`** lists **`etr_y` / `etr_ym` / `etr_ymd`** (plus partition bookkeeping rows). **Synapse DDL** (**SSDT `/ INFORMATION_SCHEMA`**) exposes **21** business columns only — tooling expecting 1‑to‑1 column lists must branch on catalog. |
| 2 | **Live UC comment debt** | Unity Catalog **`IsRedeem`** comment still echoes legacy **bank redemption** wording — regenerate via **`sync_to_databricks` / ALTER pass** AFTER wiki freeze (**out of scope**: user banned `.alter.sql` this run). |
| 3 | **Dim_Customer enrichment** | `UPSTREAM SEARCH LOG` cites **`Dim_Customer.md`** **DEFERRED read** — next rerun should **`Read`** file fully per Patch 15 gate to avoid latent FTD description drift. |
| 4 | **OpsDB orchestration granularity** | **Phase 9B** not deep-linked to **`user-opsdb_sql`** (**SB_Daily** asserted from SP commentary + mapping frequency only) — optional hardening. |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|----------------|----------------|
| _empty_ | | | | |

## Drift & Parity Log

| Check | Result |
|-------|--------|
| **Element rows vs Synapse `INFORMATION_SCHEMA`** | **21 / 21 PASS** |
| **Element rows vs UC `DESCRIBE` data columns** | **UC adds partition + metadata rows** — **NOT parity** (expected). |
| **MoneyFarm boolean myth** | **CLOSED** — FTD flags (`IsPlatformFTD`,`IsGlobalFTD`) use literal **`1`**; other indicator columns forced **`0`** per SP excerpt in parent wiki §2.4. |
