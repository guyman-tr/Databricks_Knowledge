# BI_DB_dbo.BI_DB_Tax_1099_PartA — Review Needed

## Tier 4 Items

None.

## Questions for Reviewer

1. **IRS Tax Code semantics**: The SP uses 14 distinct tax codes (0, 1, 6, 8, 9, 23, 27, 33, 35, 36, 37, 40, 78) from BI_DB_DailyDividendsByPosition.TaxCode. The wiki maps codes 0 (unclassified/exempt), 1 (ordinary), 6 (qualified), and 8 (section 199A) based on common IRS 1099-DIV conventions, but codes 9, 23, 27, 33, 35, 36, 37, 40, 78 need confirmation of their IRS box mapping. Are these internal codes or standard IRS income codes?

2. **PlayerStatusID mapping for BlockDate**: The SP uses `PlayerStatusID IN (2, 4, 9)` to detect blocked customers. No upstream Dim_PlayerStatus wiki exists to confirm which statuses these IDs represent. Sample data shows "Blocked", "Block Deposit & Trading", and "Blocked Upon Request" — are these the only three, or does ID 9 map to something else?

3. **TIN_Value PII handling**: The table stores US SSN/ITIN values in plain text (sample data confirms format `NNN-NN-NNNN`). Is there a data masking or access control policy that should be documented?

4. **Conditional execution window**: The 3-day window (`@Date <= DATEADD(dd,3,@LastDateUpdated)`) means the SP will stop running if not triggered within 3 days of the Fivetran sync. Is there a retry mechanism or alerting for missed windows?

5. **No upstream DWH wikis**: None of the source dimension tables (Dim_Customer, Dim_Regulation, Dim_PlayerStatus, Dim_Country, Dim_Position, Dim_Instrument, Dim_Range, Dim_Date, Fact_SnapshotCustomer, Fact_CustomerAction) have wikis in the current inventory. Tier 1 assignments for Regulation and LastLogInCountry are based on dictionary-level confidence but cannot be verified against upstream documentation.

6. **Short dividend columns**: The DDL omits `Dividends_ShortCFD` even though the SP's #dividends temp table computes it. Was this intentionally excluded from the final table?
