# Trade.ApexIdsListTbl

> A table-valued parameter type for passing batches of Apex clearing broker account IDs (varchar(100)) to Trade.ApexIdsToCIDs. Supports extended Apex ID formats compared to the 8-char ApexIDsList.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | ApexID (varchar(100)) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.ApexIdsListTbl is a table-valued parameter type for passing Apex clearing broker account IDs to Trade.ApexIdsToCIDs. Unlike Trade.ApexIDsList (varchar(8)), this type uses varchar(100) to support extended Apex ID formats - longer identifiers, composite keys, or future format changes.

This type exists specifically for the Apex ID to CID conversion workflow. ApexIdsToCIDs maps each ApexID to eToro Customer IDs (CIDs). Callers that have Apex IDs from external systems (clearing feeds, regulatory reports) use this TVP to resolve them to CIDs for downstream Trade operations.

Data flow: External data or batch jobs supply Apex IDs, caller populates the TVP, and passes it to ApexIdsToCIDs. The procedure returns or outputs the CID mapping. The longer field accommodates IDs that exceed the 8-char limit of ApexIDsList.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a single-column utility type for Apex ID input to the CID resolution procedure.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ApexID | varchar(100) | NO | - | CODE-BACKED | Apex clearing broker account ID. Max 100 characters. Supports extended formats beyond the 8-char ApexIDsList. Used as input to Trade.ApexIdsToCIDs for resolution to eToro CIDs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no declared FK. ApexID semantically references Apex clearing system account identifiers.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ApexIdsToCIDs | @ApexIds (or similar) | Parameter (TVP) | Input Apex IDs for CID resolution |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ApexIdsToCIDs | Stored Procedure | READONLY parameter for Apex ID to CID conversion |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate ApexIdsListTbl for CID resolution

```sql
DECLARE @ApexIds Trade.ApexIdsListTbl;
INSERT INTO @ApexIds (ApexID) VALUES ('APX-LONG-ID-001'), ('APX-LONG-ID-002');
EXEC Trade.ApexIdsToCIDs @ApexIds = @ApexIds;
```

### 8.2 Populate from clearing feed staging table

```sql
DECLARE @ApexIds Trade.ApexIdsListTbl;
INSERT INTO @ApexIds (ApexID)
SELECT  DISTINCT ApexAccountID
FROM    Staging.ClearingFeed WITH (NOLOCK)
WHERE   Processed = 0;

EXEC Trade.ApexIdsToCIDs @ApexIds = @ApexIds;
```

### 8.3 Single extended Apex ID conversion

```sql
DECLARE @ApexIds Trade.ApexIdsListTbl;
INSERT INTO @ApexIds (ApexID) VALUES ('APX-EXTENDED-FORMAT-12345');
EXEC Trade.ApexIdsToCIDs @ApexIds = @ApexIds;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ApexIdsListTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.ApexIdsListTbl.sql*
