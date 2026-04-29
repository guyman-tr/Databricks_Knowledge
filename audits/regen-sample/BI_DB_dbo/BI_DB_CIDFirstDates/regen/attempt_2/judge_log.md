I'll review this wiki systematically. Let me first verify a few upstream descriptions against the bundle.
Now let me count DDL columns to verify element count match.
Good - 139 DDL columns, 139 wiki elements. Match confirmed.

Now I have all the information I need. Let me produce the review.

---

## Adversarial Review: BI_DB_dbo.BI_DB_CIDFirstDates

### Dimension 1 — Tier Accuracy: **7/10**

Sampled 5 columns:

| Column | Lineage Transform | Correct Tier | Wiki Tier | Match? |
|--------|-------------------|--------------|-----------|--------|
| Club | Dim-lookup Dim_PlayerLevel.Name | T1 (Dictionary.PlayerLevel) | T1 — Dictionary.PlayerLevel | YES |
| Country | Dim-lookup Dim_Country.Name | T1 (Dictionary.Country) | T1 — Dictionary.Country | YES |
| Channel | Dim-lookup Dim_Channel.Channel (Dim_Channel marks it T2) | T2 | T2 — SP_CIDFirstDates via Dim_Channel | YES |
| State | Dim-lookup Dim_State_and_Province.Name → Dictionary.RegionName | T1 (Dictionary.RegionName) | T1 — Dictionary.RegionName | YES |
| IsFundedNew | ETL-computed: `1 if CID IN Function_Population_Funded result, else 0` | T2 (SP computes membership test) | T1 — Function_Population_Funded | **NO** |

