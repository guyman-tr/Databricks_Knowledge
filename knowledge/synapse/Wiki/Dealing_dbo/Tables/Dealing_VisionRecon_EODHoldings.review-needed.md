# Review Needed — Dealing_VisionRecon_EODHoldings

**Generated**: 2026-03-21
**Quality Score**: 7.5/10

## Items for Human Review

1. **CUSIP as primary join key** — This table uses CUSIP + AccountNumber as join key instead of ISINCode. Confirm that Vision always provides CUSIP in `LP_VisionET_R006_EOD_Positions_ET` and there is no fallback to ISIN when CUSIP is absent.

2. **Reality-Supposed naming** — `Reality-Supposed` means Vision (reality) minus eToro (supposed/expected). Confirm this interpretation is correct and that the calculation is `Vision_AmountUSD − eToroAmountUSD` (not `eToroAmountUSD − Vision_AmountUSD`).

3. **LowerBoundary/UpperBoundary scope** — Tolerance bands come from `etoro_Hedge_InstrumentBoundaries`. Confirm whether all Vision-traded instruments have boundary entries or if some show NULL/0 (unconfigured). Describe what action the Dealing desk takes for breaks where boundaries are zero.

4. **No FX columns** — Unlike IG and JPM, this table has no `LP_FXRate` or `eToro_FXRate` columns. Confirm that Vision provides USD-denominated amounts directly (pre-converted), or clarify how USD conversion is applied in SP_Vision_Recon.

5. **HedgeServer assignment for Vision** — `HedgeServerID` is NULL for Vision-only rows. Confirm the set of HS IDs mapped to Vision LP via `External_Fivetran_dealing_active_hs_mappings` (LP='Vision').

## Reviewer Corrections

_None yet._
