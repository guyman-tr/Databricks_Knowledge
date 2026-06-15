---
object_fqn: main.etoro_kpi.cidfirstdates_v
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.etoro_kpi.cidfirstdates_v
schema: etoro_kpi
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 105
row_count: null
generated_at: '2026-05-19T15:20:33Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
- main.general.bronze_etoro_dictionary_regulation
writer:
  kind: view_definition
  path: knowledge/UC_generated/etoro_kpi/_discovery/source_code/cidfirstdates_v.sql
  source_code_snapshot: knowledge/UC_generated/etoro_kpi/_discovery/source_code/cidfirstdates_v.sql
concept_count: 0
formula_count: 105
tier_breakdown:
  tier1_columns: 104
  tier2_columns: 1
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# cidfirstdates_v

> View in `main.etoro_kpi`. 0 business concept(s) in §2; 105 of 105 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.cidfirstdates_v` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | doriz@etoro.com |
| **Row count** | n/a |
| **Column count** | 105 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Mon Mar 09 15:28:45 UTC 2026 |

---

## 1. Business Meaning

`cidfirstdates_v` is a view in `main.etoro_kpi`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md`. Additional upstreams: 1 object(s), listed in §5 Lineage.

Of its 105 columns: 104 inherit byte-for-byte from upstream wikis (Tier 1), 1 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough — no discriminator concepts detected in source. Refer to upstream wiki for column semantics; this object adds no transformation logic beyond column selection.

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
| Standard SELECT | No precomputed flags or sign-flips — query columns directly. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | INT | YES | Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Mapped from Dim_Customer.RealCID. (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 1 | GCID | INT | YES | Group Customer ID -- cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 2 | OriginalCID | INT | YES | Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 3 | UserName | STRING | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 4 | Club | STRING | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup from Dim_PlayerLevel.Name via PlayerLevelID. (Tier 1 -Dictionary.PlayerLevel) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 5 | SerialID | INT | YES | Affiliate (partner) ID under which the customer was acquired (renamed from AffiliateID in Dim_Customer). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 6 | Channel | STRING | YES | Top-level marketing channel category. Derived from AffWizz MarketingExpense.MarketingExpenseName with overrides: 'Introducing Agents' -> 'Affiliate', AffiliateID IN (56662,56663) -> 'Direct'. Dim-lookup via Dim_Affiliate.SubChannelID -> Dim_Channel.Channel. ISNULL default 'Direct' for customers without affiliate mapping. (Tier 2 -SP_CIDFirstDates via Dim_Channel) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 7 | SubChannel | STRING | YES | Granular sub-channel name within the parent Channel. Human-readable label for SubChannelID. Derived via parallel CASE expression alongside SubChannelID. Dim-lookup via Dim_Affiliate.SubChannelID -> Dim_Channel.SubChannel. ISNULL default 'Direct'. (Tier 2 -SP_CIDFirstDates via Dim_Channel) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 8 | LabelName | STRING | YES | Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro'). Dim-lookup from Dim_Label.Name via LabelID. (Tier 1 -Dictionary.Label) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 9 | Country | STRING | YES | Full country name in English. Dim-lookup from Dim_Country.Name via CountryID. (Tier 1 -Dictionary.Country) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 10 | Language | STRING | YES | Platform language display name. Dim-lookup from Dim_Language.Name via LanguageID. Fixed-width char(500) -- trailing spaces expected. (Tier 1 -Dictionary.Language) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 11 | Region | STRING | YES | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. Dim-lookup from Dim_Country.Region via CountryID. (Tier 4 — Dictionary.MarketingRegion) (Tier 4 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 12 | PotentialDesk | STRING | YES | Sales/support desk assignment for this country. From Dim_Country.Desk via CountryID. Examples: 'ROW', 'Other EU', 'Arabic', 'USA'. NULL if no desk mapping. (Tier 1 -Ext_Dim_Country_Region_Desk) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 13 | Email | STRING | YES | Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. Dynamically masked with default(). (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 14 | Credit | DECIMAL | YES | Customer credit balance from daily equity snapshot. Source: V_Liabilities.Credit (direct passthrough of Fact_SnapshotEquity.Credit). Updated only for yesterday's run date. (Tier 2 - SP_CIDFirstDates) |
| 15 | RealizedEquity | DECIMAL | YES | Customer realized equity (total account value excluding unrealized PnL). Daily snapshot from V_Liabilities.RealizedEquity. Updated only for yesterday's run date. (Tier 2 — V_Liabilities via Fact_SnapshotEquity) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 16 | SocialConnect | INT | YES | Not updated since Sep 2018. Source table (Customer.PrivacyUniqueIdentity) stopped updating. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 17 | Verified | INT | YES | KYC verification level ID. 0=Unverified, 1=Basic, 2=Intermediate, 3=Full KYC. Dim-lookup from Dim_VerificationLevel.ID via VerificationLevelID. (Tier 1 -Dictionary.VerificationLevel) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 18 | KYC | INT | YES | Nullified 2022-02-22 by Guy Manova. Superseded by Verified column. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 19 | DocsOK | INT | YES | Nullified 2022-02-22. Document verification status -- superseded by Dim_Customer.DocsOK. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 20 | Blocked | INT | YES | Account block flag. ETL-computed: 1 when PlayerStatusID IN (2=Blocked, 4=Blocked Upon Request, 6=Under Investigation, 7=Scalpers Block, 8=PayPal Investigation, 9=Trade & MIMO Blocked), else 0. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 21 | IsSales | INT | YES | Not populated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 22 | HasPic | INT | YES | Not populated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 23 | Bankruptcy | INT | YES | Nullified 2022-02-22. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 24 | FunnelName | STRING | YES | Registration funnel name. Dim-lookup from Dim_Funnel.Name via FunnelID. Tracks which user journey/funnel variant the customer came through. (Tier 1 -Dictionary.Funnel) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 25 | DownloadID | INT | YES | Platform download source ID. Legacy tracking for which platform installer the customer used. (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 26 | registered | TIMESTAMP | YES | Earliest registration date across demo and real accounts. ETL-computed: MIN(RegisteredDemo, RegisteredReal). Not the real-account-only date. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 27 | FirstTimeUser | TIMESTAMP | YES | Not populated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 28 | FirstLoggedIn | TIMESTAMP | YES | First platform login timestamp. MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID=14. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 29 | FirstDemoLoggedIn | TIMESTAMP | YES | Demo step disabled 2017-01-26 (Katy). (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 30 | FirstDemoPosOpenDate | TIMESTAMP | YES | Demo step disabled. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 31 | FirstDemoMirrorRegistrationDate | TIMESTAMP | YES | Demo step disabled. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 32 | LastDemoMirrorRegistrationDate | TIMESTAMP | YES | Demo step disabled. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 33 | FirstDemoMirrorPosOpenDate | TIMESTAMP | YES | Demo step disabled. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 34 | FirstCashierLogin | TIMESTAMP | YES | First cashier/billing login timestamp. MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID=29. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 35 | FirstDepositAttempt | TIMESTAMP | YES | Timestamp of the customer's first deposit attempt (whether successful or not). From Fact_FirstCustomerAction WHERE ActionTypeID=27. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 36 | FirstDepositAttemptAmount | DECIMAL | YES | Amount of the first deposit attempt in USD. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 37 | FirstDepositAttemptProcessor | STRING | YES | Payment processor name for the first deposit attempt. Dim-lookup from Dim_BillingDepot.Name via DepotID. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 38 | FirstDepositAttemptFundingType | STRING | YES | Payment method name for the first deposit attempt. Dim-lookup from Dim_FundingType.Name. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 39 | FirstDepositDate | TIMESTAMP | YES | Date of first successful deposit. From Dim_Customer.FirstDepositDate via FTDTransactionID join to Fact_BillingDeposit. Sentinel 1900-01-01 = no deposit. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 40 | FirstDepositProcessor | STRING | YES | Payment processor name for the first successful deposit. Dim-lookup from Dim_BillingDepot.Name. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 41 | FirstDepositFundingType | STRING | YES | Payment method name for the first successful deposit. Dim-lookup from Dim_FundingType.Name. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 42 | FirstDepositAmount | DECIMAL | YES | Amount of first deposit in USD. Default 0. From Dim_Customer.FirstDepositAmount. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 43 | FirstEngagementDate | TIMESTAMP | YES | Engagement section disabled in SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 44 | FirstPosOpenDate | TIMESTAMP | YES | First position open timestamp (manual or copy). MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2). (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 45 | FirstMirrorRegistrationDate | TIMESTAMP | YES | First copy-trade mirror registration timestamp. MIN(Occurred) WHERE ActionTypeID=17. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 46 | LastMirrorRegistrationDate | TIMESTAMP | YES | Most recent copy-trade mirror registration. MAX(Occurred) WHERE ActionTypeID=17. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 47 | FirstMirrorPosOpenDate | TIMESTAMP | YES | First copy-trade position open timestamp. MIN(Occurred) WHERE ActionTypeID=2. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 48 | FirstLeadDate | TIMESTAMP | YES | Set to 1900-01-01 sentinel universally. Not populated with real data. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 49 | FirstDepositAmountExtended | DECIMAL | YES | Not populated by current SP. Deprecated. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 50 | ReferralID | INT | YES | Referral CID -- the customer who referred this customer (for RAF program tracking). (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 51 | LastDemoLoggedIn | TIMESTAMP | YES | Demo step disabled. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 52 | LastDemoMirrorPosOpenDate | TIMESTAMP | YES | Demo step disabled. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 53 | LastDemoPosOpenDate | TIMESTAMP | YES | Demo step disabled. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 54 | LastEngagementDate | TIMESTAMP | YES | Engagement section disabled in SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 55 | LastLoggedIn | TIMESTAMP | YES | Most recent platform login timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID=14. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 56 | LastMirrorPosOpenDate | TIMESTAMP | YES | Most recent copy-trade position open. MAX(Occurred) WHERE ActionTypeID=2. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 57 | LastPosOpenDate | TIMESTAMP | YES | Most recent position open timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2). (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 58 | CertifiedGuru | INT | YES | Not populated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 59 | FirstTimeBeingCopied | TIMESTAMP | YES | First time another customer started copying this customer's trades. MIN(OpenOccurred) from Dim_Mirror per ParentCID. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 60 | LastTimeBeingCopied | TIMESTAMP | YES | Most recent time another customer started copying this customer. MAX(OpenOccurred) from Dim_Mirror per ParentCID. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 61 | Gender | STRING | YES | Gender: M, F, or U (Unknown). CHECK constraint enforces these three values only. (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 62 | CountryID | INT | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 63 | FirstMenualPosOpenDate | TIMESTAMP | YES | First manual (non-copy) position open timestamp. MIN(Occurred) WHERE ActionTypeID=1. Note: column name has typo 'Menual' (not 'Manual'). (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 64 | BirthDate | TIMESTAMP | YES | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 65 | CommunicationLanguage | STRING | YES | Language for customer communications (emails, notifications). Dim-lookup from Dim_Language.Name via CommunicationLanguageID. May differ from Language (UI language). (Tier 1 -Dictionary.Language) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 66 | LastMenualPosOpenDate | TIMESTAMP | YES | Most recent manual position open timestamp. MAX(Occurred) WHERE ActionTypeID=1. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 67 | FirstTimeSocialConnect | TIMESTAMP | YES | Source table stopped updating. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 68 | LastCashierLogin | TIMESTAMP | YES | Most recent cashier login timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID=29. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 69 | FirstCashoutDate | TIMESTAMP | YES | First withdrawal timestamp. MIN(Occurred) WHERE ActionTypeID=8. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 70 | FunnelFromName | STRING | YES | Source funnel variant name. Dim-lookup from Dim_Funnel.Name via FunnelFromID. (Tier 1 -Dictionary.Funnel) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 71 | BannerID | INT | YES | Advertising banner ID that led to registration. Legacy acquisition tracking. (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 72 | SubAffiliateID | STRING | YES | Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. Mapped from Dim_Customer.SubSerialID. (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 73 | FirstCampaignID | STRING | YES | Campaign ID of the customer's first campaign credit event. From History.Credit WHERE CampaignID IS NOT NULL, first by Occurred. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 74 | FirstCampaignDate | TIMESTAMP | YES | Date of the customer's first campaign credit event. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 75 | FirstCampaignAmount | DECIMAL | YES | Payment amount of the first campaign credit event. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 76 | FirstStocksOpenDate | TIMESTAMP | YES | First stock order open timestamp. MIN(Occurred) WHERE ActionTypeID=34. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 77 | SevenDayRetained | INT | YES | Not populated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 78 | FirstToSevenDayRetained | INT | YES | Not populated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 79 | FirstDateRetained | INT | YES | Not populated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 80 | LastContactAttemptDate_ByPhone | TIMESTAMP | YES | Not updated by current SP. Dynamically masked. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 81 | LastContactDate | TIMESTAMP | YES | Most recent successful contact date. MAX(CreatedDate_SF) from BI_DB_UsageTracking_SF WHERE ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c'). (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 82 | LastContactAttemptDate | TIMESTAMP | YES | Not updated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 83 | LastContactDate_ByPhone | TIMESTAMP | YES | Most recent successful phone contact. MAX(CreatedDate_SF) WHERE ActionName='Phone_Call_Succeed__c'. Dynamically masked. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 84 | FirstContactAttemptDate | TIMESTAMP | YES | Not updated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 85 | FirstContactAttemptDate_ByPhone | TIMESTAMP | YES | Not updated by current SP. Dynamically masked. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 86 | FirstContactDate | TIMESTAMP | YES | First successful contact date. MIN(CreatedDate_SF) from BI_DB_UsageTracking_SF WHERE ActionName IN successful contacts. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 87 | FirstContactDate_ByPhone | TIMESTAMP | YES | Not updated by current SP. Dynamically masked. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 88 | PremiumAccount | INT | YES | Nullified 2022-02-22. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 89 | Evangelist | INT | YES | Nullified 2022-02-22. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 90 | FirstToThirtyDayRetained | INT | YES | Not populated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 91 | FirstWallEngagement | TIMESTAMP | YES | Not populated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 92 | FeedUnBlocked | INT | YES | Not populated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 93 | PrivacyPolicyID | INT | YES | Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 94 | IP | INT | YES | Registration IP address as numeric value. Dynamically masked with default(). (Tier 1 -Customer.CustomerStatic) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 95 | FeedUnlocked | INT | YES | Not populated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 96 | Follow5UsersDate | TIMESTAMP | YES | Not populated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 97 | NumberOfUsersFollowed | INT | YES | Not populated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 98 | PopularInvestor | INT | YES | Not populated by current SP. (Tier 3 -deprecated) (Tier 3 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 99 | Manager | STRING | YES | Assigned account manager full name. ETL-computed: Dim_Manager.FirstName + ' ' + Dim_Manager.LastName via AccountManagerID. NULL if no manager assigned. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 100 | RegulationName | STRING | YES | Direct passthrough from upstream. Formula: `Name`. (Tier 2 — from `main.general.bronze_etoro_dictionary_regulation`) |
| 101 | RegulationID | INT | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC, BVI, FCA. (Tier 1 -BackOffice.Customer) (Tier 1 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 102 | VerificationLevel1Date | TIMESTAMP | YES | Date customer first reached KYC verification level 1 (basic). From Fact_SnapshotCustomer + Dim_Range: MIN(FromDateID) WHERE VerificationLevelID=1. Backfilled from Level 2/3 dates if missing. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 103 | VerificationLevel2Date | TIMESTAMP | YES | Date customer first reached KYC verification level 2 (intermediate). MIN(FromDateID) WHERE VerificationLevelID=2. Backfilled from Level 3 date if missing. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |
| 104 | VerificationLevel3Date | TIMESTAMP | YES | Date customer first reached KYC verification level 3 (full KYC). MIN(FromDateID) WHERE VerificationLevelID=3. (Tier 2 -SP_CIDFirstDates) (Tier 2 — inherited from main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked). |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
| `main.general.bronze_etoro_dictionary_regulation` | JOIN/UNION | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.Regulation.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
main.general.bronze_etoro_dictionary_regulation
        │
        ▼
main.etoro_kpi.cidfirstdates_v   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=105 runtime=105 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md`)
- **JOIN/UNION upstreams**: 1 additional object(s)
- **Wiki coverage**: 1/1 JOIN/UNION upstreams have a cached upstream wiki (see `_discovery/upstream_wikis/_index.json`)

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

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 105 | Tiers: 104 T1, 1 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 105/105 | Source: view_definition*
