---
object_fqn: main.etoro_kpi.ftd_funnel_v_dev
object_type: MATERIALIZED_VIEW
producer_kind: sp_or_sql
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.ftd_funnel_v_dev
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: MATERIALIZED_VIEW
format: null
column_count: 60
row_count: null
generated_at: '2026-05-19T15:20:40Z'
upstreams:
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
- main.bi_dealing.bi_output_dealing_cidage_data
- main.general.bronze_etoro_dictionary_playerstatus
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis
  / main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis
- main.etoro_kpi.customer_exclude_list
- main.etoro_kpi.ftd_funnel_kyc
- main.etoro_kpi.ftd_click_v
writer:
  kind: sp_or_sql
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ftd_funnel_v_dev.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/ftd_funnel_v_dev.sql
concept_count: 6
formula_count: 60
tier_breakdown:
  tier1_columns: 3
  tier2_columns: 55
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 2
  unverified_columns: 0
---

# ftd_funnel_v_dev

> Table (sp/sql writer) in `main.etoro_kpi`. 6 business concept(s) in §2; 60 of 60 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ftd_funnel_v_dev` |
| **Type** | MATERIALIZED_VIEW |
| **Format** | n/a |
| **Owner** | doriz@etoro.com |
| **Row count** | n/a |
| **Column count** | 60 |
| **Concepts** | 6 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Thu Feb 19 07:49:21 UTC 2026 |

---

## 1. Business Meaning

`ftd_funnel_v_dev` is a table (SP/SQL writer) in `main.etoro_kpi` that composes 5 CASE-based classifier flag(s) computed from upstream IDs, 1 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`. Additional upstreams: 13 object(s), listed in §5 Lineage.

Of its 60 columns: 3 inherit byte-for-byte from upstream wikis (Tier 1), 55 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 2 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `VD_HasDocuments` discriminator: `GuruStatusID IN (2, 3, 4, 5, 6)`, `FirstDepositDate = '                             '`, `FirstDepositDate = '                             '` → set to '  ' else '             '
**What**: Computed flag on `VD_HasDocuments` set to `'  '` when the predicates below hold, else `'             '`.
**Columns Involved**: `VD_HasDocuments`
**Rules**:
- `GuruStatusID IN (2, 3, 4, 5, 6)`
- `FirstDepositDate = '                             '`
- `FirstDepositDate = '                             '`
- `EV_IsCountryEligible = 1`
- `VD_HasDocuments = 1`
- `VD_HasDocuments = 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/ftd_funnel_v_dev.sql` etoro_kpi.sql L17-L81
**Source(s)**: `main.general.bronze_etoro_dictionary_playerstatus`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.2 `ProofOfIdentity_IsApproved` discriminator: `POI_IsApproved = 1`, `POI_IsApproved = 0` → set to '  ' else '             '
**What**: Computed flag on `ProofOfIdentity_IsApproved` set to `'  '` when the predicates below hold, else `'             '`.
**Columns Involved**: `ProofOfIdentity_IsApproved`
**Rules**:
- `POI_IsApproved = 1`
- `POI_IsApproved = 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/ftd_funnel_v_dev.sql` etoro_kpi.sql L82-L86
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`

### 2.3 `ProofOfAddress_IsApproved` discriminator: `POA_IsApproved = 1`, `POA_IsApproved = 0` → set to '  ' else '             '
**What**: Computed flag on `ProofOfAddress_IsApproved` set to `'  '` when the predicates below hold, else `'             '`.
**Columns Involved**: `ProofOfAddress_IsApproved`
**Rules**:
- `POA_IsApproved = 1`
- `POA_IsApproved = 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/ftd_funnel_v_dev.sql` etoro_kpi.sql L90-L94
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`

### 2.4 `IsEmailVerified` discriminator: `EmailVerification = 1`, `EmailVerification = 0` → set to '  ' else '             '
**What**: Computed flag on `IsEmailVerified` set to `'  '` when the predicates below hold, else `'             '`.
**Columns Involved**: `IsEmailVerified`
**Rules**:
- `EmailVerification = 1`
- `EmailVerification = 0`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/ftd_funnel_v_dev.sql` etoro_kpi.sql L98-L102
**Source(s)**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`

