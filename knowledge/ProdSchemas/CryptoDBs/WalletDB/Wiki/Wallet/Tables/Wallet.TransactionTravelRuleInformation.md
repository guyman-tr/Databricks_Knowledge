# Wallet.TransactionTravelRuleInformation

> Stores Travel Rule compliance information for cross-VASP crypto transactions, recording the counterparty address, fiat equivalent amounts, beneficiary address type, and provider message linkage.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table stores the Travel Rule compliance data required for crypto transactions above certain fiat thresholds. International regulations (FATF Travel Rule) require VASPs to collect and share originator/beneficiary information for qualifying transfers. Each row links a request to its Travel Rule data: the counterparty address, fiat equivalent (for threshold checking), address type (private/hosted), and the provider's message ID for inter-VASP communication.

With 34K rows, this covers transactions that triggered Travel Rule requirements. FK to Wallet.Requests links each Travel Rule record to its parent transaction request. Referenced by child tables: TransactionTravelRuleStatuses (compliance workflow status) and TransactionTravelRuleBeneficiaryDetails (beneficiary identity information).

---

## 2. Business Logic

### 2.1 Fiat Threshold Determination

**What**: The fiat equivalent amount determines whether Travel Rule compliance is required.

**Columns/Parameters Involved**: `FiatAmount`, `FiatSymbol`, `FiatRate`, `FiatConversionTime`

**Rules**:
- FiatAmount and FiatSymbol record the transaction value in fiat for threshold comparison
- FiatRate captures the conversion rate used, with FiatRateCalculationTime tracking when the rate was fetched
- Different jurisdictions have different thresholds (e.g., EUR 1000 in EU, USD 3000 in US)
- BeneficiaryAddressType determines the compliance requirements: "Private" (self-hosted) vs "Hosted" (VASP)

---

## 3. Data Overview

N/A for compliance data table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing PK. FK target for TransactionTravelRuleStatuses and TransactionTravelRuleBeneficiaryDetails. |
| 2 | RequestId | bigint | NO | - | VERIFIED | Parent request. FK to Wallet.Requests.Id. Links Travel Rule data to the transaction request. |
| 3 | RequestCorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Parent request's CorrelationId for cross-service lookups. |
| 4 | FiatSymbol | varchar(10) | YES | - | CODE-BACKED | Fiat currency used for threshold calculation (e.g., "USD", "EUR"). |
| 5 | FiatAmount | decimal(28,8) | YES | - | CODE-BACKED | Transaction value in fiat for threshold comparison. |
| 6 | Occurred | datetime2(7) | YES | getutcdate() | CODE-BACKED | Record creation timestamp. |
| 7 | FiatRateCalculationTime | datetime2(7) | YES | - | CODE-BACKED | When the fiat conversion rate was fetched. |
| 8 | CounterpartyAddress | nvarchar(512) | NO | - | CODE-BACKED | Blockchain address of the counterparty (recipient for sends, sender for receives). |
| 9 | FiatConversionTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | When the fiat conversion was performed. |
| 10 | FiatRate | decimal(28,8) | YES | - | CODE-BACKED | Crypto-to-fiat conversion rate used. |
| 11 | BeneficiaryAddressType | varchar(10) | NO | - | CODE-BACKED | Whether the counterparty address is "Private" (self-hosted wallet) or "Hosted" (VASP-custodied). Determines compliance requirements. |
| 12 | ProviderMessageId | uniqueidentifier | YES | - | CODE-BACKED | Message ID from the Travel Rule provider (e.g., Notabene) for inter-VASP information sharing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RequestId | Wallet.Requests | FK | Parent transaction request |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.TransactionTravelRuleStatuses | TransactionTravelRuleInformationId | FK | Compliance workflow statuses |
| Wallet.TransactionTravelRuleBeneficiaryDetails | TravelRuleInformationId | FK | Beneficiary identity details |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.TransactionTravelRuleInformation (table)
└── Wallet.Requests (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FK target for RequestId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleStatuses | Table | FK on TransactionTravelRuleInformationId |
| Wallet.TransactionTravelRuleBeneficiaryDetails | Table | FK on TravelRuleInformationId |
| Wallet.AddTransactionTravelRuleInformation | Stored Procedure | Creates records |
| Wallet.GetTransactionTravelRuleInformationIdByRequestId | Stored Procedure | Looks up by RequestId |
| Wallet.GetTransactionTravelRuleInformationIdByCorrelationId | Stored Procedure | Looks up by CorrelationId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TransactionTravelRuleInformation | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...RequestCorrelationId | NC | RequestCorrelationId | - | - | Active |
| IX_...RequestId | NC | RequestId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (Occurred) | DEFAULT | getutcdate() |
| DF (FiatConversionTime) | DEFAULT | getutcdate() |
| FK_...RequestId | FK | -> Wallet.Requests.Id |

---

## 8. Sample Queries

### 8.1 Get Travel Rule info for a request
```sql
SELECT ttri.Id, ttri.CounterpartyAddress, ttri.BeneficiaryAddressType, ttri.FiatAmount, ttri.FiatSymbol
FROM Wallet.TransactionTravelRuleInformation ttri WITH (NOLOCK)
WHERE ttri.RequestId = 4990718
```

### 8.2 Recent Travel Rule transactions
```sql
SELECT TOP 20 ttri.Id, ttri.RequestId, ttri.CounterpartyAddress, ttri.BeneficiaryAddressType, ttri.FiatAmount, ttri.Occurred
FROM Wallet.TransactionTravelRuleInformation ttri WITH (NOLOCK)
ORDER BY ttri.Occurred DESC
```

### 8.3 Travel Rule volume by address type
```sql
SELECT BeneficiaryAddressType, COUNT(*) AS Cnt, AVG(FiatAmount) AS AvgFiatAmount
FROM Wallet.TransactionTravelRuleInformation WITH (NOLOCK)
WHERE FiatAmount IS NOT NULL
GROUP BY BeneficiaryAddressType
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.TransactionTravelRuleInformation | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.TransactionTravelRuleInformation.sql*
