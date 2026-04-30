# Trade.FeeInPercentageConfigUpdateTbl

> TVP for updating existing percentage-based fee configurations; DBRowID targets specific rows in Trade.FeeInPercentageConfigurations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | DBRowID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.FeeInPercentageConfigUpdateTbl is a table-valued parameter for updating existing percentage-based fee configurations. DBRowID is the primary key of the row in Trade.FeeInPercentageConfigurations being updated. FeeValue uses the custom dbo.dtPrice scalar type (decimal for price values).

InstrumentID, InstrumentTypeID, and GroupID identify the fee scope. The configuration can be instrument-specific, type-wide, or group-wide. Trade.UpdateFeeInPercentageConfigurations accepts this TVP via the @ConfigTable parameter.

---

## 2. Business Logic

### 2.1 Fee configuration update by row

**What**: Each row identifies a config row by DBRowID and supplies new values. The procedure updates the matching rows in FeeInPercentageConfigurations.

**Columns/Parameters Involved**: DBRowID, InstrumentID, InstrumentTypeID, GroupID, FeeValue

**Rules**: DBRowID must match an existing row. FeeValue uses dbo.dtPrice. Scope columns determine applicability (instrument/type/group).

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DBRowID | int | No | - | 10 | PK of Trade.FeeInPercentageConfigurations row |
| 2 | InstrumentID | int | Yes | - | 10 | Instrument scope (nullable = any) |
| 3 | InstrumentTypeID | int | Yes | - | 10 | Instrument type scope |
| 4 | GroupID | int | Yes | - | 10 | Instrument group scope |
| 5 | FeeValue | dbo.dtPrice | No | - | 10 | Percentage fee value |

---

## 5. Relationships

### 5.1 References To

| Target | Role |
|--------|------|
| Trade.FeeInPercentageConfigurations (DBRowID) | Target row for update |
| Trade.Instrument (InstrumentID) | Implicit reference |
| Trade.InstrumentGroups (GroupID) | Implicit reference |

### 5.2 Referenced By

| Consumer | Usage |
|----------|-------|
| Trade.UpdateFeeInPercentageConfigurations | Parameter @ConfigTable |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

- dbo.dtPrice (scalar type for FeeValue)

### 6.2 Objects That Depend On This

- Trade.UpdateFeeInPercentageConfigurations

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update fee values by DBRowID

```sql
DECLARE @ConfigTable Trade.FeeInPercentageConfigUpdateTbl;
INSERT INTO @ConfigTable (DBRowID, InstrumentID, InstrumentTypeID, GroupID, FeeValue)
VALUES (1, 100, NULL, NULL, 0.25), (2, NULL, 5, NULL, 0.30);
EXEC Trade.UpdateFeeInPercentageConfigurations @ConfigTable = @ConfigTable;
```

### 8.2 Build update from config table

```sql
DECLARE @C Trade.FeeInPercentageConfigUpdateTbl;
INSERT INTO @C (DBRowID, FeeValue)
SELECT DBRowID, FeeValue * 1.05
FROM Trade.FeeInPercentageConfigurations
WHERE InstrumentTypeID = @TypeID;
EXEC Trade.UpdateFeeInPercentageConfigurations @ConfigTable = @C;
```

### 8.3 Check type and dtPrice usage

```sql
SELECT c.name, t.name AS type_name
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE tt.name = 'FeeInPercentageConfigUpdateTbl';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10, Logic: 5, Relationships: 8, Sources: 4)*
*Confidence: High (DDL + procedure reference)*
*Sources: DDL, Trade.UpdateFeeInPercentageConfigurations procedure*
*Object: Trade.FeeInPercentageConfigUpdateTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.FeeInPercentageConfigUpdateTbl.sql*
