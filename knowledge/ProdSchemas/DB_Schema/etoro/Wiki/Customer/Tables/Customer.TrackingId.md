# Customer.TrackingId

> Marketing and analytics tracking identifiers per customer: stores AppsFlyer device IDs, user unique identifier cookies, and Firebase app instance IDs used for attribution and push notification routing.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | (CID, TrackingID) composite PK |
| **Partition** | No (MAIN filegroup, FILLFACTOR=95, PAGE compression) |
| **Indexes** | 2 (clustered PK + NC on TrackingID+CID INCLUDE TrackingValue) |

---

## 1. Business Meaning

Customer.TrackingId stores external tracking identifiers that link eToro customer accounts to their corresponding identities in third-party analytics and marketing platforms. Each row represents one tracking identifier type for one customer. The three types tracked are: AppsFlyer device ID (mobile attribution), UserUniqueIdentifierCookie (web cookie-based identity), and Firebase App Instance ID (mobile push notification routing).

These identifiers are used to: (1) attribute customer registrations and actions to specific marketing campaigns in AppsFlyer; (2) identify returning web visitors via cookie before they log in; (3) route push notifications to specific mobile app instances via Firebase. The composite PK (CID, TrackingID) allows at most one value per customer per tracking type.

Data flows: Customer.TrackingGetUserData (created 2021-2022) reads AppsFlyer and Firebase IDs for batches of CIDs, used by the tracking event pipeline. Customer.InsertRealCustomer and Customer.RegisterReal likely write to this table during account creation. The dictionary for TrackingID values is Dictionary.Tracking (though the column is named AppsFlyerDeviceID in that table - a naming inconsistency from the table's origin).

---

## 2. Business Logic

### 2.1 Three-Type Tracking Identity System

**What**: Three distinct external tracking identifier types are stored with the same table structure, differentiated by TrackingID.

**Columns/Parameters Involved**: `TrackingID`, `TrackingValue`

**Rules**:
- TrackingID=1 (AppsFlyerDeviceID): The AppsFlyer device ID for mobile attribution. TrackingGetUserData aliases this as `AppsFlyerId`. Used to link customer conversions to AppsFlyer campaigns.
- TrackingID=2 (UserUniqueIdentifierCookie): Browser cookie-based unique identifier. Used to track anonymous web visitors before they register/log in.
- TrackingID=3 (FirebaseAppInstanceId): Firebase app instance ID for push notification delivery. TrackingGetUserData aliases this as `FirebaseAppInstanceId`. Required for targeted push notifications on iOS/Android.
- One row per (CID, TrackingID) pair - a customer has at most one value per tracking type

---

## 3. Data Overview

| TrackingID | Type Name | Row Count | Meaning |
|-----------|-----------|-----------|---------|
| 1 | AppsFlyerDeviceID | 4,752 | Mobile customers with AppsFlyer attribution ID |
| 2 | UserUniqueIdentifierCookie | 3,671 | Customers with web cookie identity tracking |
| 3 | FirebaseAppInstanceId | 3,154 | Mobile customers with Firebase push notification routing |

*11,577 total rows. Even distribution across 3 types suggests coordinated enrollment at registration. TrackingValue is varchar(300) - AppsFlyer IDs and Firebase IDs are typically 36-128 char strings.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer identifier. Part of composite PK. References Customer.CustomerStatic (no FK enforced). |
| 2 | GCID | int | NO | - | CODE-BACKED | Group Customer ID - the cross-product identity. Stored alongside CID for data lake and analytics queries that work at the GCID level. |
| 3 | TrackingID | int | NO | - | VERIFIED | Type of tracking identifier. Implicit FK to Dictionary.Tracking. Values: 1=AppsFlyerDeviceID, 2=UserUniqueIdentifierCookie, 3=FirebaseAppInstanceId. Part of composite PK and the secondary NC index. |
| 4 | TrackingValue | varchar(300) | YES | - | VERIFIED | The actual identifier value from the external platform. For TrackingID=1: the AppsFlyer device ID string. For TrackingID=2: the browser cookie unique ID. For TrackingID=3: the Firebase app instance ID. Included in the NC index (Idx_Customer_TrackingId_TrackingID_CID) for covering-index lookups by tracking type. |
| 5 | Occurred | datetime | YES | getutcdate() | CODE-BACKED | UTC timestamp when this tracking identifier was recorded. Defaults to getutcdate() at INSERT. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit (no FK) | Every tracking record belongs to a registered customer |
| TrackingID | Dictionary.Tracking | Implicit (no FK) | Type of tracking identifier (1=AppsFlyer, 2=Cookie, 3=Firebase) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.TrackingGetUserData | CID, TrackingID | Reader | Returns AppsFlyer and Firebase IDs for a batch of CIDs for analytics tracking events |
| Customer.InsertRealCustomer | CID, TrackingID | Writer (likely) | Writes tracking IDs during real customer registration |
| Customer.RegisterReal | CID, TrackingID | Writer (likely) | Writes tracking IDs during real registration flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.TrackingId (table)
```
Tables are leaf nodes - no code-level FROM/JOIN dependencies in CREATE TABLE.

---

### 6.1 Objects This Depends On

No formal dependencies (no FK constraints).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.TrackingGetUserData | Stored Procedure | Reader - fetches AppsFlyer and Firebase IDs for tracking events |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Customer_TrackingId | Clustered PK | CID ASC, TrackingID ASC | - | - | Active |
| Idx_Customer_TrackingId_TrackingID_CID | NC (PAGE compressed) | TrackingID ASC, CID ASC | TrackingValue | - | Active |

*The NC index reverses the PK order (TrackingID first) to support queries filtering by tracking type across all customers. The INCLUDE of TrackingValue makes it a covering index for TrackingGetUserData.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_Customer_TrackingId_Occurred | DEFAULT | Occurred = getutcdate() |

---

## 8. Sample Queries

### 8.1 Get all tracking identifiers for a specific customer
```sql
SELECT
    ti.CID,
    ti.TrackingID,
    ti.TrackingValue,
    ti.Occurred
FROM Customer.TrackingId ti WITH (NOLOCK)
WHERE ti.CID = 12345
ORDER BY ti.TrackingID;
```

### 8.2 Get AppsFlyer and Firebase IDs for multiple customers (mirrors TrackingGetUserData)
```sql
SELECT
    cs.CID,
    cs.UserName,
    cs.GCID,
    af.TrackingValue AS AppsFlyerId,
    fb.TrackingValue AS FirebaseAppInstanceId
FROM Customer.CustomerStatic cs WITH (NOLOCK)
LEFT JOIN Customer.TrackingId af WITH (NOLOCK)
    ON af.CID = cs.CID AND af.TrackingID = 1
LEFT JOIN Customer.TrackingId fb WITH (NOLOCK)
    ON fb.CID = cs.CID AND fb.TrackingID = 3
WHERE cs.CID IN (12345, 67890, 11111);
```

### 8.3 Count customers by tracking type coverage
```sql
SELECT
    t.TrackingID,
    t.UserUniqueIdentifierCookie AS TrackingTypeName,
    COUNT(ti.CID) AS CustomersTracked
FROM Dictionary.Tracking t WITH (NOLOCK)
LEFT JOIN Customer.TrackingId ti WITH (NOLOCK) ON ti.TrackingID = t.AppsFlyerDeviceID
GROUP BY t.AppsFlyerDeviceID, t.UserUniqueIdentifierCookie
ORDER BY t.AppsFlyerDeviceID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (TrackingGetUserData) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.TrackingId | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.TrackingId.sql*
