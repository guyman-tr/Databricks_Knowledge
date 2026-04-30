# Schema Overview: RiskClassification.History

## Purpose

The `History` schema stores temporal history tables for SQL Server system-versioned tables across the RiskClassification database. These tables are automatically populated by the temporal versioning system whenever rows in their parent tables are updated or deleted. The schema provides full audit trails and point-in-time query capabilities for compliance and regulatory lookback.

## Architecture

```
Parent Tables (various schemas)          History Tables
+-----------------------------------+    +-----------------------------------+
| dbo.T_RiskClassification          | -> | History.T_RiskClassification      |
| dbo.T_Scores                      | -> | History.T_Scores                  |
| dbo.T_RiskClassification20200122  | -> | History.T_RiskClassification20200122 |
| dbo.T_Scores20200122              | -> | History.T_Scores20200122          |
| BackOffice.ExceptionalCustomers   | -> | History.ExceptionalCustomers      |
| BackOffice.RiskClassificationParam| -> | History.RiskClassificationParameter|
+-----------------------------------+    +-----------------------------------+
                                                     |
                                              History.V_Scores
                                         (UNION ALL dbo + History)
```

## Tables by Size

| Table | Approx Rows | Parent Table | Notes |
|-------|------------|-------------|-------|
| History.T_Scores | ~261M | dbo.T_Scores | Largest table in entire DB. Per-parameter score history. |
| History.T_RiskClassification | ~8.5M | dbo.T_RiskClassification | Wide-column risk classification history. |
| History.T_Scores20200122 | ~5M | dbo.T_Scores20200122 | 2020 archive history (with SubValue). |
| History.ExceptionalCustomers | ~127K | BackOffice.ExceptionalCustomers | Manual risk override history. |
| History.RiskClassificationParameter | ~195 | BackOffice.RiskClassificationParameter | Scoring rule config history. |
| History.T_RiskClassification20200122 | 0 | dbo.T_RiskClassification20200122 | Empty - archive never modified. |

## Key Patterns

- All History tables use clustered indexes on (key columns + BeginTime) with FILLFACTOR 90 and PAGE compression
- No PK constraints on History tables (managed by temporal system)
- BeginTime/EndTime define each version's validity window
- History.V_Scores is the only view - provides unified current+historical score timeline

## Cross-Schema Consumers

| Consumer | Schema | How History is Used |
|----------|--------|-------------------|
| dbo.V_RiskClassification | dbo | CTE reads History.T_RiskClassification for PreviousRisk |
| dbo.V_RiskClassificationDataLake | dbo | Same CTE pattern |
| dbo.V_RiskClassification_4_SynapseExport3 | dbo | Direct FROM History.T_RiskClassification |
| dbo.V_RiskClassification_History | dbo | Direct FROM History.T_RiskClassification |

---

*Generated: 2026-04-14 | Objects: 7 (6 tables, 1 view) | Average quality: 8.6*
