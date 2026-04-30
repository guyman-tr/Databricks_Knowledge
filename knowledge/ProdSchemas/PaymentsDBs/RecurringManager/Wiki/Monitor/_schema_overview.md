# Monitor Schema - RecurringManager

## Purpose

The Monitor schema in RecurringManager contains stored procedures designed specifically for external monitoring tool integration (primarily Datadog). These procedures provide simplified, scalar-output health checks that monitoring agents can poll on a schedule to detect business rule violations and system anomalies.

## Objects

| Object | Type | Purpose |
|--------|------|---------|
| [Monitor.Alert_CIDWithMoreThanAllowed](Stored Procedures/Monitor.Alert_CIDWithMoreThanAllowed.md) | Stored Procedure | Detects customers with more than one active recurring payment - returns 0/1 for Datadog consumption |

## Characteristics

- **Size**: 1 object (1 stored procedure)
- **Business Role**: Operational monitoring and alerting - detects violations of the one-active-plan-per-customer business rule
- **Consumers**: Datadog monitoring agent (via `datadog` SQL user)
- **Pattern**: Simplified wrappers around Recurring schema alert procedures, optimized for monitoring tool scalar-check formats
- **Relationships**: Read-only access to Recurring schema tables (no writes, no side effects)

## Relationship to Recurring Schema

The Monitor schema mirrors alert procedures from the Recurring schema but with simplified interfaces:

| Monitor Version | Recurring Version | Difference |
|----------------|-------------------|------------|
| Monitor.Alert_CIDWithMoreThanAllowed | Recurring.Alert_CIDWithMoreThanAllowed | Monitor: no params, returns scalar. Recurring: configurable threshold, returns CID detail set |

## Data Flow

```
Datadog Scheduler (periodic)
       |
       v
  Monitor.Alert_CIDWithMoreThanAllowed
       |
       v
  Recurring.Payment (read-only)
       |
       v
  0 = healthy / 1 = alert -> Datadog metric -> PagerDuty/Slack alert
```

---

*Generated: 2026-04-16*
