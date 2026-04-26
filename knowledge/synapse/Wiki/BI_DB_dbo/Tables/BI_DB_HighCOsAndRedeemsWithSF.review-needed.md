# Review Needed: BI_DB_dbo.BI_DB_HighCOsAndRedeemsWithSF

**Generated**: 2026-04-22 | **Batch**: 26 | **Pipeline phase**: 12 (Post-generation review sidecar)

---

## Questions for Domain Expert

1. **CashoutStatusID_Withdraw=1 meaning**: The Fact_BillingWithdraw wiki lists CashoutStatusID_Withdraw=1 as "Pending". Confirm the SP correctly targets pending (not yet processed) cashouts — the intent appears to be early-detection of large requests before processing, consistent with AML compliance workflows.

2. **Age threshold regulatory basis**: The >70 age threshold reducing the reporting threshold from $100K to $50K appears to be a regulatory or internal compliance rule. Can you confirm the regulatory basis (e.g., FCA vulnerability guidelines for elderly clients)?

3. **Threshold currency**: The $200K cashout and $100K/50K redeem thresholds — are these in USD? The Fact_BillingWithdraw.Amount_Withdraw is in CurrencyID denomination (not necessarily USD). If customers transact in non-USD currencies, the SUM is not in USD. Confirm whether multi-currency scenarios are handled or ignored.

4. **`Dim_GetSpreadedPriceCandle60MinSplitted`**: This table provides end-of-day BidLast prices for redeem valuation. Is this the authoritative source for EOD pricing in the compliance context, or is there a more appropriate price source?

5. **Table still active?**: The SP was last modified in 2021-06-11. Is this table still actively monitored by Account Managers or Compliance? Are there downstream reports, dashboards, or Salesforce workflows consuming it?

---

## Known Issues / Anomalies

| Issue | Severity | Description |
|-------|----------|-------------|
| Multi-currency threshold | Medium | Cashout amounts are in CurrencyID (not necessarily USD). A $200K threshold applied to EUR-denominated withdrawals uses EUR amounts, not USD-equivalent. The table may mix currencies in the Amount column without normalization. |
| NOLOCK on BI_DB_UsageTracking_SF | Low | Dirty reads possible; unlikely to materially affect 'yes'/'no' contact flag but could theoretically cause a false-negative in edge cases (contact record being written during ETL run). |
| Space-containing column name | Low | `[Account Manager]` requires bracket-quoting. Rename to `Account_Manager` on UC migration. |
| Type column oversized | Low | Type column is NVARCHAR(1000) but only ever contains 'Cashout' or 'Redeem' (7-6 chars). Oversized by ~140×. |

---

## UC Migration Notes

- **UC Target**: Not Migrated
- **No `.alter.sql`** — this session ran in wiki-only mode
- When UC migration is planned:
  - Rename `[Account Manager]` to `Account_Manager`
  - Consider normalizing Amount to USD using currency conversion for consistent threshold application
  - Evaluate whether `Dim_GetSpreadedPriceCandle60MinSplitted` has a Unity Catalog equivalent for redeem pricing
  - The TRUNCATE + INSERT full-reload pattern is straightforward to migrate
