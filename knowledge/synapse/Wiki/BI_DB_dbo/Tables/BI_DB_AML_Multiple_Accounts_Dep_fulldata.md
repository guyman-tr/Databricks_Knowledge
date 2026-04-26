# BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep_fulldata

> 265K-row AML detection table providing full customer demographic and alert context for every customer who shares a deposit funding entity (FundingID) with at least one other verified eToro customer. The "detail" companion to BI_DB_AML_Multiple_Accounts_Dep — one row per (FundingID, CID) pair, enriched with customer profile, financials, and latest alert service record.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `DWH_dbo.Dim_Customer` enriched via multiple dimension tables; alert data from `External_AlertServiceDB_*` |
| **Refresh** | On-demand — SP_AML_Multiple_Accounts is not in the standard OpsDB SB_Daily schedule |
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

`BI_DB_AML_Multiple_Accounts_Dep_fulldata` is the **customer-level expansion** of the deposit-sharing AML detection. Where `BI_DB_AML_Multiple_Accounts_Dep` provides one row per FundingID group, this table provides one row per *customer* in each group — enabling AML analysts to immediately see the profile, financial status, and regulatory standing of every person sharing a suspicious deposit entity.

The table contains 265,006 rows covering the customers from all 116K+ FundingID groups. The customer profile is pulled from `DWH_dbo.Dim_Customer` and enriched with full dimension lookups (Regulation, Country, PlayerStatus, PlayerStatusReason, Club, EvMatchStatus), current financial position from `V_Liabilities` at the report date (@DateID), and the latest active alert from the Alert Service (one per CID, selected by most-recent ModificationDate).

**Key characteristics**:
- Population is restricted to `VerificationLevelID IN (2, 3)` — only partially or fully verified customers (distribution: VerificationLevelID=3: 85.6%, VerificationLevelID=2: 14.4%)
- Top regulation: CySEC (66%), FCA (17%), ASIC & GAML (7%), FSA Seychelles (4%)
- Top countries: Germany (16%), France (11%), UK (10%), Italy (8%), UAE (4%)
- Alert coverage: 38% of customers have a recorded alert (62% have no alert — NULL AlertType)

This table is the primary investigation starting point for the AML team's "multiple accounts" deposit workflow: identify the FundingID group in `_Dep`, then pull the full customer list from `_Dep_fulldata` to investigate individual accounts.

**PII notice**: Contains UserName, BirthDate, Gender, City, Zip, BuildingNumber — PII fields requiring access controls.

---

## 2. Business Logic

### 2.1 Population: Verified Depositors in Shared FundingID Groups

**What**: Only customers who appear in the BI_DB_AML_Multiple_Accounts_Dep FundingID set are included.

**Columns Involved**: `FundingID`, `CID`, `VerificationLevelID`

**Rules**:
- Starting from the Dep table's FundingID population, the SP joins back to Fact_BillingDeposit to get all CIDs that used those FundingIDs
- Same quality filters as Dep: VerificationLevelID ≥ 2, IsValidCustomer=1, IsDepositor=1
- Each (FundingID, CID) pair is one row — a customer can appear multiple times if they share multiple FundingIDs

### 2.2 Financial Position at Report Date

**What**: Customer's current financial position is joined from V_Liabilities at the SP's @Date parameter.

**Columns Involved**: `Liabilities`, `RealizedEquity`, `PositionPnL`, `TotalEquity`

**Rules**:
- Source: `DWH_dbo.V_Liabilities` at `@DateID` (computed from the @Date parameter passed to the SP)
- `Liabilities`: Total funds deposited minus withdrawals (net client balance)
- `RealizedEquity`: Realized trading profits/losses
- `PositionPnL`: Unrealized P&L on open positions
- `TotalEquity`: Liabilities + PositionPnL (total account value)
- NULL if V_Liabilities has no record for the CID at @DateID

### 2.3 Latest Alert Enrichment

