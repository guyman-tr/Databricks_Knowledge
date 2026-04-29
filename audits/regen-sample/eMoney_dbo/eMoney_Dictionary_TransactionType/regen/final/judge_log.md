## Adversarial Review — eMoney_dbo.eMoney_Dictionary_TransactionType

This is a 3-column, 15-row static dictionary table. The attack surface for errors is small, but that also means any error is proportionally damaging. Let me walk through each dimension.

---

### Dimension 1 — Tier Accuracy: **10/10**

All 3 columns checked (only 3 exist):

| Column | Expected Tier | Wiki Claims | Correct? |
|--------|--------------|-------------|----------|
| TransactionTypeID | Tier 1 (passthrough from Dictionary.TransactionTypes.Id, upstream wiki exists) | Tier 1 — Dictionary.TransactionTypes | YES |
| TransactionType | Tier 1 (passthrough from Dictionary.TransactionTypes.Name, upstream wiki exists) | Tier 1 — Dictionary.TransactionTypes | YES |
| UpdateDate | Tier 2 (ETL metadata, no upstream column) | Tier 2 — Generic Pipeline | YES |

0 mismatches. No paraphrasing deductions needed at this stage (fidelity checked in D2).

---

### Dimension 2 — Upstream Fidelity: **9/10**

Two Tier 1 columns. Both have their upstream core text preserved verbatim, with inline dictionary values appended (legitimate for a ≤15-value dictionary per the writer's own stated rule).

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| TransactionTypeID | "Lookup identifier. Primary key." | "Lookup identifier. Primary key. 0=Unknown, 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat." | MINOR | Additive only — inline enum values appended. No semantic loss. |
| TransactionType | "Human-readable name for this value." | "Human-readable name for this value. 0=Unknown, 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat." | MINOR | Additive only — inline enum values appended. No semantic loss. |

The core upstream descriptions are character-for-character identical. The additions are inline dictionary values — purely additive, no rewording, no dropped semantics. This is the correct behavior for a small-cardinality dictionary. Score: 9 (two MINOR formatting diffs, no semantic loss).

---

### Dimension 3 — Completeness: **8/10** (9/10 checks)

| Check | Pass? | Notes |
|-------|-------|-------|
| All 8 sections present | YES | Sections 1–8 all present |
| Element count = DDL column count | YES | DDL: 3, Wiki: 3 |
| Every element row has 5 cells | YES | # / Element / Type / Nullable / Description |
| Every description ends with (Tier N — source) | YES | All 3 have tier tags |
| Property table has Production Source, Refresh, Distribution, UC Target | YES | All present |
| Section 5.2 ETL pipeline ASCII diagram with real names | YES | Full pipeline from FiatDwhDB through Bronze to Synapse to UC |
| Footer has tier breakdown counts | YES | "2 T1, 1 T2, 0 T3, 0 T4, 0 T5" |
| Section 1 contains row count and date range | PARTIAL | Row count (15) present. No meaningful date range for a static dictionary — "2023-06-12" mentioned in header but not in Section 1 body. |
| Dictionary columns ≤15 values list inline key=value pairs | YES | All 15 values enumerated in both Tier 1 column descriptions and Section 2 |
| .review-needed.md does NOT contain `## 4. Elements` | YES | Sidecar has items 1–4 but none is an Elements section |

9/10 → Score 8.

---

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific, concrete, and actionable:
- Names domain: eToro Money fiat platform
- States row grain: each row maps a TransactionTypeID integer to a human-readable name
- Names exact upstream: FiatDwhDB.Dictionary.TransactionTypes
- Names ETL pattern: Generic Pipeline Bronze export, Override, daily
- Row count: 15
- Names 9 downstream SP consumers with specifics (SP_eMoney_Calculated_Balance groups 15 types into 10 categories; SP_eMoney_Panel_FirstDates uses type subsets for FMI/FMO)

A new analyst would immediately know what this table is and when to use it. The Section 2 enumeration of all 15 values with the analytical grouping rules is excellent. Only missing element: the static date (2023-06-12) could be surfaced more prominently in Section 1 body rather than only the header.

---

### Dimension 5 — Data Evidence: **7/10**

Evidence of live data use:
- Row count (15) stated and consistent across sections ✓
- All 15 values enumerated by ID and name ✓
- "All UpdateDate values static at 2023-06-12" — specific date from live query ✓
- SP source code verified (CASE groupings for SP_eMoney_Calculated_Balance) ✓

Missing:
- No formal Phase Gate Checklist with P2/P3 checkboxes. The footer lists "Phases: 8/11" implicitly but no explicit checklist section.
- No NULL-rate analysis (though for a 3-column, 15-row dictionary with all NULLable columns, this is a minor gap).

---

### Dimension 6 — Shape Fidelity: **8/10**

- Numbered sections 1–8: ✓
- Tier legend in Section 4: ✓
- Real SQL samples in Section 7 (3 queries, all syntactically correct with real table names): ✓
- Footer with quality score and tier breakdown: ✓
- Header summary block with properties table: ✓

Minor deviations: No explicit Phase Gate Checklist section. The "T1 COPY VERIFICATION" block at the bottom is non-standard (writer's self-check leaked into output — harmless but not part of the golden shape).

---

### Weighted Total

```
weighted = 0.25×10 + 0.20×9 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×8
         = 2.50 + 1.80 + 1.60 + 1.35 + 0.70 + 0.80
         = 8.75
```

**Verdict: PASS**

---

### Top 5 Issues

1. **Low — T1 COPY VERIFICATION block leaked into output**: The footer contains a "T1 COPY VERIFICATION" debug block that is the writer's self-check, not part of the standard wiki shape. Should be removed.
2. **Low — No Phase Gate Checklist section**: The wiki lacks an explicit Phase Gate Checklist with P2/P3 checkboxes. The footer implies "Phases: 8/11" but the formal section is absent.
3. **Low — UpdateDate static value not in Section 1 body**: The header mentions "All UpdateDate values static at 2023-06-12" but Section 1 body doesn't repeat this. An analyst skimming Section 1 could miss this detail.
4. **Info — review-needed item 4 (Referenced-By directness)**: The sidecar correctly flags that downstream SPs join via `eMoney_Fact_Transaction_Status.TxTypeID`, not directly to this dictionary. Section 6.2 should clarify these are indirect references.
5. **Info — UC target unresolved**: The bundle confirms the UC target is unresolved. The wiki documents it but the review-needed sidecar correctly flags this for verification.

---

### Regeneration Feedback

1. Remove the "T1 COPY VERIFICATION" debug block from the footer — it's a writer self-check, not end-user content.
2. Add an explicit Phase Gate Checklist section (or integrate P2/P3 status into the footer).
3. Mention the static UpdateDate (2023-06-12) in Section 1 body, not just the header.
4. Clarify in Section 6.2 which downstream references are direct JOINs to this dictionary vs. indirect (via TxTypeID on fact/dim tables).

<JUDGE_VERDICT>
{
  "schema": "eMoney_dbo",
  "object": "eMoney_Dictionary_TransactionType",
  "weighted_score": 8.75,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "TransactionTypeID",
      "upstream_quote": "Lookup identifier. Primary key.",
      "wiki_quote": "Lookup identifier. Primary key. 0=Unknown, 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat.",
      "match": "MINOR",
      "loss": "Additive only — inline enum values appended per <=15 dictionary rule. No semantic loss."
    },
    {
      "column": "TransactionType",
      "upstream_quote": "Human-readable name for this value.",
      "wiki_quote": "Human-readable name for this value. 0=Unknown, 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat.",
      "match": "MINOR",
      "loss": "Additive only — inline enum values appended per <=15 dictionary rule. No semantic loss."
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "T1 COPY VERIFICATION debug block leaked into wiki output. This is the writer's self-check, not end-user content. Should be removed."
    },
    {
      "severity": "low",
      "column_or_section": "Missing section",
      "problem": "No explicit Phase Gate Checklist section with P2/P3 checkboxes. Footer implies 'Phases: 8/11' but the formal checklist is absent."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "UpdateDate static value (2023-06-12) mentioned only in header summary, not in Section 1 body. Analyst skimming Section 1 could miss this."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2",
      "problem": "Referenced-By list includes 10 downstream objects but does not clarify which are direct JOINs to this dictionary vs. indirect references via TxTypeID on fact/dim tables. Most SPs reference TxTypeID through eMoney_Fact_Transaction_Status, not this dictionary directly."
    },
    {
      "severity": "info",
      "column_or_section": "UC Target",
      "problem": "UC target main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dictionary_transactiontype is unresolved in the bundle. May not exist yet or may use a different naming convention."
    }
  ],
  "regeneration_feedback": "Minor polish only: (1) Remove the T1 COPY VERIFICATION debug block from the footer. (2) Add an explicit Phase Gate Checklist section or integrate P2/P3 status into footer. (3) Mention static UpdateDate (2023-06-12) in Section 1 body. (4) Clarify direct vs. indirect references in Section 6.2.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2/P3 phase gate checklist section absent — phases implied in footer but not explicit"]
  }
}
</JUDGE_VERDICT>
