---
object_fqn: main.bi_output.bi_output_vg_ddr_customers_snapshot
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_ddr_customers_snapshot
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 102
row_count: null
generated_at: '2026-06-19T14:35:56Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql
concept_count: 15
formula_count: 102
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 102
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_vg_ddr_customers_snapshot

> View in `main.bi_output`. 15 business concept(s) in §2; 102 of 102 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_ddr_customers_snapshot` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 102 |
| **Concepts** | 15 (see §2) |
| **Downstream consumers** | 1 (see §6.2) |
| **Generated** | 2026-06-19 |
| **Created** | Thu Jan 22 09:00:46 UTC 2026 |

---

## 1. Business Meaning

`bi_output_vg_ddr_customers_snapshot` is a view in `main.bi_output` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 14 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Customer_Daily_Status.md`. Additional upstreams: 18 object(s), listed in §5 Lineage.

Of its 102 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 102 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0
**What**: Computed flag on `IsPI` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsPI`
**Rules**:
- `GuruStatusID > 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql` bi_output.sql L31-L34
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`

### 2.2 Dim lookup via alias `dcu` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `ddrc.RealCID = dcu.RealCID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql` L120
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.3 Dim lookup via alias `dpl` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerLevelID = dpl.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql` L122
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

### 2.4 Dim lookup via alias `dm` → `gold_sql_dp_prod_we_dwh_dbo_dim_manager`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_manager` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountManagerID = dm.ManagerID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql` L124
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`

### 2.5 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_regulation` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.RegulationID = dr.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql` L126
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`

### 2.6 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.CountryID = dc.CountryID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql` L128,L150
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

### 2.7 Dim lookup via alias `dl` → `gold_sql_dp_prod_we_dwh_dbo_dim_language`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_language` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.LanguageID = dl.LanguageID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql` L130,L146
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`

### 2.8 Dim lookup via alias `dv` → `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.VerificationLevelID = dv.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql` L132
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`

### 2.9 Dim lookup via alias `gs` → `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.GuruStatusID = gs.GuruStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql` L134
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`

### 2.10 Dim lookup via alias `ast` → `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountStatusID = ast.AccountStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql` L136
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`

### 2.11 Dim lookup via alias `act` → `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountTypeID = act.AccountTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql` L138
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`

### 2.12 Dim lookup via alias `pst` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusID = pst.PlayerStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql` L140
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`

### 2.13 Dim lookup via alias `psr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql` L142
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`