**What**: Each customer is enriched with their most recent alert from the Alert Service.

**Columns Involved**: `AlertID`, `CreationDate`, `ModificationDate`, `AlertType`, `AlertTypeDescription`, `CategoryName`, `TriggerType`, `StatusType`, `StatusReason`

**Rules**:
- SP uses `ROW_NUMBER() OVER (PARTITION BY CID ORDER BY ModificationDate DESC) = 1` to select the single most recent alert per CID
- If the customer has no alert: all alert columns are NULL (62% of rows in current data)
- `StatusType` values: Active (32%), Clear (6%), Follow Up (<1%), NULL (62%)
- `CategoryName` values: eToroMoney (27%), KYC (5%), Risk (5%), AML (<1%), Cashouts (<1%), Trading (<0.1%), Deposits (<0.1%), NULL (62%)
- `AlertType` top values: AccountStatusChange (27%), HighRiskLogin (3%), KycRelations (1.6%), PossibleCompromisedAccount (0.9%)

### 2.4 Customer Status and Verification

**What**: Current account status and KYC level at ETL time.

**Columns Involved**: `PlayerStatus`, `PlayerStatusReason`, `PlayerStatusSubReasonName`, `VerificationLevelID`, `EvMatchStatusName`

**Rules**:
- `VerificationLevelID`: 2 = standard KYC verified; 3 = enhanced KYC / fully verified
- `PlayerStatus`: resolved to name from Dim_PlayerStatus (Normal, Warning, Limited, etc.)
- `PlayerStatusReason`, `PlayerStatusSubReasonName`: drill-down on why the status was applied
- `EvMatchStatusName`: Electronic Verification result (NoMatch, MatchFound, PossibleMatch, etc.) — from Dim_EvMatchStatus

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP with 265K rows. Scans are fast. For joins with large DWH tables, CTAS to a HASH-distributed temp table first.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All customers in a specific FundingID group | `WHERE FundingID = <id>` |
| High-risk customers with active alerts | `WHERE StatusType = 'Active' AND AlertType IS NOT NULL` |
| Customers with poor KYC in large groups | JOIN to _Dep ON FundingID, `WHERE dep.Group_Type = 'above 500' AND fd.VerificationLevelID = 2` |
| Financial risk exposure | `WHERE TotalEquity > 10000 AND StatusType = 'Active'` |
| CySEC customers in blocked funding groups | JOIN _Dep ON FundingID, `WHERE dep.IsBlocked = 1 AND fd.Regulation = 'CySEC'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep | ON FundingID | Get group-level summary (IsBlocked, Group_Type, Total_Users) |
| DWH_dbo.Dim_Customer | ON CID = RealCID | Additional customer attributes |
| DWH_dbo.Fact_BillingDeposit | ON CID = RealCID AND FundingID | Specific deposit transactions |

### 3.4 Gotchas

- **One CID per FundingID rule**: A customer who shares 3 different FundingIDs with others will appear 3 times in this table (one row per FundingID they shared).
- **Alert is latest only**: Alert columns reflect the most recent alert at ETL time. Historical alerts are not in this table.
- **Financial data is point-in-time**: Liabilities, RealizedEquity, PositionPnL, TotalEquity are snapshotted at @DateID (the SP's run date).
- **Not in daily ETL**: UpdateDate reflects the on-demand run date — may be stale.
- **PII columns**: UserName, BirthDate, Gender, City, Zip, BuildingNumber require access controls.

---

## 4. Elements

| Column | Type | Description | Source | Notes |
|--------|------|-------------|--------|-------|
| FundingID | int | Shared deposit funding entity ID — links back to BI_DB_AML_Multiple_Accounts_Dep | DWH_dbo.Fact_BillingDeposit | JOIN key to the Dep summary table |
| CID | int | eToro customer Real account ID | DWH_dbo.Dim_Customer (RealCID) | PK of this row when combined with FundingID |
| GCID | int | Global customer ID across all eToro platforms | DWH_dbo.Dim_Customer | |
| UserName | nvarchar | eToro account username | DWH_dbo.Dim_Customer | PII |
| BirthDate | date | Customer date of birth | DWH_dbo.Dim_Customer | PII |
| PhoneVerifiedName | nvarchar | Phone-verified display name from identity verification | DWH_dbo.Dim_Customer | PII |
| RegisteredReal | datetime | Real account registration date | DWH_dbo.Dim_Customer | |
| FirstDepositDate | datetime | Date of customer's first deposit | DWH_dbo.Dim_Customer | |
| VerificationLevelID | int | KYC verification level: 2=Verified, 3=Enhanced (full KYC) | DWH_dbo.Dim_Customer | Only 2 and 3 present in this table |
| Country | nvarchar(250) | Customer country of residence | DWH_dbo.Dim_Country (via Dim_Customer.CountryID) | Top: Germany (16%), France (11%), UK (10%) |
| Regulation | nvarchar(250) | Customer regulatory jurisdiction | DWH_dbo.Dim_Regulation (via Dim_Customer.RegulationID) | Top: CySEC (66%), FCA (17%) |
| PlayerStatus | nvarchar(250) | Current account status (Normal, Warning, Limited, etc.) | DWH_dbo.Dim_PlayerStatus | Resolved by name, not ID |
| PlayerStatusReason | nvarchar(250) | Reason for current PlayerStatus | DWH_dbo.Dim_PlayerStatus | NULL if status is Normal |
| PlayerStatusSubReasonName | nvarchar(250) | Sub-reason drill-down for current PlayerStatus | DWH_dbo.Dim_PlayerStatus | NULL if no sub-reason |
| Club | nvarchar(250) | eToro Club loyalty tier (Silver/Gold/Platinum/Diamond/Elite) | DWH_dbo.Dim_PlayerLevel (via Dim_Customer.PlayerLevelID) | |
| AffiliateID | int | Affiliate/referring partner ID for this customer | DWH_dbo.Dim_Customer | |
| City | nvarchar | Customer city of residence | DWH_dbo.Dim_Customer | PII |
| Zip | nvarchar | Customer postal code | DWH_dbo.Dim_Customer | PII |
| BuildingNumber | nvarchar | Customer address building number | DWH_dbo.Dim_Customer | PII |
| Gender | nvarchar | Customer gender | DWH_dbo.Dim_Customer | PII |
| EvMatchStatusName | nvarchar(250) | Electronic Verification match result (NoMatch, MatchFound, PossibleMatch, etc.) | DWH_dbo.Dim_EvMatchStatus (via Dim_Customer.EvMatchStatus) | NULL if not verified electronically |
| HasWallet | bit | Whether this customer has an eToro Wallet account | DWH_dbo.Dim_Customer | |
| AccountProgram | nvarchar | Account program classification | DWH_dbo.Dim_Customer | |
| Liabilities | decimal | Customer's total net liabilities (deposits minus withdrawals) at @DateID | DWH_dbo.V_Liabilities | Point-in-time at SP run date |
| RealizedEquity | decimal | Realized trading profit/loss at @DateID | DWH_dbo.V_Liabilities | Point-in-time |
| PositionPnL | decimal | Unrealized P&L on open positions at @DateID | DWH_dbo.V_Liabilities | Point-in-time |
| TotalEquity | decimal | Total account equity (Liabilities + PositionPnL) at @DateID | DWH_dbo.V_Liabilities | Point-in-time |
| AlertID | nvarchar | Latest Alert Service alert identifier for this CID | External_AlertServiceDB | NULL if no alert on record (62% of rows) |
| CreationDate | datetime | When the latest alert was created | External_AlertServiceDB | NULL if no alert |
| ModificationDate | datetime | When the latest alert was last modified | External_AlertServiceDB | Used for recency selection (most recent = this row) |
| AlertType | nvarchar(250) | Alert classification type (AccountStatusChange, HighRiskLogin, KycRelations, etc.) | External_AlertServiceDB | NULL for 62% of rows |
| AlertTypeDescription | nvarchar(250) | Human-readable description of AlertType | External_AlertServiceDB | NULL if no alert |
| CategoryName | nvarchar(250) | Alert category: eToroMoney, KYC, Risk, AML, Cashouts, Trading, Deposits | External_AlertServiceDB | NULL for 62% of rows |
| TriggerType | nvarchar(250) | What event triggered the alert | External_AlertServiceDB | NULL if no alert |
| StatusType | nvarchar(250) | Alert resolution status: Active, Clear, Follow Up | External_AlertServiceDB | NULL for 62% of rows |
| StatusReason | nvarchar(250) | Reason for current alert status | External_AlertServiceDB | NULL if no alert or no reason set |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline | ETL | GETDATE() at SP execution time |

---

## 5. Lineage

```
BI_DB_AML_Multiple_Accounts_Dep (FundingID population)
    → Fact_BillingDeposit JOIN on FundingID → get all CIDs
    → DWH_dbo.Dim_Customer JOIN → customer profile
    → DWH_dbo.Dim_Regulation, Dim_Country, Dim_PlayerStatus,
       Dim_PlayerLevel, Dim_EvMatchStatus → dimension lookups
    → DWH_dbo.V_Liabilities (at @DateID) → financial position
    → External_AlertServiceDB_* (ROW_NUMBER latest per CID) → alert data
    └─ SP_AML_Multiple_Accounts (Step 13) → BI_DB_AML_Multiple_Accounts_Dep_fulldata
