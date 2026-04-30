# dbo.AccountsProviderHoldersMapping

> Mapping table linking internal fiat account IDs to provider-side (Tribe) holder identifiers for cross-system reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

AccountsProviderHoldersMapping bridges the internal fiat account system with the external provider (Tribe) by storing the mapping between the platform's AccountId and Tribe's ProviderHolderId. This is essential for cross-system reconciliation, support investigations, and provider API calls.

This table exists because the platform and the provider use different identifier systems. When a fiat account is created, Tribe assigns its own holder ID. This mapping table allows looking up the Tribe holder ID from an internal account (or vice versa), which is needed for provider API calls, balance reconciliation, and support troubleshooting.

Data is created by dbo.AddAccountsProviderHoldersMapping when the operational system registers the provider mapping. Confluence documents this as a primary lookup pattern: "Get the accountId from the providerHolderId (Tribe)".

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a straightforward ID mapping table.

---

## 3. Data Overview

| Id | AccountId | ProviderHolderId | Created | Meaning |
|---|---|---|---|---|
| 2136062 | 2135575 | 16588734 | 2026-04-14 13:51 | Account 2135575 is holder 16588734 in Tribe |
| 2136061 | 2135574 | 16588733 | 2026-04-14 13:51 | Account 2135574 is holder 16588733 in Tribe |
| 2136060 | 2135573 | 16588732 | 2026-04-14 13:50 | Account 2135573 is holder 16588732 in Tribe |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | AccountId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatAccount.Id. The internal platform account this mapping belongs to. |
| 3 | ProviderHolderId | nvarchar(128) | NO | - | CODE-BACKED | The external provider's (Tribe) identifier for this account holder. Used in all provider API interactions and support queries. Stored as string to accommodate different provider ID formats. |
| 4 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this mapping was recorded in the data warehouse. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountId | dbo.FiatAccount | FK | Links to the internal fiat account |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddAccountsProviderHoldersMapping | INSERT | Writer | Creates provider holder mappings |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AccountsProviderHoldersMapping (table)
└── dbo.FiatAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccount | Table | FK from AccountId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddAccountsProviderHoldersMapping | Stored Procedure | Inserts mappings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AccountsProviderHoldersMapping | CLUSTERED | Id ASC | - | - | Active |
| nci_wi_AccountsProviderHoldersMapping_... | NONCLUSTERED | AccountId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_AccountsProviderHoldersMapping_Accounts | FK | AccountId -> dbo.FiatAccount.Id |

---

## 8. Sample Queries

### 8.1 Find Tribe holder ID for an account
```sql
SELECT ProviderHolderId FROM dbo.AccountsProviderHoldersMapping WITH (NOLOCK) WHERE AccountId = 2135575;
```

### 8.2 Find account by Tribe holder ID
```sql
SELECT a.Gcid, a.AccountGuid, m.ProviderHolderId
FROM dbo.AccountsProviderHoldersMapping m WITH (NOLOCK)
JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = m.AccountId
WHERE m.ProviderHolderId = '16588734';
```

### 8.3 Find account by GCID with provider mapping
```sql
SELECT a.Id AS AccountId, m.ProviderHolderId, a.AccountGuid
FROM dbo.FiatAccount a WITH (NOLOCK)
JOIN dbo.AccountsProviderHoldersMapping m WITH (NOLOCK) ON m.AccountId = a.Id
WHERE a.Gcid = 17689308;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | "Get the accountId from the providerHolderId (Tribe)" - primary lookup pattern documented |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AccountsProviderHoldersMapping | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.AccountsProviderHoldersMapping.sql*
