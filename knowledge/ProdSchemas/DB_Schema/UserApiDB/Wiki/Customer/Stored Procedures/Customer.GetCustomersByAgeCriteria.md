# Customer.GetCustomersByAgeCriteria

> Finds users who have just turned 21 years old since the last job run, filtered by designated regulation, for age-triggered compliance processing.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @regulationIds + @lastJobRunningTime |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCustomersByAgeCriteria is a compliance-focused procedure that identifies users who have recently turned 21 years old. Certain regulations require special handling when users cross the age-21 threshold - such as reclassifying their account, updating trading permissions, or performing additional verification.

This procedure exists to support periodic compliance jobs. A scheduled job calls this procedure with its last successful run time, and the procedure returns GCIDs of users whose 21st birthday fell between the last run and now - ensuring no user is missed or processed twice.

The procedure joins dbo.Real_Customer (for BirthDate) with dbo.Real_BackOfficeCustomer (for DesignatedRegulationID), filtering to only the specified regulations. The age calculation uses precise birthday anniversary logic (not just year difference) to identify users whose birthday occurred in the window.

---

## 2. Business Logic

### 2.1 Age-21 Birthday Window Detection

**What**: Identifies users whose 21st birthday falls between the last job run and the current time.

**Columns/Parameters Involved**: `BirthDate`, `@lastJobRunningTime`, `GETDATE()`

**Rules**:
- The 21st birthday is calculated via DATEADD(YEAR, DATEDIFF(YEAR, BirthDate, GETDATE()), BirthDate)
- This anniversary must be <= GETDATE() (birthday has passed)
- This anniversary must be > @lastJobRunningTime (birthday occurred after last job run)
- Additional check: DATEDIFF(YY, BirthDate, GETDATE()) = 21 (ensures exactly 21, not 22+)
- Only users under the specified regulations (via @regulationIds JOIN) are included

### 2.2 Regulation Filtering

**What**: Only users under specific designated regulations are checked.

**Columns/Parameters Involved**: `@regulationIds`, `DesignatedRegulationID`

**Rules**:
- JOIN Real_BackOfficeCustomer with DesignatedRegulationID IN (SELECT Id FROM @regulationIds)
- This allows the compliance job to target specific jurisdictions (e.g., only ASIC, only CySEC)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @regulationIds | IdList (TVP) | NO | - | CODE-BACKED | READONLY list of DesignatedRegulationID values to filter by. Only users under these regulations are returned. FK values from Dictionary.Regulation. |
| 2 | @lastJobRunningTime | datetime | NO | - | CODE-BACKED | Timestamp of the last successful job run. Only users whose 21st birthday falls after this time are returned, preventing double-processing. |

**Return Columns:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | GCID | Real_Customer | CODE-BACKED | GCIDs of users who turned 21 since last job run under the specified regulations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | dbo.Real_Customer | JOIN (READER) | BirthDate and GCID for age calculation |
| (body) | dbo.Real_BackOfficeCustomer | JOIN (READER) | DesignatedRegulationID filtering |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Scheduled job | Called by periodic compliance job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCustomersByAgeCriteria (procedure)
+-- dbo.Real_Customer (table/synonym) - BirthDate, GCID
+-- dbo.Real_BackOfficeCustomer (table/synonym) - DesignatedRegulationID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table/Synonym | JOIN - BirthDate for age calculation |
| dbo.Real_BackOfficeCustomer | Table/Synonym | JOIN - regulation filtering |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called by compliance scheduled job |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Find users turning 21 under ASIC regulation
```sql
DECLARE @regs IdList
INSERT INTO @regs (Id) VALUES (4)  -- ASIC
EXEC Customer.GetCustomersByAgeCriteria @regulationIds = @regs, @lastJobRunningTime = '2026-04-11 00:00:00'
```

### 8.2 Check who turns 21 today
```sql
SELECT GCID, BirthDate, DATEDIFF(YY, BirthDate, GETDATE()) AS Age
FROM dbo.Real_Customer WITH (NOLOCK)
WHERE DATEDIFF(YY, BirthDate, GETDATE()) = 21
  AND DATEADD(YEAR, 21, BirthDate) <= GETDATE()
  AND DATEADD(YEAR, 21, BirthDate) > DATEADD(DAY, -1, GETDATE())
```

### 8.3 Verify regulation assignment
```sql
SELECT rc.GCID, rc.BirthDate, bc.DesignatedRegulationID
FROM dbo.Real_Customer rc WITH (NOLOCK)
JOIN dbo.Real_BackOfficeCustomer bc WITH (NOLOCK) ON rc.CID = bc.CID
WHERE DATEDIFF(YY, rc.BirthDate, GETDATE()) = 21
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCustomersByAgeCriteria | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetCustomersByAgeCriteria.sql*
