## Adversarial Judge Review: BI_DB_dbo.BI_DB_H_OPS_HighCompensationsVsDeposits

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 7/10**
Sampled 5 columns: CompensationAmount (T2 correct), PlayerStatus (T1 correct — dim-lookup passthrough to Dictionary.PlayerStatus), PlayerStatusReason (T1 correct), PlayerStatusSubReason (T1 correct), RealCID (T1 INCORRECT). RealCID is tagged `(Tier 1 — Customer.CustomerStatic)` but the SP obtains CID from `External_etoro_Billing_Deposit` (via `#deps → #dailydepositors`), not from Dim_Customer. The external table has no wiki. Per tier rules ("passthrough WITH upstream wiki present → Tier 1"), this should be Tier 2 since the immediate source is an undocumented external table. 1 mismatch out of 5 = 7.

**Dimension 2 — Upstream Fidelity: 10/10**
All four Tier 1 columns (RealCID, PlayerStatus, PlayerStatusReason, PlayerStatusSubReason) carry descriptions that are character-for-character verbatim from their upstream wikis, with only an appended "Passthrough from Dim_X via Dim_Customer" note that adds context without altering or removing meaning. No vendor names dropped, no NULL semantics lost, no key values omitted.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| RealCID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." (Dim_Customer #1) | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | YES | — |
| PlayerStatus | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons." (Dim_PlayerStatus #2) | "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. Passthrough from Dim_PlayerStatus via Dim_Customer." | YES | — |
| PlayerStatusReason | "Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). Used in BackOffice reporting and customer history views." (Dim_PlayerStatusReasons #2) | Same text + "Passthrough from Dim_PlayerStatusReasons via Dim_Customer." | YES | — |
| PlayerStatusSubReason | "Human-readable sub-reason label (renamed from production `Name`). Nullable. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check. Key values: Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75)." (Dim_PlayerStatusSubReasons #2) | Same text + "Passthrough from Dim_PlayerStatusSubReasons via Dim_Customer." | YES | — |

**Dimension 3 — Completeness: 10/10**
All 8 sections present. Element count = 12/12 matches DDL. Every element row has 5 cells with tier tags. Property table has Production Source, Refresh, Distribution, UC Target. Section 5.2 has detailed ETL pipeline diagram with real object names. Footer has tier breakdown. Section 1 has row count (1) and date (2024-02-05). No dictionary FK columns with ≤15 values to enumerate (columns hold resolved names). Review-needed sidecar does not contain `## 4. Elements`. 10/10 checks pass.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (operations fraud monitoring), two detection use cases with exact thresholds (>50% ratio, >3 deposits/24hrs), specific payment methods with IDs (ACH=29, PWMB=32, etc.), filter criteria (CreditTypeID=6, CompensationReasonID=7), ETL pattern (TRUNCATE+INSERT), row count (1), and last refresh date. An analyst reading this immediately knows what the table catches and how.

**Dimension 5 — Data Evidence: 7/10**
Row count (1) and last update (2024-02-05) are present in Section 1. Specific enum values are listed for FundingTypeIDs and CreditTypeIDs. NULL-rate patterns documented. However, no explicit Phase Gate Checklist with P2/P3 checkboxes is shown. Footer says "Phases: 11/14" without detailing which phases completed.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1-8, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases list. Minor deviation: tier legend only shows Tier 1 and Tier 2 (the only tiers present), omitting the full 5-tier reference legend.

### Top 5 Issues

1. **RealCID mis-tiered** (medium): Tagged `(Tier 1 — Customer.CustomerStatic)` but SP obtains CID from `External_etoro_Billing_Deposit` (no wiki). Should be Tier 2 since the immediate source is an undocumented external table. The Dim_Customer wiki documents the same identifier, but this SP doesn't source RealCID from Dim_Customer.

2. **Lineage inconsistency for RealCID** (low): Section 5.1 lineage table correctly shows source as `External_etoro_Billing_Deposit.CID`, but the Element description claims `(Tier 1 — Customer.CustomerStatic)`. These contradict each other.

3. **No Phase Gate Checklist** (low): Footer says "Phases: 11/14" but no explicit checklist with P2/P3 boxes. Makes it harder to verify whether data claims are from live queries or fabricated.

4. **Incomplete tier legend** (low): Section 4 legend only shows Tier 1 and Tier 2. While these are the only tiers used, the golden reference shape includes all 5 tiers.

5. **Compensation$/Deposits$ formula sign** (low): Wiki Section 5.1 shows transform as `-CompensationAmount / DepositAmount$`. The SP computes `(-c.CompensationAmount/d.DepositAmount$)` where `c.CompensationAmount` is already `SUM(Payment)` (a negative number). The SP then negates it in the SELECT as `-c.CompensationAmount AS CompensationAmount`. So the ratio column is computed from the already-negated CompensationAmount. This is technically correct but the sign explanation could be clearer.

### Regeneration Feedback

1. Re-tag RealCID as `(Tier 2 — External_etoro_Billing_Deposit)` since the SP sources CID from the external table, not from Dim_Customer. Update Section 5.1 to be consistent.
2. Add full 5-tier legend to Section 4 even if only T1/T2 are used.
3. Add explicit Phase Gate Checklist showing which phases (P1-P3) were completed.

### Weighted Score

```
weighted = 0.25*7 + 0.20*10 + 0.20*10 + 0.15*9 + 0.10*7 + 0.10*9
         = 1.75  + 2.00    + 2.00    + 1.35   + 0.70   + 0.90
         = 8.70
```

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_H_OPS_HighCompensationsVsDeposits",
  "weighted_score": 8.70,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 10,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "RealCID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PlayerStatus",
      "upstream_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.",
      "wiki_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. Passthrough from Dim_PlayerStatus via Dim_Customer.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PlayerStatusReason",
      "upstream_quote": "Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). Used in BackOffice reporting and customer history views.",
      "wiki_quote": "Human-readable reason label (nullable). Key values: None (0), Failed Verification (1), Chargeback (5), AML-Account Closed (6), HRC (7), AML (10), AML review (11), WCH match (18), Right to be forgotten (20), Self-Service (21), eToro Money Restriction (33), Abusive Trading (34), Hacked Account (35), Tax (41). Used in BackOffice reporting and customer history views. Passthrough from Dim_PlayerStatusReasons via Dim_Customer.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PlayerStatusSubReason",
      "upstream_quote": "Human-readable sub-reason label (renamed from production `Name`). Nullable. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check. Key values: Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75).",
      "wiki_quote": "Human-readable sub-reason label (renamed from production `Name`). Nullable. Key abbreviations: CHBK=Chargeback, POI=Proof of Identity, POA=Proof of Address, FTD=First Time Deposit, MOP=Method of Payment, PWMB=eToro Money, SAR=Suspicious Activity Report, WCH=World Check. Key values: Fraud (1), Fake docs (2), ACH CHBK (35), Credit Card CHBK (36), PayPal CHBK (37), SAR filed (73), FATCA (66), W-8BEN (76), Vulnerable Client (75). Passthrough from Dim_PlayerStatusSubReasons via Dim_Customer.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "RealCID",
      "problem": "Tagged Tier 1 — Customer.CustomerStatic but SP sources CID from External_etoro_Billing_Deposit (no upstream wiki). Should be Tier 2 — External_etoro_Billing_Deposit per tier rules requiring upstream wiki presence for Tier 1."
    },
    {
      "severity": "low",
      "column_or_section": "RealCID (Section 4 vs 5.1)",
      "problem": "Section 5.1 lineage correctly shows source as External_etoro_Billing_Deposit.CID with rename transform, but Element description claims Tier 1 — Customer.CustomerStatic. Internal inconsistency."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 (Tier Legend)",
      "problem": "Tier legend only shows Tier 1 and Tier 2. Golden reference shape includes all 5 tiers even when not all are used."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "No explicit Phase Gate Checklist with P2/P3 checkboxes. Footer says Phases: 11/14 without detailing which phases were completed."
    },
    {
      "severity": "low",
      "column_or_section": "Compensation$/Deposits$ (Section 5.1)",
      "problem": "Transform shown as -CompensationAmount/DepositAmount$ but CompensationAmount in the SELECT is already negated (-c.CompensationAmount). The ratio column uses the pre-negated value. Sign chain could be clearer."
    }
  ],
  "regeneration_feedback": "Re-tag RealCID as Tier 2 — External_etoro_Billing_Deposit (SP sources CID from the external table, not Dim_Customer). Add full 5-tier legend to Section 4. Add explicit Phase Gate Checklist showing P1-P3 completion status.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase Gate Checklist not explicitly shown; footer says 11/14 phases"]
  }
}
</JUDGE_VERDICT>
