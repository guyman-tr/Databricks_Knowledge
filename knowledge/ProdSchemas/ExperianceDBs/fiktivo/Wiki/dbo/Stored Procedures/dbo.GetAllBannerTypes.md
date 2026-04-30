# dbo.GetAllBannerTypes

> Returns all banner type ID and name pairs from the tblaff_BannerTypes reference table.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | BannerTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a reference data lookup that returns the full list of banner types used in the affiliate creative/banner management system. Banner types classify the kind of creative asset (e.g., static image, animated GIF, video, HTML5) and are used to filter and categorize banners in the partner portal. It was introduced to support banner data display in the Partners Portal as part of PART-3001 (June 2024).

---

## 2. Business Logic

- Simple unconditional SELECT of BannerTypeID and BannerTypeName from dbo.tblaff_BannerTypes.
- No parameters, no filtering, no NOLOCK hint, no NOCOUNT.
- Returns all rows in the reference table.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| (none) | - | - | - | - | - | This procedure takes no parameters |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.tblaff_BannerTypes | Read | Returns all banner type reference rows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAllBannerTypes
  └── dbo.tblaff_BannerTypes   (READ)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_BannerTypes | Table | Reference table for banner type definitions |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

```sql
-- Retrieve all banner types for dropdown population
EXEC dbo.GetAllBannerTypes;

-- Use in application-layer filter
DECLARE @Types TABLE (BannerTypeID INT, BannerTypeName NVARCHAR(200));
INSERT INTO @Types EXEC dbo.GetAllBannerTypes;
SELECT * FROM @Types ORDER BY BannerTypeName;

-- Check if a specific type exists
DECLARE @BT TABLE (BannerTypeID INT, BannerTypeName NVARCHAR(200));
INSERT INTO @BT EXEC dbo.GetAllBannerTypes;
SELECT * FROM @BT WHERE BannerTypeID = 3;
```

---

## 9. Atlassian Knowledge Sources

- PART-3001 - Gil Haba, 17/06/2024: Support banner data in the Partners Portal.

---

*Generated: 2026-04-12 | Quality: 7.8/10*
*Object: dbo.GetAllBannerTypes | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAllBannerTypes.sql*
