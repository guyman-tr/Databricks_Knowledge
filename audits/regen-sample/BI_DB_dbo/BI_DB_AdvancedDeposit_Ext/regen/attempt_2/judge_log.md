Let me verify whether any upstream wikis exist in the repo that the writer might have missed, even though the bundle says none were resolvable.
Upstream wikis DO exist in the repo. The bundle said none were resolvable, but `Fact_BillingDeposit.md`, `Dim_PaymentStatus.md`, `Dim_Customer.md`, `Dim_Country.md`, `Dim_Funnel.md`, and `Dim_CountryBin.md` all have wikis. Let me check the critical ones to see if they have column descriptions that should have been inherited as Tier 1.
This is a critical finding. The upstream wikis **DO exist** in the repo — `Fact_BillingDeposit.md`, `Dim_PaymentStatus.md`, `Dim_Customer.md`, `Dim_Country.md`, `Dim_Funnel.md`, `Dim_CountryBin.md` all have documented Elements sections with rich descriptions. The bundle incorrectly stated "NO UPSTREAM WIKI was resolvable." Let me verify a few more specific column descriptions to complete the fidelity assessment.
All major upstream dimension tables have wikis in the repo. The bundle was defective — it failed to resolve any of them. Now I have all the evidence needed to render the verdict.

---

## Adversarial Judge Review: BI_DB_dbo.BI_DB_AdvancedDeposit_Ext

### Dimension 1 — Tier Accuracy: **3/10**

**Sampled 5 columns:**

