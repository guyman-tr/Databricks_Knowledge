# Customer.GetRealCustomersShort_FB_Connection

> OpenBook social activity view: exposes the number of public posts and comments received by each customer's OpenBook (KickApps social platform) profile in the past 24 hours - used to measure social engagement for email campaign targeting.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | GCID |
| **Partition** | N/A |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Customer.GetRealCustomersShort_FB_Connection provides a 24-hour social engagement snapshot for each customer on the eToro OpenBook platform, which was built on KickApps (a third-party social platform). Despite the "FB_Connection" name, this view is about OpenBook/KickApps activity (public posts and comments TO a user's profile), not Facebook OAuth connections - the name reflects a historical naming convention where "FB" referred to the social feed/social connection feature broadly.

The view joins Customer.Customer to dbo.OpenBook_eToroKickApps (which maps eToro CIDs to KickApps UserIDs) and then counts posts and comments directed at each customer's OpenBook profile in the last 24 hours. Customers with no KickApps profile or no activity return 0 for both counts via ISNULL. All rows from Customer.Customer are returned (LEFT JOINs throughout).

This was used by email marketing to target customers with high social activity (many followers posting to their page) or to identify customers who may be growing Popular Investors based on social engagement signals.

---

## 2. Business Logic

### 2.1 24-Hour Social Activity Counting

**What**: Posts and comments are counted only from the last 24 hours, making this a rolling time-window view.

**Columns/Parameters Involved**: `NumPosts_24Hours`, `NumComments_24Hours`

**Rules**:
- Posts: dbo.OpenBook_PublicMessages WHERE PublishDate >= DATEADD(dd,-1,GETDATE()) AND ToUserID <> FromUserID (self-posts excluded)
- Comments: dbo.OpenBook_Comments WHERE CommentDate >= DATEADD(dd,-1,GETDATE()) AND ToUserID <> FromUserID (self-comments excluded)
- Both use KickAppsUserID from dbo.OpenBook_eToroKickApps as the join key (not eToro CID directly)
- ISNULL 0 for customers with no activity or no KickApps profile
- The ToUserID <> FromUserID filter excludes self-posts/self-comments to measure only INCOMING engagement

---

## 3. Data Overview

Not fully queryable in this environment (dbo.OpenBook_* tables are cross-schema and may not be accessible).

| GCID | CID | DemoCID | NumPosts_24Hours | NumComments_24Hours | Meaning |
|------|-----|---------|-----------------|---------------------|---------|
| (active PI) | 0 | 0 | 15 | 8 | Popular Investor whose OpenBook profile received 15 posts and 8 comments from followers in the last 24h - high engagement signal |
| (standard customer) | 0 | 0 | 0 | 0 | Customer with no OpenBook activity or no KickApps profile |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | VERIFIED | Group Customer ID - cross-product identity key. From Customer.Customer (CustomerStatic). Primary identifier for email marketing integration. |
| 2 | CID | int | NO | - | CODE-BACKED | Computed: CASE WHEN GCID <> 0 THEN 0 ELSE CID END. Returns actual CID only for pre-GCID accounts; 0 for modern accounts. |
| 3 | DemoCID | int | NO | - | CODE-BACKED | Always 0 (hardcoded). Schema contract field shared across GetRealCustomersShort_* views. |
| 4 | NumPosts_24Hours | int | NO | - | CODE-BACKED | Count of public posts TO this customer's OpenBook KickApps profile in the last 24 hours (excluding self-posts: ToUserID <> FromUserID). 0 for customers with no KickApps profile or no incoming posts. |
| 5 | NumComments_24Hours | int | NO | - | CODE-BACKED | Count of comments TO this customer's OpenBook KickApps profile in the last 24 hours (excluding self-comments). 0 for customers with no KickApps profile or no incoming comments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID, CID | Customer.Customer | FROM (CCST alias) | Customer identity source |
| NumPosts_24Hours, NumComments_24Hours | dbo.OpenBook_eToroKickApps | LEFT JOIN on CID | Maps eToro CID to KickApps UserID |
| NumPosts_24Hours | dbo.OpenBook_PublicMessages | LEFT JOIN subquery on KickAppsUserID | 24h incoming posts count |
| NumComments_24Hours | dbo.OpenBook_Comments | LEFT JOIN subquery on KickAppsUserID | 24h incoming comments count |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view in the SSDT repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRealCustomersShort_FB_Connection (view)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
├── dbo.OpenBook_eToroKickApps (table) [cross-schema]
├── dbo.OpenBook_PublicMessages (table) [cross-schema]
└── dbo.OpenBook_Comments (table) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (base view) - customer identity |
| dbo.OpenBook_eToroKickApps | Table (cross-schema) | LEFT JOIN - CID to KickAppsUserID mapping |
| dbo.OpenBook_PublicMessages | Table (cross-schema) | LEFT JOIN subquery - 24h post count per KickAppsUserID |
| dbo.OpenBook_Comments | Table (cross-schema) | LEFT JOIN subquery - 24h comment count per KickAppsUserID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No IsReal filter | Note | Despite "RealCustomers" name, all customers are included |
| ToUserID <> FromUserID | Self-activity exclusion | Only INCOMING posts/comments counted, not self-authored content |

---

## 8. Sample Queries

### 8.1 Customers with highest social engagement in last 24 hours
```sql
SELECT
    GCID,
    NumPosts_24Hours,
    NumComments_24Hours,
    NumPosts_24Hours + NumComments_24Hours AS TotalEngagement
FROM Customer.GetRealCustomersShort_FB_Connection WITH (NOLOCK)
WHERE NumPosts_24Hours + NumComments_24Hours > 0
ORDER BY TotalEngagement DESC;
```

### 8.2 Full profile of top OpenBook influencers
```sql
SELECT
    fb.GCID,
    c.UserName,
    c.Email,
    fb.NumPosts_24Hours,
    fb.NumComments_24Hours
FROM Customer.GetRealCustomersShort_FB_Connection fb WITH (NOLOCK)
JOIN Customer.Customer c WITH (NOLOCK) ON c.GCID = fb.GCID
WHERE fb.NumPosts_24Hours > 5
ORDER BY fb.NumPosts_24Hours DESC;
```

### 8.3 Customers with no social engagement (dormant OpenBook profiles)
```sql
SELECT COUNT(*) AS DormantCustomers
FROM Customer.GetRealCustomersShort_FB_Connection WITH (NOLOCK)
WHERE NumPosts_24Hours = 0
  AND NumComments_24Hours = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetRealCustomersShort_FB_Connection | Type: View | Source: etoro/etoro/Customer/Views/Customer.GetRealCustomersShort_FB_Connection.sql*
