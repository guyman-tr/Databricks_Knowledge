# dbo.TrackingParameters

> Stores third-party marketing tracking parameters per user and event, linking to providers and events for attribution analytics.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

dbo.TrackingParameters stores the actual tracking data sent by third-party marketing providers during user events. Each row captures a single parameter name-value pair for a specific user (GCID), event type, and provider. Used for marketing attribution and conversion tracking.

---

## 2. Business Logic

No complex multi-column business logic. Key-value parameter store per user/event/provider.

---

## 3. Data Overview

N/A - transactional table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Auto-incrementing parameter record ID. |
| 2 | TrackingProviderId | int | NO | - | CODE-BACKED | FK to dbo.TrackingProviders. Which marketing provider sent this data. |
| 3 | TrackingEventId | int | NO | - | CODE-BACKED | Implicit FK to dbo.TrackingEvents. Which user event this parameter relates to. |
| 4 | GCID | int | NO | - | CODE-BACKED | Global Customer ID of the user. |
| 5 | ParameterName | nvarchar(500) | NO | - | CODE-BACKED | Tracking parameter name (e.g., utm_source, click_id, campaign_id). |
| 6 | ParameterValue | nvarchar(2048) | NO | - | CODE-BACKED | Tracking parameter value. |
| 7 | InsertDate | smalldatetime | NO | - | CODE-BACKED | When this tracking parameter was recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TrackingProviderId | dbo.TrackingProviders | Explicit FK | Marketing provider |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.InsertTrackingParmeter | Id | SP writes | Inserts tracking data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.TrackingParameters (table)
  +-- dbo.TrackingProviders (table) [done in this batch]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.TrackingProviders | Table | FK: TrackingProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.InsertTrackingParmeter | Stored Procedure | Inserts rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_dbo.ThirdPartyTracking | CLUSTERED PK | Id | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_TrackingParameters_TrackingProviders | FOREIGN KEY | TrackingProviderId -> dbo.TrackingProviders(Id) |

---

## 8. Sample Queries

### 8.1 Tracking data for a user
```sql
SELECT tp.ParameterName, tp.ParameterValue, te.Name AS Event, tp2.Name AS Provider, tp.InsertDate
FROM dbo.TrackingParameters tp WITH (NOLOCK)
JOIN dbo.TrackingProviders tp2 WITH (NOLOCK) ON tp.TrackingProviderId = tp2.Id
JOIN dbo.TrackingEvents te WITH (NOLOCK) ON tp.TrackingEventId = te.Id
WHERE tp.GCID = @GCID ORDER BY tp.InsertDate DESC
```

### 8.2 Recent tracking entries
```sql
SELECT TOP 100 GCID, ParameterName, ParameterValue, InsertDate FROM dbo.TrackingParameters WITH (NOLOCK) ORDER BY InsertDate DESC
```

### 8.3 Parameters by provider
```sql
SELECT tp2.Name, COUNT(*) AS ParamCount FROM dbo.TrackingParameters tp WITH (NOLOCK)
JOIN dbo.TrackingProviders tp2 WITH (NOLOCK) ON tp.TrackingProviderId = tp2.Id GROUP BY tp2.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: dbo.TrackingParameters | Type: Table | Source: UserApiDB/UserApiDB/dbo/Tables/dbo.TrackingParameters.sql*
