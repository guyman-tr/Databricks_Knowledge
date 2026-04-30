# MoneyTransfer - dbo Schema Overview

## Purpose

The `dbo` schema in the MoneyTransfer database contains infrastructure-level objects that support database administration and audit capabilities. Unlike the business-centric schemas (Billing, Monitoring, BackOffice), the dbo schema serves as a catch-all for system-level objects.

## Objects

| Object | Type | Purpose |
|--------|------|---------|
| [dbo.ChangesLog](Tables/dbo.ChangesLog.md) | Table | DDL audit log capturing schema change events (CREATE, ALTER, DROP) with full actor and command context |

## Characteristics

- **1 table** - minimal schema footprint
- **No views, procedures, functions, or synonyms** in this schema
- **Infrastructure-only** - no business transaction data
- **Audit-focused** - the sole object serves DDL change tracking

## Architecture Context

The dbo.ChangesLog table is an organization-wide DDL audit pattern found across multiple databases (also present in RecurringManager). It was historically populated by a database-level DDL trigger that captured `EVENTDATA()` from SQL Server's event notification system. The trigger has since been removed or disabled.

The table is completely isolated - no other objects in the MoneyTransfer database read from or write to it via stored procedures or views. It exists as a passive historical record of schema modifications.

## Key Insights

- **Primary DBA**: `doriz@etoro.com` performed the majority of schema changes (captured across 34 historical events)
- **Most active schema**: Billing schema accounts for 71% of all recorded DDL events, reflecting it as the core transactional schema
- **Object types modified**: Only TABLE and PROCEDURE changes were captured - no view, function, or index DDL events recorded
- **Active period**: August 2023 through June 2025

*Generated: 2026-04-16*
