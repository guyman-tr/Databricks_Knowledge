# Billing.Withdrawservice_AdditionalParametersAdd

> Inserts optional supplementary parameters for a withdrawal request into the EAV extension table, writing one row per non-NULL parameter supplied by the caller.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawID - links all inserted rows to the parent withdrawal |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.Withdrawservice_AdditionalParametersAdd` is the write gateway for optional, method-specific withdrawal metadata stored in `Billing.WithdrawAdditionalParameters`. When a customer submits a withdrawal request, the core amount and status data go into `Billing.Withdraw`, while everything that depends on the withdrawal method (bank details, KYC documents, card identifiers, FX transfer parameters) is routed through this procedure.

The procedure exists because the set of metadata required varies by withdrawal channel: a SEPA wire needs IBAN + BIC, a UK Faster Payments transfer needs account number + sort code, an eToroMoney internal transfer needs a JSON blob with FX rate details, and a compliance-triggered withdrawal needs the customer's personal ID or proof-of-payment document. Storing this as an EAV (Entity-Attribute-Value) structure avoids adding dozens of sparse columns to `Billing.Withdraw`.

The procedure is called during the withdrawal request creation flow. Each parameter is checked individually: if the caller passes a non-NULL value, a row is inserted into `Billing.WithdrawAdditionalParameters` with the corresponding `ParameterTypeID`; if the value is NULL, no row is created. This means a withdrawal may end up with 0 to ~5 rows in the extension table depending on the withdrawal method.

---

## 2. Business Logic

### 2.1 Parameter-to-ParameterTypeID Mapping

**What**: Each optional parameter in this procedure maps to a fixed `ParameterTypeID` in `Billing.WithdrawAdditionalParameters`, forming the type classification for the EAV row.

**Columns/Parameters Involved**: All optional parameters, `ParameterTypeID` in target table

**Rules**:
- Only non-NULL parameters generate INSERT rows; NULL parameters are silently skipped.
- The mapping is fixed at development time - adding a new parameter type requires a code change to both this procedure and the target table's lookup.
- Two declared parameters (@ClientWithdrawCommentID and @EtoroCardId) exist in the signature but have no corresponding INSERT block - they are vestigial and effectively unused by this procedure.

**Diagram**:
```
@ClientPersonalID      (VARCHAR 30)   -> ParameterTypeID=1   (KYC: national ID)
@IntermediaryBankDetails (NVARCHAR 510) -> ParameterTypeID=2  (wire: intermediary bank)
@ClientWithdrawCommentID (INT)         -> [NO INSERT - unused parameter]
@CurrencyBalanceId     (NVARCHAR 100)  -> ParameterTypeID=7   (FX: eToroMoney balance ID)
@Last4Digits           (NVARCHAR 4)    -> ParameterTypeID=4   (card: last 4 digits)
@NonValidMop           (NVARCHAR 510)  -> ParameterTypeID=5   (compliance: invalid MOP detail)
@ProofOfMop            (NVARCHAR 510)  -> ParameterTypeID=6   (KYC: proof-of-method document)
@EtoroCardId           (NVARCHAR 30)   -> [NO INSERT - unused parameter]
@Iban                  (NVARCHAR 34)   -> ParameterTypeID=8   (bank wire: IBAN)
@BankAccountNumber     (NVARCHAR 10)   -> ParameterTypeID=9   (bank wire: UK account number)
@Bic                   (NVARCHAR 11)   -> ParameterTypeID=10  (bank wire: BIC/SWIFT code)
@SortCode              (NVARCHAR 8)    -> ParameterTypeID=11  (bank wire: UK sort code)
@CurrentOptionsCreditCounter (MONEY)   -> ParameterTypeID=12  (finance: options credit balance)
@InternalTransferParameters (NVARCHAR 700) -> ParameterTypeID=13 (FX: JSON transfer details)
```

### 2.2 Bank Wire Combinations

**What**: Bank wire withdrawals use specific pairs or groups of parameters depending on country.

**Columns/Parameters Involved**: `@Iban`, `@Bic`, `@BankAccountNumber`, `@SortCode`

**Rules**:
- International/SEPA wires: @Iban (ParameterTypeID=8) + @Bic (ParameterTypeID=10)
- UK Faster Payments: @BankAccountNumber (ParameterTypeID=9) + @SortCode (ParameterTypeID=11)
- @IntermediaryBankDetails (ParameterTypeID=2) is optional alongside any wire combination for correspondent bank routing details.

### 2.3 InternalTransferParameters JSON Structure

**What**: @InternalTransferParameters (ParameterTypeID=13) carries a structured JSON for eToroMoney FX conversion tracking.

**Columns/Parameters Involved**: `@InternalTransferParameters`

**Rules**:
- JSON fields: `AssetCurrency` (target currency code), `Rate` (final applied FX rate), `BaseRate` (rate before fee markup), `ExchangeFee` (fee in USD cents), `ExchangeFeeInUsd`, `ExchangeFeeInPercentage` (null for fixed fees), `FeeConfigurationId`, `AmountInCurrency` (target currency amount), `ResultQueueName` (async result message bus queue).
- Example: `{"AssetCurrency":"GBP","Rate":0.86340000,"BaseRate":0.85700000,"ExchangeFee":64,"ExchangeFeeInUsd":0.555,"AmountInCurrency":30,"ResultQueueName":"moneybus-adapter-result"}`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | INT | NO | - | CODE-BACKED | Required. FK to `Billing.Withdraw.WithdrawID`. All rows inserted by this call are linked to this withdrawal. Every INSERT uses this as the EAV row key. |
| 2 | @ClientPersonalID | VARCHAR(30) | YES | NULL | CODE-BACKED | Customer's national/personal ID number (e.g., passport or government ID). Required by certain withdrawal channels for identity verification. Inserted as ParameterTypeID=1. |
| 3 | @IntermediaryBankDetails | NVARCHAR(510) | YES | NULL | CODE-BACKED | Details of an intermediary (correspondent) bank for international wire routing. May be an empty string when the customer explicitly selects "no intermediary bank." Inserted as ParameterTypeID=2. |
| 4 | @ClientWithdrawCommentID | INT | YES | NULL | CODE-BACKED | Declared parameter with no INSERT block - effectively unused in this procedure. Vestigial; no row is written regardless of value supplied. |
| 5 | @CurrencyBalanceId | NVARCHAR(100) | YES | NULL | CODE-BACKED | eToroMoney currency balance identifier - ties the withdrawal to a specific FX wallet/balance in the eToroMoney system. Inserted as ParameterTypeID=7. |
| 6 | @Last4Digits | NVARCHAR(4) | YES | NULL | CODE-BACKED | Last 4 digits of the eToro card used for the withdrawal, for card identification. Inserted as ParameterTypeID=4. |
| 7 | @NonValidMop | NVARCHAR(510) | YES | NULL | CODE-BACKED | Description of a non-valid method-of-payment (MOP) - used in compliance flows when the customer's payment method fails validation. Inserted as ParameterTypeID=5. |
| 8 | @ProofOfMop | NVARCHAR(510) | YES | NULL | CODE-BACKED | Filename or reference to the customer's proof-of-method-of-payment document (e.g., "2019Catwoman.png"), uploaded for KYC/compliance. Inserted as ParameterTypeID=6. |
| 9 | @EtoroCardId | NVARCHAR(30) | YES | NULL | CODE-BACKED | Declared parameter with no INSERT block - effectively unused in this procedure. The eToro card ID is declared but no row is written for it here (ParameterTypeID=3 is never inserted). Vestigial parameter. |
| 10 | @Iban | NVARCHAR(34) | YES | NULL | CODE-BACKED | IBAN (International Bank Account Number) for SEPA/international wire withdrawals (max 34 chars per ISO 13616). Inserted as ParameterTypeID=8. |
| 11 | @BankAccountNumber | NVARCHAR(10) | YES | NULL | CODE-BACKED | UK domestic bank account number (8 digits) for UK Faster Payments withdrawals. Inserted as ParameterTypeID=9. |
| 12 | @Bic | NVARCHAR(11) | YES | NULL | CODE-BACKED | BIC/SWIFT code (8 or 11 chars) identifying the destination bank for international wires. Inserted as ParameterTypeID=10. |
| 13 | @SortCode | NVARCHAR(8) | YES | NULL | CODE-BACKED | UK bank sort code (6 digits, typically formatted as XX-XX-XX) for UK Faster Payments routing. Inserted as ParameterTypeID=11. |
| 14 | @CurrentOptionsCreditCounter | MONEY | YES | NULL | CODE-BACKED | Current options credit balance at the time of withdrawal request submission. Stored for financial audit/reconciliation purposes. Inserted as ParameterTypeID=12. |
| 15 | @InternalTransferParameters | NVARCHAR(700) | YES | NULL | CODE-BACKED | JSON blob for eToroMoney internal currency transfer details: FX rate, exchange fee, target currency amount, and async result queue name. See Section 2.3 for full JSON schema. Inserted as ParameterTypeID=13. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID | Billing.Withdraw | FK (implicit) | All inserted rows extend the withdrawal identified by this ID. |
| (all inserts) | Billing.WithdrawAdditionalParameters | Direct write | Each non-NULL parameter produces one INSERT row in this EAV table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.WithdrawRequestAdd | - | Caller (app layer) | Called during the withdrawal request creation flow when method-specific parameters need to be persisted. |
| Billing.WithdrawalService_WithdrawRequestAdd | - | Caller | Also calls this procedure as part of the withdrawal service request creation path. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Withdrawservice_AdditionalParametersAdd (procedure)
└── Billing.WithdrawAdditionalParameters (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawAdditionalParameters | Table | Written via INSERT for each non-NULL parameter supplied |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawalService_WithdrawRequestAdd | Procedure | Calls this procedure to persist method-specific withdrawal parameters |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Add bank wire parameters for a SEPA withdrawal

```sql
EXEC Billing.Withdrawservice_AdditionalParametersAdd
    @WithdrawID = 12345,
    @Iban = N'DE89370400440532013000',
    @Bic = N'COBADEFFXXX',
    @IntermediaryBankDetails = NULL;
