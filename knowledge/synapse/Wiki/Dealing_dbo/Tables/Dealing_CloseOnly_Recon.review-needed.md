# Review Notes: Dealing_CloseOnly_Recon

**Batch**: 5 | **Date**: 2026-03-21 | **Quality Score**: 7.8

## Items Requiring Human Review

1. **AllowClosePosition flag semantics**: Documented as `AllowBuy=0 AND AllowSell=0` in the instrument configuration. Confirm which table/column in the source pipeline carries the AllowBuy/AllowSell flags — is it from `DWH_dbo.Dim_Instrument`, from an instrument configuration table in `Dealing_staging`, or derived from `Dealing_Duco_EODRecon` directly?

2. **Row grain per HedgeServerID**: The SP groups by HedgeServerID and InstrumentID. Confirm whether a single instrument can appear multiple times per date if different hedge servers hold it (e.g., one row per LP account).

3. **Change_in_Units delta sign convention**: Documented as today minus yesterday (negative = decreasing as expected). Confirm this is how downstream monitors interpret it — negative deltas for close-only instruments are expected/normal, positive deltas are alerts.

4. **Business alerting on positive Change_in_Units**: Is there an automated alert or dashboard consuming this table? Confirm what action is taken when `Change_in_Units_Clients > 0` for a close-only instrument.

5. **CurrencyPrimary**: Mapped as `SellCurrency` from Duco EODRecon. Confirm this represents the correct "primary currency" for the instrument (some instruments may have SellCurrency = instrument home currency vs USD).

6. **Previous_Date logic on Monday**: The SP skips weekends for Previous_Date. Confirm whether this means Monday's data always compares to Friday, and whether holiday handling is included (e.g., if Friday was a holiday, does it go to Thursday?).

## Low-Confidence Fields

- **AllowClosePosition**: The exact source field/table for this flag was not confirmed from SP analysis.
- **eToroUSDAmount vs ClientAmount currency**: Both should be in USD — confirm both are USD-denominated (client amount conversion path from Duco should match).
