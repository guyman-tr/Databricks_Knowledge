# Billing.WithdrawAdditionalParameters

> Extension table storing optional typed parameters for withdrawal requests (bank details, KYC documents, card identifiers, FX parameters), where each row is one parameter type for one withdrawal.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (WithdrawID, ParameterTypeID) - composite CLUSTERED PK |
| **Partition** | No - stored on MAIN filegroup |
| **Indexes** | 1 active (CLUSTERED PK on WithdrawID + ParameterTypeID) |

---

## 1. Business Meaning

Billing.WithdrawAdditionalParameters is an extension table that stores optional supplementary parameters for withdrawal requests. While `Billing.Withdraw` holds the core withdrawal data (amount, status, customer ID), this table handles the overflow of type-specific information that only applies to certain withdrawal methods or regulatory requirements. Each row is one parameter type for one withdrawal, forming an EAV (Entity-Attribute-Value) structure.

This table exists because different withdrawal methods require different sets of data: bank wire withdrawals need IBAN/BIC/SortCode, eToro card withdrawals need the card ID, regulatory flows need the customer's personal ID or proof-of-identity document, and internal currency transfers need FX rate details. Rather than adding columns to `Billing.Withdraw` for every possible combination, this extension table stores only what is relevant to each withdrawal type.

Data is written by `Billing.Withdrawservice_AdditionalParametersAdd` (called during the withdrawal request creation flow) and by `Billing.WithdrawalService_WithdrawRequestAdd`. Only non-NULL parameters are inserted - the procedure checks each parameter and only inserts a row if the value was provided. A withdrawal may have 0 to N rows here depending on its withdrawal method and regulatory requirements.

---

## 2. Business Logic

### 2.1 Withdrawal Method Parameter Sets

**What**: Different withdrawal methods require different subsets of parameters, stored as typed rows.

**Columns/Parameters Involved**: `ParameterTypeID`, `ParameterValue`

**Rules**:
- Bank wire withdrawals (ParameterTypeID 8-11): IBAN, BankAccountNumber, BIC, SortCode - UK withdrawals use BankAccountNumber (9) + SortCode (11), international use IBAN (8) + BIC (10).
- eToro card withdrawals (ParameterTypeID 3, 4): EtoroCardId + Last4Digits for card identification.
- Regulatory/compliance flows (ParameterTypeID 1, 6): ClientPersonalId for identity, ProofOfMop for document proof.
- Internal/eToroMoney transfers (ParameterTypeID 13): InternalTransferParameters as a JSON blob containing FX rate, exchange fee, asset currency, and result queue name.

**Diagram**:
```
Bank Wire (SEPA/International):
  ParameterTypeID=8  -> IBAN (e.g., "DE89370400440532013000")
  ParameterTypeID=10 -> BIC  (e.g., "MRMIGB22XXX")

Bank Wire (UK Faster Payments):
  ParameterTypeID=9  -> BankAccountNumber (e.g., "12345678")
  ParameterTypeID=11 -> SortCode (e.g., "041335")

eToro Money Internal Transfer:
  ParameterTypeID=13 -> JSON: {AssetCurrency, Rate, BaseRate, ExchangeFee, AmountInCurrency, ResultQueueName}

Compliance Documents:
  ParameterTypeID=1  -> ClientPersonalId (national ID number)
  ParameterTypeID=6  -> ProofOfMop (document image filename, e.g., "2019Catwoman.png")
```

### 2.2 EAV Pattern and Type 13 JSON Structure

**What**: ParameterTypeID=13 (InternalTransferParameters) stores a structured JSON blob for currency conversion tracking in eToroMoney transfers.

**Columns/Parameters Involved**: `ParameterValue` where `ParameterTypeID=13`

**Rules**:
- JSON fields: `AssetCurrency` (target currency abbreviation), `Rate` (final FX rate used), `BaseRate` (base rate before fee markup), `ExchangeFee` (fee in currency units), `ExchangeFeeInUsd` (fee converted to USD), `ExchangeFeeInPercentage` (null if fixed fee), `FeeConfigurationId`, `AmountInCurrency` (target currency amount), `ResultQueueName` (message bus queue for async result delivery).
- This is the most data-rich parameter type, used for eToroMoney local-currency withdrawal flows.
- Example: `{"AssetCurrency":"GBP","Rate":0.86340000,"BaseRate":0.85700000,"ExchangeFee":64,"ExchangeFeeInUsd":0.555,"AmountInCurrency":30,"ResultQueueName":"moneybus-adapter-result"}`

---

## 3. Data Overview

| WithdrawID | ParameterTypeID | ParameterValue | Meaning |
|-----------|----------------|----------------|---------|
| 1734993 | 6 (ProofOfMop) | 2019Catwoman.png | Customer submitted a proof-of-payment document for this withdrawal. The value is the filename of the uploaded document stored in a file system/blob store. |
| 1734993 | 2 (IntermediaryBankDetails) | (empty string) | Intermediary bank details field was submitted but is empty - the customer indicated no intermediary bank is required for their wire transfer. |
| 1734992 | 13 (InternalTransferParameters) | {"AssetCurrency":"GBP","Rate":0.8634,"BaseRate":0.857,"ExchangeFee":64,...} | eToroMoney internal transfer - the system recorded the GBP exchange rate (0.8634 USD/GBP), the exchange fee ($0.555 USD), and the target amount (30 GBP) for audit and dispute resolution. |
| 1734981 | 10 (Bic) | MRMIGB22XXX | BIC/SWIFT code of the destination bank for an international wire transfer - MRMIGB22XXX is a UK bank identifier. |
| 1734981 | 11 (SortCode) | 041335 | UK bank sort code accompanying the BIC, used for UK Faster Payments domestic routing. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | int | NO | - | VERIFIED | FK to Billing.Withdraw (WithdrawID). Identifies the withdrawal request this parameter belongs to. Groups all additional parameters for one withdrawal. Enforced by FK_WithdrawAdditionalParameters_Withdraw. |
| 2 | ParameterTypeID | int | NO | - | VERIFIED | FK to Dictionary.WithdrawAdditionalParameterType (ID). Identifies the type of supplementary data stored in ParameterValue. Known values: 1=ClientPersonalId, 2=IntermediaryBankDetails, 3=EtoroCardId, 4=Last4Digits, 5=NonValidMop, 6=ProofOfMop, 7=CurrencyBalanceId, 8=Iban, 9=BankAccountNumber, 10=Bic, 11=SortCode, 12=OptionsCreditCounter, 13=InternalTransferParameters. Enforced by FK_WithdrawAdditionalParameters_WithdrawAdditionalParameterType. |
| 3 | ParameterValue | nvarchar(4000) | YES | - | VERIFIED | The actual value of the parameter, typed according to ParameterTypeID. Content varies by type: plain strings (IBAN, sort code, BIC), filenames (ProofOfMop), numeric strings (ClientPersonalId, OptionsCreditCounter), or JSON blobs (InternalTransferParameters). nvarchar(4000) accommodates the largest type (InternalTransferParameters JSON, up to ~700 chars per parameter schema). NULL not expected in practice (procedure only inserts non-NULL values). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw | FK (FK_WithdrawAdditionalParameters_Withdraw) | Links supplementary parameters to the parent withdrawal request. |
| ParameterTypeID | Dictionary.WithdrawAdditionalParameterType | FK (FK_WithdrawAdditionalParameters_WithdrawAdditionalParameterType) | Resolves the numeric type to its name (ClientPersonalId, Bic, SortCode, etc.). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Withdrawservice_AdditionalParametersAdd | @WithdrawID + typed params | Writer | Inserts individual parameter rows conditionally (only non-NULL parameters). Called during withdrawal request creation. |
| Billing.WithdrawalService_WithdrawRequestAdd | (via the above) | Writer | Initiates the withdrawal creation flow which triggers AdditionalParametersAdd. |
| Billing.WithdrawService_GetWithdrawCashouts | WithdrawID | Reader | Reads additional parameters when retrieving cashout information for a withdrawal. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawAdditionalParameters (table)
(no code-level dependencies - leaf table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | FK target - WithdrawID must exist in Billing.Withdraw |
| Dictionary.WithdrawAdditionalParameterType | Table | FK target - ParameterTypeID must exist in this lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdrawservice_AdditionalParametersAdd | Stored Procedure | Writer - inserts conditional parameter rows for a withdrawal |
| Billing.WithdrawService_GetWithdrawCashouts | Stored Procedure | Reader - reads parameters when building withdrawal cashout response |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingWithdrawAdditionalParameters | CLUSTERED PK | WithdrawID ASC, ParameterTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingWithdrawAdditionalParameters | PRIMARY KEY | One row per (WithdrawID, ParameterTypeID) - each withdrawal can have at most one value per parameter type. |
| FK_WithdrawAdditionalParameters_Withdraw | FOREIGN KEY | WithdrawID must exist in Billing.Withdraw - prevents orphaned parameters. |
| FK_WithdrawAdditionalParameters_WithdrawAdditionalParameterType | FOREIGN KEY | ParameterTypeID must exist in Dictionary.WithdrawAdditionalParameterType - ensures valid parameter types only. |

---

## 8. Sample Queries

### 8.1 Get all additional parameters for a specific withdrawal (resolved names)

```sql
SELECT
    wap.WithdrawID,
    wapt.ParameterType,
    wap.ParameterValue
FROM Billing.WithdrawAdditionalParameters wap WITH (NOLOCK)
JOIN Dictionary.WithdrawAdditionalParameterType wapt WITH (NOLOCK) ON wapt.ID = wap.ParameterTypeID
WHERE wap.WithdrawID = 1734993
ORDER BY wap.ParameterTypeID;
```

### 8.2 Find all bank wire withdrawals with IBAN (international bank transfers)

```sql
SELECT TOP 100
    wap.WithdrawID,
    wap.ParameterValue AS IBAN,
    bic.ParameterValue AS BIC
FROM Billing.WithdrawAdditionalParameters wap WITH (NOLOCK)
LEFT JOIN Billing.WithdrawAdditionalParameters bic WITH (NOLOCK)
    ON bic.WithdrawID = wap.WithdrawID AND bic.ParameterTypeID = 10  -- Bic
WHERE wap.ParameterTypeID = 8  -- Iban
ORDER BY wap.WithdrawID DESC;
```

### 8.3 Find eToroMoney transfers and their currency exchange data

```sql
SELECT TOP 20
    wap.WithdrawID,
    JSON_VALUE(wap.ParameterValue, '$.AssetCurrency') AS TargetCurrency,
    JSON_VALUE(wap.ParameterValue, '$.Rate') AS ExchangeRate,
    JSON_VALUE(wap.ParameterValue, '$.AmountInCurrency') AS TargetAmount,
    JSON_VALUE(wap.ParameterValue, '$.ExchangeFeeInUsd') AS FeeUSD
FROM Billing.WithdrawAdditionalParameters wap WITH (NOLOCK)
WHERE wap.ParameterTypeID = 13  -- InternalTransferParameters
ORDER BY wap.WithdrawID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 VERIFIED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawAdditionalParameters | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.WithdrawAdditionalParameters.sql*
