# Billing.GetTransferByExReference

> Retrieves a complete transfer record by its external reference ID (provider-assigned identifier), returning all key columns for the matching transfer.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns full transfer row via SELECT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetTransferByExReference enables lookup of a transfer using the ExReferenceID - the provider-facing identifier (e.g., "TZ023be1d745af4710"). This is essential when the payment provider sends a callback or status update referencing their own ID rather than the internal ReferenceID.

Without this procedure, reconciling provider callbacks to internal transfer records would require a separate mapping layer. This direct lookup enables real-time status synchronization between the MoneyTransfer system and external payment providers.

The procedure leverages the covering index IX_Transfer_ExReferenceID_Cover on Billing.Transfers, which includes all returned columns, making this an index-only (covered) query with no key lookups required.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a direct single-row lookup by ExReferenceID. Note that ExReferenceID is not unique-constrained, so multiple rows could theoretically match.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExReferenceID | VARCHAR(50) | NO | - | VERIFIED | External reference ID to search for. Maps to Billing.Transfers.ExReferenceID. Provider-assigned identifier with prefix patterns "TZ" or "TK". |
| 2 | (RETURN) TransferID | INT | - | - | CODE-BACKED | Auto-generated transfer identity. |
| 3 | (RETURN) ReferenceID | UNIQUEIDENTIFIER | - | - | CODE-BACKED | Internal business key GUID. |
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
| 14 | (RETURN) ExReferenceID | VARCHAR(50) | - | - | CODE-BACKED | Echoed external reference (same as input). |
| 15 | (RETURN) DepotId | INT | - | - | CODE-BACKED | Processing depot identifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Billing.Transfers | Read (SELECT) | Retrieves transfer by ExReferenceID using covering index |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetTransferByExReference (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | SELECT source - lookup by ExReferenceID |

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

### 8.1 Look up a transfer by external reference
```sql
EXEC Billing.GetTransferByExReference @ExReferenceID = 'TZ023be1d745af4710'
```

### 8.2 Verify the covering index is used
```sql
SELECT TransferID, ReferenceID, TransferStatusID, CID, Amount
FROM Billing.Transfers WITH (NOLOCK)
WHERE ExReferenceID = 'TZ023be1d745af4710'
```

### 8.3 Find transfers with a specific prefix
```sql
SELECT TransferID, ExReferenceID, TransferStatusID, CreateDate
FROM Billing.Transfers WITH (NOLOCK)
WHERE ExReferenceID LIKE 'TK%'
  AND TransferID > (SELECT MAX(TransferID) - 1000 FROM Billing.Transfers WITH (NOLOCK))
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetTransferByExReference | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.GetTransferByExReference.sql*
