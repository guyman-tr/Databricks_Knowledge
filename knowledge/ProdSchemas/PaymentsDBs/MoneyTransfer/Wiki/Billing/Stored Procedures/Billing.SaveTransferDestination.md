# Billing.SaveTransferDestination

> Sets the destination funding data on a transfer record, storing the masked destination account or card details provided by the payment provider.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Void (no return value) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.SaveTransferDestination stores the destination funding instrument details (bank account number, card details, wallet address) on a transfer. This data is sensitive PII - the column uses SQL Server Dynamic Data Masking (default()) to protect it from non-privileged users.

This is the destination-side counterpart to SaveTransferOrigin. Together they record the complete funding instrument details for both ends of the transfer. The data is stored as a VARCHAR(MAX) string, typically containing JSON-structured provider-specific details.

Called during the transfer pipeline after the destination funding instrument has been identified and validated.

---

## 2. Business Logic

### 2.1 Masked PII Storage

**What**: Stores destination funding data with Dynamic Data Masking protection.

**Columns/Parameters Involved**: `DestinationFundingData`, `ReferenceID`

**Rules**:
- Uses SET NOCOUNT ON for performance (suppresses row count messages)
- Single-column UPDATE of DestinationFundingData
- Data is masked via Dynamic Data Masking (default()) - non-privileged queries see masked values
- Trigger auto-updates ModificationDate

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RefGuid | UNIQUEIDENTIFIER | NO | - | VERIFIED | Internal business key of the transfer. Maps to Billing.Transfers.ReferenceID. |
| 2 | @Destination | VARCHAR(MAX) | NO | - | CODE-BACKED | Destination funding instrument details. Typically JSON-structured provider-specific data (account numbers, card details, wallet IDs). Stored in Billing.Transfers.DestinationFundingData which is protected by Dynamic Data Masking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Billing.Transfers | Write (UPDATE) | Sets DestinationFundingData |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SaveTransferDestination (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | UPDATE target - sets DestinationFundingData WHERE ReferenceID = @RefGuid |

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

### 8.1 Set destination funding data
```sql
EXEC Billing.SaveTransferDestination
    @RefGuid = '023BE1D7-45AF-4710-9369-323E647A4EE4',
    @Destination = '{"accountId":"12345","iban":"GB82WEST12345698765432"}'
```

### 8.2 Check if destination data is set
```sql
SELECT TransferID, ReferenceID,
    CASE WHEN DestinationFundingData IS NULL THEN 'Missing' ELSE 'Set' END AS DestStatus
FROM Billing.Transfers WITH (NOLOCK)
WHERE ReferenceID = '023BE1D7-45AF-4710-9369-323E647A4EE4'
```

### 8.3 Find recent transfers missing destination data
```sql
SELECT TOP 10 TransferID, ReferenceID, TransferStatusID, CreateDate
FROM Billing.Transfers WITH (NOLOCK)
WHERE DestinationFundingData IS NULL
  AND TransferID > (SELECT MAX(TransferID) - 1000 FROM Billing.Transfers WITH (NOLOCK))
ORDER BY TransferID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.SaveTransferDestination | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.SaveTransferDestination.sql*
