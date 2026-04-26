# BI_DB_dbo.BI_DB_AML_Periodic_Review_MOP

> 151K-row AML Periodic Review support table mapping fully-verified active customers to the high-risk deposit Method of Payment (MOP) they used since January 2023. Each row represents a (CID, MOP) pair — a customer who deposited using a non-standard payment method that is classified as higher-risk in the AML periodic review framework.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `DWH_dbo.Fact_CustomerAction` (deposit events since 2023) + `DWH_dbo.Dim_FundingType` (MOP name) |
| **Refresh** | Unknown — no SSDT writer SP found. Likely derived from SP_AML_Periodic_Review's internal #mop temp table logic via a separate extraction step. |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_AML_Periodic_Review_MOP` is a support table for the AML Periodic Review process that identifies which verified eToro customers have used a "high-risk" deposit method (Method of Payment) since January 2023. In AML compliance, the payment method a customer uses is a material risk indicator — certain MOPs (e.g., MoneyBookers/Skrill, Neteller, online banking from high-risk jurisdictions) have historically been associated with money laundering patterns.

The table answers: "Which fully-verified, active eToro customers deposited using a non-standard payment method since 2023, and what was that MOP?" This directly feeds the `Is_High_MOP_Deposit` risk flag in the AML Periodic Review reports (`BI_DB_AML_Periodic_Review_HR`, `_MR`, `_AR`): a customer is flagged `Is_High_MOP_Deposit = 1` if they appear in this table.

**Population rules**: Only customers who are:
- `IsValidCustomer = 1` AND `IsDepositor = 1`
- `VerificationLevelID = 3` (fully Enhanced KYC — stricter than the Dep tables which use ≥2)
- PlayerStatus NOT IN (2, 4) — excludes Blocked and Blocked Upon Request
- Deposited since 2023 using a FundingTypeID NOT in the "safe" exclusion list

**MOP exclusion list**: FundingTypeIDs 1, 2, 3, 4, 11, 13, 15, 17, 29, 30, 32, 33, 34, 35, 36, 37, 38 are considered standard/safe methods and excluded. The remaining MOPs that pass this filter are the "high-risk" methods captured in this table.

**MOP distribution** (current): OnlineBanking (67%), MoneyBookers/Skrill (21%), Neteller (8%), SEPA (1.4%), FastPay (0.9%), WireTransfer (0.7%), Przelewy24 (0.2%), PaySafe (0.2%), Dotpay (0.1%), Klarna (<0.1%)

Note: The writer SP for this specific table is not in the SSDT repo or OpsDB. It is likely materialized from `SP_AML_Periodic_Review`'s `#mop` temp table (which has the identical logic) via an external extraction step. Always verify UpdateDate to assess data freshness.

---

## 2. Business Logic

### 2.1 MOP Risk Classification via FundingType Exclusion

**What**: Instead of classifying MOPs as "high-risk" directly, the logic uses a whitelist exclusion approach — methods on the exclusion list are considered safe; everything else is potentially high-risk.

**Columns Involved**: `MOP`

**Rules**:
- Source: `Fact_CustomerAction WHERE ActionTypeID = 7` (deposit events)
- Excluded FundingTypeIDs (safe methods): `NOT IN (1, 2, 3, 4, 11, 13, 15, 17, 29, 30, 32, 33, 34, 35, 36, 37, 38)`
- Only deposit events from DateID >= 20230101 are considered (the AML review window is 2023 to present)
- `MOP` is the human-readable name from `Dim_FundingType.Name` for the surviving FundingTypeID

### 2.2 Population: Fully-Verified Active Customers Only

**What**: The periodic review targets the highest-risk population — fully verified (VerificationLevelID=3), active, depositing customers.

**Columns Involved**: `CID`

**Rules**:
- `VerificationLevelID = 3` only (stricter than the Dep tables which allow ≥2)
- `IsValidCustomer = 1` AND `IsDepositor = 1`
- PlayerStatus JOIN with `NOT IN (2, 4)` — excludes Blocked and Blocked Upon Request accounts
- This population reflects the customers subject to Enhanced Due Diligence (EDD) review

### 2.3 One Row Per (CID, MOP) Pair

**What**: A customer who deposited using multiple high-risk MOPs since 2023 will appear multiple times — one row per distinct MOP.

**Columns Involved**: `CID`, `MOP`

