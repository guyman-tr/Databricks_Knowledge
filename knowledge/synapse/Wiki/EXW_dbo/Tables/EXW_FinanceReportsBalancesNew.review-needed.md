---
object: EXW_dbo.EXW_FinanceReportsBalancesNew
type: Table
generated: 2026-04-20
phase: review-needed
---

# Review Needed — EXW_dbo.EXW_FinanceReportsBalancesNew

## Tier 4 Items (Best Guess — No Code or Wiki Evidence)

None. All 37 columns resolved to Tier 1 (upstream verbatim) or Tier 2 (SP code analysis). No Tier 4 assignments.

---

## Open Questions for Reviewers

### Q1 — ComplianceClosureEvent: Intentional Hardcode or Deferred Implementation?

**Column**: ComplianceClosureEvent (col #31)
**Observation**: The SP hardcodes `, 0 AS ComplianceClosureEvent` — the column is always 0 regardless of any user state.
**Question**: Was this column originally intended to flag users from countries with compliance-driven wallet closures (analogous to AMLClosureEvent), or is it permanently reserved? If the logic was removed, was it migrated elsewhere (e.g., AMLClosureEvent condition 4 which checks EXW_CompensationClosingCountries)?
**Risk**: Downstream consumers may filter `WHERE ComplianceClosureEvent = 1` expecting results and get none — silently wrong queries.

### Q2 — AMLClosureEvent: Conditions 2 and 3 Overlap

**Column**: AMLClosureEvent (col #32)
**Observation**: The SP contains:
- Condition 2: `SelectedValue = 0 AND TotalBalance <= 0`
- Condition 3: `SelectedValue = 0 AND TotalBalanceUSD <= 0`

`TotalBalance` appears to be the raw crypto balance; `TotalBalanceUSD` the converted value. Both conditions check zero balance but in different currencies.
**Question**: Are these intentionally distinct (e.g., crypto balance vs USD value differ when price is NULL), or is one redundant?

### Q3 — CryptoID = 158 Exclusion

**Column**: CryptoID (col #5)
**Observation**: The SP filters `AND ct.CryptoTypeId <> 158` from the CryptoTypes JOIN. No comment in the code explains which crypto this is or why it is excluded.
**Question**: What is CryptoID = 158? Is it a test asset, a delisted coin, or a system-internal asset type? Should this exclusion be documented in the Gotchas section?

### Q4 — Five Excluded Bitcoin Addresses

**Column**: PublicAddress (col #4)
**Observation**: The SP excludes 5 specific Bitcoin addresses:
- `3GqmgFc...`, `3JZ2Ekm...`, `3KjmsAn...`, `3Peo3MT...`, `3Qjmwe3...` (truncated in wiki)

Full addresses not exposed in wiki to avoid embedding operational data.
**Question**: Are these addresses still active? Were they all pre-production Beta wallets? Should they be formally listed in an internal data dictionary rather than as a hardcoded exclusion in the SP?

### Q5 — LevelId Extended Values (API Errors, InternalError)

**Column**: LevelId (col #18)
**Observation**: The upstream wiki (WalletBalancesReportDB.Wallet.FinanceReportRecords) lists values 5–12 including API errors and InternalError. The description in this wiki mentions values up to 12.
**Question**: Do any rows in the current DWH snapshot have LevelId values 5–12? If so, what is their share? The wiki lists the distribution for 1–3 only (most common). Live query would confirm whether the error codes appear in Synapse data.

### Q6 — EXW_WalletEntity Source Not Documented Upstream

**Column**: WalletEntity (col #35)
**Observation**: EXW_dbo.EXW_WalletEntity has not yet been documented in this batch. The JOIN uses `GCID + BalanceDateID` as the composite key, and the column captures the legal entity (e.g., eToro Europe Ltd, eToro USA LLC).
**Question**: What populates EXW_WalletEntity? Is it a manually maintained table or SP-populated? How far back does the data go? The wiki notes "NULL for dates before WalletEntity data was backfilled" — is there a known backfill start date?
**Status**: EXW_WalletEntity is a Pending object in this batch (Object list). Will be documented in Batch 4 or 5.

### Q7 — Price Staleness Handling

**Column**: Price_Date (col #9), Rate (col #10)
**Observation**: The SP selects the "latest available price date for CryptoID" — if no price is available on BalanceDateID, it uses the most recent prior date. The wiki notes "May differ from BalanceDate if no price is available."
**Question**: What is the maximum allowable price staleness? Is there a threshold (e.g., if last price is > 7 days old, is Rate set to NULL or is the stale price still used)? BalanceUSD computed with a stale price could be materially misleading for volatile assets.

---

## Cross-Object Consistency Notes

### Note 1 — RealCID Description

**Canonical description** (from EXW_DimUser.md, confirmed Customer.CustomerStatic origin):
> "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from DWH_dbo.Fact_SnapshotCustomer relay. (Tier 1 — Customer.CustomerStatic)"

**Status**: This wiki matches the canonical description. Passthrough relay note appended correctly. CONSISTENT.

### Note 2 — GCID Description

**Canonical description** (from _batch_context.json glossary):
> "Global Customer ID for wallet operations. Platform-internal ID for Wallet schema joins. Not equal to RealCID/CID — Wallet-layer identifier."

**Status**: This wiki describes GCID as the wallet owner identifier carried for denormalized querying without joining back to WalletDB. T1 from FinanceReportRecords — consistent with other EXW_dbo objects.

### Note 3 — IsTestAccount Source

**Canonical source**: EXW_dbo.EXW_DimUser via LEFT JOIN on GCID.
**Documented in**: EXW_DimUser.md (Done — Batch 1, #3, 8.83/10).
**Status**: IsTestAccount description in this wiki is consistent with EXW_DimUser documentation. CONSISTENT.

### Note 4 — AMLClosureEvent Logic Cross-Reference

**Documented in**: EXW_AML_Users_Report.md (Done — Batch 2, #3, 9.7/10).
**Observation**: EXW_AML_Users_Report captures AML status from a different angle — verify that AMLClosureEvent in this table aligns with the criteria documented in EXW_AML_Users_Report or that discrepancies are explained.
**Action needed**: Reviewer should compare AMLClosureEvent conditions here against EXW_AML_Users_Report filters to confirm consistent population logic.

---

## Upstream Wiki Gaps

| Column | Upstream Column | Gap |
|--------|----------------|-----|
| BalanceDateID | — | No upstream equivalent — ETL-computed |
| BalanceDate | — | No upstream equivalent — SP @d parameter |
| CryptoName | — | CryptoTypes table not in WalletBalancesReportDB wiki |
| Rate / Price_Date | — | EXW_PriceDaily not documented in upstream wikis |
| Balance | — | ETL-computed CASE; no upstream equivalent |
| BalanceUSD | — | ETL-computed; no upstream equivalent |
| RegulationID / CountryID etc. | — | Sourced from Fact_SnapshotCustomer (DWH relay, not source system) |

These are all correctly assigned Tier 2. No gaps in tier coverage.

---

## Known Limitations in This Wiki

1. **Row count and statistics** sourced from Phase 2 MCP query (2026-04-11 snapshot). These will become stale as the table grows daily.
2. **AMLClosureEvent 12.5%** statistic is point-in-time. Ratio changes as user AML status evolves.
3. **Reserved column** added 2026-04-06 — historical rows before that date will have Reserved = 0 even for XRP wallets. The wiki notes this; reviewers should verify the actual backfill date.
4. **ComplianceClosureEvent** is documented as always-0 based on SP code inspection. If the SP is ever updated to populate this column, this wiki must be regenerated.
