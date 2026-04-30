# Billing.GetTransferByReferenceID

> Retrieves a complete transfer record by its internal ReferenceID (GUID business key), returning all key columns including ExtTransactionId.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns full transfer row via SELECT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetTransferByReferenceID is the primary transfer lookup procedure, using the ReferenceID GUID as the key. This is the most efficient lookup path because ReferenceID has the UNIQUE CLUSTERED index on Billing.Transfers, making it a single clustered index seek.

This procedure is the standard way for the MoneyTransfer application to retrieve a transfer's current state. After creating a transfer, all subsequent operations reference it by ReferenceID, and this procedure provides the full current snapshot.

Compared to GetTransferByExReference, this procedure also returns ExtTransactionId in its result set, providing the external transaction reference assigned by the payment provider.

---

## 2. Business Logic

No complex business logic. Direct single-row clustered index lookup by the unique ReferenceID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RefID | UNIQUEIDENTIFIER | NO | - | VERIFIED | Internal business key GUID to search for. Maps to Billing.Transfers.ReferenceID (UNIQUE CLUSTERED). |
| 2 | (RETURN) TransferID | INT | - | - | CODE-BACKED | Auto-generated transfer identity. |
| 3 | (RETURN) ReferenceID | UNIQUEIDENTIFIER | - | - | CODE-BACKED | Echoed business key. |
| 4 | (RETURN) TransferStatusID | INT | - | - | CODE-BACKED | Current lifecycle state. See [Transfer Status](../../_glossary.md#transfer-status). |
| 5 | (RETURN) OriginFundingData | NVARCHAR(MAX) | - | - | CODE-BACKED | Masked origin funding details (PII). |
| 6 | (RETURN) DestinationFundingData | NVARCHAR(MAX) | - | - | CODE-BACKED | Masked destination funding details (PII). |
| 7 | (RETURN) CID | INT | - | - | CODE-BACKED | Customer identifier. |
| 8 | (RETURN) Amount | MONEY | - | - | CODE-BACKED | Transfer amount. |
| 9 | (RETURN) OriginFundingTypeID | INT | - | - | CODE-BACKED | Origin funding type. |
| 10 | (RETURN) DestinationFundingTypeID | INT | - | - | CODE-BACKED | Destination funding type. |
| 11 | (RETURN) CurrencyID | INT | - | - | CODE-BACKED | Transfer currency. |
| 12 | (RETURN) CreateDate | DATETIME2 | - | - | CODE-BACKED | Transfer creation timestamp. |
| 13 | (RETURN) ModificationDate | DATETIME2 | - | - | CODE-BACKED | Last modification timestamp. |
| 14 | (RETURN) ExReferenceID | VARCHAR(50) | - | - | CODE-BACKED | External reference from provider. |
| 15 | (RETURN) DepotId | INT | - | - | CODE-BACKED | Processing depot identifier. |
| 16 | (RETURN) ExtTransactionId | VARCHAR(50) | - | - | CODE-BACKED | External transaction ID from payment provider. Additional column not returned by GetTransferByExReference. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Billing.Transfers | Read (SELECT) | Clustered index seek on ReferenceID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetTransferByReferenceID (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | SELECT source - clustered index lookup by ReferenceID |

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

### 8.1 Look up a transfer by reference
```sql
EXEC Billing.GetTransferByReferenceID @RefID = '023BE1D7-45AF-4710-9369-323E647A4EE4'
```

### 8.2 Verify using direct query
```sql
SELECT TransferID, ReferenceID, TransferStatusID, CID, Amount, ExtTransactionId
FROM Billing.Transfers WITH (NOLOCK)
WHERE ReferenceID = '023BE1D7-45AF-4710-9369-323E647A4EE4'
```

### 8.3 Find transfers with their external IDs
```sql
SELECT ReferenceID, ExReferenceID, ExtTransactionId, TransferStatusID
FROM Billing.Transfers WITH (NOLOCK)
WHERE TransferID > (SELECT MAX(TransferID) - 100 FROM Billing.Transfers WITH (NOLOCK))
  AND ExtTransactionId IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetTransferByReferenceID | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.GetTransferByReferenceID.sql*
