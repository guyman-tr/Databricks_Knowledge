# Review Notes — Dealing_dbo.Dealing_Market_Manipulation_OutstandingsharesHigherthan005

**Status**: Active ✅

## Items Requiring Human Review

1. **Threshold hardcoding**: Both thresholds (0.5% instrument-level, 0.25% CID-level) are hardcoded in the SP. Confirm these are still the correct regulatory/operational thresholds and whether they should be configurable.

2. **InstrumentID=2731 exclusion**: A specific instrument is hardcoded as excluded from monitoring. Confirm what instrument this is and whether the exclusion is still valid.

3. **HedgeServerID exclusion list**: Servers 2,7,101,121-126,225-226,3,9,112,125,126,128 are excluded. Confirm this list is current — new LP servers may need to be added.

4. **NULL row behavior**: Days with no flags produce a NULL CID row. Confirm downstream consumers handle this correctly and don't count NULL rows as events.

5. **Email sibling table**: `Dealing_Market_Manipulation_OutstandingsharesHigherthan005_Email` receives TRUNCATE+INSERT from the same SP. Confirm the email alert system reading from this table is still active.

6. **IsSettled=1 scope**: Only settled same-day positions are counted. Confirm whether unsettled intraday activity should also be captured.
