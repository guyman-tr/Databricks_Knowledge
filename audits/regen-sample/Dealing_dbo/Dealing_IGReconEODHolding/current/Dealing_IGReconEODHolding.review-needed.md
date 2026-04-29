# Review Needed — Dealing_IGReconEODHolding

**Generated**: 2026-03-21
**Quality Score**: 7.8/10

## Items for Human Review

1. **IG instrument scope** — The SP has a hardcoded `#MarketNameToID` table with ~25 instruments (indices, key FX, Oil, Gold, Silver). Confirm if this list is exhaustive or if IG has since added instruments via ISIN-only matching (unmapped market names). Current coverage looks limited vs other LPs.

2. **IG_AmountUSD derivation** — The SP uses `[Consideration (Base Ccy)]` from `LP_IG_PS_EODPositions` for IG_AmountUSD but this field appears to be the trade consideration rather than a mark-to-market EOD value. Confirm whether this is the correct USD valuation column for IG EOD holdings.

3. **Account_Number NULL rows** — Rows where Account_Number IS NULL represent eToro-only positions (no IG counterpart). Confirm expected volume and whether these indicate IG reporting gaps or eToro positions not sent to IG.

4. **IG_FXRate vs eToro_FXRate discrepancy** — The SP parses IG's FX rate as a string (`LEFT([Conversion Rate], LEN-1)`). Confirm this is stable and that the trailing character being stripped is always `%` or similar.

## Reviewer Corrections

_None yet._
