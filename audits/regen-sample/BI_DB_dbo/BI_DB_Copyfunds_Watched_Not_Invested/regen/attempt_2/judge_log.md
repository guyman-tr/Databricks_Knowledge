## Human Summary — BI_DB_dbo.BI_DB_Copyfunds_Watched_Not_Invested

### Per-Dimension Scores

| Dimension | Score | One-line justification |
|---|---|---|
| Tier Accuracy (25%) | 10 | All 5 sampled columns correctly tagged; no paraphrasing failures on any T1 column |
| Upstream Fidelity (20%) | 9 | All 6 T1 columns with available upstream text are verbatim-quoted + contextual detail added; MoneyAvailable has no upstream description in bundle (neutral) |
| Completeness (20%) | 8 | 9/10 checklist passes; `[Account Manager]` Nullable cell says NO but DDL declares the column NULL |
| Business Meaning (15%) | 9 | Specific, names row grain, ETL SP, full-rebuild pattern, row count, and calls out the commented-out filter and fan-out bug |
| Data Evidence (10%) | 9 | P2+P3 marked completed; row count, distributions, ranges, specific fan-out CID examples all present |
| Shape Fidelity (10%) | 8 | All 8 sections and SQL samples present; Section 4 omits the canonical tier-legend table found in upstream wikis |

**Weighted score**: 0.25×10 + 0.20×9 + 0.20×8 + 0.15×9 + 0.10×9 + 0.10×8 = **8.95**

---

### T1 Fidelity Table

| Column | Upstream source | Upstream quote | Wiki quote | Match |
|---|---|---|---|---|
| FundName | Dim_Customer.UserName | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Here this is the username of the eToro-managed fund account (AccountTypeID=9)..." | MINOR |
| RealCID | Dim_Customer.RealCID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | Same + "Here this identifies the investor (the user who followed the fund)." | MINOR |
| UserName | Dim_Customer.UserName | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." | Same + "Here this is the investor's username." | MINOR |
| FundCID | Dim_Customer.RealCID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." | Same + "Here this is the RealCID of the eToro-managed fund account (dc2.RealCID)." | MINOR |
| AccountManagerID | Dim_Customer.AccountManagerID | "Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned." | Same + "Here this is the investor's assigned account manager ID." | MINOR |
| MoneyAvailable | V_Liabilities.Credit → Fact_SnapshotEquity.Credit | *(V_Liabilities output-column table lists Credit with source only, no description text — Fact_SnapshotEquity wiki not in bundle)* | "Renamed from V_Liabilities.Credit — the customer available credit balance as of yesterday (DateID = @ddID). Direct passthrough from Fact_SnapshotEquity.Credit via V_Liabilities. Range: -$2,572.79 to $855,862.42..." | N/A (no upstream description available) |
| LiquidAssetsAnswer | BI_DB_KYC_Panel.Q11_AnswerText | "Answer text for Q11." | "Answer text for Q11. Self-reported liquid assets bracket from the investor's KYC questionnaire (Q11). Values include 'Up to $10K', '$10K-$50K'..." | MINOR |

All MINOR — verbatim base preserved, good contextual additions. Zero NO matches.

---

### Top 5 Issues

1. **[Account Manager] Nullable DDL mismatch** *(medium — Elements table)*: DDL defines `[Account Manager] [varchar](50) NULL` but the Elements table shows Nullable = `NO`. The column IS nullable by DDL; the INNER JOIN to Dim_Manager prevents NULLs appearing at runtime, but the declared type should say YES with the guarantee explained in the description.

2. **Section 2.5 duplicate heading number** *(low — Section 2)*: Two consecutive subsections are both numbered `### 2.5` — "MoneyAvailable = Yesterday's Credit" and "LiquidAssetsAnswer = KYC Q11 Self-Reported Bracket". The second should be `2.6`, and the existing `2.6` ("Fan-Out Bug") should shift to `2.7`.

3. **V_Liabilities INNER JOIN exclusion not called out with ⚠** *(medium — Section 1 / Section 5)*: The SP uses `JOIN DWH_dbo.V_Liabilities vl ON t.RealCID = vl.CID AND vl.DateID = @ddID` (INNER JOIN). Investors without a V_Liabilities row for yesterday are silently excluded from the output, just like the Dim_Manager INNER JOIN exclusion — but only the Dim_Manager exclusion is flagged with a warning in Section 1 and the ETL diagram. V_Liabilities is shown in the diagram but lacks the ⚠ note.

4. **Missing Tier Legend table in Section 4** *(low — Section 4)*: Upstream wikis (Dim_Mirror, Dim_Manager) begin the Elements section with a `| Stars | Tier | Tag |` reference box. This wiki omits it, relying on the footer counts. Minor structural deviation.

5. **MoneyAvailable root-level upstream description unavailable** *(informational)*: Fact_SnapshotEquity wiki not in bundle means the verbatim upstream description for `Fact_SnapshotEquity.Credit` could not be verified. Already flagged in review-needed sidecar #6. No action needed in regen unless the Fact_SnapshotEquity wiki is added to the bundle.

---

### Regeneration Feedback

