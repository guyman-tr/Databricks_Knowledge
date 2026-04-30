# Billing.SaveExtTransactionId

> Updates the external transaction ID on a transfer record, storing the payment provider's transaction identifier for reconciliation and tracking.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Void (no return value) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.SaveExtTransactionId stores the payment provider's transaction identifier on an existing transfer. While ExReferenceID (set by SaveExtRefId) is the reference the system sends to the provider, ExtTransactionId is the identifier the provider assigns back to the transaction on their side.

This distinction is important for reconciliation: when investigating a transfer with the provider, the team needs both the outgoing reference (ExReferenceID) and the provider's own transaction ID (ExtTransactionId). This procedure captures the latter.

The procedure is called during the transfer pipeline after the provider returns their transaction acknowledgment. It is part of the multi-step field population pattern documented in Billing.Transfers Section 2.2.

---

## 2. Business Logic

### 2.1 Provider Transaction ID Assignment

**What**: Stores the provider-assigned transaction identifier. Single-column update with no validation.

**Columns/Parameters Involved**: `ExtTransactionId`, `ReferenceID`

**Rules**:
- Locates transfer by ReferenceID (UNIQUE CLUSTERED seek)
- No status validation - can be set at any point in the lifecycle
- ExtTransactionId formats vary by provider: GUID-format without hyphens or shorter hex strings
- Trigger auto-updates ModificationDate

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RefGuid | UNIQUEIDENTIFIER | NO | - | VERIFIED | Internal business key of the transfer. Maps to Billing.Transfers.ReferenceID. |
| 2 | @ExtTransactionId | VARCHAR(50) | NO | - | CODE-BACKED | Provider-assigned transaction identifier. Format varies by provider: GUID without hyphens (e.g., "2b99175ec53e4fdf90f43dba6955f95d") or shorter hex (e.g., "4f3b91a2d668cabe9c9e"). Updates Billing.Transfers.ExtTransactionId. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Billing.Transfers | Write (UPDATE) | Sets ExtTransactionId on the matching transfer |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SaveExtTransactionId (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | UPDATE target - sets ExtTransactionId WHERE ReferenceID = @RefGuid |

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

### 8.1 Set external transaction ID
```sql
EXEC Billing.SaveExtTransactionId
    @RefGuid = '023BE1D7-45AF-4710-9369-323E647A4EE4',
    @ExtTransactionId = '2b99175ec53e4fdf90f43dba6955f95d'
```

### 8.2 Find transfers with external transaction IDs
```sql
SELECT TransferID, ReferenceID, ExReferenceID, ExtTransactionId
FROM Billing.Transfers WITH (NOLOCK)
WHERE ExtTransactionId IS NOT NULL
  AND TransferID > (SELECT MAX(TransferID) - 100 FROM Billing.Transfers WITH (NOLOCK))
```

### 8.3 Match internal and external references
```sql
SELECT ReferenceID, ExReferenceID, ExtTransactionId, TransferStatusID
FROM Billing.Transfers WITH (NOLOCK)
WHERE ReferenceID = '023BE1D7-45AF-4710-9369-323E647A4EE4'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.SaveExtTransactionId | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.SaveExtTransactionId.sql*
