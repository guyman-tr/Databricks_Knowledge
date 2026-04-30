# Wallet.TransactionTravelRuleStatuses

> Event-sourced status history for Travel Rule compliance workflows, tracking each step of the beneficiary information collection and approval process.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table tracks the compliance workflow status for Travel Rule records from `Wallet.TransactionTravelRuleInformation`. Each row records a status transition in the Travel Rule compliance flow: PendingManualApproval -> Approved/Canceled, or PendingMissingInformation -> MissingInformationAdded -> Approved. See [Travel Rule Status](../../_glossary.md#travel-rule-status).

FK to TransactionTravelRuleInformation.Id and implicit reference to Dictionary.TravelRuleStatuses.

---

## 2. Business Logic

No complex logic. Status event log for Travel Rule compliance workflow.

---

## 3. Data Overview

N/A for compliance status table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing event identifier. |
| 2 | TransactionTravelRuleInformationId | bigint | NO | - | VERIFIED | Parent Travel Rule record. FK to Wallet.TransactionTravelRuleInformation.Id. |
| 3 | TravelRuleStatusId | tinyint | NO | - | CODE-BACKED | Status: 0=PendingManualApproval, 1=Approved, 2=Canceled, 3=PendingMissingInformation, 4=MissingInformationAdded, 5=MustCancel. See [Travel Rule Status](../../_glossary.md#travel-rule-status). |
| 4 | Occurred | datetime2(7) | YES | getutcdate() | CODE-BACKED | Timestamp of status transition. |
| 5 | DetailsJson | varchar(max) | YES | - | CODE-BACKED | JSON with status-specific details (approval notes, missing info details). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransactionTravelRuleInformationId | Wallet.TransactionTravelRuleInformation | FK | Parent Travel Rule record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.AddTransactionTravelRuleStatus | - | Writer | Appends status events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.TransactionTravelRuleStatuses (table)
└── Wallet.TransactionTravelRuleInformation (table)
      └── Wallet.Requests (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleInformation | Table | FK target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AddTransactionTravelRuleStatus | Stored Procedure | Inserts status events |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TransactionTravelRuleStatuses | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...TransactionTravelRuleInformationId_Id | NC | TransactionTravelRuleInformationId, Id DESC | - | - | Active |
| IX_...TransactionTravelRuleInformationId_Occurred | NC | TransactionTravelRuleInformationId, Occurred DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (Occurred) | DEFAULT | getutcdate() |
| FK_...TransactionTravelRuleInformationId | FK | -> Wallet.TransactionTravelRuleInformation.Id |

---

## 8. Sample Queries

### 8.1 Status history for a Travel Rule record
```sql
SELECT ttrs.TravelRuleStatusId, ttrs.Occurred, ttrs.DetailsJson
FROM Wallet.TransactionTravelRuleStatuses ttrs WITH (NOLOCK)
WHERE ttrs.TransactionTravelRuleInformationId = 33916 ORDER BY ttrs.Id
```

### 8.2 Pending approvals
```sql
SELECT TransactionTravelRuleInformationId, Occurred
FROM Wallet.TransactionTravelRuleStatuses WITH (NOLOCK)
WHERE TravelRuleStatusId = 0 ORDER BY Occurred DESC
```

### 8.3 Travel Rule outcome distribution
```sql
SELECT TravelRuleStatusId, COUNT(*) AS Cnt FROM Wallet.TransactionTravelRuleStatuses WITH (NOLOCK) GROUP BY TravelRuleStatusId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.TransactionTravelRuleStatuses | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.TransactionTravelRuleStatuses.sql*
