# BI_DB_dbo.BI_DB_CID_Daily_NWA

## 1. Overview

Daily snapshot of **Non-Withdrawable Amount (NWA)** per customer. Each row captures one customer's financial position on one date: realized equity, open position PnL, margin, bonus credits, credit line, and NWA — alongside classification dimensions (label, country, regulation, MiFID category, player level/status). Used primarily by the **Client Money Reconciliation (CMR)** automation processes to calculate credit line exposure, bonus impact, and NWA across regulations.

**Row grain**: One CID per Date (only customers with ActualNWA <> 0 and valid customer status)

---

## 2. Business Context

NWA (Non-Withdrawable Amount) represents trading bonuses whose principal cannot be cashed out — funds the customer can trade with but not withdraw. This table provides the CMR team with a per-customer, per-day view of non-withdrawable balances alongside the customer's broader financial position.

**Key business rules**:
- **Population filter**: Only customers with `ActualNWA <> 0` AND the legacy `IsValidCustomer` logic: NOT(PlayerLevelID = 4 AND AccountTypeID <> 2) AND LabelID NOT IN (26, 30).
- **CreditLine from BI_DB_Daily_CreditLine**: LEFT JOIN — customers without credit lines get 0. This is a separate BI_DB table (SQL-level dependency).
- **German indicators**: `IsGermanResident` = CountryID 79 (Germany). `IsGermanBaFin` = exists in V_GermanBaFin for this date. These were added Nov 2020 for CMR automation.
- **Single-query SP**: Unlike most BI_DB SPs, this one uses a single SELECT/INSERT with dimension JOINs — no temp table chain.

**Consumers**: Multiple CMR automation SPs — `SP_CMR_Automation_ASIC_CIDCreditLineNWABonus`, `SP_CMR_Automation_EU_CreditLine`, `SP_CMR_Automation_ASIC_FSA_CIDCreditLineNWABonus`, `SP_CMR_Automation_MAS_Singapore_CIDCreditLineNWABonus`, `SP_CMR_Automation_CreditLine_And_Bonus`, `SP_CMR_Automation_ASIC_CreditLineNWABonus`, `SP_CMR_Automation_AzureBlob_CSV_ASIC_CIDCreditLineNWABonus`.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 20 |
| **Distribution** | ROUND_ROBIN |
| **Clustered Index** | Date ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Calendar date of the NWA snapshot. SP @Date parameter. Clustered index column — always filter on this. (Tier 2 — SP_CID_Daily_NWA, @Date) |
| 2 | CID | bigint | YES | Customer ID from V_Liabilities.CID. Only customers with ActualNWA <> 0 and valid customer status. (Tier 2 — SP_CID_Daily_NWA, V_Liabilities.CID) |
| 3 | Label | varchar(50) | YES | Brand label name from Dim_Label.Name via Fact_SnapshotCustomer.LabelID. Values: "eToro", etc. (Tier 2 — SP_CID_Daily_NWA, Dim_Label.Name) |
| 4 | Country | varchar(100) | YES | Country name from Dim_Country.Name via Fact_SnapshotCustomer.CountryID. Full name (e.g., "Spain", "United Kingdom"). (Tier 2 — SP_CID_Daily_NWA, Dim_Country.Name) |
| 5 | Region | varchar(100) | YES | Geographic region from Dim_Country.Region. Values: "Spain", "UK", "German", "Eastern Europe", "Australia", etc. Note: some region names match country names (e.g., Spain region = "Spain"). (Tier 2 — SP_CID_Daily_NWA, Dim_Country.Region) |
| 6 | AccountType | varchar(50) | YES | Account type from Dim_AccountType.Name via Fact_SnapshotCustomer.AccountTypeID. Values: "Private", "Corporate", etc. (Tier 2 — SP_CID_Daily_NWA, Dim_AccountType.Name) |
| 7 | Regulation | varchar(50) | YES | Regulation name from Dim_Regulation.Name. All regulations included (not filtered to specific ones). (Tier 2 — SP_CID_Daily_NWA, Dim_Regulation.Name) |
| 8 | RealizedEquity | money | YES | Cash balance after all realized gains and losses in USD. From V_Liabilities.RealizedEquity. ISNULL default 0. (Tier 2 — SP_CID_Daily_NWA, V_Liabilities.RealizedEquity) |
| 9 | PositionPnL | decimal(16,2) | YES | Unrealized profit/loss on open positions in USD. From V_Liabilities.PositionPnL. ISNULL default 0. (Tier 2 — SP_CID_Daily_NWA, V_Liabilities.PositionPnL) |
| 10 | TotalPositionsAmount | money | YES | Total margin allocated to open positions in USD. From V_Liabilities.TotalPositionsAmount. ISNULL default 0. (Tier 2 — SP_CID_Daily_NWA, V_Liabilities.TotalPositionsAmount) |
| 11 | ActualNWA | decimal(20,4) | YES | Non-Withdrawable Amount in USD — trading bonuses whose principal cannot be cashed out. From V_Liabilities.ActualNWA. ISNULL default 0. Filtered: only rows where ActualNWA <> 0 are inserted. (Tier 2 — SP_CID_Daily_NWA, V_Liabilities.ActualNWA) |
| 12 | BonusCredit | money | YES | Bonus/credit balance in USD. From V_Liabilities.BonusCredit. ISNULL default 0. Not withdrawable — affects equity but not NWA. (Tier 2 — SP_CID_Daily_NWA, V_Liabilities.BonusCredit) |
| 13 | CreditLine | money | YES | Total credit line amount in USD. From BI_DB_Daily_CreditLine.TotalCLAmount (LEFT JOIN). ISNULL default 0. Represents leveraged buying power extended to the customer. (Tier 2 — SP_CID_Daily_NWA, BI_DB_Daily_CreditLine.TotalCLAmount) |
| 14 | UpdateDate | datetime | YES | SP execution timestamp. GETDATE(). (Tier 3 — SP_CID_Daily_NWA, GETDATE()) |
| 15 | IsGermanResident | int | YES | Flag: 1 if customer's CountryID = 79 (Germany). Added Nov 2020 for CMR automation. (Tier 2 — SP_CID_Daily_NWA, Fact_SnapshotCustomer.CountryID) |
| 16 | IsGermanBaFin | int | YES | Flag: 1 if CID exists in V_GermanBaFin for this date. German BaFin regulatory indicator. (Tier 2 — SP_CID_Daily_NWA, V_GermanBaFin) |
| 17 | IsCreditReportValidCB | int | YES | Credit report validity flag. Direct from Fact_SnapshotCustomer.IsCreditReportValidCB. 1 = valid for CB reporting. (Tier 2 — SP_CID_Daily_NWA, Fact_SnapshotCustomer.IsCreditReportValidCB) |
| 18 | MifidCategorization | varchar(50) | YES | MiFID II client categorization from Dim_MifidCategorization.Name. Values: "Retail", "Retail Pending", "Professional", etc. EU regulatory classification. (Tier 2 — SP_CID_Daily_NWA, Dim_MifidCategorization.Name) |
| 19 | PlayerLevel | varchar(50) | YES | Customer tier/level from Dim_PlayerLevel.Name. Values: "Bronze", "Silver", "Gold", "Platinum", "Diamond", etc. (Tier 2 — SP_CID_Daily_NWA, Dim_PlayerLevel.Name) |
| 20 | PlayerStatus | varchar(50) | YES | Customer account status from Dim_PlayerStatus.Name. Values: "Normal", "Block Deposit & Trading", "Deposit Blocked", "Suspended", etc. (Tier 2 — SP_CID_Daily_NWA, Dim_PlayerStatus.Name) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| V_Liabilities | DWH_dbo | Primary — financial metrics (RealizedEquity, PositionPnL, ActualNWA, BonusCredit) |
| Fact_SnapshotCustomer | DWH_dbo | Customer dimension snapshot — classification IDs |
| Dim_Country | DWH_dbo | Country name + Region |
| Dim_Regulation | DWH_dbo | Regulation name |
| Dim_Label | DWH_dbo | Label name |
| Dim_AccountType | DWH_dbo | Account type name |
| Dim_MifidCategorization | DWH_dbo | MiFID categorization |
| Dim_PlayerLevel | DWH_dbo | Player level name |
| Dim_PlayerStatus | DWH_dbo | Player status name |
| Dim_Range | DWH_dbo | Date range resolution |
| BI_DB_Daily_CreditLine | BI_DB_dbo | Credit line amount (LEFT JOIN) |
| V_GermanBaFin | BI_DB_dbo | German BaFin indicator (LEFT JOIN) |

