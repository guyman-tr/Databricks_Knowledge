# BI_DB_dbo.BI_DB_Client_New_CompensationBreakdown

## 1. Overview

Daily breakdown of **compensation payments** made to customers, categorized by compensation type, regulation, and customer classification. Each row represents one CID's compensation of a specific type on one date — showing the total amount paid, the reason for compensation, and a rich set of customer classification dimensions for regulatory reporting and CMR automation.

**Row grain**: One CID × CompensationReasonID × classification dimensions per DateID

---

## 2. Business Context

This table is part of the `SP_Client_Balance_New` mega-SP (the same SP that produces BI_DB_Client_Balance_CID_Level_New and BI_DB_Client_Balance_Aggregate_Level_New). It isolates the compensation component of customer actions.

**Key business rules**:
- **Source**: Fact_CustomerAction filtered to ActionTypeID = 36 (compensation payment actions only). The compensation amount is the SUM of the action amounts.
- **Compensation types** (from Dim_CompensationReason): "Interest Payment", "Special Promotion", "Promotion - Leads", "Referral Bonus", "Copy Trading Compensation", etc. Each has a CompensationReasonID.
- **TransferDirection = 1 only**: The customer classification columns (AccountType, Country, etc.) come from `#CIDAgg` filtered to TransferDirection = 1 (incoming/"to regulation" direction). This means only the destination regulation's classification is captured.
- **DLT (Digital Ledger Technology)**: Tracks whether the CID is a DLT/blockchain user and whether a DLT platform transfer occurred on this date.
- **Tangany**: External crypto custody provider. TanganyStatus comes from an external dictionary table (`External_UserApiDB_Dictionary_TanganyStatus`).
- **US_State**: Only populated for US customers (CountryID = 219). 2-character state code from Dim_State_and_Province.

