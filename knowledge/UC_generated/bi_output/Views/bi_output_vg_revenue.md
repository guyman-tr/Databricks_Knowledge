---
object_fqn: main.bi_output.bi_output_vg_revenue
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_revenue
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 52
row_count: null
generated_at: '2026-05-19T15:01:51Z'
upstreams:
- main.bi_output.bi_output_vg_date
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
- main.bi_output.bi_ouput_v_dim_instrumenttype
- main.bi_output.bi_output_customer_ddr_revenue_metrics
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql
concept_count: 15
formula_count: 52
tier_breakdown:
  tier1_columns: 2
  tier2_columns: 49
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 1
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_vg_revenue

> View in `main.bi_output`. 15 business concept(s) in §2; 51 of 52 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_revenue` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 52 |
| **Concepts** | 15 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Dec 29 14:07:59 UTC 2025 |

---

## 1. Business Meaning

`bi_output_vg_revenue` is a view in `main.bi_output` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 14 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_output.bi_output_vg_date` → this object. Canonical upstream documentation: `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_date.md`. Additional upstreams: 17 object(s), listed in §5 Lineage.

Of its 52 columns: 2 inherit byte-for-byte from upstream wikis (Tier 1), 49 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0
**What**: Computed flag on `IsPI` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsPI`
**Rules**:
- `GuruStatusID > 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql` bi_output.sql L40-L40
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`

### 2.2 Dim lookup via alias `dc1` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `rga.RealCID = dc1.RealCID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql` L60,L72
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.3 Dim lookup via alias `ins` → `bi_ouput_v_dim_Instrumenttype`
**What**: `JOIN` to dimension `bi_ouput_v_dim_Instrumenttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `rga.InstrumentTypeID = ins.InstrumentTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql` L64
**Source(s)**: `main.bi_output.bi_ouput_v_dim_Instrumenttype`

### 2.4 Dim lookup via alias `dpl` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerLevelID = dpl.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql` L74
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

### 2.5 Dim lookup via alias `dm` → `gold_sql_dp_prod_we_dwh_dbo_dim_manager`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_manager` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountManagerID = dm.ManagerID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql` L76
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`

### 2.6 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_regulation` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.RegulationID = dr.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql` L78
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`

### 2.7 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.CountryID = dc.CountryID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql` L80,L100
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

### 2.8 Dim lookup via alias `dl` → `gold_sql_dp_prod_we_dwh_dbo_dim_language`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_language` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.LanguageID = dl.LanguageID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql` L82,L98
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`

### 2.9 Dim lookup via alias `dv` → `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.VerificationLevelID = dv.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql` L84
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`

### 2.10 Dim lookup via alias `gs` → `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.GuruStatusID = gs.GuruStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql` L86
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`

### 2.11 Dim lookup via alias `ast` → `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountStatusID = ast.AccountStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql` L88
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`

### 2.12 Dim lookup via alias `act` → `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountTypeID = act.AccountTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql` L90
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`

### 2.13 Dim lookup via alias `pst` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusID = pst.PlayerStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql` L92
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`

### 2.14 Dim lookup via alias `psr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql` L94
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`

