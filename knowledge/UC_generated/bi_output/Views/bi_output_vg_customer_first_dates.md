---
object_fqn: main.bi_output.bi_output_vg_customer_first_dates
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_customer_first_dates
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 67
row_count: null
generated_at: '2026-05-19T15:01:48Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
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
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql
concept_count: 15
formula_count: 67
tier_breakdown:
  tier1_columns: 2
  tier2_columns: 65
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_vg_customer_first_dates

> View in `main.bi_output`. 15 business concept(s) in §2; 67 of 67 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_customer_first_dates` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 67 |
| **Concepts** | 15 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Nov 24 14:07:47 UTC 2025 |

---

## 1. Business Meaning

`bi_output_vg_customer_first_dates` is a view in `main.bi_output` that composes 1 CASE-based classifier flag(s) computed from upstream IDs, 13 JOIN-enriched dimension lookup(s), 1 top-level filter block(s) (settled / status / dedup discriminators).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`. Additional upstreams: 16 object(s), listed in §5 Lineage.

Of its 67 columns: 2 inherit byte-for-byte from upstream wikis (Tier 1), 65 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0
**What**: Computed flag on `IsPI` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsPI`
**Rules**:
- `GuruStatusID > 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql` bi_output.sql L89-L89
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.2 Dim lookup via alias `dd` → `gold_sql_dp_prod_we_dwh_dbo_dim_date`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_date` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `cds.FirstFundedDateID = dd.DateKey`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql` L31,L33
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`

### 2.3 Dim lookup via alias `dpl` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerLevelID = dpl.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql` L113
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

### 2.4 Dim lookup via alias `dm` → `gold_sql_dp_prod_we_dwh_dbo_dim_manager`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_manager` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountManagerID = dm.ManagerID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql` L115
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`

### 2.5 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_regulation` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.RegulationID = dr.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql` L117
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`

### 2.6 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.CountryID = dc.CountryID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql` L119,L145
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

### 2.7 Dim lookup via alias `dl` → `gold_sql_dp_prod_we_dwh_dbo_dim_language`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_language` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.LanguageID = dl.LanguageID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql` L121,L137
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`

### 2.8 Dim lookup via alias `dv` → `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.VerificationLevelID = dv.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql` L123
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`

### 2.9 Dim lookup via alias `gs` → `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.GuruStatusID = gs.GuruStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql` L125
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`

### 2.10 Dim lookup via alias `ast` → `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountStatusID = ast.AccountStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql` L127
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`

### 2.11 Dim lookup via alias `act` → `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.AccountTypeID = act.AccountTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql` L129
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`

### 2.12 Dim lookup via alias `pst` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusID = pst.PlayerStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql` L131
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`

### 2.13 Dim lookup via alias `psr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusReasonID = psr.PlayerStatusReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql` L133
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`

### 2.14 Dim lookup via alias `pssr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `fsc.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql` L135
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`

### 2.15 Filter on scope `first_club`: `IsFTC = 1`
**What**: `WHERE` clause at the top of scope `first_club` — every row in this scope must satisfy these predicates. Predicates apply unconditionally to all downstream projections from this scope.
**Columns Involved**: `IsFTC`
**Rules**:
- `IsFTC = 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_customer_first_dates.sql` L43

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
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_date`, `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`). |
| Filters are pre-applied | Top-level filter blocks (e.g. settled-only / dedup) are baked into the view. Querying this object directly means working on the filtered set — see §3.4 Gotchas. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | `cds.FirstFundedDateID = dd.DateKey` | Lookup via alias `dd` |
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

