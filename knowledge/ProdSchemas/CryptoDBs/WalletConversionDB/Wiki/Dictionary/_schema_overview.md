# Schema Overview: Dictionary - WalletConversionDB

> The Dictionary schema contains small lookup/reference data tables that define value domains used by other schemas in WalletConversionDB.

## Purpose

The Dictionary schema provides canonical definitions for enumerated values used across the database. These are small, stable, read-only tables seeded during deployment. They serve as FK targets for columns in the C2F schema, ensuring data integrity and providing human-readable labels for integer status and type codes.

## Tables

| Table | Rows | Purpose | Key Consumers |
|-------|------|---------|---------------|
| ConversionToFiatStatuses | 4 | Conversion lifecycle states (Pending, Failed, Completed, Rejected) | C2F.ConversionStatuses (FK), query SPs |
| FiatConversionTargets | 3 | Fiat destination types (IbanAccount, EtoroPlatform, EtoroPosition) | C2F.Conversions (FK) |

## Relationship to Glossary

Both Dictionary tables have corresponding entries in the database-wide Business Glossary (`_glossary.md`):
- [Conversion To Fiat Status](../_glossary.md#conversion-to-fiat-status) - full value map with business context
- [Fiat Conversion Target](../_glossary.md#fiat-conversion-target) - full value map with business context

## Documentation Quality

| Metric | Value |
|--------|-------|
| **Total Objects** | 2 |
| **Average Quality** | 9.2/10 |
| **Sessions Used** | 1 |
| **Completed** | 2026-04-15 |

---

*Generated: 2026-04-15*
