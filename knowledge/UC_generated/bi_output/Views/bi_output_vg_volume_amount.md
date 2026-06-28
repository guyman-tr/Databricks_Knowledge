---
object_fqn: main.bi_output.bi_output_vg_volume_amount
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_volume_amount
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 71
row_count: null
generated_at: '2026-06-19T14:35:57Z'
upstreams:
- main.bi_output.bi_output_vg_date
- main.bi_output.bi_ouput_v_dim_instrumenttype
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
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql
concept_count: 15
formula_count: 42
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 42
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 29
---

# bi_output_vg_volume_amount

> View in `main.bi_output`. 15 business concept(s) in §2; 42 of 71 columns documented from anchored evidence; 29 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_volume_amount` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 71 |
| **Concepts** | 15 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-06-19 |
| **Created** | Tue Feb 17 06:44:49 UTC 2026 |

---

## 1. Business Meaning

`bi_output_vg_volume_amount` is a view in `main.bi_output` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 14 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_output.bi_output_vg_date` → this object. Canonical upstream documentation: `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md`. Additional upstreams: 16 object(s), listed in §5 Lineage.

Of its 71 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 42 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0
**What**: Computed flag on `IsPI` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsPI`
**Rules**:
- `GuruStatusID > 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql` bi_output.sql L31-L31
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`

### 2.2 Dim lookup via alias `di` → `bi_ouput_v_dim_instrumenttype`
**What**: `JOIN` to dimension `bi_ouput_v_dim_instrumenttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `vaa.InstrumentTypeID = di.InstrumentTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql` L50
**Source(s)**: `main.bi_output.bi_ouput_v_dim_instrumenttype`

### 2.3 Dim lookup via alias `dc1` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `vaa.RealCID = dc1.RealCID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql` L52,L60
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.4 Dim lookup via alias `dpl` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerLevelID = dpl.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql` L62
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

### 2.5 Dim lookup via alias `dm` → `gold_sql_dp_prod_we_dwh_dbo_dim_manager`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_manager` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountManagerID = dm.ManagerID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql` L64
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`

### 2.6 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_regulation` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.RegulationID = dr.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql` L66
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`

### 2.7 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.CountryID = dc.CountryID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql` L68,L88
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

### 2.8 Dim lookup via alias `dl` → `gold_sql_dp_prod_we_dwh_dbo_dim_language`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_language` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.LanguageID = dl.LanguageID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql` L70,L86
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`

### 2.9 Dim lookup via alias `dv` → `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.VerificationLevelID = dv.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql` L72
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`

### 2.10 Dim lookup via alias `gs` → `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.GuruStatusID = gs.GuruStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql` L74
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`

### 2.11 Dim lookup via alias `ast` → `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountStatusID = ast.AccountStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql` L76
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`

### 2.12 Dim lookup via alias `act` → `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountTypeID = act.AccountTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql` L78
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`

### 2.13 Dim lookup via alias `pst` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusID = pst.PlayerStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql` L80
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`

### 2.14 Dim lookup via alias `psr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql` L82
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`