### 2.5 `IsPhoneVerified` computed flag
**What**: Computed flag on `IsPhoneVerified` set to `'  '` when the predicates below hold, else `'             '`.
**Columns Involved**: `IsPhoneVerified`
**Rules**:
- (no explicit predicates / pattern-only concept)
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/ftd_funnel_v_dev.sql` etoro_kpi.sql L104-L108
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.6 Dim lookup via alias `reg_1` → `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_regulation` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dc.RegulationID = reg_1.DWHRegulationID`
**Evidence**: `knowledge/UC_generated/etoro_kpi/_discovery/source_code/ftd_funnel_v_dev.sql` L143,L145
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | MATERIALIZED_VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Filter on discriminator flags | Use `IsEmailVerified = 1`-style filters on the precomputed flag columns (`IsEmailVerified`, `IsPhoneVerified`, `ProofOfAddress_IsApproved`, `ProofOfIdentity_IsApproved`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_regulation`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `dc.RegulationID = reg_1.DWHRegulationID` | Lookup via alias `reg_1` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | INT | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 1 | CID | INT | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | Regulation | STRING | YES | Arithmetic combination of upstream columns. Formula: `/*User Dimensions*/ Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`) |
| 3 | DesignatedRegulation | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`) |
| 4 | Club | STRING | YES | Direct passthrough from upstream. Formula: `Club`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 5 | Country | STRING | YES | Direct passthrough from upstream. Formula: `Country`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 6 | MarketingRegion | STRING | YES | Direct passthrough from upstream. Formula: `NewMarketingRegion`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 7 | CustomerAge | LONG | YES | Direct passthrough from upstream. Formula: `Age`. (Tier 2 — from `bi_dealing.bi_output_dealing_cidage_data`) |
| 8 | IsPopularInvestor | BOOLEAN | YES | Computed flag (CASE expression in source). Formula: `case when GuruStatusID IN (2, 3, 4, 5, 6) then TRUE else FALSE end`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 9 | PlayerStatus | STRING | YES | Arithmetic combination of upstream columns. Formula: `/*User Dimensions: Player Status*/ Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_playerstatus`) |
| 10 | Channel | STRING | YES | Arithmetic combination of upstream columns. Formula: `/*User Acquisition Info*/ Channel`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 11 | SubChannel | STRING | YES | Direct passthrough from upstream. Formula: `SubChannel`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 12 | BannerID | INT | YES | Direct passthrough from upstream. Formula: `BannerID`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 13 | SerialID | INT | YES | Direct passthrough from upstream. Formula: `SerialID`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 14 | Language | STRING | YES | Direct passthrough from upstream. Formula: `Language`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 15 | CurrentVerificationLevel | INT | YES | Arithmetic combination of upstream columns. Formula: `/*User Dates & FTD Amount*/ VerificationLevelID`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 16 | Registration_Date | DATE | YES | Arithmetic combination of upstream columns. Formula: `-- Registration CAST(RegisteredReal AS DATE)`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 17 | Registration_Time | STRING | YES | Function call computed in source. Formula: `date_format(RegisteredReal, 'HH:mm:ss')`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 18 | VerificationLevel1_Date | DATE | YES | Arithmetic combination of upstream columns. Formula: `-- Verification Level 1 CAST(coalesce(DateTime_VL1, VerificationLevel1Date) AS DATE)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 19 | VerificationLevel1_Time | STRING | YES | Computed in source (transform kind not classified). Formula: `'HH:mm:ss' )`. (Tier 2 — literal) |
| 20 | VerificationLevel2_Date | DATE | YES | Arithmetic combination of upstream columns. Formula: `-- Verification Level 2 CAST(coalesce(DateTime_VL2, VerificationLevel2Date) AS DATE)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 21 | VerificationLevel2_Time | STRING | YES | Computed in source (transform kind not classified). Formula: `'HH:mm:ss' )`. (Tier 2 — literal) |
| 22 | VerificationLevel3_Date | DATE | YES | Arithmetic combination of upstream columns. Formula: `-- Verification Level 3 CAST(coalesce(DateTime_VL3, VerificationLevel3Date) AS DATE)`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 23 | VerificationLevel3_Time | STRING | YES | Computed in source (transform kind not classified). Formula: `'HH:mm:ss' )`. (Tier 2 — literal) |
| 24 | FirstTimeDeposit_Date | DATE | YES | Computed flag (CASE expression in source). Formula: `-- First Time Deposit CASE WHEN FirstDepositDate = '1900-01-01T00:00:00.000+00:00' THEN NULL ELSE CAST(FirstDepositDate AS DATE) END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 25 | FirstTimeDeposit_Time | STRING | YES | Computed flag (CASE expression in source). Formula: `CASE WHEN FirstDepositDate = '1900-01-01T00:00:00.000+00:00' THEN NULL ELSE date_format(FirstDepositDate, 'HH:mm:ss') END`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 26 | FirstTimeDepositAmountUSD | DECIMAL | YES | Direct passthrough from upstream. Formula: `FirstDepositAmount`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 27 | FundingType | STRING | YES | Direct passthrough from upstream. Formula: `FirstDepositFundingType`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 28 | KYCFlow | STRING | YES | Arithmetic combination of upstream columns. Formula: `/*Onboarding Details*/ KYCFlow`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 29 | UserScreening_Status | STRING | YES | Arithmetic combination of upstream columns. Formula: `/*User Screening*/ US_ScreeningStatus`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 30 | UserScreening_StartTime | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `US_StartTime`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 31 | UserScreening_EndTime | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `US_EndTime`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 32 | ElectronicVerification_IsCountryEligible | BOOLEAN | YES | Computed flag (CASE expression in source). Formula: `/*Electronic Verification*/ case when EV_IsCountryEligible = 1 then true else false end`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 33 | ElectronicVerification_MatchStatusDateTime | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `EV_MatchStatusDateTime`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 34 | ElectronicVerification_MatchStatus | STRING | YES | Direct passthrough from upstream. Formula: `EV_MatchStatus`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 35 | VD_HasDocuments | STRING | YES | `VD_HasDocuments` discriminator: `GuruStatusID IN (2, 3, 4, 5, 6)`, `FirstDepositDate = '                             '`, `FirstDepositDate = '                             '` → set to '  ' else '             '. Formula: `/*Proof of Identify*/ case when VD_HasDocuments = 1 then 'Yes' when VD_HasDocuments = 0 then 'No' else 'No Indication' end`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 36 | ProofOfIdentity_IsApproved | STRING | YES | `ProofOfIdentity_IsApproved` discriminator: `POI_IsApproved = 1`, `POI_IsApproved = 0` → set to '  ' else '             '. Formula: `case when POI_IsApproved = 1 then 'Yes' when POI_IsApproved = 0 then 'No' else 'No Indication' end`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 37 | ProofOfIdentity_UploadDateTime | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `POI_UploadDateTime`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 38 | ProofOfIdentity_ResponseDateTime | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `POI_ResponseDateTime`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 39 | ProofOfAddress_IsApproved | STRING | YES | `ProofOfAddress_IsApproved` discriminator: `POA_IsApproved = 1`, `POA_IsApproved = 0` → set to '  ' else '             '. Formula: `/*Proof of Address*/ case when POA_IsApproved = 1 then 'Yes' when POA_IsApproved = 0 then 'No' else 'No Indication' end`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 40 | ProofOfAddress_UploadDateTime | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `POA_UploadDateTime`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 41 | ProofOfAddress_ResponseDateTime | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `POA_ResponseDateTime`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 42 | IsEmailVerified | STRING | YES | `IsEmailVerified` discriminator: `EmailVerification = 1`, `EmailVerification = 0` → set to '  ' else '             '. Formula: `/*Email Verification*/ case when EmailVerification = 1 then 'Yes' when EmailVerification = 0 then 'No' else 'No Indication' end`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis`) |
| 43 | IsPhoneVerified | STRING | YES | `IsPhoneVerified` computed flag. Formula: `/*Phone Verification*/ case when IsPhoneVerified = true then 'Yes' when IsPhoneVerified = false then 'No' else 'No Indication' end`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 44 | PhoneVerificationDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `PhoneVerificationDate`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 45 | IsExcludeUser | BOOLEAN | YES | Computed flag (CASE expression in source). Formula: `Case When GCID IS NOT NULL then True Else False End`. (Tier 2 — from `main.etoro_kpi.customer_exclude_list`) |
| 46 | ExcludeReason | STRING | YES | Direct passthrough from upstream. Formula: `excludeReason`. (Tier 2 — from `main.etoro_kpi.customer_exclude_list`) |
| 47 | First_KYC_Answer_Input_DateTime | TIMESTAMP | YES | Arithmetic combination of upstream columns. Formula: `/*KYC*/ First_KYC_Answer`. (Tier 2 — from `main.etoro_kpi.ftd_funnel_kyc`) |
| 48 | Last_KYC_Answer_Input_DateTime | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `Last_KYC_Answer`. (Tier 2 — from `main.etoro_kpi.ftd_funnel_kyc`) |
| 49 | Initial_DepositClick_Date | DATE | YES | Source: `main.etoro_kpi.ftd_click_v.initial_deposit_clicks_combined`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi.ftd_click_v`). |
| 50 | Initial_DepositClick_Time | STRING | YES | Function call computed in source. Formula: `date_format(initial_deposit_clicks_combined, 'HH:mm:ss')`. (Tier 2 — from `main.etoro_kpi.ftd_click_v`) |
| 51 | Initial_DepositClick_Type | STRING | YES | Direct passthrough from upstream. Formula: `initial_deposit_click_type`. (Tier 2 — from `main.etoro_kpi.ftd_click_v`) |
| 52 | Final_DepositClick_Date | DATE | YES | Source: `main.etoro_kpi.ftd_click_v.final_deposit_click`. Upstream wiki is in-scope but not yet authored as of 2026-05-19; this column will be re-resolved when the upstream wiki is generated (Tier N — blocked-on-upstream `main.etoro_kpi.ftd_click_v`). |
| 53 | Final_DepositClick_Time | STRING | YES | Function call computed in source. Formula: `date_format(final_deposit_click, 'HH:mm:ss')`. (Tier 2 — from `main.etoro_kpi.ftd_click_v`) |
| 54 | RegistrationPlatform | STRING | YES | Arithmetic combination of upstream columns. Formula: `/*Reg Platform*/ Platform`. (Tier 2 — from `main.general.bronze_etoro_dictionary_platform`) |
| 55 | FirstPosOpenDate | DATE | YES | First position open timestamp (manual or copy). MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2). (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 56 | FirstPosOpenTime | STRING | YES | Function call computed in source. Formula: `date_format(FirstPosOpenDate, 'HH:mm:ss')`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked`) |
| 57 | FirstAction | STRING | YES | Direct passthrough from upstream. Formula: `FirstAction`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions`) |
| 58 | FirstInstrument | STRING | YES | Direct passthrough from upstream. Formula: `FirstInstrument`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions`) |
| 59 | FirstActionDate | TIMESTAMP | YES | Direct passthrough from upstream. Formula: `FirstActionDate`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | Primary | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
| `main.bi_dealing.bi_output_dealing_cidage_data` | JOIN/UNION | `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_cidage_data.md` |
| `main.general.bronze_etoro_dictionary_playerstatus` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.PlayerStatus.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis / main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | JOIN/UNION | `(no wiki — see `.review-needed.md`)` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Operations_Onboarding_Flow_UserKPIs.md` |
| `main.etoro_kpi.customer_exclude_list` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi/<Tables|Views>/customer_exclude_list.md` |
| `main.etoro_kpi.ftd_funnel_kyc` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi/<Tables|Views>/ftd_funnel_kyc.md` |
| `main.etoro_kpi.ftd_click_v` | JOIN/UNION | `knowledge/UC_generated/etoro_kpi/<Tables|Views>/ftd_click_v.md` |
| `main.general.bronze_etoro_dictionary_platform` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Platform.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions` | JOIN/UNION | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_First5Actions.md` |
| `main.general.bronze_etoro_customer_customer_masked` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Views/Customer.Customer.md` |
| `main.general.bronze_etoro_dictionary_country` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Country.md` |

### 5.2 Pipeline ASCII Diagram

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
... (11 more upstream(s))
        │
        ▼
main.etoro_kpi.ftd_funnel_v_dev   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=60 runtime=60 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (wiki: `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md`)
- **JOIN/UNION upstreams**: 13 additional object(s)
- **Wiki coverage**: 12/13 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 6 | Formulas: 60 | Tiers: 3 T1, 55 T2, 0 T3, 0 T4, 0 T5, 2 TN, 0 U | Elements: 60/60 | Source: sp_or_sql*
