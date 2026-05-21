---
object_fqn: main.bi_output.bi_output_vg_mimo
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_mimo
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 63
row_count: null
generated_at: '2026-05-19T15:01:51Z'
upstreams:
- main.bi_output.bi_output_vg_date
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
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql
concept_count: 14
formula_count: 63
tier_breakdown:
  tier1_columns: 1
  tier2_columns: 62
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_vg_mimo

> View in `main.bi_output`. 14 business concept(s) in §2; 63 of 63 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_mimo` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 63 |
| **Concepts** | 14 (see §2) |
| **Downstream consumers** | 1 (see §6.2) |
| **Generated** | 2026-05-19 |
| **Created** | Thu Jan 15 12:19:14 UTC 2026 |

---

## 1. Business Meaning

`bi_output_vg_mimo` is a view in `main.bi_output` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 13 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_output.bi_output_vg_date` → this object. Canonical upstream documentation: `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_date.md`. Additional upstreams: 15 object(s), listed in §5 Lineage.

Of its 63 columns: 1 inherit byte-for-byte from upstream wikis (Tier 1), 62 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0
**What**: Computed flag on `IsPI` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsPI`
**Rules**:
- `GuruStatusID > 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql` bi_output.sql L32-L32
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`

### 2.2 Dim lookup via alias `dcu` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `map.RealCID = dcu.RealCID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql` L72
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.3 Dim lookup via alias `dpl` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerLevelID = dpl.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql` L80
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

### 2.4 Dim lookup via alias `dm` → `gold_sql_dp_prod_we_dwh_dbo_dim_manager`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_manager` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountManagerID = dm.ManagerID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql` L82
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`

### 2.5 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_regulation` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.RegulationID = dr.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql` L84
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`

### 2.6 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.CountryID = dc.CountryID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql` L86,L106
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

### 2.7 Dim lookup via alias `dl` → `gold_sql_dp_prod_we_dwh_dbo_dim_language`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_language` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.LanguageID = dl.LanguageID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql` L88,L104
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`

### 2.8 Dim lookup via alias `dv` → `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.VerificationLevelID = dv.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql` L90
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`

### 2.9 Dim lookup via alias `gs` → `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.GuruStatusID = gs.GuruStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql` L92
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`

### 2.10 Dim lookup via alias `ast` → `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountStatusID = ast.AccountStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql` L94
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`

### 2.11 Dim lookup via alias `act` → `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountTypeID = act.AccountTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql` L96
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`

### 2.12 Dim lookup via alias `pst` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusID = pst.PlayerStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql` L98
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`

### 2.13 Dim lookup via alias `psr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql` L100
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`

