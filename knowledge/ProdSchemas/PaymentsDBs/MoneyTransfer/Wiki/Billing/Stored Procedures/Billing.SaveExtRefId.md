# Billing.SaveExtRefId

> Updates the external reference ID on a transfer record, setting the provider-assigned identifier used for cross-system reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Void (no return value) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.SaveExtRefId updates the ExReferenceID field on an existing transfer, allowing the system to associate a provider-assigned external reference with an internal transfer record. This is part of the multi-step field population pattern where transfer records are progressively enriched after creation.

The ExReferenceID is the identifier used by the payment provider to track the transfer on their side. It follows prefix patterns like "TZ" or "TK" followed by a GUID fragment. This field is initially set by CreateTransfer but may need to be updated if the provider assigns or changes the reference during processing.

The procedure is called by the MoneyTransfer application service during the transfer pipeline, typically after the provider acknowledges the transfer request and returns their reference.

---

## 2. Business Logic

### 2.1 Single-Column Update by ReferenceID

**What**: Updates only ExReferenceID, leaving all other columns untouched. The trigger TR_Transfers_ModificationDate auto-updates ModificationDate.

**Columns/Parameters Involved**: `ExReferenceID`, `ReferenceID`

**Rules**:
- Locates the transfer by ReferenceID (UNIQUE CLUSTERED index - efficient seek)
- No status validation - can update ExReferenceID regardless of current TransferStatusID
- No concurrency protection beyond the implicit row lock

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RefGuid | UNIQUEIDENTIFIER | NO | - | VERIFIED | Internal business key of the transfer to update. Maps to Billing.Transfers.ReferenceID (UNIQUE CLUSTERED). |
| 2 | @ExReferenceID | VARCHAR(50) | NO | - | CODE-BACKED | New external reference ID value from the payment provider. Prefix patterns: "TZ" (e.g., Tink/EU) or "TK" (e.g., Tink/UK) followed by lowercase GUID fragment. Updates Billing.Transfers.ExReferenceID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Billing.Transfers | Write (UPDATE) | Sets ExReferenceID on the matching transfer |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SaveExtRefId (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | UPDATE target - sets ExReferenceID WHERE ReferenceID = @RefGuid |

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

### 8.1 Update external reference
```sql
EXEC Billing.SaveExtRefId
    @RefGuid = '023BE1D7-45AF-4710-9369-323E647A4EE4',
    @ExReferenceID = 'TZ023be1d745af4710'
```

### 8.2 Verify the update
```sql
SELECT TransferID, ReferenceID, ExReferenceID, ModificationDate
FROM Billing.Transfers WITH (NOLOCK)
WHERE ReferenceID = '023BE1D7-45AF-4710-9369-323E647A4EE4'
```

### 8.3 Find transfers by external reference prefix
```sql
SELECT TransferID, ExReferenceID, TransferStatusID
FROM Billing.Transfers WITH (NOLOCK)
WHERE ExReferenceID LIKE 'TZ%'
  AND TransferID > (SELECT MAX(TransferID) - 100 FROM Billing.Transfers WITH (NOLOCK))
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.SaveExtRefId | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.SaveExtRefId.sql*
