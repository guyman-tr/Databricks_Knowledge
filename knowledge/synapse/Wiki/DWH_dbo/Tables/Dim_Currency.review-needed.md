# DWH_dbo.Dim_Currency - Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 [UNVERIFIED] columns in this document.

## Columns Needing Clarification

| Column / Topic | Question |
|----------------|----------|
| InterestRateID | What dimension does InterestRateID reference? Is there a DWH_dbo.Dim_InterestRate table? Or does this reference a production etoro.Dictionary.InterestRate configuration? |
| Row count discrepancy | DWH has 15,734 rows; upstream wiki documents 10,669. The DWH has ~5K more instruments. Is this expected growth (new instruments added since the wiki was written) or does it include delisted/inactive instruments that should be filtered? |
| CurrencyTypeID=10 in upstream | The upstream wiki documents CurrencyTypeID=10 as Crypto with 630 instruments. DWH shows 686 (56 more). Is there a Dim_CurrencyType table in DWH for decoding type IDs? |
| CurrencyID=0 placeholder | CurrencyID=0 has Name=NULL and Abbreviation='000'. Is this used as a "no instrument" foreign key placeholder in fact tables (similar to the ID=0 pattern in other dim tables)? |

## Structural Questions

| Question |
|----------|
| Is there a DWH_dbo.Dim_CurrencyType table that decodes CurrencyTypeID (1=Forex, 2=Commodity, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto)? |
| The upstream production table has 3 audit triggers capturing all changes to History.AuditHistory. The DWH does not replicate this. Is there a separate mechanism to track instrument configuration changes in the DWH? |
| The name "Dim_Currency" vs content (mostly stocks). Is there a plan to rename or create a Dim_Instrument alias? |

## Tier 5 Re-Review Needed

| Column | Tier 5 Correction | Was Based On (old Tier 1-3) | New Tier 1-3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
