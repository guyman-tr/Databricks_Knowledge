# dbo.qry_ValidRecurringCommissions

> Filters tblaff_RecurringCommissions to show only active, due recurring commission schedules that have not yet reached their repeat limit and whose frequency interval has elapsed.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: dbo.tblaff_RecurringCommissions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.qry_ValidRecurringCommissions is a filtered view over dbo.tblaff_RecurringCommissions that returns only recurring commission schedules that are both active (NumberCompleted < Repeat) and due for payment (days since LastDate >= Frequency). This is the processing queue for the recurring commission engine.

The base table is currently empty (0 rows), so this view also returns 0 rows. The feature appears inactive in this environment.

---

## 2. Business Logic

### 2.1 Dual Filter: Active AND Due

**What**: Two conditions must be met for a recurring commission to appear.

**Columns/Parameters Involved**: `NumberCompleted`, `Repeat`, `LastDate`, `Frequency`

**Rules**:
- `NumberCompleted < Repeat`: Schedule has not exhausted its repetitions
- `DATEDIFF(d, LastDate, GETDATE()) >= Frequency`: Enough days have passed since the last payment
- Both conditions must be true simultaneously
- Note: schedules with Repeat=0 (unlimited) would satisfy NumberCompleted < Repeat only if NumberCompleted is also 0 or negative - this may be a design limitation

---

## 3. Data Overview

View returns 0 rows (base table is empty).

---

## 4. Elements

All columns inherited from dbo.tblaff_RecurringCommissions. See [dbo.tblaff_RecurringCommissions](../Tables/dbo.tblaff_RecurringCommissions.md) for complete descriptions (15 columns).

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1-15 | (all columns) | (various) | (various) | - | VERIFIED | SELECT * from base table. All 15 columns passed through unchanged. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all) | dbo.tblaff_RecurringCommissions | Base table | Filtered SELECT * |

### 5.2 Referenced By (other objects point to this)

No dependents found in SSDT.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.qry_ValidRecurringCommissions (view)
  +-- dbo.tblaff_RecurringCommissions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_RecurringCommissions | Table | Base table |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

N/A for view.

---

## 8. Sample Queries

### 8.1 Check for due recurring commissions
```sql
SELECT * FROM dbo.qry_ValidRecurringCommissions WITH (NOLOCK)
```

### 8.2 Total due recurring commission amount
```sql
SELECT SUM(Commission) AS TotalDue, COUNT(*) AS SchedulesDue
FROM dbo.qry_ValidRecurringCommissions WITH (NOLOCK)
```

### 8.3 Due commissions by affiliate
```sql
SELECT AffiliateID, SUM(Commission) AS DueAmount, COUNT(*) AS Schedules
FROM dbo.qry_ValidRecurringCommissions WITH (NOLOCK)
GROUP BY AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.qry_ValidRecurringCommissions | Type: View | Source: fiktivo/dbo/Views/dbo.qry_ValidRecurringCommissions.sql*
