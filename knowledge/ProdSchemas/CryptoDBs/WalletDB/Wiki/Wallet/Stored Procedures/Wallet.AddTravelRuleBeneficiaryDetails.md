# Wallet.AddTravelRuleBeneficiaryDetails

> Stores beneficiary identity details for a Travel Rule transaction, enforcing a one-to-one relationship by raising an error if details already exist for the given Travel Rule information record.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | New row in Wallet.TransactionTravelRuleBeneficiaryDetails |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure stores the beneficiary's identity details for a specific Travel Rule transaction. While AddTravelRuleAddress captures the destination address and geographic data, this procedure captures the beneficiary's name and a detailed JSON payload of identity information received from the counterparty VASP. This data is required by regulators to prove that eToro collected and verified beneficiary information before processing the transfer.

Without this procedure, eToro could not store beneficiary identity data received from counterparty VASPs, making Travel Rule compliance incomplete.

Unlike the idempotent Travel Rule address procedure, this one enforces strict uniqueness - if beneficiary details already exist for the TravelRuleInformationId, it raises an error (RAISERROR severity 16). This prevents accidental overwrites of compliance data.

---

## 2. Business Logic

### 2.1 Strict One-to-One Enforcement

**What**: Exactly one beneficiary details record per Travel Rule information record.

**Columns/Parameters Involved**: `@TransactionTravelRuleInformationId`

**Rules**:
- Uses INSERT with WHERE NOT EXISTS (with UPDLOCK, HOLDLOCK hints for concurrency safety)
- If @@ROWCOUNT = 0 (row already exists), raises error: "Beneficiary details already exist for this TravelRuleInformationId"
- The UPDLOCK + HOLDLOCK hints prevent race conditions where two concurrent calls could both pass the NOT EXISTS check

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TransactionTravelRuleInformationId | bigint | NO | - | CODE-BACKED | The Travel Rule information record to attach beneficiary details to. Obtained from AddTransactionTravelRuleInformation. |
| 2 | @BeneficiaryName | nvarchar(512) | NO | - | CODE-BACKED | Full name of the beneficiary as provided by the counterparty VASP or the customer. Required by Travel Rule regulations. |
| 3 | @DetailsJson | varchar(MAX) | NO | - | CODE-BACKED | JSON payload containing structured beneficiary identity details (e.g., date of birth, account number, VASP name, additional KYC data). Schema varies by Travel Rule provider and jurisdiction. |
| 4 | @CorrelationId | uniqueidentifier | YES | NULL | CODE-BACKED | Optional correlation ID linking this record to the originating request. NULL for legacy records or provider-initiated updates. |
| 5 | @TransactionType | nvarchar(50) | YES | 'Default' | CODE-BACKED | Type of Travel Rule transaction (e.g., "Default", "Receive", "Send"). Defaults to "Default". Allows different handling based on transaction direction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TransactionTravelRuleInformationId | Wallet.TransactionTravelRuleInformation | FK | Parent Travel Rule record |
| INSERT target | Wallet.TransactionTravelRuleBeneficiaryDetails | Writer | Creates beneficiary details |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application compliance services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddTravelRuleBeneficiaryDetails (procedure)
  └── Wallet.TransactionTravelRuleBeneficiaryDetails (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleBeneficiaryDetails | Table | INSERT target + uniqueness check |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses UPDLOCK + HOLDLOCK hints on the NOT EXISTS check for concurrency safety
- RAISERROR with severity 16 if duplicate detected
- SET NOCOUNT ON

---

## 8. Sample Queries

### 8.1 View beneficiary details for a Travel Rule record
```sql
SELECT Id, TravelRuleInformationId, BeneficiaryName, DetailsJson, TransactionType, Created
FROM Wallet.TransactionTravelRuleBeneficiaryDetails WITH (NOLOCK)
WHERE TravelRuleInformationId = 12345
```

### 8.2 Recent beneficiary details entries
```sql
SELECT TOP 20 bd.Id, bd.BeneficiaryName, bd.TransactionType, bd.Created,
       tri.RequestId, tri.CounterpartyAddress
FROM Wallet.TransactionTravelRuleBeneficiaryDetails bd WITH (NOLOCK)
JOIN Wallet.TransactionTravelRuleInformation tri WITH (NOLOCK) ON tri.Id = bd.TravelRuleInformationId
ORDER BY bd.Id DESC
```

### 8.3 Count beneficiary details by transaction type
```sql
SELECT TransactionType, COUNT(*) AS Cnt
FROM Wallet.TransactionTravelRuleBeneficiaryDetails WITH (NOLOCK)
GROUP BY TransactionType
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddTravelRuleBeneficiaryDetails | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddTravelRuleBeneficiaryDetails.sql*
