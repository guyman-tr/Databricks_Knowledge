---
object_fqn: main.bi_output.bi_output_vg_club
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_club
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 69
row_count: null
generated_at: '2026-05-19T15:01:46Z'
upstreams:
- main.bi_output.bi_output_vg_date
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql
concept_count: 16
formula_count: 69
tier_breakdown:
  tier1_columns: 1
  tier2_columns: 68
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_vg_club

> View in `main.bi_output`. 16 business concept(s) in §2; 69 of 69 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_club` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 69 |
| **Concepts** | 16 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Mar 09 13:52:41 UTC 2026 |

---

## 1. Business Meaning

`bi_output_vg_club` is a view in `main.bi_output` that composes 2 CASE-based classifier flag(s) computed from upstream IDs, 13 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_output.bi_output_vg_date` → this object. Canonical upstream documentation: `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_date.md`. Additional upstreams: 16 object(s), listed in §5 Lineage.

Of its 69 columns: 1 inherit byte-for-byte from upstream wikis (Tier 1), 68 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0
**What**: Computed flag on `IsPI` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsPI`
**Rules**:
- `GuruStatusID > 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` bi_output.sql L58-L61
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`

### 2.2 `IsPro` discriminator: `MifidCategorizationID IN (2,3)` → set to 1 else 0
**What**: Computed flag on `IsPro` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsPro`
**Rules**:
- `MifidCategorizationID IN (2,3)`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` bi_output.sql L62-L62
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`

### 2.3 Dim lookup via alias `dc1` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `clb.CID = dc1.RealCID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` L82,L90
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.4 Dim lookup via alias `dpl` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerLevelID = dpl.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` L92
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

### 2.5 Dim lookup via alias `dm` → `gold_sql_dp_prod_we_dwh_dbo_dim_manager`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_manager` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountManagerID = dm.ManagerID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` L94
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`

### 2.6 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_regulation` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.RegulationID = dr.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` L96
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`

### 2.7 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.CountryID = dc.CountryID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` L98,L118
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

### 2.8 Dim lookup via alias `dl` → `gold_sql_dp_prod_we_dwh_dbo_dim_language`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_language` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.LanguageID = dl.LanguageID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` L100,L116
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`

### 2.9 Dim lookup via alias `dv` → `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.VerificationLevelID = dv.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` L102
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`

### 2.10 Dim lookup via alias `gs` → `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.GuruStatusID = gs.GuruStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` L104
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`

### 2.11 Dim lookup via alias `ast` → `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountStatusID = ast.AccountStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` L106
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`

### 2.12 Dim lookup via alias `act` → `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountTypeID = act.AccountTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` L108
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`

### 2.13 Dim lookup via alias `pst` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusID = pst.PlayerStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` L110
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`

### 2.14 Dim lookup via alias `psr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` L112
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`

