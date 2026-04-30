# Wallet.GetAmlValidation

> Retrieves the most recent AML (Anti-Money Laundering) validation result for a transaction identified by correlation ID and direction (send/receive).

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns latest AML validation for correlation + direction |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure looks up the AML screening result for a specific crypto transaction. Every outgoing (send) and incoming (receive) transaction undergoes AML screening by an external provider (e.g., Chainalysis, Elliptic). The screening evaluates whether the counterparty address is associated with sanctioned entities, illicit activities, or high-risk categories. This procedure returns the latest screening result for a given transaction.

Without this procedure, the system could not check AML screening outcomes when making go/no-go decisions on transaction processing. AML validation is a mandatory compliance checkpoint in the send and receive pipelines.

The procedure returns TOP 1 ordered by Created DESC, giving the most recent validation in case multiple screenings were performed (e.g., recheck after initial screening).

---

## 2. Business Logic

### 2.1 Direction-Specific Lookup

**What**: AML validations are stored separately for send and receive directions of the same correlation.

**Columns/Parameters Involved**: `@CorrelationId`, `@IsSendTransaction`

**Rules**:
- @IsSendTransaction = 1 retrieves the send-side AML check (outgoing transaction)
- @IsSendTransaction = 0 retrieves the receive-side AML check (incoming transaction)
- A single correlation ID can have both send and receive AML validations
- Returns the most recent result (TOP 1 ORDER BY Created DESC) for the direction

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Correlation ID of the transaction to look up AML screening for. |
| 2 | @IsSendTransaction | bit | NO | - | CODE-BACKED | Direction filter: 1 = outgoing/send, 0 = incoming/receive. Determines which AML check to return. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | AML validation record ID. |
| 2 | AmlProviderId | int | NO | - | CODE-BACKED | Which AML screening provider performed the check. |
| 3 | IsSend | bit | NO | - | CODE-BACKED | Transaction direction (1=send, 0=receive). |
| 4 | Address | nvarchar(512) | NO | - | CODE-BACKED | The blockchain address that was screened. |
| 5 | WalletId | uniqueidentifier | YES | - | CODE-BACKED | The wallet involved in the transaction. |
| 6 | Amount | decimal | YES | - | CODE-BACKED | Transaction amount being screened. |
| 7 | ProviderStatus | nvarchar | YES | - | CODE-BACKED | Raw status from the AML provider (e.g., "approved", "flagged", "blocked"). |
| 8 | IsPositiveDecision | bit | YES | - | CODE-BACKED | Whether the AML check passed (1) or failed (0). Simplified boolean for go/no-go decisions. |
| 9 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Transaction correlation ID. |
| 10 | Created | datetime2 | NO | - | CODE-BACKED | When this AML validation was recorded. |
| 11 | BlockchainTransactionId | nvarchar | YES | - | CODE-BACKED | On-chain transaction hash, if available at screening time. |
| 12 | DetailsJson | nvarchar(MAX) | YES | - | CODE-BACKED | Full JSON response from the AML provider with detailed risk assessment. |
| 13 | CryptoId | int | YES | - | CODE-BACKED | Cryptocurrency being transacted. |
| 14 | CategoryId | int | YES | - | CODE-BACKED | Risk category assigned by the AML provider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.AmlValidations | Reader | Source of AML validation data |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetAmlValidation (procedure)
  └── Wallet.AmlValidations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AmlValidations | Table | SELECT source |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOLOCK hint, SET NOCOUNT ON
- TOP 1 ORDER BY Created DESC for latest result

---

## 8. Sample Queries

### 8.1 Get AML validation for a send transaction
```sql
EXEC Wallet.GetAmlValidation @CorrelationId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6', @IsSendTransaction = 1
```

### 8.2 Find failed AML checks
```sql
SELECT TOP 20 Id, CorrelationId, Address, ProviderStatus, IsPositiveDecision, CryptoId, Created
FROM Wallet.AmlValidations WITH (NOLOCK)
WHERE IsPositiveDecision = 0
ORDER BY Created DESC
```

### 8.3 AML validation results by provider
```sql
SELECT AmlProviderId, IsPositiveDecision, COUNT(*) AS Cnt
FROM Wallet.AmlValidations WITH (NOLOCK)
GROUP BY AmlProviderId, IsPositiveDecision
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetAmlValidation | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetAmlValidation.sql*
