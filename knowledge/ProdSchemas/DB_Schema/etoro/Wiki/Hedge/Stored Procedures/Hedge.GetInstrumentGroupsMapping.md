# Hedge.GetInstrumentGroupsMapping

> Returns all active instrument-to-group mappings with their group names. Joins InstrumentGroupsMapping (which instruments belong to which group) with InstrumentGroups (group name definitions), filtered to IsActive=1. Used by the hedge engine to apply group-level routing and execution policies to individual instruments.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | None - no parameters, returns all active mappings |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetInstrumentGroupsMapping provides the hedge engine with the active assignment of instruments to named groups. Rather than configuring routing rules and order type policies per instrument individually (for 10,000+ instruments), the hedge system groups instruments and applies policies to the group.

The procedure returns the joined view: for each active instrument-to-group assignment, which group does the instrument belong to, and what is the group's name? This is used by the hedge engine to:
1. Apply `Hedge.OrderTypeConfiguration` rules (which reference GroupIDs via Entity=1)
2. Route instruments via different execution paths (e.g., Virtu US, Virtu EU, OMS CFDs)
3. Apply group-level behavioral overrides

The `IsActive = 1` filter on InstrumentGroupsMapping is critical - it allows instruments to be deactivated from a group without deleting the mapping record. The InstrumentGroups table (GroupID, GroupName, Description) is the source of group metadata.

Known active groups: GroupID=1 (Futures), 100-102 (Virtu path by region: US/EU/APAC), 201-202 (OMS/Virtu path by region: EU/US).

---

## 2. Business Logic

### 2.1 IsActive Filter: Active Mappings Only

**What**: Only instrument-to-group assignments with IsActive=1 are returned.

**Columns/Parameters Involved**: `Hedge.InstrumentGroupsMapping.IsActive`

**Rules**:
- WHERE `HIGM.IsActive = 1` - excludes deactivated assignments.
- Allows soft-disabling an instrument from a group (e.g., temporarily remove an instrument from Virtu routing) without data deletion.
- If an instrument should be in a new group, its old mapping can be set to IsActive=0 and a new row inserted with IsActive=1.

### 2.2 Two-Table Join: Group Metadata + Instrument Assignments

**What**: Joins InstrumentGroups (group definitions) with InstrumentGroupsMapping (instrument assignments).

**Rules**:
- `Hedge.InstrumentGroups HIG (nolock) INNER JOIN Hedge.InstrumentGroupsMapping HIGM (nolock) ON HIG.GroupID = HIGM.GroupID`
- An instrument is not in the result if its group has no IsActive=1 rows in InstrumentGroupsMapping.
- An InstrumentGroups entry with no active mappings produces no rows (INNER JOIN).
- SELECT returns GroupID from HIG (the group definition table) - it would be equivalent from HIGM.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns** (returned resultset):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier. From InstrumentGroupsMapping. Identifies which instrument is assigned to the group. |
| 2 | GroupID | int | NO | - | CODE-BACKED | Group identifier. From InstrumentGroups. Groups: 1=Futures, 100=Virtu US, 101=Virtu EU, 102=Virtu APAC, 201=OMS EU, 202=OMS US. |
| 3 | GroupName | nvarchar | YES | - | CODE-BACKED | Human-readable group name from InstrumentGroups.GroupName. Examples: "Futures", "PathToVirtu_US", "OMS_CFDs_EU". Used by OrderTypeConfiguration consumers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HIG source | Hedge.InstrumentGroups | Lookup / Read | Group definitions: GroupID, GroupName. Provides group metadata. |
| HIGM join | Hedge.InstrumentGroupsMapping | Lookup / Read | Instrument assignments: InstrumentID, GroupID, IsActive. Filtered to IsActive=1. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge engine (external) | Result set | Caller | Loads instrument group assignments at startup for routing policy application. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetInstrumentGroupsMapping (procedure)
├── Hedge.InstrumentGroups (table)
└── Hedge.InstrumentGroupsMapping (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InstrumentGroups | Table | Source of GroupID and GroupName. INNER JOIN starting table. |
| Hedge.InstrumentGroupsMapping | Table | Instrument assignments: InstrumentID, GroupID, IsActive. WHERE IsActive=1. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge engine (external) | Application | Loads active group assignments for routing and order type policy application. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

NOLOCK on both tables. No temp tables. No parameters. Simple two-table INNER JOIN with WHERE IsActive=1.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Hedge.GetInstrumentGroupsMapping;
```

### 8.2 Count instruments per group

```sql
SELECT HIG.GroupID, HIG.GroupName, COUNT(HIGM.InstrumentID) AS InstrumentCount
FROM   Hedge.InstrumentGroups HIG WITH (NOLOCK)
JOIN   Hedge.InstrumentGroupsMapping HIGM WITH (NOLOCK) ON HIG.GroupID = HIGM.GroupID
WHERE  HIGM.IsActive = 1
GROUP BY HIG.GroupID, HIG.GroupName
ORDER BY HIG.GroupID;
```

### 8.3 Find which group an instrument belongs to

```sql
EXEC Hedge.GetInstrumentGroupsMapping;
-- Filter result by InstrumentID = <your instrument>
-- OR:
SELECT HIG.GroupID, HIG.GroupName
FROM   Hedge.InstrumentGroupsMapping HIGM WITH (NOLOCK)
JOIN   Hedge.InstrumentGroups HIG WITH (NOLOCK) ON HIGM.GroupID = HIG.GroupID
WHERE  HIGM.InstrumentID = 9920
AND    HIGM.IsActive = 1;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | Instrument grouping for routing policies; Virtu and OMS execution paths by geography. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetInstrumentGroupsMapping | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetInstrumentGroupsMapping.sql*
