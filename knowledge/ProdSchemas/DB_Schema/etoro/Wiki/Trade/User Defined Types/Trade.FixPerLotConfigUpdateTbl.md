# Trade.FixPerLotConfigUpdateTbl

> TVP for updating existing fix-per-lot fee configurations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | DBRowID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.FixPerLotConfigUpdateTbl is a table-valued parameter used to update existing rows in Trade.FixPerLotConfigurations. It parallels FeeInPercentageConfigUpdateTbl but applies to the fixed-per-lot fee model rather than percentage-based fees. Each row targets an existing configuration by DBRowID (primary key) and supplies new values for scope (InstrumentID, InstrumentTypeID, GroupID) and FeeValue (the fixed fee amount per lot).

The type supports batch updates when fee schedules change. FeeValue is decimal(16,4), allowing precise fixed fees per lot traded. DBRowID identifies which configuration row to update; the scope columns and FeeValue are the new values to persist. Used exclusively by Trade.UpdateFixPerLotConfigurations via parameter @ConfigTable.

---

## 2. Business Logic

### 2.1 Fix-Per-Lot Fee Update
**What**: Updates existing fix-per-lot fee configuration rows with new fee amounts and optional scope.
**Columns/Parameters Involved**: DBRowID, InstrumentID, InstrumentTypeID, GroupID, FeeValue.
**Rules**: DBRowID must exist in Trade.FixPerLotConfigurations. FeeValue is NOT NULL. Scope columns (InstrumentID, InstrumentTypeID, GroupID) are nullable; non-NULL values override existing scope for the target row.

---

## 3. Data Overview
N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements
| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DBRowID | int | NOT NULL | - | High | Primary key of Trade.FixPerLotConfigurations |
| 2 | InstrumentID | int | NULL | - | High | Instrument scope; references Trade.Instrument |
| 3 | InstrumentTypeID | int | NULL | - | High | Instrument type scope |
| 4 | GroupID | int | NULL | - | High | Group scope for fee applicability |
| 5 | FeeValue | decimal(16,4) | NOT NULL | - | High | Fixed fee amount per lot |

---

## 5. Relationships
### 5.1 References To
Trade.FixPerLotConfigurations, Trade.Instrument
### 5.2 Referenced By
Trade.UpdateFixPerLotConfigurations (parameter @ConfigTable)

---

## 6. Dependencies
### 6.0 Dependency Chain
This object has no dependencies.
### 6.1 Objects This Depends On
No dependencies.
### 6.2 Objects That Depend On This
Trade.UpdateFixPerLotConfigurations

---

## 7. Technical Details
### 7.1 Indexes
None.
### 7.2 Constraints
None.

---

## 8. Sample Queries
### 8.1 Update Single Config
```sql
DECLARE @ConfigTable Trade.FixPerLotConfigUpdateTbl;
INSERT INTO @ConfigTable (DBRowID, InstrumentID, InstrumentTypeID, GroupID, FeeValue)
VALUES (201, 5001, 1, 10, 2.5000);
EXEC Trade.UpdateFixPerLotConfigurations @ConfigTable = @ConfigTable;
```
### 8.2 Batch Update from Calculation
```sql
DECLARE @ConfigTable Trade.FixPerLotConfigUpdateTbl;
INSERT INTO @ConfigTable (DBRowID, InstrumentID, InstrumentTypeID, GroupID, FeeValue)
SELECT DBRowID, InstrumentID, InstrumentTypeID, GroupID, FeeValue * 1.1
FROM Trade.FixPerLotConfigurations WHERE GroupID = 5;
EXEC Trade.UpdateFixPerLotConfigurations @ConfigTable = @ConfigTable;
```
### 8.3 Update Fee Value Only
```sql
DECLARE @ConfigTable Trade.FixPerLotConfigUpdateTbl;
INSERT INTO @ConfigTable (DBRowID, FeeValue)
VALUES (42, 3.2500);
EXEC Trade.UpdateFixPerLotConfigurations @ConfigTable = @ConfigTable;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FixPerLotConfigUpdateTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.FixPerLotConfigUpdateTbl.sql*
