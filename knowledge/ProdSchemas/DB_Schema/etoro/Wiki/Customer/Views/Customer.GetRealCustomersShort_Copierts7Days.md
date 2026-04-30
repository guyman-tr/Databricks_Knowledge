# Customer.GetRealCustomersShort_Copierts7Days

> Minimal view exposing the 7-day change in copier count for every customer - identifies Popular Investors whose follower count is growing or shrinking over the past week.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | GCID |
| **Partition** | N/A |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Customer.GetRealCustomersShort_Copierts7Days is a focused 4-column view that computes a single metric: how much has each customer's copier count changed over the past 7 days. It is the 7-day companion to Customer.GetRealCustomersShort_Copierts24H (24-hour change). Both are used by email marketing systems to target Popular Investors based on the trend of their CopyTrader follower base.

The view joins every customer from Customer.Customer to two snapshots from etoroGeneral.dbo.Copiers_DATA: the most recent 24 hours (current count) and 7-8 days ago (prior week count). The difference yields the weekly change. As with the 24H view, no IsReal=1 filter is applied in the DDL despite the "RealCustomers" naming convention.

The name contains a typo: "Copierts" instead of "Copiers" - consistent with its 24H counterpart.

---

## 2. Business Logic

### 2.1 Copier Count 7-Day Change Calculation

**What**: Computes the net change in the number of customers copying this Popular Investor over the past 7 days.

**Columns/Parameters Involved**: `ChangeInNumberOfCopiersInPast7Days`

**Rules**:
- `NumOfCopiers`: snapshot from etoroGeneral.dbo.Copiers_DATA WHERE DateModified BETWEEN DATEADD(d,-1,GETDATE()) AND GETDATE()
- `B4_7_DaysNumOfCopiers`: snapshot WHERE DateModified BETWEEN DATEADD(d,-8,GETDATE()) AND DATEADD(d,-7,GETDATE())
- Change = ISNULL(current, 0) - ISNULL(7d-prior, 0)
- Positive = net growth over the week; Negative = net decline; 0 = stable or no copier data
- For non-Popular Investors: both snapshots are NULL, change = 0

**Diagram**:
```
current (last 24h)  - 7d-prior (7-8 days ago)  = ChangeInNumberOfCopiersInPast7Days
500 copiers         - 450 copiers               = +50 (weekly growth)
200 copiers         - 250 copiers               = -50 (weekly decline)
0 (no data)         - 0 (no data)               = 0 (not a PI)
```

### 2.2 CID vs GCID Identity Pattern

**What**: CID is suppressed when GCID is available; DemoCID hardcoded to 0 for real account context.

**Columns/Parameters Involved**: `GCID`, `CID`, `DemoCID`

**Rules**:
- `CID` = CASE WHEN GCID <> 0 THEN 0 ELSE CID END
- `DemoCID` = hardcoded 0
- Identical pattern to GetRealCustomersShort_Copierts24H and other GetRealCustomersShort_* views

---

## 3. Data Overview

View not fully queryable (etoroGeneral.dbo.Copiers_DATA not accessible in this environment).

| GCID | CID | DemoCID | ChangeInNumberOfCopiersInPast7Days | Meaning |
|------|-----|---------|-------------------------------------|---------|
| (PI growing weekly) | 0 | 0 | +100 | Popular Investor with strong weekly follower growth - prime candidate for "rising star" campaign |
| (PI declining weekly) | 0 | 0 | -30 | Popular Investor losing followers week-over-week - retention or re-engagement target |
| (standard customer) | 0 | 0 | 0 | Non-Popular Investor or PI with stable following - no change |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | VERIFIED | Group Customer ID - cross-product identity key. From Customer.Customer (CustomerStatic). Primary join key for email marketing integration. NULL for very old pre-GCID accounts. |
| 2 | CID | int | NO | - | CODE-BACKED | Computed: CASE WHEN GCID <> 0 THEN 0 ELSE CID END. Actual CID only for legacy accounts without GCID; 0 for all modern accounts. |
| 3 | DemoCID | int | NO | - | CODE-BACKED | Always 0 (hardcoded). Field exists to maintain schema contract shared across GetRealCustomersShort_* views. |
| 4 | ChangeInNumberOfCopiersInPast7Days | int | NO | - | CODE-BACKED | Computed: ISNULL(copiers in last 24h, 0) - ISNULL(copiers 7-8 days ago, 0). Net change in CopyTrader follower count over the past week. Sourced from etoroGeneral.dbo.Copiers_DATA two time-window comparison. 0 for non-Popular Investors or missing snapshots. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID, CID | Customer.Customer | FROM (CCST alias) | Customer identity source |
| ChangeInNumberOfCopiersInPast7Days | etoroGeneral.dbo.Copiers_DATA | LEFT JOIN x2 (time windows) | Current count (last 24h) vs 7-8 days ago snapshot |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view in the SSDT repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRealCustomersShort_Copierts7Days (view)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
└── etoroGeneral.dbo.Copiers_DATA (table) [external DB, x2 time windows]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (base view) - customer identity |
| etoroGeneral.dbo.Copiers_DATA | Table (external DB) | LEFT JOIN x2 - copier count snapshots (last 24h and 7-8 days ago) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| etoroGeneral cross-DB | External dependency | Requires linked server access to etoroGeneral database |
| No IsReal filter | Note | Despite name "RealCustomers", all customers from Customer.Customer are included - no IsReal=1 filter |

---

## 8. Sample Queries

### 8.1 Popular Investors with strong weekly growth
```sql
SELECT
    GCID,
    CID,
    ChangeInNumberOfCopiersInPast7Days
FROM Customer.GetRealCustomersShort_Copierts7Days WITH (NOLOCK)
WHERE ChangeInNumberOfCopiersInPast7Days > 0
ORDER BY ChangeInNumberOfCopiersInPast7Days DESC;
```

### 8.2 Combined 24h and 7-day trends for Popular Investors
```sql
SELECT
    h24.GCID,
    h24.ChangeInNumberOfCopiersInPast24Hours,
    h7.ChangeInNumberOfCopiersInPast7Days
FROM Customer.GetRealCustomersShort_Copierts24H h24 WITH (NOLOCK)
JOIN Customer.GetRealCustomersShort_Copierts7Days h7 WITH (NOLOCK)
    ON h24.GCID = h7.GCID
WHERE h7.ChangeInNumberOfCopiersInPast7Days <> 0
ORDER BY h7.ChangeInNumberOfCopiersInPast7Days DESC;
```

### 8.3 Full profile of declining Popular Investors for retention
```sql
SELECT
    c.GCID,
    cs.UserName,
    cs.Email,
    c.ChangeInNumberOfCopiersInPast7Days
FROM Customer.GetRealCustomersShort_Copierts7Days c WITH (NOLOCK)
JOIN Customer.Customer cs WITH (NOLOCK) ON cs.GCID = c.GCID
WHERE c.ChangeInNumberOfCopiersInPast7Days < -20
ORDER BY c.ChangeInNumberOfCopiersInPast7Days ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 10/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view, no consumers) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetRealCustomersShort_Copierts7Days | Type: View | Source: etoro/etoro/Customer/Views/Customer.GetRealCustomersShort_Copierts7Days.sql*
