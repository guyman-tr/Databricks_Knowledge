# Compare — `EXW_dbo.EXW_ReportingBalances`

**Bucket**: `dormant`

**Verdict**: **EQUIVALENT**  (score delta +0.2; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.8 | 8.0 | 0.2 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 40 | 40 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 0 | 0 | +0 |
| T3 count | 0 | 40 | +40 |
| T4 count | 40 | 0 | -40 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 8 | 8 |
| completeness | 8 | 8 |
| data_evidence | 3 | 4 |
| shape_fidelity | 8 | 9 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `29` | 0.229 | 4 | 3 | Balance from a third-party tracking provider (likely BitGo or Blox, same as EXW_FinanceReportsBalancesNew). Used for independent cross-validation. (Tier 4 — External ETL) | Independent tracker system's crypto unit balance for this wallet. Used as a reference for reconciliation against the reported balance. (Tier 3 — DDL, no upstream) |
| `20` | 0.314 | 4 | 3 | Customer's regulatory jurisdiction (CySEC, FCA, FinCEN, ASIC & GAML, BVI, eToroUS, etc.). Determines which regulator this balance is reported to. (Tier 4 — External ETL) | Regulatory entity or framework under which the customer operates (e.g., FCA, CySEC, ASIC). (Tier 3 — DDL, no upstream) |
| `8` | 0.344 | 4 | 3 | The exact date-time of the prior month's closing snapshot. Connects this month's opening to the previous month's record. (Tier 4 — External ETL) | Date of the previous month's closing balance snapshot. Used to verify continuity between reporting periods. (Tier 3 — DDL, no upstream) |
| `38` | 0.344 | 4 | 3 | Crypto units held in staking during the reporting month. NULL when staking not applicable for this crypto/customer. (Tier 4 — External ETL) | Crypto units currently staked by the customer. High precision (18 decimals) to accommodate fractional staking amounts. (Tier 3 — DDL, no upstream) |
| `32` | 0.346 | 4 | 3 | Numeric difference: [TrackerBalance] minus [Closing Units Balance]. Positive = tracker shows more than ledger. (Tier 4 — External ETL) | Numeric difference between the reported crypto unit balance and the tracker balance. Non-zero when Has Dif with TrackerBalance = 'Y'. (Tier 3 — DDL, no upstream) |
| `21` | 0.353 | 4 | 3 | Internal accounting classification flag (0=production, non-zero=test accounting category). Used to exclude test accounts from regulatory submissions. (Tier 4 — External ETL) | Classifier flag used to identify test or internal accounting entries. Non-NULL values likely indicate test accounts. (Tier 3 — DDL, no upstream) |
| `39` | 0.372 | 4 | 3 | [Staking Units] converted to USD. NULL when staking not applicable. (Tier 4 — External ETL) | USD value of the staked crypto units. (Tier 3 — DDL, no upstream) |
| `25` | 0.383 | 4 | 3 | Actual change in balance over the month: [Closing Units Balance] - [Opening Balance...]. May differ from [MTD Units Total] due to staking or corrections. (Tier 4 — External ETL) | Month-to-date change in crypto unit balance, accounting for both unit flows and value adjustments. (Tier 3 — DDL, no upstream) |
| `40` | 0.383 | 4 | 3 | ETL load timestamp for this row. NULL in this schema (vs NOT NULL in EXW_EOMReportingBalances). (Tier 4 — External ETL) | Timestamp of the last update to this row. (Tier 3 — DDL, no upstream) |
| `1` | 0.385 | 4 | 3 | The month-end reporting date (always the last day of the reporting month, e.g., 2023-09-30). CLUSTERED INDEX key. NOT NULL — the primary partition key. (Tier 4 — External ETL) | Reporting period date for the balance snapshot. Used as the clustered index — each row represents one month's data for a customer-wallet-cryptoasset combination. (Tier 3 — DDL, no upstream) |

## Top issues — regen wiki (per judge)

- [medium] `KnownIssueWallet, Has Dif with TrackerBalance, Closed Country AND Regulation, User was Compensated during Country Closure, MTD Balance Change -MTD Units Total Flag` — Flag columns with small domains have no formal key=value inline enumeration. Writer uses 'likely Y/N' in prose but doesn't formalize as dictionary entries.
- [low] `Section 2.2 (Unit Flow Tracking)` — Business logic rule 'MTD Units Total = MTD Units Sent + MTD Units Recieved' is presented as a rule but is pure inference from column names — no SP or data to confirm. Should be hedged.
- [low] `Section 7 (Sample Queries)` — All three sample queries target a 0-row table and are untestable. Syntactically correct but no way to verify semantic correctness.
- [low] `Footer / Phase Gate` — No explicit Phase Gate Checklist section with [x]/[ ] checkboxes. Phases only summarized as '11/14' in footer line.
- [low] `Section 6 (Relationships)` — Relationships to customer dimension and EXW_EOMReportingBalances are speculative — no FK constraints or SP joins to confirm. Appropriately hedged but still unverified.
