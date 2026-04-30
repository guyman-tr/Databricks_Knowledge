# Trade.FeeInPercentageConfigurationsTblValidate

> Validates a batch of percentage-based fee configurations (up to 1000 rows) by iterating through each row and calling Trade.ValidateFeeInPercentageConfigurations for individual validation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ConfigTable (TVP containing fee configurations to validate) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FeeInPercentageConfigurationsTblValidate is a batch validation wrapper for percentage-based fee configurations. When fee schedules are uploaded or modified in bulk (e.g., via a configuration file), this procedure validates each row before the configurations are applied. It enforces a maximum of 1000 rows per batch and delegates individual row validation to Trade.ValidateFeeInPercentageConfigurations.

Fee-in-percentage configurations define fees as a percentage of the trade amount (as opposed to fixed-per-lot fees). These fees can be scoped by InstrumentID, InstrumentTypeID, GroupID, and IsSettled flag, covering different fee operation types (e.g., overnight, weekend, spread-based).

---

## 2. Business Logic

### 2.1 Batch Size Validation

**What**: Rejects batches exceeding 1000 rows.

**Rules**:
- If @@ROWCOUNT > 1000 after inserting into temp table: RAISERROR
- Prevents excessively large configuration uploads

### 2.2 Row-by-Row Validation Loop

**What**: Validates each fee configuration row individually.

**Columns/Parameters Involved**: `InstrumentID`, `InstrumentTypeID`, `GroupID`, `FeeValue`, `FeeOperationTypeID`, `IsSettled`

**Rules**:
- Iterates using WHILE loop with identity-based ID counter
- Calls Trade.ValidateFeeInPercentageConfigurations for each row
- On any validation failure: THROW propagates the error and stops processing
- FeeValue is DECIMAL(16,8) - high precision for percentage fees

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ConfigTable | Trade.FeeInPercentageConfigurationsTbl (TVP, READONLY) | NO | - | CODE-BACKED | Table-Valued Parameter containing fee configuration rows to validate. Each row specifies a fee scope (InstrumentID/InstrumentTypeID/GroupID/IsSettled) and the percentage fee value with its operation type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Row data | Trade.ValidateFeeInPercentageConfigurations | EXEC | Validates each individual fee configuration row |
| - | Trade.FeeInPercentageConfigurationsTbl | Type | User-Defined Table Type for the TVP parameter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.AddFeeInPercentageConfigurations | (upstream) | EXEC | Calls this as pre-insert validation |
| Fee upload pipeline | External | EXEC | Called during bulk fee configuration uploads |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FeeInPercentageConfigurationsTblValidate (procedure)
+-- Trade.ValidateFeeInPercentageConfigurations (procedure)
+-- Trade.FeeInPercentageConfigurationsTbl (user-defined table type)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ValidateFeeInPercentageConfigurations | Procedure | EXEC - individual row validation |
| Trade.FeeInPercentageConfigurationsTbl | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.AddFeeInPercentageConfigurations | Procedure | Calls this for pre-insert validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| 1000-row limit | Safety | RAISERROR if batch exceeds 1000 rows |
| WHILE loop | Pattern | Row-by-row processing with identity counter |
| TRY/CATCH with THROW | Error handling | First validation failure stops all processing |

---

## 8. Sample Queries

### 8.1 Check existing percentage-based fee configurations

```sql
SELECT TOP 20 InstrumentID, InstrumentTypeID, GroupID, FeeValue, FeeOperationTypeID, IsSettled
FROM   Trade.FeeInPercentageConfigurations WITH (NOLOCK)
ORDER BY InstrumentID, FeeOperationTypeID;
```

### 8.2 View fee operation types

```sql
SELECT DISTINCT FeeOperationTypeID
FROM   Trade.FeeInPercentageConfigurations WITH (NOLOCK)
ORDER BY FeeOperationTypeID;
```

### 8.3 Validate a single fee configuration manually

```sql
EXEC Trade.ValidateFeeInPercentageConfigurations
    @InstrumentID = 1001,
    @InstrumentTypeID = 5,
    @GroupID = 1,
    @FeeOperationTypeID = 1,
    @IsSettled = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FeeInPercentageConfigurationsTblValidate | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.FeeInPercentageConfigurationsTblValidate.sql*
