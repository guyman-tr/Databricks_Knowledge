# Billing.SaveTransferOriginFundingId

> Sets the origin funding instrument identifier on a transfer record, storing the provider-assigned numeric ID for the source account or card.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Void (no return value) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.SaveTransferOriginFundingId stores the provider-assigned numeric identifier for the origin funding instrument. This is the origin-side counterpart to SaveTransferDestinationFundingId. While SaveTransferOrigin stores the full masked funding data, this procedure stores the concise numeric ID.

In live data, OriginFundingId is less frequently populated than DestinationFundingId, suggesting that origin instrument IDs are not always available or needed for all transfer types.

---

## 2. Business Logic

No complex business logic. Single-column UPDATE of OriginFundingId by ReferenceID. Trigger auto-updates ModificationDate.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RefGuid | UNIQUEIDENTIFIER | NO | - | VERIFIED | Internal business key. Maps to Billing.Transfers.ReferenceID. |
| 2 | @OriginFundingId | INT | NO | - | CODE-BACKED | Provider-assigned numeric ID for the origin funding instrument. Stored in Billing.Transfers.OriginFundingId. Less frequently populated than DestinationFundingId in live data - may not be available for all transfer types. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Billing.Transfers | Write (UPDATE) | Sets OriginFundingId |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SaveTransferOriginFundingId (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | UPDATE target - sets OriginFundingId WHERE ReferenceID = @RefGuid |

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

### 8.1 Set origin funding ID
```sql
EXEC Billing.SaveTransferOriginFundingId
    @RefGuid = '023BE1D7-45AF-4710-9369-323E647A4EE4',
    @OriginFundingId = 16513374
```

### 8.2 Compare all three funding IDs
```sql
SELECT TransferID, InitFundingId, OriginFundingId, DestinationFundingId
FROM Billing.Transfers WITH (NOLOCK)
WHERE ReferenceID = '023BE1D7-45AF-4710-9369-323E647A4EE4'
```

### 8.3 Find transfers with origin but no destination funding ID
```sql
SELECT TOP 10 TransferID, OriginFundingId, DestinationFundingId, TransferStatusID
FROM Billing.Transfers WITH (NOLOCK)
WHERE OriginFundingId IS NOT NULL AND DestinationFundingId IS NULL
ORDER BY TransferID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.SaveTransferOriginFundingId | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.SaveTransferOriginFundingId.sql*