**Consumers**: Multiple CMR automation SPs — `SP_CMR_Automation_All_Regs_CompensationBreakDown`, `SP_CMR_Automation_US_CompensationBreakDown`, `SP_CMR_Automation_Seychelles_CompensationBreakDown`, `SP_CMR_Automation_EU_CompensationBreakDown`, `SP_CMR_Automation_AUS_CompensationBreakDown`, `SP_CMR_Automation_CompensationBreakdown_Staking`.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 31 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | DateID ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | bigint | YES | Customer ID who received the compensation. From Fact_CustomerAction.RealCID filtered to ActionTypeID = 36. (Tier 2 — SP_Client_Balance_New, Fact_CustomerAction.RealCID) |
| 2 | TransferDirection | int | YES | Direction of regulation transfer. 1 = incoming (to regulation). The classification columns are from the destination regulation only. (Tier 2 — SP_Client_Balance_New, #CIDAgg) |
| 3 | CompensationType | varchar(100) | YES | Compensation category name from Dim_CompensationReason.Name. Values: "Interest Payment", "Special Promotion", "Promotion - Leads", "Referral Bonus", etc. (Tier 2 — SP_Client_Balance_New, Dim_CompensationReason.Name) |
| 4 | AccountType | varchar(100) | YES | Account type: "Private" or "Corporate". From customer classification dimensions via #CIDAgg. (Tier 2 — SP_Client_Balance_New, Dim_AccountType) |
| 5 | Country | varchar(100) | YES | Customer country (full name). From Dim_Country via Fact_SnapshotCustomer. (Tier 2 — SP_Client_Balance_New, Dim_Country.Name) |
| 6 | MifidCategory | varchar(100) | YES | MiFID II client categorization. Values: "Retail", "Retail Pending", "Professional". (Tier 2 — SP_Client_Balance_New, Dim_MifidCategorization) |
| 7 | PlayerStatus | varchar(100) | YES | Customer account status. Values: "Normal", "Block Deposit & Trading", "Deposit Blocked", etc. (Tier 2 — SP_Client_Balance_New, Dim_PlayerStatus) |
| 8 | Regulation | varchar(100) | YES | Customer's current regulation. Values: "CySEC", "FCA", "ASIC", "FinCEN+FINRA", "BVI", "FSA", etc. (Tier 2 — SP_Client_Balance_New, Dim_Regulation) |
| 9 | IsCreditReportValidCB | int | YES | Credit report validity flag for CB reporting. 1 = valid. (Tier 2 — SP_Client_Balance_New, Fact_SnapshotCustomer.IsCreditReportValidCB) |
| 10 | DidRegulationTransfer | int | YES | Flag: 1 if CID transferred regulation on this date. From Fact_RegulationTransfer. (Tier 2 — SP_Client_Balance_New, Fact_RegulationTransfer) |
| 11 | DidCBValidTransfer | int | YES | Flag: 1 if CID's CB validity status changed on this date. (Tier 2 — SP_Client_Balance_New, #CIDAgg) |
| 12 | FromRegulation | varchar(100) | YES | Source regulation before transfer. Equals Regulation if no transfer occurred. (Tier 2 — SP_Client_Balance_New, Dim_Regulation) |
| 13 | ToRegulation | varchar(100) | YES | Target regulation after transfer. Equals Regulation if no transfer occurred. (Tier 2 — SP_Client_Balance_New, Dim_Regulation) |
| 14 | IsEtoroTradingCID | int | YES | Flag: 1 if this is an eToro internal trading/test account. Used to exclude from external reporting. (Tier 2 — SP_Client_Balance_New, #CIDAgg) |
| 15 | eToroTradingGroupUser | varchar(100) | YES | eToro group user classification. "NotEtoroGroupAccount" for regular customers. Internal accounts have specific group names. (Tier 2 — SP_Client_Balance_New, #CIDAgg) |
| 16 | IsGlenEagleAccount | int | YES | Flag: 1 if this is a Glen Eagle (partner/white-label) account. (Tier 2 — SP_Client_Balance_New, #CIDAgg) |
| 17 | CompensationAmount | decimal(18,6) | YES | Total compensation amount paid to this CID for this compensation type on this date in USD. SUM(CAST(Fact_CustomerAction.Amount AS DECIMAL(18,4))). (Tier 2 — SP_Client_Balance_New, Fact_CustomerAction.Amount) |
| 18 | DateID | int | YES | YYYYMMDD integer date. Clustered index column. SP @dateID parameter. (Tier 2 — SP_Client_Balance_New, @dateID) |
| 19 | UpdateDate | datetime | YES | SP execution timestamp. GETDATE(). (Tier 3 — SP_Client_Balance_New, GETDATE()) |
| 20 | IsGermanBaFin | int | YES | German BaFin regulatory flag. 1 if CID in V_GermanBaFin for this date. (Tier 2 — SP_Client_Balance_New, V_GermanBaFin) |
| 21 | Date | date | YES | Calendar date. SP @date parameter. (Tier 2 — SP_Client_Balance_New, @date) |
| 22 | YearMonth | int | YES | YYYYMM integer for month-level aggregation. Computed: CONVERT(VARCHAR(6),@date,112). (Tier 2 — SP_Client_Balance_New, computed) |
| 23 | YearQuarter | int | YES | YYYYQQ integer for quarter-level aggregation. Computed: YEAR(@date) * 100 + DATEPART(qq, @date). E.g., 202202 = Q2 2022. (Tier 2 — SP_Client_Balance_New, computed) |
| 24 | Year | int | YES | Calendar year. YEAR(@date). (Tier 2 — SP_Client_Balance_New, computed) |
| 25 | IsValidCustomer | int | YES | Legacy valid customer flag. From #CIDAgg. (Tier 2 — SP_Client_Balance_New, #CIDAgg) |
| 26 | MoveMoneyReason | varchar(20) | YES | Reason for the money movement from Dim_MoveMoneyReason. LEFT JOIN — may be NULL. (Tier 2 — SP_Client_Balance_New, Dim_MoveMoneyReason.MoveMoneyReason) |
| 27 | CompensationReasonID | int | YES | FK to Dim_CompensationReason. Numeric ID corresponding to CompensationType. Values: 57 (Interest Payment), 20 (Special Promotion), 94 (Promotion - Leads), etc. (Tier 2 — SP_Client_Balance_New, Fact_CustomerAction.CompensationReasonID) |
| 28 | TanganyStatus | varchar(20) | YES | Tangany crypto custody wallet status. From External_UserApiDB_Dictionary_TanganyStatus.Name via Dim_Customer.TanganyStatusID. NULL if customer has no Tangany integration. (Tier 2 — SP_Client_Balance_New, External_UserApiDB_Dictionary_TanganyStatus.Name) |
| 29 | IsDLTUser | int | YES | Flag: 1 if CID is a DLT (Digital Ledger Technology / blockchain) platform user. From #findDiffsDLT temp table. (Tier 2 — SP_Client_Balance_New, #findDiffsDLT) |
| 30 | DidDLTTransfer | int | YES | Flag: 1 if CID performed a DLT platform transfer on this date. (Tier 2 — SP_Client_Balance_New, #findDiffsDLT) |
| 31 | US_State | varchar(2) | YES | US state code (2 characters). Only populated for US customers (CountryID = 219). From Dim_State_and_Province.ShortName via Dim_Customer.RegionID. NULL for non-US. (Tier 2 — SP_Client_Balance_New, Dim_State_and_Province.ShortName) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| Fact_CustomerAction | DWH_dbo | Primary — compensation amounts (ActionTypeID = 36) |
| Dim_CompensationReason | DWH_dbo | Compensation type names |
| Fact_SnapshotCustomer | DWH_dbo | Customer classification (via #CIDAgg) |
| Dim_MoveMoneyReason | DWH_dbo | Move money reason |
| Dim_Customer | DWH_dbo | TanganyStatusID, RegionID for US state |
| External_UserApiDB_Dictionary_TanganyStatus | BI_DB_dbo | Tangany status name |
| Dim_State_and_Province | DWH_dbo | US state code |
| Fact_RegulationTransfer | DWH_dbo | Regulation transfer detection |
| V_GermanBaFin | BI_DB_dbo | German BaFin flag |

### Sibling Tables (same SP writes)

| Table | Status |
|-------|--------|
| BI_DB_Client_Balance_CID_Level_New | Documented (Batch 1) |
| BI_DB_Client_Balance_Aggregate_Level_New | Pending (170 cols — dedicated batch) |

### Consumers

| Consumer | Purpose |
|----------|---------|
| SP_CMR_Automation_All_Regs_CompensationBreakDown | Cross-regulation compensation breakdown |
| SP_CMR_Automation_US_CompensationBreakDown | US-specific compensation CMR |
| SP_CMR_Automation_EU_CompensationBreakDown | EU compensation CMR |
| SP_CMR_Automation_AUS_CompensationBreakDown | Australia compensation CMR |
| SP_CMR_Automation_Seychelles_CompensationBreakDown | Seychelles compensation CMR |
| SP_CMR_Automation_CompensationBreakdown_Staking | Staking-specific compensation |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_Client_Balance_New |
| **ETL Pattern** | DELETE-INSERT by DateID |
| **Grain** | One CID × CompensationReasonID × classification per DateID |
| **Schedule** | Daily (SB_Daily, Priority 99 — FinanceReportSPS) |
| **Delete Scope** | `DELETE WHERE DateID = @dateID` |
| **History** | Accumulating daily snapshot |
| **SP Size** | ~9,500 lines — writes 3 tables. CompensationBreakdown is produced near end (line 8750). |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Filter on DateID** | Clustered index. Always include DateID or Date filter. |
| **Use YearMonth/YearQuarter** | Pre-computed period columns for aggregation — more efficient than DATE functions. |
| **CompensationReasonID for joins** | Use the int ID for joins to Dim_CompensationReason, not the varchar CompensationType. |
| **US_State is sparse** | Only non-NULL for US customers (CountryID = 219). Filter with `US_State IS NOT NULL` for US analysis. |
| **TanganyStatus is sparse** | Only populated for crypto-related customers with Tangany integration. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Client Money Reconciliation |
| **Sub-domain** | Compensation Payments Breakdown |
| **Sensitivity** | Contains CID, compensation amounts — PII-adjacent, financial |
| **Owner** | Finance team |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline — Batch 3, Object #5*
*Phases: P1 ✓ P2 ✓ P8 ✓ P9 ✓ P10 ✓ | Skipped: P3, P4, P5, P6, P7, P9B, P10.5 (multi-source, shared SP)*
