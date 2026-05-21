---
object_fqn: main.bi_output.bi_output_vg_club_offers
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.bi_output_vg_club_offers
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 64
row_count: null
generated_at: '2026-05-19T15:01:47Z'
upstreams:
- main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty
- main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
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
  path: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql
concept_count: 15
formula_count: 64
tier_breakdown:
  tier1_columns: 0
  tier2_columns: 64
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bi_output_vg_club_offers

> View in `main.bi_output`. 15 business concept(s) in §2; 64 of 64 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_club_offers` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | tombo@etoro.com |
| **Row count** | n/a |
| **Column count** | 64 |
| **Concepts** | 15 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Mar 09 14:02:24 UTC 2026 |

---

## 1. Business Meaning

`bi_output_vg_club_offers` is a view in `main.bi_output` that composes 2 CASE-based classifier flag(s) computed from upstream IDs, 13 JOIN-enriched dimension lookup(s).

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` → this object. The primary upstream has no cached wiki yet (see `.review-needed.md`). Additional upstreams: 13 object(s), listed in §5 Lineage.

Of its 64 columns: 0 inherit byte-for-byte from upstream wikis (Tier 1), 64 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

### 2.1 `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0
**What**: Computed flag on `IsPI` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsPI`
**Rules**:
- `GuruStatusID > 1`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql` bi_output.sql L52-L55
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.2 `IsPro` discriminator: `MifidCategorizationID IN (2,3)` → set to 1 else 0
**What**: Computed flag on `IsPro` set to `1` when the predicates below hold, else `0`.
**Columns Involved**: `IsPro`
**Rules**:
- `MifidCategorizationID IN (2,3)`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql` bi_output.sql L56-L58
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.3 Dim lookup via alias `dc1` → `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `clb.RealCID = dc1.RealCID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql` L77,L79
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### 2.4 Dim lookup via alias `dpl` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dc1.PlayerLevelID = dpl.PlayerLevelID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql` L81
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`

### 2.5 Dim lookup via alias `dm` → `gold_sql_dp_prod_we_dwh_dbo_dim_manager`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_manager` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dc1.AccountManagerID = dm.ManagerID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql` L83
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`

### 2.6 Dim lookup via alias `dr` → `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_regulation` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dc1.RegulationID = dr.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql` L85
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`

### 2.7 Dim lookup via alias `dc` → `gold_sql_dp_prod_we_dwh_dbo_dim_country`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_country` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dc1.CountryID = dc.CountryID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql` L87,L107
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`

### 2.8 Dim lookup via alias `dl` → `gold_sql_dp_prod_we_dwh_dbo_dim_language`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_language` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dc1.LanguageID = dl.LanguageID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql` L89,L105
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`

### 2.9 Dim lookup via alias `dv` → `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dc1.VerificationLevelID = dv.ID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql` L91
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`

### 2.10 Dim lookup via alias `gs` → `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dc1.GuruStatusID = gs.GuruStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql` L93
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus`

### 2.11 Dim lookup via alias `ast` → `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dc1.AccountStatusID = ast.AccountStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql` L95
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus`

