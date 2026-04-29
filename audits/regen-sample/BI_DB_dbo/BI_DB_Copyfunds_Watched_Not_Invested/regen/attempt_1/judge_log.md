## Human Summary

### Per-Dimension Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Tier Accuracy (25%) | 8 | 0/5 tier mismatches. Deducted 2 for MoneyAvailable paraphrasing failure ("Answer text for Q11" prefix is semantic corruption of a credit-balance column). |
| Upstream Fidelity (20%) | 5 | FundName, RealCID, UserName, FundCID, AccountManagerID all MINOR (verbatim core + context annotation). MoneyAvailable is a clear NO — description starts with "Answer text for Q11" which is factually wrong for a V_Liabilities.Credit rename. LiquidAssetsAnswer is YES. |
| Completeness (20%) | 8 | Section 5 references the lineage file for the ASCII pipeline diagram instead of embedding it inline (rubric requires diagram in wiki). Footer tier count wrong (wiki claims 6T1/8T2; actual count from Elements is 7T1/7T2). All other checks pass. |
| Business Meaning (15%) | 8 | Specific, concrete — names domain, row grain, SP, caveats the commented-out filter, includes row counts. Slightly docked because the INNER JOIN to Dim_Manager filtering effect isn't mentioned in Section 1 (only managers with assigned customers appear). |
| Data Evidence (10%) | 7 | Row count, investor/fund counts, LiquidAssetsAnswer distribution with percentages all appear live-data-backed. Review-needed sidecar references specific CIDs. No explicit Phase Gate Checklist in the wiki, but evidence is convincing. |
| Shape Fidelity (10%) | 7 | Numbered sections ✓, SQL samples with real names ✓. Missing: tier legend block in Section 4 header, quality score and phases-completed list in footer. |

**Weighted score: 0.25×8 + 0.20×5 + 0.20×8 + 0.15×8 + 0.10×7 + 0.10×7 = 7.2 → FAIL**

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| FundName | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic)" | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Here this is the username of the eToro-managed fund account (AccountTypeID=9) that the investor followed." | MINOR | Context annotation added; verbatim core preserved |
| RealCID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic)" | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Here this identifies the investor (the user who followed the fund)." | MINOR | Context annotation added; verbatim core preserved |
| UserName | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic)" | "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Here this is the investor's username." | MINOR | Context annotation added; verbatim core preserved |
| FundCID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic)" | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Here this is the RealCID of the eToro-managed fund account (dc2.RealCID)." | MINOR | Context annotation added; verbatim core preserved |
| AccountManagerID | "Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned. (Tier 1 — BackOffice.Customer)" | "Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned. Here this is the investor's assigned account manager ID." | MINOR | Context annotation added; verbatim core preserved |
| MoneyAvailable | "Credit — Fact_SnapshotEquity.Credit — Direct — T1" (V_Liabilities col 12) | "Answer text for Q11. Renamed from V_Liabilities.Credit — the investor's available credit balance as of yesterday. Max observed: $855,862.42." | NO | Prefix "Answer text for Q11" is factually wrong — MoneyAvailable is a credit balance, not a KYC answer. Semantic corruption from copy-paste of LiquidAssetsAnswer description. |
| LiquidAssetsAnswer | "Answer text for Q11." (BI_DB_KYC_Panel col 28) | "Answer text for Q11. Self-reported liquid assets bracket from the investor's KYC questionnaire (Q11). Values include 'Up to $10K', '$10K-$50K', '$50K-$200K', '$200K-$500k', '$500K-$1M', '$1M-$5M'. NULL if investor has no Q11 KYC response." | YES | Verbatim base preserved; significantly expanded with domain values and NULL semantics |

---

### Top 5 Issues

1. **[HIGH] MoneyAvailable — description opens with wrong domain text**: The description in the Elements table begins "Answer text for Q11." — a copy-paste artifact from the LiquidAssetsAnswer description. MoneyAvailable is `V_Liabilities.Credit`, a credit balance. Any analyst reading col 12 before col 13 will be misled about the column's domain.

2. **[HIGH] [Account Manager] — INNER JOIN to Dim_Manager silently drops customers with NULL AccountManagerID**: The SP uses `join DWH_dbo.Dim_Manager dm on dm.ManagerID = tud.AccountManagerID` (INNER JOIN, not LEFT JOIN). Since `NULL = NULL` is false in SQL, customers with no assigned manager (AccountManagerID IS NULL per Dim_Customer) are excluded from the table entirely. The wiki claims "[Account Manager]: NULL if no manager is assigned" — this is incorrect. Rows without a manager are missing, not NULL.

