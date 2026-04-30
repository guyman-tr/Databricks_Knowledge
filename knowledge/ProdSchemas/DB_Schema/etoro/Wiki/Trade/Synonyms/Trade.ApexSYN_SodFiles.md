# Trade.ApexSYN_SodFiles

> Synonym pointing to the Apex SOD files tracking table in SodreconciliationAzure, used to track which SOD reconciliation files have been loaded and processed.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [SodreconciliationAzure].[Sodreconciliation].[apex].[SodFiles] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ApexSYN_SodFiles is a synonym providing local access to the SodFiles table in the Apex SOD reconciliation database. This table tracks the Start-of-Day (SOD) reconciliation files received from Apex Clearing, recording metadata about each file such as load date, file type, and processing status.

The synonym enables dividend and airdrop payment procedures to verify which SOD files have been loaded before processing payments. Used by both Trade.PayCashAirdropByPayDateAndTerminalID and Trade.PayCashDividendByPayDate.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym - a transparent alias to a remote table.

---

## 3. Data Overview

N/A for synonym.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [SodreconciliationAzure].[Sodreconciliation].[apex].[SodFiles]. Tracks SOD reconciliation file metadata from Apex Clearing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [SodreconciliationAzure].[Sodreconciliation].[apex].[SodFiles] | Synonym target | Cross-database reference to SOD file tracking table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PayCashAirdropByPayDateAndTerminalID | FROM/JOIN | Reader | Checks SOD file status for airdrop processing |
| Trade.PayCashDividendByPayDate | FROM/JOIN | Reader | Checks SOD file status for dividend processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ApexSYN_SodFiles (synonym)
  +-- [SodreconciliationAzure].[Sodreconciliation].[apex].[SodFiles] (remote table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [SodreconciliationAzure].[Sodreconciliation].[apex].[SodFiles] | Remote Table | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PayCashAirdropByPayDateAndTerminalID | Stored Procedure | Reads SOD file status |
| Trade.PayCashDividendByPayDate | Stored Procedure | Reads SOD file status |

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check recent SOD files
```sql
SELECT TOP 10 * FROM Trade.ApexSYN_SodFiles WITH (NOLOCK) ORDER BY 1 DESC
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'ApexSYN_SodFiles' AND schema_id = SCHEMA_ID('Trade')
```

### 8.3 Check connectivity
```sql
SELECT TOP 1 1 AS IsReachable FROM Trade.ApexSYN_SodFiles WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ApexSYN_SodFiles | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.ApexSYN_SodFiles.sql*
