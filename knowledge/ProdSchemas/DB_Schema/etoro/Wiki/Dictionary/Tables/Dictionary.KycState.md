# Dictionary.KycState

> Lookup table defining whether a customer's KYC (Know Your Customer) documents have been reviewed by the compliance team.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, PK CLUSTERED) |
| **Partition** | No — on PRIMARY |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.KycState tracks the document-review stage for a customer's KYC submission. Every new customer record defaults to state 0 ("Haven't seen"), meaning compliance has not yet reviewed their identity documents. Once a compliance agent opens and reviews the documents, the state transitions to 1 ("seen").

This table exists because regulatory obligations (MiFID II, ASIC, CySEC) require the platform to know whether a customer's identity documents have been visually inspected. Other KYC-related columns (VerificationLevelID, MifidCategorizationID) track the *outcome* of review; KycState tracks whether review has *begun*.

The KycState value is written by `Customer.UpdateAccountUserInfoRemote` (single-customer update) and `BackOffice.Bulk_UpdateAccountUserInfoRemote` (bulk compliance operations). It is read by virtually every customer aggregation procedure (`Customer.GetAggregatedInfo*`, `Customer.GetPrivateAggregatedInfo*`, `Customer.GetAccountUserInfo`) to surface the review status to back-office UIs and API consumers.

---

## 2. Business Logic

### 2.1 Binary Review Gate

**What**: A simple two-state flag indicating whether compliance has opened a customer's KYC documents.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- New customers default to KycState = 0 ("Haven't seen") — the DEFAULT constraint on both BackOffice.Customer.KycState and UserApiDB Customer.AccountUserInfo.KycState is 0
- Once compliance opens/reviews the documents, KycState is set to 1 ("seen") via `UpdateAccountUserInfoRemote`
- KycState is independent of the verification outcome — a customer can be "seen" but still rejected

**Diagram**:
```
Customer Registration
        │
        ▼
  KycState = 0 ("Haven't seen")
        │
  Compliance opens documents
        │
        ▼
  KycState = 1 ("seen")
```

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 0 | Haven't seen | Default state for every new customer — compliance has not yet opened or reviewed the customer's KYC identity documents |
| 1 | seen | A compliance team member has opened and visually reviewed the customer's submitted identity documents, regardless of approval outcome |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | KYC review state identifier: **0** = Haven't seen (documents not yet opened by compliance), **1** = seen (compliance has reviewed documents). Referenced by BackOffice.Customer.KycState and UserApiDB Customer.AccountUserInfo.KycState. |
| 2 | Name | varchar(50) | YES | - | CODE-BACKED | Human-readable label for the KYC review state. Values: "Haven't seen", "seen". Used in back-office UIs for compliance dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Customer | KycState | Implicit (DEFAULT 0) | Stores the KYC review state per customer in the back-office customer record |
| UserApiDB Customer.AccountUserInfo | KycState | Implicit (DEFAULT 0) | Stores the KYC review state in the User API customer profile |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.KycState (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | Stores KycState column referencing this lookup |
| Customer.UpdateAccountUserInfoRemote | Stored Procedure | Writes KycState value for individual customers |
| BackOffice.Bulk_UpdateAccountUserInfoRemote | Stored Procedure | Bulk-updates KycState for multiple customers |
| Customer.GetPrivateAggregatedInfo | Stored Procedure | Reads KycState for customer profile aggregation |
| Customer.GetSingleAggregatedInfo | Stored Procedure | Reads KycState in single-customer detail view |
| Customer.GetManyAggregatedInfo | Stored Procedure | Reads KycState in bulk customer retrieval |
| Customer.GetAccountUserInfo | Stored Procedure | Reads KycState for account user info |
| Customer.GetAccountInfo | Stored Procedure | Reads KycState for account info |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_KycState | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_KycState | PRIMARY KEY | Unique KYC state identifier, FILLFACTOR 90, DATA_COMPRESSION PAGE |

---

## 8. Sample Queries

### 8.1 List all KYC review states
```sql
SELECT  ID,
        Name
FROM    Dictionary.KycState WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find customers whose KYC has not been reviewed
```sql
SELECT  CID,
        KycState
FROM    BackOffice.Customer WITH (NOLOCK)
WHERE   KycState = 0;
```

### 8.3 Count customers by KYC review status with labels
```sql
SELECT  ks.Name         AS KycStateName,
        COUNT(*)        AS CustomerCount
FROM    BackOffice.Customer c WITH (NOLOCK)
JOIN    Dictionary.KycState ks WITH (NOLOCK) ON c.KycState = ks.ID
GROUP BY ks.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Historical reference found in code comments: "Geri Reshef, 05/10/2016, 41155, DB - Add KycState field" indicating the column was added in October 2016.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.KycState | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.KycState.sql*