1 mismatch → base score 7. IsFundedNew is ETL-computed via a CASE/membership test against a TVF result set, not a passthrough. FirstNewFundedDate (#84) has the same problem — the SP computes GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(...)), which is arithmetic, not a passthrough. Both are incorrectly tagged T1.

### Dimension 2 — Upstream Fidelity: **4/10**

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | "Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Mapped from Dim_Customer.RealCID." | YES | — |
| GCID | "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction." | "Group Customer ID -- cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction." | YES | — |
| OriginalCID | "Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0." | "Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0." | YES | — |
| UserName | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." | YES | — |
| Club | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup from Dim_PlayerLevel.Name via PlayerLevelID." | YES | — |
| SerialID | (upstream AffiliateID) "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations." | "Affiliate (partner) ID under which the customer was acquired (renamed from AffiliateID in Dim_Customer). FK to BackOffice.Affiliate. NULL for direct/organic registrations." | MINOR | Rename direction adapted for context |
| LabelName | "Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro')." | "Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro'). Dim-lookup from Dim_Label.Name via LabelID." | YES | — |
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English. Dim-lookup from Dim_Country.Name via CountryID." | **NO** | Dropped "Unique per row", usage context (UI dropdowns, compliance docs, analytical reports) |
| Language | "Language display name. UNIQUE constraint. Used in back-office language selectors and reporting." | "Platform language display name. Dim-lookup from Dim_Language.Name via LanguageID. Fixed-width char(500) -- trailing spaces expected." | **NO** | Dropped "UNIQUE constraint", "Used in back-office language selectors and reporting"; paraphrased to "Platform language display name" |
| Region | "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., 'ROW', 'Africa', 'French', 'Arabic Other'). Used for marketing campaign grouping." | "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. Dim-lookup from Dim_Country.Region via CountryID." | MINOR | Dropped "22 distinct values" examples and "Used for marketing campaign grouping" |
| PotentialDesk | "Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join. Examples: 'ROW', 'Other EU', 'Arabic', 'USA'. NULL if no desk mapping for this marketing region." | "Sales/support desk assignment for this country. From Dim_Country.Desk via CountryID. Examples: 'ROW', 'Other EU', 'Arabic', 'USA'. NULL if no desk mapping." | MINOR | Simplified sourcing reference |
| Email | "Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger." | "Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. Dynamically masked with default()." | YES | — |
| FunnelName | "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration." | "Registration funnel name. Dim-lookup from Dim_Funnel.Name via FunnelID. Tracks which user journey/funnel variant the customer came through." | **NO** | Complete rewrite. Lost "Unique", "marketing reports, BackOffice customer views, attribution analytics", "campaign/channel/product" |
| FunnelFromName | (same upstream as FunnelName) | "Source funnel variant name. Dim-lookup from Dim_Funnel.Name via FunnelFromID." | **NO** | Extreme abbreviation — all upstream content lost |
| DownloadID | "Platform download source ID. Legacy tracking for which platform installer the customer used." | "Platform download source ID. Legacy tracking for which platform installer the customer used." | YES | — |
| BannerID | "Advertising banner ID that led to registration. Legacy acquisition tracking." | "Advertising banner ID that led to registration. Legacy acquisition tracking." | YES | — |
| SubAffiliateID | "Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths." | "Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. Mapped from Dim_Customer.SubSerialID." | YES | — |
| ReferralID | "Referral CID - the customer who referred this customer (for RAF program tracking)." | "Referral CID -- the customer who referred this customer (for RAF program tracking)." | YES | — |
| Verified | (Dim_VerificationLevel.ID) "Verification tier identifier... 0=Unverified (registration default, severe restrictions), 1=Basic (limited trading), 2=Intermediate (POI submitted, moderate access), 3=Full KYC (all features unlocked)." | "KYC verification level ID. 0=Unverified, 1=Basic, 2=Intermediate, 3=Full KYC. Dim-lookup from Dim_VerificationLevel.ID via VerificationLevelID." | MINOR | Dropped sub-descriptions per level |
| Gender | "Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1." | "Gender: M, F, or U (Unknown). CHECK constraint enforces these three values only." | MINOR | Dropped constraint name CCST_GENDER and LinkedAccountHash1 |
| CountryID | "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0." | "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0." | YES | — |
| BirthDate | "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification." | "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification." | YES | — |
| CommunicationLanguage | (Dim_Customer) "Language for customer communications (emails, notifications). May differ from LanguageID if customer has different communication preferences." | "Language for customer communications (emails, notifications). Dim-lookup from Dim_Language.Name via CommunicationLanguageID. May differ from Language (UI language)." | MINOR | Reworded "May differ from LanguageID" → "May differ from Language (UI language)" |
| RegulationID | "Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC=7.39M, BVI=7.30M, FCA=1.17M. Changes trigger RegulationChangeDate update." | "Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC, BVI, FCA." | MINOR | Dropped specific counts and RegulationChangeDate trigger info |
| DesignatedRegulationID | "Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation." | "Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation." | YES | — |
| PrivacyPolicyID | "Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy." | "Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy." | YES | — |
| IP | "Registration IP address." | "Registration IP address as numeric value. Dynamically masked with default()." | MINOR | Added type info (accurate — DDL is bigint vs source varchar) |
| State | "Full human-readable geographic name of the region — state, province, or territory. Sourced from Dictionary.RegionName.Name. Examples: 'California', 'New York', 'Ontario'." | "Full human-readable geographic name of the region -- state, province, or territory. Sourced from Dictionary.RegionName.Name. Dim-lookup from Dim_State_and_Province.Name via Dim_Customer.RegionID = RegionByIP_ID. NULL if region not in the 181-row Dim_State_and_Province table." | MINOR | Dropped examples, added JOIN path |
| NewMarketingRegion | "Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction." | "Manual override name for the marketing region. From Dim_Country.MarketingRegionManualName via CountryID. May differ from Region (e.g., Albania: Region=ROE, NewMarketingRegion=CEE)." | MINOR | Dropped "Used when the automated MarketingRegion label needs a business-friendly correction" |
| EvMatchStatus | "Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed." | "Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed." | YES | — |
| Credit | (V_Liabilities: direct passthrough from Fact_SnapshotEquity.Credit) | "Customer credit balance (promotional/bonus credit). Daily snapshot from V_Liabilities.Credit. Updated only for yesterday's run date." | MINOR | Writer composed description; no verbatim upstream to quote |
| RealizedEquity | (V_Liabilities: direct passthrough from Fact_SnapshotEquity.RealizedEquity) | "Customer realized equity (total account value excluding unrealized PnL). Daily snapshot from V_Liabilities.RealizedEquity. Updated only for yesterday's run date." | MINOR | Same as Credit — composed |
| IsFundedNew | N/A — should be T2, not T1 | Tagged T1 but ETL-computed | **WRONG TIER** | Membership test in TVF result is SP logic, not passthrough |
| FirstNewFundedDate | N/A — should be T2, not T1 | Tagged T1 but computed as GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(...)) | **WRONG TIER** | Arithmetic computation, not passthrough |

