# Dictionary.ClientType

> Lookup table defining the 8 client application types — identifying which platform or app a customer is using (WebTrader, Android, iPhone, OpenBook, etc.).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ClientTypeID (tinyint, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 clustered PK + 1 unique NC on ClientTypeName |

---

## 1. Business Meaning

Dictionary.ClientType identifies the platform or application that a customer is using to interact with eToro. When a user logs in or performs an action, the system records which client type they used — whether it's the web-based trader, the mobile apps, or the legacy social trading platform (OpenBook).

This classification serves multiple purposes: analytics (tracking platform adoption), feature gating (enabling/disabling features per platform), customer support (understanding the user's context when troubleshooting), and marketing attribution (understanding which platforms drive engagement). The data reveals eToro's platform evolution — from a downloadable desktop client (ID=1) through web and mobile apps to the social trading platform OpenBook and its mobile variant.

No direct FK references to `Dictionary.ClientType` were found in the SSDT project, suggesting this table is consumed by application-layer logging and analytics code rather than by stored procedures.

---

## 2. Business Logic

### 2.1 Platform Categories

**What**: Three generations of client applications across multiple device types.

**Columns/Parameters Involved**: `ClientTypeID`, `ClientTypeName`

**Rules**:
- **Legacy Desktop (ID=1)**: The original downloadable desktop trading client. Predates the web platform — represents the earliest generation of eToro clients.
- **Modern Platforms (IDs 2-4)**: WebTrader (browser-based trading), Android, and iPhone apps — the core modern platforms that most customers use today.
- **Social Trading (IDs 5-7)**: OpenBook (web-based social trading platform), OpenBook Mobile (mobile variant), and CopyMe (a specialized CopyTrading interface). These represent eToro's social/copy trading ecosystem.
- **Unknown (ID=0)**: Default value when the client type cannot be determined — possibly from API calls without client identification headers.

---

## 3. Data Overview

| ClientTypeID | ClientTypeName | Meaning |
|---|---|---|
| 0 | Unknown | Client type could not be determined — API request without client identification or legacy system integration that doesn't report platform type. Default fallback value. |
| 1 | Download | Legacy downloadable desktop trading application — the original eToro trading client before web-based platforms existed. Likely deprecated. |
| 2 | WebTrader | Browser-based trading platform — the primary web client accessed via desktop/laptop browsers. Most feature-complete client with full trading, analysis, and social features. |
| 3 | Android | eToro mobile app for Android devices — full trading capabilities optimized for mobile with push notifications and biometric login. |
| 4 | iPhone | eToro mobile app for iOS devices — same capabilities as Android with iOS-specific optimizations. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClientTypeID | tinyint | NO | - | VERIFIED | Primary key identifying the client platform. Values 0-7. Uses tinyint (0-255 range) — sufficient for the small number of platform types. Recorded with user actions and sessions for analytics and feature gating. |
| 2 | ClientTypeName | varchar(20) | NO | - | VERIFIED | Name of the client platform (e.g., 'WebTrader', 'Android', 'iPhone', 'OpenBook'). Enforced unique via `UK_DCT_ClientTypeName` constraint. Used in analytics reports and admin UIs to identify platform distribution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No FK references found in the SSDT project. Consumed by application-layer logging and analytics code.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the SSDT project.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCT | CLUSTERED PK | ClientTypeID ASC | - | - | Active |
| UK_DCT_ClientTypeName | UNIQUE NC | ClientTypeName ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UK_DCT_ClientTypeName | UNIQUE | Ensures no two client types share the same name |

---

## 8. Sample Queries

### 8.1 List all client types
```sql
SELECT  ClientTypeID,
        ClientTypeName
FROM    Dictionary.ClientType WITH (NOLOCK)
ORDER BY ClientTypeID;
```

### 8.2 Find mobile client types
```sql
SELECT  ClientTypeID,
        ClientTypeName
FROM    Dictionary.ClientType WITH (NOLOCK)
WHERE   ClientTypeName IN ('Android', 'iPhone', 'OpenBook Mobile')
ORDER BY ClientTypeID;
```

### 8.3 Find social trading client types
```sql
SELECT  ClientTypeID,
        ClientTypeName
FROM    Dictionary.ClientType WITH (NOLOCK)
WHERE   ClientTypeName LIKE '%OpenBook%'
     OR ClientTypeName = 'CopyMe'
ORDER BY ClientTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ClientType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ClientType.sql*