| Column | Expected Tier | Wiki Tier | Verdict |
|--------|-------------|-----------|---------|
| DepositID (#1) | Tier 1 — Fact_BillingDeposit wiki exists with description | Tier 2 | MISMATCH |
| Amount (#9) | Tier 1 — Fact_BillingDeposit wiki exists | Tier 2 | MISMATCH |
| Country (#34) | Tier 1 — Dim_Country.Name wiki exists (origin: Dictionary.Country) | Tier 2 | MISMATCH |
| Funnel (#39) | Tier 1 — Dim_Funnel.Name wiki exists (origin: Dictionary.Funnel) | Tier 2 | MISMATCH |
| CardSubType (#44) | Tier 2 — Dim_CountryBin.CardSubType is itself Tier 2 | Tier 2 | MATCH |

4/5 mismatches → base score 3. The upstream wikis exist at `knowledge/synapse/Wiki/DWH_dbo/Tables/` for Fact_BillingDeposit, Dim_PaymentStatus, Dim_Customer, Dim_Country, Dim_Funnel, Dim_CountryBin, Dim_CardType, Dim_BillingDepot, and Dim_Affiliate. The bundle erroneously reported "NO UPSTREAM WIKI was resolvable" — but they are all present. Approximately 40+ of 47 columns should be Tier 1 with verbatim inherited descriptions.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

The wiki contains **zero Tier 1 columns**, so there is nothing to compare character-by-character. The bundle told the writer no upstream wikis existed. The writer followed that instruction faithfully and transparently documented the limitation. Per rubric: "No upstream wiki existed in the bundle → 7 (neutral)."

However, this neutrality masks a critical systemic failure: the upstream wikis DO exist in the repo. The regeneration must fix the bundle.

### T1 Fidelity Table (Mandatory)

The wiki declares 0 Tier 1 columns. Table is empty. The columns below are examples of what SHOULD have been Tier 1, shown in the issues section.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — wiki has 0 Tier 1 columns)* | — | — | — | All ~40 columns that should be Tier 1 are tagged Tier 2 due to defective bundle |

### Dimension 3 — Completeness: **8/10**

Checklist (9/10):
- [x] All 8 sections present
- [x] Element count matches DDL (47/47)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real SP names
- [x] Footer has tier breakdown counts
- [x] Section 1 has row count (0) — date range N/A for empty table
- [ ] Dictionary columns with ≤15 values list inline key=value pairs — PaymentStatus_Name has limited enum values (from Dim_PaymentStatus: 1=Pending through 7=CompletedExternally) but no inline listing; Channel lists values in description but not in key=value format
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

### Dimension 4 — Business Meaning: **9/10**

Excellent. Section 1 is specific, concrete, and actionable. It names: the row grain (deposit transactions), the ETL SP (SP_H_Deposits), the dormancy status with date (~Nov 2024), the replacement table (BI_DB_Deposits), all source groupings with column counts, and the decommission recommendation. A new analyst would immediately know not to use this table and where to go instead.

### Dimension 5 — Data Evidence: **7/10**

- Row count confirmed: 0 rows via live query
- P2 marked `[x]` (sample data checked — confirmed empty)
- P3 marked `[-]` with justification (0 rows)
- Backup cleanup date cited (2024-11-17)
- Some enum values listed inline (Channel values in description)
- No fabricated data claims for a 0-row table

### Dimension 6 — Shape Fidelity: **8/10**

Good structural compliance: numbered sections 1-8, tier legend in Section 4, Phase Gate Checklist, SQL samples in Section 7 (alternative queries appropriate for dormant table), footer with tier breakdown and phases completed. Minor deviations: Section 8 titled "Atlassian Knowledge Sources" rather than standard; tier legend only lists Tier 2 (correct but atypical).

---

### Weighted Score

```
weighted = 0.25×3 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×8
         = 0.75 + 1.40 + 1.60 + 1.35 + 0.70 + 0.80
         = 6.60
```

**Verdict: FAIL** (6.60 < 7.5)

---

### Top 5 Issues

1. **CRITICAL — Defective bundle caused universal Tier 2 misassignment.** All 47 columns are tagged Tier 2 when upstream wikis exist for Fact_BillingDeposit (22 passthrough columns), Dim_PaymentStatus (2 columns), Dim_Customer (4 columns), Dim_Country (2 columns), Dim_Funnel (3 columns), Dim_CountryBin (2 columns), Dim_CardType (1 column), Dim_BillingDepot (1 column). Approximately 40+ columns should be Tier 1 with verbatim descriptions.

2. **HIGH — DepositID description paraphrases upstream.** Upstream (Fact_BillingDeposit wiki): *"Primary distribution key (HASH). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Clustered index key in DWH."* Wiki says: *"Unique identifier for each deposit attempt."* Lost: HASH distribution, IDENTITY, clustered index key.

3. **HIGH — PaymentStatusID description drops enum values.** Upstream: *"Key values: 1=New, 2=Approved (73%), 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE (10.2%). Full 39-value enum in upstream wiki."* Wiki: *"Current deposit payment status."* Lost all enum values and distribution percentages.

4. **HIGH — Amount description drops ETL cap rule.** Upstream: *"As of 2025-04-17, capped via CASE expression in ETL to prevent extreme outlier values from distorting aggregations."* Wiki: *"Deposit amount in the deposit currency."* Lost the ETL capping rule — an analyst using aggregations would not know about the cap.

5. **MEDIUM — Dim-lookup columns cite SP relay instead of dictionary origin.** Country is tagged `(Tier 2 — SP_H_Deposits code analysis)` but Dim_Country.Name traces to `Dictionary.Country` per the Dim_Country wiki. Similarly, Funnel/FunnelFrom/AcquisitionFunnel should trace to `Dictionary.Funnel`, PaymentStatus_Name to `Dictionary.PaymentStatus`, etc.

---

### Regeneration Feedback

1. **Fix the upstream bundle.** Re-resolve upstream wikis — they exist at `knowledge/synapse/Wiki/DWH_dbo/Tables/` for: `Fact_BillingDeposit.md`, `Dim_PaymentStatus.md`, `Dim_Customer.md`, `Dim_Country.md`, `Dim_Funnel.md`, `Dim_CountryBin.md`, `Dim_CardType.md`, `Dim_BillingDepot.md`, `Dim_Affiliate.md`. Include them in the bundle.
2. **Re-tag ~40 columns as Tier 1.** All passthroughs from Fact_BillingDeposit (DepositID through ExTransactionID, excluding OldPaymentID and Code), all dim-lookup passthroughs (PaymentStatus_Name, Country, Funnel, etc.) should be Tier 1 with the root origin (e.g., `Tier 1 — Billing.Deposit` or `Tier 1 — Dictionary.Country`).
3. **Copy upstream descriptions VERBATIM.** Do not paraphrase. Specifically preserve: enum key=value pairs (PaymentStatusID), NULL semantics (RiskManagementStatusID "NULL=no risk check recorded"), ETL cap rules (Amount), distribution details (DepositID HASH key), and FK targets.
4. **Add inline enum values** for PaymentStatus_Name, RiskManagementStatusID, and IsFTD from the upstream wikis.
5. **Keep OldPaymentID and Code as Tier 2** (hardcoded NULLs — no upstream to inherit from). Keep CardSubType and CardCategory as Tier 2 (upstream Dim_CountryBin marks them Tier 2).

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_AdvancedDeposit_Ext",
  "weighted_score": 6.60,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "critical",
      "column_or_section": "ALL 47 columns",
      "problem": "Defective upstream bundle reported 'NO UPSTREAM WIKI was resolvable' but wikis exist in the repo for Fact_BillingDeposit, Dim_PaymentStatus, Dim_Customer, Dim_Country, Dim_Funnel, Dim_CountryBin, Dim_CardType, Dim_BillingDepot, Dim_Affiliate. ~40 columns should be Tier 1 with verbatim descriptions but are all tagged Tier 2."
    },
    {
      "severity": "high",
      "column_or_section": "DepositID",
      "problem": "Description paraphrases upstream. Upstream: 'Primary distribution key (HASH). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Clustered index key in DWH.' Wiki: 'Unique identifier for each deposit attempt.' Lost HASH distribution key, IDENTITY, clustered index key."
    },
    {
      "severity": "high",
      "column_or_section": "PaymentStatusID",
      "problem": "Upstream has rich enum values: '1=New, 2=Approved (73%), 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE (10.2%). Full 39-value enum.' Wiki drops all enum values and distributions."
    },
    {
      "severity": "high",
      "column_or_section": "Amount",
      "problem": "Upstream notes: 'As of 2025-04-17, capped via CASE expression in ETL to prevent extreme outlier values from distorting aggregations.' Wiki drops the ETL capping rule entirely."
    },
    {
      "severity": "high",
      "column_or_section": "Country, Funnel, FunnelFrom, AcquisitionFunnel, PaymentStatus_Name",
      "problem": "Dim-lookup passthroughs cite SP relay (Tier 2 — SP_H_Deposits) instead of root dictionary origin. Country should be Tier 1 — Dictionary.Country, Funnel/FunnelFrom/AcquisitionFunnel should be Tier 1 — Dictionary.Funnel, PaymentStatus_Name should be Tier 1 — Dictionary.PaymentStatus."
    },
    {
      "severity": "medium",
      "column_or_section": "RiskManagementStatusID",
      "problem": "Upstream has '69 distinct risk reason codes. Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation.' Wiki retains NULL semantics but drops all enum details."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 4 Elements",
      "problem": "No inline enum key=value pairs for PaymentStatus_Name or IsFTD despite upstream wikis documenting them. PaymentStatus has 7+ known values, IsFTD has binary 0/1 with ~60.6% FTD=1 distribution."
    }
  ],
  "regeneration_feedback": "Re-run with corrected bundle: (1) Include upstream wikis from knowledge/synapse/Wiki/DWH_dbo/Tables/ for Fact_BillingDeposit, Dim_PaymentStatus, Dim_Customer, Dim_Country, Dim_Funnel, Dim_CountryBin, Dim_CardType, Dim_BillingDepot, Dim_Affiliate. (2) Re-tag ~40 columns as Tier 1 with root origins (e.g. Tier 1 — Billing.Deposit, Tier 1 — Dictionary.Country). (3) Copy upstream descriptions VERBATIM — preserve enum values, NULL semantics, ETL cap rules, FK targets. (4) Keep OldPaymentID, Code as Tier 2 (hardcoded NULLs); keep CardSubType, CardCategory as Tier 2 (upstream Dim_CountryBin marks them Tier 2). (5) Add inline enum key=value pairs for PaymentStatusID, IsFTD from upstream wikis.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P3 (0 rows — justified)", "P7 (dormant — justified)", "P10 (none found)"]
  }
}
</JUDGE_VERDICT>
