# Billing.SaveTransferOrigin

> Sets the origin funding data on a transfer record, storing the masked source account or card details provided by the payment provider.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Void (no return value) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.SaveTransferOrigin stores the origin funding instrument details (source bank account number, card details, wallet address) on a transfer. This is the origin-side counterpart to SaveTransferDestination. The data is sensitive PII protected by SQL Server Dynamic Data Masking (default()) on the Billing.Transfers.OriginFundingData column.

Together with SaveTransferDestination, this procedure completes the funding instrument pair that defines where money is moving from and to. The data is stored as VARCHAR(MAX), typically containing JSON-structured provider-specific details.

Called during the transfer pipeline after the origin funding instrument has been identified and validated.

---

## 2. Business Logic

### 2.1 Masked PII Storage

**What**: Stores origin funding data with Dynamic Data Masking protection.

**Columns/Parameters Involved**: `OriginFundingData`, `ReferenceID`

**Rules**:
- Uses SET NOCOUNT ON for performance
- Single-column UPDATE of OriginFundingData
- Data is masked via Dynamic Data Masking (default())
- Trigger auto-updates ModificationDate

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RefGuid | UNIQUEIDENTIFIER | NO | - | VERIFIED | Internal business key. Maps to Billing.Transfers.ReferenceID. |
| 2 | @Origin | VARCHAR(MAX) | NO | - | CODE-BACKED | Origin funding instrument details. Typically JSON-structured provider-specific data (source account numbers, card details). Stored in Billing.Transfers.OriginFundingData which is protected by Dynamic Data Masking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Billing.Transfers | Write (UPDATE) | Sets OriginFundingData |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SaveTransferOrigin (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | UPDATE target - sets OriginFundingData WHERE ReferenceID = @RefGuid |

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

### 8.1 Set origin funding data
```sql
EXEC Billing.SaveTransferOrigin
    @RefGuid = '023BE1D7-45AF-4710-9369-323E647A4EE4',
    @Origin = '{"accountId":"67890","iban":"DE89370400440532013000"}'
```

### 8.2 Check both origin and destination data
```sql
SELECT TransferID,
    CASE WHEN OriginFundingData IS NULL THEN 'Missing' ELSE 'Set' END AS OriginStatus,
    CASE WHEN DestinationFundingData IS NULL THEN 'Missing' ELSE 'Set' END AS DestStatus
FROM Billing.Transfers WITH (NOLOCK)
WHERE ReferenceID = '023BE1D7-45AF-4710-9369-323E647A4EE4'
```

### 8.3 Find recent transfers missing origin data
```sql
SELECT TOP 10 TransferID, TransferStatusID, CreateDate
FROM Billing.Transfers WITH (NOLOCK)
WHERE OriginFundingData IS NULL
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
*Object: Billing.SaveTransferOrigin | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.SaveTransferOrigin.sql*
