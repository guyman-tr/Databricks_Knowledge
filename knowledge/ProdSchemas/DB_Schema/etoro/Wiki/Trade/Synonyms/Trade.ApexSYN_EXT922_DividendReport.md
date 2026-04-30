# Trade.ApexSYN_EXT922_DividendReport

> Synonym pointing to the Apex SOD reconciliation dividend report table in the SodreconciliationAzure linked server, used for dividend payment processing and verification.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [SodreconciliationAzure].[Sodreconciliation].[apex].[EXT922_DividendReport] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ApexSYN_EXT922_DividendReport is a synonym that provides local access to the EXT922_DividendReport table in the Apex SOD reconciliation database. EXT922 is an Apex Clearing report format specifically for dividend distributions, containing details about dividend payments, ex-dates, record dates, and per-share amounts.

This synonym abstracts the cross-database path so dividend processing procedures can reference the data with a simple two-part name. It is used by Trade.PayCashDividendByPayDate to verify dividend amounts and reconcile payments against Apex clearing records.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym - a transparent alias to a remote table.

---

## 3. Data Overview

N/A for synonym. Data resides in the target SodreconciliationAzure database.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [SodreconciliationAzure].[Sodreconciliation].[apex].[EXT922_DividendReport]. Stores Apex EXT922 dividend report data including dividend amounts, ex-dates, record dates, and payment details. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [SodreconciliationAzure].[Sodreconciliation].[apex].[EXT922_DividendReport] | Synonym target | Cross-database reference to Apex dividend reconciliation table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PayCashDividendByPayDate | FROM/JOIN | Reader | Reads dividend report data for cash dividend payment processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ApexSYN_EXT922_DividendReport (synonym)
  +-- [SodreconciliationAzure].[Sodreconciliation].[apex].[EXT922_DividendReport] (remote table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [SodreconciliationAzure].[Sodreconciliation].[apex].[EXT922_DividendReport] | Remote Table | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PayCashDividendByPayDate | Stored Procedure | Reads dividend report data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Query dividend report through synonym
```sql
SELECT TOP 10 *
FROM   Trade.ApexSYN_EXT922_DividendReport WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name
FROM   sys.synonyms
WHERE  name = 'ApexSYN_EXT922_DividendReport'
  AND  schema_id = SCHEMA_ID('Trade')
```

### 8.3 Check for recent dividend records
```sql
SELECT TOP 5 *
FROM   Trade.ApexSYN_EXT922_DividendReport WITH (NOLOCK)
ORDER BY 1 DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ApexSYN_EXT922_DividendReport | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.ApexSYN_EXT922_DividendReport.sql*
