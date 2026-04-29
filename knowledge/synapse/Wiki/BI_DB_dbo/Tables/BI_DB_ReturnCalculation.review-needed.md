# BI_DB_dbo.BI_DB_ReturnCalculation — Review Needed

## Tier 4 Items

None.

## Questions for Reviewer

1. **RiskApetite typo**: Column name `RiskApetite` is missing the second 'p' (should be "Appetite"). Is this intentional or should it be renamed? Any downstream consumers that depend on the current spelling?
2. **Zero-equity masking**: When AverageRealizedEquity = 0, Return is set to 0 rather than NULL. This makes it impossible to distinguish "0% return" from "no equity data available." Is this the desired behavior?
3. **Open PnL in NetProfitPnL**: The NetProfitPnL columns include unrealized gains from BI_DB_PositionPnL, making these mark-to-market figures rather than realized profit. Consumers should be aware this value fluctuates with market conditions.
4. **Single snapshot only**: TRUNCATE+INSERT means no historical snapshots are retained. If historical return tracking is needed, a separate archival process would be required.
