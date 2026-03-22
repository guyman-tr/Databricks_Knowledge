# Review Needed — Dealing_IBRecon_Trades

**Generated**: 2026-03-21
**Quality Score**: 6.5/10

## Items for Human Review

1. **⚠️ STALE DATA — last row 2025-08-22** — The table has not been updated in 7+ months. Investigate whether `SP_IB_Recon` is still running for trades, whether IB stopped sending trade confirmation files, or whether this table has been superseded by another data source.

2. **Pipeline health** — If the stale data is unintentional, this represents a significant reconciliation gap. The Dealing team should be alerted if they are relying on this table for IB trade break analysis.

3. **IB_Rate vs eToro_Rate** — The `Rate` columns are present in trades but their derivation (IB execution price vs eToro average execution price) should be confirmed for accuracy in break analysis workflows.
