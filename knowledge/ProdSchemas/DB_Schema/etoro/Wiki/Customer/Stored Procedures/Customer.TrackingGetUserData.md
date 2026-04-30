# Customer.TrackingGetUserData

> Batch lookup of customer identity and tracking identifiers: given a set of CIDs (TVP), returns CID, UserName, Email, PlatformID, AppsFlyerId, GCID, and FirebaseAppInstanceId for tracking/analytics event enrichment.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CIDs dbo.Typ_CID READONLY - TVP of CIDs to look up |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.TrackingGetUserData` is the data-enrichment endpoint for the tracking/analytics pipeline. When the system needs to enrich tracking events with customer identity information (email, username) and attribution data (AppsFlyer ID, Firebase Instance ID), this procedure provides a single batched lookup.

Created January 2021 (Ran Ovadia) as part of the tracking events infrastructure. Updated April 2021 to add GCID. Updated November 2022 (Guy Shahaf) to add Firebase User ID. The procedure reads from `Customer.CustomerStatic` (the real customer table) and `Customer.TrackingId` for attribution identifiers:
- TrackingID=1 = AppsFlyer mobile attribution ID.
- TrackingID=3 = Firebase App Instance ID (for push notifications).

The TrackingID=2 (UserUniqueIdentifierCookie) is not returned - it's for server-side cookie tracking and not needed in the analytics enrichment flow.

---

## 2. Business Logic

### 2.1 Batch Customer + Tracking ID Lookup

**What**: Retrieves identity and attribution data for a batch of CIDs.

**Columns/Parameters Involved**: `@CIDs` (TVP), `Customer.CustomerStatic`, `Customer.TrackingId`

**Rules**:
- INNER JOIN `Customer.CustomerStatic` on CID to get UserName, Email, PlatformID, GCID.
- LEFT JOIN `Customer.TrackingId` WHERE TrackingID=1 -> AppsFlyerId (NULL if not registered).
- LEFT JOIN `Customer.TrackingId` WHERE TrackingID=3 -> FirebaseAppInstanceId (NULL if not registered).
- All JOINs use NOLOCK.
- Returns one row per input CID (INNER JOIN on CustomerStatic - customers not in CustomerStatic are excluded).

```
@CIDs (TVP)
  -> INNER JOIN Customer.CustomerStatic (CID match)
  -> LEFT JOIN Customer.TrackingId (TrackingID=1) -> AppsFlyerId
  -> LEFT JOIN Customer.TrackingId (TrackingID=3) -> FirebaseAppInstanceId
Returns: CID, UserName, Email, PlatformID, AppsFlyerId, GCID, FirebaseAppInstanceId
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CIDs | dbo.Typ_CID | NO | - | CODE-BACKED | Table-valued parameter of CID values (dbo.Typ_CID type). READONLY. The set of customers to look up. |

**Returned Columns:**

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | CID | Customer.CustomerStatic.CID | Internal customer ID |
| 2 | UserName | Customer.CustomerStatic.UserName | Customer's login username |
| 3 | Email | Customer.CustomerStatic.Email | Customer's email address |
| 4 | PlatformID | Customer.CustomerStatic.PlatformID | Platform/application the customer registered on |
| 5 | AppsFlyerId | Customer.TrackingId.TrackingValue (TrackingID=1) | AppsFlyer mobile attribution ID; NULL if not set |
| 6 | GCID | Customer.CustomerStatic.GCID | Global Customer ID |
| 7 | FirebaseAppInstanceId | Customer.TrackingId.TrackingValue (TrackingID=3) | Firebase push notification instance ID; NULL if not set |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CIDs | dbo.Typ_CID | Parameter type | TVP type definition (dbo schema) |
| (identity) | Customer.CustomerStatic | READ (NOLOCK) | INNER JOIN - CID match for identity fields |
| TrackingID=1 | Customer.TrackingId | READ (NOLOCK) | LEFT JOIN - AppsFlyer attribution ID |
| TrackingID=3 | Customer.TrackingId | READ (NOLOCK) | LEFT JOIN - Firebase App Instance ID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tracking event service | External call | Caller | Enriches analytics events with customer identity + attribution data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.TrackingGetUserData (procedure)
├── dbo.Typ_CID (UDT) [PARAMETER TYPE - TVP definition]
├── Customer.CustomerStatic (table) [READ NOLOCK - identity fields]
└── Customer.TrackingId (table) [READ NOLOCK x2 - TrackingID 1 + 3]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Typ_CID | User Defined Type | TVP parameter type |
| Customer.CustomerStatic | Table | READ - UserName, Email, PlatformID, GCID |
| Customer.TrackingId | Table | READ (twice) - AppsFlyerId (TrackingID=1), FirebaseAppInstanceId (TrackingID=3) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tracking event service | External | Enriches events with customer data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN on CustomerStatic | Application | Customers not in CustomerStatic (demo accounts?) are excluded |
| TrackingID=2 excluded | Design | Cookie-based tracking ID is not returned in this endpoint |
| NOLOCK everywhere | Performance | All reads are dirty-read safe for analytics purposes |

---

## 8. Sample Queries

### 8.1 Get tracking data for a set of customers

```sql
DECLARE @CIDs dbo.Typ_CID
INSERT INTO @CIDs VALUES (12345), (67890)

EXEC Customer.TrackingGetUserData @CIDs
```

### 8.2 Check tracking IDs by type

```sql
SELECT
    ti.CID,
    CASE ti.TrackingID
        WHEN 1 THEN 'AppsFlyer'
        WHEN 2 THEN 'Cookie'
        WHEN 3 THEN 'Firebase'
    END AS TrackingType,
    ti.TrackingValue
FROM Customer.TrackingId ti WITH (NOLOCK)
WHERE ti.CID IN (12345, 67890)
ORDER BY ti.CID, ti.TrackingID
```

### 8.3 Find customers with Firebase IDs (eligible for push notifications)

```sql
SELECT COUNT(DISTINCT ti.CID) AS CustomersWithFirebase
FROM Customer.TrackingId ti WITH (NOLOCK)
WHERE ti.TrackingID = 3
  AND ti.TrackingValue IS NOT NULL
  AND ti.TrackingValue != ''
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.TrackingGetUserData | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.TrackingGetUserData.sql*
