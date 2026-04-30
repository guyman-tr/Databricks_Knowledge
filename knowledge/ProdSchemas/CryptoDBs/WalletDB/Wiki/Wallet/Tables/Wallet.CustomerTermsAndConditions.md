# Wallet.CustomerTermsAndConditions

> Records each customer's acceptance of Terms and Conditions versions, tracking which T&C version each user has agreed to and when they accepted it.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table records every instance of a customer accepting a Terms and Conditions version. Each row links a customer (Gcid) to a specific T&C version (TermsAndConditionId). With ~3.4M rows, this reflects that many users have accepted multiple T&C versions over time as terms are updated.

When a user accesses the wallet, the system checks if they have accepted the latest T&C version for their legal entity. If not, they are prompted to accept before proceeding. This table stores the acceptance record. It is a critical compliance table - without it, the system could not verify user consent.

Rows are created by `Wallet.StoreCustomerTermsAndConditions` when a user clicks "Accept" on the T&C dialog. FK to `Wallet.TermsAndConditions.Id` ensures the referenced T&C version exists.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The table is a simple acceptance log. See individual element descriptions in Section 4.

---

## 3. Data Overview

| Id | Gcid | TermsAndConditionId | Occured | Meaning |
|---|---|---|---|---|
| 3406447 | 47473367 | 24 | 2026-04-14 16:45 | Customer accepted T&C version 24 (likely specific to their legal entity) |
| 3406446 | 47592378 | 31 | 2026-04-14 16:44 | Customer accepted T&C version 31 - different version for different entity |
| 3406445 | 42793023 | 32 | 2026-04-14 16:41 | Customer accepted T&C version 32 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID of the user who accepted. Indexed with TermsAndConditionId for per-user acceptance queries. |
| 3 | TermsAndConditionId | int | NO | - | VERIFIED | The T&C version accepted. FK to Wallet.TermsAndConditions.Id. Multiple rows per Gcid reflect acceptance of different versions over time. |
| 4 | Occured | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when the user accepted. Note: column name typo "Occured" preserved from original schema. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TermsAndConditionId | Wallet.TermsAndConditions | FK | Links to the T&C version accepted |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.StoreCustomerTermsAndConditions | - | Writer | Records acceptance events |
| Wallet.GetCustomerTermsAndConditions | - | Reader | Checks customer acceptance status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.CustomerTermsAndConditions (table)
└── Wallet.TermsAndConditions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TermsAndConditions | Table | FK target for TermsAndConditionId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.StoreCustomerTermsAndConditions | Stored Procedure | Records acceptance |
| Wallet.GetCustomerTermsAndConditions | Stored Procedure | Checks acceptance |
| Wallet.GetMultipleCustomerTermsAndConditions | Stored Procedure | Bulk checks |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerTermsAndConditions | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_CustomerTermsAndConditions_Gcid_Version | NC | Gcid, TermsAndConditionId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_CustomerTermsAndConditions_Occured | DEFAULT | getutcdate() |
| FK_...TermsAndConditionId | FK | TermsAndConditionId -> Wallet.TermsAndConditions.Id |

---

## 8. Sample Queries

### 8.1 Check if customer accepted latest T&C
```sql
SELECT ctc.TermsAndConditionId, tc.Version, ctc.Occured
FROM Wallet.CustomerTermsAndConditions ctc WITH (NOLOCK)
JOIN Wallet.TermsAndConditions tc WITH (NOLOCK) ON ctc.TermsAndConditionId = tc.Id
WHERE ctc.Gcid = 47473367
ORDER BY ctc.Id DESC
```

### 8.2 Customers who accepted a specific version
```sql
SELECT COUNT(DISTINCT Gcid) AS CustomerCount
FROM Wallet.CustomerTermsAndConditions WITH (NOLOCK)
WHERE TermsAndConditionId = 24
```

### 8.3 Full acceptance history for a customer
```sql
SELECT tc.Version, tc.TypeId, ctc.Occured
FROM Wallet.CustomerTermsAndConditions ctc WITH (NOLOCK)
JOIN Wallet.TermsAndConditions tc WITH (NOLOCK) ON ctc.TermsAndConditionId = tc.Id
WHERE ctc.Gcid = 47473367
ORDER BY ctc.Occured
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.CustomerTermsAndConditions | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.CustomerTermsAndConditions.sql*
