# AffiliateCommission.ClosedPositionIDSalesID

> Bridge table mapping new-system ClosedPositionIDs to legacy SalesIDs from the old tblaff_Sales commission system, enabling backward compatibility during the gradual migration.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | ClosedPositionID (bigint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (PK clustered + NC on SalesID) |

---

## 1. Business Meaning

ClosedPositionIDSalesID is a bridge/mapping table that links the new commission system's ClosedPositionID to the legacy system's SalesID (from dbo.tblaff_Sales). This table exists because the migration from the legacy affiliate system to the new AffiliateCommission schema was done incrementally, and some downstream reporting and payment processes still reference the old SalesID.

The table has 21,206 rows, which is a subset of the 246,449 positions in ClosedPosition. This suggests that the mapping is only created for positions that also need a legacy SalesID (early positions during migration), and newer positions may not have a legacy counterpart.

The NC index on SalesID supports reverse lookups - given a legacy SalesID, find the corresponding new ClosedPositionID.

---

## 2. Business Logic

No complex business logic. This is a pure ID mapping table for migration compatibility.

---

## 3. Data Overview

| ClosedPositionID | SalesID | Meaning |
|---|---|---|
| 71198 | 5631782 | Maps new position 71198 to legacy sales record 5631782. Higher SalesID suggests the legacy system has many more records. |
| 61199 | 5631741 | Earlier position, sequential SalesID. Gap between ClosedPositionID (61199 vs 71198) larger than SalesID gap (41), suggesting non-1:1 creation. |
| 61198 | 5631740 | Consecutive pair (61198/61199 -> 5631740/5631741). Shows sequential mapping for consecutive positions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClosedPositionID | bigint | NO | - | CODE-BACKED | New system position ID. PK. Maps to ClosedPosition.ClosedPositionID. One row per mapped position. |
| 2 | SalesID | int | YES | - | CODE-BACKED | Legacy system sales record ID. Maps to dbo.tblaff_Sales. Nullable to handle edge cases where the legacy record could not be created. Indexed for reverse lookups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ClosedPositionID | AffiliateCommission.ClosedPosition | Implicit FK | New system position record |
| SalesID | dbo.tblaff_Sales | Implicit FK | Legacy system sales record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.ClosedPositionIDSalesID (table)
└── AffiliateCommission.ClosedPosition (table) [implicit, via ClosedPositionID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPosition | Table | ClosedPositionID references position |

### 6.2 Objects That Depend On This

No dependents found in this schema's stored procedures.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AffiliateCommissionPositionIDSalesID | CLUSTERED PK | ClosedPositionID ASC | - | - | Active |
| IX_ClosedPositionIDSalesID$SalesID | NC | SalesID ASC | - | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_AffiliateCommissionPositionIDSalesID | PRIMARY KEY | Unique ClosedPositionID |

---

## 8. Sample Queries

### 8.1 Look up legacy SalesID for a position
```sql
SELECT SalesID FROM AffiliateCommission.ClosedPositionIDSalesID WITH (NOLOCK)
WHERE ClosedPositionID = 71198;
```

### 8.2 Reverse lookup - find new ID from legacy SalesID
```sql
SELECT ClosedPositionID FROM AffiliateCommission.ClosedPositionIDSalesID WITH (NOLOCK)
WHERE SalesID = 5631782;
```

### 8.3 Positions without legacy mapping
```sql
SELECT TOP 100 cp.ClosedPositionID, cp.CommissionDate
FROM AffiliateCommission.ClosedPosition cp WITH (NOLOCK)
LEFT JOIN AffiliateCommission.ClosedPositionIDSalesID m WITH (NOLOCK)
    ON cp.ClosedPositionID = m.ClosedPositionID
WHERE m.ClosedPositionID IS NULL
ORDER BY cp.ClosedPositionID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ClosedPositionIDSalesID | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.ClosedPositionIDSalesID.sql*
