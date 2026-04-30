# Trade.SynPdtOperations

> Synonym pointing to the PdtOperations table in the ExternalOperationsAzure database, enabling the Trade schema to access Pattern Day Trading (PDT) rule enforcement operations for US equity traders.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [ExternalOperationsAzure].[ExternalOperations].[Trade].[PdtOperations] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.SynPdtOperations is a synonym that provides local access to the PdtOperations table in the ExternalOperationsAzure database. PDT (Pattern Day Trading) is a US regulatory classification under FINRA Rule 4210 that applies to traders who execute 4 or more day trades within 5 business days using a margin account. The PdtOperations table tracks PDT-related operational actions applied to customer accounts - such as PDT flags being set, restrictions being imposed, or exemptions being granted.

The synonym exists because external regulatory operations are managed in a dedicated Azure database (ExternalOperationsAzure), keeping regulatory enforcement isolated from the core trading engine. The Trade schema may need to reference PDT operations for pre-trade validation, account status checks, or compliance reporting.

No direct consumers were found in the Trade schema's stored procedures. This synonym may be used by external reporting processes, compliance tools, or ad-hoc queries that need to correlate PDT enforcement actions with trading activity.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. PDT rule enforcement logic resides in the ExternalOperationsAzure database.

---

## 3. Data Overview

N/A for synonym (targets a table in an external database).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [ExternalOperationsAzure].[ExternalOperations].[Trade].[PdtOperations]. A table tracking Pattern Day Trading regulatory operations - PDT flags, restrictions, and exemptions applied to US equity trading accounts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [ExternalOperationsAzure].[ExternalOperations].[Trade].[PdtOperations] | Synonym target | Cross-database reference to the PDT operations table in the external operations database |

### 5.2 Referenced By (other objects point to this)

No consumers found in Trade schema stored procedures. May be used by external compliance processes or ad-hoc queries.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SynPdtOperations (synonym)
  +-- [ExternalOperationsAzure].[ExternalOperations].[Trade].[PdtOperations] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [ExternalOperationsAzure].[ExternalOperations].[Trade].[PdtOperations] | Remote Table | Synonym target |

### 6.2 Objects That Depend On This

No dependents found in the Trade schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

N/A for synonym.

---

## 8. Sample Queries

### 8.1 Verify synonym target
```sql
SELECT name, base_object_name
FROM   sys.synonyms WITH (NOLOCK)
WHERE  name = 'SynPdtOperations'
       AND schema_id = SCHEMA_ID('Trade')
```

### 8.2 Check if synonym resolves
```sql
SELECT OBJECT_ID('Trade.SynPdtOperations') AS ObjectID
```

### 8.3 Preview PDT operations data (if accessible)
```sql
SELECT TOP 10 *
FROM   Trade.SynPdtOperations WITH (NOLOCK)
ORDER BY 1 DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SynPdtOperations | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.SynPdtOperations.sql*
