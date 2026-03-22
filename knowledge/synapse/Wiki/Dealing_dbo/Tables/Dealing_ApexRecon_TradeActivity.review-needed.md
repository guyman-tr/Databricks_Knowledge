# Review Notes: Dealing_ApexRecon_TradeActivity

**Batch**: 5 | **Date**: 2026-03-21 | **Quality Score**: 8.0

## Items Requiring Human Review

1. **SP_Run_Recon intraday trigger**: OpsDB shows `SP_Run_Recon` triggers at 12:00 UTC in addition to EOD run. Confirm what SP_Run_Recon does — does it re-run SP_Apex_Recon for the current day? If so, data may be refreshed mid-day and consumers should be aware of this.

2. **Daylight Savings handling**: SP_Apex_Recon has explicit DST code paths. Confirm the DST boundary dates are maintained and the logic correctly handles the transition periods (especially for EU/US boundary crossings).

3. **LP_APEX_EXT872_3EU_217314 file format**: The table name suggests this is a specific Apex file format (EXT872). Confirm the file schema has not changed since the SP was last updated (2025-09-29) and that the Fivetran connector is current.

4. **Three-table write order**: SP writes TradeActivity → Holdings → Hedging in sequence. Confirm each step completes before the next begins and that partial failures are handled (what happens if Holdings fails after TradeActivity succeeds?).

5. **Reconciliation break thresholds**: The Hedging recon table uses $50K/$5K thresholds. Confirm whether TradeActivity has similar alert thresholds or if it's purely informational.

6. **AccountNumber format validation**: Apex account numbers are alphanumeric 8-char. Confirm the format hasn't changed and whether multiple account numbers per LP are possible.

## Low-Confidence Fields

- **LiquidityAccountID**: Sourced via Fivetran HS mapping — confirm the mapping is current and covers all active Apex LP accounts.
- **Etoro_Rate / Apex_Rate**: Rate comparison semantics (weighted average vs last price vs VWAP) should be confirmed with the Apex reconciliation team.
