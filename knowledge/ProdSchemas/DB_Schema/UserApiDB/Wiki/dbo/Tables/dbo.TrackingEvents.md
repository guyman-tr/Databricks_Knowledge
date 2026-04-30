# dbo.TrackingEvents

> Lookup table defining third-party tracking event types (registration, deposit, etc.) for marketing attribution.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

dbo.TrackingEvents defines the types of user events that are tracked for third-party marketing attribution (e.g., registration, first deposit, first trade). These event types are referenced by TrackingParameters to associate tracking data with specific user actions.

---

## 2. Business Logic

No complex business logic. Simple ID+Name lookup.

---

## 3. Data Overview

Small lookup table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Primary key. Event type identifier. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Event type name (e.g., Registration, FirstDeposit, FirstTrade). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.TrackingParameters | TrackingEventId | Implicit FK | Event type for tracking data |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.TrackingParameters | Table | References TrackingEventId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TrackingEvents | CLUSTERED PK | Id | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all events
```sql
SELECT Id, Name FROM dbo.TrackingEvents WITH (NOLOCK) ORDER BY Id
```

### 8.2 Tracking data by event
```sql
SELECT te.Name, COUNT(*) AS ParamCount FROM dbo.TrackingParameters tp WITH (NOLOCK)
JOIN dbo.TrackingEvents te WITH (NOLOCK) ON tp.TrackingEventId = te.Id GROUP BY te.Name
```

### 8.3 Find event by name
```sql
SELECT Id FROM dbo.TrackingEvents WITH (NOLOCK) WHERE Name = @EventName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: dbo.TrackingEvents | Type: Table | Source: UserApiDB/UserApiDB/dbo/Tables/dbo.TrackingEvents.sql*
