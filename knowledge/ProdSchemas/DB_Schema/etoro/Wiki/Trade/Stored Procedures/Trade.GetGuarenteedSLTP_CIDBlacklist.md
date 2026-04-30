# Trade.GetGuarenteedSLTP_CIDBlacklist

> Returns all client IDs currently blacklisted from guaranteed Stop-Loss/Take-Profit features.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | CID (result set from blacklist table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the list of customer IDs (CIDs) that are currently excluded from guaranteed Stop-Loss and Take-Profit functionality. It returns all rows from Trade.GuarenteedSLTP_CIDBlacklist where GuarenteedSLTP=0, meaning these clients are actively blacklisted.

The procedure exists as the "read" component of a three-procedure blacklist management system: Set (blacklist a CID), Clear (remove from blacklist), and Get (retrieve current blacklist). It was created for Jira 41586 (Geri Reshef, 2016-11-01) to allow eToro to disable guaranteed SL/TP per client without code changes - typically for clients who abuse or trigger edge cases with the feature.

Data flow: caller invokes with no parameters. The SP reads Trade.GuarenteedSLTP_CIDBlacklist with a WHERE filter for blacklisted rows (GuarenteedSLTP=0) and returns all columns. The table is currently empty (0 rows) but the structure and procedures remain active.

---

## 2. Business Logic

### 2.1 Blacklist Filter

**What**: Only returns actively blacklisted clients, not cleared ones.

**Columns/Parameters Involved**: `GuarenteedSLTP`

**Rules**:
- The SP uses `SELECT * FROM Trade.GuarenteedSLTP_CIDBlacklist WHERE GuarenteedSLTP=0`
- GuarenteedSLTP=0 means blacklisted (cannot use guaranteed SL/TP)
- GuarenteedSLTP=1 means cleared (guaranteed SL/TP re-enabled) - these rows are NOT returned
- Clients are blacklisted by Trade.SetGuarenteedSLTP_CIDBlacklist and cleared by Trade.ClearGuarenteedSLTP_CIDBlacklist

**Diagram**:
```
Trade.SetGuarenteedSLTP_CIDBlacklist(@CID)
  --> MERGE: GuarenteedSLTP = 0 (blacklist)

Trade.GetGuarenteedSLTP_CIDBlacklist  <-- THIS SP
  --> SELECT * WHERE GuarenteedSLTP = 0 (read blacklist)

Trade.ClearGuarenteedSLTP_CIDBlacklist(@CID)
  --> UPDATE: GuarenteedSLTP = 1 (clear)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. It returns all columns from Trade.GuarenteedSLTP_CIDBlacklist (via `SELECT *`):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID (output) | INT | NO | - | CODE-BACKED | Client ID of the blacklisted customer. PK of the source table. FK to Customer (inferred). |
| 2 | Occurred (output) | DATETIME | YES | GETDATE() | CODE-BACKED | Timestamp when the client was originally blacklisted. Set automatically on INSERT via default constraint. |
| 3 | GuarenteedSLTP (output) | INT | YES | 0 | CODE-BACKED | Blacklist flag: always 0 in results (blacklisted). 0 = cannot use guaranteed SL/TP, 1 = cleared/re-enabled. The WHERE clause filters to 0 only. |
| 4 | ModificationDate (output) | DATETIME | YES | - | CODE-BACKED | Timestamp of last modification. Set by ClearGuarenteedSLTP_CIDBlacklist when clearing (GuarenteedSLTP -> 1). NULL until first clear operation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.GuarenteedSLTP_CIDBlacklist | FROM | Source table - reads all blacklisted rows |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | GRANT EXECUTE | Permission | BI admin service account has execute permission |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetGuarenteedSLTP_CIDBlacklist (procedure)
+-- Trade.GuarenteedSLTP_CIDBlacklist (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GuarenteedSLTP_CIDBlacklist | Table | FROM - reads all columns where GuarenteedSLTP=0 |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase. No application code references discovered.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute to get current blacklist

```sql
EXEC Trade.GetGuarenteedSLTP_CIDBlacklist;
```

### 8.2 Equivalent direct query

```sql
SELECT  *
FROM    Trade.GuarenteedSLTP_CIDBlacklist WITH (NOLOCK)
WHERE   GuarenteedSLTP = 0;
```

### 8.3 Check if a specific CID is blacklisted

```sql
SELECT  CASE WHEN EXISTS (
            SELECT 1
            FROM   Trade.GuarenteedSLTP_CIDBlacklist WITH (NOLOCK)
            WHERE  CID = 12345
            AND    GuarenteedSLTP = 0
        )
        THEN 'Blacklisted'
        ELSE 'Not blacklisted'
        END AS Status;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Jira 41586 referenced in SP comment ("DB stuff for BlackList for GuarenteedSLTP") but no matching Confluence/Jira content discovered via search.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetGuarenteedSLTP_CIDBlacklist | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetGuarenteedSLTP_CIDBlacklist.sql*
