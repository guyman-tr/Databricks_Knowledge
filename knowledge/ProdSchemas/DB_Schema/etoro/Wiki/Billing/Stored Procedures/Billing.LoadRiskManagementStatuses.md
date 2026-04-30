# Billing.LoadRiskManagementStatuses

> Data loader intended to return all rows from Billing.RiskManagementStatus - currently broken because the source table does not exist in the database or SSDT repository.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - intended to return Billing.RiskManagementStatus table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadRiskManagementStatuses is a bulk data loader intended to return all rows from Billing.RiskManagementStatus for the billing engine's risk management status cache. However, the table `Billing.RiskManagementStatus` does not exist in the database or in the SSDT source repository.

**CRITICAL DEFECT**: Executing this procedure raises "Invalid object name 'Billing.RiskManagementStatus'". The table has likely been renamed, dropped, or never deployed. The existing risk management tables in the Billing schema are `Billing.RiskManagementCheck` and `Billing.RiskManagementConfiguration`, neither of which matches the name referenced in this procedure.

This suggests the procedure is a legacy artifact from an older version of the risk management subsystem. The billing engine may have been updated to use a different risk status mechanism, or the Load* procedure was left in place after the underlying table was removed.

---

## 2. Business Logic

### 2.1 Broken Reference - Table Does Not Exist

**What**: The procedure references a table that does not exist in the database or SSDT repository.

**Columns/Parameters Involved**: (none - no parameters)

**Rules**:
- Code: `SELECT * FROM Billing.RiskManagementStatus WITH (NOLOCK)` - table does not exist.
- Executing this procedure raises: "Invalid object name 'Billing.RiskManagementStatus'".
- Related existing tables: Billing.RiskManagementCheck (checks), Billing.RiskManagementConfiguration (configuration) - neither matches the intended name.
- The procedure is likely a legacy artifact from an earlier architecture.

**Diagram**:
```
Billing.LoadRiskManagementStatuses
        |
        v [FAILS - object not found]
Billing.RiskManagementStatus (does NOT exist)

Existing related tables (not what this SP references):
  Billing.RiskManagementCheck
  Billing.RiskManagementConfiguration
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no input parameters) | - | - | - | - | - | This procedure takes no parameters. |
| RETURN | int | NO | - | CODE-BACKED | Intended to return 0 - currently fails before reaching RETURN. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT *) | Billing.RiskManagementStatus | READ (BROKEN) | References a non-existent table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing Engine (BILLING_MANAGER role) | - | EXEC | Permission exists but procedure fails on execution. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadRiskManagementStatuses (procedure)
└── Billing.RiskManagementStatus (DOES NOT EXIST)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.RiskManagementStatus | Table | SELECT * (BROKEN - table does not exist in DB or SSDT repository). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing Engine (BILLING_MANAGER) | Application | EXEC - permission granted but procedure fails on execution. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 View existing related risk management tables (as alternatives)
```sql
-- RiskManagementCheck (available)
SELECT TOP 5 * FROM Billing.RiskManagementCheck WITH (NOLOCK);
-- RiskManagementConfiguration (available)
SELECT TOP 5 * FROM Billing.RiskManagementConfiguration WITH (NOLOCK);
```

### 8.2 Verify the broken reference
```sql
-- This will fail: "Invalid object name 'Billing.RiskManagementStatus'"
EXEC Billing.LoadRiskManagementStatuses;
```

### 8.3 Check if table exists in sys.objects
```sql
SELECT name, type_desc, create_date
FROM sys.objects WITH (NOLOCK)
WHERE schema_id = SCHEMA_ID('Billing')
  AND name LIKE 'RiskManagement%'
ORDER BY name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 6.5/10 (Elements: 10/10, Logic: 4/10, Relationships: 3/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadRiskManagementStatuses | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadRiskManagementStatuses.sql*
