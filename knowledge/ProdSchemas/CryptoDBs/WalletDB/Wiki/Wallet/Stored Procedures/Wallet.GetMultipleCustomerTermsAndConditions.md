# Wallet.GetMultipleCustomerTermsAndConditions

> Checks a customer's terms-and-conditions acceptance status across multiple T&C types, returning whether each type is first-time, signed, or requires an update.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns T&C status per type for a given customer |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure determines whether a customer has accepted the current version of each requested terms-and-conditions type. Before a customer can perform certain crypto operations (withdrawals, staking, new features), the system must verify they have signed the latest T&C for that operation type. This procedure checks multiple T&C types in a single call, returning a status for each: 'FirstTime' (never signed), 'Signed' (signed current version), or 'UpdateRequired' (signed an older version).

Without this check, the platform could allow customers to perform operations without proper legal consent, creating regulatory and compliance risk. The multi-type batch design avoids N+1 query patterns when checking prerequisites for operations that require multiple T&C acceptances.

Data flows from the input @TypeIds (table-valued parameter) joined to `Wallet.TermsAndConditions` to find the current version per type, then LEFT JOINed to `Wallet.CustomerTermsAndConditions` to find the customer's signed version. The CASE expression compares signed version to current version to determine the status.

---

## 2. Business Logic

### 2.1 T&C Status Determination

**What**: Classifies each T&C type into one of three states based on the customer's acceptance history.

**Columns/Parameters Involved**: `TermsAndConditionId`, `CurrentVersionId`, `@Gcid`, `TypeId`

**Rules**:
- 'FirstTime': Customer has never signed any version of this T&C type (TermsAndConditionId IS NULL)
- 'Signed': Customer's signed version matches the current version (TermsAndConditionId = CurrentVersionId)
- 'UpdateRequired': Customer signed an older version (TermsAndConditionId <> CurrentVersionId)
- Current version = most recent by Occured date within each TypeId (ROW_NUMBER ORDER BY Occured DESC, RowNum=1)
- Customer's signed version = latest signed record per type (ROW_NUMBER ORDER BY TermsAndConditionId DESC, RowNum=1)

**Diagram**:
```
@TypeIds (requested T&C types)
    |
    +-- JOIN TermsAndConditions -> current version per type (latest by Occured)
    |     -> #TermsAndConditions (TypeId, CurrentVersionId, Url)
    |
    +-- LEFT JOIN CustomerTermsAndConditions (for @Gcid)
    |     -> customer's signed version per type
    |
    v
CASE:
  NULL signed version       -> 'FirstTime'
  Signed = Current version  -> 'Signed'
  Signed <> Current version -> 'UpdateRequired'
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | BIGINT | NO | - | CODE-BACKED | Global Customer ID. Identifies the customer whose T&C status is being checked. |
| 2 | @TypeIds | Wallet.IntListType (READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing the T&C type IDs to check. Each Item value corresponds to a TermsAndConditions.TypeId. Allows batch checking multiple types in one call. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | TypeId | INT | NO | - | CODE-BACKED | The T&C type identifier. Matches the input @TypeIds. FK to TermsAndConditions.TypeId. |
| 4 | CurrentVersionId | INT | NO | - | CODE-BACKED | The ID of the current (latest) version of this T&C type. FK to Wallet.TermsAndConditions.Id. |
| 5 | Url | NVARCHAR | YES | - | CODE-BACKED | URL to the current T&C document. Used by the UI to display the document for the customer to review and sign. |
| 6 | TandCStatus | VARCHAR(20) | NO | - | CODE-BACKED | Acceptance status: 'FirstTime' (never signed any version), 'Signed' (signed current version - no action needed), 'UpdateRequired' (signed older version - must re-accept). Drives UI flow for T&C gating. |
| 7 | SignedAt | DATETIME2 | YES | - | CODE-BACKED | Timestamp when the customer last signed a version of this T&C type. NULL when TandCStatus='FirstTime'. From CustomerTermsAndConditions.Occured. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TypeIds | Wallet.IntListType | UDT | Table-valued parameter for batch type ID input |
| TypeId | Wallet.TermsAndConditions | JOIN | Gets current version per T&C type |
| @Gcid + TermsAndConditionId | Wallet.CustomerTermsAndConditions | LEFT JOIN | Gets customer's signed version per type |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by application services during operation prerequisite checks.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetMultipleCustomerTermsAndConditions (procedure)
+-- Wallet.IntListType (UDT)
+-- Wallet.TermsAndConditions (table)
+-- Wallet.CustomerTermsAndConditions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.IntListType | User Defined Type | Parameter type for @TypeIds |
| Wallet.TermsAndConditions | Table | JOIN - current version lookup per type |
| Wallet.CustomerTermsAndConditions | Table | LEFT JOIN - customer acceptance history |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Temp table | #TermsAndConditions | Caches the current version per T&C type to avoid re-querying in the second SELECT |

---

## 8. Sample Queries

### 8.1 Check T&C status for a customer
```sql
DECLARE @Types Wallet.IntListType;
INSERT INTO @Types (Item) VALUES (1), (2), (3);
EXEC Wallet.GetMultipleCustomerTermsAndConditions @Gcid = 12345, @TypeIds = @Types;
```

### 8.2 Find the current version of each T&C type
```sql
SELECT TypeId, Id AS CurrentVersionId, Url, Occured
FROM (
    SELECT TypeId, Id, Url, Occured,
           ROW_NUMBER() OVER (PARTITION BY TypeId ORDER BY Occured DESC) AS RowNum
    FROM Wallet.TermsAndConditions WITH (NOLOCK)
) t
WHERE RowNum = 1
ORDER BY TypeId;
```

### 8.3 Find customers who need to re-accept updated T&C
```sql
SELECT DISTINCT ctac.Gcid
FROM Wallet.CustomerTermsAndConditions ctac WITH (NOLOCK)
JOIN Wallet.TermsAndConditions tac WITH (NOLOCK) ON tac.Id = ctac.TermsAndConditionId
WHERE tac.Id <> (
    SELECT TOP 1 Id FROM Wallet.TermsAndConditions t WITH (NOLOCK)
    WHERE t.TypeId = tac.TypeId ORDER BY t.Occured DESC
);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetMultipleCustomerTermsAndConditions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetMultipleCustomerTermsAndConditions.sql*
