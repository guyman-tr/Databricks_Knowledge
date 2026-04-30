## Judge Review: BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Five random columns sampled: DateID (Tier 2, ETL-computed ✓), Customer (Tier 1 — Customer.CustomerStatic, dim-lookup passthrough with root origin ✓), Amount (Tier 2, ABS + sign correction ✓), RegCountry (Tier 1 — Dictionary.Country, dim-lookup passthrough with root origin ✓), IsIBANTrade (Tier 2, CASE expression ✓). All correct. No paraphrasing failures on sampled T1 columns.

**Dimension 2 — Upstream Fidelity: 7/10**
All 12 Tier 1 columns preserve core upstream meaning, but most truncate "Used in..." context and several add "Passthrough from Dim_X" annotations not in the original. Currency changes "instrument identification" to "currency identification" — a minor but real semantic shift. No vendor names dropped, no NULL semantics removed, no FK targets lost.

**Dimension 3 — Completeness: 8/10**
9 of 10 checks pass: all 8 sections present ✓, 45/45 elements ✓, 5-cell rows ✓, tier tags on all descriptions ✓, property table complete ✓, ETL pipeline diagram ✓, footer tier breakdown ✓, Section 1 row count + date range ✓, review-needed sidecar clean ✓. Minor: footer claims "11 T1" but actual count is 12.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the reversal domain, row grain (DepositWithdrawID + TransactionID per DateID), ETL SP (SP_DepositWithdrawFee), refresh pattern (daily DELETE/INSERT), row count (~19,762), date range (20230103-20260424), TransactionType distribution with actual counts and percentages. Missing only explicit SLA or downstream consumer names.

**Dimension 5 — Data Evidence: 7/10**
Row count (~19,762) and date range present. TransactionType distribution has specific counts (Refund: 1,946, Chargeback: 796, etc.). NULL columns documented as intentionally NULL with SR references. No formal Phase Gate Checklist section, but footer indicates 11/14 phases completed and data specificity suggests live queries were run.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1-8 ✓, tier legend in Section 4 ✓, three real SQL samples in Section 7 ✓, footer with quality score and phase count ✓. Minor: footer quality score format differs slightly from golden reference (no explicit phases-completed list by name).

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|-----------|-------|------|
| Customer | "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format." | "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. CAST to VARCHAR(50) from Dim_Customer.ExternalID." | MINOR | Added transform context, core preserved |
| PaymentMethod | "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay)." | "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Passthrough from Dim_FundingType." | YES | Added passthrough note only |
| Currency | "Ticker symbol. …Use this for human-readable instrument identification." | "Ticker symbol (e.g., USD, EUR, GBP). Use this for human-readable currency identification." | MINOR | Changed "instrument" to "currency"; dropped stock/crypto examples |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards." | "Short code for the regulation. Passthrough from Dim_Regulation." | MINOR | Dropped usage context |
| Label | "Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name." | "Brand name displayed in BackOffice interfaces, reports, and internal systems. Passthrough from Dim_Label." | MINOR | Dropped multi-ID note |
| Depot | "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports." | "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Used in admin dashboards, routing logs, and discrepancy reports. Passthrough from Dim_BillingDepot." | MINOR | Dropped "Unique across all depots" |
| Club | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI." | "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Passthrough from Dim_PlayerLevel." | MINOR | Dropped usage context |
| PlayerStatus | "Human-readable restriction state label. Unique per status. Used in BackOffice UI…Note: some values have trailing spaces in live data." | "Human-readable restriction state label (e.g., Normal, Blocked, Trade & MIMO Blocked). Passthrough from Dim_PlayerStatus." | MINOR | Dropped trailing spaces note and uniqueness note; added examples |
| RegCountry | "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports." | "Full country name in English for the customer's registration country. Passthrough from Dim_Country…" | MINOR | Dropped uniqueness and usage notes; added context |
| RegCountryByIP | (same upstream as RegCountry) | "Full country name in English for the customer's IP-detected country. Passthrough from Dim_Country via Dim_Customer.CountryIDByIP." | MINOR | Same pattern |
| BinCountry | (same upstream as RegCountry) | "Full country name in English for the country associated with the card BIN code. Passthrough from Dim_Country…" | MINOR | Same pattern |
| GuruStatus | "Human-readable PI tier name. Values: No, Certified, Cadet…Used in BackOffice customer views, Trade procedures, and SalesForce integration." | "Human-readable PI tier name: No, Certified, Cadet…Passthrough from Dim_GuruStatus." | MINOR | Dropped usage context |

---

### Top 5 Issues

1. **Footer T1 count mismatch** (severity: low, section: Footer) — Footer says "11 T1" but the Elements table contains 12 Tier 1 columns (Customer, PaymentMethod, Currency, Regulation, Label, Depot, Club, PlayerStatus, RegCountry, RegCountryByIP, BinCountry, GuruStatus).

2. **Currency description paraphrased** (severity: medium, column: Currency) — Changed "human-readable instrument identification" to "human-readable currency identification" and dropped stock/crypto ticker examples. While contextually reasonable for a finance table, the upstream text was not preserved verbatim.

3. **Systematic truncation of T1 usage context** (severity: low, columns: Regulation, Label, Club, PlayerStatus, GuruStatus, Depot) — All T1 dim-lookup columns consistently drop "Used in..." clauses from upstream descriptions. While no semantic data is lost, the pattern indicates a systematic rather than targeted edit.

4. **Fact-passthrough columns tagged Tier 2 when upstream wikis exist** (severity: low, columns: DepositID, WithdrawPaymentID, CreditID) — These columns are straight passthroughs from fact tables that have upstream wikis in the bundle. Per strict tier rules, passthroughs with available upstream wikis should be Tier 1. However, the descriptions are written for this table's context (conditional population), so Tier 2 is a defensible judgment call.

