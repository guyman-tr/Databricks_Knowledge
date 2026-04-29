# BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions — Review Needed

## Tier 4 Items

None — all columns resolved to Tier 1 or Tier 2.

## Questions for Reviewer

1. **TradingVolume units**: TradingVolume sums InitialUnits (opens) and AmountInUnitsDecimal (closes). These are in instrument-native units (shares for stocks, coins for crypto, lots for CFDs). Is it meaningful to aggregate volume across different instrument types, or should volume only be compared within the same Instrument_Type?

2. **TradingValue forex rate timing**: For opens, the value uses InitForexRate * InitConversionRate (rate at position open). For closes, it uses EndForexRate * EndForex_USDConversionRate (rate at position close). Confirm these are the intended rates — should quarter-end rates be used instead for consistency?

3. **Is_Active flag source**: The Is_Active flag appears to use the same composite logic as the sibling `_end` table (position activity OR deposit/cashout). Since this table only contains customers with positions, under what circumstances would Is_Active = 0 appear? Only if the position data is from a different quarter than the activity check?

4. **Country and Account_Type_Group denormalization**: These columns are also present in the sibling `_end` table. Confirm they are populated from the same source (Dim_Country, Dim_AccountType) and should always match when joined on CID + Report_End_Date.

5. **Instrument_Type classification**: Same classification as Market_Value table. Are there any instrument types that appear in Positions but not in Market_Value, or vice versa?

## Corrections Applied

- None required — column count matches DDL (9 columns).

## Tier Summary

- **Tier 1 (2 columns)**: CID (Customer.CustomerStatic), Country (Dictionary.Country)
- **Tier 2 (7 columns)**: Instrument_Type, TradingVolume, TradingValue, Report_End_Date, UpdateDate, Is_Active, Account_Type_Group

## Reviewer Instructions

1. Validate TradingValue against manual calculations for a sample of known positions
2. Confirm forex rate source (trade-time vs quarter-end) with the SP author
3. Check for any Is_Active = 0 rows and explain why they exist in a positions table
4. Verify Country/Account_Type_Group consistency with sibling _end table
