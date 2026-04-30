# Customer.Get_LastLoginDateToCashier

> Rolling 24-hour view: returns customers who have logged into the eToro cashier (deposit/withdrawal portal) within the past day, with their most recent cashier login timestamp.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | GCID |
| **Partition** | N/A |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Customer.Get_LastLoginDateToCashier is a time-windowed view that returns the last cashier login timestamp for every customer who visited the eToro cashier (deposit/withdrawal portal) in the last 24 hours. The cashier is a separate system from the main trading platform; its login events are tracked in Billing.Login.

The view is time-dependent: its result set changes every moment as Billing.Login.LoggedIn timestamps age out of the 24-hour window. Customers who last logged into the cashier more than 24 hours ago do not appear. This makes it suitable for real-time "currently active" cashier sessions or very recent cashier visit follow-up campaigns.

The WHERE clause uses GETUTCDATE() (UTC time) while Billing.Login.LoggedIn presumably stores UTC timestamps - this is consistent, but developers should note that the 24-hour window is UTC-based, not local time.

---

## 2. Business Logic

### 2.1 24-Hour Rolling Window Filter

**What**: Only customers whose most recent cashier login is within the past 24 hours are returned.

**Columns/Parameters Involved**: `LastLoginDateToCashier`

**Rules**:
- `MAX(LoggedIn)` from Billing.Login grouped by CID gives the most recent cashier login per customer
- WHERE `LastLoginDateToCashier > DATEADD(d,-1,GETUTCDATE())` filters to the past 24 hours
- INNER JOIN (not LEFT) means customers with NO cashier login in last 24h are excluded
- Result set is completely different each time the view is queried due to the rolling window
- `LastLoginDateToCashier` is formatted as MM/DD/YYYY string (style 101), losing time precision

---

## 3. Data Overview

0 rows in this environment (no cashier logins in the last 24 hours - test/dev environment). In production, this view returns customers who most recently visited the cashier within the past day.

| GCID | CID | DemoCID | LastLoginDateToCashier | Meaning |
|------|-----|---------|------------------------|---------|
| (active depositor) | 0 | 0 | "03/17/2026" | Customer who logged into the deposit/withdrawal cashier today. Prime target for same-day follow-up deposit encouragement or cashier abandonment re-engagement. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | VERIFIED | Group Customer ID - cross-product identity key. From Customer.Customer (CustomerStatic). Primary identifier for real-time marketing integration. |
| 2 | CID | int | NO | - | CODE-BACKED | Computed: CASE WHEN GCID <> 0 THEN 0 ELSE CID END. Returns actual CID only for pre-GCID accounts; 0 for modern accounts. |
| 3 | DemoCID | int | NO | - | CODE-BACKED | Always 0 (hardcoded). Schema contract field for GetRealCustomersShort_* family views. |
| 4 | LastLoginDateToCashier | varchar(50) | NO | - | CODE-BACKED | Most recent cashier portal login date formatted as MM/DD/YYYY (CONVERT style 101). MAX(Billing.Login.LoggedIn) grouped by CID. Only populated for customers whose last cashier visit was within the past 24 hours (rolling window - result changes continuously). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID, CID | Customer.Customer | FROM (CCST alias) | Customer identity source |
| LastLoginDateToCashier | Billing.Login | INNER JOIN subquery (MAX LoggedIn per CID) | Most recent cashier login timestamp |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view in the SSDT repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.Get_LastLoginDateToCashier (view)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
└── Billing.Login (table) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (base view) - customer identity |
| Billing.Login | Table (cross-schema) | INNER JOIN subquery (MAX LoggedIn, 24h filter) - cashier login timestamp |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WHERE > DATEADD(d,-1,GETUTCDATE()) | Rolling time filter | Result changes continuously - only last-24h cashier visitors returned |
| INNER JOIN to Billing.Login | Implicit filter | Only customers with any cashier login (ever) and one within last 24h appear |
| CONVERT style 101 | Precision loss | Time component lost - only date retained in MM/DD/YYYY format |

---

## 8. Sample Queries

### 8.1 Customers who visited the cashier today
```sql
SELECT GCID, CID, LastLoginDateToCashier
FROM Customer.Get_LastLoginDateToCashier WITH (NOLOCK)
ORDER BY LastLoginDateToCashier DESC;
```

### 8.2 Full profile of recent cashier visitors for follow-up campaign
```sql
SELECT
    cl.GCID,
    c.UserName,
    c.Email,
    c.LanguageID,
    c.Credit,
    cl.LastLoginDateToCashier
FROM Customer.Get_LastLoginDateToCashier cl WITH (NOLOCK)
JOIN Customer.Customer c WITH (NOLOCK) ON c.GCID = cl.GCID
WHERE c.IsReal = 1
ORDER BY cl.LastLoginDateToCashier DESC;
```

### 8.3 Count of cashier visitors in the last 24 hours
```sql
SELECT COUNT(*) AS CashierVisitorsLast24H
FROM Customer.Get_LastLoginDateToCashier WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.Get_LastLoginDateToCashier | Type: View | Source: etoro/etoro/Customer/Views/Customer.Get_LastLoginDateToCashier.sql*
