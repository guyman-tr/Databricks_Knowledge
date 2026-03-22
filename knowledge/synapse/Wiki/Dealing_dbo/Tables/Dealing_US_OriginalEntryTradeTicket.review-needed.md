# Review Needed: Dealing_US_OriginalEntryTradeTicket

| Property | Value |
|----------|-------|
| **Generated** | 2026-03-21 |
| **Batch** | 17 |
| **Quality Score** | 6.5/10 |

## Automated Flags

- [ ] ⚠️ **STALE**: Data stopped 2025-01-13. SP_USTradeReports not in OpsDB. Confirm SP scheduling status.
- [ ] **PII**: `[Client Name]` contains customer full name. Confirm access controls and GDPR/data residency compliance.
- [ ] Mixed UTC/EDT: `[Time Order Received]` and `[Date/Time routed to APEX]` are UTC, while `[Time Order Executed or Cancelled]` is EDT (`DATEADD(HOUR,-4,...)`). Flag for downstream report consumers.
- [ ] `[Price Executed]` uses `UnitMargin` — this differs from `[Unit Price/share]` in DailyTradeBlotter which uses `ExecutionRate` from HedgeExecutionLog. Confirm which is the correct regulatory price for Original Entry.
- [ ] All regulatory constant fields (`[Order Type]='Market'`, `[Agency/Principal]='Agency'`, `[Solicited/Unsolicited]='Unsolicited'`, `[Long/Short Sell]='Long'`, `[Discretionary or non]='Non-discretionary'`) — confirm these are still accurate for all US trade types, especially after any regulatory changes or new product types.
- [ ] 587.6M rows — largest table in Dealing schema. Confirm whether there is a data retention/archival policy.
- [ ] Multiple special-character column names (spaces, slashes, parentheses) require bracket quoting throughout all queries.
- [ ] `[OrderID]` is bigint here vs varchar(25) in DailyTradeBlotter — different sources (HistoryOrder vs HedgeEMSOrders). Confirm these are compatible for joining.
- [ ] Atlassian MCP unavailable — likely has Confluence documentation as a regulatory report.

## Reviewer Corrections

<!-- Add reviewer corrections here. Mark resolved items with [RESOLVED] -->
