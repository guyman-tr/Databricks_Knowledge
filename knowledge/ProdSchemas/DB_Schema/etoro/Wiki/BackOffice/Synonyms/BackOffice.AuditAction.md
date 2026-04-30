# BackOffice.AuditAction

> Synonym that provides a local alias for the AuditAction table in the DB_Logs database, allowing BackOffice procedures to write audit trail records without cross-database schema references.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Synonym |
| **Key Identifier** | N/A (synonym - see target) |
| **Partition** | N/A |
| **Indexes** | N/A (defined on target table) |

---

## 1. Business Meaning

`BackOffice.AuditAction` is a synonym that transparently redirects all reads and writes to `[DB_Logs].[BackOffice].[AuditAction]` - a table in the separate `DB_Logs` database. This allows BackOffice stored procedures to use `INSERT BackOffice.AuditAction (...)` without needing to know that the data physically lives in a different database.

The AuditAction table records every significant back-office operation performed by managers: which manager did what action, against which customer (CID/GCID), when, and with what parameters (XML). It is the primary audit trail for back-office compliance and accountability.

This synonym pattern exists to decouple the application logic from the physical storage location of audit logs. Audit log data is stored in a dedicated logging database (`DB_Logs`) for performance isolation and retention policy management, but the consuming BackOffice procedures reference it as a local object. If the target database is moved or renamed, only the synonym needs updating - not every procedure.

---

## 2. Business Logic

### 2.1 Cross-Database Audit Trail Redirection

**What**: Transparently routes all BackOffice audit writes to the central DB_Logs database without requiring cross-database syntax in consuming procedures.

**Columns/Parameters Involved**: N/A (synonym - see DB_Logs.BackOffice.AuditAction)

**Rules**:
- Any `SELECT/INSERT/UPDATE/DELETE` against `BackOffice.AuditAction` is transparently executed against `DB_Logs.BackOffice.AuditAction`.
- The calling procedures (`AuditActionAdd`, `AuditActionAdd_V2`) INSERT rows with: `ActionTime`, `ManagerID`, `AuditActionTypeID`, `AuditActionParameters` (XML), `CID`, `GCID`.
- `AuditActionTypeID` is resolved from `Dictionary.AuditActionType` by `ActionName` - if the action type doesn't exist yet, it is auto-created (with table lock).
- `View V_AuditAction` in the BackOffice schema also wraps this synonym for read access.

**Diagram**:
```
BackOffice.AuditActionAdd(@ActionTime, @ManagerID, @ActionName, @Params)
  |
  +-- lookup/create AuditActionTypeID in Dictionary.AuditActionType
  |
  +-- INSERT BackOffice.AuditAction (...)
        |
        v (resolved via synonym)
  INSERT DB_Logs.BackOffice.AuditAction (...)
        |
        v
  Audit record stored in DB_Logs database (separate storage)
```

---

## 3. Data Overview

N/A for Synonym. Data lives in DB_Logs.BackOffice.AuditAction (separate database, not in this repo).

---

## 4. Elements

N/A for Synonym. The column structure is defined on the target table `DB_Logs.BackOffice.AuditAction`. Known columns from consuming procedures:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActionTime | datetime | - | - | CODE-BACKED | Timestamp when the back-office action was performed. Passed as @ActionTime by AuditActionAdd. |
| 2 | ManagerID | int | YES | - | CODE-BACKED | BackOffice manager who performed the action. References BackOffice.Manager.ManagerID. |
| 3 | AuditActionTypeID | int | - | - | CODE-BACKED | Type of action performed (e.g., CustomerSetStatus, DocumentClassify). References Dictionary.AuditActionType.AuditActionTypeID. Auto-created if new. |
| 4 | AuditActionParameters | xml | YES | - | CODE-BACKED | XML payload containing action-specific parameters. Includes CID and GCID elements extracted to separate columns. Schema varies by action type. |
| 5 | CID | int/varchar | YES | - | CODE-BACKED | Customer ID extracted from AuditActionParameters XML (case-insensitive: CID or cid element). |
| 6 | GCID | int/varchar | YES | - | CODE-BACKED | Group Customer ID extracted from AuditActionParameters XML (case-insensitive: GCID or gcid element). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | DB_Logs.BackOffice.AuditAction | Synonym | All DML against BackOffice.AuditAction is redirected to this cross-database table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.AuditActionAdd | INSERT BackOffice.AuditAction | Writer | Primary write path for manager audit events |
| BackOffice.AuditActionAdd_V2 | INSERT BackOffice.AuditAction | Writer | Updated version of the audit insert procedure |
| BackOffice.AuditActionDetailsAdd | (likely references) | Writer | Adds detail records to the audit trail |
| BackOffice.GetAuditHistory | SELECT BackOffice.AuditAction | Reader | Returns audit history for a customer or manager |
| BackOffice.GetAuditHistoryDetails | SELECT BackOffice.AuditAction | Reader | Returns detailed audit event records |
| BackOffice.V_AuditAction | (based on synonym) | View | BackOffice view wrapping this synonym for read access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.AuditAction (synonym)
└── DB_Logs.BackOffice.AuditAction (table - cross-database)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| DB_Logs.BackOffice.AuditAction | Table (cross-database) | Synonym target - all DML is redirected here |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.AuditActionAdd | Stored Procedure | WRITER - inserts manager audit events |
| BackOffice.AuditActionAdd_V2 | Stored Procedure | WRITER - updated audit insert |
| BackOffice.AuditActionDetailsAdd | Stored Procedure | WRITER - inserts detail records |
| BackOffice.GetAuditHistory | Stored Procedure | READER - retrieves audit history |
| BackOffice.GetAuditHistoryDetails | Stored Procedure | READER - retrieves audit details |
| BackOffice.V_AuditAction | View | READER - view layer over this synonym |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym. Indexes exist on the target table in DB_Logs.

### 7.2 Constraints

N/A for Synonym. Constraints are defined on the target table.

---

## 8. Sample Queries

### 8.1 Record a manager audit action

```sql
EXEC BackOffice.AuditActionAdd
    @ActionTime = GETUTCDATE(),
    @ManagerID = 1001,
    @ActionName = 'CustomerSetDocumentStatus',
    @AuditActionParameters = '<AuditParameters><CID>12345</CID><DocumentStatus>2</DocumentStatus></AuditParameters>';
```

### 8.2 Read recent audit actions for a customer (via synonym)

```sql
SELECT TOP 20
    aa.ActionTime,
    aat.AuditActionTypeName,
    aa.ManagerID,
    aa.CID,
    aa.AuditActionParameters
FROM BackOffice.AuditAction aa WITH (NOLOCK)
JOIN Dictionary.AuditActionType aat WITH (NOLOCK)
    ON aat.AuditActionTypeID = aa.AuditActionTypeID
WHERE aa.CID = 12345
ORDER BY aa.ActionTime DESC;
```

### 8.3 Get audit history via the dedicated stored procedure

```sql
EXEC BackOffice.GetAuditHistory
    @CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [MIMO and BO - Important DBs](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/11474042949) | Confluence | Mentions DB_Logs and BackOffice as important databases in the MIMO/BO architecture |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.AuditAction | Type: Synonym | Source: etoro/etoro/BackOffice/Synonyms/BackOffice.AuditAction.sql*
