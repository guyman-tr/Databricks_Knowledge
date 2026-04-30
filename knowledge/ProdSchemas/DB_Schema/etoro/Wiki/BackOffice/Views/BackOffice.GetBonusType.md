# BackOffice.GetBonusType

> Simple two-column view exposing BonusTypeID and Name from BackOffice.BonusType for lookup and display purposes.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | BonusTypeID (from BackOffice.BonusType) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetBonusType` is a minimal lookup view that exposes the ID and name of each bonus type from `BackOffice.BonusType`. It provides a clean, stable public interface for retrieving the bonus type catalog without exposing the full table structure (ParentBonusTypeID, CreatedBy, etc.).

The bonus type catalog classifies every credit adjustment (bonus) issued to customers by the department and program that owns it: Sales first-deposit bonuses, Marketing promotions, Retention adjustments, Accounting/Ops fee refunds, R&D test credits, MT4 transfers, etc. This view is the standard read path for populating bonus type dropdowns, lookups, and report filters in back-office tooling.

---

## 2. Business Logic

### 2.1 Direct Projection of BonusType Catalog

**What**: Returns all BonusTypeID and Name rows from BackOffice.BonusType with no filtering.

**Rules**:
- No WHERE clause - all rows returned including hierarchy roots and leaf types.
- Does not filter by department, parent, or active status.
- The `WITH (NOLOCK)` hint on the base query avoids blocking on the small lookup table.

---

## 3. Data Overview

Matches `BackOffice.BonusType` row count (small reference table, ~50-100 rows). Two-level hierarchy: root department categories + specific bonus program types.

---

## 4. Elements

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | BonusTypeID | int | CODE-BACKED | Primary key of the bonus type. Matches BackOffice.BonusType.BonusTypeID. Referenced by BackOffice.Bonus.BonusTypeID. |
| 2 | Name | nvarchar | CODE-BACKED | Display name of the bonus type (e.g., "FTD Bonus", "Marketing Promotion", "Fee Refund"). Used for UI dropdowns and report labels. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BonusTypeID, Name | BackOffice.BonusType | Base Table | Direct projection of ID and Name columns |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No BackOffice SP consumers identified in SSDT repo) | - | - | Likely consumed by application layer for dropdown/lookup population |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetBonusType (view)
+-- BackOffice.BonusType (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BonusType | Table | Sole data source - projects BonusTypeID and Name |

### 6.2 Objects That Depend On This

No stored procedure consumers identified in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A. BackOffice.BonusType has clustered PK on BonusTypeID.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 List all bonus types

```sql
SELECT BonusTypeID, Name
FROM BackOffice.GetBonusType WITH (NOLOCK)
ORDER BY Name;
```

### 8.2 Join to bonus records for a customer

```sql
SELECT bb.BonusID, bb.Amount, gbt.Name AS BonusType, bb.CreatedOn
FROM BackOffice.Bonus bb WITH (NOLOCK)
JOIN BackOffice.GetBonusType gbt WITH (NOLOCK)
    ON gbt.BonusTypeID = bb.BonusTypeID
WHERE bb.CID = 12345
ORDER BY bb.CreatedOn DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this view.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11 (DDL, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetBonusType | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.GetBonusType.sql*
