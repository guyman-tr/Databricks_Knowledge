# AffiliateCommission.RegistrationCommission

> Child table of Registration storing the actual commission amounts earned by each affiliate at each tier for a customer registration event.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | RegistrationID + Tier (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (PK clustered + NC on AffiliateID, Tier) |

---

## 1. Business Meaning

RegistrationCommission stores the commission breakdown for each registration - how much each affiliate earned at each tier level for referring a customer who registered. While Registration holds the event details, this table holds the per-affiliate, per-tier commission amounts that result from applying CPA commission rules.

This table exists because a single registration can generate commissions for multiple affiliates in a multi-tier referral chain. The composite PK (RegistrationID + Tier) ensures one commission record per tier per registration. The table was created as part of PART-1195 (Feb 2022) to support the registration commission model.

With 14.5 million rows closely matching Registration's 14.5 million, the 1:1 ratio indicates mostly single-tier commissions. The table supports 1,077+ affiliates and is populated atomically with Registration by InsertRegistration.

---

## 2. Business Logic

### 2.1 Registration Commission Model

**What**: Affiliates earn commissions for each customer registration they drive.

**Columns/Parameters Involved**: `RegistrationID`, `AffiliateID`, `Tier`, `Commission`, `Paid`, `PaymentID`

**Rules**:
- Same multi-tier pattern as ClosedPositionCommission and CreditCommission
- Commission can be 0 for registrations that don't generate commissions under the affiliate's agreement
- Unlike CreditCommission, this table does NOT have AffiliateTypeID

---

## 3. Data Overview

| RegistrationID | AffiliateID | Commission | Tier | Paid | PaymentID | Meaning |
|---|---|---|---|---|---|---|
| 15411827 | 3 | 0 | 1 | 0 | 0 | Latest registration. Zero commission, Tier 1, unpaid. |
| 15411826 | 3 | 0 | 1 | 0 | 0 | Same pattern - all going to AffiliateID 3. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegistrationID | bigint | NO | - | CODE-BACKED | Registration this commission applies to. First column of composite PK. References Registration.RegistrationID. |
| 2 | AffiliateID | int | NO | - | CODE-BACKED | Affiliate earning this commission. Indexed with Tier for reporting. |
| 3 | Commission | float | NO | - | CODE-BACKED | Dollar amount of commission earned. Can be 0. |
| 4 | Tier | int | NO | - | CODE-BACKED | Commission tier level. 1 = direct referrer, 2+ = upstream. |
| 5 | Paid | bit | NO | - | CODE-BACKED | Payment status. 0 = unpaid, 1 = paid out. |
| 6 | PaymentID | int | NO | - | CODE-BACKED | Payment batch ID. 0 when unpaid. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RegistrationID | AffiliateCommission.Registration | Implicit FK | Parent registration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.RegistrationCommissionVW | JOIN | View | Commission view with UpdateDate |
| AffiliateCommission.InsertRegistration | INSERT | Writer | Creates atomically with registration |
| AffiliateCommission.SaveRegistrationCommission | DELETE+INSERT | Writer | Replaces commission rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.RegistrationCommission (table)
└── AffiliateCommission.Registration (table) [implicit]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Registration | Table | RegistrationID references registration |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationCommissionVW | View | Reads with payment date |
| AffiliateCommission.InsertRegistration | Stored Procedure | Writer |
| AffiliateCommission.SaveRegistrationCommission | Stored Procedure | Writer (replace) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RegistrationCommission_RegistrationID | CLUSTERED PK | RegistrationID, Tier | - | - | Active (PAGE compression) |
| IX_AffiliateID_Tier | NC | AffiliateID, Tier | Commission | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RegistrationCommission_RegistrationID | PRIMARY KEY | Composite - one commission per registration per tier |

---

## 8. Sample Queries

### 8.1 Commission for a registration
```sql
SELECT RegistrationID, AffiliateID, Commission, Tier, Paid, PaymentID
FROM AffiliateCommission.RegistrationCommission WITH (NOLOCK)
WHERE RegistrationID = 15411827;
```

### 8.2 Total unpaid registration commissions
```sql
SELECT AffiliateID, SUM(Commission) AS UnpaidTotal, COUNT(*) AS RegCount
FROM AffiliateCommission.RegistrationCommission WITH (NOLOCK)
WHERE Paid = 0 GROUP BY AffiliateID ORDER BY UnpaidTotal DESC;
```

### 8.3 Registration with commission context
```sql
SELECT r.RegistrationID, r.CID, r.RegistrationDate, r.CountryID,
       rc.AffiliateID, rc.Commission, rc.Tier, rc.Paid
FROM AffiliateCommission.Registration r WITH (NOLOCK)
JOIN AffiliateCommission.RegistrationCommission rc WITH (NOLOCK) ON r.RegistrationID = rc.RegistrationID
WHERE r.RegistrationID = 15411827;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-1195](https://etoro-jira.atlassian.net/browse/PART-1195) | Jira | Registration commission support created (Feb 2022) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RegistrationCommission | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.RegistrationCommission.sql*
