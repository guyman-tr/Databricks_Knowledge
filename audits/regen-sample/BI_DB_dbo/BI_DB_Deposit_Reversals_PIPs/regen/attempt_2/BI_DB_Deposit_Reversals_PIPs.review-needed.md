# Review Needed: BI_DB_dbo.BI_DB_Deposit_Reversals_PIPs

## Open Questions

1. **Label ↔ Dim_PlayerLevel mapping**: The SP maps the `Label` column to `Dim_PlayerLevel.Name` instead of `Dim_Label.Name`. This appears intentional (same pattern exists in other BI_DB SPs) but is semantically misleading — the column name suggests label/brand but contains club tier names. Reviewer should confirm this is the intended behavior and not a bug in SP_Deposit_Reversals_PIPs.

2. **Temporary solution status**: The SP header (Author: Guy Manova, 2024-02-16) states this is a "temporary solution" pending production views from DBAs. Has the permanent solution been implemented? If so, this table may be superseded.

3. **MOPCountry and IsGermanBaFin**: Both columns are hardcoded to 'NA' and NULL respectively. Are these planned for future population or should they be removed from the schema?

4. **Data freshness**: Data ends at 2025-09-10 (observed during Phase 2 sampling). Confirm whether the daily ETL is still running or has been suspended.

5. **MID resolution logic**: The MID CASE chain references specific DepotIDs (78, 79, 80, 4, 75, 86) and FundingTypeID=2. These hardcoded values may drift from production if depot/funding configurations change.

## Tier Coverage Summary

- **Tier 1 (15 columns)**: CID, Customer, Currency, ExchangeRate, BaseExchangeRate, RegulationID, PlayerLevelID, Regulation, Label, Club, PlayerStatus, RegCountry, RegCountryByIP, CardType, BinCountry — all dim-lookup passthroughs or direct passthroughs with upstream wiki traced to production origin.
- **Tier 2 (22 columns)**: All SP-computed or multi-source columns including DateID, DepositWithdrawID, Occurred, CreditTypeID, TransactionID, Date, TransactionType, PaymentMethod, Amount, AmountUSD, LabelID, IsValidCustomer, UpdateDate, ExchangeFee, ExternalTransactionID, Depot, MIDValue, PIPsCalculation, CardCategory, MOPCountry, IsGermanBaFin, Entity.
- **Tier 3/4 (0 columns)**: None — all columns grounded in SP code or upstream wikis.

## Validation Notes

- Element count: 37 columns matches DDL (37 columns in CREATE TABLE).
- All 8 sections present in wiki.
- ETL pipeline diagram present in Section 5.2.
- Tier suffix present on every Element row.
