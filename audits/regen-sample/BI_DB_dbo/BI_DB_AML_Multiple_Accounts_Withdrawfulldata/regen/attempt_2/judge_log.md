## Human-Readable Summary — BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdrawfulldata

---

### Per-Dimension Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Tier Accuracy (25%) | 7 | 1 mismatch in 5 sampled: `EvMatchStatusName` tagged Tier 2 via SP when rubric mandates Tier 1 with the dim's root origin |
| Upstream Fidelity (20%) | 7 | Core descriptions verbatim; 4 columns drop upstream usage context (`PlayerStatus`, `Regulation`, `Club`, `PhoneVerifiedName`) — pattern of rewording that loses metadata |
| Completeness (20%) | 10 | All 8 sections present; 37/37 DDL columns documented; property table complete; ETL diagram with real names; footer with tier counts; row count + date in Section 1; no elements bleed into review-needed sidecar |
| Business Meaning (15%) | 9 | Excellent specificity: grain, domain, SP step, filter criteria, companion tables, row count, all named. Minor: companion table list could include schemas |
| Data Evidence (10%) | 8 | Row count, distinct CID/FID counts, NULL rates, observed enum values all present. Phase notation uses custom scheme, not explicit P2/P3 checkboxes, but sampled data is clearly real |
| Shape Fidelity (10%) | 9 | All required sections, tier legend, 3 real SQL samples, footer quality score — minor: footer format slightly non-standard (dashes vs em-dashes) |

**Weighted: 0.25×7 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×8 + 0.10×9 = 1.75+1.40+2.00+1.35+0.80+0.90 = 8.20 → PASS**

---

### T1 Fidelity Table

| Column | Upstream Quote (verbatim) | Wiki Quote | Match | Loss |
|--------|--------------------------|------------|-------|------|
| FundingID | "FK to Billing.Funding — the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected." | "FK to Billing.Funding -- the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected. This table only contains FundingIDs shared by 2+ customers..." | YES | None — additive context |
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | "Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | YES | None |
| UserName | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer." | YES | None — additive only |
| BirthDate | "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification." | "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. DWH note: CAST to DATE in SP..." | YES | None — DWH note is additive |
| PhoneVerifiedName | "Human-readable verification state label. Note: ID=2 has value 'ManualyVerified' … Displayed in customer cards, verification reports, and compliance dashboards." | "Human-readable verification state label for the customer's phone number. Values: NotVerified, AutomaticallyVerified, ManualyVerified…" | MINOR | Drops "Displayed in customer cards, verification reports, and compliance dashboards" |
| Country | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough…" | YES | None — additive |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | "Short code for the regulatory entity governing this customer's account. Used in analytics dashboards. Values match production Dictionary.Regulation.Name." | MINOR | Drops "in V_Dim_Customer"; rewrites start of description |
| PlayerStatus | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces…" | "Human-readable restriction state label for the customer's account. Values: Normal, Blocked… Note: some values have trailing spaces…" | MINOR | Drops "Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards" |
| PlayerStatusReason | "Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). Used in BackOffice reporting and customer history views." | Identical plus "By request (22)" inserted | YES | None — additive only |
| PlayerStatusSubReasonName | "Human-readable sub-reason label (renamed from production \`Name\`). Nullable. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity…" | Verbatim (backtick vs apostrophe only) | YES | None |
| Club | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." | "eToro Club tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A." | MINOR | Drops "Used in BackOffice reporting JOINs and customer-facing UI" |
| AffiliateID | "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations." | Verbatim + "Passthrough from Dim_Customer" | YES | None |
| Gender | "Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1." | "Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only in production. Used in LinkedAccountHash1." | YES | None (adds "in production") |
| VerificationLevelID | "KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified (34.2%), 1=partial (12.4%), 2=intermediate (6.2%), 3=fully verified (47.1%). Default=0." | Verbatim + filter note | YES | None |
| HasWallet | "1 if the customer has an active eToro Money wallet linked to their trading account. Default=0." | Verbatim + "Passthrough from Dim_Customer" | YES | None |
| RealizedEquity | V_Liabilities wiki shows "Direct \| T1" only, no prose description to inherit | "Customer realized equity snapshot from Fact_SnapshotEquity via V_Liabilities." | N/A | No upstream prose to compare |
| PositionPnL | V_Liabilities wiki shows "Direct \| T1" only | "Unrealized profit/loss on open positions from Fact_CustomerUnrealized_PnL via V_Liabilities." | N/A | No upstream prose to compare |

---

### Top 5 Issues

