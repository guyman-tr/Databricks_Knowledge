# BI_DB_dbo.BI_DB_Employee_Crypto_NWA — Review Needed

## Tier 4 Items
None — all columns traced to SP code.

## Reviewer Questions

1. **RealCID 149 hardcoded**: Why is CID 149 always included regardless of employee/analyst filters? Is this a test account, founder account, or special-purpose account?

2. **NWA meaning**: "Net Wallet Amount" is inferred from the table name. Confirm this is the correct expansion and business context.

3. **No downstream consumers**: No SPs or views reference this table in the SSDT repo. Is this consumed by external reports (e.g., Excel, regulatory filings)?

4. **Rate = MAX**: Using MAX(EOD_Bid_Price) — is this correct, or should it be a closing price? Multiple bid prices per instrument per date seems unusual.

## Data Quality Notes
- 3,006 rows total, 185 distinct crypto instruments, 27 EOM dates (Jan 2024–Mar 2026)
- ~111 instruments per month-end date
- Very small table — entire dataset fits in memory
