# Wallet.TermsAndConditions_History

> System-managed temporal history table for Wallet.TermsAndConditions, automatically storing previous versions of T&C records when they are updated for regulatory audit compliance.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | No PK (heap with clustered index on temporal columns) |
| **Partition** | No |
| **Indexes** | 1 clustered index on (ValidTo, ValidFrom) |

---

## 1. Business Meaning

This is the system-managed temporal history table for `Wallet.TermsAndConditions`. SQL Server automatically moves previous row versions here when T&C records are updated. Essential for regulatory auditing: "what T&C version was active on date X?" queries use this history. The table mirrors the parent's column structure.

---

## 2. Business Logic

N/A - system-managed temporal history table.

---

## 3. Data Overview

N/A for temporal history.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | T&C record identifier (mirrors parent PK). |
| 2 | Version | varchar(20) | NO | - | CODE-BACKED | T&C version string. |
| 3 | Url | varchar(1024) | NO | - | CODE-BACKED | Document URL. |
| 4 | Occured | datetime2(7) | NO | - | CODE-BACKED | Publication timestamp. |
| 5 | TypeId | int | YES | - | CODE-BACKED | Legal entity type. |
| 6 | LinksJson | nvarchar(max) | YES | - | CODE-BACKED | Associated legal links JSON. |
| 7 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | When this version became active. |
| 8 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | When this version was superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.TermsAndConditions | Temporal | History table for the parent |

### 5.2 Referenced By (other objects point to this)

Not directly referenced. Accessed via FOR SYSTEM_TIME on parent.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies (system-managed).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TermsAndConditions | Table | Parent temporal table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_TermsAndConditions_History | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. System-managed table.

---

## 8. Sample Queries

### 8.1 View T&C history
```sql
SELECT * FROM Wallet.TermsAndConditions_History WITH (NOLOCK) ORDER BY ValidTo DESC
```

### 8.2 T&C active at a specific date via parent
```sql
SELECT * FROM Wallet.TermsAndConditions FOR SYSTEM_TIME AS OF '2024-01-01' WHERE TypeId = 1
```

### 8.3 Row count
```sql
SELECT COUNT(*) FROM Wallet.TermsAndConditions_History WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.TermsAndConditions_History | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.TermsAndConditions_History.sql*
