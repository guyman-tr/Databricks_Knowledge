# Review Needed: BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months

## Tier 4 Items (Needs Verification)

- None. All columns traced to SP code (Tier 2) or ETL metadata (Tier 5).

## Questions for Reviewer

1. **Count columns as decimal**: LossTotalPnL, ZeroTotalPnL, ProfitTotalPnL are customer counts but stored as decimal(16,4). This appears to be an oversight — CAST to INT for reporting. Was this intentional?
2. **Retail-only population**: MifidCategorizationID NOT IN (2,3) excludes Professional and Eligible Counterparty. Confirm this matches the ESMA disclosure requirement (should only include retail clients).
3. **IsSettled=0 filter**: The NetProfit query filters Dim_Position.IsSettled=0 (unsettled positions). Confirm this is the correct interpretation — does IsSettled=0 mean "real trades" vs IsSettled=1 meaning "settled/demo"?
4. **Daily vs Quarterly**: The SP runs daily but creates daily rolling windows. For quarterly ESMA reporting, the convention is to use the last window of the quarter (MAX EndDateID per QuarterYear).

## Cross-Object Consistency

- RegulationID/Regulation: consistent with DWH_dbo.Dim_Regulation conventions
- Companion: BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months_Instrument — same SP writes both, same window logic

## Corrections Applied

- None.
