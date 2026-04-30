# Billing.SaveTransferInitFundingId

> Sets the initial funding instrument identifier on a transfer record, capturing the funding instrument determined early in the pipeline before final origin/destination routing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Void (no return value) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.SaveTransferInitFundingId stores the initial funding instrument identifier, which represents the funding instrument determined early in the transfer pipeline before the final origin and destination routing is resolved. This may differ from the final OriginFundingId or DestinationFundingId if routing changes during processing.

In live data, InitFundingId is less frequently populated than DestinationFundingId, suggesting it is only set for certain transfer types or when the initial funding instrument needs to be tracked separately from the final resolved instruments.

---

## 2. Business Logic

No complex business logic. Single-column UPDATE of InitFundingId by ReferenceID. Trigger auto-updates ModificationDate.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RefGuid | UNIQUEIDENTIFIER | NO | - | VERIFIED | Internal business key. Maps to Billing.Transfers.ReferenceID. |
| 2 | @InitFundingId | INT | NO | - | CODE-BACKED | Initial funding instrument identifier, set early in the pipeline before final routing. Stored in Billing.Transfers.InitFundingId. Often NULL - only populated when the initial instrument differs from final origin/destination. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Billing.Transfers | Write (UPDATE) | Sets InitFundingId |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SaveTransferInitFundingId (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | UPDATE target - sets InitFundingId WHERE ReferenceID = @RefGuid |

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

### 8.1 Set initial funding ID
```sql
EXEC Billing.SaveTransferInitFundingId
    @RefGuid = '023BE1D7-45AF-4710-9369-323E647A4EE4',
    @InitFundingId = 16513374
```

### 8.2 Find transfers with InitFundingId set
```sql
SELECT TOP 10 TransferID, InitFundingId, OriginFundingId, DestinationFundingId
FROM Billing.Transfers WITH (NOLOCK)
WHERE InitFundingId IS NOT NULL
ORDER BY TransferID DESC
```

### 8.3 Compare initial vs final funding IDs
```sql
SELECT TransferID, InitFundingId, OriginFundingId, DestinationFundingId,
    CASE WHEN InitFundingId = OriginFundingId THEN 'Same' ELSE 'Different' END AS InitVsOrigin
FROM Billing.Transfers WITH (NOLOCK)
WHERE InitFundingId IS NOT NULL AND OriginFundingId IS NOT NULL
  AND TransferID > (SELECT MAX(TransferID) - 10000 FROM Billing.Transfers WITH (NOLOCK))
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.SaveTransferInitFundingId | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.SaveTransferInitFundingId.sql*