```

### 8.2 Add UK Faster Payments parameters

```sql
EXEC Billing.Withdrawservice_AdditionalParametersAdd
    @WithdrawID = 12346,
    @BankAccountNumber = N'12345678',
    @SortCode = N'041335';
```

### 8.3 Retrieve all parameters for a withdrawal (with type labels)

```sql
SELECT
    wap.WithdrawID,
    wap.ParameterTypeID,
    wap.ParameterValue,
    CASE wap.ParameterTypeID
        WHEN 1  THEN 'ClientPersonalID'
        WHEN 2  THEN 'IntermediaryBankDetails'
        WHEN 4  THEN 'Last4Digits'
        WHEN 5  THEN 'NonValidMop'
        WHEN 6  THEN 'ProofOfMop'
        WHEN 7  THEN 'CurrencyBalanceId'
        WHEN 8  THEN 'IBAN'
        WHEN 9  THEN 'BankAccountNumber'
        WHEN 10 THEN 'BIC'
        WHEN 11 THEN 'SortCode'
        WHEN 12 THEN 'CurrentOptionsCreditCounter'
        WHEN 13 THEN 'InternalTransferParameters'
        ELSE    'Unknown'
    END AS ParameterTypeName
FROM Billing.WithdrawAdditionalParameters wap WITH (NOLOCK)
WHERE wap.WithdrawID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.Withdrawservice_AdditionalParametersAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.Withdrawservice_AdditionalParametersAdd.sql*
