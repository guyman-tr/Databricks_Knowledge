---
object_fqn: main.bi_output.bi_output_vg_aum
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_aum
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 64
row_count: null
generated_at: '2026-05-19T15:01:45Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
- main.bi_output.bi_output_vg_date
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql
concept_count: 14
formula_count: 52
tier_breakdown:
  tier1_columns: 3
  tier2_columns: 61
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_vg_aum

> View in `main.bi_output`. 14 business concept(s) in §2; 64 of 64 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_aum` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 64 |
| **Concepts** | 14 (see §2) |
| **Downstream consumers** | 1 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Tue Apr 28 19:07:27 UTC 2026 |

---

## 1. Business Meaning

`bi_output_vg_aum` is a view in `main.bi_output` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 13 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_AUM.md`. Additional upstreams: 15 object(s), listed in §5 Lineage.

Of its 64 columns: 3 inherit byte-for-byte from upstream wikis (Tier 1), 61 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0
**What**: Computed flag on `IsPI` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsPI`
**Rules**:
- `GuruStatusID > 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql` bi_output.sql L53-L53
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`

### 2.2 Dim lookup via alias `dcu` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.RealCID = dcu.RealCID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql` L78
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.3 Dim lookup via alias `dpl` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerLevelID = dpl.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql` L80
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

### 2.4 Dim lookup via alias `dm` → `gold_sql_dp_prod_we_dwh_dbo_dim_manager`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_manager` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountManagerID = dm.ManagerID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql` L82
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`

### 2.5 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_regulation` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.RegulationID = dr.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql` L84
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`

### 2.6 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.CountryID = dc.CountryID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql` L86,L106
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

### 2.7 Dim lookup via alias `dl` → `gold_sql_dp_prod_we_dwh_dbo_dim_language`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_language` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.LanguageID = dl.LanguageID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql` L88,L104
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`

### 2.8 Dim lookup via alias `dv` → `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.VerificationLevelID = dv.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql` L90
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`

### 2.9 Dim lookup via alias `gs` → `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.GuruStatusID = gs.GuruStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql` L92
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`

### 2.10 Dim lookup via alias `ast` → `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountStatusID = ast.AccountStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql` L94
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`

### 2.11 Dim lookup via alias `act` → `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountTypeID = act.AccountTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql` L96
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`

### 2.12 Dim lookup via alias `pst` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusID = pst.PlayerStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql` L98
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`

### 2.13 Dim lookup via alias `psr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql` L100
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`

