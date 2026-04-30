# Schema Overview: RiskClassification.BackOffice

## Purpose

The `BackOffice` schema contains operational/configuration tables used by compliance operations to manage the risk classification system. It holds the scoring rules configuration, manual risk overrides, and deployment tracking.

## Tables

| Table | Rows | Purpose | Temporal |
|-------|------|---------|----------|
| BackOffice.RiskClassificationParameter | ~varies | Scoring rules configuration - maps input values to risk scores per parameter and regulation | Yes (History.RiskClassificationParameter) |
| BackOffice.ExceptionalCustomers | 7 active, ~127K historical | Manual compliance overrides forcing specific risk scores for individual customers | Yes (History.ExceptionalCustomers) |
| BackOffice.UpgradeScript | 16 | Schema migration audit log tracking deployed upgrade scripts | No |

## Key Patterns

- Both business tables (ExceptionalCustomers, RiskClassificationParameter) use temporal versioning for full audit trails
- Both have explicit FK constraints to Dictionary.RiskClassificationParameter
- UpgradeScript is a standalone DevOps/deployment tracking table with no business dependencies
- ExceptionalCustomers is the compliance team's override mechanism for forcing risk scores

## Cross-Schema Relationships

| Dependency | Direction | Description |
|-----------|-----------|-------------|
| Dictionary.RiskClassificationParameter | BackOffice depends on | FK target for both ExceptionalCustomers and RiskClassificationParameter |
| History.ExceptionalCustomers | Depends on BackOffice | Temporal history for ExceptionalCustomers |
| History.RiskClassificationParameter | Depends on BackOffice | Temporal history for RiskClassificationParameter |
| dbo.V_RiskClassificationParameter | Depends on BackOffice | View built on BackOffice.RiskClassificationParameter |

---

*Generated: 2026-04-14 | Objects: 3 (3 tables) | Average quality: 9.1*
