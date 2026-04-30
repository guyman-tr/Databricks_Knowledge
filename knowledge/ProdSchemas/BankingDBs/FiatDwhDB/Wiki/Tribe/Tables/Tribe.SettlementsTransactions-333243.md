# Tribe.SettlementsTransactions-333243

> Parent container table for Tribe SettlementsTransactions data files containing settlement/clearing transaction records from the provider.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

SettlementsTransactions-333243 stores Tribe settlement transaction files. Child tables: SettlementsTransactions_SettlementTransaction-637239, SettlementsTransactions_RiskActions-236807, SettlementsTransactions_SecurityChecks-426253. Contains post-authorization settlement/clearing records.

---

## 2. Business Logic

### 2.1 JSON File Container Pattern

Same pattern. Children reference via @SettlementsTransactions@Id-333243.

---

## 3. Data Overview

N/A - file container metadata.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Unique file identifier. PK. |
| 3 | @FileName | nvarchar(max) | YES | - | CODE-BACKED | Source file name. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source system timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tribe.SettlementsTransactions_SettlementTransaction-637239 | Implicit FK | Implicit FK | Settlement details |
| Tribe.SettlementsTransactions_RiskActions-236807 | Implicit FK | Implicit FK | Risk actions |
| Tribe.SettlementsTransactions_SecurityChecks-426253 | Implicit FK | Implicit FK | Security checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| 3 child tables | Tables | Reference via @SettlementsTransactions@Id-333243 |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SettlementsTransactions-333243 | CLUSTERED | @Id ASC | - | - | Active |
| IX_SettlementsTransactions-333243_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (defaults) | DEFAULT | @Created and Created default to getutcdate() |

---

## 8. Sample Queries

### 8.1 View recent settlement files
```sql
SELECT TOP 10 [@Id], [@FileName], Created FROM Tribe.[SettlementsTransactions-333243] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Join with settlement details
```sql
SELECT TOP 5 p.[@FileName], c.* FROM Tribe.[SettlementsTransactions-333243] p WITH (NOLOCK)
JOIN Tribe.[SettlementsTransactions_SettlementTransaction-637239] c WITH (NOLOCK) ON c.[@SettlementsTransactions@Id-333243] = p.[@Id] ORDER BY p.Created DESC;
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Tribe.[SettlementsTransactions-333243] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.SettlementsTransactions-333243 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.SettlementsTransactions-333243.sql*
