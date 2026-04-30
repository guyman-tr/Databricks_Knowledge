# Customer.GetRealCustomersShort_FB

> Minimal view filtering to customers who have connected their Facebook account to eToro - returns one row per Facebook-connected customer with a hardcoded FacebookConnect=1 flag.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | GCID |
| **Partition** | N/A |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Customer.GetRealCustomersShort_FB filters Customer.Customer to return only customers who have linked their Facebook account to eToro. The link is detected via Customer.PrivacyUniqueIdentity WHERE PrivacyRecipientID=2 (Facebook). Only customers with a Facebook OAuth connection stored in PrivacyUniqueIdentity appear in this view.

The view is used by email marketing systems to segment Facebook-connected customers for social-platform-specific campaigns (e.g., "share your eToro portfolio on Facebook" CTAs, or re-engagement through Facebook channels).

The LEFT JOIN combined with a WHERE IS NOT NULL is functionally equivalent to an INNER JOIN - only customers WITH a Facebook connection appear. The FacebookConnect CASE expression is always 1 for all returned rows (making it redundant given the filter), likely a legacy design preserved for schema contract consistency with other GetRealCustomersShort_* views.

---

## 2. Business Logic

### 2.1 Facebook Connection Filter (PrivacyRecipientID=2)

**What**: The view uses Customer.PrivacyUniqueIdentity with PrivacyRecipientID=2 to identify Facebook-connected customers.

**Columns/Parameters Involved**: `FacebookConnect`

**Rules**:
- PrivacyRecipientID=2 = Facebook (per Customer.PrivacyUniqueIdentity value map)
- LEFT JOIN + WHERE IS NOT NULL = only Facebook-connected customers returned
- FacebookConnect is always 1 for all rows (the WHERE clause ensures the LEFT JOIN always finds a match)
- See Customer.PrivacyUniqueIdentity for full PrivacyRecipientID value map

---

## 3. Data Overview

0 rows in this environment (Customer.PrivacyUniqueIdentity is empty - social integration not active in this environment).

| GCID | CID | DemoCID | FacebookConnect | Meaning |
|------|-----|---------|-----------------|---------|
| (Facebook user) | 0 | 0 | 1 | Customer who has authenticated eToro using their Facebook OAuth credentials. Targeted for Facebook-specific marketing campaigns. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | VERIFIED | Group Customer ID - cross-product identity key. From Customer.Customer (CustomerStatic). Primary identifier used by email marketing integration. |
| 2 | CID | int | NO | - | CODE-BACKED | Computed: CASE WHEN GCID <> 0 THEN 0 ELSE CID END. Returns actual CID only for pre-GCID accounts; 0 for modern accounts. |
| 3 | DemoCID | int | NO | - | CODE-BACKED | Always 0 (hardcoded). Exists for schema contract consistency across GetRealCustomersShort_* views. |
| 4 | FacebookConnect | int | NO | - | CODE-BACKED | Computed: CASE WHEN PrivacyUniqueIdentity.CID IS NULL THEN 0 ELSE 1 END. Always 1 for all rows in this view (the WHERE clause filters out all NULLs). Indicates customer has an active Facebook OAuth connection stored in Customer.PrivacyUniqueIdentity (PrivacyRecipientID=2). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID, CID | Customer.Customer | FROM (CCST alias) | Customer identity source |
| FacebookConnect | Customer.PrivacyUniqueIdentity | LEFT JOIN on CID WHERE PrivacyRecipientID=2 | Facebook OAuth connection lookup |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view in the SSDT repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRealCustomersShort_FB (view)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
└── Customer.PrivacyUniqueIdentity (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (base view) - customer identity |
| Customer.PrivacyUniqueIdentity | Table | LEFT JOIN on CID WHERE PrivacyRecipientID=2 - Facebook connection filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WHERE PrivacyUniqueIdentity.CID IS NOT NULL | Implicit INNER JOIN | Only Facebook-connected customers returned; non-connected customers excluded |

---

## 8. Sample Queries

### 8.1 All Facebook-connected customers
```sql
SELECT GCID, CID, FacebookConnect
FROM Customer.GetRealCustomersShort_FB WITH (NOLOCK);
```

### 8.2 Facebook-connected customers with full profile
```sql
SELECT
    fb.GCID,
    c.UserName,
    c.Email,
    c.LanguageID,
    c.CountryID,
    fb.FacebookConnect
FROM Customer.GetRealCustomersShort_FB fb WITH (NOLOCK)
JOIN Customer.Customer c WITH (NOLOCK) ON c.GCID = fb.GCID;
```

### 8.3 Count of Facebook-connected real customers
```sql
SELECT COUNT(*) AS FacebookConnectedCustomers
FROM Customer.GetRealCustomersShort_FB WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetRealCustomersShort_FB | Type: View | Source: etoro/etoro/Customer/Views/Customer.GetRealCustomersShort_FB.sql*