3. **[MEDIUM] #final fan-out bug undocumented in Section 2**: The SP groups `#temp` by `(RealCID, UserName, AccountManagerID, FundCID, FundName)` but only stores `RealCID` in the physical table. The subsequent join in `#final` is `JOIN #transformuserdata tud ON t.RealCID = tud.RealCID` (no FundCID predicate). For an investor watching N funds, this produces N×N rows — confirmed by the review-needed duplicate CID=54019 observation. Section 2 Business Logic does not document this mechanism; it only appears buried in the review-needed sidecar.

4. **[MEDIUM] Section 5 missing inline ETL pipeline ASCII diagram**: The wiki says "See `BI_DB_Copyfunds_Watched_Not_Invested.lineage.md` for full column lineage and ETL pipeline diagram" — the diagram exists in the lineage file but is not embedded in the wiki. Per rubric, the pipeline diagram with real object names must appear in the wiki's Section 5.

5. **[LOW] Footer tier count wrong**: Footer claims "6 T1, 8 T2" but the Elements table contains 7 T1 columns (FundName, RealCID, UserName, FundCID, AccountManagerID, MoneyAvailable, LiquidAssetsAnswer) and 7 T2 columns. The count is off by one in each direction (one T1 was tallied as T2).

---

### Regeneration Feedback