### 2.14 Dim lookup via alias `pssr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql` L144
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`

### 2.15 Dim lookup via alias `dd` → `gold_sql_dp_prod_we_dwh_dbo_dim_date`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_date` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dd.DateKey between dcl.FromDateID and dcl.ToDateID               and dd.FullDate <= to_date(getdate(`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_ddr_customers_snapshot.sql` L164
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`

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
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `ddrc.RealCID = dcu.RealCID` | Lookup via alias `dcu` |
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
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `dd.DateKey between dcl.FromDateID and dcl.ToDateID               and dd.FullDate <= to_date(getdate(` | Lookup via alias `dd` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | STRING | YES | Real customer identifier (HASH distribution key). One row per `RealCID` per `DateID` after RN dedup. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 1 | GCID | INT | YES | Direct passthrough from upstream. Formula: `GCID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 2 | Date | TIMESTAMP | YES | Calendar business date evaluated by `SP_DDR_Customer_Daily_Status` (= `@date` parameter). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 3 | DateID | INT | YES | `@dateID` (`YYYYMMDD`) — partition / delete key for the narrow table. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 4 | PlayerLevelID | INT | YES | Direct passthrough from upstream. Formula: `PlayerLevelID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 5 | ClubTier | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`) |
| 6 | RegulationID | INT | YES | Direct passthrough from upstream. Formula: `RegulationID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 7 | Regulation | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`) |
| 8 | VerificationLevelID | INT | YES | Direct passthrough from upstream. Formula: `VerificationLevelID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 9 | VerificationLevel | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`) |
| 10 | CountryID | INT | YES | Direct passthrough from upstream. Formula: `CountryID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 11 | Country | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 12 | Region | STRING | YES | Direct passthrough from upstream. Formula: `MarketingRegionManualName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 13 | AccountManagerID | INT | YES | Direct passthrough from upstream. Formula: `AccountManagerID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 14 | AccountManager | STRING | YES | Function call computed in source. Formula: `concat(FirstName, ' ', LastName)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`) |
| 15 | LanguageID | INT | YES | Direct passthrough from upstream. Formula: `LanguageID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 16 | Language | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`) |
| 17 | CommunicationLanguageID | INT | YES | Direct passthrough from upstream. Formula: `CommunicationLanguageID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 18 | CommunicationLanguage | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`) |
| 19 | AccountTypeID | INT | YES | Direct passthrough from upstream. Formula: `AccountTypeID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 20 | AccountType | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`) |
| 21 | GuruStatusID | INT | YES | Direct passthrough from upstream. Formula: `GuruStatusID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 22 | GuruStatusName | STRING | YES | Direct passthrough from upstream. Formula: `GuruStatusName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`) |
| 23 | IsPI | INT | NO | `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0. Formula: `CASE WHEN GuruStatusID > 1 THEN 1 else 0 END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 24 | AccountStatusID | INT | YES | Direct passthrough from upstream. Formula: `AccountStatusID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 25 | AccountStatusName | STRING | YES | Direct passthrough from upstream. Formula: `AccountStatusName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`) |
| 26 | PlayerStatusID | INT | YES | Direct passthrough from upstream. Formula: `PlayerStatusID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 27 | PlayerStatusName | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 28 | CanOpenPosition | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanOpenPosition`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 29 | CanClosePosition | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanClosePosition`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 30 | CanEditPosition | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanEditPosition`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 31 | CanBeCopied | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanBeCopied`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 32 | CanDeposit | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanDeposit`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 33 | CanRequestWithdraw | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanRequestWithdraw`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 34 | PlayerStatusReasonID | INT | YES | Direct passthrough from upstream. Formula: `PlayerStatusReasonID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 35 | PlayerStatusReasonName | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`) |
| 36 | PlayerStatusSubReasonID | INT | YES | Direct passthrough from upstream. Formula: `PlayerStatusSubReasonID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 37 | PlayerStatusSubReasonName | STRING | YES | Direct passthrough from upstream. Formula: `PlayerStatusSubReasonName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`) |
| 38 | WeekNumberYear | INT | YES | Direct passthrough from upstream. Formula: `WeekNumberYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 39 | CalendarYearMonth | STRING | YES | Direct passthrough from upstream. Formula: `CalendarYearMonth`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 40 | CalendarQuarter | INT | YES | Direct passthrough from upstream. Formula: `CalendarQuarter`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 41 | CalendarYear | INT | YES | Direct passthrough from upstream. Formula: `CalendarYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 42 | IsLastDayWeek | INT | NO | Direct passthrough from upstream. Formula: `IsLastDayWeek`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 43 | IsLastDayMonth | INT | NO | Direct passthrough from upstream. Formula: `IsLastDayMonth`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 44 | IsLastDayQuarter | INT | NO | Direct passthrough from upstream. Formula: `IsLastDayQuarter`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 45 | IsLastDayYear | INT | NO | Direct passthrough from upstream. Formula: `IsLastDayYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 46 | CitizenshipCountryID | INT | YES | Direct passthrough from upstream. Formula: `CitizenshipCountryID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 47 | CitizenshipCountry | STRING | YES | Computed in source (transform kind not classified). Formula: `Name CitizenshipCountry`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 48 | AffiliateID | INT | YES | Direct passthrough from upstream. Formula: `AffiliateID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 49 | ClusterDetail | STRING | YES | Direct passthrough from upstream. Formula: `cdl.ClusterDetail`. (Tier 2 — computed in source) |
| 50 | ClusterSF | STRING | YES | Direct passthrough from upstream. Formula: `cdl.ClusterSF`. (Tier 2 — computed in source) |
| 51 | IsLastCluster | INT | YES | Direct passthrough from upstream. Formula: `cdl.IsLastCluster`. (Tier 2 — computed in source) |
| 52 | IsFirstCluster | INT | YES | Direct passthrough from upstream. Formula: `cdl.IsFirstCluster`. (Tier 2 — computed in source) |
| 53 | IsSFCluster | INT | YES | Direct passthrough from upstream. Formula: `cdl.IsSFCluster`. (Tier 2 — computed in source) |
| 54 | UpdateDateIDSF | INT | YES | Direct passthrough from upstream. Formula: `cdl.UpdateDateIDSF`. (Tier 2 — computed in source) |
| 55 | ClusterDynamic | STRING | YES | Direct passthrough from upstream. Formula: `cdl.ClusterDynamic`. (Tier 2 — computed in source) |
| 56 | ActiveTraded | INT | YES | 1 when `Function_Population_Active_Traders(@dateID,@dateID)` marks the CID as DDR-active (explicit trades / mirror participation / qualifying Options actions — see TVF wiki / SP commentary). Default `ISNULL` to 0 in INSERT. (Tier 2 — Function_Population_Active_Traders) |
| 57 | BalanceOnlyAccount | INT | YES | Presence/measure flag from `Function_Population_Balance_Only_Accounts(@dateID,@dateID)` — customer had **positive equity** but **no** qualifying open-position / trading activity tiers. Stored as int indicator in INSERT path. (Tier 2 — Function_Population_Balance_Only_Accounts) |
| 58 | Portfolio_Only | DECIMAL | YES | **`Function_Population_Portfolio_Only`** output persisted as DECIMAL per DDL — analytics treat nonzero as **portfolio/HODL** segment participation for `@date`. `AccountActive` tests `ISNULL(Portfolio_Only,0)` in SP logic. (Tier 2 — Function_Population_Portfolio_Only) |
| 59 | AccountActive | INT | YES | Derived: **`1` iff `ActiveTraded = 1 OR ISNULL(Portfolio_Only,0) <> 0`** (see `#enrichStatusActions`). Encapsulates intentional engagement vs inactive tiers. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 60 | AccountInActive | INT | YES | Derived flag for customers occupying the explicit **inactive** bucket after removing balanced segment winners (`EXCEPT` ladders in `#inactive`). Requires understanding mutual exclusivity with active tiers — see sibling periodic wiki diagrams. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 61 | IsFunded | INT | YES | Indicator that customer appears in **`Function_Population_Funded(@dateID)`** output for that date (`CASE WHEN Equity join exists`). (Tier 2 — Function_Population_Funded) |
| 62 | ActiveTraded_ThisWeek | INT | YES | Direct passthrough from upstream. Formula: `ActiveTraded_ThisWeek`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 63 | ActiveTraded_ThisMonth | INT | YES | Direct passthrough from upstream. Formula: `ActiveTraded_ThisMonth`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 64 | ActiveTraded_ThisQuarter | INT | YES | Direct passthrough from upstream. Formula: `ActiveTraded_ThisQuarter`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 65 | ActiveTraded_ThisYear | INT | YES | Direct passthrough from upstream. Formula: `ActiveTraded_ThisYear`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 66 | BalanceOnlyAccount_ThisWeek | INT | YES | Direct passthrough from upstream. Formula: `BalanceOnlyAccount_ThisWeek`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 67 | BalanceOnlyAccount_ThisMonth | INT | YES | Direct passthrough from upstream. Formula: `BalanceOnlyAccount_ThisMonth`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 68 | BalanceOnlyAccount_ThisQuarter | INT | YES | Direct passthrough from upstream. Formula: `BalanceOnlyAccount_ThisQuarter`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 69 | BalanceOnlyAccount_ThisYear | INT | YES | Direct passthrough from upstream. Formula: `BalanceOnlyAccount_ThisYear`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 70 | Portfolio_Only_ThisWeek | INT | YES | Direct passthrough from upstream. Formula: `Portfolio_Only_ThisWeek`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 71 | Portfolio_Only_ThisMonth | INT | YES | Direct passthrough from upstream. Formula: `Portfolio_Only_ThisMonth`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 72 | Portfolio_Only_ThisQuarter | INT | YES | Direct passthrough from upstream. Formula: `Portfolio_Only_ThisQuarter`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 73 | Portfolio_Only_ThisYear | INT | YES | Direct passthrough from upstream. Formula: `Portfolio_Only_ThisYear`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 74 | IsFunded_ThisWeek | INT | YES | Direct passthrough from upstream. Formula: `IsFunded_ThisWeek`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 75 | IsFunded_ThisMonth | INT | YES | Direct passthrough from upstream. Formula: `IsFunded_ThisMonth`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 76 | IsFunded_ThisQuarter | INT | YES | Direct passthrough from upstream. Formula: `IsFunded_ThisQuarter`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 77 | IsFunded_ThisYear | INT | YES | Direct passthrough from upstream. Formula: `IsFunded_ThisYear`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 78 | RegulationID_ThisWeek | INT | YES | Direct passthrough from upstream. Formula: `RegulationID_ThisWeek`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 79 | RegulationID_ThisMonth | INT | YES | Direct passthrough from upstream. Formula: `RegulationID_ThisMonth`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 80 | RegulationID_ThisQuarter | INT | YES | Direct passthrough from upstream. Formula: `RegulationID_ThisQuarter`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 81 | RegulationID_ThisYear | INT | YES | Direct passthrough from upstream. Formula: `RegulationID_ThisYear`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 82 | CountryID_ThisWeek | INT | YES | Direct passthrough from upstream. Formula: `CountryID_ThisWeek`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 83 | CountryID_ThisMonth | INT | YES | Direct passthrough from upstream. Formula: `CountryID_ThisMonth`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 84 | CountryID_ThisQuarter | INT | YES | Direct passthrough from upstream. Formula: `CountryID_ThisQuarter`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 85 | CountryID_ThisYear | INT | YES | Direct passthrough from upstream. Formula: `CountryID_ThisYear`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 86 | IsCreditReportValidCB_ThisWeek | INT | YES | Direct passthrough from upstream. Formula: `IsCreditReportValidCB_ThisWeek`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 87 | IsCreditReportValidCB_ThisMonth | INT | YES | Direct passthrough from upstream. Formula: `IsCreditReportValidCB_ThisMonth`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 88 | IsCreditReportValidCB_ThisQuarter | INT | YES | Direct passthrough from upstream. Formula: `IsCreditReportValidCB_ThisQuarter`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 89 | IsCreditReportValidCB_ThisYear | INT | YES | Direct passthrough from upstream. Formula: `IsCreditReportValidCB_ThisYear`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 90 | IsValidCustomer_ThisWeek | INT | YES | Direct passthrough from upstream. Formula: `IsValidCustomer_ThisWeek`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 91 | IsValidCustomer_ThisMonth | INT | YES | Direct passthrough from upstream. Formula: `IsValidCustomer_ThisMonth`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 92 | IsValidCustomer_ThisQuarter | INT | YES | Direct passthrough from upstream. Formula: `IsValidCustomer_ThisQuarter`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 93 | IsValidCustomer_ThisYear | INT | YES | Direct passthrough from upstream. Formula: `IsValidCustomer_ThisYear`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 94 | MarketingRegion_ThisWeek | STRING | YES | Direct passthrough from upstream. Formula: `MarketingRegion_ThisWeek`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 95 | MarketingRegion_ThisMonth | STRING | YES | Direct passthrough from upstream. Formula: `MarketingRegion_ThisMonth`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 96 | MarketingRegion_ThisQuarter | STRING | YES | Direct passthrough from upstream. Formula: `MarketingRegion_ThisQuarter`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 97 | MarketingRegion_ThisYear | STRING | YES | Direct passthrough from upstream. Formula: `MarketingRegion_ThisYear`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 98 | ClubTier_ThisWeek | INT | YES | Direct passthrough from upstream. Formula: `PlayerLevelID_ThisWeek`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 99 | ClubTier_ThisMonth | INT | YES | Direct passthrough from upstream. Formula: `PlayerLevelID_ThisMonth`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 100 | ClubTier_ThisQuarter | INT | YES | Direct passthrough from upstream. Formula: `PlayerLevelID_ThisQuarter`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |
| 101 | ClubTier_ThisYear | INT | YES | Direct passthrough from upstream. Formula: `PlayerLevelID_ThisYear`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Customer_Daily_Status.md` |
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
| `main.bi_output.bi_output_vg_date` | JOIN/UNION | `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Customer_Periodic_Status.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailycluster` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_DailyCluster.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Date.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
... (16 more upstream(s))
        │
        ▼
main.bi_output.bi_output_vg_ddr_customers_snapshot   ←── this object
        │
        ▼
main.bi_dealing_stg.bi_output_dealing_bod_overview_investment_etoro
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=102 runtime=102 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Customer_Daily_Status.md`)
- **JOIN/UNION upstreams**: 18 additional object(s)
- **Wiki coverage**: 18/18 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 15 | Formulas: 102 | Tiers: 0 T1, 102 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 102/102 | Source: view_definition*
