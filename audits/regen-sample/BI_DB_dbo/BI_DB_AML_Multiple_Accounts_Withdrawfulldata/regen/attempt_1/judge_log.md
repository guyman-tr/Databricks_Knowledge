## Adversarial Review — `BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdrawfulldata`

---

### Dimension Scores

| Dim | Score | Justification |
|-----|-------|---------------|
| Tier Accuracy | 6 | 0 tier-level mismatches in the 5-column sample (FundingID, Country, AccountProgram, Liabilities, EvMatchStatusName). Base = 10. However, two Tier 1 columns — **PlayerStatusReason** and **PlayerStatusSubReasonName** — have clear paraphrasing failures (domain values truncated, AML-specific codes dropped). Per rubric: −2 each → 10 − 4 = **6**. Secondary issue: the footer says "19 T1, 9 T2" but body tag counts give 22 T1, 6 T2; internal inconsistency. |
| Upstream Fidelity | 3 | 2+ Tier 1 columns paraphrased with semantic loss. **PlayerStatusReason** drops eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41) — all AML-relevant values for this exact table. **PlayerStatusSubReasonName** drops 5 abbreviations (FTD, MOP, PWMB, SAR, WCH) and all 9 key value=ID pairs from upstream. Per rubric: 2+ paraphrased → **3**. |
| Completeness | 10 | All 8 sections present. 37 wiki elements = 37 DDL columns ✓. All elements have 5 cells and tier tags. Property table complete. Section 5.2 has a named ASCII pipeline. Footer has tier breakdown. Section 1 has row count (48,529) and sample date. Enum values listed for short-domain columns. review-needed.md has no § 4 Elements. **10/10**. |
| Business Meaning | 9 | Excellent. Names the domain (AML Multiple Accounts Dashboard), grain (one row per customer sharing a withdrawal FundingID), ETL SP (SP_AML_Multiple_Accounts), refresh (TRUNCATE+INSERT daily), filter criteria (IsValidCustomer=1, IsDepositor=1, VerificationLevelID≥2, FundingIDs 1-7 excluded), companion tables, and concrete stats. Minor gap: no observation window end date beyond the sample date. |
| Data Evidence | 7 | Live data clearly used: 48,529 rows, distinct CID/FundingID counts, country/regulation counts, alert coverage (~20%), AccountProgram sparsity (~14%), UpdateDate = 2025-03-13, trailing-space confirmation on PlayerStatus. No explicit P2/P3 phase gate checklist in wiki body, though evidence of sampling is woven throughout. |
| Shape Fidelity | 9 | Numbered sections 1–8 ✓, tier legend in §4 ✓, real SQL samples in §7 (3 queries) ✓, footer with quality score and phases completed ✓. Trivial: `--` used for em-dash throughout (minor formatting inconsistency vs golden reference). |

---

### Weighted Score

```
0.25 × 6 + 0.20 × 3 + 0.20 × 10 + 0.15 × 9 + 0.10 × 7 + 0.10 × 9
= 1.50 + 0.60 + 2.00 + 1.35 + 0.70 + 0.90
= 7.05
```

**FAIL** (7.05 < 7.5)

---

### T1 Fidelity Table

