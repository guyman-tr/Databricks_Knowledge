---
object_fqn: main.bi_output.bi_output_vg_customer_snapshot_test
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_customer_snapshot_test
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 56
row_count: null
generated_at: '2026-06-19T14:35:55Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.bi_output.bi_output_vg_date
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
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql
concept_count: 14
formula_count: 56
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 56
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_vg_customer_snapshot_test

> View in `main.bi_output`. 14 business concept(s) in §2; 56 of 56 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_customer_snapshot_test` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | guyman@etoro.com |
| **Row count** | n/a |
| **Column count** | 56 |
| **Concepts** | 14 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Sun Mar 08 13:20:38 UTC 2026 |

---

## 1. Business Meaning

`bi_output_vg_customer_snapshot_test` is a view in `main.bi_output` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 13 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md`. Additional upstreams: 14 object(s), listed in §5 Lineage.

Of its 56 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 56 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0
**What**: Computed flag on `IsPI` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsPI`
**Rules**:
- `GuruStatusID > 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql` bi_output.sql L31-L34
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`

### 2.2 Dim lookup via alias `dcu` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.RealCID = dcu.RealCID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql` L71
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.3 Dim lookup via alias `dpl` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerLevelID = dpl.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql` L73
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

### 2.4 Dim lookup via alias `dm` → `gold_sql_dp_prod_we_dwh_dbo_dim_manager`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_manager` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountManagerID = dm.ManagerID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql` L75
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`

### 2.5 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_regulation` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.RegulationID = dr.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql` L77
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`

### 2.6 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.CountryID = dc.CountryID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql` L79,L99
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

### 2.7 Dim lookup via alias `dl` → `gold_sql_dp_prod_we_dwh_dbo_dim_language`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_language` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.LanguageID = dl.LanguageID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql` L81,L97
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`

### 2.8 Dim lookup via alias `dv` → `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.VerificationLevelID = dv.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql` L83
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`

### 2.9 Dim lookup via alias `gs` → `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.GuruStatusID = gs.GuruStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql` L85
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`

### 2.10 Dim lookup via alias `ast` → `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountStatusID = ast.AccountStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql` L87
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`

### 2.11 Dim lookup via alias `act` → `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountTypeID = act.AccountTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql` L89
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`

### 2.12 Dim lookup via alias `pst` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusID = pst.PlayerStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql` L91
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`

### 2.13 Dim lookup via alias `psr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql` L93
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`

### 2.14 Dim lookup via alias `pssr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_snapshot_test.sql` L95
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
| 1 | RealCID | STRING | YES | Real (funded) customer ID. Hash distribution key. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). 46.4M distinct values. (Tier 2 — via Fact_SnapshotCustomer) |
| 1 | GCID | INT | YES | Global Customer ID — the cross-platform identifier linking RealCID to demo and external systems. Source: Ext_FSC_Real_Customer_Customer (primary), Ext_Dim_Customer_CustomerIdentification_DLT (fallback). (Tier 2 — via Fact_SnapshotCustomer) |
| 2 | Date | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `Date`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 3 | DateID | INT | YES | Direct passthrough from upstream. Formula: `DateID`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 4 | PlayerLevelID | INT | YES | Account tier (4=demo, other=real tiers). FK to Dim_PlayerLevel. Critical for IsValidCustomer. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 5 | ClubTier | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`) |
| 6 | RegulationID | INT | YES | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 — via Fact_SnapshotCustomer) |
| 7 | Regulation | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`) |
| 8 | VerificationLevelID | INT | YES | KYC verification level. FK to Dim_VerificationLevel. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 9 | VerificationLevel | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`) |
| 10 | CountryID | INT | YES | Customer's registered country. FK to Dim_Country. Key filter for valid customer segmentation. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 11 | Country | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 12 | Region | STRING | YES | Direct passthrough from upstream. Formula: `MarketingRegionManualName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 13 | AccountManagerID | INT | YES | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 — via Fact_SnapshotCustomer) |
| 14 | AccountManager | STRING | YES | Function call computed in source. Formula: `concat(FirstName, ' ', LastName)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`) |
| 15 | LanguageID | INT | YES | Customer's preferred interface language. FK to Dim_Language. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 16 | Language | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`) |
| 17 | CommunicationLanguageID | INT | YES | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 — via Fact_SnapshotCustomer) |
| 18 | CommunicationLanguage | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`) |
| 19 | AccountTypeID | INT | YES | Account type (e.g., 7=Employee, 9=excluded). FK to Dim_AccountType. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 20 | AccountType | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`) |
| 21 | GuruStatusID | INT | YES | Popular Investor (Guru) program status. FK to Dim_GuruStatus. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 22 | GuruStatusName | STRING | YES | Direct passthrough from upstream. Formula: `GuruStatusName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`) |
| 23 | IsPI | INT | NO | `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0. Formula: `CASE WHEN GuruStatusID > 1 THEN 1 else 0 END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 24 | AccountStatusID | INT | YES | Account enabled/suspended status. FK to Dim_AccountStatus. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
| 25 | AccountStatusName | STRING | YES | Direct passthrough from upstream. Formula: `AccountStatusName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`) |
| 26 | PlayerStatusID | INT | YES | Customer lifecycle status. FK to Dim_PlayerStatus. (Tier 2 — inherited from Fact_SnapshotCustomer wiki) |
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
| 49 | ClusterDetail | NULL | YES | Literal constant set in this object. Formula: `NULL`. (Tier 2 — literal) |
| 50 | ClusterSF | NULL | YES | Literal constant set in this object. Formula: `NULL`. (Tier 2 — literal) |
| 51 | IsLastCluster | NULL | YES | Literal constant set in this object. Formula: `NULL`. (Tier 2 — literal) |
| 52 | IsFirstCluster | NULL | YES | Literal constant set in this object. Formula: `NULL`. (Tier 2 — literal) |
| 53 | IsSFCluster | NULL | YES | Literal constant set in this object. Formula: `NULL`. (Tier 2 — literal) |
| 54 | UpdateDateIDSF | NULL | YES | Literal constant set in this object. Formula: `NULL`. (Tier 2 — literal) |
| 55 | ClusterDynamic | NULL | YES | Literal constant set in this object. Formula: `NULL`. (Tier 2 — literal) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.bi_output.bi_output_vg_date` | JOIN/UNION | `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |
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
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
main.bi_output.bi_output_vg_date
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
... (12 more upstream(s))
        │
        ▼
main.bi_output.bi_output_vg_customer_snapshot_test   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=56 runtime=56 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md`)
- **JOIN/UNION upstreams**: 14 additional object(s)
- **Wiki coverage**: 14/14 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 14 | Formulas: 56 | Tiers: 0 T1, 56 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 56/56 | Source: view_definition*
