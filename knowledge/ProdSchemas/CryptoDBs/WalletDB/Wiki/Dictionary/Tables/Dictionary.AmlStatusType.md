# Dictionary.AmlStatusType

> Lookup table defining the possible outcomes of an AML (Anti-Money Laundering) screening check on a cryptocurrency address or transaction.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (int, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the three possible outcomes of an AML compliance check performed on a cryptocurrency address or transaction. Every address screened through the AML system receives one of these statuses, which determines whether a transaction is allowed to proceed.

AML screening is a gating step in the crypto transaction lifecycle. Without clear status outcomes, the system could not make automated pass/fail decisions on transactions, and compliance teams could not audit screening results.

The status values are consumed by application logic and stored in `Wallet.AmlValidations` to record the outcome of each individual AML check. The business flow is: address submitted -> AML provider screens it -> result stored with one of these status types.

---

## 2. Business Logic

### 2.1 AML Screening Outcomes

**What**: Three-state outcome model for AML compliance checks.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Pass` (0): The address/transaction passed all AML checks - no risk flags detected, transaction may proceed
- `Rejected` (1): The address/transaction was rejected by the AML provider - risk flags detected (e.g., sanctioned entity, darknet market), transaction must be blocked
- `Failed` (2): The AML check itself failed (technical error, provider timeout, etc.) - the compliance status is unknown and the transaction requires manual review or retry

**Diagram**:
```
AML Check Initiated
    |
    +---> Pass (0)     --> Transaction proceeds normally
    |
    +---> Rejected (1) --> Transaction blocked, compliance alert raised
    |
    +---> Failed (2)   --> Technical failure, manual review required
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 0 | Pass | Address or transaction cleared all AML screening checks. No risk indicators detected by any provider. The transaction is approved to proceed through the normal flow. |
| 1 | Rejected | AML provider identified risk indicators on the address or transaction. The address may be associated with sanctioned entities, illicit activity, or high-risk categories. Transaction is blocked and a compliance alert is generated. |
| 2 | Failed | The AML screening check encountered a technical error (provider unavailable, timeout, malformed response). The compliance status is indeterminate. Requires either automated retry or manual compliance review before the transaction can proceed. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Unique identifier for the AML status. Values: 0=Pass, 1=Rejected, 2=Failed. Note: 0 is the "success" value, distinguishing it from typical 1-based enums. Referenced by AML validation records. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Human-readable label for the AML outcome. Used in compliance dashboards, audit reports, and internal tooling. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK references found in the Wallet schema. Consumed implicitly by `Wallet.AmlValidations` and application-layer AML screening logic.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No direct dependents found in the Wallet schema SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AmlStatusType_Id | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all AML status types
```sql
SELECT Id, Name
FROM Dictionary.AmlStatusType WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Count AML validations by status
```sql
SELECT ast.Id, ast.Name, COUNT(av.Id) AS ValidationCount
FROM Dictionary.AmlStatusType ast WITH (NOLOCK)
LEFT JOIN Wallet.AmlValidations av WITH (NOLOCK) ON av.AmlStatusTypeId = ast.Id
GROUP BY ast.Id, ast.Name
ORDER BY ast.Id
```

### 8.3 Find rejected AML validations with provider details
```sql
SELECT av.Id, ap.Name AS Provider, ast.Name AS Status, av.Created
FROM Wallet.AmlValidations av WITH (NOLOCK)
JOIN Dictionary.AmlStatusType ast WITH (NOLOCK) ON av.AmlStatusTypeId = ast.Id
JOIN Dictionary.AmlProviders ap WITH (NOLOCK) ON av.AmlProviderId = ap.Id
WHERE ast.Id = 1 -- Rejected
ORDER BY av.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 3.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AmlStatusType | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.AmlStatusType.sql*