### 2.14 Dim lookup via alias `pssr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_mimo.sql` L102
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
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `map.RealCID = dcu.RealCID` | Lookup via alias `dcu` |
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
| 1 | DateID | INT | YES | Arithmetic combination of upstream columns. Formula: `-- ========================================================================== -- Source: information_schema.views.view_definition -- Object: bi_output.bi_output_vg_mimo -- Captured: 2026-05-19T14…`. (Tier 2 — computed in source) |
| 1 | Date | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,Date`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 2 | WeekNumberYear | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 3 | CalendarYearMonth | STRING | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 4 | CalendarQuarter | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 5 | CalendarYear | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 6 | PlayerLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 7 | ClubTier | STRING | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 8 | RegulationID | INT | YES | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 — via Fact_SnapshotCustomer) |
| 9 | Regulation | STRING | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 10 | VerificationLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 11 | VerificationLevel | STRING | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 12 | CountryID | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 13 | Country | STRING | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 14 | Region | STRING | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 15 | AccountManagerID | INT | YES | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 — via Fact_SnapshotCustomer) |
| 16 | AccountManager | STRING | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 17 | LanguageID | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 18 | Language | STRING | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 19 | CommunicationLanguageID | INT | YES | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 — via Fact_SnapshotCustomer) |
| 20 | CommunicationLanguage | STRING | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 21 | AccountTypeID | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 22 | AccountType | STRING | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 23 | GuruStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 24 | GuruStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 25 | IsPI | INT | NO | `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0. Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 26 | AccountStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 27 | AccountStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 28 | PlayerStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 29 | PlayerStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 30 | CanOpenPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,Date ,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 31 | CanClosePosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,WeekNumberYear ,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,Ver…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 32 | CanEditPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 33 | CanBeCopied | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,CalendarQuarter ,CalendarYear ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS Verifica…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date` (+2 more)) |
| 34 | CanDeposit | BOOLEAN | YES | Whether the user can add funds to their account. False for full-block statuses (IsBlocked=1), close-only/pending statuses (9, 13, 15), status 10 (Deposit Blocked), and status 11 (Social Index). |
| 35 | CanRequestWithdraw | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Na…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+2 more)) |
| 36 | PlayerStatusReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,M…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+2 more)) |
| 37 | PlayerStatusReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 38 | PlayerStatusSubReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,Accoun…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 39 | PlayerStatusSubReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(d…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 40 | CitizenshipCountryID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` (+1 more)) |
| 41 | CitizenshipCountry | STRING | YES | Computed in source (transform kind not classified). Formula: `,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 42 | RealCID | STRING | YES | Global Real Customer Identifier on the ledger row (`fca.RealCID`). (Tier 1 — Customer.CustomerStatic) |
| 43 | DepositRealCID | INT | YES | Computed in source (transform kind not classified). Formula: `,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID ,Name AS Language ,Communic…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` (+1 more)) |
| 44 | WithdrawRealCID | INT | YES | Computed in source (transform kind not classified). Formula: `,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID ,Name AS Language ,CommunicationLanguageID ,Name AS Communicati…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 45 | GlobalDepositsCount | LONG | YES | Computed in source (transform kind not classified). Formula: `,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID ,Name AS Language ,CommunicationLanguageID ,Name AS CommunicationLanguage ,Accoun…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 46 | GlobalWithdrawsCount | LONG | YES | Computed in source (transform kind not classified). Formula: `,LanguageID ,Name AS Language ,CommunicationLanguageID ,Name AS CommunicationLanguage ,AccountTypeID ,Name AS AccountType ,GuruStatusID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 47 | GlobalDepositsAmount | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,Name AS Language ,CommunicationLanguageID ,Name AS CommunicationLanguage ,AccountTypeID ,Name AS AccountType ,GuruStatusID ,GuruStatusNam…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` (+1 more)) |
| 48 | GlobalWithdrawsAmount | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `,CommunicationLanguageID ,Name AS CommunicationLanguage ,AccountTypeID ,Name AS AccountType ,GuruStatusID ,GuruStatusName ,CASE WHEN Gur…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` (+1 more)) |
| 49 | TotalFTDGlobalAmount | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `,Name AS CommunicationLanguage ,AccountTypeID ,Name AS AccountType ,GuruStatusID ,GuruStatusName ,CASE WHEN GuruStatusID > 1 THEN 1 else 0 END AS …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` (+1 more)) |
| 50 | TotalFTDGlobalCount | LONG | YES | Computed flag (CASE expression in source). Formula: `,AccountTypeID ,Name AS AccountType ,GuruStatusID ,GuruStatusName ,CASE WHEN GuruStatusID > 1 THEN 1 else 0 END AS IsPI ,AccountStatusID ,a…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 51 | GlobalWithdraw_ExclRedeem | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `,GuruStatusID ,GuruStatusName ,CASE WHEN GuruStatusID > 1 THEN 1 else 0 END AS IsPI ,AccountStatusID ,AccountStatusName ,PlayerStatusID ,ps…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 52 | TransferCoins | DECIMAL | YES | Computed flag (CASE expression in source). Formula: `,GuruStatusName ,CASE WHEN GuruStatusID > 1 THEN 1 else 0 END AS IsPI ,AccountStatusID ,AccountStatusName ,PlayerStatusID ,Name as PlayerStatusNa…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` (+1 more)) |
| 53 | CountRedeems | LONG | YES | Computed flag (CASE expression in source). Formula: `,CASE WHEN GuruStatusID > 1 THEN 1 else 0 END AS IsPI ,AccountStatusID ,AccountStatusName ,PlayerStatusID ,Name as PlayerStatusName ,CanOpenPosit…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 54 | ExternalDepositsTPAmount | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,AccountStatusID ,AccountStatusName ,PlayerStatusID ,Name as PlayerStatusName ,CanOpenPosition ,CanClosePosition ,CanEditPosition …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 55 | ExternalWithdrawTPAmount | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,AccountStatusName ,PlayerStatusID ,Name as PlayerStatusName ,CanOpenPosition ,CanClosePosition ,CanEditPosition ,CanBeCopied ,pst…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 56 | ExternalDepositsTPCount | LONG | YES | Computed in source (transform kind not classified). Formula: `,PlayerStatusID ,Name as PlayerStatusName ,CanOpenPosition ,CanClosePosition ,CanEditPosition ,CanBeCopied ,CanDeposit ,CanReq…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 57 | ExternalWithdrawTPCount | LONG | YES | Computed in source (transform kind not classified). Formula: `,Name as PlayerStatusName ,CanOpenPosition ,CanClosePosition ,CanEditPosition ,CanBeCopied ,CanDeposit ,CanRequestWithdraw ,Pl…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 58 | ExternalDepositToIBANAmount | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,CanOpenPosition ,CanClosePosition ,CanEditPosition ,CanBeCopied ,CanDeposit ,CanRequestWithdraw ,PlayerStatusReasonID ,Name A…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 59 | ExternalWithdrawFromIBANAmount | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,CanClosePosition ,CanEditPosition ,CanBeCopied ,CanDeposit ,CanRequestWithdraw ,PlayerStatusReasonID ,Name AS PlayerStatusReasonName …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 60 | ExternalDepositToIBANCount | LONG | YES | Computed in source (transform kind not classified). Formula: `,CanEditPosition ,CanBeCopied ,CanDeposit ,CanRequestWithdraw ,PlayerStatusReasonID ,Name AS PlayerStatusReasonName ,PlayerStatusSubReas…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 61 | ExternalWithdrawFromIBANCount | LONG | YES | Computed in source (transform kind not classified). Formula: `,CanBeCopied ,CanDeposit ,CanRequestWithdraw ,PlayerStatusReasonID ,Name AS PlayerStatusReasonName ,PlayerStatusSubReasonID ,PlayerStat…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` (+1 more)) |
| 62 | AffiliateID | INT | YES | Computed in source (transform kind not classified). Formula: `,CanDeposit ,CanRequestWithdraw ,PlayerStatusReasonID ,Name AS PlayerStatusReasonName ,PlayerStatusSubReasonID ,PlayerStatusSubReasonName ,…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` (+1 more)) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_output.bi_output_vg_date` | Primary | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_date.md` |
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
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_MIMO_AllPlatforms.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_output.bi_output_vg_date
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
... (13 more upstream(s))
        │
        ▼
main.bi_output.bi_output_vg_mimo   ←── this object
        │
        ▼
main.bi_dealing_stg.bi_output_dealing_bod_overview_investment_etoro
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=63 runtime=63 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_output.bi_output_vg_date` (wiki: `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_date.md`)
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

*Generated: 2026-05-19 | Concepts: 14 | Formulas: 63 | Tiers: 1 T1, 62 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 63/63 | Source: view_definition*
