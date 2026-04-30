# Wallet.AddTransactionTravelRuleInformation

> Creates or retrieves a Travel Rule information record for a crypto transaction, capturing fiat conversion details, counterparty address, and provider message reference for regulatory compliance.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TransactionTravelRuleInformationId (new or existing) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates the Travel Rule compliance record for a crypto transaction. The Travel Rule (FATF Recommendation 16) requires Virtual Asset Service Providers (VASPs) to exchange originator and beneficiary information for transfers above certain thresholds. This record stores the fiat equivalent value, exchange rate, counterparty address, and a link to the external compliance provider's message.

Without this procedure, eToro could not comply with Travel Rule regulations, which would block high-value crypto transfers and expose the company to regulatory penalties.

The procedure is idempotent - if a record already exists for the given RequestId, it returns the existing ID instead of creating a duplicate. This handles retry scenarios gracefully. It returns the TransactionTravelRuleInformationId for use by subsequent procedures (AddTransactionTravelRuleStatus, AddTravelRuleBeneficiaryDetails).

---

## 2. Business Logic

### 2.1 Idempotent Create-or-Return Pattern

**What**: Prevents duplicate Travel Rule records for the same request.

**Columns/Parameters Involved**: `@RequestId`, `TransactionTravelRuleInformation.Id`

**Rules**:
- First checks if a record exists with the given @RequestId
- If found, returns the existing Id without modification
- If not found, inserts a new record and returns the new Id via SCOPE_IDENTITY()
- Uses TRY/CATCH with THROW for clean error propagation

### 2.2 Fiat Conversion Snapshot

**What**: Captures the fiat equivalent value at the time of the transaction for regulatory reporting.

**Columns/Parameters Involved**: `@FiatSymbol`, `@FiatAmount`, `@FiatRate`, `@FiatRateCalculationTime`

**Rules**:
- FiatSymbol is the target fiat currency (e.g., USD, EUR)
- FiatAmount is the converted value in that fiat currency
- FiatRate is the crypto-to-fiat exchange rate used
- FiatRateCalculationTime records when the rate was calculated (rate staleness matters for compliance)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestId | bigint | NO | - | CODE-BACKED | The wallet request ID this Travel Rule record belongs to. Links to Wallet.Requests. Used for idempotency check. |
| 2 | @RequestCorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Correlation ID of the parent request for cross-system traceability. |
| 3 | @FiatSymbol | varchar(10) | NO | - | CODE-BACKED | ISO currency code of the fiat equivalent (e.g., "USD", "EUR", "GBP"). Required for Travel Rule threshold determination. |
| 4 | @FiatAmount | decimal(28,8) | NO | - | CODE-BACKED | The transaction value converted to fiat currency. Used to determine if the transfer exceeds the Travel Rule threshold (typically $1,000 or EUR 1,000). |
| 5 | @FiatRate | decimal(28,8) | NO | - | CODE-BACKED | The crypto-to-fiat exchange rate used for the conversion. Preserved for audit trail and rate dispute resolution. |
| 6 | @FiatRateCalculationTime | datetime2 | NO | - | CODE-BACKED | Timestamp when the exchange rate was calculated. Important for proving the rate was current at transaction time. |
| 7 | @CounterpartyAddress | varchar(512) | NO | - | CODE-BACKED | The blockchain address of the counterparty (recipient for sends, sender for receives). Key Travel Rule data point for VASP identification. |
| 8 | @BeneficiaryAddressType | varchar(10) | YES | '' | CODE-BACKED | Type classification of the beneficiary address (e.g., "hosted", "unhosted"). Determines which Travel Rule workflow applies. Defaults to empty string. |
| 9 | @ProviderMessageId | uniqueidentifier | YES | NULL | CODE-BACKED | Reference to the compliance provider's Travel Rule message (e.g., Notabene, Sygna). NULL if no provider message was initiated yet. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RequestId | Wallet.Requests | Implicit | Parent wallet request |
| INSERT target | Wallet.TransactionTravelRuleInformation | Writer | Creates Travel Rule record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.AddTransactionTravelRuleStatus | @TransactionTravelRuleInformationId | Consumer | Uses the returned ID to add status entries |
| Wallet.AddTravelRuleBeneficiaryDetails | @TransactionTravelRuleInformationId | Consumer | Uses the returned ID to add beneficiary details |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddTransactionTravelRuleInformation (procedure)
  └── Wallet.TransactionTravelRuleInformation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleInformation | Table | INSERT target + existence check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AddTransactionTravelRuleStatus | Stored Procedure | Consumes the returned ID |
| Wallet.AddTravelRuleBeneficiaryDetails | Stored Procedure | Consumes the returned ID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses TRY/CATCH with THROW for error handling
- NOLOCK hint on the existence check SELECT
- SCOPE_IDENTITY() used (safer than @@IDENTITY)
- Occurred column is auto-set to GETUTCDATE()

---

## 8. Sample Queries

### 8.1 View Travel Rule records for recent requests
```sql
SELECT TOP 20 Id, RequestId, FiatSymbol, FiatAmount, FiatRate, CounterpartyAddress, Occurred
FROM Wallet.TransactionTravelRuleInformation WITH (NOLOCK)
ORDER BY Id DESC
```

### 8.2 Find Travel Rule info by request correlation
```sql
SELECT tri.Id, tri.RequestId, tri.FiatSymbol, tri.FiatAmount, tri.CounterpartyAddress,
       tri.BeneficiaryAddressType, tri.ProviderMessageId
FROM Wallet.TransactionTravelRuleInformation tri WITH (NOLOCK)
WHERE tri.RequestCorrelationId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
```

### 8.3 Travel Rule records with their latest status
```sql
SELECT tri.Id, tri.RequestId, tri.FiatSymbol, tri.FiatAmount, tri.CounterpartyAddress,
       trs.TravelRuleStatusId, trs.Created AS StatusDate
FROM Wallet.TransactionTravelRuleInformation tri WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 TravelRuleStatusId, Created
    FROM Wallet.TransactionTravelRuleStatuses WITH (NOLOCK)
    WHERE TransactionTravelRuleInformationId = tri.Id
    ORDER BY Id DESC
) trs
ORDER BY tri.Id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddTransactionTravelRuleInformation | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddTransactionTravelRuleInformation.sql*
