# BI_DB_dbo.BI_DB_M_Affiliates_FraudMonitoring_Relations

> 14.04M-row affiliate fraud monitoring table flagging suspicious customer relations within the same affiliate. Two detection methods: FundingRelation (shared deposit FundingIDs, 4,713 flagged) and PersonalDetailsRelation (shared name+DOB, 233,353 flagged). One row per CID registered through an active affiliate. Registration months: Apr 2023 -- Mar 2026. Monthly DELETE+INSERT by RegisteredID (YYYYMM) via SP_M_Affiliates_FraudMonitoring_Relations.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Compliance -- Affiliate Fraud Monitoring, Relations) |
| **Production Source** | BI_DB_CIDFirstDates + Dim_Customer + Fact_BillingDeposit by SP_M_Affiliates_FraudMonitoring_Relations |
| **Refresh** | Monthly DELETE+INSERT by RegisteredID/YYYYMM (SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | -- |
| **UC Partitioned By** | -- |
| **UC Table Type** | -- |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |

---

## 1. Business Meaning

`BI_DB_M_Affiliates_FraudMonitoring_Relations` is a **compliance/fraud monitoring table** that identifies suspicious relationships among customers registered through the same affiliate partner. Affiliate fraud occurs when an affiliate registers multiple accounts using the same person (identity fraud) or the same funding source (financial fraud) to inflate referral bonuses.

The table holds 14.04M rows (one per CID per registration month). Each monthly batch includes all new registrations through active affiliates (AccountActivated=1) for that month, with two binary fraud flags:

1. **FundingRelation**: 1 if the CID shares a deposit FundingID (excluding FundingID=1) with another CID under the same affiliate. This indicates shared bank accounts, credit cards, or payment methods — a strong signal of multi-accounting. 4,713 flagged (0.03%).
2. **PersonalDetailsRelation**: 1 if the CID shares the same FirstName+LastName+BirthDate with another CID under the same affiliate. This indicates potential duplicate identities. 233,353 flagged (1.7%).

### Author and History
Created by Pavlina Masuora (2022-12-05). Test customer filter removed, RegisteredID column added (2023-05/08).

---

## 2. Business Logic

### 2.1 Funding Relation Detection

**What**: Finds customers sharing deposit funding sources within the same affiliate.
**Columns Involved**: FundingRelation
**Rules**:
- JOIN new registrations to Fact_BillingDeposit on CID
- GROUP BY AffiliateID, FundingID — HAVING COUNT(DISTINCT CID) > 1
- FundingID = 1 is excluded (generic/default funding)
- FundingRelation = 1 if CID appears in the flagged set

### 2.2 Personal Details Relation Detection

**What**: Finds customers with identical name + DOB within the same affiliate.
**Columns Involved**: PersonalDetailsRelation
**Rules**:
- GROUP BY AffiliateID, FirstName+' '+LastName, BirthDate — HAVING COUNT(DISTINCT RealCID) > 1
- Only counts where ClientName IS NOT NULL
- PersonalDetailsRelation = 1 if CID's name+DOB+AffiliateID appears in the flagged set

### 2.3 Date Window

**What**: Monthly processing based on registration date.
**Columns Involved**: RegisteredID
**Rules**:
- @Date is capped at end of last month (EOMONTH(GETDATE(), -1))
- @StartDate = first day of @Date's month
- @EndDate = first day of next month
- DELETE+INSERT by RegisteredID = YYYYMM of @StartDate

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. Large table (14M rows). Filter on RegisteredID (YYYYMM) for monthly analysis.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Affiliates with funding fraud | `WHERE FundingRelation = 1 GROUP BY AffiliateID` |
| Duplicate identity detection | `WHERE PersonalDetailsRelation = 1` |
| Monthly fraud rate trend | `GROUP BY RegisteredID` with `AVG(FundingRelation)` |
| High-risk affiliates | Both flags = 1 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer profile |
| DWH_dbo.Dim_Affiliate | AffiliateID | Affiliate details |
| BI_DB_dbo.BI_DB_CIDFirstDates | CID | Full lifecycle dates |

### 3.4 Gotchas

- **ClientName contains PII**: FirstName + LastName is stored in plain text. Handle with care
- **FundingID = 1 excluded**: The default/generic FundingID is not considered for relation detection
- **PersonalDetailsRelation false positives**: Common names (e.g., "John Smith") combined with same DOB across different real people will produce false positives
- **Monthly granularity**: RegisteredID is YYYYMM integer, not daily. The entire month is reprocessed on each run
- **@Date capping**: The SP caps @Date at end of last month — it never processes the current month

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki with documented production source |
| Tier 2 | Derived from SP code analysis with high confidence |
| Tier 3 | Inferred from data patterns and naming conventions |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliateID | bigint | YES | Affiliate partner ID (SerialID from BI_DB_CIDFirstDates). FK to Dim_Affiliate. Identifies which affiliate referred the customer. (Tier 2 -SP_M_Affiliates_FraudMonitoring_Relations) |
| 2 | CID | int | YES | Customer ID. FK to Dim_Customer.RealCID. (Tier 2 -SP_M_Affiliates_FraudMonitoring_Relations) |
| 3 | GCID | int | YES | Global customer ID from BI_DB_CIDFirstDates. (Tier 2 -SP_M_Affiliates_FraudMonitoring_Relations) |
| 4 | registered | datetime | YES | Customer registration datetime from BI_DB_CIDFirstDates. (Tier 2 -SP_M_Affiliates_FraudMonitoring_Relations) |
| 5 | Country | varchar(max) | YES | Customer's country at registration from BI_DB_CIDFirstDates. (Tier 2 -SP_M_Affiliates_FraudMonitoring_Relations) |
| 6 | FirstDepositAmount | money | YES | First deposit amount from BI_DB_CIDFirstDates. In USD. (Tier 2 -SP_M_Affiliates_FraudMonitoring_Relations) |
| 7 | IsFTD | int | YES | Whether the customer has made a first deposit. 1=yes (FirstDepositDate NOT NULL), 0=no. (Tier 2 -SP_M_Affiliates_FraudMonitoring_Relations) |
| 8 | FTDYearMonth | int | YES | First deposit date as YYYYMM integer. NULL if no FTD. (Tier 2 -SP_M_Affiliates_FraudMonitoring_Relations) |
| 9 | ClientName | varchar(max) | YES | Customer's full name (FirstName + ' ' + LastName). PII -- handle with care. Used for PersonalDetailsRelation matching. (Tier 2 -SP_M_Affiliates_FraudMonitoring_Relations via Dim_Customer) |
| 10 | VerificationLevelID | int | YES | KYC verification level. 0=unverified, 1=partial, 2=intermediate, 3=fully verified. From Dim_Customer. (Tier 2 -SP_M_Affiliates_FraudMonitoring_Relations via Dim_Customer) |
| 11 | FundingRelation | int | YES | Funding source relation flag. 1=CID shares a deposit FundingID (!=1) with another CID under the same affiliate (0.03% flagged). 0=no shared funding detected. (Tier 2 -SP_M_Affiliates_FraudMonitoring_Relations) |
| 12 | PersonalDetailsRelation | int | YES | Personal details relation flag. 1=CID shares FirstName+LastName+BirthDate with another CID under the same affiliate (1.7% flagged). 0=no match. (Tier 2 -SP_M_Affiliates_FraudMonitoring_Relations) |
| 13 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was inserted. Set to GETDATE(). (Tier 5 -SP_M_Affiliates_FraudMonitoring_Relations) |
| 14 | RegisteredID | int | YES | Registration month as YYYYMM integer. Used for DELETE+INSERT partitioning. (Tier 2 -SP_M_Affiliates_FraudMonitoring_Relations) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| AffiliateID | BI_DB_CIDFirstDates | SerialID | Passthrough |
| CID, GCID, registered, Country | BI_DB_CIDFirstDates | Same columns | Passthrough |
| FirstDepositAmount | BI_DB_CIDFirstDates | FirstDepositAmount | Passthrough |
| IsFTD | Computed | FirstDepositDate | IS NULL check |
| FTDYearMonth | Computed | FirstDepositDate | YYYYMM conversion |
| ClientName | DWH_dbo.Dim_Customer | FirstName, LastName | Concatenation |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough |
| FundingRelation | Computed | Fact_BillingDeposit.FundingID | Multi-CID shared FundingID detection |
| PersonalDetailsRelation | Computed | Dim_Customer name+DOB | Multi-CID shared identity detection |
| RegisteredID | Computed | registered | YYYYMM conversion |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_CIDFirstDates (registrations for the month)
  + DWH_dbo.Dim_Affiliate (AccountActivated=1)
  + DWH_dbo.Dim_Customer (name, DOB, verification, validity)
    |-- SP_M_Affiliates_FraudMonitoring_Relations @Date (monthly) ---|
    |   Step 1: #newregs = new affiliate registrations for month      |
    |   Step 2: #fundingCIDS = all deposits by new registrations      |
    |   Step 3: #countfudningIDs = FundingIDs shared by >1 CID       |
    |           (excluding FundingID=1)                                |
    |   Step 4: #RELATIONS = CIDs with shared FundingIDs              |
    |   Step 5: #personaldetails = name+DOB shared by >1 CID         |
    |   Step 6: #final = LEFT JOIN → FundingRelation + PersonalDetails|
    |   Step 7: DELETE + INSERT by RegisteredID (YYYYMM)              |
    v
BI_DB_dbo.BI_DB_M_Affiliates_FraudMonitoring_Relations (14.04M rows)
  (Not in Generic Pipeline -- _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer profile |
| AffiliateID | DWH_dbo.Dim_Affiliate | Affiliate details |
| All base data | BI_DB_dbo.BI_DB_CIDFirstDates | Customer lifecycle dates |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Affiliates with Most Funding Relations

```sql
SELECT AffiliateID,
       COUNT(*) AS total_cids,
       SUM(FundingRelation) AS funding_flagged,
       SUM(PersonalDetailsRelation) AS personal_flagged
FROM [BI_DB_dbo].[BI_DB_M_Affiliates_FraudMonitoring_Relations]
WHERE RegisteredID >= 202601
GROUP BY AffiliateID
HAVING SUM(FundingRelation) > 0
ORDER BY funding_flagged DESC
```

### 7.2 Monthly Fraud Flag Trend

```sql
SELECT RegisteredID,
       COUNT(*) AS total,
       SUM(FundingRelation) AS funding_flags,
       SUM(PersonalDetailsRelation) AS personal_flags,
       CAST(SUM(PersonalDetailsRelation) AS FLOAT) / COUNT(*) AS personal_rate
FROM [BI_DB_dbo].[BI_DB_M_Affiliates_FraudMonitoring_Relations]
GROUP BY RegisteredID
ORDER BY RegisteredID
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 13 T2, 0 T3, 0 T4, 1 T5 | Elements: 14/14, Logic: 9/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_M_Affiliates_FraudMonitoring_Relations | Type: Table | Production Source: BI_DB_CIDFirstDates + Dim_Customer + Fact_BillingDeposit*
