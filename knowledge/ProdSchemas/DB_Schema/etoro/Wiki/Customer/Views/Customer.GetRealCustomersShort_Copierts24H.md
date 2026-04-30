# Customer.GetRealCustomersShort_Copierts24H

> Minimal view exposing the 24-hour change in copier count for every customer - identifies Popular Investors whose follower count is growing or shrinking over the past day.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | GCID |
| **Partition** | N/A |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Customer.GetRealCustomersShort_Copierts24H is a focused 4-column view that computes a single metric: how much has each customer's copier count changed in the past 24 hours. It is one of a pair (see also Customer.GetRealCustomersShort_Copierts7Days for the 7-day equivalent). Both views are used by email marketing systems to target Popular Investors based on the trajectory of their CopyTrader follower counts.

The view joins every customer record from Customer.Customer to two time-window snapshots from etoroGeneral.dbo.Copiers_DATA: one for the most recent 24 hours (current count) and one for 24-48 hours ago (prior count). The difference is the change metric. No IsReal filter is applied in the DDL - the "Real" in the name reflects intended usage context (real-money customers), not a WHERE clause.

The name contains a typo: "Copierts" instead of "Copiers". Despite the typo, the view is identified by its full name in all consumers.

---

## 2. Business Logic

### 2.1 Copier Count Change Calculation

**What**: Computes the net change in the number of customers copying this Popular Investor over the last 24 hours.

**Columns/Parameters Involved**: `ChangeInNumberOfCopiersInPast24Hours`

**Rules**:
- `NumOfCopiers`: snapshot from etoroGeneral.dbo.Copiers_DATA WHERE DateModified BETWEEN DATEADD(d,-1,GETDATE()) AND GETDATE()
- `B4_24_hoursNumOfCopiers`: snapshot WHERE DateModified BETWEEN DATEADD(d,-2,GETDATE()) AND DATEADD(d,-1,GETDATE())
- Change = ISNULL(current, 0) - ISNULL(prior, 0)
- Positive = gained copiers in last 24h; Negative = lost copiers; 0 = no change or no copier data
- For non-Popular Investors (no copiers), both snapshots are NULL and change = 0

**Diagram**:
```
current (0-24h ago)  - prior (24-48h ago)  = ChangeInNumberOfCopiersInPast24Hours
100 copiers          - 90 copiers           = +10 (growing)
50 copiers           - 60 copiers           = -10 (shrinking)
0 (no data)          - 0 (no data)          = 0 (not a PI or no snapshot)
```

### 2.2 CID vs GCID Identity Pattern

**What**: Like other short views in this schema, CID is suppressed when GCID is available.

**Columns/Parameters Involved**: `GCID`, `CID`, `DemoCID`

**Rules**:
- `CID` = CASE WHEN GCID <> 0 THEN 0 ELSE CID END (CID is 0 for all accounts with a GCID)
- `DemoCID` = hardcoded 0 (this view targets real accounts)
- External systems use GCID as the primary join key

---

## 3. Data Overview

View not fully queryable in this environment (etoroGeneral.dbo.Copiers_DATA not accessible). The view produces one row per customer with a single change metric, most of which will be 0 for non-Popular Investors.

| GCID | CID | DemoCID | ChangeInNumberOfCopiersInPast24Hours | Meaning |
|------|-----|---------|--------------------------------------|---------|
| (PI with growing followers) | 0 | 0 | +25 | Popular Investor who gained 25 new copiers in the last 24 hours - prime target for engagement/recognition email |
| (PI with shrinking followers) | 0 | 0 | -10 | Popular Investor who lost 10 copiers - potential churn signal for retention campaign |
| (standard customer) | 0 | 0 | 0 | Non-Popular Investor: no copier data, change = 0 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | VERIFIED | Group Customer ID - cross-product identity key. From Customer.Customer (CustomerStatic). Primary join key for external email marketing systems. NULL for very old accounts without GCID. |
| 2 | CID | int | NO | - | CODE-BACKED | Computed: CASE WHEN GCID <> 0 THEN 0 ELSE CID END. Returns actual CID only for legacy accounts without GCID; 0 for all modern accounts. GCID is the primary identifier. |
| 3 | DemoCID | int | NO | - | CODE-BACKED | Always 0 (hardcoded). This view targets real accounts; the field exists to match the schema contract shared across GetRealCustomersShort_* views. |
| 4 | ChangeInNumberOfCopiersInPast24Hours | int | NO | - | CODE-BACKED | Computed: ISNULL(copiers in last 24h, 0) - ISNULL(copiers 24-48h ago, 0). Net change in CopyTrader follower count over the past day. Sourced from etoroGeneral.dbo.Copiers_DATA two-window comparison. 0 for non-Popular Investors or when no Copiers_DATA snapshot exists. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID, CID | Customer.Customer | FROM (CCST alias) | Customer identity source |
| ChangeInNumberOfCopiersInPast24Hours | etoroGeneral.dbo.Copiers_DATA | LEFT JOIN x2 (time windows) | Copier count snapshots at current and 24h-prior |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view in the SSDT repository. Terminal export view for email marketing systems.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRealCustomersShort_Copierts24H (view)
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
| etoroGeneral.dbo.Copiers_DATA | Table (external DB) | LEFT JOIN x2 - copier count snapshots (last 24h and 24-48h ago) |

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
| No IsReal filter | Missing filter | Despite name "RealCustomers", no IsReal=1 WHERE clause - all customers from Customer.Customer are included |

---

## 8. Sample Queries

### 8.1 Popular Investors who gained copiers in the last 24 hours
```sql
SELECT
    GCID,
    CID,
    ChangeInNumberOfCopiersInPast24Hours
FROM Customer.GetRealCustomersShort_Copierts24H WITH (NOLOCK)
WHERE ChangeInNumberOfCopiersInPast24Hours > 0
ORDER BY ChangeInNumberOfCopiersInPast24Hours DESC;
```

### 8.2 Popular Investors losing copiers (retention alert)
```sql
SELECT
    GCID,
    CID,
    ChangeInNumberOfCopiersInPast24Hours
FROM Customer.GetRealCustomersShort_Copierts24H WITH (NOLOCK)
WHERE ChangeInNumberOfCopiersInPast24Hours < 0
ORDER BY ChangeInNumberOfCopiersInPast24Hours ASC;
```

### 8.3 Join with Customer.Customer for full profile of fast-growing PIs
```sql
SELECT
    c.GCID,
    cs.UserName,
    cs.Email,
    c.ChangeInNumberOfCopiersInPast24Hours
FROM Customer.GetRealCustomersShort_Copierts24H c WITH (NOLOCK)
JOIN Customer.Customer cs WITH (NOLOCK) ON cs.GCID = c.GCID
WHERE c.ChangeInNumberOfCopiersInPast24Hours >= 10
ORDER BY c.ChangeInNumberOfCopiersInPast24Hours DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 10/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view, no consumers) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetRealCustomersShort_Copierts24H | Type: View | Source: etoro/etoro/Customer/Views/Customer.GetRealCustomersShort_Copierts24H.sql*
