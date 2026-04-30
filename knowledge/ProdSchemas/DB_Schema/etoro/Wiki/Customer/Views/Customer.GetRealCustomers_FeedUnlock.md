# Customer.GetRealCustomers_FeedUnlock

> Targeted view exposing the FeedUnlocked setting for customers who have a record in etoroGeneral.Customer.Settings - used to identify customers eligible for or opted into the OpenBook social feed.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | GCID |
| **Partition** | N/A |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Customer.GetRealCustomers_FeedUnlock returns customers who have a settings record in etoroGeneral.Customer.Settings and exposes their FeedUnlocked flag. The FeedUnlocked setting controls whether a customer's OpenBook social feed is activated - customers must either meet certain trading criteria or explicitly unlock their feed.

The INNER JOIN to etoroGeneral.Customer.Settings means only customers who have been written to that external settings store appear in this view. This makes it a "settings-registered" customer view, not a full customer list. Customers without a settings record in etoroGeneral are excluded.

This view was used by email marketing to segment customers based on their feed unlock status for campaigns like "unlock your feed" conversion emails or confirmation emails for customers who just unlocked.

---

## 2. Business Logic

### 2.1 FeedUnlocked Status

**What**: FeedUnlocked is a boolean flag from etoroGeneral.Customer.Settings indicating whether the customer's OpenBook social feed has been activated.

**Columns/Parameters Involved**: `FeedUnlocked`

**Rules**:
- Sourced from etoroGeneral.Customer.Settings.FeedUnlocked
- INNER JOIN means only customers WITH a settings record in etoroGeneral appear
- FeedUnlocked=1: customer's OpenBook feed is active; they can post, follow, and be followed
- FeedUnlocked=0: customer has not yet unlocked their feed; may need to meet minimum trading activity requirements

---

## 3. Data Overview

Not queryable in this environment (etoroGeneral not accessible).

| GCID | CID | DemoCID | FeedUnlocked | Meaning |
|------|-----|---------|--------------|---------|
| (active PI) | 0 | 0 | 1 | Customer whose OpenBook feed is active. Eligible for social engagement campaigns. |
| (new trader) | 0 | 0 | 0 | Customer registered in settings but feed not yet unlocked. Target for "unlock your feed" conversion campaign. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | VERIFIED | Group Customer ID - cross-product identity key. From Customer.Customer (CustomerStatic). Primary identifier for email marketing integration. |
| 2 | CID | int | NO | - | CODE-BACKED | Computed: CASE WHEN GCID <> 0 THEN 0 ELSE CID END. Returns actual CID only for pre-GCID accounts; 0 for modern accounts. |
| 3 | DemoCID | int | NO | - | CODE-BACKED | Always 0 (hardcoded). Schema contract field for GetRealCustomersShort_* family. |
| 4 | FeedUnlocked | bit/int | YES | - | CODE-BACKED | From etoroGeneral.Customer.Settings.FeedUnlocked. 1=customer's OpenBook social feed is active and visible to others; 0=feed not yet unlocked (typically requires minimum trading activity). Used to segment "unlock your feed" email campaigns. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID, CID | Customer.Customer | FROM (CCST alias) | Customer identity source |
| FeedUnlocked | etoroGeneral.Customer.Settings | INNER JOIN on CID | Feed unlock status from external settings store |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view in the SSDT repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRealCustomers_FeedUnlock (view)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
└── etoroGeneral.Customer.Settings (table) [external DB]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (base view) - customer identity |
| etoroGeneral.Customer.Settings | Table (external DB) | INNER JOIN on CID - FeedUnlocked flag + customer filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN to etoroGeneral.Customer.Settings | Data filter | Only customers with a settings record in etoroGeneral appear |
| etoroGeneral cross-DB | External dependency | Requires linked server access to etoroGeneral database |

---

## 8. Sample Queries

### 8.1 Customers with feed not yet unlocked (conversion campaign targets)
```sql
SELECT GCID, CID, FeedUnlocked
FROM Customer.GetRealCustomers_FeedUnlock WITH (NOLOCK)
WHERE FeedUnlocked = 0;
```

### 8.2 All customers with unlocked feeds
```sql
SELECT GCID, CID, FeedUnlocked
FROM Customer.GetRealCustomers_FeedUnlock WITH (NOLOCK)
WHERE FeedUnlocked = 1;
```

### 8.3 Full profile of non-unlocked customers for re-engagement
```sql
SELECT
    fu.GCID,
    c.UserName,
    c.Email,
    c.LanguageID,
    fu.FeedUnlocked
FROM Customer.GetRealCustomers_FeedUnlock fu WITH (NOLOCK)
JOIN Customer.Customer c WITH (NOLOCK) ON c.GCID = fu.GCID
WHERE fu.FeedUnlocked = 0
  AND c.IsReal = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.0/10, Logic: 5.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetRealCustomers_FeedUnlock | Type: View | Source: etoro/etoro/Customer/Views/Customer.GetRealCustomers_FeedUnlock.sql*