**Rules**:
- The `DISTINCT pp.CID, dft.Name AS MOP` select ensures no duplicate (CID, MOP) pairs
- A customer with deposits via both MoneyBookers and Neteller → 2 rows

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP with 151K rows. Fast full-table scans. For CID-based JOINs with large DWH tables, filter here first.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customers who used high-risk MOP | `SELECT DISTINCT CID FROM BI_DB_AML_Periodic_Review_MOP` |
| MOP frequency distribution | `GROUP BY MOP ORDER BY COUNT(*) DESC` |
| Customers using Neteller or MoneyBookers | `WHERE MOP IN ('MoneyBookers', 'Neteller')` |
| Link to full AML profile | JOIN BI_DB_AML_Periodic_Review_AR ON CID |
| Customers with multiple high-risk MOPs | `GROUP BY CID HAVING COUNT(DISTINCT MOP) > 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_AML_Periodic_Review_AR | ON CID | Full AML periodic review profile (all-risk clients) |
| BI_DB_dbo.BI_DB_AML_Periodic_Review_HR | ON CID | High-risk client periodic review profile |
| DWH_dbo.Dim_Customer | ON CID = RealCID | Customer demographics and regulation |
| DWH_dbo.Fact_CustomerAction | ON CID=RealCID AND ActionTypeID=7 AND DateID>=20230101 | Specific deposit transactions for investigation |

### 3.4 Gotchas

- **No writer SP in SSDT**: This table's ETL process is not tracked in SSDT or OpsDB. UpdateDate is the only way to assess freshness.
- **Multiple rows per CID**: Aggregating by CID without deduplication will overcount customers. Use `SELECT DISTINCT CID` or `COUNT(DISTINCT CID)` when counting people.
- **VerificationLevelID=3 only**: Unlike other Multiple Accounts tables, this is restricted to the highest KYC level. Customers with VerificationLevelID=2 are not here.
- **Date window = 2023+**: MOPs used before 2023 are not reflected.

---

## 4. Elements

| Column | Type | Description | Source | Notes |
|--------|------|-------------|--------|-------|
| CID | int | eToro customer Real account ID — a fully-verified (VerificationLevelID=3), active depositor who used a high-risk payment method since 2023 | DWH_dbo.Dim_Customer (via population filter) | Part of composite key with MOP; one CID may appear multiple times |
| MOP | nvarchar(500) | Method of Payment name — the high-risk deposit method used since 2023 (from Dim_FundingType.Name) | DWH_dbo.Dim_FundingType (via Fact_CustomerAction.FundingTypeID) | Top values: OnlineBanking (67%), MoneyBookers (21%), Neteller (8%), SEPA (1.4%), FastPay (0.9%), WireTransfer (0.7%) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline | ETL | GETDATE() at extraction time — verify freshness before use |

---

## 5. Lineage

```
DWH_dbo.Dim_Customer (VerificationLevelID=3, IsValidCustomer=1, IsDepositor=1)
    JOIN DWH_dbo.Dim_PlayerStatus (PlayerStatusID NOT IN (2,4))
    →
    JOIN DWH_dbo.Fact_CustomerAction
         ActionTypeID=7, DateID>=20230101
         FundingTypeID NOT IN (1,2,3,4,11,13,15,17,29,30,32,33,34,35,36,37,38)
    →
    JOIN DWH_dbo.Dim_FundingType → MOP name
    └─ [extraction step] → BI_DB_AML_Periodic_Review_MOP
```

Logic derived from SP_AML_Periodic_Review's internal `#mop` temp table (see SSDT: `BI_DB_dbo.SP_AML_Periodic_Review.sql`, line ~182-195).

See full column lineage: `BI_DB_AML_Periodic_Review_MOP.lineage.md`

**UC**: Not_Migrated.

---

## 6. Relationships

| Related Table | Join Condition | Relationship |
|--------------|----------------|--------------|
| BI_DB_dbo.BI_DB_AML_Periodic_Review_AR | ON CID | Full all-risk periodic review profile |
| BI_DB_dbo.BI_DB_AML_Periodic_Review_HR | ON CID | High-risk periodic review profile (Is_High_MOP_Deposit=1 if CID present here) |
| BI_DB_dbo.BI_DB_AML_Periodic_Review_MR | ON CID | Medium-risk periodic review profile |
| DWH_dbo.Dim_FundingType | ON MOP = Name | Funding type details and flags |

---

## 7. Sample Queries

```sql
-- MOP frequency: which high-risk payment methods are most common?
SELECT MOP, COUNT(DISTINCT CID) AS unique_customers, COUNT(*) AS rows
FROM [BI_DB_dbo].[BI_DB_AML_Periodic_Review_MOP]
GROUP BY MOP
ORDER BY unique_customers DESC

-- Customers using more than one high-risk MOP (elevated risk)
SELECT CID, COUNT(DISTINCT MOP) AS num_mops, STRING_AGG(MOP, ', ') AS mops_used
FROM [BI_DB_dbo].[BI_DB_AML_Periodic_Review_MOP]
GROUP BY CID
HAVING COUNT(DISTINCT MOP) > 1
ORDER BY num_mops DESC

-- Link to AML Periodic Review: all high-MOP customers with their HR review profile
SELECT mop.CID, mop.MOP,
       hr.Regulation, hr.Country, hr.RiskScoreName, hr.Final_Decision,
       hr.Has_Open_AML_SF_Case
FROM [BI_DB_dbo].[BI_DB_AML_Periodic_Review_MOP] mop
JOIN [BI_DB_dbo].[BI_DB_AML_Periodic_Review_HR] hr ON hr.CID = mop.CID
WHERE mop.MOP IN ('MoneyBookers', 'Neteller')
ORDER BY hr.Final_Decision DESC, mop.CID
```

---

## 8. Atlassian

No Confluence pages found specifically for this table. Part of the AML Periodic Review detection suite alongside `BI_DB_AML_Periodic_Review_AR`, `_HR`, and `_MR`. The AML Periodic Review process (authored in `SP_AML_Periodic_Review`) covers high-risk and medium-risk clients under enhanced due diligence. Contact the AML Analytics team for process documentation.
