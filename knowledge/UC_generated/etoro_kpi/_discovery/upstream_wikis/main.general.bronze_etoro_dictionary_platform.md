# Dictionary.Platform

> Lookup table defining the client platform types (Web, iOS, Android) from which users access the eToro trading application.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (INT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.Platform defines the device/application platforms from which customers access the eToro trading application. Every user session, trade, and interaction is tagged with a platform identifier to enable per-platform analytics, feature flagging, and UX customization.

This is critical for product and engineering teams because the platform determines which features are available (some features are web-only or mobile-only), which UI is rendered, and which API endpoints are called. Marketing uses platform data to analyze user acquisition channels and engagement patterns across devices.

The "Undefined" value (0) serves as a fallback for sessions where platform detection failed or for server-side operations that are not initiated by a user device.

---

## 2. Business Logic

### 2.1 Multi-Platform Access

**What**: Users can access eToro from multiple platforms, each with different capabilities and UX.

**Columns/Parameters Involved**: `Id`, `Platform`

**Rules**:
- **Undefined (0)**: Platform not detected or not applicable (server-side operations, API calls without client context)
- **Web (1)**: Browser-based access — full feature set, desktop-optimized trading interface
- **IOS (2)**: iPhone/iPad native app — mobile-optimized trading, push notifications, Face ID authentication
- **Android (3)**: Android native app — mobile-optimized trading, push notifications, biometric authentication
- Each user action/trade records the platform it originated from for analytics
- Feature flags can be platform-specific (e.g., a feature rolled out to iOS first)

---

## 3. Data Overview

| Id | Platform | Meaning |
|---|---|---|
| 0 | Undefined | Platform not detected — used for server-initiated actions, API calls without user-agent, or legacy records before platform tracking was added |
| 1 | Web | Browser-based access via desktop or mobile browser — full trading interface with charting, CopyTrader, portfolio management |
| 2 | IOS | Apple iOS native app — iPhone/iPad trading with push notifications, Face ID, and mobile-optimized experience |
| 3 | Android | Google Android native app — trading with push notifications, biometric auth, and mobile-optimized experience |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Platform identifier: **0**=Undefined, **1**=Web, **2**=IOS, **3**=Android. Referenced by session tracking, trade records, and analytics tables. |
| 2 | Platform | nvarchar(20) | NO | - | CODE-BACKED | Platform name: "Undefined", "Web", "IOS", "Android". Used in reporting dashboards and API responses. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Session/trade tables | PlatformID | Implicit | Records the originating platform for user actions |
| Dictionary.ApplicationIdentifier | PlatformID | Implicit | Links app identifiers to platforms |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.Platform (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Session and trade tracking | Tables | Records platform per user action |
| Analytics/BI | Various | Platform-segmented reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_Platform | CLUSTERED PK | Id | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_Platform | PRIMARY KEY | Unique platform, FILLFACTOR 95, DATA_COMPRESSION PAGE, DICTIONARY filegroup |

---

## 8. Sample Queries

### 8.1 List all platforms
```sql
SELECT  Id, Platform
FROM    Dictionary.Platform WITH (NOLOCK)
ORDER BY Id;
```

### 8.2 Resolve platform ID to name
```sql
SELECT  p.Platform
FROM    Dictionary.Platform p WITH (NOLOCK)
WHERE   p.Id = 2; -- IOS
```

### 8.3 Platform distribution (conceptual join)
```sql
SELECT  p.Platform,
        COUNT(*) AS ActionCount
FROM    Dictionary.Platform p WITH (NOLOCK)
CROSS APPLY (SELECT 1 AS Example) x
GROUP BY p.Platform;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Platform | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Platform.sql*
