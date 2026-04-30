# Customer.GetGCIDForAppropriatenessMigration

> Filters a list of GCIDs to return only those assigned a specific DesignatedRegulationID in BackOffice; used during regulatory appropriateness assessment migrations to identify customers under a target jurisdiction.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcids + @regulationID (filter criteria) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetGCIDForAppropriatenessMigration is a regulatory migration utility. Given a batch of GCIDs and a target regulation ID, it returns only the GCIDs whose BackOffice.Customer.DesignatedRegulationID matches the target. It is used during MiFID II appropriateness assessment migrations - when regulatory rules require reassessing or migrating customer accounts that fall under a specific regulatory jurisdiction.

"Appropriateness" refers to the MiFID II obligation to assess whether trading instruments are appropriate for retail customers. When regulatory perimeters change (e.g., UK post-Brexit moving to a different regulation from EU MiFID II), customer accounts need to be migrated to the correct assessment framework. This procedure identifies the subset of a provided GCID list that belongs to a specific regulation.

Note: The parameter @gcids is of type IdList with column 'CID', but the WHERE clause compares `cc.GCID IN (SELECT CID FROM @gcids)` - meaning the IdList.CID column holds GCID values (the naming is slightly misleading).

---

## 2. Business Logic

### 2.1 GCID Filtering by DesignatedRegulationID

**What**: Intersects a provided GCID list with customers in a specific regulatory jurisdiction.

**Columns/Parameters Involved**: `@gcids`, `@regulationID`, `GCID`, `DesignatedRegulationID`

**Rules**:
- Joins Customer.Customer and BackOffice.Customer by CID
- WHERE bc.DesignatedRegulationID = @regulationID: filter to the target regulation
- AND cc.GCID IN (SELECT CID FROM @gcids): only process GCIDs from the input list (IdList.CID holds the GCID values)
- ORDER BY cc.GCID: results returned in ascending GCID order for deterministic processing
- Returns the GCID only (not CID) - the caller operates at GCID level for cross-environment consistency

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcids | IdList | NO | - | CODE-BACKED | Table-valued parameter (READONLY) containing the GCIDs to filter. The IdList type has a CID column that holds GCID values in this context. Only customers whose GCID appears in this list and who match @regulationID are returned. |
| 2 | @regulationID | INT | NO | - | CODE-BACKED | DesignatedRegulationID to filter on. Matches BackOffice.Customer.DesignatedRegulationID. Used to identify which regulatory jurisdiction to target in the migration. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| GCID | Customer.Customer.GCID | Global Customer ID of each customer who matches both the GCID input list and the designated regulation. Ordered ascending. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcids | IdList (UDT) | TVP type definition | Input parameter type |
| CID | Customer.Customer | Read | Source of GCID for each customer |
| CID | BackOffice.Customer | INNER JOIN (filter) | Filters by DesignatedRegulationID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase (migration utility called by compliance/regulatory scripts).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetGCIDForAppropriatenessMigration (procedure)
├── IdList (user defined type - schema unknown)
├── Customer.Customer (view)
│     └── Customer.CustomerStatic (table)
└── BackOffice.Customer (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| IdList | User Defined Type | TVP parameter type for the GCID input list |
| Customer.Customer | View | Source of GCID and CID for each customer |
| BackOffice.Customer | Table | INNER JOIN to filter by DesignatedRegulationID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| READONLY TVP | Parameter | @gcids cannot be modified within the procedure |
| Naming convention | Design | IdList.CID column holds GCID values - naming is inconsistent but matches usage pattern |

---

## 8. Sample Queries

### 8.1 Get GCIDs for a regulation from a batch

```sql
DECLARE @gcids IdList
INSERT INTO @gcids VALUES (9876543), (8765432)
EXEC Customer.GetGCIDForAppropriatenessMigration @gcids = @gcids, @regulationID = 1
```

### 8.2 Find DesignatedRegulationID distribution

```sql
SELECT DesignatedRegulationID, COUNT(*) AS CustomerCount
FROM BackOffice.Customer WITH (NOLOCK)
WHERE DesignatedRegulationID IS NOT NULL
GROUP BY DesignatedRegulationID
ORDER BY CustomerCount DESC
```

### 8.3 Direct query equivalent

```sql
SELECT cc.GCID
FROM Customer.Customer cc WITH (NOLOCK)
INNER JOIN BackOffice.Customer bc WITH (NOLOCK) ON cc.CID = bc.CID
WHERE bc.DesignatedRegulationID = 1
AND cc.GCID IN (9876543, 8765432)
ORDER BY cc.GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetGCIDForAppropriatenessMigration | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetGCIDForAppropriatenessMigration.sql*
