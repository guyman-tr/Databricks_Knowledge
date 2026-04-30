# Dictionary.RafStatus_NogaJunk210725

> Lookup table defining 4 Refer-A-Friend (RAF) referral lifecycle states — WaitForEligibility, Expired, Completed, and ReachMaxCompensation. Legacy/junk table from July 2021.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RafStatusID (INT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.RafStatus_NogaJunk210725 tracks the lifecycle of individual referral records in eToro's Refer-A-Friend program. When a customer refers someone, the referral enters a pending state until the referred user meets eligibility criteria (usually making a qualifying deposit). The referral then completes or expires.

The "_NogaJunk210725" suffix indicates this is a legacy table preserved from a July 2021 cleanup. Referenced by Customer.RafEligibleCustomers_NogaJunk210725, Customer.RafViewCustomerStatus_NogaJunk210725, Customer.SetRafCompensation, and related RAF procedures.

---

## 2. Business Logic

### 2.1 Referral Lifecycle

**What**: Each status represents a stage in the referral's lifecycle.

**Columns/Parameters Involved**: `RafStatusID`, `RafStatusName`

**Rules**:
- **1 = WaitForEligibility** — Referral is pending. The referred user has registered but hasn't met the qualifying criteria (usually a minimum deposit) yet.
- **2 = Expired** — Referral expired before the referred user met eligibility criteria. Time-limited referral window elapsed.
- **3 = Completed** — Referral successfully completed. The referred user met all criteria and the referrer received their compensation.
- **4 = ReachMaxCompensation** — The referrer has reached the maximum allowed RAF compensation limit. No further referral rewards will be paid.

**Diagram**:
```
RAF Referral Lifecycle
1 (WaitForEligibility)
    │
    ├──▶ 2 (Expired)               ← time limit reached
    ├──▶ 3 (Completed)             ← criteria met, reward paid
    └──▶ 4 (ReachMaxCompensation)  ← referrer at cap
```

---

## 3. Data Overview

| RafStatusID | RafStatusName | Meaning |
|---|---|---|
| 1 | WaitForEligibility | Pending — referred user hasn't met qualifying criteria yet. |
| 2 | Expired | Referral window expired before eligibility was met. |
| 3 | Completed | Successfully completed — reward paid to the referrer. |
| 4 | ReachMaxCompensation | Referrer has reached the maximum cumulative RAF reward limit. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RafStatusID | int | NO | - | VERIFIED | Primary key. Values 1-4 representing the 4 referral lifecycle states. Referenced by Customer.RafEligibleCustomers_NogaJunk210725. |
| 2 | RafStatusName | varchar(50) | NO | - | VERIFIED | Human-readable status label. Used in RAF reporting, customer views, and admin dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RafEligibleCustomers_NogaJunk210725 | RafStatusID | Implicit | Tracks per-referral status |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RafEligibleCustomers_NogaJunk210725 | Table | Stores RafStatusID per referral |
| Customer.RafViewCustomerStatus_NogaJunk210725 | View | Displays referral status |
| Customer.SetRafCompensation | Stored Procedure | Modifier — updates referral status on compensation |
| Customer.GetRafStatusByGCID_NogaJunk210725 | Stored Procedure | Reader — gets RAF status |
| Customer.RafGetReferralHistory_NogaJunk210725 | Stored Procedure | Reader — referral history with status |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RafStatus_RafStatusID | CLUSTERED PK | RafStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RafStatus_RafStatusID | PRIMARY KEY | Unique status identifier |

---

## 8. Sample Queries

### 8.1 List all RAF statuses
```sql
SELECT  RafStatusID,
        RafStatusName
FROM    [Dictionary].[RafStatus_NogaJunk210725] WITH (NOLOCK)
ORDER BY RafStatusID;
```

### 8.2 Count referrals by status
```sql
SELECT  rs.RafStatusName,
        COUNT(*) AS ReferralCount
FROM    [Customer].[RafEligibleCustomers_NogaJunk210725] re WITH (NOLOCK)
JOIN    [Dictionary].[RafStatus_NogaJunk210725] rs WITH (NOLOCK) ON re.RafStatusID = rs.RafStatusID
GROUP BY rs.RafStatusName;
```

### 8.3 Find active (pending) referrals
```sql
SELECT  *
FROM    [Customer].[RafEligibleCustomers_NogaJunk210725] WITH (NOLOCK)
WHERE   RafStatusID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RafStatus_NogaJunk210725 | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RafStatus_NogaJunk210725.sql*
