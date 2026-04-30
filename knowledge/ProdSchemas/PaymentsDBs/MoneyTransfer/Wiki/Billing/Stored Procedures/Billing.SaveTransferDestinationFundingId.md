# Billing.SaveTransferDestinationFundingId

> Sets the destination funding instrument identifier on a transfer record, storing the provider-assigned numeric ID for the destination account or card.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Void (no return value) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.SaveTransferDestinationFundingId stores the provider-assigned numeric identifier for the destination funding instrument. While SaveTransferDestination stores the full masked funding data (bank details, card info), this procedure stores the concise numeric ID that the provider uses to reference the destination instrument.

This ID enables efficient provider-side lookups without transmitting full PII data. It is frequently populated in live data (most recent transfers have DestinationFundingId set), making it a reliable tracking field.

---

## 2. Business Logic

No complex business logic. Single-column UPDATE of DestinationFundingId by ReferenceID. Trigger auto-updates ModificationDate.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RefGuid | UNIQUEIDENTIFIER | NO | - | VERIFIED | Internal business key. Maps to Billing.Transfers.ReferenceID. |
| 2 | @DestinationFundingId | INT | NO | - | CODE-BACKED | Provider-assigned numeric ID for the destination funding instrument. Stored in Billing.Transfers.DestinationFundingId. More frequently populated than OriginFundingId in live data. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Billing.Transfers | Write (UPDATE) | Sets DestinationFundingId |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SaveTransferDestinationFundingId (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | UPDATE target - sets DestinationFundingId WHERE ReferenceID = @RefGuid |

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

### 8.1 Set destination funding ID
```sql
EXEC Billing.SaveTransferDestinationFundingId
    @RefGuid = '023BE1D7-45AF-4710-9369-323E647A4EE4',
    @DestinationFundingId = 17981381
```

### 8.2 Verify funding IDs for a transfer
```sql
SELECT TransferID, InitFundingId, OriginFundingId, DestinationFundingId
FROM Billing.Transfers WITH (NOLOCK)
WHERE ReferenceID = '023BE1D7-45AF-4710-9369-323E647A4EE4'
```

### 8.3 Find transfers with all funding IDs populated
```sql
SELECT TOP 10 TransferID, InitFundingId, OriginFundingId, DestinationFundingId
FROM Billing.Transfers WITH (NOLOCK)
WHERE DestinationFundingId IS NOT NULL AND OriginFundingId IS NOT NULL
ORDER BY TransferID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.SaveTransferDestinationFundingId | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.SaveTransferDestinationFundingId.sql*
