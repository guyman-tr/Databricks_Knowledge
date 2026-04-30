# Trade.SynPositionTimeOuts

> Synonym pointing to the PositionTimeOuts dictionary table on the AO-REAL-DB linked server, providing configurable timeout thresholds for position open, close, and stop-loss edit operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [AO-REAL-DB].[etoro].[Dictionary].[PositionTimeOuts] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.SynPositionTimeOuts is a synonym that provides local access to the PositionTimeOuts dictionary table on the AO-REAL-DB linked server. This table defines configurable timeout thresholds (in milliseconds or seconds) for different trading operations. When a position open, close, or stop-loss edit exceeds its configured timeout, the system logs the event to Trade.SynPositionEndedWithTOError for operational monitoring.

The synonym exists because timeout configuration is centralized on the AO-REAL-DB server, enabling consistent timeout enforcement across all datacenters. The Dictionary schema placement indicates this is a configuration/lookup table rather than transactional data.

The primary consumers are Trade.PositionOpenWithTimeout, Trade.PositionCloseWithTimeout, and Trade.PositionEditSLWithTimeout. These procedures read the timeout threshold from this synonym at the start of each operation and compare actual execution time against the configured limit. This is the companion to Trade.SynPositionEndedWithTOError - this synonym provides the thresholds, and that synonym stores the violations.

---

## 2. Business Logic

### 2.1 Timeout Enforcement Configuration

**What**: Configurable timeout thresholds that define the maximum acceptable execution time for each type of trading operation.

**Columns/Parameters Involved**: N/A (synonym targets a remote dictionary table)

**Rules**:
- Each operation type (Open, Close, EditSL) has its own timeout threshold
- Procedures read the threshold at operation start via this synonym
- If execution time exceeds the threshold, the event is logged to SynPositionEndedWithTOError
- Centralized on AO-REAL-DB for cross-datacenter consistency

**Diagram**:
```
SynPositionTimeOuts (thresholds)
    |
    +-- Read by PositionOpenWithTimeout
    +-- Read by PositionCloseWithTimeout
    +-- Read by PositionEditSLWithTimeout
    |
    v (if exceeded)
SynPositionEndedWithTOError (violations)
```

---

## 3. Data Overview

N/A for synonym (targets a table on a linked server).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [AO-REAL-DB].[etoro].[Dictionary].[PositionTimeOuts]. A dictionary table defining timeout thresholds for trading operations (open, close, SL edit). Used by WithTimeout procedures to detect and log slow operations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [AO-REAL-DB].[etoro].[Dictionary].[PositionTimeOuts] | Synonym target | Linked server reference to the timeout configuration dictionary table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionOpenWithTimeout | SELECT | Reader | Reads timeout threshold for position open operations |
| Trade.PositionCloseWithTimeout | SELECT | Reader | Reads timeout threshold for position close operations |
| Trade.PositionEditSLWithTimeout | SELECT | Reader | Reads timeout threshold for stop-loss edit operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SynPositionTimeOuts (synonym)
  +-- [AO-REAL-DB].[etoro].[Dictionary].[PositionTimeOuts] (remote dictionary table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-REAL-DB].[etoro].[Dictionary].[PositionTimeOuts] | Remote Table (Linked Server) | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionOpenWithTimeout | Stored Procedure | Reads timeout configuration for open operations |
| Trade.PositionCloseWithTimeout | Stored Procedure | Reads timeout configuration for close operations |
| Trade.PositionEditSLWithTimeout | Stored Procedure | Reads timeout configuration for SL edit operations |

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
WHERE  name = 'SynPositionTimeOuts'
       AND schema_id = SCHEMA_ID('Trade')
```

### 8.2 Check if synonym resolves
```sql
SELECT OBJECT_ID('Trade.SynPositionTimeOuts') AS ObjectID
```

### 8.3 Preview timeout configuration (if accessible)
```sql
SELECT *
FROM   Trade.SynPositionTimeOuts WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SynPositionTimeOuts | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.SynPositionTimeOuts.sql*
