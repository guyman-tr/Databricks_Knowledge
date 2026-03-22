# Review Needed — Dealing_BNY_Detailed

**Generated**: 2026-03-21
**Quality Score**: 7.0/10

## Items for Human Review

1. **Redundancy with summary tables** — This table appears to be a staging/diagnostic table used by the recon pipeline. Confirm whether it is consumed by any downstream reports or is exclusively for internal pipeline debugging.

2. **LiquidityAccountID nullable** — Many eToro rows have LiquidityAccountID populated but LP rows may not. Confirm whether `HedgeServerID` and `LiquidityAccountID` are always populated together for eToro rows.

3. **CFD activity** — Small fraction of rows have activity='Stocks - CFDs'/'Stocks - CFD'. Confirm if this is expected or if CFD activities should be handled separately.
