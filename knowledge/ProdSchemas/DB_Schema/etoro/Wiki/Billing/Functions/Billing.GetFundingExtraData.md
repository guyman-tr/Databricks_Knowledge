# Billing.GetFundingExtraData

> Scalar function that retrieves a customer's most recently used bank details (BIC and BankName) for a given funding type, returned as a JSON object for pre-populating withdrawal bank fields.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns NVARCHAR(MAX) - JSON: {"LastUsedBank":{"Bic":"...","BankName":"..."}} |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetFundingExtraData provides the "smart pre-fill" capability for withdrawal bank fields. When a customer initiates a withdrawal via a funding type that requires bank details (e.g., wire transfer), the system calls this function to retrieve their most recently used BIC and bank name from previous deposits. This pre-populates the withdrawal form, reducing friction for repeat customers who always use the same bank.

This function exists because the relevant bank details are stored in historical funding data (from deposits), not in a dedicated "customer's bank" table. By querying `Billing.Funding` and `Billing.Deposit` for the most recent non-empty BIC and BankName combination, the function bridges the deposit history into the withdrawal flow.

The returned JSON `{"LastUsedBank":{"Bic":"...","BankName":"..."}}` is consumed by payment processing services that use it to pre-populate withdrawal forms. Returns NULL if no suitable historical funding record exists.

---

## 2. Business Logic

### 2.1 Last Used Bank Lookup

**What**: Finds the most recent deposit where the funding record has a non-empty BIC and the deposit has a non-empty BankName.

**Columns/Parameters Involved**: `@CID`, `@FundingTypeID`

**Rules**:
- Queries `Billing.Funding` INNER JOIN `Billing.Deposit` on FundingID.
- Filters: FundingTypeID = @FundingTypeID, BicCodeAsString in FundingData is non-empty, BankNameAsString in PaymentData is non-empty.
- Orders by FundingID DESC -> returns the most recently created funding record matching criteria.
- Returns TOP(1) - the single most recent bank combination.
- LTRIM/RTRIM + ISNULL checks handle whitespace-only values as empty.

**Diagram**:
```
Customer @CID submits withdrawal using @FundingTypeID
    |
SELECT TOP(1) FROM Billing.Funding f
JOIN Billing.Deposit d ON f.FundingID = d.FundingID
WHERE f.FundingTypeID = @FundingTypeID
  AND f.FundingData.BicCodeAsString IS NOT empty
  AND d.PaymentData.BankNameAsString IS NOT empty
  AND d.CID = @CID
ORDER BY f.FundingID DESC
    |
Returns: {"LastUsedBank":{"Bic":"MRMIGB22XXX","BankName":"Metro Bank PLC"}}
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Customer ID. Filters Billing.Deposit.CID to only retrieve this customer's deposit history. |
| 2 | @FundingTypeID | int | NO | - | VERIFIED | The payment method to look up bank details for. Filters Billing.Funding.FundingTypeID. Typically called for wire transfer types (FundingTypeID=2, 34, 35, etc.) where BIC and bank name are required. |
| RETURN | nvarchar(max) | YES | - | VERIFIED | JSON string `{"LastUsedBank":{"Bic":"...","BankName":"..."}}` where Bic comes from FundingData XML and BankName from PaymentData XML. Returns NULL if no qualifying historical record exists for this customer+funding type combination. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + FundingTypeID | Billing.Funding | Lookup (JOIN) | Reads FundingData XML to extract BIC code from previous funding records. |
| @CID | Billing.Deposit | Lookup (JOIN) | Reads PaymentData XML to extract bank name from previous deposits, filtered by CID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetDepositsCustomerCardPCIVersion | @CID, @FundingTypeID | Caller | Procedure that retrieves customer deposit/card data, calls this to include last-used bank details. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetFundingExtraData (function)
├── Billing.Funding (table)
└── Billing.Deposit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | Reads FundingData XML (BicCodeAsString) and FundingTypeID filter. |
| Billing.Deposit | Table | Reads PaymentData XML (BankNameAsString) and CID filter. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetDepositsCustomerCardPCIVersion | Stored Procedure | Calls this to retrieve last-used bank details per customer/funding type. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | NOT schema-bound. |
| Hardcoded JSON keys | Design | Returns `$.LastUsedBank.Bic` and `$.LastUsedBank.BankName` - callers must know these exact key paths. |
| Non-empty filter | Logic | Uses ISNULL(LTRIM(RTRIM(value)), '') <> '' to treat whitespace-only values as empty (more robust than IS NOT NULL alone). |

---

## 8. Sample Queries

### 8.1 Get last used bank for a customer's wire transfer

```sql
SELECT Billing.GetFundingExtraData(12345, 2) AS LastUsedBankJSON;
-- Returns: {"LastUsedBank":{"Bic":"MRMIGB22XXX","BankName":"Metro Bank"}}
-- or NULL if no history
```

### 8.2 Parse the returned JSON inline

```sql
DECLARE @json NVARCHAR(MAX) = Billing.GetFundingExtraData(12345, 2);
SELECT
    JSON_VALUE(@json, '$.LastUsedBank.Bic') AS LastBIC,
    JSON_VALUE(@json, '$.LastUsedBank.BankName') AS LastBankName;
```

### 8.3 Check last bank for multiple customers

```sql
SELECT TOP 10
    d.CID,
    Billing.GetFundingExtraData(d.CID, 2) AS LastWireBank
FROM (SELECT DISTINCT CID FROM Billing.Deposit WITH (NOLOCK) WHERE CID > 0) d
WHERE Billing.GetFundingExtraData(d.CID, 2) IS NOT NULL
ORDER BY d.CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetFundingExtraData | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.GetFundingExtraData.sql*
