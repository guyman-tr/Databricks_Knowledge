# BackOffice Schema Overview - MoneyTransfer

> The BackOffice schema in MoneyTransfer is a minimal administrative schema containing a single metadata tracking table for database upgrade script history.

## Schema Summary

| Property | Value |
|----------|-------|
| **Database** | MoneyTransfer |
| **Schema** | BackOffice |
| **Total Objects** | 1 |
| **Tables** | 1 |
| **Views** | 0 |
| **Functions** | 0 |
| **Stored Procedures** | 0 |
| **Documentation Coverage** | 100% |

## Purpose

The BackOffice schema provides administrative infrastructure for the MoneyTransfer database. Its sole object, `BackOffice.UpgradeScript`, serves as a registry for tracking manual database schema migrations. This is a common pattern in databases that may receive both automated deployments (SSDT dacpac) and ad-hoc upgrade scripts.

## Objects

### Tables

| Table | Purpose |
|-------|---------|
| [BackOffice.UpgradeScript](Tables/BackOffice.UpgradeScript.md) | Tracks applied database upgrade scripts with version and script name |

## Related Schemas

The MoneyTransfer database contains the following additional schemas:

| Schema | Purpose |
|--------|---------|
| **Billing** | Core money transfer transaction processing - transfers, post-transfer actions, and related stored procedures |
| **Dictionary** | Lookup/reference tables for transfer statuses (TransferStatus, PostTransferStatus) |
| **History** | Historical/archival storage for transfer data (Transfers, TransferStepsLog) |
| **Monitoring** | Operational monitoring procedures for transfer health metrics |
| **dbo** | System-level tracking (ChangesLog) |

## Key Observations

- The BackOffice schema is notably lightweight compared to the Billing schema, which contains the core business logic for money transfers
- A parallel `Billing.UpgradeScript` table exists with a richer schema (PK, timestamp, login tracking), suggesting BackOffice uses an older or simplified version of the upgrade tracking pattern
- The BackOffice.UpgradeScript table is currently empty, likely because schema changes are deployed via automated SSDT dacpac rather than manual scripts

---

*Last updated: 2026-04-15 | Documentation sessions: 1*
