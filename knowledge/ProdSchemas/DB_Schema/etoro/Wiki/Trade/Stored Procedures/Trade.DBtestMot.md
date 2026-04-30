# Trade.DBtestMot

> Developer test procedure that forwards a CID/MirrorID pair to a remote test server to invoke the unrealized equity data calculation procedure for debugging purposes.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Proxies to remote SP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DBtestMot is a developer/DBA test procedure created for debugging the unrealized equity data calculation. It accepts a CID and MirrorID via a table-valued parameter, extracts them, and forwards the call to Trade.GetUsersUnrealizedEquityDataNativeTest on a remote test server (AZR-W-DAGREAL-3Test, database PnlYitz). The "Mot" in the name likely refers to a developer's name or alias.

This procedure exists solely for testing and debugging. It provides a convenient way to invoke a test version of the equity calculation procedure on a specific test server without requiring the caller to know the four-part server/database name. It has no production business function.

The procedure should not be called in production environments. It references a specific test server that may or may not be available.

---

## 2. Business Logic

No business logic. This is a pass-through test wrapper.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @i | Trade.CidToMirrorId (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing CID and MirrorID columns. The procedure extracts the first row's values and passes them to the remote test procedure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Remote EXEC | [AZR-W-DAGREAL-3Test].[PnlYitz].[Trade].[GetUsersUnrealizedEquityDataNativeTest] | Caller | Forwards CID and MirrorID to a test version of the equity calculation on a remote test server |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Ad-hoc developer use only.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DBtestMot (procedure)
+-- [AZR-W-DAGREAL-3Test].[PnlYitz].[Trade].[GetUsersUnrealizedEquityDataNativeTest] (remote procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AZR-W-DAGREAL-3Test].[PnlYitz].[Trade].[GetUsersUnrealizedEquityDataNativeTest] | Remote Stored Procedure | Called via EXEC with @CID and @MirrorID parameters |
| Trade.CidToMirrorId | User Defined Type | TVP type for the input parameter |

### 6.2 Objects That Depend On This

No dependents found. Ad-hoc test procedure.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Verify the procedure exists
```sql
SELECT OBJECT_ID('Trade.DBtestMot') AS ObjectID
```

### 8.2 Check the TVP type definition
```sql
SELECT c.name, t.name AS TypeName
FROM   sys.table_types tt
       JOIN sys.columns c ON c.object_id = tt.type_table_object_id
       JOIN sys.types t ON c.system_type_id = t.system_type_id
WHERE  tt.name = 'CidToMirrorId'
       AND SCHEMA_NAME(tt.schema_id) = 'Trade'
```

### 8.3 Check linked server availability
```sql
SELECT name, is_linked, product
FROM   sys.servers WITH (NOLOCK)
WHERE  name = 'AZR-W-DAGREAL-3Test'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DBtestMot | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DBtestMot.sql*