Summary: 15 YES, 12 MINOR, 4 NO (semantic loss), 2 WRONG TIER.

4 paraphrased with semantic loss → base score 3. The 2 wrong-tier columns (ETL-computed tagged as T1) add another penalty. Score: **4** (giving marginal credit for the high MINOR count being close-to-verbatim).

### Dimension 3 — Completeness: **10/10**

| Check | Pass? |
|-------|-------|
| All 8 sections present | YES |
| Element count matches DDL (139/139) | YES |
| Every element has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count + date range | YES (46.7M, 2007-08-29) |
| Dictionary ≤15 values listed inline | YES (Club, Blocked, Gender, Verified) |
| .review-needed.md has no `## 4. Elements` | YES |

10/10 = **10**

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent: names the domain (customer lifecycle milestones), specifies row grain (one per valid customer), identifies the ETL SP (SP_CIDFirstDates), refresh pattern (daily incremental INSERT + UPDATE), row count (46.7M), date range (2007-08-29), and comprehensively lists column categories. The deprecated column warning is particularly valuable. Section 2 has 10 detailed business logic rules with SQL-level specifics.

### Dimension 5 — Data Evidence: **6/10**

Row count (46.7M) and date range (2007-08-29) are in Section 1. Specific enum values are listed for Blocked (PlayerStatusID values), Club (tier names), Gender (M/F/U). However, there is no explicit Phase Gate Checklist with P2/P3 markers. The footer says "Phases: 12/14" but doesn't specify which phases were completed or skipped. No NULL-rate distributions are cited. The data claims are plausible but unverifiable without explicit phase confirmation.

### Dimension 6 — Shape Fidelity: **8/10**

All numbered sections present, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier breakdown. Minor deviations: footer doesn't list which specific phases were completed/skipped; no explicit quality score breakdown by sub-dimension.

### Weighted Total

```
weighted = 0.25*7 + 0.20*4 + 0.20*10 + 0.15*9 + 0.10*6 + 0.10*8
         = 1.75 + 0.80 + 2.00 + 1.35 + 0.60 + 0.80
         = 7.30
```

**Verdict: FAIL (7.30 < 7.5)**

### Top 5 Issues

