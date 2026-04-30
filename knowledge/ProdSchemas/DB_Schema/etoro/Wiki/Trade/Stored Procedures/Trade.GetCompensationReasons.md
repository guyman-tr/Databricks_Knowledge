# Trade.GetCompensationReasons

> Returns all compensation reason codes and names from the BackOffice.CompensationReason lookup table, providing the reference data for customer compensation workflows.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from BackOffice.CompensationReason |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the complete list of reasons why a customer might receive compensation (e.g., system error, price dispute, goodwill gesture). It serves as a lookup data provider for administrative interfaces where operators select a compensation reason when processing customer compensation requests.

Without this procedure, the admin UI would not have the list of valid compensation reasons to present to operators. It ensures consistency by centralizing the reason lookup.

Data flow: Admin/BackOffice UI calls this procedure -> returns all compensation reasons ordered by ID -> UI populates a dropdown or selection list.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple lookup table reader. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

None.

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CompensationReasonID | INT | NO | - | CODE-BACKED | Unique identifier for the compensation reason. Primary key of BackOffice.CompensationReason. |
| 2 | Name | VARCHAR | NO | - | CODE-BACKED | Human-readable name of the compensation reason (e.g., "System Error", "Price Adjustment", "Goodwill"). Displayed in admin UI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | BackOffice.CompensationReason | Read | Reads all compensation reason records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Admin/BackOffice UI | EXEC | Caller | Populates compensation reason selection lists |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCompensationReasons (procedure)
└── BackOffice.CompensationReason (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CompensationReason | Table | Source of all compensation reasons |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Admin UI | External | Reads compensation reasons for display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Trade.GetCompensationReasons;
```

### 8.2 Query the source table directly

```sql
SELECT CompensationReasonID, Name
FROM BackOffice.CompensationReason WITH (NOLOCK)
ORDER BY CompensationReasonID;
```

### 8.3 Find which compensation reasons are most used

```sql
SELECT cr.CompensationReasonID, cr.Name, COUNT(*) AS UsageCount
FROM BackOffice.CompensationReason cr WITH (NOLOCK)
INNER JOIN BackOffice.Compensation c WITH (NOLOCK) ON c.CompensationReasonID = cr.CompensationReasonID
GROUP BY cr.CompensationReasonID, cr.Name
ORDER BY COUNT(*) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCompensationReasons | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCompensationReasons.sql*
