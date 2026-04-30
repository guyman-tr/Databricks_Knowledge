# Dictionary.PayoutProcessReason

> Lookup table defining the 10 reasons why a payout (withdrawal) processing operation reached its current state — from success (None) through technical, validation, provider, and communication errors.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PayoutProcessReasonID (INT, PK) |
| **Partition** | PRIMARY filegroup (PAGE compression) |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.PayoutProcessReason classifies the reasons behind a payout processing outcome within the billing system. When the platform processes a customer withdrawal (payout), the operation can succeed or fail for various reasons — technical errors, validation failures, unsupported providers, communication timeouts, or provider-side rejections.

This table exists because payout failures require different remediation paths. A technical error (1) may resolve on retry, while an unsupported provider (3) requires routing to a different payment method. A validation error (2) indicates the payout request itself has issues. Understanding the failure reason drives the automated retry logic and manual intervention workflows.

The PayoutProcessReasonID is stored in Billing.PayoutProcess and used by Billing.PayoutProcess_UpdateStatus, Billing.PayoutProcess_Update, Billing.PayoutProcess_CreateRecords, and the LoadPayoutProcessData procedures for payout lifecycle management.

---

## 2. Business Logic

### 2.1 Payout Failure Classification

**What**: Ten categories classify why a payout processing operation is in its current state, from success to various failure types.

**Columns/Parameters Involved**: `PayoutProcessReasonID`, `Name`

**Rules**:
- **None (0)** — No reason needed — the payout was processed successfully or is in a clean state.
- **Technical (1)** — Internal system error. Usually transient and eligible for automatic retry.
- **Validation (2)** — The payout request failed validation (e.g., invalid account details, amount exceeds limits).
- **UnsupportedProvider (3)** — The payment provider configured for this payout does not support the requested operation or currency.
- **Communication (4)** — Network or connectivity failure between eToro and the payment provider.
- **NoRecordsFound (5)** — The payout system could not find the expected records (e.g., missing deposit to refund against).
- **ProviderError (6)** — The external payment provider returned an error (e.g., declined by bank, insufficient provider balance).
- **FundingError (7)** — Error related to the customer's funding method (e.g., expired card, closed bank account).
- **DepositNotFound (8)** — The payout references a deposit that cannot be located (required for refund-to-source).
- **IncorrectStatus (9)** — The payout is in an unexpected status for the requested operation.

**Diagram**:
```
Payout Process Reasons
├── 0 = None (success / clean state)
├── Internal Errors
│   ├── 1 = Technical (system error, retryable)
│   └── 9 = IncorrectStatus (state mismatch)
├── Request Issues
│   ├── 2 = Validation (bad input)
│   ├── 5 = NoRecordsFound (missing data)
│   └── 8 = DepositNotFound (missing deposit)
├── Provider Issues
│   ├── 3 = UnsupportedProvider
│   ├── 4 = Communication (connectivity)
│   └── 6 = ProviderError (external rejection)
└── Funding Issues
    └── 7 = FundingError (payment method problem)
```

---

## 3. Data Overview

| PayoutProcessReasonID | Name | Meaning |
|---|---|---|
| 0 | None | Payout processed successfully or in a clean state — no failure reason applies. The default value for healthy payout records. |
| 1 | Technical | Internal system error during payout processing. Usually transient (timeouts, service unavailability) and eligible for automatic retry. |
| 3 | UnsupportedProvider | The payment provider does not support the requested payout operation, currency, or destination. Requires routing to an alternative provider. |
| 6 | ProviderError | The external payment provider rejected the payout — bank declined, insufficient provider balance, or provider-specific validation failure. |
| 8 | DepositNotFound | The payout system tried to refund against the original deposit (refund-to-source compliance) but could not locate the deposit record. Requires manual investigation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PayoutProcessReasonID | int | NO | - | VERIFIED | Primary key identifying the payout process reason. 0=None (success), 1=Technical, 2=Validation, 3=UnsupportedProvider, 4=Communication, 5=NoRecordsFound, 6=ProviderError, 7=FundingError, 8=DepositNotFound, 9=IncorrectStatus. Stored in Billing.PayoutProcess. |
| 2 | Name | varchar(50) | YES | - | VERIFIED | Human-readable label for the reason. Used in payout status reports and billing operations dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.PayoutProcess | PayoutProcessReasonID | Implicit | Stores the reason for each payout processing outcome |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PayoutProcess | Table | Stores PayoutProcessReasonID per payout record |
| Billing.PayoutProcess_UpdateStatus | Stored Procedure | Modifier — updates payout status with reason |
| Billing.PayoutProcess_Update | Stored Procedure | Modifier — updates payout process records |
| Billing.PayoutProcess_CreateRecords | Stored Procedure | Writer — creates payout records with initial reason |
| Billing.LoadPayoutProcessData | Stored Procedure | Reader — loads payout data including reasons |
| Billing.LoadPayoutProcessData_v2 | Stored Procedure | Reader — v2 of payout data loader |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_PayoutProcessReason | CLUSTERED PK | PayoutProcessReasonID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_PayoutProcessReason | PRIMARY KEY | Unique payout process reason identifier |

---

## 8. Sample Queries

### 8.1 List all payout process reasons
```sql
SELECT  PayoutProcessReasonID,
        Name
FROM    [Dictionary].[PayoutProcessReason] WITH (NOLOCK)
ORDER BY PayoutProcessReasonID;
```

### 8.2 Join payout records to reason descriptions
```sql
SELECT  pp.PayoutProcessID,
        pp.PayoutProcessReasonID,
        ppr.Name AS ReasonName
FROM    [Billing].[PayoutProcess] pp WITH (NOLOCK)
JOIN    [Dictionary].[PayoutProcessReason] ppr WITH (NOLOCK)
        ON pp.PayoutProcessReasonID = ppr.PayoutProcessReasonID
WHERE   pp.PayoutProcessReasonID > 0;
```

### 8.3 Count payouts by failure reason
```sql
SELECT  ppr.Name AS ReasonName,
        COUNT(*) AS PayoutCount
FROM    [Billing].[PayoutProcess] pp WITH (NOLOCK)
JOIN    [Dictionary].[PayoutProcessReason] ppr WITH (NOLOCK)
        ON pp.PayoutProcessReasonID = ppr.PayoutProcessReasonID
GROUP BY ppr.Name
ORDER BY PayoutCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PayoutProcessReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PayoutProcessReason.sql*
