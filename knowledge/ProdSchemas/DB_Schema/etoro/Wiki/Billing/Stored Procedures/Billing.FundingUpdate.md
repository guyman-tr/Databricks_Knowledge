# Billing.FundingUpdate

> General-purpose partial update for Billing.Funding metadata - updates any subset of non-data columns using ISNULL pattern (only updates fields where parameters are provided).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingID INTEGER - PK of Billing.Funding |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingUpdate` is the general metadata update procedure for `Billing.Funding`. It follows the ISNULL optional-parameter pattern: every updatable column defaults to NULL, and only columns where a non-NULL parameter is passed are modified. Columns where parameters are NULL retain their existing values. This makes the procedure safe to call with partial updates - the caller only needs to pass the specific fields they want to change.

The procedure covers all non-data fields: funding type classification, blocking status, refund exclusion, document requirements, payment details display text, and encryption key version. Notably, it does NOT update `FundingData` (the XML payload) - that is handled by the dedicated `Billing.FundingUpdateFundingData` procedure.

If `@FundingID` is NULL, the procedure returns 0 immediately with no data modification - a null-safety guard.

---

## 2. Business Logic

### 2.1 ISNULL Optional-Parameter Update Pattern

**What**: All parameters default to NULL, allowing callers to update only specific fields.

**Columns/Parameters Involved**: All parameters and their corresponding Billing.Funding columns

**Rules**:
- `ISNULL(@Param, ColumnCurrentValue)` pattern: if @Param is NOT NULL, the column is set to @Param; if @Param IS NULL, the column keeps its current value.
- `@FundingID = NULL` guard: if the primary key is not provided, procedure returns 0 immediately (no-op, no error).
- All fields are optional - a caller can pass only @FundingID + @IsBlocked to block a funding without touching any other fields.
- Column `FundingData` is NOT updatable via this procedure - use `FundingUpdateFundingData` for XML data changes.

### 2.2 Key Use Cases

**Blocking a payment instrument**:
- Pass `@IsBlocked = 1`, `@BlockedDescription = 'Fraud'`, `@BlockedAt = GETUTCDATE()`

**Setting DocumentRequired**:
- Pass `@DocumentRequired = 1` to flag an instrument as requiring compliance documents

**Updating KeyVersion after PCI key rotation**:
- Pass `@KeyVersion = <new_version>` (added PAYIL-6869, Jul 2023) after re-encrypting card data

**Updating PaymentDetails display text**:
- Pass `@PaymentDetails = <formatted_string>` after Billing.Funding trigger recalculates it

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INTEGER | YES | NULL | CODE-BACKED | PK of Billing.Funding record to update. If NULL, procedure returns 0 immediately (no-op). |
| 2 | @FundingTypeID | INTEGER | YES | NULL | CODE-BACKED | Optional: new payment method type. If NULL, existing FundingTypeID is preserved. FK to Dictionary.FundingType. |
| 3 | @ManagerID | INTEGER | YES | NULL | CODE-BACKED | Optional: BO manager performing the update. If NULL, existing ManagerID is preserved. |
| 4 | @IsBlocked | BIT | YES | NULL | CODE-BACKED | Optional: 1 = block the instrument; 0 = unblock. If NULL, existing IsBlocked is preserved. |
| 5 | @BlockedDescription | VARCHAR(255) | YES | NULL | CODE-BACKED | Optional: reason for blocking (fraud, KYC, chargeback). If NULL, existing BlockedDescription is preserved. Should be set alongside @IsBlocked=1. |
| 6 | @BlockedAt | DATETIME | YES | NULL | CODE-BACKED | Optional: UTC timestamp of blocking action. If NULL, existing BlockedAt is preserved. Should be set alongside @IsBlocked=1. |
| 7 | @IsRefundExcluded | BIT | YES | NULL | CODE-BACKED | Optional: 1 = prevent refunds to this instrument; 0 = allow refunds. If NULL, existing IsRefundExcluded is preserved. |
| 8 | @DocumentRequired | BIT | YES | NULL | CODE-BACKED | Optional: 1 = compliance document required before use; 0 = no document required. If NULL, existing DocumentRequired is preserved. |
| 9 | @PaymentDetails | VARCHAR(MAX) | YES | NULL | CODE-BACKED | Optional: pre-formatted payment display text (added Nov 2022, PAYIL-5313). If NULL, existing PaymentDetails is preserved. |
| 10 | @KeyVersion | SMALLINT | YES | NULL | CODE-BACKED | Optional: encryption key version (added Jul 2023, PAYIL-6869). If NULL, existing KeyVersion is preserved. Used after PCI key rotation to update which key version encrypts this record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingID | Billing.Funding | Modifier | Updates metadata columns by FundingID (PK) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| FundingUser (DB role) | EXECUTE | Permission | Called by Billing/Funding application service to update payment instrument metadata |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingUpdate (procedure)
└── Billing.Funding (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | UPDATE - partial metadata update via ISNULL pattern |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing/Funding application service | External | Calls for payment instrument metadata updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Uses SET NOCOUNT ON. All parameters default NULL. @FundingID null-guard (RETURN 0). No TRY/CATCH, no transaction. Does NOT update FundingData XML column.

---

## 8. Sample Queries

### 8.1 Block a payment instrument

```sql
EXEC [Billing].[FundingUpdate]
    @FundingID = 123456,
    @IsBlocked = 1,
    @BlockedDescription = 'Chargeback - fraud detected',
    @BlockedAt = '2026-03-18 10:00:00';
```

### 8.2 Update KeyVersion after PCI key rotation

```sql
EXEC [Billing].[FundingUpdate]
    @FundingID = 123456,
    @KeyVersion = 2;
-- Other columns unchanged
```

### 8.3 Verify update applied

```sql
SELECT FundingID, IsBlocked, BlockedDescription, BlockedAt, KeyVersion, PaymentDetails
FROM [Billing].[Funding] WITH (NOLOCK)
WHERE FundingID = 123456;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYIL-5313 (Nov 2022) | Jira | Added @PaymentDetails parameter |
| PAYIL-6869 (Jul 2023) | Jira | Added @KeyVersion parameter for PCI key rotation support |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 2 Jira (from code comments) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingUpdate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingUpdate.sql*