1. Fix `[Account Manager]` Nullable cell: change `NO` → `YES` and keep the existing text noting that the INNER JOIN guarantees zero NULLs in practice.
2. Renumber Section 2.5/2.5/2.6 → 2.5/2.6/2.7 to resolve the duplicate heading.
3. Add `⚠` note to the V_Liabilities line in the Section 5 ETL diagram and a sentence in Section 1 noting that the INNER JOIN to V_Liabilities may exclude investors with no yesterday snapshot.
4. Add a Tier Legend box at the top of Section 4 (Elements): `| Stars | Tier | Tag |` matching the format used in Dim_Mirror and Dim_Manager wikis.

No re-generation needed — all issues are minor fixes suitable for an in-place edit pass.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Copyfunds_Watched_Not_Invested",
  "weighted_score": 8.95,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 9,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "FundName",
      "upstream_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index).",
      "wiki_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Here this is the username of the eToro-managed fund account (AccountTypeID=9) that the investor followed.",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "RealCID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Here this identifies the investor (the user who followed the fund).",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "UserName",
      "upstream_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index).",
      "wiki_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Here this is the investor's username.",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "FundCID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Here this is the RealCID of the eToro-managed fund account (dc2.RealCID).",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "AccountManagerID",
      "upstream_quote": "Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned.",
      "wiki_quote": "Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned. Here this is the investor's assigned account manager ID.",
      "match": "MINOR",
      "loss": null
    },
    {
      "column": "MoneyAvailable",
      "upstream_quote": "(V_Liabilities output-column table lists Credit as a T1 direct passthrough from Fact_SnapshotEquity.Credit with no description text; Fact_SnapshotEquity wiki not in bundle)",
      "wiki_quote": "Renamed from V_Liabilities.Credit — the customer available credit balance as of yesterday (DateID = @ddID). Direct passthrough from Fact_SnapshotEquity.Credit via V_Liabilities. Range: -$2,572.79 to $855,862.42 (avg $7,186.34); 32.2% of rows show zero credit.",
      "match": "MINOR",
      "loss": "No upstream description text available in bundle for Fact_SnapshotEquity.Credit; V_Liabilities wiki documents Credit only as a passthrough reference without prose description"
    },
    {
      "column": "LiquidAssetsAnswer",
      "upstream_quote": "Answer text for Q11.",
      "wiki_quote": "Answer text for Q11. Self-reported liquid assets bracket from the investor's KYC questionnaire (Q11). Values include 'Up to $10K', '$10K-$50K', '$50K-$200K', '$200K-$500k', '$500K-$1M', '$1M-$5M'. NULL if investor has no Q11 KYC response (Q11_AnswerID IS NULL in BI_DB_KYC_Panel).",
      "match": "MINOR",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "[Account Manager]",
      "problem": "DDL defines [Account Manager] as [varchar](50) NULL (nullable), but the Elements table lists Nullable = NO. The INNER JOIN to Dim_Manager guarantees zero NULLs at runtime, but the declared DDL nullability should be reflected as YES in the Elements table with a note explaining the runtime guarantee."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2",
      "problem": "Two consecutive subsections are both numbered '### 2.5': 'MoneyAvailable = Yesterday's Credit' and 'LiquidAssetsAnswer = KYC Q11 Self-Reported Bracket'. The second 2.5 should be 2.6, and the existing '2.6 #final Fan-Out Bug' should shift to 2.7."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 1 / Section 5 ETL diagram",
      "problem": "The SP uses an INNER JOIN to V_Liabilities (ON t.RealCID = vl.CID AND vl.DateID = @ddID), meaning investors with no V_Liabilities row for yesterday are silently excluded. Only the Dim_Manager INNER JOIN exclusion is flagged with a warning in Section 1 and the ETL diagram. V_Liabilities INNER JOIN exclusion is not called out with an equivalent ⚠ note."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 (Elements)",
      "problem": "The Elements section omits the canonical Tier Legend reference table (format: '| Stars | Tier | Tag |') that is present in upstream wikis like Dim_Mirror and Dim_Manager. Tier information is only in the footer."
    },
    {
      "severity": "low",
      "column_or_section": "MoneyAvailable",
      "problem": "Fact_SnapshotEquity wiki was not included in the upstream bundle, so the verbatim upstream description for Fact_SnapshotEquity.Credit (the root source of MoneyAvailable) could not be confirmed or quoted. Already flagged in review-needed sidecar #6. Not a writer failure — bundle limitation."
    }
  ],
  "regeneration_feedback": "This is a high-quality wiki requiring only minor in-place edits, not a full regeneration. Fix: (1) Change [Account Manager] Nullable from NO to YES; add sentence noting zero NULLs in practice due to INNER JOIN guarantee. (2) Renumber Section 2.5 (LiquidAssetsAnswer) to 2.6 and shift Fan-Out Bug to 2.7. (3) Add ⚠ note on V_Liabilities INNER JOIN line in Section 5 ETL diagram and add a sentence in Section 1 noting that investors without a V_Liabilities snapshot for yesterday are excluded. (4) Add Tier Legend table at the top of Section 4 matching the format in Dim_Mirror/Dim_Manager wikis.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "MoneyAvailable: 'Range: -$2,572.79 to $855,862.42 (avg $7,186.34); 32.2% of rows show zero credit'",
      "CopyEquity: 'Max observed: $82,886.67'",
      "CopyPortfolioEquity: 'Max observed: $64,842.40'"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
