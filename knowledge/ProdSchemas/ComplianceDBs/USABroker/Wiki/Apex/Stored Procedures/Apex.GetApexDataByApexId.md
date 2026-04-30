# Apex.GetApexDataByApexId

> Retrieves the Apex account record by Apex Clearing account ID (reverse lookup), returning the GCID-to-ApexID mapping with status and creation time.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns ApexData row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Apex.GetApexDataByApexId performs a reverse lookup on the ApexData table - given an Apex Clearing account ID, it returns the platform's customer record. This is used when incoming Apex API responses or events reference an account by ApexID and the system needs to resolve the corresponding GCID for internal processing.

---

## 2. Business Logic

No complex business logic. Simple SELECT WHERE filter on ApexID (the clustered PK of ApexData).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ApexID | varchar(8) | NO | - | CODE-BACKED | The Apex Clearing account ID to look up. Matches the PK of Apex.ApexData. |

**Returns**: ApexID, GCID, StatusID, BeginTime from Apex.ApexData.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Apex.ApexData | Read | Queries by ApexID (PK) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.GetApexDataByApexId (procedure)
└── Apex.ApexData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Apex.ApexData | Table | Read by ApexID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up customer by Apex account ID

```sql
EXEC Apex.GetApexDataByApexId @ApexID = '3FN37590';
```

### 8.2 Verify account mapping exists

```sql
EXEC Apex.GetApexDataByApexId @ApexID = '3ER05011';
-- Returns GCID=19533157, StatusID=12 (COMPLETE)
```

### 8.3 Debug: check if ApexID is in the system

```sql
EXEC Apex.GetApexDataByApexId @ApexID = 'UNKNOWN1';
-- Returns empty if not found
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.GetApexDataByApexId | Type: Stored Procedure | Source: USABroker/Apex/Stored Procedures/Apex.GetApexDataByApexId.sql*