### Consumers

| Consumer | Purpose |
|----------|---------|
| SP_CMR_Automation_ASIC_CIDCreditLineNWABonus | ASIC CMR — credit line, NWA, bonus report |
| SP_CMR_Automation_ASIC_FSA_CIDCreditLineNWABonus | ASIC+FSA combined CMR |
| SP_CMR_Automation_MAS_Singapore_CIDCreditLineNWABonus | MAS Singapore CMR |
| SP_CMR_Automation_EU_CreditLine | EU credit line reconciliation |
| SP_CMR_Automation_CreditLine_And_Bonus | Cross-regulation credit line + bonus |
| SP_CMR_Automation_ASIC_CreditLineNWABonus | ASIC credit line + NWA + bonus |
| SP_CMR_Automation_AzureBlob_CSV_ASIC_CIDCreditLineNWABonus | CSV export to Azure Blob for ASIC |
| SP_CMR_Automation_*_CheckTableUpdate | Data freshness checks |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_CID_Daily_NWA |
| **ETL Pattern** | DELETE-INSERT by Date |
| **Grain** | One row per CID per Date |
| **Schedule** | Daily (SB_Daily, Priority 99 — FinanceReportSPS) |
| **Parameter** | @Date (DATE) |
| **Delete Scope** | `DELETE WHERE Date = @Date` |
| **History** | Accumulating daily snapshot |
| **Architecture** | Single SELECT/INSERT — no temp table chain |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **Always filter on Date** | Clustered index on Date. Scans without Date filter will be expensive. |
| **ROUND_ROBIN distribution** | No CID colocation. For CID-focused queries, filter on Date first, then CID. |
| **ActualNWA <> 0** | Only customers with non-zero NWA (active bonus balances) are present. If you need ALL customers, query V_Liabilities directly. |
| **Credit line may be 0** | CreditLine = 0 means either no credit line exists (LEFT JOIN miss) or the credit line is genuinely 0. Check BI_DB_Daily_CreditLine for the distinction. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Client Money Reconciliation |
| **Sub-domain** | NWA (Non-Withdrawable Amount) Monitoring |
| **Sensitivity** | Contains CID, financial balances — PII-adjacent |
| **Owner** | Finance / CMR team |
| **Quality Score** | 9.5 |

---

*Generated by DWH Semantic Documentation Pipeline — Batch 3, Object #3*
*Phases: P1 ✓ P2 ✓ P8 ✓ P9 ✓ P10 ✓ | Skipped: P3, P4, P5, P6, P7, P9B, P10.5 (single-query SP, dimension lookups resolved in SP)*