1. **HIGH — FunnelName (#15): Tier 1 description completely paraphrased.** Upstream says "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics." Wiki says "Registration funnel name. Tracks which user journey/funnel variant the customer came through." All upstream content lost.

2. **HIGH — FunnelFromName (#17): Tier 1 description extremely abbreviated.** Same upstream as FunnelName, but wiki reduces to just "Source funnel variant name." — a one-liner that drops everything.

3. **HIGH — IsFundedNew (#83) and FirstNewFundedDate (#84): Wrongly tagged Tier 1.** IsFundedNew is ETL-computed (`1 if CID IN Function_Population_Funded result, else 0`). FirstNewFundedDate is arithmetic: `GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID))`. Both are SP computations, not passthroughs — should be Tier 2.

4. **MEDIUM — Country (#10) and Language (#11): Tier 1 descriptions paraphrased with semantic loss.** Country dropped "Unique per row" and all usage context. Language dropped "UNIQUE constraint" and "Used in back-office language selectors and reporting."

5. **LOW — Credit (#47) and RealizedEquity (#48) tagged T1 from V_Liabilities.** These are daily snapshot values updated by SP_CIDFirstDates only when running for yesterday's date. The V_Liabilities wiki doesn't provide a quotable column description — these are passthrough from Fact_SnapshotEquity. The T1 attribution is arguable but the descriptions are writer-composed, not verbatim from any upstream wiki.

### Regeneration Feedback

1. **FunnelName**: Replace description with upstream verbatim: "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Dim-lookup from Dim_Funnel.Name via FunnelID. (Tier 1 — Dictionary.Funnel)"
2. **FunnelFromName**: Same upstream source as FunnelName — use the same verbatim text with "via FunnelFromID" instead of "via FunnelID."
3. **IsFundedNew**: Re-tag as `(Tier 2 — SP_CIDFirstDates)`. The SP computes membership in Function_Population_Funded result set.
4. **FirstNewFundedDate**: Re-tag as `(Tier 2 — SP_CIDFirstDates)`. The SP computes GREATEST(...) arithmetic from Function_Population_First_Time_Funded outputs.
5. **Country**: Append upstream verbatim: "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports."
6. **Language**: Restore upstream: "Language display name. UNIQUE constraint. Used in back-office language selectors and reporting." Then add the char(500) note.
7. Update footer tier counts to reflect IsFundedNew and FirstNewFundedDate moving from T1 to T2 (25 T1, 70 T2).

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_CIDFirstDates",
  "weighted_score": 7.30,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 4,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {"column": "CID", "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.", "wiki_quote": "Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Mapped from Dim_Customer.RealCID.", "match": "YES", "loss": null},
    {"column": "GCID", "upstream_quote": "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction.", "wiki_quote": "Group Customer ID -- cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction.", "match": "YES", "loss": null},
    {"column": "OriginalCID", "upstream_quote": "Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0.", "wiki_quote": "Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0.", "match": "YES", "loss": null},
    {"column": "UserName", "upstream_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index).", "wiki_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index).", "match": "YES", "loss": null},
    {"column": "Club", "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.", "wiki_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup from Dim_PlayerLevel.Name via PlayerLevelID.", "match": "YES", "loss": null},
    {"column": "SerialID", "upstream_quote": "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations.", "wiki_quote": "Affiliate (partner) ID under which the customer was acquired (renamed from AffiliateID in Dim_Customer). FK to BackOffice.Affiliate. NULL for direct/organic registrations.", "match": "MINOR", "loss": "Rename direction adapted for CIDFirstDates context (correct but not verbatim)"},
    {"column": "LabelName", "upstream_quote": "Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro').", "wiki_quote": "Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro'). Dim-lookup from Dim_Label.Name via LabelID.", "match": "YES", "loss": null},
    {"column": "Country", "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.", "wiki_quote": "Full country name in English. Dim-lookup from Dim_Country.Name via CountryID.", "match": "NO", "loss": "Dropped 'Unique per row' and all usage context (UI dropdowns, compliance documents, analytical reports)"},
    {"column": "Language", "upstream_quote": "Language display name. UNIQUE constraint. Used in back-office language selectors and reporting.", "wiki_quote": "Platform language display name. Dim-lookup from Dim_Language.Name via LanguageID. Fixed-width char(500) -- trailing spaces expected.", "match": "NO", "loss": "Dropped UNIQUE constraint and usage context; paraphrased 'Language display name' to 'Platform language display name'"},
    {"column": "Region", "upstream_quote": "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., 'ROW', 'Africa', 'French', 'Arabic Other'). Used for marketing campaign grouping.", "wiki_quote": "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. Dim-lookup from Dim_Country.Region via CountryID.", "match": "MINOR", "loss": "Dropped '22 distinct values' examples and 'Used for marketing campaign grouping'"},
    {"column": "PotentialDesk", "upstream_quote": "Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join. Examples: 'ROW', 'Other EU', 'Arabic', 'USA'. NULL if no desk mapping for this marketing region.", "wiki_quote": "Sales/support desk assignment for this country. From Dim_Country.Desk via CountryID. Examples: 'ROW', 'Other EU', 'Arabic', 'USA'. NULL if no desk mapping.", "match": "MINOR", "loss": "Simplified sourcing reference"},
    {"column": "Email", "upstream_quote": "Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger.", "wiki_quote": "Customer email address. Unique (case-insensitive via LowerEmail computed column). Email changes trigger Customer.LastChanges update via trigger. Dynamically masked with default().", "match": "YES", "loss": null},
    {"column": "FunnelName", "upstream_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.", "wiki_quote": "Registration funnel name. Dim-lookup from Dim_Funnel.Name via FunnelID. Tracks which user journey/funnel variant the customer came through.", "match": "NO", "loss": "Complete rewrite. Lost 'Unique', 'marketing reports, BackOffice customer views, attribution analytics', 'campaign/channel/product'"},
    {"column": "FunnelFromName", "upstream_quote": "Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.", "wiki_quote": "Source funnel variant name. Dim-lookup from Dim_Funnel.Name via FunnelFromID.", "match": "NO", "loss": "Extreme abbreviation — all upstream content dropped"},
    {"column": "DownloadID", "upstream_quote": "Platform download source ID. Legacy tracking for which platform installer the customer used.", "wiki_quote": "Platform download source ID. Legacy tracking for which platform installer the customer used.", "match": "YES", "loss": null},
    {"column": "BannerID", "upstream_quote": "Advertising banner ID that led to registration. Legacy acquisition tracking.", "wiki_quote": "Advertising banner ID that led to registration. Legacy acquisition tracking.", "match": "YES", "loss": null},
    {"column": "SubAffiliateID", "upstream_quote": "Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths.", "wiki_quote": "Sub-affiliate identifier string. Can be up to 1024 chars for complex affiliate tracking paths. Mapped from Dim_Customer.SubSerialID.", "match": "YES", "loss": null},
    {"column": "ReferralID", "upstream_quote": "Referral CID - the customer who referred this customer (for RAF program tracking).", "wiki_quote": "Referral CID -- the customer who referred this customer (for RAF program tracking).", "match": "YES", "loss": null},
    {"column": "Verified", "upstream_quote": "Verification tier identifier. 0=Unverified (registration default, severe restrictions), 1=Basic (limited trading), 2=Intermediate (POI submitted, moderate access), 3=Full KYC (all features unlocked). -1=DWH sentinel.", "wiki_quote": "KYC verification level ID. 0=Unverified, 1=Basic, 2=Intermediate, 3=Full KYC. Dim-lookup from Dim_VerificationLevel.ID via VerificationLevelID.", "match": "MINOR", "loss": "Dropped per-level descriptions (severe restrictions, limited trading, moderate access, all features unlocked)"},
    {"column": "Gender", "upstream_quote": "Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1.", "wiki_quote": "Gender: M, F, or U (Unknown). CHECK constraint enforces these three values only.", "match": "MINOR", "loss": "Dropped constraint name CCST_GENDER and LinkedAccountHash1 reference"},
    {"column": "CountryID", "upstream_quote": "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0.", "wiki_quote": "Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0.", "match": "YES", "loss": null},
    {"column": "BirthDate", "upstream_quote": "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification.", "wiki_quote": "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification.", "match": "YES", "loss": null},
    {"column": "CommunicationLanguage", "upstream_quote": "Language for customer communications (emails, notifications). May differ from LanguageID if customer has different communication preferences.", "wiki_quote": "Language for customer communications (emails, notifications). Dim-lookup from Dim_Language.Name via CommunicationLanguageID. May differ from Language (UI language).", "match": "MINOR", "loss": "Reworded 'May differ from LanguageID' to 'May differ from Language (UI language)'"},
    {"column": "RegulationID", "upstream_quote": "Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC=7.39M, BVI=7.30M, FCA=1.17M. Changes trigger RegulationChangeDate update.", "wiki_quote": "Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC, BVI, FCA.", "match": "MINOR", "loss": "Dropped specific distribution counts and RegulationChangeDate trigger info"},
    {"column": "DesignatedRegulationID", "upstream_quote": "Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation.", "wiki_quote": "Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation.", "match": "YES", "loss": null},
    {"column": "PrivacyPolicyID", "upstream_quote": "Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy.", "wiki_quote": "Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy.", "match": "YES", "loss": null},
    {"column": "IP", "upstream_quote": "Registration IP address.", "wiki_quote": "Registration IP address as numeric value. Dynamically masked with default().", "match": "MINOR", "loss": "Added type context (bigint vs varchar in source) and masking info"},
    {"column": "State", "upstream_quote": "Full human-readable geographic name of the region — state, province, or territory. Sourced from Dictionary.RegionName.Name. Examples: 'California', 'New York', 'Ontario'.", "wiki_quote": "Full human-readable geographic name of the region -- state, province, or territory. Sourced from Dictionary.RegionName.Name. Dim-lookup from Dim_State_and_Province.Name via Dim_Customer.RegionID = RegionByIP_ID. NULL if region not in the 181-row Dim_State_and_Province table.", "match": "MINOR", "loss": "Dropped example values; added JOIN path and NULL semantics"},
    {"column": "NewMarketingRegion", "upstream_quote": "Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction.", "wiki_quote": "Manual override name for the marketing region. From Dim_Country.MarketingRegionManualName via CountryID. May differ from Region (e.g., Albania: Region=ROE, NewMarketingRegion=CEE).", "match": "MINOR", "loss": "Dropped 'Used when the automated MarketingRegion label needs a business-friendly correction'"},
    {"column": "EvMatchStatus", "upstream_quote": "Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed.", "wiki_quote": "Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed.", "match": "YES", "loss": null},
    {"column": "Credit", "upstream_quote": "(V_Liabilities: Direct passthrough from Fact_SnapshotEquity.Credit — no quotable upstream description)", "wiki_quote": "Customer credit balance (promotional/bonus credit). Daily snapshot from V_Liabilities.Credit. Updated only for yesterday's run date.", "match": "MINOR", "loss": "Writer-composed description; no verbatim upstream available for this column path"},
    {"column": "RealizedEquity", "upstream_quote": "(V_Liabilities: Direct passthrough from Fact_SnapshotEquity.RealizedEquity — no quotable upstream description)", "wiki_quote": "Customer realized equity (total account value excluding unrealized PnL). Daily snapshot from V_Liabilities.RealizedEquity. Updated only for yesterday's run date.", "match": "MINOR", "loss": "Writer-composed description; no verbatim upstream available"},
    {"column": "IsFundedNew", "upstream_quote": "N/A — should be Tier 2, not Tier 1", "wiki_quote": "1 if the customer meets ALL four funded criteria on this date... Source: Function_Population_Funded.", "match": "NO", "loss": "Wrong tier: ETL-computed membership test in TVF result set, not a passthrough. Should be Tier 2."},
    {"column": "FirstNewFundedDate", "upstream_quote": "N/A — should be Tier 2, not Tier 1", "wiki_quote": "Permanent graduation date -- the LATEST of the three funded milestones. Computed as GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(...)). Source: Function_Population_First_Time_Funded.", "match": "NO", "loss": "Wrong tier: arithmetic GREATEST/LEAST computation, not a passthrough. Should be Tier 2."}
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "FunnelName (#15)",
      "problem": "Tier 1 description completely paraphrased. Upstream Dim_Funnel.Name says 'Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics.' Wiki says 'Registration funnel name. Tracks which user journey/funnel variant the customer came through.' All upstream specifics lost."
    },
    {
      "severity": "high",
      "column_or_section": "FunnelFromName (#17)",
      "problem": "Tier 1 description reduced to a single generic sentence ('Source funnel variant name'). Same upstream source as FunnelName but all content dropped."
    },
    {
      "severity": "high",
      "column_or_section": "IsFundedNew (#83)",
      "problem": "Tagged Tier 1 from Function_Population_Funded but is ETL-computed: SP does UPDATE SET IsFundedNew = 1 WHERE CID IN (SELECT RealCID FROM Function_Population_Funded(@dateINT)), else 0. This is a membership test / CASE expression, not a passthrough. Should be Tier 2."
    },
    {
      "severity": "high",
      "column_or_section": "FirstNewFundedDate (#84)",
      "problem": "Tagged Tier 1 from Function_Population_First_Time_Funded but the wiki itself describes it as 'Computed as GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID))'. Arithmetic computation = Tier 2, not Tier 1."
    },
    {
      "severity": "medium",
      "column_or_section": "Country (#10), Language (#11)",
      "problem": "Country dropped 'Unique per row' and all usage context. Language dropped 'UNIQUE constraint' and 'Used in back-office language selectors and reporting.' Both are dim-lookup passthroughs where the upstream wiki text was available and should have been quoted verbatim."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) FunnelName: use upstream verbatim 'Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration.' + dim-lookup context. (2) FunnelFromName: same upstream text as FunnelName, adapted for FunnelFromID. (3) Re-tag IsFundedNew as Tier 2 — SP_CIDFirstDates (ETL-computed membership test). (4) Re-tag FirstNewFundedDate as Tier 2 — SP_CIDFirstDates (GREATEST/LEAST arithmetic). (5) Country: restore 'Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.' (6) Language: restore 'UNIQUE constraint. Used in back-office language selectors and reporting.' (7) Update footer tier counts to 25 T1, 70 T2.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2/P3 status unclear — footer says 12/14 but no explicit phase gate checklist"]
  }
}
</JUDGE_VERDICT>
