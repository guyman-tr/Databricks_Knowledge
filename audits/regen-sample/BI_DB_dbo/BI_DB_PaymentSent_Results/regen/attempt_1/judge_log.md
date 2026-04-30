I'll review this wiki systematically against the SP code and upstream bundle.

## Per-Dimension Analysis

### Dimension 1 — Tier Accuracy (Score: 7)

Five random columns sampled:

| Column | Wiki Claim | Actual | Correct? |
|--------|-----------|--------|----------|
| **CID** | Tier 1 — Customer.CustomerStatic | SP reads `fbd.[CID]` from `External_etoro_Billing_Withdraw` (no wiki). Dim_Customer is joined only for RegulationID, NOT to source CID. | **NO** — should be Tier 2 |
| **Regulation** | Tier 1 — Dictionary.Regulation | `dr.Name` from `Dim_Regulation` via `Dim_Customer.RegulationID`. Dim-lookup passthrough. Dim_Regulation wiki confirms Tier 1 from Dictionary.Regulation. | YES |
| **Currency** | Tier 1 — Dictionary.Currency | `CURR1.[Abbreviation]` from `Dim_Currency` via `wtf.ProcessCurrencyID`. Dim-lookup passthrough. Dim_Currency wiki confirms Tier 1. | YES |
| **DaysInPaymentSentStatus** | Tier 2 — External_etoro_History | `cast(getdate()-lu.LastUpdatedDate as int)` — ETL-computed. | YES |
| **WithdrawID** | Tier 2 — External_etoro_Billing_Withdraw | Passthrough from external table with no wiki. | YES |

1 mismatch (CID) → base score 7. No additional paraphrasing deductions on correctly-tagged Tier 1 columns.

### Dimension 2 — Upstream Fidelity (Score: 6)

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|-----------|-------|------|
| **CID** | Dim_Customer.RealCID: "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from External_etoro_Billing_Withdraw." | **NO — wrong tier** | CID comes from External_etoro_Billing_Withdraw (no wiki), NOT from Dim_Customer. Writer borrowed Dim_Customer's description to dress up a Tier 2 column as Tier 1. |
| **Regulation** | Dim_Regulation.Name: "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Dim-lookup passthrough from Dim_Regulation.Name via Dim_Customer.RegulationID." | **MINOR** | Dropped "Values match production Dictionary.Regulation.Name", replaced with dim-lookup context. Meaning preserved. |
| **Currency** | Dim_Currency.Abbreviation: "Ticker symbol. 'USD', 'EUR' for forex; 'AAPL.US', 'TSLA.US' for US stocks (format: TICKER.EXCHANGE); 'BTC' for crypto. Unique across all instruments. Use this for human-readable instrument identification." | "Ticker symbol. 'USD', 'EUR' for forex; 'AAPL.US', 'TSLA.US' for US stocks (format: TICKER.EXCHANGE); 'BTC' for crypto. Unique across all instruments. Use this for human-readable instrument identification. Dim-lookup passthrough from Dim_Currency.Abbreviation via ProcessCurrencyID. In this table, only USD, EUR, GBP, AUD, CAD appear (wire transfer currencies)." | **YES** | Core upstream text verbatim; added table-specific context appended after. |

CID is a wrong-tier-origin issue (promoted external table column to Tier 1 using dim description). Deduct 2 for wrong tier origin. Base score 7 (neutral since one upstream existed but was wrongly applied) → 6 after deduction.

### Dimension 3 — Completeness (Score: 8)

| Check | Pass? |
|-------|-------|
| All 8 sections present | YES |
| Element count = DDL count (11/11) | YES |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count and date range | YES (0 rows, explains empty state) |
| Dictionary columns ≤15 values have inline k=v pairs | NO — Currency has exactly 5 values but no `1=USD, 2=EUR...` inline mapping in the element description |
| .review-needed.md has no `## 4. Elements` | YES |

9/10 → Score: 8.

### Dimension 4 — Business Meaning (Score: 8)

