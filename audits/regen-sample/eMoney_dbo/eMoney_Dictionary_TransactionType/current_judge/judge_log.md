## Adversarial Review: eMoney_dbo.eMoney_Dictionary_TransactionType

This is a 3-column, 15-row static dictionary table sourced from FiatDwhDB via Generic Pipeline. The review surface is small but the writer added substantial downstream context (analytical groupings, FMI/FMO definitions). Let me stress-test each dimension.

---

### Dimension 1 — Tier Accuracy: **10/10**

All 3 columns checked (entire table):

| Column | Expected Tier | Wiki Claims | Correct? |
|--------|--------------|-------------|----------|
| TransactionTypeID | Tier 1 (passthrough rename from Dictionary.TransactionTypes.Id, upstream wiki present) | Tier 1 — Dictionary.TransactionTypes | YES |
| TransactionType | Tier 1 (passthrough rename from Dictionary.TransactionTypes.Name, upstream wiki present) | Tier 1 — Dictionary.TransactionTypes | YES |
| UpdateDate | Tier 2 (ETL metadata, no upstream column) | Tier 2 — Generic Pipeline | YES |

0 mismatches. No paraphrasing failures on Tier 1 columns (see Dimension 2). No dim-lookup relay errors possible — this is a leaf dictionary with no dim intermediary.

---

### Dimension 2 — Upstream Fidelity: **9/10**

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| TransactionTypeID | "Lookup identifier. Primary key." | "Lookup identifier. Primary key. 0=Unknown, 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat." | MINOR | No loss. Core text verbatim; enumeration values appended from live data. |
| TransactionType | "Human-readable name for this value." | "Human-readable name for this value. 0=Unknown, 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat." | MINOR | No loss. Core text verbatim; enumeration values appended from live data. |

Both Tier 1 columns preserve the upstream description character-for-character and append live enumeration values. This is additive enrichment, not paraphrasing. No vendor names dropped, no NULL semantics removed, no meaning altered. Score: 9 (trivial formatting difference — appended enumerations).

---

### Dimension 3 — Completeness: **8/10**

| # | Check | Pass? |
|---|-------|-------|
| 1 | All 8 sections present (1–8) | YES |
| 2 | Element count matches DDL (3 DDL cols, 3 wiki rows) | YES |
| 3 | Every element row has 5 cells | YES |
| 4 | Every description ends with `(Tier N — source)` | YES |
| 5 | Property table has Production Source, Refresh, Distribution, UC Target | YES |
| 6 | Section 5.2 has ETL ASCII diagram with real names | YES |
| 7 | Footer has tier breakdown counts | YES |
| 8 | Section 1 contains row count and date range | PARTIAL — row count (15) present; no date range, but this is a static dictionary with no temporal grain |
| 9 | Dictionary columns with ≤15 values list inline key=value pairs | YES — all 15 enumerated in Elements |
| 10 | .review-needed.md does NOT contain `## 4. Elements` | YES |

9/10 checks → Score 8. The missing date range is defensible (static dictionary has no meaningful date range) but the rubric doesn't exempt dictionaries.

---

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable:
- Names the domain: eToro Money fiat platform
- Row grain: each row = one transaction type ID→name mapping
- Row count: 15
- ETL pattern: Generic Pipeline Bronze export from FiatDwhDB
- Downstream usage: names eMoney_Calculated_Balance and its 10 analytical buckets

Section 2 goes further with FMI/FMO definitions and the CryptoToFiat TBD gap. An analyst could immediately understand when and how to use this table. Only missing a date range (N/A for static dictionary).

---

### Dimension 5 — Data Evidence: **8/10**

- Row count: 15, confirmed in property table and Section 1
- Specific values: all 15 types enumerated with ID=Name mappings
- UpdateDate static since 2023-06-12 noted
- Phase Gate: sidecar lists P1, P2, P4, P8, P10A, P10B, P11 completed. P2 is present (live data). P3 (deep profiling) was skipped but a 15-row dictionary needs no NULL-rate profiling or distribution analysis — the entire table is enumerated inline.

Data claims are consistent with live query evidence. Deducting slightly for P3 skip even though it's justified.

---

### Dimension 6 — Shape Fidelity: **9/10**

- Numbered sections 1–8: present
- Tier legend in Section 4: present with 5 tiers defined
- Real SQL in Section 7: 3 queries with proper schema-qualified names
- Footer: quality score (9.3/10), phases (7/14), tier breakdown, object metadata
- Property table: complete with UC Target, distribution, index

Minor: Section headers use descriptive names rather than strict numbered format (e.g., "## 2. Business Logic" not "## 2. Business Logic & Derivation Rules"), but this is a trivial deviation.

---

### Weighted Total

```
weighted = 0.25×10 + 0.20×9 + 0.20×8 + 0.15×9 + 0.10×8 + 0.10×9
         = 2.50 + 1.80 + 1.60 + 1.35 + 0.80 + 0.90
         = 8.95
```

**Verdict: PASS**

---

### Top Issues

1. **(Low) Section 1 — no date range**: Static dictionary has no temporal grain, but the format spec expects it. Could add "Static; all 15 rows present since initial load (UpdateDate = 2023-06-12)."
2. **(Low) DDL nullability vs upstream**: Upstream defines Id as `tinyint NOT NULL` and Name as `nvarchar NOT NULL`, but DWH widens to `int NULL` / `varchar(50) NULL`. The wiki notes the type change but doesn't flag the NULL→nullable semantic change in Section 3.4 gotchas.
3. **(Info) P3 skipped**: Justified for a 15-row dictionary but means NULL-rate claims are assumed, not measured.

### Regeneration Feedback (if needed — not required for PASS)

1. Add one line to Section 1: "Static since 2023-06-12; no temporal grain."
2. Add a gotcha in 3.4: "Source columns are NOT NULL; DWH columns are nullable — NULLs would indicate a pipeline failure."

<JUDGE_VERDICT>
{
  "schema": "eMoney_dbo",
  "object": "eMoney_Dictionary_TransactionType",
  "weighted_score": 8.95,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "TransactionTypeID",
      "upstream_quote": "Lookup identifier. Primary key.",
      "wiki_quote": "Lookup identifier. Primary key. 0=Unknown, 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat.",
      "match": "MINOR",
      "loss": "No loss. Upstream core text preserved verbatim; live enumeration values appended."
    },
    {
      "column": "TransactionType",
      "upstream_quote": "Human-readable name for this value.",
      "wiki_quote": "Human-readable name for this value. 0=Unknown, 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat.",
      "match": "MINOR",
      "loss": "No loss. Upstream core text preserved verbatim; live enumeration values appended."
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "No date range stated. Static dictionary has no temporal grain, but format spec expects a date range. Should add 'Static since 2023-06-12; no temporal grain.'"
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.4 / TransactionTypeID, TransactionType",
      "problem": "Upstream columns are NOT NULL (Id tinyint NOT NULL, Name nvarchar NOT NULL) but DWH columns are nullable (int NULL, varchar(50) NULL). The type widening is documented but the nullability change is not flagged as a gotcha — NULLs in these columns would indicate a pipeline failure."
    },
    {
      "severity": "info",
      "column_or_section": "Phase Gate",
      "problem": "P3 (deep profiling) skipped. Justified for a 15-row static dictionary but means NULL-rate and distribution claims are assumed, not measured."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P3"]
  }
}
</JUDGE_VERDICT>