### 2.15 Dim lookup via alias `pssr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_volume_amount.sql` L84
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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`bi_ouput_v_dim_instrumenttype`, `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `gold_sql_dp_prod_we_dwh_dbo_dim_manager`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | `vaa.InstrumentTypeID = di.InstrumentTypeID` | Lookup via alias `di` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `vaa.RealCID = dc1.RealCID` | Lookup via alias `dc1` |
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
| 1 | WeekNumberYear | INT | YES | Arithmetic combination of upstream columns. Formula: `-- ========================================================================== -- Source: information_schema.views.view_definition -- Object: bi_output.bi_output_vg_volume_amount -- Captured: 2026…`. (Tier 2 — computed in source) |
| 1 | CalendarYearMonth | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 2 | CalendarQuarter | INT | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 3 | CalendarYear | INT | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear`. (Tier 2 — from `main.bi_output.bi_output_vg_date`) |
| 4 | InstrumentType | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.bi_output.bi_ouput_v_dim_instrumenttype`) |
| 5 | PlayerLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID`. (Tier 2 — from `main.bi_output.bi_output_vg_date`, `main.bi_output.bi_ouput_v_dim_instrumenttype`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 6 | ClubTier | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.bi_output.bi_ouput_v_dim_instrumenttype` (+1 more)) |
| 7 | RegulationID | INT | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.bi_output.bi_output_vg_date`, `main.bi_output.bi_ouput_v_dim_instrumenttype` (+1 more)) |
| 8 | Regulation | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 9 | VerificationLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 10 | VerificationLevel | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 11 | CountryID | INT | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 12 | Country | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 13 | Region | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 14 | AccountManagerID | INT | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 15 | AccountManager | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 16 | LanguageID | INT | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 17 | Language | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 18 | CommunicationLanguageID | INT | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 19 | CommunicationLanguage | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 20 | AccountTypeID | INT | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 21 | AccountType | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 22 | GuruStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 23 | GuruStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 24 | IsPI | INT | NO | `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0. Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 25 | AccountStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 26 | AccountStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 27 | PlayerStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 28 | PlayerStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 29 | CanOpenPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 30 | CanClosePosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,CalendarYearMonth ,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,f…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 31 | CanEditPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,CalendarQuarter ,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 32 | CanBeCopied | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,CalendarYear ,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS Ver…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output.bi_output_vg_date` (+3 more)) |
| 33 | CanDeposit | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,InstrumentType ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,fs…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 34 | CanRequestWithdraw | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Na…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+2 more)) |
| 35 | PlayerStatusReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,M…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+2 more)) |
| 36 | PlayerStatusReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 37 | PlayerStatusSubReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,Accoun…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 38 | PlayerStatusSubReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(d…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 39 | CitizenshipCountryID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` (+1 more)) |
| 40 | CitizenshipCountry | STRING | YES | Computed in source (transform kind not classified). Formula: `,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked`) |
| 41 | DateID | INT | YES | Computed in source (transform kind not classified). Formula: `inner join bi_output.bi_ouput_v_dim_instrumenttype di on InstrumentTypeID = InstrumentTypeID inner join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc1 on RealCID = R…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.bi_output.bi_ouput_v_dim_instrumenttype`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts`) |
| 42 | Date | TIMESTAMP | YES | Transform `unknown` for column `Date` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 43 | RealCID | INT | YES | Transform `unknown` for column `RealCID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 44 | InstrumentTypeID | INT | YES | Transform `unknown` for column `InstrumentTypeID` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 45 | IsSettled | INT | YES | Transform `unknown` for column `IsSettled` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 46 | IsCopy | INT | YES | Transform `unknown` for column `IsCopy` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 47 | IsBuy | INT | YES | Transform `unknown` for column `IsBuy` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 48 | IsLeverage | INT | YES | Transform `unknown` for column `IsLeverage` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 49 | IsFuture | INT | YES | Transform `unknown` for column `IsFuture` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 50 | IsCopyFund | INT | YES | Transform `unknown` for column `IsCopyFund` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 51 | IsOpenedFromIBAN | STRING | YES | Transform `unknown` for column `IsOpenedFromIBAN` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 52 | IsClosedToIBAN | INT | YES | Transform `unknown` for column `IsClosedToIBAN` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 53 | IsRecurring | INT | YES | Transform `unknown` for column `IsRecurring` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 54 | IsAirDrop | INT | YES | Transform `unknown` for column `IsAirDrop` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 55 | VolumeOpen | LONG | YES | Transform `unknown` for column `VolumeOpen` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 56 | VolumeClose | LONG | YES | Transform `unknown` for column `VolumeClose` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 57 | InvestedAmountOpen | DECIMAL | YES | Transform `unknown` for column `InvestedAmountOpen` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 58 | InvestedAmountClosed | DECIMAL | YES | Transform `unknown` for column `InvestedAmountClosed` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 59 | TotalVolume | LONG | YES | Transform `unknown` for column `TotalVolume` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 60 | NetInvestedAmount | DECIMAL | YES | Transform `unknown` for column `NetInvestedAmount` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 61 | CountOpenTransactions | INT | YES | Transform `unknown` for column `CountOpenTransactions` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 62 | CountCloseTransactions | INT | YES | Transform `unknown` for column `CountCloseTransactions` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 63 | CountTotalTransactions | INT | YES | Transform `unknown` for column `CountTotalTransactions` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 64 | UpdateDate | TIMESTAMP | YES | Transform `unknown` for column `UpdateDate` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 65 | IsSQF | INT | YES | Transform `unknown` for column `IsSQF` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 66 | IsMarginTrade | INT | YES | Transform `unknown` for column `IsMarginTrade` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 67 | IsC2P | INT | YES | Transform `unknown` for column `IsC2P` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 68 | etr_y | STRING | YES | Transform `unknown` for column `etr_y` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 69 | etr_ym | STRING | YES | Transform `unknown` for column `etr_ym` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |
| 70 | etr_ymd | STRING | YES | Transform `unknown` for column `etr_ymd` could not be resolved to an upstream wiki or a source-code expression. See `.review-needed.md`. (Tier U — unclassified) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_output.bi_output_vg_date` | Primary | `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md` |
| `main.bi_output.bi_ouput_v_dim_instrumenttype` | JOIN/UNION | `knowledge\UC_generated\bi_output\Views\bi_ouput_v_dim_instrumenttype.md` |
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
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_Trading_Volumes_And_Amounts.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_output.bi_output_vg_date
main.bi_output.bi_ouput_v_dim_instrumenttype
main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked
... (14 more upstream(s))
        │
        ▼
main.bi_output.bi_output_vg_volume_amount   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=71 runtime=71 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_output.bi_output_vg_date` (wiki: `knowledge\UC_generated\bi_output\Views\bi_output_vg_date.md`)
- **JOIN/UNION upstreams**: 16 additional object(s)
- **Wiki coverage**: 16/16 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-06-19 | Concepts: 15 | Formulas: 42 | Tiers: 0 T1, 42 T2, 0 T3, 0 T4, 0 T5, 0 TN, 29 U | Elements: 71/71 | Source: view_definition*
