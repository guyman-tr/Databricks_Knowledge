# Trade.Syn_TradeOrphanedPositionsCloseByJob

> Synonym pointing to the TradeOrphanedPositionsCloseByJob table within the same database, used by orphaned position cleanup processes to track and close positions that lost their parent context.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [Trade].[TradeOrphanedPositionsCloseByJob] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.Syn_TradeOrphanedPositionsCloseByJob is a synonym that references the TradeOrphanedPositionsCloseByJob table within the same Trade schema. The target table tracks positions that have become orphaned - positions whose parent copy-trade tree, mirror relationship, or managing context no longer exists - and need to be closed by an automated cleanup job.

This synonym exists to support the orphaned position management pipeline. When positions become detached from their original context (e.g., a copied trader stops trading, a mirror relationship is dissolved, or a tree node is removed), those positions must be identified and closed to prevent unmanaged exposure.

The primary consumers are Trade.CloseOrpahnedPositions (which processes the close operations) and Trade.AlertForOrphanedPositions (which monitors and raises alerts about orphaned positions that need attention).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The orphaned position identification and closure logic resides in the consuming procedures.

---

## 3. Data Overview

N/A for synonym.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Two-part name | - | - | CODE-BACKED | Points to [Trade].[TradeOrphanedPositionsCloseByJob]. A table tracking orphaned trading positions flagged for automated closure by the cleanup job. Unlike most Trade synonyms, this targets an object in the same database. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | Trade.TradeOrphanedPositionsCloseByJob | Synonym target | Same-database reference to the orphaned position tracking table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CloseOrpahnedPositions | SELECT/DELETE | Consumer | Reads orphaned positions and processes closures |
| Trade.AlertForOrphanedPositions | SELECT | Reader | Monitors orphaned positions and raises operational alerts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Syn_TradeOrphanedPositionsCloseByJob (synonym)
  +-- Trade.TradeOrphanedPositionsCloseByJob (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TradeOrphanedPositionsCloseByJob | Table | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CloseOrpahnedPositions | Stored Procedure | Processes orphaned position closures |
| Trade.AlertForOrphanedPositions | Stored Procedure | Monitors and alerts on orphaned positions |

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
WHERE  name = 'Syn_TradeOrphanedPositionsCloseByJob'
       AND schema_id = SCHEMA_ID('Trade')
```

### 8.2 Check if synonym resolves
```sql
SELECT OBJECT_ID('Trade.Syn_TradeOrphanedPositionsCloseByJob') AS ObjectID
```

### 8.3 Preview orphaned position data
```sql
SELECT TOP 10 *
FROM   Trade.Syn_TradeOrphanedPositionsCloseByJob WITH (NOLOCK)
ORDER BY 1 DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Syn_TradeOrphanedPositionsCloseByJob | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.Syn_TradeOrphanedPositionsCloseByJob.sql*
