# dbo.InsertTrackingParmeter

> Inserts a single marketing tracking parameter into dbo.TrackingParameters for third-party attribution.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid + @trackingProviderId + @trackingEventId (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.InsertTrackingParmeter (note: typo in name "Parmeter") inserts a single tracking parameter into dbo.TrackingParameters. Each call records one name-value pair for a specific user, provider, and event.

---

## 2. Business Logic

No complex business logic. Single INSERT.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @trackingProviderId | int (IN) | NO | - | CODE-BACKED | Marketing provider. FK to dbo.TrackingProviders. |
| 2 | @trackingEventId | int (IN) | NO | - | CODE-BACKED | Event type. FK to dbo.TrackingEvents. |
| 3 | @gcid | int (IN) | NO | - | CODE-BACKED | User GCID. |
| 4 | @parameterName | nvarchar(500) (IN) | NO | - | CODE-BACKED | Parameter name (e.g., utm_source). |
| 5 | @parameterValue | nvarchar(2048) (IN) | NO | - | CODE-BACKED | Parameter value. |
| 6 | @insertDate | smalldatetime (IN) | NO | - | CODE-BACKED | When the parameter was captured. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.TrackingParameters | INSERT INTO | Writes tracking data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.InsertTrackingParmeter (procedure)
  +-- dbo.TrackingParameters (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.TrackingParameters | Table | INSERT INTO |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Insert tracking parameter
```sql
EXEC dbo.InsertTrackingParmeter @trackingProviderId = 1, @trackingEventId = 1, @gcid = 12345,
  @parameterName = N'utm_source', @parameterValue = N'google', @insertDate = '2026-04-12'
```

### 8.2 Multiple parameters for one event
```sql
EXEC dbo.InsertTrackingParmeter @trackingProviderId = 1, @trackingEventId = 1, @gcid = 12345, @parameterName = N'utm_source', @parameterValue = N'google', @insertDate = '2026-04-12'
EXEC dbo.InsertTrackingParmeter @trackingProviderId = 1, @trackingEventId = 1, @gcid = 12345, @parameterName = N'utm_campaign', @parameterValue = N'spring2026', @insertDate = '2026-04-12'
```

### 8.3 Verify
```sql
SELECT * FROM dbo.TrackingParameters WITH (NOLOCK) WHERE GCID = 12345 ORDER BY Id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: dbo.InsertTrackingParmeter | Type: Stored Procedure | Source: UserApiDB/UserApiDB/dbo/Stored Procedures/dbo.InsertTrackingParmeter.sql*
