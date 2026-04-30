# dbo.TrackingProviders

> Lookup table defining third-party marketing/tracking providers for attribution (Google Analytics, Facebook Pixel, etc.).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

dbo.TrackingProviders defines the third-party tracking/analytics providers integrated with the platform for marketing attribution and conversion tracking. Referenced by TrackingParameters via explicit FK.

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
| 1 | Id | int | NO | - | CODE-BACKED | Primary key. Provider identifier. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Provider name (e.g., GoogleAnalytics, FacebookPixel). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.TrackingParameters | TrackingProviderId | Explicit FK | Provider for tracking data |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.TrackingParameters | Table | FK: TrackingProviderId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ThirdPartyTrackingProviders | CLUSTERED PK | Id | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all providers
```sql
SELECT Id, Name FROM dbo.TrackingProviders WITH (NOLOCK) ORDER BY Id
```

### 8.2 Tracking data by provider
```sql
SELECT tp2.Name, COUNT(*) AS ParamCount FROM dbo.TrackingParameters tp WITH (NOLOCK)
JOIN dbo.TrackingProviders tp2 WITH (NOLOCK) ON tp.TrackingProviderId = tp2.Id GROUP BY tp2.Name
```

### 8.3 Find provider
```sql
SELECT Id FROM dbo.TrackingProviders WITH (NOLOCK) WHERE Name = @ProviderName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: dbo.TrackingProviders | Type: Table | Source: UserApiDB/UserApiDB/dbo/Tables/dbo.TrackingProviders.sql*
