# History.ManualPositionClose_Crisis

> Synonym providing local-schema access to DB_Logs.History.ManualPositionClose_Crisis - the audit log table recording each individual position closed within a manual/emergency "crisis" close operation, linking positions to their parent operation record.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | Alias: DB_Logs.History.ManualPositionClose_Crisis |
| **Partition** | N/A (resolves to target in DB_Logs) |
| **Indexes** | N/A (resolves to target in DB_Logs) |

---

## 1. Business Meaning

`History.ManualPositionClose_Crisis` is a cross-database synonym pointing to `DB_Logs.History.ManualPositionClose_Crisis`. The underlying table is the position-level detail log for manual/emergency crisis close operations - each row records one position that was force-closed as part of a crisis operation.

This table works as a pair with `History.ManualOperationPositionClose_Crisis`:
- `ManualOperationPositionClose_Crisis` stores the **operation** (one row per crisis batch, with the operator's UserName, reason code, and description)
- `ManualPositionClose_Crisis` stores the **positions** (one row per position closed within each operation, with OperationID linking back to the operation record and PositionID identifying the position)

The primary writer is `Trade.ManualPositionClose_Crisis` (in the Trade schema), which closes the root position plus its entire copy-trade child tree, inserting one row here per position closed. The audit trail created by this table enables post-incident reconstruction of exactly which positions were closed in any given crisis operation and by which DBA action.

---

## 2. Business Logic

### 2.1 Crisis Position Audit

**What**: Each INSERT records one position closed during a manual crisis close operation.

**Columns/Parameters Involved**: OperationID, PositionID

**Rules**:
- Written by Trade.ManualPositionClose_Crisis (Trade schema SP), NOT a History schema procedure
- One OperationID links all position rows back to the parent operation record in ManualOperationPositionClose_Crisis
- In Real environment (Maintenance.Feature FeatureID=22), the writer recursively traverses the copy-trade tree: the root position is closed first (one INSERT), then all child positions are closed in a WHILE loop (one INSERT each)
- PositionID is BIGINT (changed from INT by Elad in 2021-11-16 for large position ID support, matching the Trade.PositionTbl.PositionID BIGINT migration)
- OperationID is obtained from History.InsertManualOperationPositionClose_Crisis via @@IDENTITY before Trade.ManualPositionClose_Crisis is called; the caller passes it as @OperationID

### 2.2 Operation-Position Relationship

**What**: The two-table design separates operation metadata from position detail.

**Rules**:
- One OperationID in ManualOperationPositionClose_Crisis can have N rows in ManualPositionClose_Crisis
- Single-position closes: 1 operation -> 1 position row
- Tree closes (copy trade): 1 operation -> 1 root + N child position rows
- The OperationID FK is the only structural link between the two tables

---

## 3. Data Overview

N/A for Synonym (target table is in DB_Logs).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym) | - | - | - | CODE-BACKED | Synonym resolves to DB_Logs.History.ManualPositionClose_Crisis. Target columns inferred from Trade.ManualPositionClose_Crisis INSERT statements: OperationID (int, FK to ManualOperationPositionClose_Crisis.OperationID), PositionID (BIGINT, FK to Trade.PositionTbl.PositionID - migrated to BIGINT 2021-11-16). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | DB_Logs.History.ManualPositionClose_Crisis | Synonym | All operations redirect to this target in DB_Logs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ManualPositionClose_Crisis | INSERT | Writer | Inserts one row per position closed in a crisis operation (root + tree children) |
| BackOffice.AccountStatement_GetTaxReport_v3 | SELECT | Reader | Reads crisis-closed positions for tax reporting |
| BackOffice.AccountStatement_GetTaxReport_v2_withDBLogs | SELECT | Reader | Reads crisis-closed positions for tax reporting (v2 with DB_Logs access) |
| BackOffice.AccountStatement_GetTaxReport_v2 | SELECT | Reader | Reads crisis-closed positions for tax reporting (v2) |
| dbo.AccountStatement_GetTransactionsReport_v10 | SELECT | Reader | Reads crisis-closed positions in transaction report |
| dbo.AccountStatement_GetClosedPositionsReport_v3 | SELECT | Reader | Reads crisis-closed positions in closed positions report |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ManualPositionClose_Crisis (synonym)
└── DB_Logs.History.ManualPositionClose_Crisis (table - external database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| DB_Logs.History.ManualPositionClose_Crisis | Table (external DB) | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ManualPositionClose_Crisis | Stored Procedure (Trade schema) | Primary writer - closes root + tree positions in crisis operations |
| BackOffice.AccountStatement_GetTaxReport_v3 | Stored Procedure | Reader for tax report generation |
| BackOffice.AccountStatement_GetTaxReport_v2_withDBLogs | Stored Procedure | Reader for tax report generation |
| BackOffice.AccountStatement_GetTaxReport_v2 | Stored Procedure | Reader for tax report generation |
| dbo.AccountStatement_GetTransactionsReport_v10 | Stored Procedure | Reader for transaction reports |
| dbo.AccountStatement_GetClosedPositionsReport_v3 | Stored Procedure | Reader for closed positions reports |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Show recent crisis-closed positions with operation details

```sql
SELECT TOP 20
    pc.OperationID,
    pc.PositionID,
    op.UserName,
    op.OperationDescription,
    op.ManualOperationReasonID
FROM History.ManualPositionClose_Crisis pc WITH (NOLOCK)
INNER JOIN History.ManualOperationPositionClose_Crisis op WITH (NOLOCK)
    ON pc.OperationID = op.OperationID
ORDER BY pc.OperationID DESC
```

### 8.2 Count positions closed per operation

```sql
SELECT
    op.OperationID,
    op.UserName,
    op.OperationDescription,
    COUNT(pc.PositionID) AS PositionsClosed
FROM History.ManualOperationPositionClose_Crisis op WITH (NOLOCK)
LEFT JOIN History.ManualPositionClose_Crisis pc WITH (NOLOCK)
    ON op.OperationID = pc.OperationID
GROUP BY op.OperationID, op.UserName, op.OperationDescription
ORDER BY op.OperationID DESC
```

### 8.3 Find all operations that closed a specific position

```sql
SELECT
    pc.OperationID,
    op.UserName,
    op.ManualOperationReasonID,
    op.OperationDescription
FROM History.ManualPositionClose_Crisis pc WITH (NOLOCK)
INNER JOIN History.ManualOperationPositionClose_Crisis op WITH (NOLOCK)
    ON pc.OperationID = op.OperationID
WHERE pc.PositionID = 123456789
ORDER BY pc.OperationID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.2/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/6 applicable (synonym)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.ManualPositionClose_Crisis | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.ManualPositionClose_Crisis.sql*
