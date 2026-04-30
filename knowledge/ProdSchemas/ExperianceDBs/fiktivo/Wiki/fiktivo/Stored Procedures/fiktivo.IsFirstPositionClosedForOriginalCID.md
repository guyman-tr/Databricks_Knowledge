# fiktivo.IsFirstPositionClosedForOriginalCID

> Checks whether a customer (by original CID) has ever had a first-position event recorded, determining if an upcoming position close qualifies as a "first" position for commission purposes.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IsFirst OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a gating check for first-position commission eligibility. Before awarding a first-position commission, the system needs to verify the customer hasn't already had a first position recorded. It checks dbo.tblaff_FirstPositions for any existing record with the given OriginalCID.

Created by Amir Moualem (17/03/2012). Returns @IsFirst=1 if NO record exists (this truly is the first), @IsFirst=0 if a record already exists (not the first).

---

## 2. Business Logic

### 2.1 First Position Deduplication

**What**: Prevents duplicate first-position commission awards by checking for prior records.

**Columns/Parameters Involved**: `@OriginalCID`, `@IsFirst`

**Rules**:
- EXISTS check on tblaff_FirstPositions WHERE OriginalCID = @OriginalCID
- If record exists: @IsFirst = 0 (not the first - already recorded)
- If no record: @IsFirst = 1 (this is truly the first position for this customer)
- Uses TOP 1 'have record' pattern for efficient existence check

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OriginalCID (IN) | BIGINT | NO | - | CODE-BACKED | Original customer ID to check. This is the customer's ID at registration time (may differ from current CID after account migration). |
| 2 | @IsFirst (OUT) | BIT | NO | - | CODE-BACKED | 1=no prior first-position record exists (this IS the first), 0=a record already exists (this is NOT the first). Inverse logic: 1 means eligible, 0 means already claimed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT) | dbo.tblaff_FirstPositions | Table read | EXISTS check for prior first-position records. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.IsFirstPositionClosedForOriginalCID (procedure)
    └── dbo.tblaff_FirstPositions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_FirstPositions | Table | EXISTS check by OriginalCID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Check if customer has a first position
```sql
DECLARE @isFirst BIT
EXEC fiktivo.IsFirstPositionClosedForOriginalCID @OriginalCID = 130294, @IsFirst = @isFirst OUTPUT
SELECT @isFirst AS IsFirstPosition
```

### 8.2 Verify first positions table for a customer
```sql
SELECT FirstPositionID, ORDER_DATE, OriginalCID
FROM dbo.tblaff_FirstPositions WITH (NOLOCK)
WHERE OriginalCID = 130294
```

### 8.3 Find customers with no first position yet
```sql
-- Customers who registered but never had a first position recorded
SELECT TOP 10 a.AffiliateID, l.Optional3 AS CID
FROM dbo.tblaff_Leads l WITH (NOLOCK)
JOIN dbo.tblaff_Leads_Commissions lc WITH (NOLOCK) ON l.LeadID = lc.LeadID
JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON lc.AffiliateID = a.AffiliateID
WHERE NOT EXISTS (SELECT 1 FROM dbo.tblaff_FirstPositions fp WITH (NOLOCK) WHERE fp.OriginalCID = l.Optional3)
AND l.Optional3 > 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.IsFirstPositionClosedForOriginalCID | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.IsFirstPositionClosedForOriginalCID.sql*
