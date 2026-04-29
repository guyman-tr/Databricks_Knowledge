# BI_DB_dbo.BI_DB_STP_Redeems

> 335K-row STP (Straight-Through Processing) redeem approval tracking table covering completed cryptocurrency/asset redeems from 2023-08-28 to present — recording per-redeem approval status across 5 operational teams (OPS, Risk, Trading, AML, Administrators), execution type (Auto/Manual), customer tier (PlayerLevel), regulation, and coin units. Sourced from External_etoro_Billing_Redeem + BackOffice_RedeemApproval via SP_H_BI_DB_STP_Redeems (Pavlina Masoura, Sep 2022). Daily DELETE+INSERT by LastModificationDate.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | External_etoro_Billing_Redeem + BackOffice_RedeemApproval → SP_H_BI_DB_STP_Redeems (Pavlina Masoura, 2022) |
| **Refresh** | Daily DELETE+INSERT by LastModificationDate range (SB_Daily, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated (not in Generic Pipeline mapping) |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_STP_Redeems tracks the approval workflow for completed cryptocurrency/asset redeem requests (STP = Straight-Through Processing). Each row represents one completed redeem (RedeemStatusID=8, "TransactionDone") with the approval decision from each operational team and the execution method.

The SP reads External table data from the production Billing.Redeem and BackOffice.RedeemApproval tables, filters to completed redeems (StatusID=8) modified on @Date, and enriches with:
- Per-team approval flags (OPS=UserGroupID 2, Risk=3, Trading=6, AML=36, Admins=1), excluding auto-approvals
- Overall approval type (Auto Approval vs Manually Approved)
- Execution approval (Auto if ManagerID=0 AND CashoutStatusID=3, else Manual)
- Customer PlayerLevel and Regulation from Dim_Customer + dimensions
- Approver manager name from Dim_Manager

Key facts:
- 335K total rows from 2023-08-28 to 2026-04-13
- Approval split: Auto 52% / Manual 48%
- Execution: Auto 48% / Manual 52%
- PlayerLevel distribution: Bronze (25%), Platinum+ (22%), Gold (19%), Platinum (15%), Silver (12%), Diamond (7%)
- Note: duplicate rows observed (same RedeemID appears multiple times with different UpdateDate — likely from multiple SP runs on overlapping date ranges)

---

## 2. Business Logic

### 2.1 Approval Flag Computation

**What**: Per-team manual approval indicators for each redeem.
**Columns Involved**: OPSApproved, RiskApproved, TradingApproved, AMLApproved, AmdinistratorsApproved
**Rules**:
- Each flag: MAX(CASE WHEN UserGroupID={N} AND Approved=1 AND Comment NOT IN ('Auto Approval') THEN 1 ELSE 0 END)
- UserGroupID mapping: 2=OPS, 3=Risk, 6=Trading, 36=AML, 1=Administrators
- Auto-approved redeems have all flags = 0 (excluded by the Comment filter)

### 2.2 Overall Approval Classification

**What**: Whether the redeem was auto-approved or manually approved.
**Columns Involved**: Approval
**Rules**:
- If RedeemApproval.Comment = 'Auto Approval' OR 'Cleared - Auto Approval' → use the comment text
- Otherwise → 'Manually Approved'
- In #FINAL: consolidated to 'Auto Approval' (if no manual approval record exists) or 'Manually Approved'

### 2.3 Execution Approval

**What**: Whether the withdrawal execution was automatic or manual.
**Columns Involved**: ExecutionApproval
**Rules**:
- From vWithdrawToFunding: ManagerID=0 AND CashoutStatusID=3 → 'Auto'
- Otherwise → 'Manual'

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no index optimization. Filter by LastModificationDate for date-based analysis.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Auto vs manual approval breakdown | `GROUP BY Approval` |
| Redeems requiring multi-team approval | `WHERE OPSApproved + RiskApproved + TradingApproved + AMLApproved > 1` |
| Redeem volume by player tier | `GROUP BY PlayerLevel` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Extended customer profile |

### 3.4 Gotchas

- **Duplicate rows**: Same RedeemID can appear multiple times with different UpdateDate values — likely from overlapping SP runs. Use DISTINCT on RedeemID for unique redeem counts.
- **Column name typo**: `AmdinistratorsApproved` is misspelled (should be Administrators). This is the DDL name — do not rename.
- **All approval flags = 0 for auto-approvals**: The Comment NOT IN ('Auto Approval') filter means auto-approved redeems show zero across all team flags even though they were technically approved.
- **Only TransactionDone redeems**: RedeemStatusID=8 filter means in-progress, rejected, or cancelled redeems are excluded.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Description | Tag Pattern |
|------|-------------|-------------|
| Tier 1 | Upstream wiki verbatim | `(Tier 1 — source)` |
| Tier 2 | SP code / DDL evidence | `(Tier 2 — SP)` |
| Tier 5 | ETL metadata | `(Tier 5 — ETL)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RedeemID | bigint | YES | Unique identifier for the redeem request from Billing.Redeem. Primary grain column. (Tier 2 — SP_H_BI_DB_STP_Redeems, External_etoro_Billing_Redeem.RedeemID) |
| 2 | CID | int | YES | Customer identifier who initiated the redeem request. (Tier 2 — SP_H_BI_DB_STP_Redeems, External_etoro_Billing_Redeem.CID) |
| 3 | AmountOnRequest | money | YES | USD amount requested for redemption as submitted by the customer. (Tier 2 — SP_H_BI_DB_STP_Redeems, External_etoro_Billing_Redeem.AmountOnRequest) |
| 4 | LastModificationDate | datetime | YES | Timestamp of the last status change on the redeem request. Used as the DELETE+INSERT partition key. (Tier 2 — SP_H_BI_DB_STP_Redeems, External_etoro_Billing_Redeem.LastModificationDate) |
| 5 | RedeemStatus | varchar(max) | YES | Display name of the redeem status. Always 'TransactionDone' in this table (filtered to RedeemStatusID=8). From Dim_RedeemStatus.DisplayName. (Tier 2 — SP_H_BI_DB_STP_Redeems, DWH_dbo.Dim_RedeemStatus.DisplayName) |
| 6 | OPSApproved | int | YES | 1 if Operations team (UserGroupID=2) manually approved, 0 otherwise. Excludes auto-approvals. (Tier 2 — SP_H_BI_DB_STP_Redeems, MAX CASE from BackOffice_RedeemApproval) |
| 7 | RiskApproved | int | YES | 1 if Risk team (UserGroupID=3) manually approved, 0 otherwise. Excludes auto-approvals. (Tier 2 — SP_H_BI_DB_STP_Redeems, MAX CASE from BackOffice_RedeemApproval) |
| 8 | TradingApproved | int | YES | 1 if Trading team (UserGroupID=6) manually approved, 0 otherwise. Excludes auto-approvals. (Tier 2 — SP_H_BI_DB_STP_Redeems, MAX CASE from BackOffice_RedeemApproval) |
| 9 | AMLApproved | int | YES | 1 if AML team (UserGroupID=36) manually approved, 0 otherwise. Excludes auto-approvals. (Tier 2 — SP_H_BI_DB_STP_Redeems, MAX CASE from BackOffice_RedeemApproval) |
| 10 | AmdinistratorsApproved | int | YES | 1 if Administrators (UserGroupID=1) manually approved, 0 otherwise. Excludes auto-approvals. Note: column name is misspelled in DDL ('Amdinistrators' instead of 'Administrators'). (Tier 2 — SP_H_BI_DB_STP_Redeems, MAX CASE from BackOffice_RedeemApproval) |
| 11 | Approval | varchar(max) | YES | Overall approval classification: 'Auto Approval' (no manual approval records exist) or 'Manually Approved' (at least one manual approval record). (Tier 2 — SP_H_BI_DB_STP_Redeems, CASE logic on BackOffice_RedeemApproval.Comment) |
| 12 | ExecutionApproval | varchar(max) | YES | Execution method: 'Auto' (ManagerID=0 AND CashoutStatusID=3 in vWithdrawToFunding) or 'Manual'. Independent from the approval classification. (Tier 2 — SP_H_BI_DB_STP_Redeems, External_etoro_Billing_vWithdrawToFunding) |
| 13 | PlayerLevel | varchar(max) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel via Dim_Customer.PlayerLevelID. (Tier 1 — Dictionary.PlayerLevel) |
| 14 | Regulation | varchar(max) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation via Dim_Customer.RegulationID. (Tier 1 — Dictionary.Regulation) |
| 15 | Units | decimal(18,10) | YES | Coin/asset units being redeemed. Added Mar 2023 for crypto redeem tracking. (Tier 2 — SP_H_BI_DB_STP_Redeems, External_etoro_Billing_Redeem.Units) |
| 16 | UpdateDate | datetime | YES | Row load timestamp set to GETDATE() at insert time. Not a business date. (Tier 5 — ETL metadata, GETDATE()) |
| 17 | Manager | varchar(max) | YES | Approving manager full name: Dim_Manager.FirstName + ' ' + LastName via RedeemApproval.ManagerID. Empty string when no manager assigned to the approval. Added Nov 2023. (Tier 2 — SP_H_BI_DB_STP_Redeems, DWH_dbo.Dim_Manager) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RedeemID | etoro.Billing.Redeem | RedeemID | Passthrough via External table |
| CID | etoro.Billing.Redeem | CID | Passthrough via External table |
| AmountOnRequest | etoro.Billing.Redeem | AmountOnRequest | Passthrough |
| LastModificationDate | etoro.Billing.Redeem | LastModificationDate | Passthrough |
| RedeemStatus | DWH_dbo.Dim_RedeemStatus | DisplayName | Dim-lookup via RedeemStatusID |
| OPSApproved | etoro.BackOffice.RedeemApproval | UserGroupID, Approved | MAX CASE UserGroupID=2 |
| RiskApproved | etoro.BackOffice.RedeemApproval | UserGroupID, Approved | MAX CASE UserGroupID=3 |
| TradingApproved | etoro.BackOffice.RedeemApproval | UserGroupID, Approved | MAX CASE UserGroupID=6 |
| AMLApproved | etoro.BackOffice.RedeemApproval | UserGroupID, Approved | MAX CASE UserGroupID=36 |
| AmdinistratorsApproved | etoro.BackOffice.RedeemApproval | UserGroupID, Approved | MAX CASE UserGroupID=1 |
| Approval | etoro.BackOffice.RedeemApproval | Comment | CASE on Comment + manual check |
| ExecutionApproval | etoro.Billing.vWithdrawToFunding | ManagerID, CashoutStatusID | CASE logic |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel | Name | Dim-lookup via Dim_Customer |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup via Dim_Customer |
| Units | etoro.Billing.Redeem | Units | Passthrough via External table |
| UpdateDate | ETL | GETDATE() | ETL timestamp |
| Manager | DWH_dbo.Dim_Manager | FirstName, LastName | Concatenation via RedeemApproval.ManagerID |

### 5.2 ETL Pipeline

```
etoro.Billing.Redeem (production redeem requests)
  |-- External_etoro_Billing_Redeem (External table) ---|
etoro.BackOffice.RedeemApproval (approval records)
  |-- External_etoro_BackOffice_RedeemApproval (External table) ---|
etoro.Billing.vWithdrawToFunding (withdrawal execution)
  |-- External_etoro_Billing_vWithdrawToFunding (External table) ---|
  + DWH_dbo.Dim_RedeemStatus (status display name)
  + DWH_dbo.Dim_Manager (approver name)
  + DWH_dbo.Dim_Customer (PlayerLevelID, RegulationID)
  + DWH_dbo.Dim_PlayerLevel (Name)
  + DWH_dbo.Dim_Regulation (Name)
  |-- SP_H_BI_DB_STP_Redeems @Date ---|
  |  Filter: RedeemStatusID=8 (TransactionDone)
  |  #DATA → #MANUALAPPROVAL → #FINAL
  |  DELETE by LastModificationDate range + INSERT
  v
BI_DB_dbo.BI_DB_STP_Redeems (335K rows, 2023-08-28 to present)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer profile |
| RedeemID | etoro.Billing.Redeem | Source redeem request |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Relationship |
|-------------------|-------------|
| Operations/compliance dashboards | Primary consumer (redeem approval monitoring) |

---

## 7. Sample Queries

### 7.1 Approval Breakdown by Player Level

```sql
SELECT PlayerLevel, Approval,
       COUNT(DISTINCT RedeemID) AS Redeems,
       SUM(AmountOnRequest) AS TotalAmount
FROM BI_DB_dbo.BI_DB_STP_Redeems
GROUP BY PlayerLevel, Approval
ORDER BY PlayerLevel, Approval
```

### 7.2 Multi-Team Manual Approvals

```sql
SELECT RedeemID, CID, AmountOnRequest, PlayerLevel, Regulation,
       OPSApproved, RiskApproved, TradingApproved, AMLApproved, AmdinistratorsApproved,
       (OPSApproved + RiskApproved + TradingApproved + AMLApproved + AmdinistratorsApproved) AS TeamsApproved
FROM BI_DB_dbo.BI_DB_STP_Redeems
WHERE Approval = 'Manually Approved'
  AND (OPSApproved + RiskApproved + TradingApproved + AMLApproved + AmdinistratorsApproved) >= 2
ORDER BY AmountOnRequest DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 2 T1, 13 T2, 0 T3, 0 T4, 1 T5 | Elements: 17/17, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_STP_Redeems | Type: Table | Production Source: External_etoro_Billing_Redeem via SP_H_BI_DB_STP_Redeems*
