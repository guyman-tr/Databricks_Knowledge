# Tribe.Lookups-75520

> Parent container table for Tribe Lookups data files containing reference data (status codes, action types, etc.) from the provider.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (+ PK) |

---

## 1. Business Meaning

Lookups-75520 stores Tribe lookup/reference data files. This is the parent for the largest set of child tables (32 children), covering all Tribe reference data: AccountStatusCodes, ActionTypes, AuthorizationCodes, CardEvents, CardStatusCodes, EntryModeCodes, ExternalPaymentTransactionStatusCodes/Types, FunctionCodes, LoadSources, LoadTypes, Networks, RegionTypes, RiskActions, SecurityChecks, TransactionCodes.

Each lookup type has two child tables: a singular (e.g., Lookups_AccountStatusCode) and a plural collection (e.g., Lookups_AccountStatusCodes).

---

## 2. Business Logic

### 2.1 JSON File Container with Extensive Lookup Children

Same container pattern. Children reference via @Lookups@Id-75520. Has the most child tables of any parent (32 children = 16 lookup types x 2 tables each).

---

## 3. Data Overview

N/A - file container metadata.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Unique file identifier. PK. |
| 3 | @FileName | nvarchar(4000) | YES | - | CODE-BACKED | Source file name. |
| 4 | IssuerIdentificationNumber | nvarchar(4000) | YES | - | CODE-BACKED | Tribe issuer identification number for this lookup set. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source system timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

32 child tables reference this via @Lookups@Id-75520 (16 lookup types x 2 tables each).

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

32 Lookups_* child tables.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Lookups-75520 | CLUSTERED | @Id ASC | - | - | Active |
| IX_FiatDWHDB_Tribe_Lookups-75520_@Created | NONCLUSTERED | @Created ASC | - | - | Active |
| IX_Lookups-75520_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (defaults) | DEFAULT | @Created and Created default to getutcdate() |

---

## 8. Sample Queries

### 8.1 View recent lookup files
```sql
SELECT TOP 10 [@Id], [@FileName], IssuerIdentificationNumber, Created FROM Tribe.[Lookups-75520] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Join with account status codes
```sql
SELECT TOP 5 p.[@FileName], c.* FROM Tribe.[Lookups-75520] p WITH (NOLOCK)
JOIN Tribe.[Lookups_AccountStatusCodes-618179] c WITH (NOLOCK) ON c.[@Lookups@Id-75520] = p.[@Id] ORDER BY p.Created DESC;
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups-75520] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.Lookups-75520 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Lookups-75520.sql*
