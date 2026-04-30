# BILoad.TruncateLoadTable

> Utility procedure that dynamically truncates a named BILoad staging table, using EXECUTE AS OWNER for elevated permissions and QUOTENAME for SQL injection prevention, then logs the action to the progress log.

| Property | Value |
|----------|-------|
| **Schema** | BILoad |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Dynamic TRUNCATE TABLE on BILoad schema tables |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BILoad.TruncateLoadTable is a utility procedure that clears a named BILoad staging table between ADF pipeline runs. Instead of having separate TRUNCATE statements for each staging table, this single procedure accepts a table name parameter and dynamically builds the TRUNCATE command. Azure Data Factory calls this procedure before loading new data to ensure staging tables are empty.

This procedure exists because TRUNCATE TABLE requires ALTER TABLE permission, which the ADF service account may not have directly. By using `EXECUTE AS OWNER`, the procedure elevates its permissions to the schema owner's level, allowing the truncation to succeed. The dynamic SQL approach also centralizes the truncation pattern - ADF can clear any BILoad table by passing its name, without needing a dedicated procedure per table.

Called by Azure Data Factory before each pipeline run. ADF truncates BILoad.HistoryClosedPosition and BILoad.RevsharePositionSummary to prepare them for fresh data. After each truncation, the procedure logs the action to BILoad.Progress_Log via BILoad.UpdateProgress_Log.

---

## 2. Business Logic

### 2.1 Dynamic Truncation with Security

**What**: Builds and executes a dynamic TRUNCATE TABLE command with SQL injection prevention.

**Columns/Parameters Involved**: `@TableName`

**Rules**:
- Command format: `TRUNCATE TABLE [BILoad].[{@TableName}]`
- QUOTENAME(@TableName) wraps the table name in square brackets and escapes any embedded brackets - prevents SQL injection
- Schema is hardcoded to [BILoad] - this procedure can ONLY truncate tables in the BILoad schema
- EXECUTE AS OWNER elevates permissions to the schema owner for the duration of the procedure
- sp_executesql executes the dynamic command

**Diagram**:
```
ADF Pipeline
    |
    | EXEC BILoad.TruncateLoadTable 'HistoryClosedPosition'
    | EXEC BILoad.TruncateLoadTable 'RevsharePositionSummary'
    v
TruncateLoadTable(@TableName)
    |
    | 1. Build: 'TRUNCATE TABLE [BILoad].[HistoryClosedPosition]'
    | 2. EXEC sp_executesql @V_Command
    | 3. EXEC UpdateProgress_Log @V_Command, NULL
    v
Staging tables cleared + action logged
```

### 2.2 Permission Elevation via EXECUTE AS OWNER

**What**: The procedure runs with the permissions of the schema owner to execute TRUNCATE TABLE.

**Columns/Parameters Involved**: `@TableName`

**Rules**:
- TRUNCATE TABLE requires ALTER TABLE permission on the target table
- The ADF service account likely only has EXECUTE permission on stored procedures
- EXECUTE AS OWNER temporarily assumes the schema owner's identity for the procedure's execution
- This is a security pattern: rather than granting ALTER TABLE to the service account, the permission is encapsulated in a controlled procedure that only truncates BILoad tables

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TableName | nvarchar(50) | NO | - | CODE-BACKED | Name of the BILoad table to truncate (without schema prefix). Wrapped in QUOTENAME() for SQL injection prevention. Only tables in the BILoad schema can be targeted (schema is hardcoded). Expected values: 'HistoryClosedPosition', 'RevsharePositionSummary'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | BILoad.UpdateProgress_Log | EXEC (caller) | Logs the truncation command after execution |
| @TableName | BILoad.* tables (dynamic) | TRUNCATE (dynamic SQL) | Truncates the named table via sp_executesql |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Azure Data Factory (external) | - | Caller | ADF calls this before each pipeline run to clear staging tables |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BILoad.TruncateLoadTable (procedure)
+-- BILoad.UpdateProgress_Log (procedure)
      +-- BILoad.Progress_Log (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BILoad.UpdateProgress_Log | Stored Procedure | EXEC - logs the truncation action |
| BILoad.HistoryClosedPosition | Table | Dynamic TRUNCATE target (via @TableName parameter) |
| BILoad.RevsharePositionSummary | Table | Dynamic TRUNCATE target (via @TableName parameter) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Azure Data Factory (external) | External | Calls this procedure to clear staging tables before loading |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS OWNER | Security | Procedure runs with schema owner permissions to allow TRUNCATE TABLE without granting ALTER to callers |
| QUOTENAME(@TableName) | Injection Prevention | Wraps table name in brackets and escapes embedded brackets to prevent SQL injection in dynamic SQL |

---

## 8. Sample Queries

### 8.1 Truncate the HistoryClosedPosition staging table
```sql
EXEC BILoad.TruncateLoadTable 'HistoryClosedPosition'
```

### 8.2 Truncate the RevsharePositionSummary staging table
```sql
EXEC BILoad.TruncateLoadTable 'RevsharePositionSummary'
```

### 8.3 Verify the truncation was logged
```sql
SELECT TOP 5 StepName, StartDate
FROM BILoad.Progress_Log WITH (NOLOCK)
WHERE StepName LIKE 'TRUNCATE TABLE%'
ORDER BY ID DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-5265 (referenced in SQL comments) | Jira | Original ticket for ADF pipeline implementation by Noga (Feb 2026). Created this utility procedure for staging table cleanup. |

No direct Confluence pages found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 1 Jira (ref only) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BILoad.TruncateLoadTable | Type: Stored Procedure | Source: fiktivo/BILoad/Stored Procedures/BILoad.TruncateLoadTable.sql*
