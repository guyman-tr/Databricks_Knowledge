---
object: EXW_dbo.EXW_ReimbursementSumTable
type: Table
generated: 2026-04-20
phase: review-needed
---

# Review Needed — EXW_dbo.EXW_ReimbursementSumTable

## Tier 4 Items (Best Guess — No Code or Wiki Evidence)

None. All 5 columns are Tier 2 (SP code analysis + MCP live data). No Tier 4 assignments.

---

## Open Questions for Reviewers

### Q1 — Downstream Consumers

**Observation**: No SSDT stored procedure in the EXW_dbo schema was found that reads from `EXW_ReimbursementSumTable`. The table appears to be the terminal output of the SP_EXW_CompensationClosingCountries pipeline.
**Question**: What BI tool or report consumes this table? Is there a Power BI dataset, an SSRS report, or an Excel sheet connected directly to this table? If the SP changes the Population string values (e.g., a typo fix), downstream reports would break silently.

### Q2 — BalanceUSD Reference Date

**Observation**: The SP computes `@d = MAX(BalanceDate) FROM EXW_dbo.EXW_FinanceReportsBalancesNew` as the reference date for both balance lookup and price lookup. BalanceUSD and [Compensated By Current USD Price] use prices from `EXW_Wallet.EXW_PriceDaily` at this same date.
**Question**: Is it intentional that the reference date is the latest balance date in EXW_FinanceReportsBalancesNew (which may lag by 1–2 days), rather than "today"? If EXW_FinanceReportsBalancesNew is stale, both BalanceUSD and [Compensated By Current USD Price] reflect stale prices. Is there a staleness check or alert before the SP runs?

### Q3 — [Compensated By Current USD Price] AML vs Non-AML Split

**Observation**: The SP computes `Compensated By Current USD Price` separately for AML projects (via `#Compaml`) and non-AML projects (via `#Comp`). For AML projects, the filter is `Project IN('AML', 'AML_US', 'AML_EEA') AND CompensationDate IS NOT NULL`. For non-AML projects, the filter is `Project NOT IN ('AML', 'AML_US', 'AML_EEA')` — with NO CompensationDate IS NOT NULL filter.
**Question**: Is it intentional that non-AML legacy projects (FrenchTerr, Germany, Russia, etc.) do not require a non-NULL CompensationDate? Legacy rows with NULL CompensationDate would be included in the non-AML compensation value. Is this a known discrepancy?

### Q4 — Segment 3: EXW_WalletClosedCountryProjects Join

**Observation**: Segment 3 ('Customer in Closed Country, Compliance Event Closure, but was not compensated') uses a JOIN to `EXW_dbo.EXW_WalletClosedCountryProjects` matching on `CountryID` and optionally `RegulationID` (`edu.RegulationID = wc.RegulationID OR wc.Regulation IS NULL`). This table has not yet been documented.
**Question**: Is `EXW_WalletClosedCountryProjects` a static reference table (manually maintained) or dynamically updated? If it's manually maintained, it could become out of date as country closure events evolve, leading to incorrect classification of segment 3 users.

### Q5 — Segments 1 and 2 Overlap with Segment 3

**Observation**: Segments 1 and 2 filter for users NOT in `EXW_CompensationClosingCountries` and with `SelectedValue IN (0,1)` (closed wallet). Segment 3 filters for users in `EXW_WalletClosedCountryProjects` NOT in `EXW_CompensationClosingCountries`. There is NO mutual exclusion between segments 1/2 and segment 3 in the SP code.
**Question**: Can the same user appear in segment 3 (closed country compliance event) AND segment 1 or 2 (AML or unknown closure) simultaneously? If so, their balance would be double-counted in the BalanceUSD total across segments. Is there known overlap between AML-limited users and compliance-event country closure users?

---

## Cross-Object Consistency Notes

### Note 1 — SP_EXW_CompensationClosingCountries as Sole Writer

The wiki documents that this table is written exclusively by `SP_EXW_CompensationClosingCountries` — the same SP that writes `EXW_CompensationClosingCountries` (Object #3) and `EXW_ReimbursementFollowUp`. This is consistent with the SP code reviewed for Object #3 documentation. CONSISTENT.

### Note 2 — #Aml_Limited UNION Uses EXW_Aml_Limited_Accounts

The wiki documents that segment 1's AML-limited population is derived from `UNION` of `EXW_Aml_Limited_Accounts` (Object #4) and the Fivetran external table. This is consistent with the SP code (lines 873–888) and with Object #4's documentation of its downstream use. CONSISTENT.

### Note 3 — EXW_FinanceReportsBalancesNew as Balance Source

The use of `EXW_FinanceReportsBalancesNew` (Object #1) as the balance reference is consistent with that object's documentation as the authoritative daily balance snapshot table. CONSISTENT.

---

## Known Limitations in This Wiki

1. **No downstream consumers documented**: The table's consumers are unknown from SSDT code alone. This is the most significant gap — if Population strings change, the impact is invisible.
2. **Platform compensation path not visible in this table**: `DWH_dbo.Fact_CustomerAction` compensation data (via `#platformdata`) feeds `EXW_ReimbursementFollowUp` but is not directly surfaced as a column in this 5-column summary table.
3. **Segment overlap not assessed**: Whether users can appear in multiple segments is not validated. The SP does not enforce mutual exclusivity.
