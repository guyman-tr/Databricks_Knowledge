# Schema Overview: RiskClassification.Dictionary

## Purpose

The `Dictionary` schema contains the core reference/lookup tables that define the domain vocabulary for the risk classification system. These small, stable tables are the foundation that all other schemas reference for regulation names, parameter definitions, and risk level labels.

## Tables

| Table | Rows | Purpose | Key Consumers |
|-------|------|---------|--------------|
| Dictionary.Regulation | 14 | Regulatory jurisdiction definitions (CySEC, FCA, ASIC, FinCEN, etc.) | All scoring tables and views |
| Dictionary.RiskClassificationParameter | 46 | Risk parameter definitions with names, descriptions, sources, and weights | T_Scores, V_Scores, P_RiskClassification |
| Dictionary.RiskClassificationRegulation | 42 | Score-to-label mapping per regulation (0=Low, 50=Medium, 100=High, etc.) | V_Scores, V_RiskClassification, all export views |
| Dictionary.CySecRiskClassificationParameter | 46 | CySEC-specific parameter dictionary (FK target for CySEC scoring rules) | RiskClassification.CySecRiskClassificationParameter |

## Key Characteristics

- All tables are small (14-46 rows) and rarely change
- Dictionary.Regulation is replicated from the etoro source database via transactional replication
- All tables use PAGE compression
- These tables are already fully documented in the Business Glossary at `RiskClassification/Wiki/_glossary.md` with complete value maps

## Cross-Schema Relationships

Every schema in the database depends on Dictionary tables:
- **dbo**: T_RiskClassification, T_Scores reference Regulation and Parameter IDs
- **BackOffice**: RiskClassificationParameter has FK to Dictionary.RiskClassificationParameter
- **RiskClassification**: CySecRiskClassificationParameter has FK to Dictionary.CySecRiskClassificationParameter
- **History**: V_Scores JOINs to all three main Dictionary tables

---

*Generated: 2026-04-14 | Objects: 4 (4 tables) | Average quality: 9.2*