| Column | Upstream Quote (verbatim from bundle) | Wiki Quote | Match | Loss |
|--------|--------------------------------------|------------|-------|------|
| FundingID | "FK to Billing.Funding — the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected." (Fact_BillingWithdraw) | "FK to Billing.Funding -- the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected. This table only contains FundingIDs shared by 2+ customers; IDs 1-7 (reserved/internal) are excluded." | MINOR | Adds context not in source; core meaning preserved |
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | "Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in Dim_Customer." | MINOR | Adds rename note; verbatim otherwise |
| GCID | "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction." | "Group Customer ID -- cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from Dim_Customer." | MINOR | Adds passthrough note only |
| UserName | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer." | MINOR | Adds passthrough note only |
| BirthDate | "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification." | "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. DWH note: CAST to DATE in SP (time component discarded), stored as datetime in this table." | MINOR | Adds SP cast note; verbatim core |
| PhoneVerifiedName | "Human-readable verification state label. Note: ID=2 has value 'ManualyVerified' -- a production typo (single 'l') preserved verbatim from etoro.Dictionary.PhoneVerified. Displayed in customer cards, verification reports, and compliance dashboards." | "Human-readable verification state label for the customer's phone number. Values: NotVerified, AutomaticallyVerified, ManualyVerified (production typo preserved), Initiated, Rejected, AbuseFlag." | MINOR | Drops "Displayed in customer cards, verification reports, and compliance dashboards" |
| RegisteredReal | "Account registration date (renamed from Registered). Default=getdate()." | "Account registration date (renamed from Registered). Default=getdate(). Passthrough from Dim_Customer." | MINOR | Adds passthrough note only |
| VerificationLevelID | "KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified (34.2%), 1=partial (12.4%), 2=intermediate (6.2%), 3=fully verified (47.1%). Default=0." | "KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. This table only contains customers with VerificationLevelID >= 2. Passthrough from Dim_Customer." | MINOR | Drops distribution percentages and Default=0 |
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | YES | Verbatim |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | "Short code for the regulatory entity governing this customer's account. Used in analytics dashboards. Values match production Dictionary.Regulation.Name." | MINOR | Changes "the regulation" → "the regulatory entity governing this customer's account"; drops "Used in V_Dim_Customer" |
| PlayerStatus | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons." | "Human-readable restriction state label for the customer's account. Values: Normal, Blocked, ... Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons." | MINOR | Drops "Used in BackOffice UI, compliance reports, and monitoring dashboards"; adds values list not in upstream |
| PlayerStatusReason | "Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), **eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41)**. Used in BackOffice reporting and customer history views." | "Human-readable reason label for the customer's current account status change (nullable). Key values: None, Failed Verification, Chargeback, AML-Account Closed, HRC, AML, AML review, WCH match, Right to be forgotten, Self-Service, **CloseAccountByUser**." | NO | Drops eToro Money Restriction, Abusive Trading, Hacked Account, Tax (all AML-relevant); drops ID numbers; drops "Used in BackOffice reporting and customer history views"; adds "CloseAccountByUser" (found in upstream §2.1 but not in elements key-values list) |
| PlayerStatusSubReasonName | "Human-readable sub-reason label (renamed from production `Name`). Nullable. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, **FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check**. Key values: Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75)." | "Human-readable sub-reason label for the customer's account status change (nullable). Provides second-level detail beneath PlayerStatusReason. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address. Renamed from production `Name`." | NO | Drops FTD, MOP, PWMB, SAR, WCH abbreviations; drops ALL 9 key value=ID pairs (Fraud, ACH CHBK, Credit Card CHBK, SAR filed, FATCA, W-8BEN, Vulnerable Client, etc.) |
| Club | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." | "eToro Club tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A." | MINOR | Drops "Used in BackOffice reporting JOINs and customer-facing UI" |
| AffiliateID | "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations." | "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. Passthrough from Dim_Customer." | MINOR | Adds passthrough note only |
| City | "City in Unicode." | "City in Unicode. Passthrough from Dim_Customer." | MINOR | Adds passthrough note only |
| Zip | "Postal code. Used in LinkedAccountHash1." | "Postal code. Passthrough from Dim_Customer." | MINOR | Drops "Used in LinkedAccountHash1" — relevant for duplicate detection in AML context |
| BuildingNumber | "Building/apartment number. Separate from Address for structured address storage." | "Building/apartment number. Separate from Address for structured address storage. Passthrough from Dim_Customer." | MINOR | Adds passthrough note only |
| Gender | "Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1." | "Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only in production. Passthrough from Dim_Customer." | MINOR | Drops "Used in LinkedAccountHash1" |
| HasWallet | "1 if the customer has an active eToro Money wallet linked to their trading account. Default=0." | "1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. Passthrough from Dim_Customer." | MINOR | Adds passthrough note only |
| RealizedEquity | V_Liabilities row 4: "Direct | T1" from Fact_SnapshotEquity.RealizedEquity (no extended description in V_Liabilities wiki) | "Customer realized equity snapshot from Fact_SnapshotEquity via V_Liabilities. Passthrough from V_Liabilities." | MINOR | V_Liabilities wiki has no description for this column; wiki adds reasonable context |
| PositionPnL | V_Liabilities row 17: "Direct | T1" from Fact_CustomerUnrealized_PnL.PositionPnL (no extended description in V_Liabilities wiki) | "Unrealized profit/loss on open positions from Fact_CustomerUnrealized_PnL via V_Liabilities. Passthrough from V_Liabilities." | MINOR | V_Liabilities wiki has no description; wiki adds reasonable context |

---

### Top 5 Issues

1. **PlayerStatusSubReasonName** (HIGH) — Tier 1 column with major semantic loss. Drops 5 abbreviations (FTD, MOP, PWMB, SAR, WCH) and all 9 key value=ID pairs from upstream `Dim_PlayerStatusSubReasons`. For an AML table, SAR filed, FATCA, W-8BEN, ACH CHBK, Credit Card CHBK are mission-critical values that analysts must know. Upstream verbatim required.

