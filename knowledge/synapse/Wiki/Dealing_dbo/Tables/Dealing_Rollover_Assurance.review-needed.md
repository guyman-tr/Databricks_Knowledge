# Review Needed — Dealing_Rollover_Assurance

## Items Requiring Domain Expert Review

1. **[Fee updated] category scope**: InstrumentID=22 (XNG/USD) and InstrumentTypeID IN (5,6) are hardcoded in the SP as the "fee config update" bucket. Confirm whether this is still the correct scope or if the logic has evolved since SR-219309 migration (Nov 2023).

2. **WeekendFeePrecentage semantics**: The column is named "percentage" but value=0 identifies Islamic accounts while non-zero values represent weekend fee percentages. Confirm the non-zero range and whether any non-Islamic customers also have WeekendFeePrecentage=0 for other contractual reasons.

3. **HedgeServerID=121 exclusion**: Why is server 121 excluded from rollover tracking? Confirm this is a dedicated non-rollover hedge server or a special LP routing.

4. **Data gap before 2022**: SP is daily (SB_Daily) but data starts 2022-01-01. Confirm whether pre-2022 history was never loaded or was truncated/deleted.

5. **[Closed after cutoff] 90-min window**: The SP uses `BETWEEN chargeTime AND dateadd(minute,30,dateadd(hour,1,chargeTime))` = chargeTime + 1h30min. Confirm whether this window is still the correct business rule for the "late close" category.
