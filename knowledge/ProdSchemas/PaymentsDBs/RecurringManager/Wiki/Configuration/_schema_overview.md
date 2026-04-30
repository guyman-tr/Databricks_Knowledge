# Configuration Schema - RecurringManager

## Purpose

The Configuration schema in RecurringManager contains feature-flag and settings tables that control the behavior of the recurring payments system. These tables externalize business rules that would otherwise be hardcoded, allowing operations teams to adjust system behavior per jurisdiction without code deployments.

## Objects

| Object | Type | Purpose |
|--------|------|---------|
| [Configuration.NotificationSetting](Tables/Configuration.NotificationSetting.md) | Table | Controls whether recurring payment notifications are enabled for specific countries, states, and regulatory frameworks |

## Characteristics

- **Size**: 1 object (1 table)
- **Business Role**: Feature gating and jurisdiction-specific configuration for the notifications subsystem
- **Consumers**: Recurring Manager application service (reads at runtime to gate notification creation)
- **Temporal**: All tables use SYSTEM_VERSIONING for full change audit trail
- **Relationships**: No direct FK relationships within the database - references external platform-level data (country, state, regulation IDs)

## Data Flow

```
Operations/BackOffice -> Configuration.NotificationSetting (manual config)
                              |
                              v
                    Recurring Manager Service (reads settings)
                              |
                              v
                    Recurring.Notification (creates/suppresses based on config)
```

---

*Generated: 2026-04-16*