2. **PlayerStatusReason** (HIGH) — Tier 1 column with semantic loss. Drops eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), and Tax (41) — four AML-relevant reason codes directly applicable to this table's use case. Also drops ID numbers from all remaining values and "Used in BackOffice reporting and customer history views." Additionally includes "CloseAccountByUser" which is sourced from the upstream wiki's business logic section (§2.1) rather than the elements key-values list, mixing text from different upstream sections.

3. **Footer tier count inconsistency** (MEDIUM) — Footer states "19 T1, 9 T2, 9 T3" but body tag counting yields 22 T1, 6 T2, 9 T3 (total = 37). The 3-column discrepancy suggests the writer's own internal tracking was incorrect, undermining trust in the tier classification audit trail.

4. **EvMatchStatusName tier attribution** (MEDIUM) — Tagged `(Tier 2 -- SP_Dictionaries_DL_To_Synapse)`. Per dim-lookup rules, this should reference the dim's origin (UserApiDB.Dictionary.EvMatchStatus) or SP_AML_Multiple_Accounts as the writing SP. SP_Dictionaries_DL_To_Synapse is the SP that built Dim_EvMatchStatus, not the SP that wrote this table. An analyst following the tier tag to understand ETL dependency would be misled about the pipeline.

5. **Zip / Gender — LinkedAccountHash1 dropped** (LOW-MEDIUM) — Both drop "Used in LinkedAccountHash1" from the Dim_Customer upstream descriptions. In the AML context of this specific table (duplicate-account detection), the knowledge that Zip and Gender feed the linked-account hash is highly relevant and should be preserved verbatim.

---

### Regeneration Feedback

1. **PlayerStatusSubReasonName** — Replace with verbatim from upstream `Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName`: restore all 5 dropped abbreviations (FTD, MOP, PWMB, SAR, WCH) and all 9 key value=ID pairs (Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75)).

2. **PlayerStatusReason** — Restore eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41) to the key values list; add ID numbers for all values; add "Used in BackOffice reporting and customer history views." Re-source from `Dim_PlayerStatusReasons.Name` elements section only (not §2.1 business logic).

3. **EvMatchStatusName** — Change tier tag from `(Tier 2 -- SP_Dictionaries_DL_To_Synapse)` to `(Tier 2 -- SP_AML_Multiple_Accounts, via Dim_EvMatchStatus)` to correctly identify the writing SP and the intermediate dim source.

4. **Zip and Gender** — Add "Used in LinkedAccountHash1" back per upstream Dim_Customer descriptions. Particularly important context for this AML-focused table.

