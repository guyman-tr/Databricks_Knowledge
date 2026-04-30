# Dictionary.Tracking

> Maps tracking device identifier types for mobile attribution and analytics (AppsFlyer, Firebase).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AppsFlyerDeviceID (int, PK) |
| **Row Count** | 3 |
| **Indexes** | 1 (clustered PK, FILLFACTOR 95, PAGE compression) |

---

## 1. Business Meaning

### What It Is
Dictionary.Tracking is a small lookup table defining the types of mobile device tracking identifiers used for attribution and analytics. It maps numeric IDs to the name of each tracking cookie/identifier type.

### Why It Exists
The platform tracks user acquisition through multiple mobile attribution channels (AppsFlyer for install attribution, browser cookies for web tracking, Firebase for Android analytics). This table provides the canonical list of tracking identifier types, enabling the attribution system to distinguish which type of device identifier is being stored for each user.

### How It Works
Each row maps a numeric ID to a tracking identifier type name. The `UserUniqueIdentifierCookie` column acts as the label (despite the column name, it's really the identifier type name). The table uses PAGE compression due to its small size, and the PK column is named `AppsFlyerDeviceID` reflecting its origin in mobile attribution, even though it now covers non-AppsFlyer identifiers too.

---

## 2. Business Logic

### Value Map (Complete — 3 rows)

| AppsFlyerDeviceID | UserUniqueIdentifierCookie | Business Meaning |
|-------------------|---------------------------|------------------|
| 1 | AppsFlyerDeviceID | AppsFlyer mobile device identifier — tracks app installs and in-app events |
| 2 | UserUniqueIdentifierCookie | Browser/web unique identifier cookie — tracks web user sessions |
| 3 | FirebaseAppInstanceId | Firebase app instance ID — Google Analytics for Android apps |

---

## 3. Data Overview

| AppsFlyerDeviceID | UserUniqueIdentifierCookie | Scenario |
|-------------------|---------------------------|----------|
| 1 | AppsFlyerDeviceID | Mobile app user tracked for install attribution |
| 2 | UserUniqueIdentifierCookie | Web browser user tracked via cookie |
| 3 | FirebaseAppInstanceId | Android user tracked via Firebase analytics |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AppsFlyerDeviceID | int | NO | — | HIGH | Primary key identifying the tracking identifier type. `1`=AppsFlyer, `2`=Cookie, `3`=Firebase. Named for historical reasons (originally AppsFlyer-only). |
| 2 | UserUniqueIdentifierCookie | varchar(50) | YES | — | HIGH | Name/label of the tracking identifier type. Describes the source system for the device identifier. |

---

## 5. Relationships

### Referenced By

No SQL procedure or table references found in SSDT — this table is likely consumed by application-layer code for mobile attribution and analytics.

---

## 6. Dependencies

### Depends On
None — leaf dictionary table with no foreign keys.

### Depended On By
- Application-layer mobile attribution and analytics systems

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_Dictionary_Tracking | CLUSTERED PK | AppsFlyerDeviceID ASC | FILLFACTOR 95, PAGE compression |

---

## 8. Sample Queries

```sql
-- Get all tracking identifier types
SELECT  AppsFlyerDeviceID AS TrackingTypeID,
        UserUniqueIdentifierCookie AS IdentifierType
FROM    Dictionary.Tracking WITH (NOLOCK)
ORDER BY AppsFlyerDeviceID;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `Dictionary.Tracking`.

---

*Generated: 2026-03-14 | Quality: 9.0/10*
*Object: Dictionary.Tracking | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Tracking.sql*
