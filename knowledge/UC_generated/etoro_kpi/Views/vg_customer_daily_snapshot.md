---
object_fqn: main.etoro_kpi.vg_customer_daily_snapshot
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.vg_customer_daily_snapshot
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 62
row_count: null
generated_at: '2026-05-19T15:20:43Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql
concept_count: 15
formula_count: 62
tier_breakdown:
  tier1_columns: 9
  tier2_columns: 52
  tier3_columns: 1
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_customer_daily_snapshot

> View in `main.etoro_kpi`. 15 business concept(s) in §2; 61 of 62 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.vg_customer_daily_snapshot` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 62 |
| **Concepts** | 15 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Tue Feb 24 14:46:48 UTC 2026 |

---

## 1. Business Meaning

`vg_customer_daily_snapshot` is a view in `main.etoro_kpi` that composes 2 CASE-based classifier flag(s) computed from upstream IDs, 13 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Date.md`. Additional upstreams: 15 object(s), listed in §5 Lineage.

Of its 62 columns: 9 inherit byte-for-byte from upstream wikis (Tier 1), 52 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `MifidType` discriminator: `MifidCategorizationID IN (2,3)` (2=Professional, 3=Elective Professional per upstream wiki) → set to '            ' else '      '
**What**: Computed flag on `MifidType` set to `'            '` when the predicates below hold, else `'      '`.
**Columns Involved**: `MifidType`
**Rules**:
- `MifidCategorizationID IN (2,3)` (2=Professional, 3=Elective Professional per upstream wiki)
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql` etoro_kpi.sql L43-L46
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization`

### 2.2 `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0
**What**: Computed flag on `IsPI` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsPI`
**Rules**:
- `GuruStatusID > 1`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql` etoro_kpi.sql L50-L53
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`

### 2.3 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.CountryID = dc.CountryID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql` L82,L92
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

### 2.4 Dim lookup via alias `dpl` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerLevelID = dpl.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql` L84
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

### 2.5 Dim lookup via alias `dmc` → `gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.MifidCategorizationID = dmc.MifidCategorizationID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql` L86
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization`

### 2.6 Dim lookup via alias `dr1` → `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_regulation` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.RegulationID = dr1.DWHRegulationID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql` L88
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`

### 2.7 Dim lookup via alias `dc1` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.RealCID = dc1.RealCID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql` L90
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.8 Dim lookup via alias `dgs` → `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.GuruStatusID = dgs.GuruStatusID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql` L94
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`

### 2.9 Dim lookup via alias `ast` → `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountStatusID = ast.AccountStatusID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql` L96
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`

### 2.10 Dim lookup via alias `act` → `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountTypeID = act.AccountTypeID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql` L98
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`

### 2.11 Dim lookup via alias `pst` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusID = pst.PlayerStatusID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql` L100
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`

### 2.12 Dim lookup via alias `psr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql` L102
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`

### 2.13 Dim lookup via alias `pssr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql` L104
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`

### 2.14 Dim lookup via alias `dl` → `gold_sql_dp_prod_we_dwh_dbo_dim_language`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_language` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.LanguageID = dl.LanguageID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql` L106,L108
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`

