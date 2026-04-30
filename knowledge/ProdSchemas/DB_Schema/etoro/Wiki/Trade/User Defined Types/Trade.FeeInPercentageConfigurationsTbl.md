# Trade.FeeInPercentageConfigurationsTbl

> TVP for inserting new percentage-based fee configurations and for validation; includes FeeOperationTypeID and IsSettled for scope.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID, InstrumentTypeID, GroupID, FeeOperationTypeID |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.FeeInPercentageConfigurationsTbl is a table-valued parameter for inserting new percentage-based fee configurations and for pre-insert validation. FeeOperationTypeID determines when the fee applies (open, close, overnight, etc.). IsSettled distinguishes real stock (1) vs CFD (0) positions. FeeValue uses dbo.dtPrice.

Trade.AddFeeInPercentageConfigurations and Trade.FeeInPercentageConfigurationsTblValidate both accept this TVP via the @ConfigTable parameter. The validate procedure checks for duplicate or conflicting configurations before insert.

---

## 2. Business Logic

### 2.1 New fee configuration insert and validation

**What**: Each row defines a new fee config. AddFeeInPercentageConfigurations inserts; FeeInPercentageConfigurationsTblValidate checks for conflicts.

**Columns/Parameters Involved**: InstrumentID, InstrumentTypeID, FeeValue, FeeOperationTypeID, GroupID, IsSettled

**Rules**: FeeOperationTypeID required. IsSettled: 1=real stock, 0=CFD. Scope via InstrumentID/InstrumentTypeID/GroupID. Validate before add to avoid duplicates.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | Yes | - | 10 | Instrument scope |
| 2 | InstrumentTypeID | int | Yes | - | 10 | Instrument type scope |
| 3 | FeeValue | dbo.dtPrice | No | - | 10 | Percentage fee value |
| 4 | FeeOperationTypeID | tinyint | No | - | 10 | When fee applies (open/close/overnight) |
| 5 | GroupID | int | Yes | - | 10 | Instrument group scope |
| 6 | IsSettled | bit | Yes | - | 10 | 1=real stock, 0=CFD |

---

## 5. Relationships

### 5.1 References To

| Target | Role |
|--------|------|
| Trade.FeeInPercentageConfigurations | Target table for insert |
| Trade.Instrument (InstrumentID) | Implicit reference |
| Trade.InstrumentGroups (GroupID) | Implicit reference |
| Fee operation type dictionary | FeeOperationTypeID |

### 5.2 Referenced By

| Consumer | Usage |
|----------|-------|
| Trade.AddFeeInPercentageConfigurations | Parameter @ConfigTable |
| Trade.FeeInPercentageConfigurationsTblValidate | Parameter @ConfigTable |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

- dbo.dtPrice (scalar type for FeeValue)

### 6.2 Objects That Depend On This

- Trade.AddFeeInPercentageConfigurations
- Trade.FeeInPercentageConfigurationsTblValidate

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Add new fee configurations

```sql
DECLARE @ConfigTable Trade.FeeInPercentageConfigurationsTbl;
INSERT INTO @ConfigTable (InstrumentID, InstrumentTypeID, FeeValue, FeeOperationTypeID, GroupID, IsSettled)
VALUES (100, NULL, 0.15, 1, NULL, 1), (NULL, 5, 0.20, 2, NULL, 0);
EXEC Trade.AddFeeInPercentageConfigurations @ConfigTable = @ConfigTable;
```

### 8.2 Validate before insert

```sql
DECLARE @C Trade.FeeInPercentageConfigurationsTbl;
INSERT INTO @C (InstrumentID, FeeValue, FeeOperationTypeID, IsSettled)
VALUES (200, 0.25, 1, 1);
EXEC Trade.FeeInPercentageConfigurationsTblValidate @ConfigTable = @C;
```

### 8.3 List type columns including dtPrice

```sql
SELECT c.name, t.name AS type_name
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE tt.name = 'FeeInPercentageConfigurationsTbl';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10, Logic: 5, Relationships: 8, Sources: 4)*
*Confidence: High (DDL + procedure references)*
*Sources: DDL, Trade.AddFeeInPercentageConfigurations, Trade.FeeInPercentageConfigurationsTblValidate*
*Object: Trade.FeeInPercentageConfigurationsTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.FeeInPercentageConfigurationsTbl.sql*