### 2.15 Dim lookup via alias `pssr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_revenue.sql` L96
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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `bi_ouput_v_dim_Instrumenttype`, `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `gold_sql_dp_prod_we_dwh_dbo_dim_manager`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `rga.RealCID = dc1.RealCID` | Lookup via alias `dc1` |
| `main.bi_output.bi_ouput_v_dim_Instrumenttype` | `rga.InstrumentTypeID = ins.InstrumentTypeID` | Lookup via alias `ins` |
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
| 1 | Date | TIMESTAMP | YES | Arithmetic combination of upstream columns. Formula: `-- ========================================================================== -- Source: information_schema.views.view_definition -- Object: bi_output.bi_output_vg_revenue -- Captured: 2026-05-19…`. (Tier 2 — computed in source) |
| 1 | DateID | INT | YES | Computed in source (transform kind not classified). Formula: `, DateID`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 2 | CalendarYearMonth | STRING | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 3 | CalendarQuarter | INT | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 4 | CalendarYear | INT | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 5 | RealCID | STRING | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. **(Tier 1 — Customer.CustomerStatic)** (cast to `STRING`) |
| 6 | InstrumentTypeID | INT | YES | From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. **`ISNULL(...,-1)`** masks NULL account-level feeds. **(Tier 1 — Trade.GetInstrument)** |
| 7 | InstrumentType | STRING | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 8 | IsSettled | INT | YES | 1 = real asset, 0 = CFD asset. **DDR note:** `ISNULL(...,-1)` sentinel for streams lacking instruments. **(Tier 5 — Expert Review)** |
| 9 | IsCopy | INT | YES | `CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END` from revenue TVFs, then `ISNULL(...,-1)`; crypto-to-fiat branch forces `-1` post UPDATE. Indicates copy-trading linkage on applicable metrics. **(Tier 2 — Fact_CustomerAction.MirrorID logic via Function_Revenue_*)** |
| 10 | Metric | STRING | YES | Canonical revenue column label (`FullCommission`, `RollOverFee`, `TransferCoinFee`, `StakingLagOneMonth`, …) — enumerated in **`Dim_Revenue_Metrics.Metric`**. **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 11 | CountAsActiveTrade | INT | YES | **`CASE WHEN ActionTypeID IN (1,39) AND ISNULL(IsAirDrop,0) = 0 THEN 1 ELSE 0 END`** on commission feeders; flattened to **`0`** elsewhere before insert coercion. **(Tier 2 — SP_DDR_Fact_Revenue_Generating_Actions)** |
| 12 | IncludedInTotalRevenue | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 13 | RevenueMetricCategory | STRING | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 14 | PlayerLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 15 | ClubTier | STRING | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 16 | RegulationID | INT | YES | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 — via Fact_SnapshotCustomer) |
| 17 | Regulation | STRING | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 18 | VerificationLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 19 | VerificationLevel | STRING | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 20 | CountryID | INT | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 21 | Country | STRING | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 22 | Region | STRING | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 23 | AccountManagerID | INT | YES | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 — via Fact_SnapshotCustomer) |
| 24 | AccountManager | STRING | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 25 | LanguageID | INT | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 26 | Language | STRING | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 27 | CommunicationLanguageID | INT | YES | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 — via Fact_SnapshotCustomer) |
| 28 | CommunicationLanguage | STRING | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 29 | AccountTypeID | INT | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 30 | AccountType | STRING | YES | Computed in source (transform kind not classified). Formula: `, DateID , CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 31 | GuruStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `, CalendarYearMonth , CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled , IsCop…`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 32 | GuruStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `, CalendarQuarter , CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled , IsCopy , Metric , r…`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 33 | IsPI | INT | NO | `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0. Formula: `, CalendarYear , STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled , IsCopy , Metric , CountAsActiveTrade …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_output.bi_output_vg_date`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`) |
| 34 | AccountStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `, STRING(RealCID) AS RealCID , InstrumentTypeID , InstrumentType , IsSettled , IsCopy , Metric , CountAsActiveTrade , IncludedInTotalR…`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`, `main.bi_output.bi_output_customer_ddr_revenue_metrics`) |
| 35 | AccountStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `, InstrumentTypeID , InstrumentType , IsSettled , IsCopy , Metric , CountAsActiveTrade , IncludedInTotalRevenue , RevenueMetricCategory…`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`, `main.bi_output.bi_output_customer_ddr_revenue_metrics`) |
| 36 | PlayerStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `, InstrumentType , IsSettled , IsCopy , Metric , CountAsActiveTrade , IncludedInTotalRevenue , RevenueMetricCategory ,PlayerLevelID …`. (Tier 2 — from `main.bi_output.bi_ouput_v_dim_Instrumenttype`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` (+1 more)) |
| 37 | PlayerStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `, IsSettled , IsCopy , Metric , CountAsActiveTrade , IncludedInTotalRevenue , RevenueMetricCategory ,PlayerLevelID ,Name AS ClubTier …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` (+1 more)) |
| 38 | CanOpenPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `, IsCopy , Metric , CountAsActiveTrade , IncludedInTotalRevenue , RevenueMetricCategory ,PlayerLevelID ,Name AS ClubTier ,RegulationI…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` (+1 more)) |
| 39 | CanClosePosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `, Metric , CountAsActiveTrade , IncludedInTotalRevenue , RevenueMetricCategory ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name A…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 40 | CanEditPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `, CountAsActiveTrade , IncludedInTotalRevenue , RevenueMetricCategory ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 41 | CanBeCopied | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `, IncludedInTotalRevenue , RevenueMetricCategory ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (+1 more)) |
| 42 | CanDeposit | BOOLEAN | YES | Whether the user can add funds to their account. False for full-block statuses (IsBlocked=1), close-only/pending statuses (9, 13, 15), status 10 (Deposit Blocked), and status 11 (Social Index). |
| 43 | CanRequestWithdraw | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Na…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+2 more)) |
| 44 | PlayerStatusReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,M…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+2 more)) |
| 45 | PlayerStatusReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 46 | PlayerStatusSubReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,Accoun…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 47 | PlayerStatusSubReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(d…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 48 | CitizenshipCountryID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` (+1 more)) |
| 49 | CitizenshipCountry | STRING | YES | Computed in source (transform kind not classified). Formula: `,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 50 | Amount | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID ,Name AS La…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` (+1 more)) |
| 51 | AffiliateID | INT | YES | Computed in source (transform kind not classified). Formula: `,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID ,Name AS Language ,Communic…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` (+1 more)) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_output.bi_output_vg_date` | Primary | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_date.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_Revenue_Generating_Actions.md` |
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_ouput_v_dim_instrumenttype.md` |
| `main.bi_output.bi_output_customer_ddr_revenue_metrics` | JOIN/UNION | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_customer_ddr_revenue_metrics.md` |
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
main.bi_output.bi_output_vg_date
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions
main.bi_output.bi_ouput_v_dim_instrumenttype
... (15 more upstream(s))
        │
        ▼
main.bi_output.bi_output_vg_revenue   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=52 runtime=52 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_output.bi_output_vg_date` (wiki: `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_date.md`)
- **JOIN/UNION upstreams**: 17 additional object(s)
- **Wiki coverage**: 17/17 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

### 6.2 Referenced By (downstream consumers)

- _(no downstream consumers tracked in `_dag.json`)_

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

*Generated: 2026-05-19 | Concepts: 15 | Formulas: 52 | Tiers: 2 T1, 49 T2, 0 T3, 0 T4, 1 T5, 0 TN, 0 U | Elements: 52/52 | Source: view_definition*
