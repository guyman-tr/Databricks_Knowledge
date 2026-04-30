# Trade.ApexIdsToCIDs

> Resolves a batch of Apex broker account IDs to eToro customer IDs (CIDs) by joining to Customer.CustomerStatic, supporting the US brokerage integration.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ApexIdsToCIDs (Trade.ApexIdsListTbl READONLY) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure translates Apex Clearing broker account IDs into eToro internal customer IDs (CIDs). Apex Clearing is the US broker-dealer that handles real stock settlement for US customers. External systems and integration workflows reference customers by their Apex account ID, but internal eToro systems use CID. This procedure bridges that gap for batch operations.

Created as part of the US project (TRADCD-753, August 2021) by Ran Ovadia. The procedure accepts a TVP of Apex IDs and returns CID + ApexID pairs via a LEFT JOIN to Customer.CustomerStatic, which stores the ApexID-to-CID mapping.

---

## 2. Business Logic

### 2.1 Batch ID Resolution

**What**: LEFT JOINs the input ApexIDs to Customer.CustomerStatic to resolve CIDs.

**Rules**:
- LEFT JOIN ensures all input ApexIDs are returned, even if no matching CID exists (CID will be NULL)
- Uses NOLOCK on Customer.CustomerStatic for read consistency without blocking
- Returns one row per input ApexID

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ApexIdsToCIDs | Trade.ApexIdsListTbl READONLY | NO | - | CODE-BACKED | TVP containing Apex Clearing broker account IDs to resolve. Each row has an ApexID that maps to Customer.CustomerStatic.ApexID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LEFT JOIN | Customer.CustomerStatic | READER | Resolves ApexID to CID |
| @ApexIdsToCIDs | Trade.ApexIdsListTbl | UDT Parameter | TVP type for batch ApexID input |

### 5.2 Referenced By (other objects point to this)

No SQL-level dependents found. Called by US brokerage integration services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ApexIdsToCIDs (procedure)
+-- Customer.CustomerStatic (table)
+-- Trade.ApexIdsListTbl (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | LEFT JOIN - resolves ApexID to CID |
| Trade.ApexIdsListTbl | User Defined Type | TVP parameter type |

### 6.2 Objects That Depend On This

No SQL-level dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Resolve Apex IDs to CIDs

```sql
DECLARE @ids Trade.ApexIdsListTbl;
INSERT INTO @ids (ApexID) VALUES ('ABC123'), ('DEF456');
EXEC Trade.ApexIdsToCIDs @ApexIdsToCIDs = @ids;
```

### 8.2 Check Apex ID mapping in CustomerStatic

```sql
SELECT  CID, ApexID
FROM    Customer.CustomerStatic WITH (NOLOCK)
WHERE   ApexID IS NOT NULL
ORDER BY CID;
```

### 8.3 Find unmapped Apex IDs

```sql
DECLARE @ids Trade.ApexIdsListTbl;
INSERT INTO @ids (ApexID) VALUES ('UNKNOWN1');
SELECT  a.ApexID
FROM    @ids a
LEFT JOIN Customer.CustomerStatic b WITH (NOLOCK) ON a.ApexID = b.ApexID
WHERE   b.CID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [TRADCD-753](https://etoro-jira.atlassian.net/browse/TRADCD-753) | Jira | Procedure created for US project - Apex Clearing integration |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ApexIdsToCIDs | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ApexIdsToCIDs.sql*
