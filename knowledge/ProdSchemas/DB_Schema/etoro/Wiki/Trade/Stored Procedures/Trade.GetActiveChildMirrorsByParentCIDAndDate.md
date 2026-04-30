# Trade.GetActiveChildMirrorsByParentCIDAndDate

> Returns active child mirror (copier) relationships for a parent investor that are eligible for copy dividend distribution before a given date.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns mirror records with copier CID, equity, and calculation type |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the active CopyTrader mirror relationships where copiers are following a specific parent (leader) investor, filtered to those eligible for copy dividend distribution. It is used during the dividend payment workflow to identify which copiers should receive proportional dividend payments based on their mirror of the parent's portfolio.

The procedure exists to support the CopyTrader dividend distribution feature. When a dividend event occurs for a parent investor's positions, each active copier who has copy dividend enabled (UseCopyDividend=1) and whose mirror was established before the dividend date receives a proportional share.

Data flows from Trade.Mirror filtered by ParentCID, active status, copy dividend eligibility, and creation date. The procedure returns the copier's CID, MirrorID, RealizedEquity (for proportional calculation), the parent's username, the mirror calculation type, and the mirror status.

---

## 2. Business Logic

### 2.1 Copy Dividend Eligibility Filter

**What**: Only mirrors that meet all four criteria are included in dividend distribution.

**Columns/Parameters Involved**: `ParentCID`, `UseCopyDividend`, `IsActive`, `Occurred`, `@Date`

**Rules**:
- ParentCID = @CID: mirror must be copying this specific parent
- UseCopyDividend = 1: copier must have opted into copy dividends
- IsActive = 1: mirror relationship must be currently active
- Occurred <= @Date: mirror must have been established on or before the dividend date (prevents new copiers from receiving dividends for events before they started copying)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Parent (leader) investor CID whose copiers should receive dividends. |
| 2 | @Date | DATETIME | NO | - | CODE-BACKED | Dividend event date. Only mirrors created on or before this date are eligible. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | CID | INT | NO | - | CODE-BACKED | Copier's customer ID - the person copying the parent investor. |
| 4 | MirrorID | BIGINT | NO | - | CODE-BACKED | Unique mirror relationship identifier linking copier to parent. |
| 5 | RealizedEquity | MONEY | YES | - | CODE-BACKED | Copier's realized equity in the mirror relationship. Used for proportional dividend calculation. |
| 6 | ParentUserName | VARCHAR | YES | - | CODE-BACKED | Display username of the parent (leader) being copied. |
| 7 | MirrorCalculationType | TINYINT | YES | - | CODE-BACKED | Calculation method for the mirror relationship (determines how copy amounts are computed). |
| 8 | MirrorStatusID | TINYINT | YES | - | CODE-BACKED | Current status of the mirror relationship. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Mirror | Direct Read | Reads active mirror relationships for the parent CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetActiveChildMirrorsByParentCIDAndDate (procedure)
└── Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | SELECT with NOLOCK - reads active mirror relationships |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get dividend-eligible copiers for a parent investor

```sql
EXEC Trade.GetActiveChildMirrorsByParentCIDAndDate
    @CID = 12345678,
    @Date = '2026-03-15';
```

### 8.2 Check all active mirrors for a parent

```sql
SELECT  CID,
        MirrorID,
        UseCopyDividend,
        IsActive,
        Occurred,
        RealizedEquity
FROM    Trade.Mirror WITH (NOLOCK)
WHERE   ParentCID = 12345678
    AND IsActive = 1;
```

### 8.3 Count dividend-eligible copiers per parent

```sql
SELECT  ParentCID,
        COUNT(*) AS EligibleCopiers
FROM    Trade.Mirror WITH (NOLOCK)
WHERE   UseCopyDividend = 1
    AND IsActive = 1
    AND Occurred <= GETUTCDATE()
GROUP BY ParentCID
ORDER BY EligibleCopiers DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetActiveChildMirrorsByParentCIDAndDate | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetActiveChildMirrorsByParentCIDAndDate.sql*
