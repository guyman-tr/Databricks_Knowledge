# Billing.GetPostTransfer

> Retrieves all post-transfer action records for a given reference ID, returning the full action details for status tracking and processing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set of actions for a ReferenceID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetPostTransfer is the primary lookup procedure for post-transfer actions. It retrieves all actions associated with a given ReferenceID, returning the complete set of follow-up operations for a transfer. Since a single transfer can generate multiple post-transfer actions, this may return multiple rows.

The procedure is used by the MoneyTransfer application service to check the status of post-transfer processing, determine if all follow-up actions have completed, and retrieve payload data for continued processing.

It leverages the IX_Billing_PostTransferActions index on ReferenceID for efficient retrieval.

---

## 2. Business Logic

No complex business logic. Direct multi-row SELECT by ReferenceID. Returns all actions regardless of PostTransferStatusID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RefID | UNIQUEIDENTIFIER | NO | - | VERIFIED | Business reference GUID. Maps to Billing.PostTransferActions.ReferenceID (indexed). |
| 2 | (RETURN) PostTransferActionID | INT | - | - | CODE-BACKED | Auto-generated action identity. |
| 3 | (RETURN) TransferID | INT | - | - | CODE-BACKED | Parent transfer identity (links to Billing.Transfers). |
| 4 | (RETURN) ReferenceID | UNIQUEIDENTIFIER | - | - | CODE-BACKED | Echoed business reference GUID. |
| 5 | (RETURN) Payload | NVARCHAR(MAX) | - | - | CODE-BACKED | Masked action payload (PII-protected). |
| 6 | (RETURN) FundingTypeID | INT | - | - | CODE-BACKED | Funding type for this action. |
| 7 | (RETURN) PostTransferStatusID | INT | - | - | CODE-BACKED | Current action status: 1=in-progress, 2=completed (app-managed). |
| 8 | (RETURN) PostTransferActionTypeID | INT | - | - | CODE-BACKED | Action type classification (typically 1). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Billing.PostTransferActions | Read (SELECT) | Retrieves actions by ReferenceID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPostTransfer (procedure)
  └── Billing.PostTransferActions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.PostTransferActions | Table | SELECT source - retrieves all actions WHERE ReferenceID = @RefID |

### 6.2 Objects That Depend On This

No dependents found in the database.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get post-transfer actions
```sql
EXEC Billing.GetPostTransfer @RefID = '7418D7FB-CBFD-4288-A1CD-7B0C033E910D'
```

### 8.2 Join actions with parent transfer
```sql
SELECT pta.PostTransferActionID, pta.PostTransferStatusID, pta.FundingTypeID,
       t.TransferID, t.TransferStatusID, t.Amount
FROM Billing.PostTransferActions pta WITH (NOLOCK)
JOIN Billing.Transfers t WITH (NOLOCK) ON pta.TransferID = t.TransferID
WHERE pta.ReferenceID = '7418D7FB-CBFD-4288-A1CD-7B0C033E910D'
```

### 8.3 Count actions by status
```sql
SELECT PostTransferStatusID, COUNT(*) AS Count
FROM Billing.PostTransferActions WITH (NOLOCK)
WHERE PostTransferActionID > (SELECT MAX(PostTransferActionID) - 1000 FROM Billing.PostTransferActions WITH (NOLOCK))
GROUP BY PostTransferStatusID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPostTransfer | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.GetPostTransfer.sql*
