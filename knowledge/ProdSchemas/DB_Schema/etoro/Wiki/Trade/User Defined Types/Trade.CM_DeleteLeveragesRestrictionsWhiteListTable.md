# Trade.CM_DeleteLeveragesRestrictionsWhiteListTable

> A table-valued parameter type for batch-deleting leverage restriction whitelist entries. Each row specifies a Global Customer ID and Instrument to remove from the whitelist, allowing compliance to revoke leverage overrides for specific customers on specific instruments.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | GCID, InstrumentID (composite) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.CM_DeleteLeveragesRestrictionsWhiteListTable is a TVP for batch-deleting entries from the leverage restriction whitelist. The whitelist allows specific customers to use leverage ratios that would otherwise be restricted by regulation. CM (Compliance Manager) uses this type when removing exemptions - for example when a customer no longer qualifies, an instrument changes, or compliance policy changes.

Without this type, each whitelist entry would require a separate procedure call. The batch semantics let compliance revoke dozens or hundreds of overrides in a single operation.

The consuming procedure Trade.CM_DeleteLeveragesRestrictionsWhiteList receives a populated instance of this TVP, matches rows by GCID and InstrumentID against the base whitelist table, and deletes the matching entries.

---

## 2. Business Logic

### 2.1 Composite Key for Whitelist Deletion

**What**: Each row uniquely identifies one whitelist entry to remove by customer and instrument.

**Columns/Parameters Involved**: `GCID`, `InstrumentID`

**Rules**:
- Both columns are required (NOT NULL). A row without either identifier cannot target a specific whitelist entry.
- Rows with the same GCID + InstrumentID could appear multiple times; the procedure typically deletes by unique pairs or handles duplicates via JOIN semantics.
- Deletion is idempotent for non-existent pairs: no error if the whitelist entry was already removed.

**Diagram**:
```
[TVP Row] -> (GCID, InstrumentID) -> DELETE FROM whitelist WHERE whitelist.GCID = TVP.GCID AND whitelist.InstrumentID = TVP.InstrumentID
```

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID - the platform-wide customer identifier. Identifies which customer's leverage exemption to revoke. Maps to customer records in the identity/customer domain. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument ID - identifies which instrument's leverage override to remove for this customer. The pair (GCID, InstrumentID) uniquely identifies one whitelist entry. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no declared outgoing references. GCID and InstrumentID semantically reference customer and instrument lookup tables, but there are no FK constraints on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CM_DeleteLeveragesRestrictionsWhiteList | @Table parameter | Parameter (TVP) | Receives batch of (GCID, InstrumentID) pairs to delete from the whitelist |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CM_DeleteLeveragesRestrictionsWhiteList | Stored Procedure | READONLY parameter - batch delete whitelist entries |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for batch whitelist deletion

```sql
DECLARE @List Trade.CM_DeleteLeveragesRestrictionsWhiteListTable;
INSERT INTO @List (GCID, InstrumentID) VALUES (100001, 5), (100001, 12), (100002, 5);
EXEC Trade.CM_DeleteLeveragesRestrictionsWhiteList @List = @List;
```

### 8.2 Build TVP from existing whitelist for specific customers

```sql
DECLARE @ToRemove Trade.CM_DeleteLeveragesRestrictionsWhiteListTable;
INSERT INTO @ToRemove (GCID, InstrumentID)
SELECT  GCID, InstrumentID
FROM    Trade.LeveragesRestrictionsWhiteListTbl WITH (NOLOCK)
WHERE   GCID IN (100001, 100002) AND SomeCondition = 1;
EXEC Trade.CM_DeleteLeveragesRestrictionsWhiteList @List = @ToRemove;
```

### 8.3 Single-entry deletion

```sql
DECLARE @List Trade.CM_DeleteLeveragesRestrictionsWhiteListTable;
INSERT INTO @List (GCID, InstrumentID) VALUES (100001, 5);
EXEC Trade.CM_DeleteLeveragesRestrictionsWhiteList @List = @List;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CM_DeleteLeveragesRestrictionsWhiteListTable | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.CM_DeleteLeveragesRestrictionsWhiteListTable.sql*
