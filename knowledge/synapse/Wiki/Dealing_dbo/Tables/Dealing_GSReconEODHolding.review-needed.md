# Review Needed — Dealing_GSReconEODHolding

**Generated**: 2026-03-21
**Quality Score**: 7.5/10

## Items for Human Review

1. **CFDs only** — The Fivetran HS mapping filter is `activity = 'Stocks - CFDs'`. Confirm GS is exclusively a CFD LP and no Real Stocks hedging goes through GS.

2. **InstrumentDisplayName is varchar(max)** — Unusually large column type for a display name. Check if this causes any downstream processing issues.

3. **GS_FXRate vs eToro_FXRate discrepancy** — Sample data shows GS_FXRate and eToro_FXRate differ. Confirm this is expected (different FX sources) and how it is used in break analysis.