5. **No formal Phase Gate Checklist section** (severity: low, section: overall) — The wiki lacks an explicit checklist showing which data validation phases were completed. The footer says "Phases: 11/14" but doesn't enumerate which phases or confirm P2/P3.

---

### Regeneration Feedback

Not required — the wiki passes. For a future polish pass:
1. Fix the footer T1 count from 11 to 12.
2. Restore "instrument identification" in Currency description to match upstream verbatim.
3. Consider restoring "Unique per status" and trailing-spaces note on PlayerStatus from upstream.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_DepositWithdrawFee_Reversals",
  "weighted_score": 8.45,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "Customer",
      "upstream_quote": "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format.",
      "wiki_quote": "APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. CAST to VARCHAR(50) from Dim_Customer.ExternalID.",
      "match": "MINOR",
      "loss": "Added transform context (CAST to VARCHAR), core description preserved verbatim"
    },
    {
      "column": "PaymentMethod",
      "upstream_quote": "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay).",
      "wiki_quote": "Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Passthrough from Dim_FundingType.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Currency",
      "upstream_quote": "Ticker symbol. 'USD', 'EUR' for forex; 'AAPL.US', 'TSLA.US' for US stocks (format: TICKER.EXCHANGE); 'BTC' for crypto. Unique across all instruments. Use this for human-readable instrument identification.",
      "wiki_quote": "Ticker symbol (e.g., USD, EUR, GBP). Use this for human-readable currency identification. Passthrough from Dim_Currency.",
      "match": "MINOR",
      "loss": "Changed 'instrument identification' to 'currency identification'; dropped stock/crypto ticker examples and 'Unique across all instruments'"
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the regulation. Passthrough from Dim_Regulation.",
      "match": "MINOR",
      "loss": "Dropped 'Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.'"
    },
    {
      "column": "Label",
      "upstream_quote": "Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro').",
      "wiki_quote": "Brand name displayed in BackOffice interfaces, reports, and internal systems. Passthrough from Dim_Label.",
      "match": "MINOR",
      "loss": "Dropped 'Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = eToro)'"
    },
    {
      "column": "Depot",
      "upstream_quote": "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports.",
      "wiki_quote": "Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Used in admin dashboards, routing logs, and discrepancy reports. Passthrough from Dim_BillingDepot.",
      "match": "MINOR",
      "loss": "Dropped 'Unique across all depots'"
    },
    {
      "column": "Club",
      "upstream_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI.",
      "wiki_quote": "Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Passthrough from Dim_PlayerLevel.",
      "match": "MINOR",
      "loss": "Dropped 'Used in BackOffice reporting JOINs and customer-facing UI'"
    },
    {
      "column": "PlayerStatus",
      "upstream_quote": "Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons.",
      "wiki_quote": "Human-readable restriction state label (e.g., Normal, Blocked, Trade & MIMO Blocked). Passthrough from Dim_PlayerStatus.",
      "match": "MINOR",
      "loss": "Dropped uniqueness note, usage context, and trailing spaces warning; added inline examples"
    },
    {
      "column": "RegCountry",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English for the customer's registration country. Passthrough from Dim_Country via snapshot CountryID (withdraw) or Dim_Customer.CountryID (deposit).",
      "match": "MINOR",
      "loss": "Dropped 'Unique per row' and usage context; added path-specific provenance"
    },
    {
      "column": "RegCountryByIP",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English for the customer's IP-detected country. Passthrough from Dim_Country via Dim_Customer.CountryIDByIP.",
      "match": "MINOR",
      "loss": "Dropped uniqueness and usage notes; added IP-specific context"
    },
    {
      "column": "BinCountry",
      "upstream_quote": "Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports.",
      "wiki_quote": "Full country name in English for the country associated with the card BIN code. Passthrough from Dim_Country via BinCountryIDAsInteger from Fact_BillingDeposit (deposit) or Fact_BillingWithdraw (withdraw).",
      "match": "MINOR",
      "loss": "Dropped uniqueness and usage notes; added BIN-specific context"
    },
    {
      "column": "GuruStatus",
      "upstream_quote": "Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration.",
      "wiki_quote": "Human-readable PI tier name: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Passthrough from Dim_GuruStatus.",
      "match": "MINOR",
      "loss": "Dropped 'Used in BackOffice customer views, Trade procedures, and SalesForce integration'"
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer claims '11 T1' but Elements table contains 12 Tier 1 columns. Off-by-one count error."
    },
    {
      "severity": "medium",
      "column_or_section": "Currency",
      "problem": "Description changes upstream 'human-readable instrument identification' to 'human-readable currency identification' and drops stock/crypto ticker examples. Minor semantic shift from upstream verbatim text."
    },
    {
      "severity": "low",
      "column_or_section": "Regulation, Label, Club, PlayerStatus, GuruStatus, Depot",
      "problem": "All T1 dim-lookup columns systematically truncate 'Used in...' and 'Unique per...' clauses from upstream descriptions. Pattern indicates bulk edit rather than selective curation."
    },
    {
      "severity": "low",
      "column_or_section": "DepositID, WithdrawPaymentID, CreditID",
      "problem": "Fact-passthrough columns tagged Tier 2 when upstream wikis (Fact_BillingWithdraw, Fact_Deposit_State) exist in the bundle. Strict tier rules would classify these as Tier 1, though the conditional population logic makes Tier 2 a defensible choice."
    },
    {
      "severity": "low",
      "column_or_section": "Overall",
      "problem": "No formal Phase Gate Checklist section. Footer says 'Phases: 11/14' but does not enumerate which phases were completed or confirm P2/P3 data validation."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
