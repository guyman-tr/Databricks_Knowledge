# Review Needed — Dealing_JPMReconEODHolding

**Generated**: 2026-03-21
**Quality Score**: 7.8/10

## Items for Human Review

1. **HS 9 special grouping key** — HedgeServer 9 is joined on ISINCode + InstrumentDisplayName only (not InstrumentID or Exchange). This is claimed to be due to LP reporting differences, but the exact LP-side reason is not confirmed. Verify whether HS 9's behaviour is intentional and stable, or a workaround for a historical data issue.

2. **JPM date lag handling** — When JPM's report is delayed, `@DateID2 = MAX(ReportDateID) WHERE ReportDateID <= @DateID` means this table may show a date 1 day behind eToro's actual EOD. Confirm whether downstream consumers (e.g., Dealing desk dashboards) are aware of and handle this potential 1-day lag.

3. **GBX normalisation scope** — GBX ÷100 is applied on the eToro side (`eToroLocalAmount`). Confirm that JPM always reports GBP (not GBX) for UK-listed instruments, so the normalisation is one-sided and not double-applied.

4. **Regions covered** — Documentation states NA, EMEA, and ASIA. Confirm all three regions are actively populated in `Dealing_Duco_EODRecon` with HedgeServers 2, 8, 22, 9, 121, 110, 129, and that no new HS has been added to the JPM LP group since Nov 2023.

## Reviewer Corrections

_None yet._
