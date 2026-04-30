# fiktivo.IsFirstPositionClosedForOriginalCID

> Checks whether a customer has ever closed a first position, used to determine if an affiliate qualifies for a first-position commission on this customer.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IsFirst (OUTPUT - returns whether this is the customer's first position) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

IsFirstPositionClosedForOriginalCID determines whether a specific customer (identified by their original CID) has any prior first-position records. This is a critical eligibility check in the first-position commission workflow: an affiliate only earns a first-position commission if the referred customer has never previously closed a first position.

The procedure checks for the existence of any record in dbo.tblaff_FirstPositions for the given OriginalCID. If no record exists, it means this customer has never had a first position recorded, so @IsFirst returns 1 (true -- this would be their first). If a record already exists, the customer already had a first position, so @IsFirst returns 0.

The naming convention is slightly counterintuitive: @IsFirst = 1 means "this IS the customer's first" (no prior records found), and @IsFirst = 0 means "this is NOT the first" (a prior record exists).

---

## 2. Business Logic

### 2.1 First Position Existence Check

**What**: Checks whether any first-position record exists for the given customer.

**Columns/Parameters Involved**: `@OriginalCID`, `@IsFirst`

**Rules**:
- IF EXISTS(SELECT TOP 1 from dbo.tblaff_FirstPositions WHERE OriginalCID = @OriginalCID), SET @IsFirst = 0
- ELSE SET @IsFirst = 1
- The logic is inverted from the table check: existence of a record means this is NOT the first (0), absence means it IS the first (1)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OriginalCID | BIGINT (IN) | NO | - | CODE-BACKED | The original customer ID to check for prior first-position closures. This is the platform-wide customer identifier. |
| 2 | @IsFirst | BIT (OUTPUT) | NO | - | CODE-BACKED | Returns 1 if the customer has no prior first-position record (this would be their first), 0 if a first-position record already exists. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OriginalCID | dbo.tblaff_FirstPositions | SELECT (EXISTS) | Checks for existence of any first-position record for this customer |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.IsFirstPositionClosedForOriginalCID (procedure)
└── dbo.tblaff_FirstPositions (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_FirstPositions | Table (cross-schema) | EXISTS check to determine if customer has prior first-position records |

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check if a customer's next position would be their first
```sql
DECLARE @IsFirst BIT
EXEC fiktivo.IsFirstPositionClosedForOriginalCID @OriginalCID = 123456, @IsFirst = @IsFirst OUTPUT
SELECT @IsFirst AS IsFirstPosition
```

### 8.2 View all recorded first positions for a customer
```sql
SELECT *
FROM dbo.tblaff_FirstPositions WITH (NOLOCK)
WHERE OriginalCID = 123456
```

### 8.3 Count customers with first-position records
```sql
SELECT COUNT(DISTINCT OriginalCID) AS CustomersWithFirstPositions
FROM dbo.tblaff_FirstPositions WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.IsFirstPositionClosedForOriginalCID | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.IsFirstPositionClosedForOriginalCID.sql*
