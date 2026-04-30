# apex.EXT235_MandatoryCorporateActions

> Mandatory corporate actions from Apex Clearing EXT235 extract: splits, mergers, and spinoffs with stock/cash factors.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores daily mandatory corporate action data from Apex Clearing's EXT235 extract. Each row represents a mandatory corporate action event -- stock splits, reverse splits, mergers, spinoffs, and other reorganizations where shareholder participation is not optional. The data includes both the old and new security identifiers (CUSIP, Symbol), conversion factors for stock and cash components, and key dates.

The EXT235 data is critical for position reconciliation because mandatory corporate actions directly change position quantities and/or generate cash proceeds. When a stock splits 2-for-1, every account's position doubles. This data enables eToro to anticipate and verify corporate action processing, ensuring positions match after the event.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT235 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Old vs. New Security Mapping

**What**: Corporate actions map from an old security to a new security.

**Columns Involved**: `Cusip`, `CusipOld`, `Symbol`, `SymbolOld`, `ShortDescription`, `ShortDescriptionOld`

**Rules**:
- CusipOld/SymbolOld identify the original security being transformed
- Cusip/Symbol identify the resulting security after the corporate action
- For mergers, the old is the acquired company and the new is the acquirer or surviving entity
- For splits, old and new CUSIPs may be the same (just quantity changes)

### 2.2 Conversion Factors

**What**: Stock and cash factors define the economic terms of the action.

**Columns Involved**: `StockFactor`, `CashFactor`

**Rules**:
- StockFactor defines how many new shares are received per old share (e.g., 2.0 for a 2:1 split)
- CashFactor defines how much cash is received per old share
- Both may be present in a mixed merger (part stock, part cash)

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT235 file import. CASCADE DELETE. |
| 3 | Firm | varchar(2) | YES | - | CODE-BACKED | Clearing firm identifier. |
| 4 | Cusip | varchar(12) | YES | - | CODE-BACKED | New CUSIP identifier (resulting security after corporate action). |
| 5 | CusipOld | varchar(12) | YES | - | CODE-BACKED | Old CUSIP identifier (original security before corporate action). |
| 6 | Symbol | varchar(12) | YES | - | CODE-BACKED | New trading symbol (resulting security). |
| 7 | SymbolOld | varchar(12) | YES | - | CODE-BACKED | Old trading symbol (original security). |
| 8 | ShortDescription | varchar(15) | YES | - | CODE-BACKED | Description of the new/resulting security. |
| 9 | ShortDescriptionOld | varchar(15) | YES | - | CODE-BACKED | Description of the old/original security. |
| 10 | ISIN | varchar(12) | YES | - | CODE-BACKED | International Securities Identification Number. |
| 11 | ExpirationDate | smalldatetime | YES | - | CODE-BACKED | Expiration date for the corporate action processing window. |
| 12 | ProcessDate | smalldatetime | YES | - | CODE-BACKED | Business date of the Apex extract file. |
| 13 | ToMarket | varchar(8) | YES | - | NAME-INFERRED | Market/exchange of the resulting security. |
| 14 | FromMarket | varchar(8) | YES | - | NAME-INFERRED | Market/exchange of the original security. |
| 15 | CountryCode | varchar(2) | YES | - | CODE-BACKED | Country code for the resulting security. |
| 16 | CountryCodeOld | varchar(2) | YES | - | CODE-BACKED | Country code for the original security. |
| 17 | StockFactor | decimal(28,10) | YES | - | CODE-BACKED | Number of new shares received per old share. |
| 18 | CashFactor | decimal(28,10) | YES | - | CODE-BACKED | Cash amount received per old share. |
| 19 | PayableDate | smalldatetime | YES | - | CODE-BACKED | Date when the corporate action proceeds are payable. |
| 20 | SettlementDate | smalldatetime | YES | - | CODE-BACKED | Settlement date for the corporate action. |
| 21 | LastChangeDate | datetime | YES | - | CODE-BACKED | Date the corporate action record was last updated at Apex. |
| 22 | CorporateAction | varchar(15) | YES | - | CODE-BACKED | Type of corporate action (split, merger, spinoff, etc.). |
| 23 | CorporateActionMessage | nvarchar(4000) | YES | - | CODE-BACKED | Detailed message describing the corporate action terms. |
| 24 | RecordDate | datetime | YES | - | CODE-BACKED | Record date for determining entitled shareholders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (ON DELETE CASCADE) | Links to source file import |

### 5.2 Referenced By (other objects point to this)

No known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
apex.EXT235_MandatoryCorporateActions (table)
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
| PK_EXT235_MandatoryCorporateActions | CLUSTERED PK | Id | - | - | Active |
| IX_EXT235_MandatoryCorporateActions_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT235_MandatoryCorporateActions | PRIMARY KEY | Unique Id per row |
| FK_EXT235_MandatoryCorporateActions_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get recent mandatory corporate actions

```sql
SELECT CorporateAction, SymbolOld, Symbol, CusipOld, Cusip,
       StockFactor, CashFactor, RecordDate, PayableDate, ProcessDate
FROM apex.EXT235_MandatoryCorporateActions WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 235 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY RecordDate DESC;
```

### 8.2 Find stock splits

```sql
SELECT Symbol, SymbolOld, StockFactor, CashFactor, RecordDate, PayableDate,
       CorporateAction, CorporateActionMessage
FROM apex.EXT235_MandatoryCorporateActions WITH (NOLOCK)
WHERE StockFactor IS NOT NULL AND StockFactor <> 1
  AND ProcessDate >= '2026-04-01'
ORDER BY RecordDate DESC;
```

### 8.3 Summarize corporate actions by type

```sql
SELECT CorporateAction, COUNT(*) AS ActionCount
FROM apex.EXT235_MandatoryCorporateActions WITH (NOLOCK)
WHERE ProcessDate >= '2026-01-01'
GROUP BY CorporateAction
ORDER BY ActionCount DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT235_MandatoryCorporateActions | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT235_MandatoryCorporateActions.sql*
