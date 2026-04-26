# Review Needed: BI_DB_dbo.BI_DB_Finance_Cashout_RollbackDetails

Generated: 2026-04-22 | Batch 25 #3

## Tier 4 Items (Needs SME Verification)

None — all column descriptions are Tier 2.

## Questions for Business SME

1. **`[Payment Details]` placeholder**: The SP hardcodes `'Payment Details' as [Payment Details]` — every row has the literal string "Payment Details" in this column. Was this column intended to be populated with actual payment detail data (e.g., bank account, IBAN), and if so, why was this never implemented? Is the column currently unused in reporting?

2. **`[Brand]` always empty**: The Brand column comes from Dim_CardType via BinCode lookup, which only works for card-based payments. All observed data (wire transfers and MoneyBookers) produces an empty Brand. Should wire transfers populate Brand with a static value (e.g., 'WireTransfer'), or is the empty value expected?

3. **`[Fee PIPs]` column naming**: The column is named "Fee PIPs" but contains `Fact_BillingWithdraw.ExchangeFee` — a billing exchange fee in monetary units, not a PIP count. Is the naming intentional (historical term), or should it be renamed to 'ExchangeFee'? Current data shows it as 0 for all sampled wire transfers.

4. **`[AdjustDiscrepancy]` reason**: RollbackReasonID=3 maps to 'AdjustDiscrepancy' in the SP CASE statement, but zero rows with this reason exist in the current data. Is this reason still active, or has it been deprecated in the source system?

5. **`[PreviousCS]` default value**: LAG uses default `0` (integer) — the first status event for each payment has PreviousCS = '0' (stored as varchar due to implicit conversion). Is '0' the expected sentinel for "no previous status", or should consumers treat it as NULL?

6. **BVI concentration (57%)**: The majority of rollback events are BVI-regulated customers. Is this distribution expected given the platform's BVI customer base composition, or does it indicate a data anomaly?

## Data Quality Observations

- **107 rows over 3 years**: Very low event volume (roughly 3 events/month). Confirm this is the expected scale for cashout rollbacks.
- **RollbackReason trailing spaces**: SP CASE output for reasons 1, 2, 4 includes a trailing space ('ReturnedPayment ', 'CancelRollback '). Consumers should use `LTRIM(RTRIM([RollbackReason]))` when filtering.
- **Column name typo**: `[Withdraw Processing Id Stauts]` ("Stauts" not "Status") in both DDL and SP — this is production schema; renaming would require all downstream consumers to be updated.

## Reviewer Sign-Off

- [ ] Payment Details placeholder purpose confirmed
- [ ] Brand empty behavior confirmed (expected for wire/MoneyBookers)
- [ ] Fee PIPs naming confirmed or rename requested
- [ ] AdjustDiscrepancy reason confirmed as active/deprecated
- [ ] PreviousCS default '0' sentinel confirmed
- [ ] BVI distribution confirmed as expected