1. **HIGH — `EvMatchStatusName` (#21): Wrong tier classification.** Tagged `(Tier 2 -- SP_AML_Multiple_Accounts, via Dim_EvMatchStatus)`. Per rubric, dim-lookup passthroughs (`SELECT dems.EvMatchStatusName`) must be Tier 1 with the dim's root origin. The SP does a straight passthrough from `Dim_EvMatchStatus.EvMatchStatusName`, whose ultimate source is `UserApiDB.Dictionary.EvMatchStatus`. Should be `(Tier 1 — UserApiDB.Dictionary.EvMatchStatus)` with the description from the Dim_EvMatchStatus wiki.

2. **MEDIUM — `PhoneVerifiedName` (#6): Usage context dropped.** Upstream wiki: "Displayed in customer cards, verification reports, and compliance dashboards." Wiki replaces this with a value list only. Both are valuable — the description should include both the value list AND the usage context.

3. **MEDIUM — `PlayerStatus` (#12): Usage context dropped.** Upstream wiki: "Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards." Wiki replaces with a value list, losing "Unique per status" and all display surface context.

4. **MEDIUM — `Club` (#15): Usage context dropped.** Upstream wiki: "Used in BackOffice reporting JOINs and customer-facing UI." Wiki replaces with nothing after the value list. Minor rewrite also adds "eToro" prefix not present upstream.

5. **LOW — `Regulation` (#11): Subtle paraphrase.** "Short code for the regulation. Used in **V_Dim_Customer and** analytics dashboards." Wiki writes "Short code for the **regulatory entity governing this customer's account**. Used in analytics dashboards." Drops the V_Dim_Customer usage hint; rewrites opening phrase.

---

### Regeneration Feedback (if re-run needed)

1. Re-tag `EvMatchStatusName` as `(Tier 1 — UserApiDB.Dictionary.EvMatchStatus)` using verbatim description from `Dim_EvMatchStatus` wiki: "Human-readable label for the EV match status. Renamed from `Name` in the production source. Values: None, PartiallyVerified, Verified, NotVerified."
2. For `PhoneVerifiedName`, keep the value list AND append the upstream usage context: "Displayed in customer cards, verification reports, and compliance dashboards."
3. For `PlayerStatus`, re-add "Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards." alongside the value list.
4. For `Club`, append "Used in BackOffice reporting JOINs and customer-facing UI." from the Dim_PlayerLevel wiki.
5. For `Regulation`, restore "Used in V_Dim_Customer and analytics dashboards" per the Dim_Regulation wiki.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_AML_Multiple_Accounts_Withdrawfulldata",
  "weighted_score": 8.20,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "FundingID",
      "upstream_quote": "FK to Billing.Funding — the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected.",
      "wiki_quote": "FK to Billing.Funding -- the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected. This table only contains FundingIDs shared by 2+ customers; IDs 1-7 (reserved/internal) are excluded.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID -- platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in Dim_Customer.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "UserName",
      "upstream_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index).",
      "wiki_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "BirthDate",
      "upstream_quote": "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification.",
      "wiki_quote": "Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. DWH note: CAST to DATE in SP (time component discarded), stored as datetime in this table.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PhoneVerifiedName",
      "upstream_quote": "Human-readable verification state label. Note: ID=2 has value 'ManualyVerified' -- a production typo (single 'l') preserved verbatim from etoro.Dictionary.PhoneVerified. Displayed in customer cards, verification reports, and compliance dashboards.",
      "wiki_quote": "Human-readable verification state label for the customer's phone number. Values: NotVerified, AutomaticallyVerified, ManualyVerified (production typo preserved), Initiated, Rejected, AbuseFlag. Dim-lookup passthrough from Dim_PhoneVerified via Dim_Customer.PhoneVerifiedID.",
      "match": "MINOR",
      "loss": "Drops 'Displayed in customer cards, verification reports, and compliance dashboards' — display surface context removed"
    },
    {
      "column": "Country",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via Dim_Customer.CountryID.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the regulatory entity governing this customer's account. Used in analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "match": "MINOR",
      "loss": "Opening phrase rewritten; 'in V_Dim_Customer' dropped from usage context"
    },
    {
      "column": "PlayerStatus",
      "upstream_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.",
      "wiki_quote": "Human-readable restriction state label for the customer's account. Values: Normal, Blocked, Blocked Upon Request, Warning... Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.",
      "match": "MINOR",
      "loss": "Drops 'Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards'"
    },
    {
      "column": "PlayerStatusReason",
      "upstream_quote": "Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). Used in BackOffice reporting and customer history views.",
      "wiki_quote": "Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), By request (22), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). Used in BackOffice reporting and customer history views.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PlayerStatusSubReasonName",
      "upstream_quote": "Human-readable sub-reason label (renamed from production `Name`). Nullable. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check. Key values: Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75).",
      "wiki_quote": "Human-readable sub-reason label (renamed from production `Name`). Nullable. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check. Key values: Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75).",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Club",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "wiki_quote": "eToro Club tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Dim-lookup passthrough from Dim_PlayerLevel.Name via Dim_Customer.PlayerLevelID.",
      "match": "MINOR",
      "loss": "Drops 'Used in BackOffice reporting JOINs and customer-facing UI'; adds 'eToro' prefix not in upstream"
    },
    {
      "column": "AffiliateID",
      "upstream_quote": "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations.",
      "wiki_quote": "Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. Passthrough from Dim_Customer.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Gender",
      "upstream_quote": "Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1.",
      "wiki_quote": "Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only in production. Used in LinkedAccountHash1. Passthrough from Dim_Customer.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "HasWallet",
      "upstream_quote": "1 if the customer has an active eToro Money wallet linked to their trading account. Default=0.",
      "wiki_quote": "1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. Passthrough from Dim_Customer.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "RealizedEquity",
      "upstream_quote": "(V_Liabilities wiki shows 'Direct | T1' only — no prose description available in bundle)",
      "wiki_quote": "Customer realized equity snapshot from Fact_SnapshotEquity via V_Liabilities. Passthrough from V_Liabilities.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PositionPnL",
      "upstream_quote": "(V_Liabilities wiki shows 'Direct | T1' only — no prose description available in bundle)",
      "wiki_quote": "Unrealized profit/loss on open positions from Fact_CustomerUnrealized_PnL via V_Liabilities. Passthrough from V_Liabilities.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "EvMatchStatusName",
      "problem": "Tagged '(Tier 2 -- SP_AML_Multiple_Accounts, via Dim_EvMatchStatus)' but rubric mandates dim-lookup passthroughs use Tier 1 with the dim's root origin. The SP selects dems.EvMatchStatusName directly from Dim_EvMatchStatus with no transform. The dim's ultimate source is UserApiDB.Dictionary.EvMatchStatus. Should be '(Tier 1 — UserApiDB.Dictionary.EvMatchStatus)' with verbatim description from the Dim_EvMatchStatus wiki."
    },
    {
      "severity": "medium",
      "column_or_section": "PhoneVerifiedName",
      "problem": "Upstream Dim_PhoneVerified wiki states 'Displayed in customer cards, verification reports, and compliance dashboards.' Wiki replaces this entirely with a value list, dropping all display surface context. Should retain both the value list and the usage context per verbatim inheritance rule."
    },
    {
      "severity": "medium",
      "column_or_section": "PlayerStatus",
      "problem": "Upstream Dim_PlayerStatus wiki states 'Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards.' Wiki drops 'Unique per status' and replaces the usage context with a value enumeration only. Both should be present."
    },
    {
      "severity": "medium",
      "column_or_section": "Club",
      "problem": "Upstream Dim_PlayerLevel wiki states 'Used in BackOffice reporting JOINs and customer-facing UI.' Wiki drops this entirely. Also adds 'eToro' prefix ('eToro Club tier display name') not present in the upstream."
    },
    {
      "severity": "low",
      "column_or_section": "Regulation",
      "problem": "Upstream Dim_Regulation wiki states 'Short code for the regulation. Used in V_Dim_Customer and analytics dashboards.' Wiki rewrites opening as 'Short code for the regulatory entity governing this customer's account' and drops 'in V_Dim_Customer' from the usage hint — a minor but real paraphrase."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag EvMatchStatusName as '(Tier 1 — UserApiDB.Dictionary.EvMatchStatus)' using verbatim description from Dim_EvMatchStatus wiki: 'Human-readable label for the EV match status. Renamed from Name in the production source. Values: None, PartiallyVerified, Verified, NotVerified.' (2) For PhoneVerifiedName, append upstream usage context: 'Displayed in customer cards, verification reports, and compliance dashboards.' alongside the existing value list. (3) For PlayerStatus, prepend 'Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards.' before the value enumeration. (4) For Club, append 'Used in BackOffice reporting JOINs and customer-facing UI.' from Dim_PlayerLevel wiki. (5) For Regulation, restore 'Used in V_Dim_Customer and analytics dashboards.' per Dim_Regulation wiki element #2.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
