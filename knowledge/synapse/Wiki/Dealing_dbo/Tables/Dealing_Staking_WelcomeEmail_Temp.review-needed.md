# Review Notes: Dealing_Staking_WelcomeEmail_Temp

**Batch**: 5 | **Date**: 2026-03-21 | **Quality Score**: 5.5

## Items Requiring Human Review

1. **GCID vs CID**: The table stores `GCID` (Global Customer ID) rather than the more common `CID`. Confirm that downstream email dispatch (`EXE_dbo.EXE_Staking_AirDrop_sent_email`) correctly maps GCID to the email system's identifier. Document the GCID-to-CID relationship if it differs.

2. **Country exclusion list**: SP_Staking_WelcomeEmail has a hardcoded country exclusion list. Confirm this list is current and matches the staking eligibility policy. Countries may need updating as regulations change.

3. **Run day logic**: The SP uses `DayNumberOfWeek_Sun_Start IN (3, 7)` for Wed/Sun. Confirm this day-of-week convention is consistent with other SPs in the schema (some use Mon-start vs Sun-start conventions).

4. **Supported crypto list**: The staking parameters reference `Dealing_Staking_Parameters` — confirm the 10 supported cryptos (ETH, ADA, TRX, SOL, DOT, NEAR, ATOM, AVAX, SUI, POL) are current and the `instrument_id_range` (100xxx series) is accurate.

5. **OpsDB shows P0 AND P1**: There are three OpsDB entries (SP_Staking_WelcomeEmail P0, SP_W_Sun P1, SP_W_Wed P1). Confirm which SP is the canonical writer and whether the P0 daily entry is a no-op on non-Sun/Wed days or is decommissioned.

## Low-Confidence Fields

- **GCID**: Single-column table — description is inferred from SP logic. Verify GCID matches the email system's customer identifier (may be a platform-level ID distinct from Synapse CID).
