# BI_DB_dbo.BI_DB_Deposits_WiresFromGooglesheets — Review Needed

## Data Quality Observations

1. **All columns are varchar(1000)** — no type safety. Numeric columns (Amount, Rate, USD amount) should be CAST for calculations. CID should be INT.
2. **Account ID is always NULL** — hardcoded in SP since 2021-02-23 due to data quality issues. Can this column be dropped?
3. **CID = '1' and Deposit ID = '1'** are placeholder values for Google Sheets null cleanup. Filter these out for analytics.
4. **Bank reference number** has leading double-quote characters ('"RTE2O1gvlv6dRp') — Google Sheets CSV formatting artifact not cleaned by SP.
5. **USD amount = '0'** for many rows — either genuinely zero or null/N/A replaced by cleanup. No way to distinguish.

## PII Assessment

This table contains HIGH PII sensitivity:
- CID (customer identifier)
- IBAN / Account number (bank account details)
- Transaction name originator/Payment recipient (real names)
- Client Bank Name + Swift Code (banking relationships)
- Full description for MEMO BO (may contain additional PII in SWIFT messages)

**Recommendation**: Restrict access via column-level security or move PII columns to a separate secure table.

## Open Questions

1. Is the Fivetran sync still hourly or has it been changed to daily? The SP runs on SB_Daily.
2. Why was the pattern changed from DELETE+INSERT (with history) to TRUNCATE+INSERT (no history) in 2021-05-19?
3. Are there downstream tables or processes that depend on this data?
