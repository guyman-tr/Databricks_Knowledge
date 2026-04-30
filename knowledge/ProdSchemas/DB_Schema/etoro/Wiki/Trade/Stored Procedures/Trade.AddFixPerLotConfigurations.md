# Trade.AddFixPerLotConfigurations

> Inserts new fixed-per-lot fee configurations in bulk after validating the batch via Trade.FixPerLotConfigurationsTblValidate.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ConfigTable (TVP containing fee rows to insert) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.AddFixPerLotConfigurations is the INSERT entry point for fixed-per-lot fee schedules. Fixed-per-lot fees are charged as a flat monetary amount per lot traded (as opposed to percentage-based fees defined in Trade.FeeInPercentageConfigurations). These configurations are scoped by instrument, instrument type, group, settlement type (real stock vs CFD), and fee operation type (open, close, or all).

Without this procedure, operations teams would have no validated bulk-insert path for fixed-per-lot fee rules. The validation step (Trade.FixPerLotConfigurationsTblValidate) prevents invalid combinations from entering the system, which would cause incorrect fee calculations at trade time.

The procedure is called from the Trading Opstool (admin API) when operations staff upload or add fee schedules. The inserted rows are then read at trade time by the CostConfigurationProvider service via Trade.GetAllFixPerLotConfigurations, cached in InstrumentFixPerLotCache for low-latency fee lookups during position open/close flows.

---

## 2. Business Logic

### 2.1 Validate-Then-Insert Pattern

**What**: All-or-nothing batch insert with pre-validation.

**Columns/Parameters Involved**: `@ConfigTable`, `@AppLoginName`

**Rules**:
- The entire TVP is passed to Trade.FixPerLotConfigurationsTblValidate first
- If validation fails (any row invalid), THROW propagates the error and no rows are inserted
- On success, all rows are inserted in a single INSERT...SELECT from the TVP
- DataUpdated is set to GETUTCDATE() for every row (not caller-supplied)

### 2.2 Audit Trail via CONTEXT_INFO

**What**: Captures the calling user's identity for temporal table history tracking.

**Columns/Parameters Involved**: `@AppLoginName`

**Rules**:
- @AppLoginName is cast to VARBINARY(128) and stored via SET CONTEXT_INFO
- The target table has a computed column `AppLoginName = CONVERT(varchar(500), context_info())` that reads this value
- Combined with DbLoginName (suser_name()) and system-versioning (SysStartTime/SysEndTime), this creates a full audit trail

### 2.3 Fee Value Precision

**What**: Fixed-per-lot fees use DECIMAL(16,4) precision.

**Rules**:
- Lower precision than percentage fees (which use DECIMAL(16,8)) since fixed fees represent monetary amounts, not ratios
- FeeValue is the absolute amount charged per lot in the trade's currency

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ConfigTable | Trade.FixPerLotConfigurationsTbl (TVP, READONLY) | NO | - | VERIFIED | Table-Valued Parameter containing fixed-per-lot fee configuration rows to insert. Each row specifies a fee scope (InstrumentID, InstrumentTypeID, GroupID, IsSettled) and the fixed fee value per lot with its operation type. Maps to FixPerLotConfiguration entity in application code (Source: trading-shared). |
| 2 | @AppLoginName | nvarchar(100) | YES | '' | CODE-BACKED | Name of the application-level user performing the insert (e.g., ops tool operator). Stored via CONTEXT_INFO so the target table's computed AppLoginName column captures it for audit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ConfigTable | Trade.FixPerLotConfigurationsTbl | Type | User-Defined Table Type for the TVP parameter |
| Validation | Trade.FixPerLotConfigurationsTblValidate | EXEC | Pre-insert batch validation - rejects invalid fee configurations |
| INSERT | Trade.FixPerLotConfigurations | INSERT | Target table for the fee configuration rows (system-versioned with History.FixPerLotConfigurations) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading Opstool API | External | EXEC | Admin tool calls this SP to add fixed-per-lot fee configurations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AddFixPerLotConfigurations (procedure)
+-- Trade.FixPerLotConfigurationsTblValidate (procedure)
|     +-- Trade.ValidateFixPerLotConfigurations (procedure)
|     +-- Trade.FixPerLotConfigurationsTbl (user-defined table type)
+-- Trade.FixPerLotConfigurations (table)
+-- Trade.FixPerLotConfigurationsTbl (user-defined table type)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FixPerLotConfigurationsTblValidate | Procedure | EXEC - validates all rows before insert |
| Trade.FixPerLotConfigurations | Table | INSERT INTO - target for fee configuration rows |
| Trade.FixPerLotConfigurationsTbl | UDT | TVP parameter type definition |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading Opstool API | External | Calls this SP to bulk-add fixed-per-lot fee configurations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH with THROW | Error handling | Validation errors from FixPerLotConfigurationsTblValidate propagate to caller |
| CONTEXT_INFO | Audit | @AppLoginName stored in session context for computed column capture |

---

## 8. Sample Queries

### 8.1 View current fixed-per-lot fee configurations with operation type names

```sql
SELECT  f.ID, f.InstrumentID, f.InstrumentTypeID, f.GroupID,
        f.IsSettled, f.FeeValue, fot.Name AS FeeOperationType,
        f.DataUpdated, f.AppLoginName
FROM    Trade.FixPerLotConfigurations f WITH (NOLOCK)
JOIN    Dictionary.FeeOperationTypes fot WITH (NOLOCK)
        ON f.FeeOperationTypeID = fot.FeeOperationTypeID
ORDER BY f.InstrumentID, f.FeeOperationTypeID;
```

### 8.2 Check history of fixed-per-lot fee configuration changes (temporal query)

```sql
SELECT  ID, InstrumentID, FeeValue, FeeOperationTypeID,
        AppLoginName, SysStartTime, SysEndTime
FROM    Trade.FixPerLotConfigurations
FOR SYSTEM_TIME ALL
WHERE   InstrumentID = 1001
ORDER BY SysStartTime DESC;
```

### 8.3 Prepare a TVP for testing this SP

```sql
DECLARE @Config Trade.FixPerLotConfigurationsTbl;
INSERT INTO @Config (InstrumentID, InstrumentTypeID, GroupID, FeeValue, FeeOperationTypeID, IsSettled)
VALUES (1001, 5, 1, 2.5000, 1, 0);

EXEC Trade.AddFixPerLotConfigurations @ConfigTable = @Config, @AppLoginName = 'admin_user';
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Trading Opstool API TDD | Confluence | Confirms this SP is part of the Trading Opstool admin API for fee configuration management |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 3 files | Corrections: 0 applied*
*Object: Trade.AddFixPerLotConfigurations | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AddFixPerLotConfigurations.sql*