Section 1 is strong: names the domain (wire withdrawal monitoring), row grain (stuck cashouts), ETL SP, refresh pattern (TRUNCATE+INSERT), and explains the 0-row operational state. However, it contains a **factual error about CAD**: the wiki claims CAD is one of 5 monitored currencies, but the SP's `#final` WHERE clause has no OR-branch matching CAD. CAD rows from `#cashouts` are always filtered OUT by the final WHERE clause. The wiki misleads analysts into expecting CAD rows. Deducted 1 point for this factual error. Good but flawed → 8.

### Dimension 5 — Data Evidence (Score: 6)

Row count (0 rows) is stated. No date range applicable (empty table). Specific enum values are listed (CashoutStatusID=6, currency IDs). No explicit P2/P3 phase gate checklist markings in the wiki body. Footer says "Phases: 10/14" but the wiki body contains no "Phase 2" or "Phase 3" checkbox evidence. The data claims are plausible but unverifiable from the wiki alone.

### Dimension 6 — Shape Fidelity (Score: 8)

Numbered sections 1-8 present. Tier legend in Section 4 (simplified, no stars). Real SQL in Section 7 with proper bracket-quoting of `[Amount$Withdraw]`. Footer has quality score, tier breakdown, phases count. Minor deviation: tier legend is simplified (2 tiers only, no star ratings). Overall solid shape.

---

## Weighted Score

```
weighted = 0.25*7 + 0.20*6 + 0.20*8 + 0.15*8 + 0.10*6 + 0.10*8
         = 1.75 + 1.20 + 1.60 + 1.20 + 0.60 + 0.80
         = 7.15
```

**Verdict: FAIL** (7.15 < 7.5)

---

## Top 5 Issues

1. **HIGH — CID wrongly tagged Tier 1**: CID is selected from `fbd` (`External_etoro_Billing_Withdraw`), not looked up from Dim_Customer. The SP joins Dim_Customer only for RegulationID. Writer borrowed the Dim_Customer.RealCID description to upgrade a Tier 2 column.

2. **HIGH — CAD business logic error**: Section 2.2 and 3.4 claim "CAD has no explicit aging threshold" implying CAD rows may appear. In reality, the `#final` WHERE clause requires matching one of four OR-branches (USD/EUR, AUD+CySEC, AUD+non-CySEC, GBP). CAD matches NONE, so CAD rows are **always excluded** from the final output. The wiki misleads analysts.

3. **MEDIUM — Section 1 claims 5 currencies, effective output is 4**: The summary says "USD, EUR, GBP, AUD, CAD only" but CAD cannot appear in the final table due to the WHERE clause gap. This makes the opening paragraph factually inaccurate.

4. **LOW — Regulation description paraphrased**: Upstream Dim_Regulation.Name says "Values match production Dictionary.Regulation.Name" — wiki drops this and substitutes dim-lookup context. Minor semantic loss.

5. **LOW — No inline key=value pairs for Currency**: Currency column has exactly 5 possible values in this table. The element description mentions the values in prose but doesn't list them as a formal mapping (e.g., `ProcessCurrencyID: 1=USD, 2=EUR, 3=GBP, 5=AUD, 7=CAD`).

---

## Regeneration Feedback

