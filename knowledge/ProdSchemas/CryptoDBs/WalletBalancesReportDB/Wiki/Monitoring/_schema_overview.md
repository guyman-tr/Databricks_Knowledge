# Monitoring Schema Overview - WalletBalancesReportDB

> Operational health-check procedures for the crypto wallet balance reconciliation system.

## Purpose

The Monitoring schema contains procedures designed for external observability tools (Datadog, Splunk) to verify that critical scheduled processes have executed successfully. It provides a clean separation between business logic (in the Wallet schema) and operational monitoring concerns.

## Objects

| Object | Type | Purpose |
|--------|------|---------|
| Monitoring.CheckIfTodaysFinanceReportExecuted | Stored Procedure | Returns count of completed reconciliation runs for today. Called by Datadog and SplunkUser agents. |

## Cross-Schema Dependencies

| Dependency | Schema | Relationship |
|-----------|--------|-------------|
| Wallet.FinanceReportRuns | Wallet | Read - counts completed runs by checking StartTime (today) and EndTime (NOT NULL) |

## Key Consumers

| Consumer | Type | How |
|----------|------|-----|
| Datadog | External monitoring agent | GRANT EXECUTE - polls to detect missed reconciliation runs |
| SplunkUser | External log aggregation | GRANT EXECUTE - operational dashboards and alerting |

## Architecture Notes

- The Monitoring schema is a thin read-only layer over Wallet schema tables
- All procedures are parameterless and return simple scalar results suitable for monitoring agents
- No data is written by Monitoring schema procedures - they are purely observational

---

*Generated: 2026-04-16*