### 2.12 Dim lookup via alias `act` → `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dc1.AccountTypeID = act.AccountTypeID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql` L97
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`

### 2.13 Dim lookup via alias `pst` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dc1.PlayerStatusID = pst.PlayerStatusID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql` L99
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus`

### 2.14 Dim lookup via alias `psr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dc1.PlayerStatusReasonID = psr.PlayerStatusReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql` L101
**Source(s)**: `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons`

### 2.15 Dim lookup via alias `pssr` → `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons`
**What**: `JOIN` to dimension `gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` enriches every base row with attributes drawn from that dim. The base side is the FROM-clause object; this side contributes lookups only.
**Columns Involved**: (none)
**Rules**:
- ON `dc1.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID`
**Evidence**: `knowledge/UC_generated/bi_output/_discovery/source_code/bi_output_vg_club_offers.sql` L103
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
| Filter on discriminator flags | Use `IsPI = 1`-style filters on the precomputed flag columns (`IsPI`, `IsPro`) instead of recomputing the underlying CASE predicates downstream. |
| Use enriched columns directly | Dimension attributes are already joined in — no need to re-join the underlying dim tables (`gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `gold_sql_dp_prod_we_dwh_dbo_dim_regulation`). |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `clb.RealCID = dc1.RealCID` | Lookup via alias `dc1` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `dc1.PlayerLevelID = dpl.PlayerLevelID` | Lookup via alias `dpl` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` | `dc1.AccountManagerID = dm.ManagerID` | Lookup via alias `dm` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `dc1.RegulationID = dr.ID` | Lookup via alias `dr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `dc1.CountryID = dc.CountryID` | Lookup via alias `dc` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language` | `dc1.LanguageID = dl.LanguageID` | Lookup via alias `dl` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel` | `dc1.VerificationLevelID = dv.ID` | Lookup via alias `dv` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` | `dc1.GuruStatusID = gs.GuruStatusID` | Lookup via alias `gs` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accountstatus` | `dc1.AccountStatusID = ast.AccountStatusID` | Lookup via alias `ast` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` | `dc1.AccountTypeID = act.AccountTypeID` | Lookup via alias `act` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | `dc1.PlayerStatusID = pst.PlayerStatusID` | Lookup via alias `pst` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons` | `dc1.PlayerStatusReasonID = psr.PlayerStatusReasonID` | Lookup via alias `psr` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons` | `dc1.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID` | Lookup via alias `pssr` |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- ========================================================================== -- Source: information_schema.views.view_definition -- Object: bi_output.bi_output_vg_club_offers -- Captured: 2026-0…`. (Tier 2 — computed in source) |
| 1 | OfferID | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 2 | OfferName | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 3 | Inventorytype | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 4 | DeliveryMethod | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 5 | Type | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 6 | SubType | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 7 | Category | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 8 | StartDate | DATE | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 9 | IsEligble | INT | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 10 | HasOffer | INT | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 11 | CountryCriteria | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 12 | RegulationCriteria | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 13 | ClubCriteria | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 14 | LanguageCriteria | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 15 | ExcludeCountryCriteria | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 16 | ActivationDate | DATE | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 17 | CancellationDate | DATE | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 18 | CancellationReason | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 19 | ToBeCancelled | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 20 | SendCouponDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 21 | AssetStatus | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 22 | ClaimedDate | TIMESTAMP | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 23 | IsEligbleOnRequest | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 24 | RequestedBy | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 25 | Active | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 26 | PlayerLevelID | INT | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 27 | ClubTier | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 28 | RegulationID | INT | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 29 | Regulation | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferID ,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 30 | VerificationLevelID | INT | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. DDL default=-1; SP_Dim_Customer converts NULLs to 0 via ISNULL. |
| 31 | VerificationLevel | STRING | YES | Computed in source (transform kind not classified). Formula: `,OfferName ,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCriteria ,Club…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 32 | CountryID | INT | YES | Computed in source (transform kind not classified). Formula: `,Inventorytype ,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCriteria ,ClubCriteria ,L…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 33 | Country | STRING | YES | Computed in source (transform kind not classified). Formula: `,DeliveryMethod ,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCriteria ,ClubCriteria ,LanguageCriteria ,cl…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 34 | Region | STRING | YES | Computed in source (transform kind not classified). Formula: `,Type ,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCriteria ,ClubCriteria ,LanguageCriteria ,ExcludeCountryCrite…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 35 | AccountManagerID | INT | YES | Computed in source (transform kind not classified). Formula: `,SubType ,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCriteria ,ClubCriteria ,LanguageCriteria ,ExcludeCountryCriteria ,A…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 36 | AccountManager | STRING | YES | Computed in source (transform kind not classified). Formula: `,Category ,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCriteria ,ClubCriteria ,LanguageCriteria ,ExcludeCountryCriteria ,ActivationDate …`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 37 | LanguageID | INT | YES | Computed in source (transform kind not classified). Formula: `,StartDate ,IsEligble ,HasOffer ,CountryCriteria ,RegulationCriteria ,ClubCriteria ,LanguageCriteria ,ExcludeCountryCriteria ,ActivationDate ,Cancellat…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 38 | Language | STRING | YES | Computed in source (transform kind not classified). Formula: `,IsEligble ,HasOffer ,CountryCriteria ,RegulationCriteria ,ClubCriteria ,LanguageCriteria ,ExcludeCountryCriteria ,ActivationDate ,CancellationDate ,Ca…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 39 | CommunicationLanguageID | INT | YES | Computed in source (transform kind not classified). Formula: `,HasOffer ,CountryCriteria ,RegulationCriteria ,ClubCriteria ,LanguageCriteria ,ExcludeCountryCriteria ,ActivationDate ,CancellationDate ,CancellationReason…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 40 | CommunicationLanguage | STRING | YES | Computed in source (transform kind not classified). Formula: `,CountryCriteria ,RegulationCriteria ,ClubCriteria ,LanguageCriteria ,ExcludeCountryCriteria ,ActivationDate ,CancellationDate ,CancellationReason ,ToBeCanc…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 41 | AccountTypeID | INT | YES | Computed in source (transform kind not classified). Formula: `,RegulationCriteria ,ClubCriteria ,LanguageCriteria ,ExcludeCountryCriteria ,ActivationDate ,CancellationDate ,CancellationReason ,ToBeCancelled ,SendCoupon…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 42 | AccountType | STRING | YES | Computed in source (transform kind not classified). Formula: `,ClubCriteria ,LanguageCriteria ,ExcludeCountryCriteria ,ActivationDate ,CancellationDate ,CancellationReason ,ToBeCancelled ,SendCouponDate ,AssetStatus ,…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 43 | GuruStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,LanguageCriteria ,ExcludeCountryCriteria ,ActivationDate ,CancellationDate ,CancellationReason ,ToBeCancelled ,SendCouponDate ,AssetStatus ,ClaimedDate ,c…`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 44 | GuruStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,ExcludeCountryCriteria ,ActivationDate ,CancellationDate ,CancellationReason ,ToBeCancelled ,SendCouponDate ,AssetStatus ,ClaimedDate ,IsEligbleOnRequest …`. (Tier 2 — from `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty`) |
| 45 | IsPI | INT | NO | `IsPI` discriminator: `GuruStatusID > 1` → set to 1 else 0. Formula: `,ToBeCancelled ,SendCouponDate ,AssetStatus ,ClaimedDate ,IsEligbleOnRequest ,RequestedBy ,Active ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,N…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (+1 more)) |
| 46 | IsPro | INT | NO | MiFID II investor classification. FK to Dictionary.MifidCategorization. Values: 1=Retail (97.3%), 4=Eligible Counterparty (2.6%), 5=Professional (0.03%). Default=1. |
| 47 | AccountStatusID | INT | YES | Account operational status. Default=0. SP_Dim_Customer converts NULLs to 0 via ISNULL. |
| 48 | AccountStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,RequestedBy ,Active ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name A…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` (+3 more)) |
| 49 | PlayerStatusID | INT | YES | Computed in source (transform kind not classified). Formula: `,Active ,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,Mar…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` (+3 more)) |
| 50 | PlayerStatusName | STRING | YES | Computed in source (transform kind not classified). Formula: `,PlayerLevelID ,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionM…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+2 more)) |
| 51 | CanOpenPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,Name AS ClubTier ,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+2 more)) |
| 52 | CanClosePosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,RegulationID ,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (+1 more)) |
| 53 | CanEditPosition | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,Name AS Regulation ,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(Firs…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` (+2 more)) |
| 54 | CanBeCopied | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,VerificationLevelID ,Name AS VerificationLevel ,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName, '', LastName) …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_verificationlevel`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (+1 more)) |
| 55 | CanDeposit | BOOLEAN | YES | Whether the user can add funds to their account. False for full-block statuses (IsBlocked=1), close-only/pending statuses (9, 13, 15), status 10 (Deposit Blocked), and status 11 (Social Index). |
| 56 | CanRequestWithdraw | BOOLEAN | YES | Computed in source (transform kind not classified). Formula: `,CountryID ,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName, '', LastName) AS AccountManager ,LanguageID ,Name AS Language …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (+1 more)) |
| 57 | PlayerStatusReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,Name AS Country ,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName, '', LastName) AS AccountManager ,LanguageID ,Name AS Language ,Communicat…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (+1 more)) |
| 58 | PlayerStatusReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,MarketingRegionManualName AS Region ,AccountManagerID ,concat_ws(FirstName, '', LastName) AS AccountManager ,LanguageID ,Name AS Language ,CommunicationLanguageID ,N…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` (+1 more)) |
| 59 | PlayerStatusSubReasonID | INT | YES | Computed in source (transform kind not classified). Formula: `,AccountManagerID ,concat_ws(FirstName, '', LastName) AS AccountManager ,LanguageID ,Name AS Language ,CommunicationLanguageID ,Name AS CommunicationLanguage ,Accoun…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`) |
| 60 | PlayerStatusSubReasonName | STRING | YES | Computed in source (transform kind not classified). Formula: `,concat_ws(FirstName, '', LastName) AS AccountManager ,LanguageID ,Name AS Language ,CommunicationLanguageID ,Name AS CommunicationLanguage ,AccountTypeID ,Name AS A…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (+1 more)) |
| 61 | CitizenshipCountryID | INT | YES | Computed in source (transform kind not classified). Formula: `,LanguageID ,Name AS Language ,CommunicationLanguageID ,Name AS CommunicationLanguage ,AccountTypeID ,Name AS AccountType ,GuruStatusID ,GuruStatusName ,CASE …`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` (+1 more)) |
| 62 | CitizenshipCountry | STRING | YES | Computed flag (CASE expression in source). Formula: `,Name AS Language ,CommunicationLanguageID ,Name AS CommunicationLanguage ,AccountTypeID ,Name AS AccountType ,GuruStatusID ,GuruStatusName ,CASE WHEN GuruStat…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype` (+1 more)) |
| 63 | AffiliateID | INT | YES | Computed flag (CASE expression in source). Formula: `,CommunicationLanguageID ,Name AS CommunicationLanguage ,AccountTypeID ,Name AS AccountType ,GuruStatusID ,GuruStatusName ,CASE WHEN GuruStatusID > 1 THEN 1 el…`. (Tier 2 — from `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus` (+1 more)) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` | Primary | `(no wiki — see `.review-needed.md`)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN/UNION | `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
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

### 5.2 Pipeline ASCII Diagram

```
main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel
... (11 more upstream(s))
        │
        ▼
main.bi_output.bi_output_vg_club_offers   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=64 runtime=64 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_output_stg.bi_output_customer_customer_facing_club_club_offer_eligibilty` (wiki: `(no wiki)`)
- **JOIN/UNION upstreams**: 13 additional object(s)
- **Wiki coverage**: 13/13 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 15 | Formulas: 64 | Tiers: 0 T1, 64 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 64/64 | Source: view_definition*
