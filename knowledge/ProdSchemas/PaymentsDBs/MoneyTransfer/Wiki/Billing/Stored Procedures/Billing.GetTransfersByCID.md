# Billing.GetTransfersByCID

> Retrieves all transfer records for a given customer, returning the full set of transfer details ordered for client-facing display.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set of all transfers for a CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetTransfersByCID is the primary customer-scoped transfer listing procedure. It returns all transfer records belonging to a specific customer, providing the complete transfer history needed for account statements, support tools, and customer-facing transfer dashboards.

Unlike the single-transfer lookup procedures (GetTransferByReferenceID, GetTransferByExReference), this procedure returns multiple rows - every transfer the customer has ever initiated. It leverages the IX_Billing_Transfers_CID index for efficient customer-scoped retrieval.

The procedure is called by the MoneyTransfer application service (MoneyTransferUser has EXECUTE permission) to populate transfer history views. It returns 12 key columns covering identity, financial details, status, and external references - sufficient for rendering a complete transfer list without follow-up queries.

---

## 2. Business Logic

No complex business logic. Direct multi-row SELECT by CID with no filtering on status, date, or amount. Returns all transfers regardless of lifecycle state.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | VERIFIED | Customer identifier. Maps to Billing.Transfers.CID. Used as the IX_Billing_Transfers_CID index seek predicate. |
| 2 | (RETURN) TransferID | INT | - | - | CODE-BACKED | Auto-generated transfer identity. |
| 3 | (RETURN) CreateDate | DATETIME2 | - | - | CODE-BACKED | Transfer creation timestamp (UTC). |
| 4 | (RETURN) TransferStatusID | INT | - | - | CODE-BACKED | Current lifecycle state: 0=New, 1=Init, 2=Pending, 4=Technical, 7=Cancel, 8=Fail, 9=Sent, 10=Received. See [Transfer Status](../../_glossary.md#transfer-status). |
| 5 | (RETURN) ModificationDate | DATETIME2 | - | - | CODE-BACKED | Last modification timestamp (UTC), auto-updated by trigger. |
| 6 | (RETURN) CID | INT | - | - | CODE-BACKED | Customer identifier (echoed). |
| 7 | (RETURN) ReferenceID | UNIQUEIDENTIFIER | - | - | CODE-BACKED | Internal business key GUID. |
| 8 | (RETURN) Amount | MONEY | - | - | CODE-BACKED | Transfer amount in specified currency. |
| 9 | (RETURN) OriginFundingTypeID | INT | - | - | CODE-BACKED | Origin funding instrument type (application-managed). |
| 10 | (RETURN) OriginFundingData | NVARCHAR(MAX) | - | - | CODE-BACKED | Masked origin funding details (PII). |
| 11 | (RETURN) CurrencyID | INT | - | - | CODE-BACKED | Transfer currency identifier. |
| 12 | (RETURN) ExReferenceID | VARCHAR(50) | - | - | CODE-BACKED | External provider reference ID. |
| 13 | (RETURN) DestinationFundingData | NVARCHAR(MAX) | - | - | CODE-BACKED | Masked destination funding details (PII). |
| 14 | (RETURN) DestinationFundingTypeID | INT | - | - | CODE-BACKED | Destination funding instrument type (application-managed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Billing.Transfers | Read (SELECT) | Retrieves all transfers for a CID via index seek |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetTransfersByCID (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | SELECT source - multi-row read by CID |

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

### 8.1 Get all transfers for a customer
```sql
EXEC Billing.GetTransfersByCID @cid = 12345678
```

### 8.2 Manual equivalent with status name
```sql
SELECT T.TransferID, T.CreateDate, ts.Name AS StatusName, T.Amount, T.CurrencyID
FROM Billing.Transfers T WITH (NOLOCK)
JOIN Dictionary.TransferStatus ts WITH (NOLOCK) ON T.TransferStatusID = ts.ID
WHERE T.CID = 12345678
ORDER BY T.TransferID DESC
```

### 8.3 Count transfers by status for a customer
```sql
SELECT TransferStatusID, COUNT(*) AS Count
FROM Billing.Transfers WITH (NOLOCK)
WHERE CID = 12345678
GROUP BY TransferStatusID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetTransfersByCID | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.GetTransfersByCID.sql*
