# Dictionary.GetAllRegulations

> Stored procedure returning all regulation records with their full details from the dbo.Dictionary_Regulation synonym.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Result set: ID, Name, IsUSA, JurisdictionName, BankID, RegulationLongName, RegulationShortName, DefaultRegulationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.GetAllRegulations is a simple data access procedure that returns all regulation records from the platform. It reads from `dbo.Dictionary_Regulation`, which is a synonym or view providing cross-schema access to regulation data. The procedure is used by application services to cache or display the full list of available regulatory jurisdictions.

This procedure exists as a standardized data access layer rather than having applications query the Dictionary.Regulation table directly. It includes a `DefaultRegulationID` column in the output (present in the dbo view/synonym but not in the base Dictionary.Regulation table), which identifies the fallback regulation for unclassified users.

The procedure uses SET NOCOUNT ON for performance and returns a simple result set with no filtering or parameters.

---

## 2. Business Logic

No complex business logic. Simple SELECT from dbo.Dictionary_Regulation with no parameters, filtering, or transformation.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int (output) | NO | - | CODE-BACKED | Regulation identifier. Maps to Dictionary.Regulation.ID. |
| 2 | Name | varchar (output) | YES | - | CODE-BACKED | Short regulation name (CySEC, FCA, ASIC, etc.). |
| 3 | IsUSA | tinyint (output) | NO | - | CODE-BACKED | US regulation flag. 1=US jurisdiction, 0=non-US. |
| 4 | JurisdictionName | varchar (output) | YES | - | CODE-BACKED | eToro legal entity name for this jurisdiction. |
| 5 | BankID | int (output) | YES | - | CODE-BACKED | Payment processing configuration identifier. |
| 6 | RegulationLongName | varchar (output) | YES | - | CODE-BACKED | Full official regulatory body name. |
| 7 | RegulationShortName | varchar (output) | YES | - | CODE-BACKED | Abbreviated regulation name for UI display. |
| 8 | DefaultRegulationID | int (output) | YES | - | CODE-BACKED | Default/fallback regulation ID. Present in dbo view but not in base Dictionary.Regulation table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.Dictionary_Regulation | FROM | Reads all regulation data from dbo synonym/view |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.GetAllRegulations (procedure)
  +-- dbo.Dictionary_Regulation (synonym/view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Dictionary_Regulation | Synonym/View | SELECT FROM - reads all regulation records |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Dictionary.GetAllRegulations
```

### 8.2 Capture results into temp table
```sql
CREATE TABLE #Regulations (ID INT, Name VARCHAR(50), IsUSA TINYINT, JurisdictionName VARCHAR(30),
    BankID INT, RegulationLongName VARCHAR(100), RegulationShortName VARCHAR(50), DefaultRegulationID INT)
INSERT INTO #Regulations EXEC Dictionary.GetAllRegulations
SELECT * FROM #Regulations WHERE IsUSA = 1
DROP TABLE #Regulations
```

### 8.3 Compare with base table
```sql
SELECT r.ID, r.Name, r.RegulationShortName FROM Dictionary.Regulation r WITH (NOLOCK) ORDER BY r.ID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GetAllRegulations | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Dictionary/Stored Procedures/Dictionary.GetAllRegulations.sql*