1. Re-tag CID as `(Tier 2 — External_etoro_Billing_Withdraw)` — it is NOT a dim-lookup passthrough; the SP reads it directly from the billing external table.
2. Fix CAD business logic: CAD is filtered to `#cashouts` but excluded from `#final` because no OR-branch in the final WHERE matches CAD. Either document this as "CAD is effectively excluded despite being in the currency filter" or confirm with the SP author whether this is a bug.
3. Update Section 1 summary to say 4 effective currencies (USD, EUR, GBP, AUD), noting CAD is filtered in `#cashouts` but excluded in `#final`.
4. Restore verbatim upstream text for Regulation: include "Values match production Dictionary.Regulation.Name" from Dim_Regulation wiki.
5. Add inline key=value mapping for Currency element: `ProcessCurrencyID 1=USD, 2=EUR, 3=GBP, 5=AUD` (drop 7=CAD or note its exclusion).

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_PaymentSent_Results",
  "weighted_score": 7.15,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 6,
    "completeness": 8,
    "business_meaning": 8,
    "data_evidence": 6,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic)",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from External_etoro_Billing_Withdraw. (Tier 1 — Customer.CustomerStatic)",
      "match": "NO",
      "loss": "Wrong tier assignment. CID is read from External_etoro_Billing_Withdraw (fbd.[CID]), not looked up from Dim_Customer. The Dim_Customer join is only for RegulationID. Writer borrowed the Dim_Customer.RealCID description to upgrade a Tier 2 column to Tier 1."
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation)",
      "wiki_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Dim-lookup passthrough from Dim_Regulation.Name via Dim_Customer.RegulationID. (Tier 1 — Dictionary.Regulation)",
      "match": "MINOR",
      "loss": "Dropped 'Values match production Dictionary.Regulation.Name', replaced with dim-lookup context. Core meaning preserved."
    },
    {
      "column": "Currency",
      "upstream_quote": "Ticker symbol. \"USD\", \"EUR\" for forex; \"AAPL.US\", \"TSLA.US\" for US stocks (format: TICKER.EXCHANGE); \"BTC\" for crypto. Unique across all instruments. Use this for human-readable instrument identification. (Tier 1 - Dictionary.Currency upstream wiki)",
      "wiki_quote": "Ticker symbol. \"USD\", \"EUR\" for forex; \"AAPL.US\", \"TSLA.US\" for US stocks (format: TICKER.EXCHANGE); \"BTC\" for crypto. Unique across all instruments. Use this for human-readable instrument identification. Dim-lookup passthrough from Dim_Currency.Abbreviation via ProcessCurrencyID. In this table, only USD, EUR, GBP, AUD, CAD appear (wire transfer currencies). (Tier 1 — Dictionary.Currency)",
      "wiki_quote_note": "Core upstream text is verbatim; table-specific context appended after.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "CID",
      "problem": "Tagged Tier 1 — Customer.CustomerStatic but CID is selected from fbd (External_etoro_Billing_Withdraw), not from Dim_Customer. The SP joins Dim_Customer only for RegulationID. Writer borrowed the Dim_Customer.RealCID description to dress up a Tier 2 column. Should be Tier 2 — External_etoro_Billing_Withdraw."
    },
    {
      "severity": "high",
      "column_or_section": "Section 2.2 / Section 3.4 (CAD threshold)",
      "problem": "Wiki claims CAD has no explicit aging threshold and 'may appear regardless of age'. In reality, the #final WHERE clause requires matching one of four OR-branches (USD/EUR, AUD+CySEC, AUD+non-CySEC, GBP). CAD matches NONE of them, so CAD rows are always excluded from the final output. The wiki gives analysts a false expectation that CAD rows can appear."
    },
    {
      "severity": "high",
      "column_or_section": "Section 1 (summary)",
      "problem": "Summary says 'Filtered to wire transfers in USD, EUR, GBP, AUD, CAD only' but CAD is effectively excluded by the #final WHERE clause. The effective output covers only 4 currencies."
    },
    {
      "severity": "low",
      "column_or_section": "Regulation",
      "problem": "Upstream Dim_Regulation.Name says 'Values match production Dictionary.Regulation.Name' — wiki drops this line and substitutes dim-lookup context. Minor semantic loss."
    },
    {
      "severity": "low",
      "column_or_section": "Currency (element #3)",
      "problem": "Currency has exactly 5 values in #cashouts (4 effective in output) but the element description does not include inline key=value pairs mapping ProcessCurrencyID to abbreviation (1=USD, 2=EUR, 3=GBP, 5=AUD, 7=CAD)."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag CID as Tier 2 — External_etoro_Billing_Withdraw. It is NOT a dim-lookup; the SP reads CID directly from the billing external table. (2) Fix CAD business logic: the #final WHERE clause has no OR-branch matching CAD, so CAD rows are always excluded despite being in the #cashouts currency filter. Document this as effective exclusion or flag as a potential SP bug. (3) Update Section 1 to say 4 effective currencies (USD, EUR, GBP, AUD), noting CAD is filtered at the intermediate stage but excluded from the final output. (4) Restore verbatim text for Regulation from Dim_Regulation wiki: include 'Values match production Dictionary.Regulation.Name'. (5) Add inline ProcessCurrencyID key=value mapping to Currency element description.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2 and P3 not explicitly marked in wiki body"]
  }
}
</JUDGE_VERDICT>