```

See full column lineage: `BI_DB_AML_Multiple_Accounts_Dep_fulldata.lineage.md`

**UC**: Not_Migrated.

---

## 6. Relationships

| Related Table | Join Condition | Relationship |
|--------------|----------------|--------------|
| BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep | ON FundingID | Parent summary table (1:N) |
| DWH_dbo.Dim_Customer | ON CID = RealCID | Full customer master |
| DWH_dbo.V_Liabilities | ON CID at date | Financial position |

---

## 7. Sample Queries

```sql
-- All customers in a high-risk group (>500 shared users)
SELECT fd.FundingID, dep.Group_Type, dep.Total_Users, dep.IsBlocked,
       fd.CID, fd.UserName, fd.Country, fd.Regulation, fd.PlayerStatus,
       fd.TotalEquity, fd.AlertType, fd.StatusType
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Dep_fulldata] fd
JOIN [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Dep] dep ON dep.FundingID = fd.FundingID
WHERE dep.Group_Type = 'above 500'
ORDER BY dep.Total_Users DESC, fd.FundingID, fd.CID

-- CySEC customers with active alerts in blocked funding groups
SELECT fd.CID, fd.UserName, fd.Regulation, fd.PlayerStatus, fd.TotalEquity,
       fd.AlertType, fd.CategoryName, fd.StatusType, fd.ModificationDate
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Dep_fulldata] fd
JOIN [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Dep] dep ON dep.FundingID = fd.FundingID
WHERE dep.IsBlocked = 1
  AND fd.Regulation = 'CySEC'
  AND fd.StatusType = 'Active'
ORDER BY fd.ModificationDate DESC

-- Alert type breakdown for this population
SELECT AlertType, CategoryName, COUNT(*) AS cnt,
       COUNT(CASE WHEN StatusType = 'Active' THEN 1 END) AS active_cnt
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Dep_fulldata]
WHERE AlertType IS NOT NULL
GROUP BY AlertType, CategoryName
ORDER BY cnt DESC
```

---

## 8. Atlassian

No Confluence pages found specifically for this table. Part of the AML Multiple Accounts detection suite. SP authored by Lior Ben Dor (2023-11-13, migrated to Synapse). Contact the AML Analytics team for process documentation.