5. **Footer tier counts** — Recount from body: body has 22 T1 / 6 T2 / 9 T3. Reconcile the footer "19 T1, 9 T2, 9 T3" claim. If the intended count is 19 T1, identify which 3 T1 columns were reclassified as T2 and update the body tags accordingly; otherwise update the footer.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_AML_Multiple_Accounts_Withdrawfulldata",
  "weighted_score": 7.05,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 6,
    "upstream_fidelity": 3,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "FundingID",
      "upstream_quote": "FK to Billing.Funding — the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected.",
      "wiki_quote": "FK to Billing.Funding -- the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected. This table only contains FundingIDs shared by 2+ customers; IDs 1-7 (reserved/internal) are excluded.",
      "match": "MINOR",
      "loss": "Adds table-specific context not in upstream source; core meaning preserved verbatim"
    },
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in Dim_Customer.",
      "match": "MINOR",
      "loss": "Adds rename note; otherwise verbatim"
    },
    {
      "column": "GCID",
      "upstream_quote": "Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction.",
      "wiki_quote": "Group Customer ID -- cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from Dim_Customer.",
      "match": "MINOR",
      "loss": "Adds passthrough note only"
    },
    {
      "column": "UserName",
      "upstream_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index).",
      "wiki_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer.",
      "match": "MINOR",
      "loss": "Adds passthrough note only"
    },
    {
      "column": "BirthDate",
      "upstream_quote": "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification.",
      "wiki_quote": "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. DWH note: CAST to DATE in SP (time component discarded), stored as datetime in this table. Passthrough from Dim_Customer.",
      "match": "MINOR",
      "loss": "Adds SP cast note; verbatim core"
    },
    {
      "column": "PhoneVerifiedName",
      "upstream_quote": "Human-readable verification state label. Note: ID=2 has value 'ManualyVerified' -- a production typo (single 'l') preserved verbatim from etoro.Dictionary.PhoneVerified. Displayed in customer cards, verification reports, and compliance dashboards.",
      "wiki_quote": "Human-readable verification state label for the customer's phone number. Values: NotVerified, AutomaticallyVerified, ManualyVerified (production typo preserved), Initiated, Rejected, AbuseFlag.",
      "match": "MINOR",
      "loss": "Drops 'Displayed in customer cards, verification reports, and compliance dashboards'; restructures with values list not present in upstream elements description"
    },
    {
      "column": "RegisteredReal",
      "upstream_quote": "Account registration date (renamed from Registered). Default=getdate().",
      "wiki_quote": "Account registration date (renamed from Registered). Default=getdate(). Passthrough from Dim_Customer.",
      "match": "MINOR",
      "loss": "Adds passthrough note only"
    },
    {
      "column": "VerificationLevelID",
      "upstream_quote": "KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified (34.2%), 1=partial (12.4%), 2=intermediate (6.2%), 3=fully verified (47.1%). Default=0.",
      "wiki_quote": "KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. This table only contains customers with VerificationLevelID >= 2. Passthrough from Dim_Customer.",
      "match": "MINOR",
      "loss": "Drops distribution percentages and Default=0; adds table-specific filter note"
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the regulatory entity governing this customer's account. Used in analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "match": "MINOR",
      "loss": "Changes 'Short code for the regulation' to 'Short code for the regulatory entity governing this customer's account'; drops 'Used in V_Dim_Customer'"
    },
    {
      "column": "PlayerStatus",
      "upstream_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.",
      "wiki_quote": "Human-readable restriction state label for the customer's account. Values: Normal, Blocked, Blocked Upon Request, Warning, Under Investigation, Chat Blocked, Trade & MIMO Blocked, Deposit Blocked, Copy Block, Pending Verification, Failed Verification, Block Deposit & Trading, and others. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.",
      "match": "MINOR",
      "loss": "Drops 'Used in BackOffice UI, compliance reports, and monitoring dashboards'; adds values list not sourced from upstream elements description"
    },
    {
      "column": "PlayerStatusReason",
      "upstream_quote": "Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). Used in BackOffice reporting and customer history views.",
      "wiki_quote": "Human-readable reason label for the customer's current account status change (nullable). Key values: None, Failed Verification, Chargeback, AML-Account Closed, HRC, AML, AML review, WCH match, Right to be forgotten, Self-Service, CloseAccountByUser.",
      "match": "NO",
      "loss": "Drops eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41) — four AML-relevant reason codes; drops all ID numbers; drops 'Used in BackOffice reporting and customer history views'; adds 'CloseAccountByUser' sourced from §2.1 of upstream wiki (business logic) rather than elements key-values list"
    },
    {
      "column": "PlayerStatusSubReasonName",
      "upstream_quote": "Human-readable sub-reason label (renamed from production `Name`). Nullable. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check. Key values: Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75).",
      "wiki_quote": "Human-readable sub-reason label for the customer's account status change (nullable). Provides second-level detail beneath PlayerStatusReason. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address. Renamed from production `Name`.",
      "match": "NO",
      "loss": "Drops FTD, MOP, PWMB, SAR, WCH abbreviations; drops all 9 key value=ID pairs (Fraud, ACH CHBK, Credit Card CHBK, PayPal CHBK, SAR filed, FATCA, W-8BEN, Vulnerable Client, Fake docs)"
    },
    {
      "column": "Club",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "wiki_quote": "eToro Club tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A.",
      "match": "MINOR",
      "loss": "Drops 'Used in BackOffice reporting JOINs and customer-facing UI'"
    },
    {
      "column": "AffiliateID",
      "upstream_quote": "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations.",
      "wiki_quote": "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. Passthrough from Dim_Customer.",
      "match": "MINOR",
      "loss": "Adds passthrough note only"
    },
    {
      "column": "City",
      "upstream_quote": "City in Unicode.",
      "wiki_quote": "City in Unicode. Passthrough from Dim_Customer.",
      "match": "MINOR",
      "loss": "Adds passthrough note only"
    },
    {
      "column": "Zip",
      "upstream_quote": "Postal code. Used in LinkedAccountHash1.",
      "wiki_quote": "Postal code. Passthrough from Dim_Customer.",
      "match": "MINOR",
      "loss": "Drops 'Used in LinkedAccountHash1' — relevant for duplicate detection in AML context"
    },
    {
      "column": "BuildingNumber",
      "upstream_quote": "Building/apartment number. Separate from Address for structured address storage.",
      "wiki_quote": "Building/apartment number. Separate from Address for structured address storage. Passthrough from Dim_Customer.",
      "match": "MINOR",
      "loss": "Adds passthrough note only"
    },
    {
      "column": "Gender",
      "upstream_quote": "Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1.",
      "wiki_quote": "Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only in production. Passthrough from Dim_Customer.",
      "match": "MINOR",
      "loss": "Drops 'Used in LinkedAccountHash1'"
    },
    {
      "column": "HasWallet",
      "upstream_quote": "1 if the customer has an active eToro Money wallet linked to their trading account. Default=0.",
      "wiki_quote": "1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. Passthrough from Dim_Customer.",
      "match": "MINOR",
      "loss": "Adds passthrough note only"
    },
    {
      "column": "RealizedEquity",
      "upstream_quote": "V_Liabilities row 4: Direct passthrough from Fact_SnapshotEquity.RealizedEquity (T1; no extended description in V_Liabilities wiki body)",
      "wiki_quote": "Customer realized equity snapshot from Fact_SnapshotEquity via V_Liabilities. Passthrough from V_Liabilities.",
      "match": "MINOR",
      "loss": "V_Liabilities wiki provides no description for this column; wiki adds reasonable lineage context"
    },
    {
      "column": "PositionPnL",
      "upstream_quote": "V_Liabilities row 17: Direct passthrough from Fact_CustomerUnrealized_PnL.PositionPnL (T1; no extended description in V_Liabilities wiki body)",
      "wiki_quote": "Unrealized profit/loss on open positions from Fact_CustomerUnrealized_PnL via V_Liabilities. Passthrough from V_Liabilities.",
      "match": "MINOR",
      "loss": "V_Liabilities wiki provides no description for this column; wiki adds reasonable lineage context"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "PlayerStatusSubReasonName",
      "problem": "Tier 1 column with major semantic loss. Drops 5 abbreviations (FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check) and all 9 key value=ID pairs (Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75)) from Dim_PlayerStatusSubReasons upstream. For an AML-focused table this is critical missing context."
    },
    {
      "severity": "high",
      "column_or_section": "PlayerStatusReason",
      "problem": "Tier 1 column with semantic loss. Drops eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41) — four AML-relevant reason codes directly applicable to this table. Drops ID numbers from remaining values. Drops 'Used in BackOffice reporting and customer history views'. Adds 'CloseAccountByUser' sourced from upstream §2.1 business logic section rather than the elements key-values list — mixes text from different upstream sections."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer tier count",
      "problem": "Footer states '19 T1, 9 T2, 9 T3' but body tag counting yields 22 T1, 6 T2, 9 T3 (total = 37 in both cases). The 3-column discrepancy in the tier breakdown undermines the audit trail. Either 3 columns tagged T1 in the body should be T2, or the footer count is wrong and must be corrected."
    },
    {
      "severity": "medium",
      "column_or_section": "EvMatchStatusName",
      "problem": "Tier tag reads '(Tier 2 -- SP_Dictionaries_DL_To_Synapse)'. SP_Dictionaries_DL_To_Synapse is the SP that built Dim_EvMatchStatus, not the SP that writes this table (SP_AML_Multiple_Accounts). An analyst following this tag to understand data pipeline dependency would trace to the wrong ETL. Should read '(Tier 2 -- SP_AML_Multiple_Accounts, via Dim_EvMatchStatus)' or equivalent."
    },
    {
      "severity": "low",
      "column_or_section": "Zip / Gender",
      "problem": "Both columns drop 'Used in LinkedAccountHash1' from upstream Dim_Customer descriptions. In the AML context of this specific table — which exists to detect multi-account patterns — the knowledge that Zip and Gender feed the linked-account deduplication hash is highly relevant context and should be preserved verbatim."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) PlayerStatusSubReasonName — restore full upstream verbatim from Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName: add FTD, MOP, PWMB, SAR, WCH to abbreviation glossary; add all key value=ID pairs (Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75)). (2) PlayerStatusReason — restore eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41); add ID numbers for all values; add 'Used in BackOffice reporting and customer history views'; source only from elements key-values section of Dim_PlayerStatusReasons, not §2.1. (3) EvMatchStatusName tier tag — change from '(Tier 2 -- SP_Dictionaries_DL_To_Synapse)' to '(Tier 2 -- SP_AML_Multiple_Accounts, via Dim_EvMatchStatus)'. (4) Zip and Gender — add 'Used in LinkedAccountHash1' back per upstream Dim_Customer. (5) Footer tier counts — recount from body tags: body shows 22 T1 / 6 T2 / 9 T3; reconcile with footer '19 T1 / 9 T2 / 9 T3' discrepancy.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
