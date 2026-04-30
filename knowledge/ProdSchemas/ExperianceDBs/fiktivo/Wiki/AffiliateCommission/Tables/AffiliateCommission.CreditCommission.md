# AffiliateCommission.CreditCommission

> Child table of Credit storing the actual commission amounts earned by each affiliate at each tier for a credit event (deposit or chargeback), with affiliate type classification.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Table |
| **Key Identifier** | CreditID + Tier (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (PK clustered + 2 NC) |

---

## 1. Business Meaning

CreditCommission stores the commission breakdown for each credit event - how much each affiliate earned at each tier level for a deposit or chargeback. While Credit holds the event details (Amount, CreditTypeID, IsFirstDeposit), this table holds the per-affiliate, per-tier commission amounts that result from applying commission rules to those events.

This table exists because a single credit event can generate commissions for multiple affiliates in a multi-tier referral chain. The composite PK (CreditID + Tier) ensures one commission record per tier per credit. Unlike ClosedPositionCommission, this table includes AffiliateTypeID (added in PART-2448) to support affiliate-type-specific commission rules.

The table has 4.75 million rows matching the Credit table 1:1 (mostly single-tier), across 1,077 distinct affiliates and 825 distinct affiliate types. Data is populated atomically with Credit by InsertCredit and can be replaced by SaveCreditCommission.

---

## 2. Business Logic

### 2.1 Multi-Tier Credit Commission

**What**: Each credit event generates commission(s) for affiliates in the referral chain.

**Columns/Parameters Involved**: `CreditID`, `AffiliateID`, `Tier`, `Commission`, `Paid`, `PaymentID`, `AffiliateTypeID`

**Rules**:
- Tier 1 = direct referrer, Tier 2+ = upstream affiliates
- Commission can be 0 for credits that don't generate commissions under the affiliate's agreement
- AffiliateTypeID classifies the type of affiliate for type-specific commission rules (added PART-2448)
- Paid/PaymentID track payment processing - same pattern as ClosedPositionCommission

---

## 3. Data Overview

| CreditID | AffiliateID | Commission | Tier | Paid | PaymentID | AffiliateTypeID | Meaning |
|---|---|---|---|---|---|---|---|
| 2168476045 | 3 | 0 | 1 | 0 | 0 | 3 | Latest credit. Zero commission, Tier 1, AffiliateType 3. Unpaid. |
| 2168476044 | 3 | 0 | 1 | 0 | 0 | 3 | Same pattern - all AffiliateID 3, Type 3, zero commission. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NO | - | CODE-BACKED | Credit event this commission applies to. First column of composite PK. Implicitly references Credit.CreditID. Sourced from CreditAccountMapping.CreditInternalID. |
| 2 | AffiliateID | int | NO | - | CODE-BACKED | Affiliate earning this commission. References dbo.tblaff_Affiliates. Indexed with Tier and AffiliateTypeID for reporting. |
| 3 | Commission | float | NO | - | CODE-BACKED | Dollar amount of commission earned. Can be 0 for non-commissionable credits. Uses float for legacy compatibility. |
| 4 | Tier | int | NO | - | CODE-BACKED | Commission tier level. 1 = direct referrer, 2+ = upstream. Second column of composite PK. |
| 5 | Paid | bit | NO | - | CODE-BACKED | Payment status. 0 = unpaid, 1 = paid out. |
| 6 | PaymentID | int | NO | - | CODE-BACKED | Payment batch ID. 0 when unpaid, batch ID when paid. |
| 7 | AffiliateTypeID | int | YES | - | CODE-BACKED | Affiliate type classification for type-specific commission rules. Added in PART-2448 (CPA New Compensation Design, Dec 2023). NULL for records created before this feature. 825 distinct types observed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditID | AffiliateCommission.Credit | Implicit FK | Parent credit event |
| AffiliateID | dbo.tblaff_Affiliates | Implicit | Affiliate earning commission |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.CreditCommissionVW | JOIN | View | Commission view with UpdateDate |
| AffiliateCommission.InsertCredit | INSERT | Writer | Creates commission atomically with credit |
| AffiliateCommission.SaveCreditCommission | DELETE+INSERT | Writer | Replaces commission rows |
| AffiliateCommission.GetEarnedDepositCommission | SELECT | Reader | Reads deposit commissions |
| AffiliateCommission.GetNumberOfFTDs | SELECT | Reader | FTD counting with commission |
| AffiliateCommission.UpdateCreditTrackingAffiliate | UPDATE | Modifier | Updates affiliate tracking |
| AffiliateCommission.CheckCidExistsInChargebacks | SELECT | Reader | Chargeback existence check |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.CreditCommission (table)
└── AffiliateCommission.Credit (table) [implicit, via CreditID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Credit | Table | CreditID references credit events |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditCommissionVW | View | Reads with payment date |
| AffiliateCommission.InsertCredit | Stored Procedure | Writer |
| AffiliateCommission.SaveCreditCommission | Stored Procedure | Writer (replace pattern) |
| AffiliateCommission.GetEarnedDepositCommission | Stored Procedure | Reader |
| AffiliateCommission.GetNumberOfFTDs | Stored Procedure | Reader |
| AffiliateCommission.CheckCidExistsInChargebacks | Stored Procedure | Reader |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CreditCommission_CreditID | CLUSTERED PK | CreditID, Tier | - | - | Active (PAGE compression) |
| IX_CreditCommission_AffiliateIDTierAffiliateTypeID | NC | AffiliateID, Tier, AffiliateTypeID | - | - | Active (PAGE compression) |
| IX_CreditCommission_CreditIDAffiliateID | NC | CreditID, AffiliateID, Tier | - | - | Active (PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CreditCommission_CreditID | PRIMARY KEY | Composite - one commission per credit per tier |

---

## 8. Sample Queries

### 8.1 Commission details for a credit
```sql
SELECT CreditID, AffiliateID, Commission, Tier, Paid, PaymentID, AffiliateTypeID
FROM AffiliateCommission.CreditCommission WITH (NOLOCK)
WHERE CreditID = 2168476044;
```

### 8.2 Total unpaid credit commissions by affiliate
```sql
SELECT AffiliateID, SUM(Commission) AS UnpaidTotal, COUNT(*) AS CreditCount
FROM AffiliateCommission.CreditCommission WITH (NOLOCK)
WHERE Paid = 0
GROUP BY AffiliateID
ORDER BY UnpaidTotal DESC;
```

### 8.3 Credit with full context
```sql
SELECT c.CreditID, c.CreditDate, c.Amount, c.CreditTypeID, c.IsFirstDeposit,
       cc.AffiliateID, cc.Commission, cc.Tier, cc.AffiliateTypeID, cc.Paid
FROM AffiliateCommission.Credit c WITH (NOLOCK)
JOIN AffiliateCommission.CreditCommission cc WITH (NOLOCK) ON c.CreditID = cc.CreditID
WHERE c.CreditID = 2168476044;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PART-2448](https://etoro-jira.atlassian.net/browse/PART-2448) | Jira | Added AffiliateTypeID for CPA New Compensation Design (Dec 2023) |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CreditCommission | Type: Table | Source: fiktivo/AffiliateCommission/Tables/AffiliateCommission.CreditCommission.sql*
