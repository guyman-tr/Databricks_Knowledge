# dbo.InlineMax

> Scalar function returning the maximum of up to 6 datetime values, used in CPA compensation design for determining the latest event date across multiple commission types.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns datetime |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.InlineMax is a utility function that returns the maximum (latest) value from up to 6 datetime parameters. It was created for the CPA New Compensation Design (PART-2448, 2023-12-17) to determine the latest qualifying event date across multiple commission types when calculating CPA eligibility windows.

The function uses VALUES/MAX pattern with SCHEMABINDING for optimal performance in inline expressions and computed columns.

---

## 2. Business Logic

### 2.1 Maximum of N Datetimes

**What**: Returns the latest datetime from up to 6 inputs.

**Columns/Parameters Involved**: `@val1` through `@val6`

**Rules**:
- Uses VALUES table constructor with MAX aggregate for efficient comparison
- NULL values are automatically excluded by MAX (NULL-safe)
- SCHEMABINDING enables use in indexed computed columns
- All 6 parameters are required (pass NULL for unused positions)

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @val1 | datetime | YES | - | VERIFIED | First datetime value to compare. Typically a CPA-related event date. |
| 2 | @val2 | datetime | YES | - | VERIFIED | Second datetime value. |
| 3 | @val3 | datetime | YES | - | VERIFIED | Third datetime value. |
| 4 | @val4 | datetime | YES | - | VERIFIED | Fourth datetime value. |
| 5 | @val5 | datetime | YES | - | VERIFIED | Fifth datetime value. |
| 6 | @val6 | datetime | YES | - | VERIFIED | Sixth datetime value. |
| 7 | RETURN | datetime | YES | - | VERIFIED | The maximum (latest) datetime among the 6 inputs. NULL if all inputs are NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (SCHEMABINDING, no tables).

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Created for PART-2448 CPA compensation calculations.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies. WITH SCHEMABINDING, no table references.

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

N/A for function.

---

## 8. Sample Queries

### 8.1 Basic usage - find latest date
```sql
SELECT dbo.InlineMax('2024-01-15', '2024-03-20', '2024-02-10', NULL, NULL, NULL) AS LatestDate
```

### 8.2 Find latest event across commission types for an affiliate
```sql
SELECT a.AffiliateID,
       dbo.InlineMax(
         (SELECT MAX(ORDER_DATE) FROM dbo.tblaff_Registrations r WITH (NOLOCK) WHERE r.AffiliateID = a.AffiliateID),
         (SELECT MAX(ORDER_DATE) FROM dbo.tblaff_Leads l WITH (NOLOCK) WHERE l.AffiliateID = a.AffiliateID),
         (SELECT MAX([date]) FROM dbo.tblaff_CPA c WITH (NOLOCK) WHERE c.affiliateID = a.AffiliateID),
         NULL, NULL, NULL
       ) AS LatestEventDate
FROM dbo.tblaff_Affiliates a WITH (NOLOCK)
WHERE a.AffiliateID = @AffiliateID
```

### 8.3 NULL-safe behavior
```sql
SELECT dbo.InlineMax(NULL, '2024-01-01', NULL, NULL, NULL, NULL) AS Result
-- Returns: 2024-01-01 (NULLs ignored)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-2448](https://etoro-jira.atlassian.net/browse/PART-2448) | Jira | CPA New Compensation Design - function created for this feature (referenced in code comment) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.InlineMax | Type: Scalar Function | Source: fiktivo/dbo/Functions/dbo.InlineMax.sql*
