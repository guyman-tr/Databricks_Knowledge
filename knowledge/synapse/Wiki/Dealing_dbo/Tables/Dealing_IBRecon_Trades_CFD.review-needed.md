# Review Needed — Dealing_IBRecon_Trades_CFD

**Generated**: 2026-03-21
**Quality Score**: 5.5/10

## Items for Human Review

1. **⚠️ EFFECTIVELY ABANDONED — 1 row from 2025-03-28** — Only a single row exists, nearly a year old. Confirm whether this table was ever operationally used, whether it should be formally decommissioned, or whether IB CFD trade reconciliation is handled elsewhere.

2. **No downstream consumers identified** — No reports, views, or downstream tables were found referencing this table. If it has no consumers, consider whether it should be dropped to reduce schema clutter.

3. **SP_IB_Recon CFD branch** — The writer SP has a CFD insert branch. Confirm whether the CFD trade reconciliation logic was intentionally disabled or if the IB CFD account (HS 300) simply generates no trade-level data for reconciliation.
