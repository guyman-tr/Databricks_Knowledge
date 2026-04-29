# Review Sidecar — BI_DB_dbo.BI_DB_Tax_1099_PartB

## Auto-Generated Verification

| Check | Status | Notes |
|-------|--------|-------|
| Column count matches DDL | OK | 19 columns in DDL, 19 in wiki |
| All columns have tier suffix | OK | 18 Tier 2 + 1 Tier 5 |
| Writer SP confirmed | OK | SP_Tax_1099_PartB matches DDL schema |
| Sample data reviewed | EMPTY | Table has 0 rows (annual cycle — only populated during tax season) |

## Items for Human Review

| # | Column / Section | Confidence | Question |
|---|-----------------|------------|----------|
| 1 | TIN_Value deduplication | Medium | The SP uses ROW_NUMBER partitioned by CID ordered by TIN_CountryID but only filters CountryID=219. If a customer has multiple FieldId=6 entries for CountryID=219, which one wins? The ROW_NUMBER is applied but no WHERE rn=1 filter is visible in the final SELECT. Confirm dedup logic. |
| 2 | #Users1099 usage | Medium | The #Users1099 temp table is created with PlayerStatus and FTD columns but only RealCID is used downstream (in #regulation_EOY). Confirm if PlayerStatus/FTD filtering was removed or is intentionally unused. |
| 3 | Gross_Proceed formula | High | Gross_Proceed = Amount + NetProfit. Confirm this aligns with IRS 1099-B Box 1d definition (should be total proceeds from sale, not cost + profit — though mathematically equivalent if Amount = cost basis and NetProfit = proceeds minus cost). |
| 4 | Execution guard timing | Medium | The guard requires @Date > @lastDayOfYear AND @Date >= DATEADD(dd,1,@LastDateUpdated) AND @Date <= DATEADD(dd,3,@LastDateUpdated). This creates a narrow 3-day window. If the pipeline misses this window, the table stays empty. Is there a manual override process? |
| 5 | No upstream DWH wikis | Low | No wiki documentation exists for Dim_Customer, Dim_Regulation, Dim_Position, Dim_Instrument, or Fact_SnapshotCustomer. All column descriptions are Tier 2 (SP-derived). When DWH wikis are created, descriptions should be upgraded to Tier 1 with verbatim inheritance. |
| 6 | ISINCode filtering logic | Medium | The WHERE clause uses `SUBSTRING(di1.ISINCode, 1, 2)='US' OR ISINCountryCode='US'` as an alternative to the exchange filter. The ISINCountryCode column reference is unqualified — confirm it comes from Dim_Instrument. |
| 7 | PII sensitivity | High | Table contains customer full name, email, and TIN (tax ID). This is IRS-reportable PII. Confirm appropriate access controls and retention policies are in place. |

## Reviewer Corrections

*(Empty — awaiting human review)*

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 18 | RealCID, Regulation_EOY, ClientName, Client_Middle_Name, Client_Surname, Email, TIN_Value, Gross_Proceed, Cost, NetProfit, IsLongTerm, CloseDate, OpenDate, InstrumentDisplayName, ISINCode, Exchange, CUSIP, PositionID |
| Tier 5 | 1 | UpdateDate |
