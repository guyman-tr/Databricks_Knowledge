# dbo.tblaff_Registrations_Commissions

> Stores tier-based affiliate commission records from customer registration events - the largest commission table (~3.75M rows), reflecting registration as the highest-volume affiliate event.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK NC) |
| **Partition** | No |
| **Indexes** | 6 active |

---

## 1. Business Meaning

dbo.tblaff_Registrations_Commissions records affiliate commissions from customer registrations (tblaff_Registrations). This is the **largest commission table** (~3.75M records), as every customer registration generates at least one commission row (and additional rows for each tier level). Registration commissions are fundamental to the affiliate program - they reward affiliates for driving new customer sign-ups.

Triggers enforce that RegistrationID references a valid registration and AffiliateID references a valid affiliate. Like Leads, includes an `eCost` field for effective cost tracking. The `UpdateSubAffiliateID` procedure handles late-binding attribution. The DailySummaryReport view joins this table with tblaff_Registrations for daily registration counts.

---

## 2. Business Logic

### 2.1 Multi-Tier Registration Commission

**Columns/Parameters Involved**: `RegistrationID`, `AffiliateID`, `Commission`, `Tier`, `eCost`

**Rules**:
- RegistrationID references tblaff_Registrations. Triggers enforce RI on INSERT/UPDATE.
- Standard multi-tier: Tier 1 = direct, 2-5 = parents
- `eCost` tracks the platform's effective acquisition cost per registration

### 2.2 Payment Lifecycle

- Same pattern: Paid=0/PaymentID=0 = unpaid, Paid=1/PaymentID>0 = paid

---

## 3. Data Overview

Table contains 3,746,042 rows - the highest volume commission table. Registration is the most common tracked affiliate event.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | - | CODE-BACKED | Auto-incrementing primary key. NOT FOR REPLICATION. |
| 2 | RegistrationID | int | YES | 0 | VERIFIED | References tblaff_Registrations.RegistrationID. Trigger enforces RI. |
| 3 | AffiliateID | int | YES | 0 | VERIFIED | The affiliate receiving this commission. Trigger enforces RI. |
| 4 | Commission | float | YES | 0 | VERIFIED | Registration commission amount for this tier. |
| 5 | Tier | int | YES | 0 | VERIFIED | Commission tier level: 1-5. |
| 6 | Paid | bit | NO | 0 | VERIFIED | Payment status: 0 = unpaid, 1 = paid. |
| 7 | PaymentID | int | NO | 0 | VERIFIED | References tblaff_PaymentHistory.PaymentID when paid. |
| 8 | SubAffiliateID | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking tag. Updatable by UpdateSubAffiliateID. |
| 9 | eCost | float | YES | - | CODE-BACKED | Effective cost to the platform for this registration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RegistrationID | dbo.tblaff_Registrations | Implicit (trigger) | The registration event |
| AffiliateID | dbo.tblaff_Affiliates | Implicit (trigger) | The affiliate receiving commission |
| PaymentID | dbo.tblaff_PaymentHistory | Implicit | Payment batch when paid |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.UpdateSubAffiliateID | UPDATE | Procedure (MODIFIER) | Late-binding attribution |
| dbo.DailySummaryReport | JOIN | View (READER) | Daily registration count aggregation (Tier=1 only) |
| dbo.qry_aff_RegistrationDetailAllTiers | FROM | View (READER) | All-tier registration commission details |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.UpdateSubAffiliateID | Stored Procedure | MODIFIER |
| dbo.DailySummaryReport | View | Registration count aggregation |
| dbo.qry_aff_Tier1RegistrationsCommissions through Tier5 | Views | Per-tier aggregation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| tblaff_Registrations_Commissions_PK | NC PK | ID ASC | - | - | Active (PAGE) |
| CIX_tblaff_Registrations_Commissions_RegistrationID | CLUSTERED | RegistrationID ASC | - | - | Active (PAGE) |
| IDX_tblaff_Registrations_Commissions_AffiliateIDTier | NC | AffiliateID, Tier | RegistrationID, Commission, Paid, SubAffiliateID | - | Active (PAGE) |
| IDX_tblaff_Registrations_Commissions_AffiliateIDTier1 | NC | AffiliateID, Tier | RegistrationID, Commission, Paid | - | Active (PAGE) |
| IDX_tblaff_Registrations_Commissions_Tier1 | NC | Tier | RegistrationID, AffiliateID, Commission, SubAffiliateID | - | Active (PAGE) |
| IX_tblaff_Registrations_Commissions_Incl1 | NC | AffiliateID, Paid | ID, RegistrationID | - | Active (PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_Registrations_Commissions_Paid | DEFAULT | 0 |
| DF_tblaff_Registrations_Commissions_PaymentID | DEFAULT | 0 |

---

## 8. Sample Queries

### 8.1 Unpaid registration commissions by affiliate
```sql
SELECT AffiliateID, Tier, COUNT(*) AS Records, SUM(Commission) AS TotalUnpaid
FROM dbo.tblaff_Registrations_Commissions WITH (NOLOCK)
WHERE Paid = 0
GROUP BY AffiliateID, Tier ORDER BY TotalUnpaid DESC
```

### 8.2 Registration volume by tier
```sql
SELECT Tier, COUNT(*) AS Records, SUM(Commission) AS TotalCommission
FROM dbo.tblaff_Registrations_Commissions WITH (NOLOCK)
GROUP BY Tier ORDER BY Tier
```

### 8.3 Registration commissions with customer details
```sql
SELECT rc.Commission, rc.Tier, r.Optional3 AS CustomerCID, r.ORDER_DATE
FROM dbo.tblaff_Registrations_Commissions rc WITH (NOLOCK)
JOIN dbo.tblaff_Registrations r WITH (NOLOCK) ON rc.RegistrationID = r.RegistrationID
WHERE rc.AffiliateID = @AffiliateID AND rc.Tier = 1
ORDER BY r.ORDER_DATE DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Registrations_Commissions | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Registrations_Commissions.sql*
