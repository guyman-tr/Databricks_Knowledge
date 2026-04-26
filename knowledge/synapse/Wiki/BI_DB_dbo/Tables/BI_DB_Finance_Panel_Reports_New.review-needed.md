# Review Needed: BI_DB_dbo.BI_DB_Finance_Panel_Reports_New

**Generated**: 2026-04-22 | **Batch**: 26 | **Pipeline phase**: 12 (Post-generation review sidecar)

---

## Tier 4 / Ghost Items Requiring Expert Confirmation

| Column | Issue | Action Needed |
|--------|-------|---------------|
| `Notional_Value_GBP` | **Ghost column** — present in DDL but NOT in SP INSERT list. Always NULL. DDL type is NVARCHAR(256) with description "Notional Value GBP". SP never populates it. | Confirm whether this column was intentionally abandoned or if a future SP version is expected to populate it. Safe to mark deprecated if confirmed. |
| `Position_Quantity` | Hardcoded literal `1` in all three UNION ALL branches — no analytical derivation. Every row always has `Position_Quantity = 1`. | Confirm this column provides no analytical value beyond counting rows. If never used downstream, consider removal from UC target. |
| `Is_Stamp_Duty` | Always `1` in this table — the SP filters `WHERE Is_Stamp_Duty = 1` before INSERT. The column is logically redundant (all rows are stamp-duty-eligible by construction). | Confirm whether this column is retained for schema parity with a broader positions table or serves a downstream use. |

---

## Questions for Domain Expert

1. **HedgeServerID values**: The SP filters `HedgeServerID IN (121, 124, 125, 126, 128, 130)`. What are the business names/venues for each of these 6 hedge servers? HedgeServerID=126 has special treatment (1% stamp duty pre-2021-01-18 vs 0.5% for all others). This context is missing from the DWH_dbo.Dim_HedgeServer wiki.

2. **Predecessor table**: `BI_DB_Finance_Panel_Reports` (without the `_New` suffix) appears to be an older version of this table. Is it still active? Has it been fully superseded by this table? Should both be documented?

3. **Change_CFD_To_Real branch deduplication**: The `Change_CFD_To_Real` UNION branch self-JOINs back to `BI_DB_Finance_Panel_Reports_New` to exclude positions already present from the Open/Close branches (`WHERE fpr.PositionID IS NULL`). This means the third branch is order-dependent — it must run after Open and Close have been inserted in prior days. Is this by design, and is there a risk of over-deduplication on same-day re-runs?

4. **`IsCreditReportValidCB = 1` filter**: This filter (via `Fact_SnapshotCustomer + Dim_Range`) excludes customers without valid credit bureau checks. Confirm this is an HMRC/FCA regulatory requirement, not an internal data-quality filter.

5. **`IsPartialCloseChild ≠ 1` scope**: The partial-close child exclusion applies only to the `Open_Position` branch. Partial-close child positions ARE included in `Close_Position`. Confirm this asymmetry is intentional.

---

## Known Issues / Anomalies

| Issue | Severity | Description |
|-------|----------|-------------|
| SP alias typo | Low | SP uses `ParialNULLS_Amount_OnOpen_USD`, `ParialNULLS_Amount_OnOpen_GBP`, `ParialZero_Amount_OnOpen_USD`, `ParialZero_Amount_OnOpen_GBP` (missing one `l` in `Partial`). The INSERT column list uses the correct DDL names (`PartialNULLS_*`, `PartialZero_*`), so data integrity is maintained. The alias typo is cosmetic only. |
| Stamp duty abolished on close | Medium | As of 2021-01-18, `Total_Stamp_Duty` for the `Close_Position` branch returns 0 for HedgeServerID=126 and NULL for all others. This was a regulatory change (HMRC abolished SDRT on closing transactions). The wiki documents this but it may surprise users expecting non-zero values. |
| Currency conversion precision | Low | GBP/USD and EUR/USD prices come from `Fact_CurrencyPriceWithSplit` for InstrumentID IN (1, 2, 666). Confirm these InstrumentIDs reliably represent EUR/USD and GBP/USD pairs (ID assignments are implicit, not named). |
| `EOW` Saturday formula | Low | End-of-week is computed as `DATEADD(day, 7 - DATEPART(weekday, ...), ...)` (next Saturday). Verify this handles year-end weeks and holidays correctly in downstream reports. |

---

## UC Migration Notes

- **UC Target**: Not Migrated
- **No `.alter.sql`** — this session ran in wiki-only mode; no Unity Catalog target was generated
- When UC migration is planned: `Notional_Value_GBP` should be excluded or confirmed as a deliberate NULL column
- Consider whether `Position_Quantity` (always 1) and `Is_Stamp_Duty` (always 1) should be materialized or dropped in the UC target
- The self-JOIN deduplication for `Change_CFD_To_Real` will need redesign for UC (no mutable Synapse table to JOIN against during INSERT)
