# Trade.CM_DeleteLeveragesRestrictionsWhiteList

> Bulk-deletes leverage restriction whitelist entries by matching GCID + InstrumentID pairs from a TVP against Trade.LeveragesRestrictionsWhiteList.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DeleteLeveragesRestrictionsWhiteListTable (TVP with GCID/InstrumentID pairs to remove) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CM_DeleteLeveragesRestrictionsWhiteList removes leverage restriction whitelist entries for specific customers and instruments. The leverage whitelist allows certain customers (identified by GCID) to have custom leverage limits that override the default platform limits for specific instruments. This procedure removes those overrides, reverting the affected customers back to standard leverage rules.

This is used by the Customer Management (CM) tooling when operations staff need to revoke previously-granted custom leverage permissions, typically when a customer's risk profile changes or during periodic compliance reviews.

The procedure operates transactionally - all deletions succeed or none do. On failure, the transaction rolls back and the error is re-thrown to the caller.

---

## 2. Business Logic

### 2.1 Bulk Delete by GCID + InstrumentID

**What**: Deletes whitelist entries matching the provided GCID and InstrumentID pairs.

**Columns/Parameters Involved**: `@DeleteLeveragesRestrictionsWhiteListTable`

**Rules**:
- JOIN between Trade.LeveragesRestrictionsWhiteList and TVP on GCID + InstrumentID
- All matching rows are deleted in a single statement
- Wrapped in a transaction for atomicity
- RETURN 0 on success

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DeleteLeveragesRestrictionsWhiteListTable | Trade.CM_DeleteLeveragesRestrictionsWhiteListTable (TVP, READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing GCID and InstrumentID pairs identifying which whitelist entries to remove. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE | Trade.LeveragesRestrictionsWhiteList | DELETE | Removes matching whitelist entries |
| Type | Trade.CM_DeleteLeveragesRestrictionsWhiteListTable | Type | UDT for TVP parameter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer Management tools | External | EXEC | Called from CM admin interface to revoke leverage overrides |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CM_DeleteLeveragesRestrictionsWhiteList (procedure)
+-- Trade.LeveragesRestrictionsWhiteList (table)
+-- Trade.CM_DeleteLeveragesRestrictionsWhiteListTable (user-defined table type)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LeveragesRestrictionsWhiteList | Table | DELETE - target for whitelist removal |
| Trade.CM_DeleteLeveragesRestrictionsWhiteListTable | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer Management admin tools | External | Calls this SP to revoke leverage overrides |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | Atomicity | All deletes succeed or all roll back |
| THROW | Error handling | Errors propagate to caller after rollback |

---

## 8. Sample Queries

### 8.1 View current leverage whitelist entries for a customer

```sql
SELECT  GCID, InstrumentID, MinLeverage, MaxLeverage, DefaultLeverage, Comments
FROM    Trade.LeveragesRestrictionsWhiteList WITH (NOLOCK)
WHERE   GCID = 12345;
```

### 8.2 Prepare and execute a deletion

```sql
DECLARE @DelTable Trade.CM_DeleteLeveragesRestrictionsWhiteListTable;
INSERT INTO @DelTable (GCID, InstrumentID) VALUES (12345, 1001);
EXEC Trade.CM_DeleteLeveragesRestrictionsWhiteList @DeleteLeveragesRestrictionsWhiteListTable = @DelTable;
```

### 8.3 Check all whitelist entries for an instrument

```sql
SELECT  GCID, MinLeverage, MaxLeverage, DefaultLeverage, LastUpdateDate
FROM    Trade.LeveragesRestrictionsWhiteList WITH (NOLOCK)
WHERE   InstrumentID = 1001
ORDER BY GCID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CM_DeleteLeveragesRestrictionsWhiteList | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CM_DeleteLeveragesRestrictionsWhiteList.sql*