1. **Fix MoneyAvailable description**: Remove the erroneous "Answer text for Q11." prefix. Replace the full description with: "Renamed from `V_Liabilities.Credit` — the customer's available credit balance as of yesterday (DateID = @ddID). Direct passthrough from `Fact_SnapshotEquity.Credit` via `V_Liabilities`. Max observed: $855,862.42. NULL when CID has no V_Liabilities row for yesterday. (Tier 1 — Fact_SnapshotEquity via V_Liabilities)"
2. **Fix [Account Manager] NULL semantics**: Change "NULL if no manager is assigned" to "Customers with NULL or unmatched AccountManagerID are excluded from this table entirely (INNER JOIN to Dim_Manager — not a LEFT JOIN). All rows in this table have a non-NULL [Account Manager]."
3. **Document #final fan-out in Section 2**: Add a Business Logic subsection (2.x) explaining that the join `#temp JOIN #transformuserdata ON RealCID` (without FundCID) causes one copy of mirror stats per (investor × fund) pair, and that this is the root cause of duplicate (RealCID, FundName) rows for investors with >1 fund watchlist entry.
4. **Embed ETL pipeline diagram inline in Section 5**: Copy the ASCII diagram from the lineage file into the wiki's Section 5.2. Do not merely reference the lineage file.
5. **Fix footer tier count**: Change "6 T1, 8 T2" to "7 T1, 7 T2" to match the actual Elements table.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Copyfunds_Watched_Not_Invested",
  "weighted_score": 7.2,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 8,
    "upstream_fidelity": 5,
    "completeness": 8,
    "business_meaning": 8,
    "data_evidence": 7,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [
    {
      "column": "FundName",
      "upstream_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic)",
      "wiki_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Here this is the username of the eToro-managed fund account (AccountTypeID=9) that the investor followed.",
      "match": "MINOR",
      "loss": "Context annotation appended; verbatim core fully preserved"
    },
    {
      "column": "RealCID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic)",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Here this identifies the investor (the user who followed the fund).",
      "match": "MINOR",
      "loss": "Context annotation appended; verbatim core fully preserved"
    },
    {
      "column": "UserName",
      "upstream_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic)",
      "wiki_quote": "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Here this is the investor's username.",
      "match": "MINOR",
      "loss": "Context annotation appended; verbatim core fully preserved"
    },
    {
      "column": "FundCID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic)",
      "wiki_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Here this is the RealCID of the eToro-managed fund account (dc2.RealCID).",
      "match": "MINOR",
      "loss": "Context annotation appended; verbatim core fully preserved"
    },
    {
      "column": "AccountManagerID",
      "upstream_quote": "Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned. (Tier 1 — BackOffice.Customer)",
      "wiki_quote": "Currently assigned BackOffice sales/service agent (renamed from ManagerID). FK to BackOffice.Manager. NULL = unassigned. Here this is the investor's assigned account manager ID.",
      "match": "MINOR",
      "loss": "Context annotation appended; verbatim core fully preserved"
    },
    {
      "column": "MoneyAvailable",
      "upstream_quote": "Credit | Fact_SnapshotEquity.Credit | Direct | T1 (V_Liabilities col 12)",
      "wiki_quote": "Answer text for Q11. Renamed from V_Liabilities.Credit — the investor's available credit balance as of yesterday. Max observed: $855,862.42. Used by account managers to identify investable capacity.",
      "match": "NO",
      "loss": "Description opens with 'Answer text for Q11' — factually wrong domain (MoneyAvailable is a credit balance, not a KYC answer). Copy-paste artifact from LiquidAssetsAnswer description. Semantic corruption in the first sentence misleads any reader scanning the Elements table."
    },
    {
      "column": "LiquidAssetsAnswer",
      "upstream_quote": "Answer text for Q11. (BI_DB_KYC_Panel col 28)",
      "wiki_quote": "Answer text for Q11. Self-reported liquid assets bracket from the investor's KYC questionnaire (Q11). Values include 'Up to $10K', '$10K-$50K', '$50K-$200K', '$200K-$500k', '$500K-$1M', '$1M-$5M'. NULL if investor has no Q11 KYC response (Q11_AnswerID IS NULL in BI_DB_KYC_Panel).",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "MoneyAvailable",
      "problem": "Element description begins 'Answer text for Q11.' — a copy-paste artifact from LiquidAssetsAnswer. MoneyAvailable is V_Liabilities.Credit (a credit balance), not a KYC question answer. The correct information follows the bad prefix but the opening sentence is factually wrong and will mislead any reader scanning column 12."
    },
    {
      "severity": "high",
      "column_or_section": "[Account Manager]",
      "problem": "Wiki states '[Account Manager]: NULL if no manager is assigned.' This is incorrect. The SP uses an INNER JOIN to Dim_Manager (`join DWH_dbo.Dim_Manager dm on dm.ManagerID = tud.AccountManagerID`), not a LEFT JOIN. Customers with NULL AccountManagerID fail the INNER JOIN predicate (NULL = NULL is false in SQL) and are excluded from the table entirely. The [Account Manager] column is never NULL in practice — rows without a manager are missing, not NULL-populated."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 2 / Business Logic",
      "problem": "#final fan-out bug not documented in Section 2. The SP groups #temp by (RealCID, UserName, AccountManagerID, FundCID, FundName) but does not carry FundCID into the physical #temp table. The subsequent join in #final is `JOIN #transformuserdata tud ON t.RealCID = tud.RealCID` without a FundCID predicate, causing N×N row fan-out for investors watching N funds. This is the root cause of the duplicate (RealCID=54019 × FundName='StanleyDruck13F') rows noted in the review-needed sidecar. Section 2 does not document this mechanism."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 5",
      "problem": "ETL pipeline ASCII diagram is not embedded inline in the wiki's Section 5. The wiki defers to the lineage file ('See BI_DB_Copyfunds_Watched_Not_Invested.lineage.md for full column lineage and ETL pipeline diagram'). The rubric requires the diagram with real object names in the wiki itself."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer tier count claims '6 T1, 8 T2' but the Elements table contains 7 T1 columns (FundName, RealCID, UserName, FundCID, AccountManagerID, MoneyAvailable, LiquidAssetsAnswer) and 7 T2 columns. Off by one in both directions. Footer also missing quality score and phases-completed list required by the golden reference shape."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix MoneyAvailable Element description — remove the erroneous 'Answer text for Q11.' prefix; correct opening should be 'Renamed from V_Liabilities.Credit — the customer available credit balance as of yesterday (DateID = @ddID). Direct passthrough from Fact_SnapshotEquity.Credit via V_Liabilities.' (2) Fix [Account Manager] NULL semantics — the SP uses INNER JOIN to Dim_Manager, so customers with NULL or unmatched AccountManagerID are excluded entirely, not NULL-populated; document this filtering effect. (3) Add Section 2 subsection documenting the #final fan-out mechanism: because #temp groups by FundCID but does not SELECT it, the JOIN back to #transformuserdata on RealCID alone produces N×N rows for investors watching N funds; this is the root cause of duplicate (RealCID, FundName) pairs. (4) Embed the ETL pipeline ASCII diagram inline in Section 5 of the wiki — do not merely reference the lineage file. (5) Correct footer tier count from '6 T1, 8 T2' to '7 T1, 7 T2' and add quality score and phases-completed list to footer.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "CopyEquity: 'Max observed: $82,886.67'",
      "CopyPortfolioEquity: 'Max observed: $64,842.40'",
      "MoneyAvailable: 'Max observed: $855,862.42'",
      "LiquidAssetsAnswer: bracket distribution percentages in Section 2"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