- Scope `first_club` applies `IsFTC = 1` unconditionally — rows failing these predicates are NOT in this view's output.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | INT | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 1 | GCID | INT | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 2 | RegistrationDate | DATE | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 3 | VerificationLevel1Date | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 4 | VerificationLevel2Date | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 5 | VerificationLevel3Date | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 6 | EmailVerifiedDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 7 | VerificationLevelID | INT | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. DDL default=-1; SP_Dim_Customer converts NULLs to 0 via ISNULL. |
| 8 | Channel | STRING | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 9 | SubChannel | STRING | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 10 | Global_FTD_Date | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 11 | Global_FTDA | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 12 | IBAN_FTD_Date | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 13 | IBAN_FTDA | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 14 | TP_FTD_Date | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 15 | TP_FTDA | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 16 | Options_FTD_Date | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 17 | Options_FTDA | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 18 | FirstActionType | STRING | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 19 | FirstActionDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,Global_FTD_Date ,Global_FTDA ,IBAN_FTD_Date ,IBAN_FTDA ,TP_FTD_Date ,TP_FTDA ,Options_FTD_Date ,Options_FTDA ,FirstActionType ,FullDate AS FirstA…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |
| 20 | FirstIOBTime | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,Global_FTD_Date ,Global_FTDA ,IBAN_FTD_Date ,IBAN_FTDA ,TP_FTD_Date ,TP_FTDA ,Options_FTD_Date ,Options_FTDA ,FirstActionType ,FullDate AS FirstA…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |
| 21 | FirstTimeFunded | INT | YES | Computed in source (transform kind not classified). Formula: `,Global_FTD_Date ,Global_FTDA ,IBAN_FTD_Date ,IBAN_FTDA ,TP_FTD_Date ,TP_FTDA ,Options_FTD_Date ,Options_FTDA ,FirstActionType ,FullDate AS FirstA…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |
| 22 | FirstFundedDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,Global_FTD_Date ,Global_FTDA ,IBAN_FTD_Date ,IBAN_FTDA ,TP_FTD_Date ,TP_FTDA ,Options_FTD_Date ,Options_FTDA ,FirstActionType ,FullDate AS FirstA…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |
| 23 | IsFunded | INT | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 24 | FirstClub | STRING | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 25 | FirstTimeClubDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 26 | PlayerLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 27 | ClubTier | STRING | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 28 | RegulationID | INT | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 29 | Regulation | STRING | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 30 | VerificationLevel | STRING | YES | Computed in source (transform kind not classified). Formula: `,GCID ,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 31 | CountryID | INT | YES | Computed in source (transform kind not classified). Formula: `,to_date(RegisteredReal) RegistrationDate ,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,Verification…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 32 | Country | STRING | YES | Computed in source (transform kind not classified). Formula: `,VerificationLevel1Date ,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,VerificationLevelID ,Channel ,SubChannel …`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 33 | Region | STRING | YES | Computed in source (transform kind not classified). Formula: `,VerificationLevel2Date ,VerificationLevel3Date ,EmailVerifiedDate ,VerificationLevelID ,Channel ,SubChannel ,Global_FTD_Date ,dsf…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` (+1 more)) |
| 34 | AccountManagerID | INT | YES | Computed in source (transform kind not classified). Formula: `,VerificationLevel3Date ,EmailVerifiedDate ,VerificationLevelID ,Channel ,SubChannel ,Global_FTD_Date ,Global_FTDA ,IBAN_FTD_D…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` (+1 more)) |
| 35 | AccountManager | STRING | YES | Computed in source (transform kind not classified). Formula: `,EmailVerifiedDate ,VerificationLevelID ,Channel ,SubChannel ,Global_FTD_Date ,Global_FTDA ,IBAN_FTD_Date ,IBAN_FTDA ,ds…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` (+1 more)) |
| 36 | LanguageID | INT | YES | Computed in source (transform kind not classified). Formula: `,VerificationLevelID ,Channel ,SubChannel ,Global_FTD_Date ,Global_FTDA ,IBAN_FTD_Date ,IBAN_FTDA ,TP_FTD_Date ,TP_F…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` (+1 more)) |
| 37 | Language | STRING | YES | Computed in source (transform kind not classified). Formula: `,Channel ,SubChannel ,Global_FTD_Date ,Global_FTDA ,IBAN_FTD_Date ,IBAN_FTDA ,TP_FTD_Date ,TP_FTDA ,Options_FTD_Date…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |
| 38 | CommunicationLanguageID | INT | YES | Computed in source (transform kind not classified). Formula: `,SubChannel ,Global_FTD_Date ,Global_FTDA ,IBAN_FTD_Date ,IBAN_FTDA ,TP_FTD_Date ,TP_FTDA ,Options_FTD_Date ,Options…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |
| 39 | CommunicationLanguage | STRING | YES | Computed in source (transform kind not classified). Formula: `,Global_FTD_Date ,Global_FTDA ,IBAN_FTD_Date ,IBAN_FTDA ,TP_FTD_Date ,TP_FTDA ,Options_FTD_Date ,Options_FTDA ,First…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |
| 40 | AccountTypeID | INT | YES | Computed in source (transform kind not classified). Formula: `,Global_FTDA ,IBAN_FTD_Date ,IBAN_FTDA ,TP_FTD_Date ,TP_FTDA ,Options_FTD_Date ,Options_FTDA ,FirstActionType ,First…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |
| 41 | AccountType | STRING | YES | Computed in source (transform kind not classified). Formula: `,IBAN_FTD_Date ,IBAN_FTDA ,TP_FTD_Date ,TP_FTDA ,Options_FTD_Date ,Options_FTDA ,FirstActionType ,FirstActionDate ,F…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |
| 42 | GuruStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,IBAN_FTDA ,TP_FTD_Date ,TP_FTDA ,Options_FTD_Date ,Options_FTDA ,FirstActionType ,FirstActionDate ,FirstIOBTime ,Fi…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |
| 43 | GuruStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,TP_FTD_Date ,TP_FTDA ,Options_FTD_Date ,Options_FTDA ,FirstActionType ,FirstActionDate ,FirstIOBTime ,FirstTimeFunded ,…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |
| 44 | IsPI | INT | NO | `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0. Formula: `,TP_FTDA ,Options_FTD_Date ,Options_FTDA ,FirstActionType ,FirstActionDate ,FirstIOBTime ,FirstTimeFunded ,FirstFundedDate …`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`) |
| 45 | AccountStatusID | INT | YES | Account operational status. Default=0. SP_Dim_Customer converts NULLs to 0 via ISNULL. |
| 46 | AccountStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,Options_FTDA ,FirstActionType ,FirstActionDate ,FirstIOBTime ,FirstTimeFunded ,FirstFundedDate ,IsFunded ,currentclub FirstClu…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`, `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct`) |
| 47 | PlayerStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,FirstActionType ,FirstActionDate ,FirstIOBTime ,FirstTimeFunded ,FirstFundedDate ,IsFunded ,currentclub FirstClub ,date FirstTi…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`, `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct`) |
| 48 | PlayerStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,FirstActionDate ,FirstIOBTime ,FirstTimeFunded ,FirstFundedDate ,IsFunded ,currentclub FirstClub ,date FirstTimeClubDate ,Playe…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`, `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct` (+1 more)) |
| 49 | CanOpenPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,FirstIOBTime ,FirstTimeFunded ,FirstFundedDate ,IsFunded ,currentclub FirstClub ,date FirstTimeClubDate ,PlayerLevelID ,Name AS…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 50 | CanClosePosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,FirstTimeFunded ,FirstFundedDate ,IsFunded ,currentclub FirstClub ,date FirstTimeClubDate ,PlayerLevelID ,Name AS ClubTier ,Reg…`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` (+2 more)) |
| 51 | CanEditPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,FirstFundedDate ,IsFunded ,currentclub FirstClub ,date FirstTimeClubDate ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` (+3 more)) |
| 52 | CanBeCopied | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,IsFunded ,currentclub FirstClub ,date FirstTimeClubDate ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,Name …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct` (+4 more)) |
| 53 | CanDeposit | BOOLEAN | YES | Whether the user can add funds to their account. False for full-block statuses (IsBlocked=1), close-only/pending statuses (9, 13, 15), status 10 (Deposit Blocked), and status 11 (Social Index). |
| 54 | CanRequestWithdraw | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,date FirstTimeClubDate ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,Name AS VerificationLevel ,CountryID ,dc.…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+3 more)) |
| 55 | PlayerStatusReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,Name AS VerificationLevel ,CountryID ,Name AS Country ,Marketi…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+2 more)) |
| 56 | PlayerStatusReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,Name AS ClubTier ,RegulationID ,Name AS Regulation ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Reg…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+2 more)) |
| 57 | PlayerStatusSubReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,RegulationID ,Name AS Regulation ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManage…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+1 more)) |
| 58 | PlayerStatusSubReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,Name AS Regulation ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(dm.…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+2 more)) |
| 59 | ActiveTraded | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` (+1 more)) |
| 60 | BalanceOnlyAccount | INT | YES | Computed in source (transform kind not classified). Formula: `,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 61 | Portfolio_Only | DECIMAL | YES | Computed in source (transform kind not classified). Formula: `,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID ,Name AS La…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` (+1 more)) |
| 62 | AccountActive | INT | YES | Computed in source (transform kind not classified). Formula: `,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID ,Name AS Language ,Communic…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` (+1 more)) |
| 63 | AccountInActive | INT | YES | Computed in source (transform kind not classified). Formula: `,AccountManagerID ,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID ,Name AS Language ,CommunicationLanguageID ,Name AS Communicati…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 64 | CitizenshipCountryID | INT | YES | Computed in source (transform kind not classified). Formula: `,concat_ws(FirstName,'',LastName) AS AccountManager ,LanguageID ,Name AS Language ,CommunicationLanguageID ,Name AS CommunicationLanguage ,Accoun…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 65 | CitizenshipCountry | STRING | YES | Computed in source (transform kind not classified). Formula: `,LanguageID ,Name AS Language ,CommunicationLanguageID ,Name AS CommunicationLanguage ,AccountTypeID ,Name AS AccountType ,GuruStatusID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 66 | AffiliateID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS Language ,CommunicationLanguageID ,Name AS CommunicationLanguage ,AccountTypeID ,Name AS AccountType ,GuruStatusID ,GuruStatusNam…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` (+1 more)) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
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
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Customer_Daily_Status.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Date.md` |
| `main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_clubchangelogproduct` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_ClubChangeLogProduct.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
... (14 more upstream(s))
        │
        ▼
main.bi_output.bi_output_vg_customer_first_dates   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=67 runtime=67 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`)
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

*Generated: 2026-05-19 | Concepts: 15 | Formulas: 67 | Tiers: 2 T1, 65 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 67/67 | Source: view_definition*
