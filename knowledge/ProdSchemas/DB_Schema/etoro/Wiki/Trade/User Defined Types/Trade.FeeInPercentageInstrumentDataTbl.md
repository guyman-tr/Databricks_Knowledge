# Trade.FeeInPercentageInstrumentDataTbl

> TVP for identifying percentage-based fee configuration rows to delete.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | DBRowID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.FeeInPercentageInstrumentDataTbl is a table-valued parameter type used when deleting fee configurations from Trade.FeeInPercentageConfigurations. The type carries only identity columns needed to target rows for removal: DBRowID (primary key of the config table) plus InstrumentID, InstrumentTypeID, and GroupID for fee scope identification.

Unlike insert or update TVPs, this type does not include FeeValue because deletions only require row identity. The caller populates the TVP with the DBRowID values (and optional scope columns) of configurations to remove, then passes it to Trade.DeleteFeeInPercentageConfigurations. This supports batch delete operations where multiple percentage-based fee rules are retired at once.

---

## 2. Business Logic

### 2.1 Deletion Targeting
**What**: Identifies which fee configuration rows to delete from Trade.FeeInPercentageConfigurations.
**Columns/Parameters Involved**: DBRowID, InstrumentID, InstrumentTypeID, GroupID.
**Rules**: DBRowID must exist in Trade.FeeInPercentageConfigurations. InstrumentID, InstrumentTypeID, GroupID provide scope context but deletion is driven by DBRowID.

---

## 3. Data Overview
N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements
| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DBRowID | int | NOT NULL | - | High | Primary key of Trade.FeeInPercentageConfigurations |
| 2 | InstrumentID | int | NULL | - | High | Instrument scope; references Trade.Instrument |
| 3 | InstrumentTypeID | int | NULL | - | High | Instrument type scope |
| 4 | GroupID | int | NULL | - | High | Group scope for fee applicability |

---

## 5. Relationships
### 5.1 References To
Trade.FeeInPercentageConfigurations, Trade.Instrument
### 5.2 Referenced By
Trade.DeleteFeeInPercentageConfigurations (parameter @ConfigTable)

---

## 6. Dependencies
### 6.0 Dependency Chain
This object has no dependencies.
### 6.1 Objects This Depends On
No dependencies.
### 6.2 Objects That Depend On This
Trade.DeleteFeeInPercentageConfigurations

---

## 7. Technical Details
### 7.1 Indexes
None.
### 7.2 Constraints
None.

---

## 8. Sample Queries
### 8.1 Populate TVP for Delete
```sql
DECLARE @ConfigTable Trade.FeeInPercentageInstrumentDataTbl;
INSERT INTO @ConfigTable (DBRowID, InstrumentID, InstrumentTypeID, GroupID)
VALUES (101, 5001, 1, 10);
EXEC Trade.DeleteFeeInPercentageConfigurations @ConfigTable = @ConfigTable;
```
### 8.2 Batch Delete from Config Table
```sql
DECLARE @ConfigTable Trade.FeeInPercentageInstrumentDataTbl;
INSERT INTO @ConfigTable (DBRowID, InstrumentID, InstrumentTypeID, GroupID)
SELECT DBRowID, InstrumentID, InstrumentTypeID, GroupID
FROM Trade.FeeInPercentageConfigurations
WHERE FeeValue < 0.001;
EXEC Trade.DeleteFeeInPercentageConfigurations @ConfigTable = @ConfigTable;
```
### 8.3 Single Row Delete
```sql
DECLARE @ConfigTable Trade.FeeInPercentageInstrumentDataTbl;
INSERT INTO @ConfigTable (DBRowID)
VALUES (42);
EXEC Trade.DeleteFeeInPercentageConfigurations @ConfigTable = @ConfigTable;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FeeInPercentageInstrumentDataTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.FeeInPercentageInstrumentDataTbl.sql*
