# Billing.FundingUpdateFundingData

> Updates the FundingData XML and optional KeyVersion for a specific payment instrument, used primarily during PCI key rotation and card data re-tokenization.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingID + @FundingTypeID - composite WHERE clause |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingUpdateFundingData` is the dedicated update procedure for the `FundingData` XML column in `Billing.Funding`. It replaces the entire XML payload and optionally updates the `KeyVersion` - the two fields that change together during PCI card data migration and key rotation operations.

The companion `Billing.FundingUpdate` handles all NON-data metadata (blocking status, document requirements, etc.) but deliberately excludes `FundingData`. This separation ensures that card XML data updates are performed through a controlled, auditable path rather than mixed with administrative metadata changes.

The WHERE clause uses both `FundingID` AND `FundingTypeID`, providing an additional safety check: the update only proceeds if the funding record's type matches the expected type, preventing accidental cross-type data corruption.

---

## 2. Business Logic

### 2.1 Card Data Re-tokenization

**What**: Replaces the payment instrument XML payload with newly tokenized card data.

**Columns/Parameters Involved**: `@FundingID`, `@FundingTypeID`, `@FundingData`, `@KeyVersion`

**Rules**:
- `FundingData = @FundingData`: replaces the entire XML. Triggers on `Billing.Funding` (FundingInsertTrigger/FundingUpdateTrigger) fire on this UPDATE - history is captured in History.BillingFunding and PaymentDetails is recalculated by TR_FundingPaymentDetails.
- `KeyVersion = ISNULL(@KeyVersion, KeyVersion)`: optional update. Pass new version when rotating encryption keys; omit to preserve existing version.
- `WHERE FundingTypeID = @FundingTypeID`: safety guard - only updates if type matches.
- Always returns 0 (RETURN 0). Callers should check @@ROWCOUNT if needed.

### 2.2 Trigger Side Effects

**What**: Writing to FundingData triggers three Billing.Funding triggers that update related data.

**Rules**:
- `TR_FundingPaymentDetails`: recalculates the `PaymentDetails` display text via `Billing.FormatFundingPaymentDetailsForWithdraw`. Result is visible in the next `FundingGetByID` call.
- `FundingUpdateTrigger`: writes a new row to `History.BillingFunding` (ValidTo=3000-01-01) and closes the previous history row. For CreditCard records, PAN data is stripped from the history (PCI compliance).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INTEGER | NO | - | CODE-BACKED | PK of the Billing.Funding record to update. Combined with @FundingTypeID in WHERE clause for safety. |
| 2 | @FundingTypeID | INTEGER | NO | - | CODE-BACKED | Expected funding type of the record. Safety guard in WHERE clause - prevents updating if type doesn't match. |
| 3 | @FundingData | XML | NO | - | CODE-BACKED | New XML payload replacing the entire FundingData column. Triggers PaymentDetails recalculation and History.BillingFunding audit row. |
| 4 | @KeyVersion | SMALLINT | YES | NULL | CODE-BACKED | New encryption key version (added Jul 2023, PAYIL-6869). If NULL, existing KeyVersion is preserved. Pass new version when rotating PCI encryption keys. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID, @FundingTypeID | Billing.Funding | Modifier | Updates FundingData + KeyVersion by (FundingID, FundingTypeID) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.FundingDataMigration pipeline | External | Caller | Called by UpdateSecuredCard as part of the card data migration |
| PCI key rotation process | External | Caller | Calls to replace encrypted card XML with newly keyed version |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingUpdateFundingData (procedure)
└── Billing.Funding (table)
      ├── TR_FundingPaymentDetails (trigger) [fires on UPDATE]
      └── FundingUpdateTrigger (trigger) [fires on UPDATE -> History.BillingFunding]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | UPDATE FundingData + KeyVersion WHERE FundingID + FundingTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Card data migration process | External | Called to write newly tokenized card XML back to source records |
| PCI key rotation process | External | Called to re-encrypt and update card XML |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. No SET NOCOUNT ON (implicit). No TRY/CATCH. RETURN 0 always (not an error code - always succeeds from SP perspective). Writing to FundingData fires 3 triggers.

---

## 8. Sample Queries

### 8.1 Update card XML data and key version

```sql
DECLARE @NewXML XML = '<Funding><FundingType>1</FundingType><TokenizedData>...</TokenizedData></Funding>';
EXEC [Billing].[FundingUpdateFundingData]
    @FundingID = 123456,
    @FundingTypeID = 1,  -- CreditCard
    @FundingData = @NewXML,
    @KeyVersion = 2;
```

### 8.2 Verify update was applied (including trigger-computed columns)

```sql
SELECT FundingID, FundingTypeID, FundingHash, SecuredCardData,
    Parameter, KeyVersion, PaymentDetails
FROM [Billing].[Funding] WITH (NOLOCK)
WHERE FundingID = 123456;
-- FundingHash and SecuredCardData are computed from new FundingData
-- PaymentDetails recalculated by trigger
```

### 8.3 Check history after update

```sql
SELECT TOP 3 AccountID, FundingID, FundingData, ValidFrom, ValidTo
FROM [History].[BillingFunding] WITH (NOLOCK)
WHERE FundingID = 123456
ORDER BY ValidFrom DESC;
-- New row with ValidTo = '3000-01-01', previous row closed with ValidTo = update time
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUS-1560 | Jira | Original procedure creation |
| PAYIL-6869 (Jul 2023) | Jira | Added @KeyVersion parameter for PCI key rotation support |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 2 Jira (from code comments) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingUpdateFundingData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingUpdateFundingData.sql*