### 2.15 Dim lookup via alias `dm` → `gold_sql_dp_prod_we_dwh_dbo_dim_manager`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_manager` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountManagerID = dm.ManagerID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/vg_customer_daily_snapshot.sql` L110
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`

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
| Filter on discriminator flags | Use `IsPI = 1`-style filters on the precomputed flag columns (`IsPI`, `MifidType`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_country`, `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization`, `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `fsc.CountryID = dc.CountryID` | Lookup via alias `dc` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `fsc.PlayerLevelID = dpl.PlayerLevelID` | Lookup via alias `dpl` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization` | `fsc.MifidCategorizationID = dmc.MifidCategorizationID` | Lookup via alias `dmc` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `fsc.RegulationID = dr1.DWHRegulationID` | Lookup via alias `dr1` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `fsc.RealCID = dc1.RealCID` | Lookup via alias `dc1` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | `fsc.GuruStatusID = dgs.GuruStatusID` | Lookup via alias `dgs` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | `fsc.AccountStatusID = ast.AccountStatusID` | Lookup via alias `ast` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | `fsc.AccountTypeID = act.AccountTypeID` | Lookup via alias `act` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `fsc.PlayerStatusID = pst.PlayerStatusID` | Lookup via alias `pst` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | `fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID` | Lookup via alias `psr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | `fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID` | Lookup via alias `pssr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `fsc.LanguageID = dl.LanguageID` | Lookup via alias `dl` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | `fsc.AccountManagerID = dm.ManagerID` | Lookup via alias `dm` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | INT | YES | Primary key. Date encoded as integer YYYYMMDD (e.g. 20260101 for 2026-01-01). The join target for every date-keyed fact in the warehouse. (Tier 1 — DDL + SP_PopulateDimDate) |
| 1 | Date | TIMESTAMP | YES | Native SQL date (e.g. 2026-01-01). 1:1 with DateKey. Use this when a date-typed comparison is needed; use DateKey for integer joins. (Tier 1 — DDL) |
| 2 | MonthNumberOfYear | INT | YES | Month number 1-12 (1=January). (Tier 1 — DDL) |
| 3 | ISOYearAndWeekNumber | STRING | YES | ISO-8601 year+week label, format `YYYYWnn` (e.g. `2026W16` for week 16 of 2026). ISO weeks start Monday and the year boundary follows ISO rules. (Tier 2 — live sample) |
| 4 | DayNumberOfWeek_Sun_Start | INT | YES | Day-of-week with Sunday=1, Saturday=7 (US convention; SET DATEFIRST 7 in SP). (Tier 1 — SP) |
| 5 | MonthName | STRING | YES | Full English month name (`'January'`, `'February'`, ..., `'December'`). (Tier 2 — live sample) |
| 6 | MonthNameAbbreviation | STRING | YES | 3-letter month abbreviation (`'Jan'`, `'Feb'`, ..., `'Dec'`). (Tier 1 — DDL) |
| 7 | DayName | STRING | YES | Full English weekday name (`'Sunday'`, `'Monday'`, ..., `'Saturday'`). (Tier 1 — DDL) |
| 8 | DayNameAbbreviation | STRING | YES | 3-letter weekday abbreviation (`'Sun'`, `'Mon'`, ..., `'Sat'`). (Tier 1 — DDL) |
| 9 | CalendarYear | INT | YES | Calendar year (e.g. 2026). (Tier 1 — DDL) |
| 10 | CalendarYearMonth | STRING | YES | Calendar year-month label, format `YYYY-MM` (e.g. `'2026-04'`). Most common GROUP BY key for monthly rollups. (Tier 2 — live sample) |
| 11 | CalendarYearQtr | STRING | YES | Calendar year-quarter label, format `YYYY-Qn` (e.g. `'2026-Q2'`). (Tier 3 — name-inferred) |
| 12 | IsLastDayOfMonth | STRING | YES | `'Y'` if FullDate is the last day of its calendar month, else `'N'`. (Tier 2 — live sample) |
| 13 | IsWeekday | STRING | YES | `'Y'` if day is Mon-Fri (calendar-only, ignores holidays), else `'N'`. (Tier 2 — live sample) |
| 14 | IsWeekend | STRING | YES | `'Y'` if day is Sat-Sun, else `'N'`. (Tier 1 — DDL) |
| 15 | RealCID | INT | YES | Direct passthrough from upstream. Formula: `RealCID`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`) |
| 16 | IsFunded | INT | YES | Direct passthrough from upstream. Formula: `IsFunded`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`) |
| 17 | ActiveTraded | INT | YES | Direct passthrough from upstream. Formula: `ActiveTraded`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`) |
| 18 | Portfolio_Only | DECIMAL | YES | Direct passthrough from upstream. Formula: `Portfolio_Only`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`) |
| 19 | BalanceOnlyAccount | INT | YES | Direct passthrough from upstream. Formula: `BalanceOnlyAccount`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`) |
| 20 | GlobalDeposited | INT | YES | Direct passthrough from upstream. Formula: `GlobalDeposited`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`) |
| 21 | GlobalRedeposited | INT | YES | Direct passthrough from upstream. Formula: `GlobalRedeposited`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`) |
| 22 | GlobalCashedOut | INT | YES | Direct passthrough from upstream. Formula: `GlobalCashedOut`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`) |
| 23 | Redeemed | INT | YES | Direct passthrough from upstream. Formula: `Redeemed`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`) |
| 24 | RegulationID | INT | YES | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 — via Fact_SnapshotCustomer) |
| 25 | PlayerLevelID | INT | YES | Direct passthrough from upstream. Formula: `PlayerLevelID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 26 | CountryID | INT | YES | Direct passthrough from upstream. Formula: `CountryID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 27 | MifidCategorizationID | INT | YES | Direct passthrough from upstream. Formula: `MifidCategorizationID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 28 | IsValidCustomer | INT | YES | Direct passthrough from upstream. Formula: `IsValidCustomer`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 29 | IsCreditReportValidCB | INT | YES | Direct passthrough from upstream. Formula: `IsCreditReportValidCB`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 30 | Region | STRING | YES | Direct passthrough from upstream. Formula: `MarketingRegionManualName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 31 | Regulation | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`) |
| 32 | Country | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 33 | ClubTier | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`) |
| 34 | MifidCategory | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization`) |
| 35 | MifidType | STRING | NO | `MifidType` discriminator: `MifidCategorizationID IN (2,3)` (2=Professional, 3=Elective Professional per upstream wiki) → set to '            ' else '      '. Formula: `CASE WHEN MifidCategorizationID IN (2,3) THEN 'Professional' ELSE 'Retail' END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization`) |
| 36 | CitizenshipCountry | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 37 | GuruStatusID | INT | YES | Direct passthrough from upstream. Formula: `GuruStatusID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 38 | GuruStatusName | STRING | YES | Direct passthrough from upstream. Formula: `GuruStatusName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`) |
| 39 | IsPI | INT | NO | `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0. Formula: `CASE WHEN GuruStatusID > 1 THEN 1 ELSE 0 END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 40 | AccountStatusID | INT | YES | Direct passthrough from upstream. Formula: `AccountStatusID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 41 | AccountStatusName | STRING | YES | Direct passthrough from upstream. Formula: `AccountStatusName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`) |
| 42 | PlayerStatusID | INT | YES | Direct passthrough from upstream. Formula: `PlayerStatusID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 43 | PlayerStatusName | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 44 | CanOpenPosition | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanOpenPosition`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 45 | CanClosePosition | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanClosePosition`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 46 | CanEditPosition | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanEditPosition`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 47 | CanBeCopied | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanBeCopied`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 48 | CanDeposit | BOOLEAN | YES | Whether the user can add funds to their account. False for full-block statuses (IsBlocked=1), close-only/pending statuses (9, 13, 15), status 10 (Deposit Blocked), and status 11 (Social Index). |
| 49 | CanRequestWithdraw | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanRequestWithdraw`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 50 | PlayerStatusReasonID | INT | YES | Direct passthrough from upstream. Formula: `PlayerStatusReasonID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 51 | PlayerStatusReasonName | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`) |
| 52 | PlayerStatusSubReasonID | INT | YES | Direct passthrough from upstream. Formula: `PlayerStatusSubReasonID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 53 | PlayerStatusSubReasonName | STRING | YES | Direct passthrough from upstream. Formula: `PlayerStatusSubReasonName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`) |
| 54 | AccountManagerID | INT | YES | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 — via Fact_SnapshotCustomer) |
| 55 | AccountManager | STRING | YES | Function call computed in source. Formula: `concat(FirstName, ' ', LastName)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`) |
| 56 | LanguageID | INT | YES | Direct passthrough from upstream. Formula: `LanguageID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 57 | Language | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`) |
| 58 | CommunicationLanguageID | INT | YES | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 — via Fact_SnapshotCustomer) |
| 59 | CommunicationLanguage | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`) |
| 60 | AccountTypeID | INT | YES | Direct passthrough from upstream. Formula: `AccountTypeID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 61 | AccountType | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Date.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Customer_Daily_Status.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mifidcategorization` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_MifidCategorization.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_GuruStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatus.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerStatusSubReasons.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Manager.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Language.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_AccountType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
... (13 more upstream(s))
        │
        ▼
main.etoro_kpi.vg_customer_daily_snapshot   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=62 runtime=62 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Date.md`)
- **JOIN/UNION upstreams**: 15 additional object(s)
- **Wiki coverage**: 15/15 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 15 | Formulas: 62 | Tiers: 9 T1, 52 T2, 1 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 62/62 | Source: view_definition*
