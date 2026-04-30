# apex.EXT001_EasyToBorrowList

> Stores Apex Clearing's daily Easy-to-Borrow list - securities available for short selling without needing a locate.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 PK + 1 NC on SodFileId) |

---

## 1. Business Meaning

This table stores Apex Clearing's Extract 001 - the Easy-to-Borrow list. This is a daily list of securities that are readily available for short selling at Apex without requiring the broker-dealer to arrange a separate locate. Regulatory rules (Reg SHO) require that brokers confirm securities can be borrowed before executing short sales; securities on this list are pre-approved.

Data is imported daily from Apex via the SOD file pipeline (Data Factory -> Blob Storage -> Azure Function -> this table). Each import creates a SodFiles record and links all rows via SodFileId FK with cascade delete.

---

## 2. Business Logic

No complex multi-column business logic. Each row is a single symbol on the easy-to-borrow list for a given import date.

---

## 3. Data Overview

N/A - simple list of symbols per daily file import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Auto-generated sequential GUID primary key. |
| 2 | SodFileId | uniqueidentifier | NO | - | VERIFIED | FK to apex.SodFiles.Id. Links this row to the source file import. CASCADE DELETE ensures cleanup when file is removed. |
| 3 | Symbol | varchar(12) | YES | - | CODE-BACKED | Ticker symbol of the security on the easy-to-borrow list. Securities listed here can be shorted without a separate locate arrangement at Apex. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (ON DELETE CASCADE) | Links to source file import record |

### 5.2 Referenced By (other objects point to this)

No known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
apex.EXT001_EasyToBorrowList (table)
└── apex.SodFiles (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EXT001_EasyToBorrowList | CLUSTERED PK | Id | - | - | Active |
| IX_EXT001_EasyToBorrowList_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_EXT001_EasyToBorrowList_SodFiles_SodFileId | FOREIGN KEY | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |

---

## 8. Sample Queries

### 8.1 Get the latest easy-to-borrow list

```sql
SELECT e.Symbol
FROM apex.EXT001_EasyToBorrowList e WITH (NOLOCK)
JOIN apex.SodFiles f WITH (NOLOCK) ON e.SodFileId = f.Id
WHERE f.ApexFormat = 1 AND f.Status = 2
  AND f.ProcessDate = (SELECT MAX(ProcessDate) FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1 AND Status = 2)
ORDER BY e.Symbol;
```

### 8.2 Check if a symbol is on the easy-to-borrow list for a date

```sql
SELECT e.Symbol, f.ProcessDate
FROM apex.EXT001_EasyToBorrowList e WITH (NOLOCK)
JOIN apex.SodFiles f WITH (NOLOCK) ON e.SodFileId = f.Id
WHERE e.Symbol = 'AAPL' AND f.Status = 2
ORDER BY f.ProcessDate DESC;
```

### 8.3 Count symbols per daily import

```sql
SELECT f.ProcessDate, COUNT(*) AS SymbolCount
FROM apex.EXT001_EasyToBorrowList e WITH (NOLOCK)
JOIN apex.SodFiles f WITH (NOLOCK) ON e.SodFileId = f.Id
WHERE f.ApexFormat = 1 AND f.Status = 2
GROUP BY f.ProcessDate
ORDER BY f.ProcessDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | File import pipeline: Data Factory -> Blob -> Event Grid -> Azure Function -> SodFiles + EXT tables |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: apex.EXT001_EasyToBorrowList | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT001_EasyToBorrowList.sql*
