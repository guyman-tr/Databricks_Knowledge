# BackOffice.JUNK_GetAverageLotCount

> **DEPRECATED (JUNK prefix)** - Returns a single scalar value: the platform-wide average lot count across all historical closed positions in History.Position.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | AverageLotCountDecimal - single scalar row |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAverageLotCount` is a legacy, single-value view (JUNK prefix indicates deprecated) that computes the platform-wide average lot size across all records in `History.Position`. It returns exactly one row with one column: the mean `LotCountDecimal` cast to FLOAT.

This view was likely used for analytical baselines or risk benchmarks - "What is the typical position size on the platform?" The JUNK prefix and absence of any active consumers indicate it was abandoned, possibly when more sophisticated reporting tools replaced ad-hoc SQL views for analytics.

`History.Position` resides in the EtoroArchive database which is not accessible via the current MCP connection, so live data cannot be sampled.

---

## 2. Business Logic

### 2.1 Platform-Wide Average Lot Calculation

**What**: Computes the arithmetic mean of all lot sizes across the entire History.Position table (no filters, no date range).

**Columns/Parameters Involved**: `AverageLotCountDecimal`

**Rules**:
- `AVG(CAST(LotCountDecimal AS FLOAT))` - CAST to FLOAT prevents integer truncation in the average calculation
- No WHERE filter - includes ALL historical positions regardless of status, date, instrument, or provider
- Returns exactly 1 row, always

---

## 3. Data Overview

*Live data not available - History.Position references EtoroArchive database, not accessible in current environment.*

| AverageLotCountDecimal | Meaning |
|------------------------|---------|
| (e.g., 1.234567) | The arithmetic mean of LotCountDecimal across all rows in History.Position. Represents the typical position size in standard lots ever opened on the eToro platform. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AverageLotCountDecimal | FLOAT (computed) | YES | - | CODE-BACKED | Platform-wide arithmetic mean of `LotCountDecimal` across all records in `History.Position`. Cast to FLOAT for decimal precision. Returns NULL if History.Position is empty. Represents the average position size in standard lots across the platform's entire trading history. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AverageLotCountDecimal | History.Position | Source (cross-schema, NOLOCK) | Sole data source - all closed/historical positions in the EtoroArchive database. |

### 5.2 Referenced By (other objects point to this)

No active dependents found. Legacy view with JUNK prefix.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAverageLotCount (view) [DEPRECATED]
└── History.Position (cross-schema table - EtoroArchive)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Cross-schema Table | FROM clause (NOLOCK) - sole data source for AVG(LotCountDecimal) |

### 6.2 Objects That Depend On This

No active dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Get the platform-wide average lot count

```sql
SELECT AverageLotCountDecimal
FROM BackOffice.JUNK_GetAverageLotCount WITH (NOLOCK)
```

### 8.2 Compare average lot to a threshold

```sql
SELECT AverageLotCountDecimal,
       CASE WHEN AverageLotCountDecimal > 2.0 THEN 'High' ELSE 'Low' END AS LotSizeCategory
FROM BackOffice.JUNK_GetAverageLotCount WITH (NOLOCK)
```

### 8.3 Direct equivalent without the view

```sql
SELECT AVG(CAST(LotCountDecimal AS FLOAT)) AS AverageLotCountDecimal
FROM History.Position WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7 (Phase 2 blocked - EtoroArchive)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAverageLotCount | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.JUNK_GetAverageLotCount.sql*
