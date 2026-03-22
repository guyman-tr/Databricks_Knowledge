# Review Notes: Dealing_Duco_EODRecon

**Batch**: 5 | **Date**: 2026-03-21 | **Quality Score**: 8.5

## Items Requiring Human Review

1. **MKTcap source**: The `MKTcap` column source was listed as "external reference table" — the exact source table was not conclusively identified from the SP. Confirm whether this comes from `Dealing_staging` or `CopyFromLake` and what refresh cadence it uses.

2. **CUSIP source**: Similarly, CUSIP appears to come from `etoro_Hedge_Netting` or a separate external data file. Confirm the exact source and whether CUSIP is always populated for US-listed instruments.

3. **eToroRate weighted average**: Documented as LP weighted average holding rate. Confirm the exact weighting formula in the SP (is it units-weighted or value-weighted?).

4. **HedgingPercent NULL handling**: When `ClientUnits = 0` but `eToro_Units > 0` (LP holds but no clients), HedgingPercent is NULL/undefined. Confirm this is handled correctly downstream in the LP-specific recon SPs (they may filter these out).

5. **Weekend gap impact on recon**: Several downstream recon SPs (e.g., SP_ApexRecon) run daily but use EODRecon data from the previous business day on weekends. Confirm the `Previous_Date` logic in each downstream SP handles the Fri→Mon gap.

6. **Atlassian context unavailable**: The Atlassian MCP was unavailable during documentation. Any Jira tickets referencing schema changes to `Dealing_Duco_EODRecon` from 2025+ should be reviewed for accuracy (particularly the 2025-08-07 SP update).

## Low-Confidence Fields

- **MKTcap**: Source not conclusively identified from SSDT SP.
- **CUSIP**: Source table inferred; may come from an external file rather than a Synapse table.
- **Buy/Sell derivation**: Sign logic for direction documented as net units; exact SP implementation should be verified.
