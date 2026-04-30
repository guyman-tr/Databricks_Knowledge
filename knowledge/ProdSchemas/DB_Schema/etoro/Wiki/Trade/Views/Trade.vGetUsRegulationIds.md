# Trade.vGetUsRegulationIds

> Returns regulation IDs representing US-regulated jurisdictions, excluding eToroUS (ID=6), for use as a filter in US regulatory logic.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | ID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.vGetUsRegulationIds is a **US regulation filter view** that returns the set of regulation IDs considered to represent US-regulated jurisdictions. It reads from Dictionary.Regulation where IsUSA = 1 and explicitly excludes ID = 6 (eToroUS). The exclusion of eToroUS reflects that the eToro US entity is often handled separately in regulatory logic—e.g., for position/customer eligibility checks or feature availability.

This view is used as a lookup or filter in procedures and functions that need to determine whether a customer or position is subject to US regulatory rules. For example, Trade.IsUsUser joins to this view on RegulationID to classify US vs. non-US users. Consumers typically use it in JOINs or IN/EXISTS predicates to scope queries to US-regulated entities.

---

## 2. Business Logic

### 2.1 US Regulation Filter with eToroUS Exclusion

**What**: Selects regulation IDs where IsUSA = 1 and ID <> 6.

**Columns/Parameters Involved**: `ID`, `IsUSA`

**Rules**:
- IsUSA = 1 (US-regulated jurisdiction)
- ID <> 6 (exclude eToroUS)
- Single column output: ID

---

## 3. Data Overview

Each row is one regulation ID that represents a US-regulated jurisdiction other than eToroUS. Typical use is as a filter list (e.g., WHERE RegulationID IN (SELECT ID FROM Trade.vGetUsRegulationIds)).

---

## 4. Elements

| # | Column Name | Data Type | Source | Confidence | Description |
|---|-------------|-----------|--------|------------|-------------|
| 1 | ID | int | Dictionary.Regulation | CODE-BACKED | Regulation ID. US-regulated jurisdiction; excludes eToroUS (6). |

---

## 5. Relationships

### 5.1 References To

| Object | Relationship |
|--------|--------------|
| Dictionary.Regulation | FROM; filter on IsUSA=1, ID<>6 |

### 5.2 Referenced By

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.vGetUsRegulationIds (view)
+-- Dictionary.Regulation (table) [x-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Regulation | Table | Source of regulation IDs; filtered by IsUSA, ID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List US regulation IDs (excluding eToroUS)

```sql
SELECT ID
FROM   Trade.vGetUsRegulationIds WITH (NOLOCK);
```

### 8.2 Check if a regulation ID is US-regulated (excluding eToroUS)

```sql
SELECT @IsUsRegulated = CASE WHEN EXISTS (
    SELECT 1 FROM Trade.vGetUsRegulationIds WITH (NOLOCK) WHERE ID = @RegulationID
) THEN 1 ELSE 0 END;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Quality: 7.0/10*
*Object: Trade.vGetUsRegulationIds | Type: View | Source: etoro/etoro/Trade/Views/Trade.vGetUsRegulationIds.sql*