### 2.15 Dim lookup via alias `pssr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` L114
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`

### 2.16 State + timestamp pair
**What**: Column-name pattern group (Is* + *Date): these columns work together as a unit. Treat them together when filtering or aggregating.
**Columns Involved**: `IsFTC`, `FTCDate`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club.sql` uc_inventory.json

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
| Filter on discriminator flags | Use `IsPI = 1`-style filters on the precomputed flag columns (`IsPI`, `IsPro`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `clb.CID = dc1.RealCID` | Lookup via alias `dc1` |
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
| 1 | Date | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `Date`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 1 | DateID | INT | YES | Direct passthrough from upstream. Formula: `DateID`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 2 | CalendarYearMonth | STRING | YES | Direct passthrough from upstream. Formula: `CalendarYearMonth`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 3 | CalendarQuarter | INT | YES | Direct passthrough from upstream. Formula: `CalendarQuarter`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 4 | CalendarYear | INT | YES | Direct passthrough from upstream. Formula: `CalendarYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 5 | RealCID | STRING | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 6 | PLChangeType | STRING | YES | Direct passthrough from upstream. Formula: `PLChangeType`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 7 | PLChangeTypeDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `PLChangeTypeDate`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 8 | IsUpgrade | INT | YES | Direct passthrough from upstream. Formula: `IsUpgrade`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 9 | IsDowngrade | INT | YES | Direct passthrough from upstream. Formula: `IsDowngrade`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 10 | IsFTC | INT | YES | State + timestamp pair. Formula: `IsFTC`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 11 | CurrentTier | INT | YES | Direct passthrough from upstream. Formula: `CurrentTier`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 12 | LastTier | INT | YES | Direct passthrough from upstream. Formula: `LastTier`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 13 | MaxTier | INT | YES | Direct passthrough from upstream. Formula: `MaxTier`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 14 | FTDDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `FTDDate`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 15 | FTCDate | TIMESTAMP | YES | State + timestamp pair. Formula: `FTCDate`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 16 | IsFTC_Status | INT | YES | Direct passthrough from upstream. Formula: `IsFTC_Status`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 17 | DaysTillFTC | LONG | YES | Direct passthrough from upstream. Formula: `DaysTillFTC`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 18 | DaysFromFTD | LONG | YES | Direct passthrough from upstream. Formula: `DaysFromFTD`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 19 | DaysInClub | LONG | YES | Direct passthrough from upstream. Formula: `DaysInClub`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 20 | DaysInCurrentClub | LONG | YES | Direct passthrough from upstream. Formula: `DaysInCurrentClub`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 21 | AmountForUpgrade | DECIMAL | YES | Direct passthrough from upstream. Formula: `AmountForUpgrade`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 22 | IsOptInIOB | INT | YES | Direct passthrough from upstream. Formula: `IsOptInIOB`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 23 | IOB_Date | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `IOB_Date`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 24 | UpdateDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `UpdateDate`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 25 | GCID_Club | LONG | YES | Direct passthrough from upstream. Formula: `GCID_Club`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 26 | TotalEquityClub | DECIMAL | YES | Direct passthrough from upstream. Formula: `TotalEquityClub`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 27 | WealthFrance | DECIMAL | YES | Direct passthrough from upstream. Formula: `WealthFrance`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 28 | MoneyBalance | DECIMAL | YES | Direct passthrough from upstream. Formula: `MoneyBalance`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 29 | RealizedEquity | DECIMAL | YES | Direct passthrough from upstream. Formula: `RealizedEquity`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 30 | MoneyFarmBalance | DECIMAL | YES | Direct passthrough from upstream. Formula: `MoneyFarmBalance`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity`) |
| 31 | PlayerLevelID | INT | YES | Direct passthrough from upstream. Formula: `PlayerLevelID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 32 | ClubTier | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`) |
| 33 | RegulationID | INT | YES | Customer's assigned regulatory jurisdiction. DEFAULT 0. Sourced from Ext_FSC_BackOffice_RegulationChangeLog.ToRegulationID — end-of-day change. See §2.4. FK to Dim_Regulation. (Tier 2 — via Fact_SnapshotCustomer) |
| 34 | Regulation | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`) |
| 35 | VerificationLevelID | INT | YES | Direct passthrough from upstream. Formula: `VerificationLevelID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 36 | VerificationLevel | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`) |
| 37 | CountryID | INT | YES | Direct passthrough from upstream. Formula: `CountryID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 38 | Country | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 39 | Region | STRING | YES | Direct passthrough from upstream. Formula: `MarketingRegionManualName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 40 | AccountManagerID | INT | YES | Assigned account manager (sales/retention). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.AccountManagerID (BO). FK to Dim_Manager. (Tier 2 — via Fact_SnapshotCustomer) |
| 41 | AccountManager | STRING | YES | Function call computed in source. Formula: `concat_ws(FirstName, '', LastName)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`) |
| 42 | LanguageID | INT | YES | Direct passthrough from upstream. Formula: `LanguageID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 43 | Language | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`) |
| 44 | CommunicationLanguageID | INT | YES | Preferred communication language (may differ from interface language). DEFAULT 0. Source: Ext_FSC_Real_Customer_Customer.CommunicationLanguageID (CC). FK to Dim_Language. (Tier 2 — via Fact_SnapshotCustomer) |
| 45 | CommunicationLanguage | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`) |
| 46 | AccountTypeID | INT | YES | Direct passthrough from upstream. Formula: `AccountTypeID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 47 | AccountType | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`) |
| 48 | GuruStatusID | INT | YES | Direct passthrough from upstream. Formula: `GuruStatusID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 49 | GuruStatusName | STRING | YES | Direct passthrough from upstream. Formula: `GuruStatusName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`) |
| 50 | IsPI | INT | NO | `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0. Formula: `CASE WHEN GuruStatusID > 1 THEN 1 ELSE 0 END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 51 | IsPro | INT | NO | `IsPro` discriminator: `MifidCategorizationID IN (2,3)` → set to 1 else 0. Formula: `CASE WHEN MifidCategorizationID in (2,3) THEN 1 else 0 END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 52 | AccountStatusID | INT | YES | Direct passthrough from upstream. Formula: `AccountStatusID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 53 | AccountStatusName | STRING | YES | Direct passthrough from upstream. Formula: `AccountStatusName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`) |
| 54 | PlayerStatusID | INT | YES | Direct passthrough from upstream. Formula: `PlayerStatusID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 55 | PlayerStatusName | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 56 | CanOpenPosition | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanOpenPosition`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 57 | CanClosePosition | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanClosePosition`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 58 | CanEditPosition | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanEditPosition`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 59 | CanBeCopied | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanBeCopied`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 60 | CanDeposit | BOOLEAN | YES | Whether the user can add funds to their account. False for full-block statuses (IsBlocked=1), close-only/pending statuses (9, 13, 15), status 10 (Deposit Blocked), and status 11 (Social Index). |
| 61 | CanRequestWithdraw | BOOLEAN | YES | Direct passthrough from upstream. Formula: `CanRequestWithdraw`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`) |
| 62 | PlayerStatusReasonID | INT | YES | Direct passthrough from upstream. Formula: `PlayerStatusReasonID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 63 | PlayerStatusReasonName | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`) |
| 64 | PlayerStatusSubReasonID | INT | YES | Direct passthrough from upstream. Formula: `PlayerStatusSubReasonID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 65 | PlayerStatusSubReasonName | STRING | YES | Direct passthrough from upstream. Formula: `PlayerStatusSubReasonName`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`) |
| 66 | CitizenshipCountryID | INT | YES | Direct passthrough from upstream. Formula: `CitizenshipCountryID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 67 | CitizenshipCountry | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`) |
| 68 | AffiliateID | INT | YES | Direct passthrough from upstream. Formula: `AffiliateID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_output.bi_output_vg_date` | Primary | `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_date.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
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
| `main.bi_output_stg.bi_output_customer_customer_facing_stg_dim_club` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_output.bi_output_vg_date
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
main.bi_output_stg.bi_output_customer_customer_facing_club_club_equity
... (14 more upstream(s))
        │
        ▼
main.bi_output.bi_output_vg_club   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=69 runtime=69 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_output.bi_output_vg_date` (wiki: `knowledge/UC_generated/bi_output/<Tables|Views>/bi_output_vg_date.md`)
- **JOIN/UNION upstreams**: 16 additional object(s)
- **Wiki coverage**: 14/16 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 16 | Formulas: 69 | Tiers: 1 T1, 68 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 69/69 | Source: view_definition*
