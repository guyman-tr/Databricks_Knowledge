# Billing.FundingAdd

> Creates a new funding instrument record in Billing.Funding for a customer - the entry point for registering a new payment method (card, bank account, wallet). Returns the new FundingID via OUTPUT parameter.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT Billing.Funding; @FundingID OUTPUT = SCOPE_IDENTITY() |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.FundingAdd` inserts a new funding record into `Billing.Funding` when a customer registers a payment method. Each funding record represents a specific payment instrument: a credit card, bank account, e-wallet, etc., with its associated XML metadata stored in `FundingData`.

The SP enforces one key business rule: funding types marked as `IsSingleFunding=1` in `Dictionary.FundingType` cannot be added via this procedure - those are managed by the system and added through other flows. For CreditCard (FundingTypeID=1), `DocumentRequired` is set to 1 (requiring KYC document upload); all other types default to 0.

The XML validation (CLR.ParseXML) was present in earlier versions but is commented out in the current code - the @FundingData is inserted as-is.

Version: Added @ManagerID (05/11/2019, Ran Ovadia), @KeyVersion (PAYIL-6869, 18/07/2023, Dor Izmaylov).

---

## 2. Business Logic

### 2.1 SingleFunding Type Guard

**Rules**: `IF EXISTS (SELECT * FROM Dictionary.FundingType WHERE FundingTypeID=@FundingTypeID AND IsSingleFunding=1)` -> RAISERROR(60025, 'cannot add funding of passed type') + RETURN 60025. Prevents registering system-managed funding types (e.g., internal accounts) through the customer-facing funding add flow.

### 2.2 DocumentRequired Resolution

**Rules**: `IF @FundingTypeID = 1` -> `@DocumentRequired = 1` (CreditCard requires document upload). All other types -> `@DocumentRequired = 0`.

### 2.3 Funding Record Insert

**Rules**: INSERT Billing.Funding (FundingTypeID, IsBlocked=0, FundingData, DocumentRequired, ManagerID, KeyVersion). `SET @FundingID = SCOPE_IDENTITY()`. If @@ERROR != 0 -> RAISERROR(60000) + RETURN 60000.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingID | INTEGER | YES | - | CODE-BACKED | OUTPUT: New Billing.Funding.FundingID after INSERT via SCOPE_IDENTITY(). The caller stores this to associate deposits/withdrawals with the new funding record. |
| 2 | @FundingTypeID | INTEGER | NO | - | CODE-BACKED | Payment method category. FK to Dictionary.FundingType. Validated: IsSingleFunding=1 types are rejected. Examples: 1=CreditCard, 29=Plaid. |
| 3 | @FundingData | XML | NO | - | CODE-BACKED | Full payment instrument metadata in XML format (card number token, account details, wallet ID, etc.). Stored in Billing.Funding.FundingData. XML validation (CLR.ParseXML) was present but is currently commented out. |
| 4 | @ManagerID | INT | YES | NULL | CODE-BACKED | Manager/system user creating the funding record. Written to Billing.Funding.ManagerID. Added 05/11/2019 with default NULL for backward compatibility. |
| 5 | @KeyVersion | SMALLINT | YES | NULL | CODE-BACKED | Encryption key version used to encrypt the FundingData XML. Written to Billing.Funding.KeyVersion. Added PAYIL-6869 (18/07/2023) for PCI key rotation tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingTypeID | Dictionary.FundingType | Validation READ | Checks IsSingleFunding=1 to prevent invalid funding type registration. |
| (new row) | Billing.Funding | WRITER (INSERT) | Creates new funding instrument record. IsBlocked=0 (not blocked on creation). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment registration service | @FundingTypeID | EXEC | Called when customer registers a new payment method. |

---

## 6. Dependencies

```
Billing.FundingAdd (procedure)
+-- Billing.Funding (table)
+-- Dictionary.FundingType (table) [cross-schema, validation]
```

---

## 7. Technical Details

**Removed XML validation**: Comments show the schema lookup + CLR.ParseXML block was removed from active code. FundingData is now inserted without format validation.

**DocumentRequired**: Only CreditCard (FundingTypeID=1) sets this to 1. This flag drives the KYC document upload requirement in the payment onboarding flow.

---

## 8. Sample Queries

```sql
DECLARE @NewFundingID INT;
EXEC [Billing].[FundingAdd]
    @FundingID = @NewFundingID OUTPUT,
    @FundingTypeID = 1,   -- CreditCard
    @FundingData = N'<Funding><CardToken>tok_xxxx</CardToken></Funding>',
    @ManagerID = NULL,
    @KeyVersion = 3;
SELECT @NewFundingID AS NewFundingID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.FundingAdd.sql*