### 2.14 Dim lookup via alias `pssr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_aum.sql` L102
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |
| **Materialization** | view_definition (re-runs on every query) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Filter on discriminator flags | Use `IsPI = 1`-style filters on the precomputed flag columns (`IsPI`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `fsc.RealCID = dcu.RealCID` | Lookup via alias `dcu` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `fsc.PlayerLevelID = dpl.PlayerLevelID` | Lookup via alias `dpl` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | `fsc.AccountManagerID = dm.ManagerID` | Lookup via alias `dm` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `fsc.RegulationID = dr.ID` | Lookup via alias `dr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `fsc.CountryID = dc.CountryID` | Lookup via alias `dc` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `fsc.LanguageID = dl.LanguageID` | Lookup via alias `dl` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | `fsc.VerificationLevelID = dv.ID` | Lookup via alias `dv` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | `fsc.GuruStatusID = gs.GuruStatusID` | Lookup via alias `gs` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | `fsc.AccountStatusID = ast.AccountStatusID` | Lookup via alias `ast` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | `fsc.AccountTypeID = act.AccountTypeID` | Lookup via alias `act` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `fsc.PlayerStatusID = pst.PlayerStatusID` | Lookup via alias `pst` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | `fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID` | Lookup via alias `psr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | `fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID` | Lookup via alias `pssr` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | STRING | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. HASH distribution grain for this fact. Merge key `COALESCE(cb.CID, i.CID, ob.RealCID)` resolves TP + IBAN + Options shell customers. (Tier 1 — Customer.CustomerStatic) |
| 1 | DateID | INT | YES | Computed in source (transform kind not classified). Formula: `,DateID`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 2 | Date | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,DateID ,Date`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 3 | WeekNumberYear | INT | YES | Computed in source (transform kind not classified). Formula: `,DateID ,Date ,WeekNumberYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 4 | CalendarYearMonth | STRING | YES | Computed in source (transform kind not classified). Formula: `,DateID ,Date ,WeekNumberYear ,CalendarYearMonth`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 5 | CalendarQuarter | INT | YES | Computed in source (transform kind not classified). Formula: `,DateID ,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 6 | CalendarYear | INT | YES | Computed in source (transform kind not classified). Formula: `,DateID ,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 7 | RealizedEquityTradingPlatform | DECIMAL | YES | Customer's **settled (realized) equity** — the realized portion of customer balance, **excluding unrealized PnL on open positions** (the unrealized component lives in `Fact_CustomerUnrealized_PnL.PositionPnL`). From `Fact_SnapshotEquity.RealizedEquity` via Client Balance. DDR transform: **SUM per CID/DateID** across Client Balance rows. (Tier 2 — SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity) |
| 8 | TotalPositionPNL | DECIMAL | YES | Total position PnL across all asset classes. From `V_Liabilities.PositionPnL`. Unrealized profit/loss on all open positions. DDR transform: SUM(`PositionPNL`). (Tier 2 — SP_Client_Balance_New) |
| 9 | TotalInvestedAmount | DECIMAL | YES | Total position amount (`TotalPositionsAmount` lineage). Measures aggregate market value of exposures. DDR transform: SUM(`PositionAmount`). (Tier 2 — SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotEquity) |
| 10 | EquityTradingPlatform | DECIMAL | YES | Trading-platform **TotalEquity surrogate** summed as `SUM(ISNULL(TotalLiability,0) + ISNULL(actualNWA,0))` inside `#ClientBalance`. Not identical to interpreting “TP equity = liability view only”; treat as authoritative DDR column for `_TP` rollup. DDR transform: aggregate SUM pipeline. (Tier 2 — SP_DDR_Fact_AUM) |
| 11 | CashInCopy | DECIMAL | YES | Allocation of **`TotalCash`** attributable to mirrored strategies — VL passes `Fact_SnapshotEquity.TotalMirrorCash`; represents copier-side cash earmarked inside copy envelopes. Passthrough VL daily snapshot filtered to `@dateID`. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.TotalMirrorCash) |
| 12 | InvestedAmountCopy | DECIMAL | YES | **`TotalMirrorPositionsAmount + TotalMirrorStockOrders + CopyPositionPnL`** (copy invested + unrealized uplift). Cash excluded intentionally. SP-authored. (Tier 2 — SP_DDR_Fact_AUM) |
| 13 | EquityCopy | DECIMAL | YES | **Composite copy equity**: `TotalMirrorCash + TotalMirrorPositionsAmount + TotalMirrorStockOrders + CopyPositionPnL`, null-guarded in SP verbatim block. Mirrors entire copy-trade economic bundle. (Tier 2 — SP_DDR_Fact_AUM) |
| 14 | EquityStocksManual | DECIMAL | YES | Manual (non-copy) stock equity authored per SP verbatim difference of totals & mirrors (see lineage Phase 9). (Tier 2 — SP_DDR_Fact_AUM) |
| 15 | InvestedAmountStocksManual | DECIMAL | YES | Manual invested-only stock footprint **excluding** mirrored mirror stock leg (SP subtract). (Tier 2 — SP_DDR_Fact_AUM) |
| 16 | InvestedAmountCryptoManual | DECIMAL | YES | **`TotalCryptoManualPosition`** = `TotalCryptoPositionAmount − TotalMirrorCryptoPositionAmount` per VL formula; VL-classified Tier-2 derivation because computed inside view. Alias renamed in DDR inserts. (Tier 2 — DWH_dbo.V_Liabilities) |
| 17 | BalanceTradingPlatfrom | DECIMAL | YES | Promotional **`Credit`** component from VL / `Fact_SnapshotEquity.Credit`; column renamed **`CreditTP`** for DDR clarity while identical numeric semantics. VL passthrough. (Tier 1 — DWH_dbo.V_Liabilities lineage: Fact_SnapshotEquity.Credit) |
| 18 | BalanceIBAN | DECIMAL | YES | **Non-TP** IBAN-held balance aggregated `SUM(mcb.ClosingBalanceBO * mcb.USDApproxRate)` excluding `GCID IS NULL OR GCID=0`. Explicit USD approximation path. (Tier 2 — SP_DDR_Fact_AUM) |
| 19 | RealizedEquityGlobal | DECIMAL | YES | **`RealizedEquityTP + IBANBalance`**; excludes Options equities per SP explanatory comment inability to split invested vs PnL. (Tier 2 — SP_DDR_Fact_AUM) |
| 20 | EquityGlobal | DECIMAL | YES | **`TotalEquityTP + IBANBalance + OptionsTotalEquity`** — consolidated **DDR AUM / equity-under-management style metric**. Filter axis for primary INSERT. (Tier 2 — SP_DDR_Fact_AUM) |
| 21 | CreditGlobal | DECIMAL | YES | **`CreditTP + IBANBalance + OptionsCashEquity`** — injects Apex **cash** component only (distinct from **`OptionsTotalEquity`** numerator). Authored verbatim in SP. (Tier 2 — SP_DDR_Fact_AUM) |
| 22 | OptionsTotalEquity | DECIMAL | YES | Apex options economic value from **`Function_AUM_OptionsPlatform(@OptionsMaxDateID,0)`** keyed on latest external buy-power close ≤ ingestion; merges by `FULL OUTER` on **`RealCID`**; precision widened DDL `decimal(18,6)` versus TP metrics. House IDs filtered inside downstream function lineage. (Tier 2 — SP_DDR_Fact_AUM) |
| 23 | IsLastDayWeek | INT | NO | Computed in source (transform kind not classified). Formula: `,DateID ,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,RealizedEquityTP AS RealizedEquityTradingPlatform ,TotalPositionPNL ,TotalI…`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 24 | IsLastDayMonth | INT | NO | Computed in source (transform kind not classified). Formula: `,DateID ,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,RealizedEquityTP AS RealizedEquityTradingPlatform ,TotalPositionPNL ,TotalI…`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 25 | IsLastDayQuarter | INT | NO | Computed in source (transform kind not classified). Formula: `,DateID ,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,RealizedEquityTP AS RealizedEquityTradingPlatform ,TotalPositionPNL ,TotalI…`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 26 | IsLastDayYear | INT | NO | Computed in source (transform kind not classified). Formula: `,DateID ,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,RealizedEquityTP AS RealizedEquityTradingPlatform ,TotalPositionPNL ,TotalI…`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 27 | PlayerLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `,DateID ,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,RealizedEquityTP AS RealizedEquityTradingPlatform ,TotalPositionPNL ,TotalI…`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 28 | ClubTier | STRING | YES | Computed in source (transform kind not classified). Formula: `,DateID ,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,RealizedEquityTP AS RealizedEquityTradingPlatform ,TotalPositionPNL ,TotalI…`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 29 | RegulationID | INT | YES | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 — via Fact_SnapshotCustomer) |
| 30 | Regulation | STRING | YES | Computed in source (transform kind not classified). Formula: `,DateID ,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,RealizedEquityTP AS RealizedEquityTradingPlatform ,TotalPositionPNL ,TotalI…`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 31 | VerificationLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,RealizedEquityTP AS RealizedEquityTradingPlatform ,TotalPositionPNL ,TotalInvestedAmount …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 32 | VerificationLevel | STRING | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,RealizedEquityTP AS RealizedEquityTradingPlatform ,TotalPositionPNL ,TotalInvestedAmount ,TotalEqui…`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 33 | CountryID | INT | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,RealizedEquityTP AS RealizedEquityTradingPlatform ,TotalPositionPNL ,TotalInvestedAmount ,TotalEquityTP AS EquityTradingP…`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 34 | Country | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarQuarter ,CalendarYear ,RealizedEquityTP AS RealizedEquityTradingPlatform ,TotalPositionPNL ,TotalInvestedAmount ,TotalEquityTP AS EquityTradingPlatform ,CashInCopy …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 35 | Region | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYear ,RealizedEquityTP AS RealizedEquityTradingPlatform ,TotalPositionPNL ,TotalInvestedAmount ,TotalEquityTP AS EquityTradingPlatform ,CashInCopy ,InvestedAmountCopy …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 36 | AccountManagerID | INT | YES | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 — via Fact_SnapshotCustomer) |
| 37 | AccountManager | STRING | YES | Computed in source (transform kind not classified). Formula: `,TotalPositionPNL ,TotalInvestedAmount ,TotalEquityTP AS EquityTradingPlatform ,CashInCopy ,InvestedAmountCopy ,EquityCopy ,EquityStocksManual ,InvestedAmountStocksManual …`. (Tier 2 — literal) |
| 38 | LanguageID | INT | YES | Computed in source (transform kind not classified). Formula: `,TotalInvestedAmount ,TotalEquityTP AS EquityTradingPlatform ,CashInCopy ,InvestedAmountCopy ,EquityCopy ,EquityStocksManual ,InvestedAmountStocksManual ,InvestedAmountCrypto…`. (Tier 2 — literal) |
| 39 | Language | STRING | YES | Computed in source (transform kind not classified). Formula: `,TotalEquityTP AS EquityTradingPlatform ,CashInCopy ,InvestedAmountCopy ,EquityCopy ,EquityStocksManual ,InvestedAmountStocksManual ,InvestedAmountCryptoManual ,CreditTP Bala…`. (Tier 2 — literal) |
| 40 | CommunicationLanguageID | INT | YES | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 — via Fact_SnapshotCustomer) |
| 41 | CommunicationLanguage | STRING | YES | Computed in source (transform kind not classified). Formula: `,InvestedAmountCopy ,EquityCopy ,EquityStocksManual ,InvestedAmountStocksManual ,InvestedAmountCryptoManual ,CreditTP BalanceTradingPlatfrom ,IBANBalance BalanceIBAN ,Realize…`. (Tier 2 — literal) |
| 42 | AccountTypeID | INT | YES | Computed in source (transform kind not classified). Formula: `,EquityCopy ,EquityStocksManual ,InvestedAmountStocksManual ,InvestedAmountCryptoManual ,CreditTP BalanceTradingPlatfrom ,IBANBalance BalanceIBAN ,RealizedEquityGlobal ,EquityGlob…`. (Tier 2 — literal) |
| 43 | AccountType | STRING | YES | Computed in source (transform kind not classified). Formula: `,EquityStocksManual ,InvestedAmountStocksManual ,InvestedAmountCryptoManual ,CreditTP BalanceTradingPlatfrom ,IBANBalance BalanceIBAN ,RealizedEquityGlobal ,EquityGlobal ,CreditGl…`. (Tier 2 — literal) |
| 44 | GuruStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,InvestedAmountStocksManual ,InvestedAmountCryptoManual ,CreditTP BalanceTradingPlatfrom ,IBANBalance BalanceIBAN ,RealizedEquityGlobal ,EquityGlobal ,CreditGlobal ,OptionsTotalEq…`. (Tier 2 — literal) |
| 45 | GuruStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,InvestedAmountCryptoManual ,CreditTP BalanceTradingPlatfrom ,IBANBalance BalanceIBAN ,RealizedEquityGlobal ,EquityGlobal ,CreditGlobal ,OptionsTotalEquity ,IsLastDayWeek ,…`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 46 | IsPI | INT | NO | `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0. Formula: `,CreditTP BalanceTradingPlatfrom ,IBANBalance BalanceIBAN ,RealizedEquityGlobal ,EquityGlobal ,CreditGlobal ,OptionsTotalEquity ,IsLastDayWeek ,IsLastDayMonth ,IsLast…`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 47 | AccountStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,IBANBalance BalanceIBAN ,RealizedEquityGlobal ,EquityGlobal ,CreditGlobal ,OptionsTotalEquity ,IsLastDayWeek ,IsLastDayMonth ,IsLastDayQuarter ,IsLastDayYear …`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 48 | AccountStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,RealizedEquityGlobal ,EquityGlobal ,CreditGlobal ,OptionsTotalEquity ,IsLastDayWeek ,IsLastDayMonth ,IsLastDayQuarter ,IsLastDayYear ,PlayerLevelID ,…`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 49 | PlayerStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,EquityGlobal ,CreditGlobal ,OptionsTotalEquity ,IsLastDayWeek ,IsLastDayMonth ,IsLastDayQuarter ,IsLastDayYear ,PlayerLevelID ,Name AS ClubTier …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 50 | PlayerStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,CreditGlobal ,OptionsTotalEquity ,IsLastDayWeek ,IsLastDayMonth ,IsLastDayQuarter ,IsLastDayYear ,PlayerLevelID ,Name AS ClubTier ,Regulation…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 51 | CanOpenPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,OptionsTotalEquity ,IsLastDayWeek ,IsLastDayMonth ,IsLastDayQuarter ,IsLastDayYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 52 | CanClosePosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,IsLastDayWeek ,IsLastDayMonth ,IsLastDayQuarter ,IsLastDayYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 53 | CanEditPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,IsLastDayMonth ,IsLastDayQuarter ,IsLastDayYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 54 | CanBeCopied | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,IsLastDayQuarter ,IsLastDayYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS Ver…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date` (+2 more)) |
| 55 | CanDeposit | BOOLEAN | YES | Whether the user can add funds to their account. False for full-block statuses (IsBlocked=1), close-only/pending statuses (9, 13, 15), status 10 (Deposit Blocked), and status 11 (Social Index). |
| 56 | CanRequestWithdraw | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Na…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+2 more)) |
| 57 | PlayerStatusReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,M…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+2 more)) |
| 58 | PlayerStatusReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 59 | PlayerStatusSubReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,Accoun…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 60 | PlayerStatusSubReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(d…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 61 | CitizenshipCountryID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` (+1 more)) |
| 62 | CitizenshipCountry | STRING | YES | Computed in source (transform kind not classified). Formula: `,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 63 | AffiliateID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID ,Name AS La…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` (+1 more)) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_AUM.md` |
| `main.bi_output.bi_output_vg_date` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_date.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_VerificationLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_GuruStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum
main.bi_output.bi_output_vg_date
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
... (13 more upstream(s))
        │
        ▼
main.bi_output.bi_output_vg_aum   ←── this object
        │
        ▼
main.bi_dealing_stg.bi_output_dealing_bod_overview_investment_etoro
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=64 runtime=64 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_AUM.md`)
- **JOIN/UNION upstreams**: 15 additional object(s)
- **Wiki coverage**: 15/15 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- `main.bi_dealing_stg.bi_output_dealing_bod_overview_investment_etoro`

---

## 7. Sample Queries

> Sample queries are not auto-generated. Refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage patterns against this object.

---

## 8. Atlassian Knowledge Sources

> No Atlassian sources discovered for this object in the current pipeline. When Confluence pages or Jira tickets are linked to this UC object, they will appear here (run `tools/uc_pipelines/cache_atlassian_for_object.py` if/when that tool exists).

---

## Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough/rename/cast).
- **Tier 2** — column described from a formula in `formulas.json` + an optional named concept from `concepts.json`. The formula is the predicate-explicit, alias-resolved SQL transformation; the concept gives the business name.
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides every other tier including Tier 1 (per DWH semantic-doc framework).
- **Tier N** — null-with-provenance: column points at an upstream that is either terminal-with-no-wiki, or in-scope-but-not-yet-authored. Explicit gap disclosure.
- **Tier U** — unclassifiable: no upstream wiki match, no formula, no source-code snippet. Mechanical disclosure of unclassifiability — see `.review-needed.md`.

*Generated: 2026-05-19 | Concepts: 14 | Formulas: 52 | Tiers: 3 T1, 61 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 64/64 | Source: view_definition*
