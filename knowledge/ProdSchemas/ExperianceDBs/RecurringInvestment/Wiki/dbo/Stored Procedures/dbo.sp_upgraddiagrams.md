# dbo.sp_upgraddiagrams

> Stored procedure that initializes the database diagram subsystem by creating the sysdiagrams table and migrating any legacy dtproperties-based diagrams.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.sp_upgraddiagrams is a SQL Server system-generated stored procedure that ensures the database diagram infrastructure is properly set up. It is automatically created when database diagramming is first used in SSMS. This is not a business object -- it supports the SSMS visual diagram feature.

The procedure handles two scenarios: creating the sysdiagrams table from scratch when it does not exist, and migrating legacy diagrams stored in the deprecated dtproperties table (used in SQL Server 2000 and earlier) into the modern sysdiagrams format.

---

## 2. Business Logic

### 2.1 Diagram Table Initialization

**What**: Creates or upgrades the sysdiagrams table used to store database diagrams.

**Columns/Parameters Involved**: None (no parameters).

**Rules**:
- If dbo.sysdiagrams already exists, returns 0 (no action needed)
- If dbo.dtproperties exists (legacy SQL Server 2000 diagram storage), migrates diagrams to the new sysdiagrams table and returns 2
- If neither table exists, creates sysdiagrams fresh and returns 1
- The sysdiagrams table contains columns: name, principal_id, diagram_id (identity), version, definition (varbinary(max))
- Migration from dtproperties preserves diagram names, ownership, and binary definitions

### 2.2 Return Values

| Return Value | Meaning |
|--------------|---------|
| 0 | sysdiagrams already exists, no action taken |
| 1 | sysdiagrams created fresh (no legacy data) |
| 2 | sysdiagrams created and legacy dtproperties diagrams migrated |

---

## 3. Data Overview

N/A for system procedure. This procedure creates/modifies the dbo.sysdiagrams table structure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RETURN | int | NO | - | VERIFIED | Status code: 0 = already exists, 1 = created, 2 = migrated from dtproperties. |

This procedure takes no input parameters.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Object | Type | Relationship |
|--------|------|-------------|
| dbo.sysdiagrams | Table | Creates this table if not exists |
| dbo.dtproperties | Table | Reads legacy diagrams for migration (if table exists) |

### 5.2 Referenced By (other objects point to this)

| Object | Type | Relationship |
|--------|------|-------------|
| dbo.fn_diagramobjects | Function | Checks for existence of this procedure (bit 1) |

Called by SSMS when initializing diagram support for the first time.

---

## 6. Dependencies

### 6.0 Dependency Chain

No hard dependencies. Checks for table existence before acting.

### 6.1 Objects This Depends On

No required dependencies. Optionally reads from dbo.dtproperties if it exists.

### 6.2 Objects That Depend On This

All other diagram procedures depend on the sysdiagrams table that this procedure creates.

---

## 7. Technical Details

- **Execution Context**: Standard execution (no EXECUTE AS clause)
- **Transaction Handling**: DDL operations (CREATE TABLE) are auto-committed
- **Idempotent**: Yes -- safe to run multiple times; returns 0 if already initialized
- **Side Effects**: Creates dbo.sysdiagrams table on first run

---

## 8. Sample Queries

### 8.1 Initialize diagram support
```sql
EXEC dbo.sp_upgraddiagrams
-- Returns 0 if already set up, 1 if created fresh, 2 if migrated
```

### 8.2 Check and initialize in a script
```sql
IF dbo.fn_diagramobjects() & 2 = 0
BEGIN
    EXEC dbo.sp_upgraddiagrams
    PRINT 'Diagram support initialized.'
END
ELSE
    PRINT 'Diagram support already present.'
```

### 8.3 Verify sysdiagrams exists after upgrade
```sql
EXEC dbo.sp_upgraddiagrams
SELECT OBJECT_ID('dbo.sysdiagrams') AS SysdiagramsObjectId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Standard SQL Server system procedure.

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: dbo.sp_upgraddiagrams | Type: Stored Procedure | Source: RecurringInvestment/dbo/Stored Procedures/dbo.sp_upgraddiagrams.sql*
