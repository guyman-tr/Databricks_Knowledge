# BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start

> ~1.49M-row quarterly AML reporting table capturing start-of-quarter customer snapshots for FSA Seychelles (RegulationID=9) regulated customers. Populated by `SP_Q_AML_FSA_Report` via DELETE+INSERT per quarter. Population: IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3. Contains 11 quarterly snapshots (20231231–20260101) covering 234,560 distinct CIDs with demographic, compliance, activity, and equity attributes.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer (primary) via `SP_Q_AML_FSA_Report` |
| **Refresh** | Quarterly (DELETE+INSERT per quarter-start snapshot) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~1,489,727 (11 quarterly snapshots, 20231231–20260101) |

---

## 1. Business Meaning

`BI_DB_Q_AML_FSA_Report_start` captures start-of-quarter customer snapshots for the FSA Seychelles AML regulatory report. Each row represents one customer (CID) at one quarter-start date, providing a comprehensive view of their demographic profile, account status, investor classification, activity indicators, and equity positions.

The table is restricted to FSA Seychelles regulated customers (RegulationID=9) who are verified depositors (IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3). It is the start-of-period counterpart to `BI_DB_Q_AML_FSA_Report_end` — both are produced by the same `SP_Q_AML_FSA_Report`. The start snapshot uses `Dim_Range` filtered on `@StartDateID` (first day of the quarter), while the end snapshot uses `@EndDateID` (last day of the quarter). Together they enable quarter-over-quarter change analysis for regulatory compliance.

The SP also writes three companion end-of-period tables: `_end` (customer detail), `_end_Market_Value` (market value by instrument type), `_end_Positions` (per-CID trading volumes), and `_end_InvestorType` (aggregated trading by investor segment).

With 11 quarterly snapshots spanning Q4 2023 through Q1 2026, the table enables trend analysis for regulatory compliance metrics including PEP status, account closures/suspensions, investor type distribution, activity rates, and equity positions at the beginning of each reporting period.

---

## 2. Business Logic

### 2.1 Investor Type Classification

**What**: Mutually exclusive investor type flags based on customer country.
**Columns Involved**: `Is_Seychelles_Investor`, `Is_United_States_Investor`, `Is_EU_Investor`, `Is_Other_Country_Investor`
**Rules**:
- `Is_Seychelles_Investor` = 1 if CountryID = 181
- `Is_United_States_Investor` = 1 if CountryID = 219
- `Is_EU_Investor` = 1 if Dim_Country.EU = 1
- `Is_Other_Country_Investor` = 1 if none of the above apply (EU=0 AND CountryID<>219 AND CountryID<>181)

### 2.2 Account Status Flags

**What**: Derived flags for closed and suspended account detection.
**Columns Involved**: `Is_Closed_Account`, `Is_Suspended_Account`
**Rules**:
- `Is_Closed_Account` = 1 if PlayerStatusID IN (2, 4) AND PlayerStatusReasonID IN (3, 6, 40)
- `Is_Suspended_Account` = 1 if PlayerStatusID NOT IN (1, 2, 4, 5)

### 2.3 Seychelles Categorization

**What**: Binary categorization from BackOffice for FSA Seychelles regulatory classification.
**Columns Involved**: `SeychellesCategorization`
**Rules**:
- 'Advanced' if SeychellesCategorizationID = 2 (from External_etoro_BackOffice_Customer, Verified=1)
- 'Basic' otherwise (default)

### 2.4 Account Type Group

**What**: Classifies account holder type for regulatory reporting.
**Columns Involved**: `Account_Type_Group`
**Rules**:
- AccountTypeID = 1 → 'Natural Persons'
- AccountTypeID = 2 → 'Legal Entities'
- Otherwise → 'Other'

### 2.5 Age Group Bucketing

**What**: Age bucketed into standard demographic bands.
**Columns Involved**: `Age_Group`, `Age`
**Rules**:
- Age = DATEDIFF(YEAR, BirthDate, @Date) where @Date is the adjusted SP input
- Age_Group: '18-25', '26-35', '36-45', '46-55', '56-65', '66+', 'N/A' (if BirthDate is NULL or age < 18)

### 2.6 PEP Flag

**What**: Politically Exposed Person indicator from screening status.
**Columns Involved**: `Is_PEP`
**Rules**:
- Is_PEP = 1 if ScreeningStatusID = 3
- Is_PEP = 0 otherwise

### 2.7 Activity Flag

**What**: Customer activity indicator for the quarter.
**Columns Involved**: `Is_Active`, `OpenedOrClosedPos`, `DepositesOrCashout`
**Rules**:
- `OpenedOrClosedPos` = 1 if opened or closed any position during the quarter (from Dim_Position where OpenDateID or CloseDateID between @StartDateID and @EndDateID)
- `DepositesOrCashout` = 1 if any deposit or cashout during the quarter (from Fact_CustomerAction where ActionTypeID IN (7,8))
- `Is_Active` = 1 if either OpenedOrClosedPos = 1 OR DepositesOrCashout = 1

### 2.8 High Net Worth Flag

**What**: Identifies customers who self-reported net worth over $1M.
**Columns Involved**: `Is_High_Net_Worth`
**Rules**:
- Is_High_Net_Worth = 1 if Q11_AnswerID = 38 (Over $1M) in BI_DB_KYC_Panel
- Note: HNW lookup uses the end-of-period population (#pop_end) even for the start table

### 2.9 Equity Calculations

**What**: Customer equity position at quarter end.
**Columns Involved**: `UnrealizedEquity`, `RealizedEquity`
**Rules**:
- `UnrealizedEquity` = SUM(Amount + PositionPnL) from BI_DB_PositionPnL at @EndDateID. ISNULL → 0 for customers without positions.
- `RealizedEquity` = SUM(RealizedEquity) from V_Liabilities at @EndDateID. ISNULL → 0 for customers without liabilities.
- Note: Both equity columns are computed from end-of-period data even for the start snapshot.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no preferred join key. ~1.49M rows across 11 quarterly snapshots. Filter on `Report_Start_Date` for single-quarter analysis.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest quarter snapshot | `WHERE Report_Start_Date = (SELECT MAX(Report_Start_Date) FROM BI_DB_Q_AML_FSA_Report_start)` |
| PEP customer count by quarter | `SELECT Report_Start_Date, SUM(Is_PEP) FROM ... GROUP BY Report_Start_Date` |
| Active customer rate trend | `SELECT Report_Start_Date, AVG(CAST(Is_Active AS FLOAT)) FROM ... GROUP BY Report_Start_Date` |
| Investor type breakdown | `SELECT Report_Start_Date, SUM(Is_Seychelles_Investor), SUM(Is_EU_Investor), SUM(Is_United_States_Investor), SUM(Is_Other_Country_Investor) FROM ... GROUP BY Report_Start_Date` |
| High net worth with large equity | `WHERE Is_High_Net_Worth = 1 AND UnrealizedEquity > 100000` |
| Quarter-over-quarter change | `JOIN BI_DB_Q_AML_FSA_Report_end e ON s.CID = e.CID AND s.Report_Start_Date = e.Report_End_Date - quarter_offset` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `CID = RealCID` | Full customer profile |
| BI_DB_Q_AML_FSA_Report_end | `CID = CID` | Start vs end comparison for same customers |
| BI_DB_Q_AML_FSA_Report_end_Positions | `CID = CID` | Per-instrument trading volumes (end-of-quarter) |

### 3.4 Gotchas

- **Report_Start_Date is int, not date**: Stored as YYYYMMDD integer (e.g., 20260101). Use `CAST(CAST(Report_Start_Date AS VARCHAR) AS DATE)` for date functions.
- **Misspelled column**: `DepositesOrCashout` — note the typo "Deposites" (not "Deposits").
- **Multiple quarters in one table**: Always filter on `Report_Start_Date` to avoid mixing snapshots.
- **Equity uses end-of-period data**: UnrealizedEquity and RealizedEquity are computed from @EndDateID, not @StartDateID. This is a design choice in the SP — start-of-quarter demographic snapshot includes end-of-quarter equity.
- **HNW uses end-of-period population**: The High Net Worth lookup joins against #pop_end, meaning the HNW flag reflects end-of-period KYC answers applied to start-of-period customers.
- **UnrealizedEquity defaults to 0**: ISNULL wrapping means 0 = no open positions, not "equity is zero."
- **RealizedEquity defaults to 0**: Same ISNULL logic — 0 means no V_Liabilities record.
- **Is_Active combines two signals**: A customer can be "active" solely from a deposit/cashout with no trading activity.
- **Population is filtered**: Only FSA Seychelles (RegulationID=9), verified depositors. Do not assume all Seychelles customers are included.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Mapped from Fact_SnapshotCustomer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Regulation | varchar(250) | YES | Regulatory jurisdiction name. Always 'FSA Seychelles' in this table due to RegulationID=9 filter. Passthrough from Dim_Regulation.Name. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Regulation) |
| 3 | Country | varchar(250) | YES | Full country name in English. Unique per row. Passthrough from Dim_Country via CountryID. (Tier 1 — Dictionary.Country) |
| 4 | PlayerStatus | varchar(250) | YES | Human-readable restriction state label. Values: Normal, Block Deposit & Trading, etc. Passthrough from Dim_PlayerStatus.Name. (Tier 2 — SP_Q_AML_FSA_Report, Dim_PlayerStatus) |
| 5 | PlayerStatusReasons | varchar(250) | YES | Human-readable reason for the player status. Passthrough from Dim_PlayerStatusReasons.Name. (Tier 2 — SP_Q_AML_FSA_Report, Dim_PlayerStatusReasons) |
| 6 | PlayerStatusSubReasonName | varchar(250) | YES | Granular sub-reason beneath the primary status reason. Passthrough from Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName. (Tier 2 — SP_Q_AML_FSA_Report, Dim_PlayerStatusSubReasons) |
| 7 | EU | int | YES | Whether this country is a full EU member state. 1=EU member, 0=non-EU. Passthrough from Dim_Country.EU. Source: Ext_Dim_Country manual extension table. (Tier 3 — Ext_Dim_Country) |
| 8 | Desk | varchar(250) | YES | Sales/support desk assignment for this country. Passthrough from Dim_Country.Desk. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join. (Tier 3 — Ext_Dim_Country_Region_Desk) |
| 9 | Region | varchar(250) | YES | Marketing region label for this country. Passthrough from Dim_Country.Region. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 10 | RiskGroupID | int | YES | Customer risk group identifier from Fact_SnapshotCustomer. (Tier 2 — SP_Q_AML_FSA_Report, Fact_SnapshotCustomer) |
| 11 | SeychellesCategorization | varchar(250) | YES | FSA Seychelles regulatory categorization: 'Advanced' if SeychellesCategorizationID=2, else 'Basic'. Derived from External_etoro_BackOffice_Customer (Verified=1 filter). (Tier 2 — SP_Q_AML_FSA_Report, BackOffice.Customer) |
| 12 | Account_Type_Group | varchar(250) | YES | Account holder classification: 'Natural Persons' (AccountTypeID=1), 'Legal Entities' (AccountTypeID=2), or 'Other'. Derived from Fact_SnapshotCustomer.AccountTypeID. (Tier 2 — SP_Q_AML_FSA_Report, Dim_AccountType) |
| 13 | Account_Type | varchar(250) | YES | Specific account type name. Passthrough from Dim_AccountType.Name. (Tier 2 — SP_Q_AML_FSA_Report, Dim_AccountType) |
| 14 | Age_Group | varchar(250) | YES | Demographic age band: 18-25, 26-35, 36-45, 46-55, 56-65, 66+, or N/A. Computed from Dim_Customer.BirthDate relative to the SP @Date parameter. (Tier 2 — SP_Q_AML_FSA_Report) |
| 15 | Age | int | YES | Customer age in years at SP execution date. Computed as DATEDIFF(YEAR, BirthDate, @Date). (Tier 2 — SP_Q_AML_FSA_Report) |
| 16 | MifidCategorization | varchar(250) | YES | MiFID II investor categorization (Retail, Professional, Eligible Counterparty, Retail Pending). Passthrough from Dim_MifidCategorization.Name. (Tier 2 — SP_Q_AML_FSA_Report, Dim_MifidCategorization) |
| 17 | ScreeningStatus | varchar(250) | YES | AML screening status label. Passthrough from Dim_ScreeningStatus.Name. (Tier 2 — SP_Q_AML_FSA_Report, Dim_ScreeningStatus) |
| 18 | Is_PEP | int | YES | Politically Exposed Person flag. 1 if Dim_Customer.ScreeningStatusID=3, else 0. (Tier 2 — SP_Q_AML_FSA_Report, Dim_ScreeningStatus) |
| 19 | Is_Closed_Account | int | YES | Closed account flag. 1 if PlayerStatusID IN (2,4) AND PlayerStatusReasonID IN (3,6,40), else 0. (Tier 2 — SP_Q_AML_FSA_Report) |
| 20 | Is_Suspended_Account | int | YES | Suspended account flag. 1 if PlayerStatusID NOT IN (1,2,4,5), else 0. (Tier 2 — SP_Q_AML_FSA_Report) |
| 21 | Is_Seychelles_Investor | int | YES | Seychelles investor flag. 1 if CountryID=181, else 0. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Country) |
| 22 | Is_United_States_Investor | int | YES | United States investor flag. 1 if CountryID=219, else 0. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Country) |
| 23 | Is_EU_Investor | int | YES | EU investor flag. 1 if Dim_Country.EU=1, else 0. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Country) |
| 24 | Is_Other_Country_Investor | int | YES | Other country investor flag. 1 if not Seychelles (CountryID<>181), not US (CountryID<>219), and not EU (EU=0), else 0. (Tier 2 — SP_Q_AML_FSA_Report) |
| 25 | OpenedOrClosedPos | int | YES | Position activity flag. 1 if customer opened or closed any position during the quarter (OpenDateID or CloseDateID between @StartDateID and @EndDateID). Derived from Dim_Position. (Tier 2 — SP_Q_AML_FSA_Report, Dim_Position) |
| 26 | DepositesOrCashout | int | YES | Deposit/cashout activity flag. 1 if customer had any deposit or cashout during the quarter (ActionTypeID IN (7,8)). Note: column name contains typo ("Deposites"). Derived from Fact_CustomerAction. (Tier 2 — SP_Q_AML_FSA_Report, Fact_CustomerAction) |
| 27 | Is_Active | int | YES | Overall activity flag. 1 if OpenedOrClosedPos=1 OR DepositesOrCashout=1, else 0. Composite of position and monetary activity. (Tier 2 — SP_Q_AML_FSA_Report) |
| 28 | Is_High_Net_Worth | int | YES | High net worth flag. 1 if Q11_AnswerID=38 (Over $1M) in BI_DB_KYC_Panel, else 0. Note: lookup uses end-of-period population. (Tier 2 — SP_Q_AML_FSA_Report, BI_DB_KYC_Panel) |
| 29 | UnrealizedEquity | money | YES | Sum of unrealized equity (Amount + PositionPnL) from BI_DB_PositionPnL at quarter end date (@EndDateID). ISNULL defaults to 0 for customers without open positions. (Tier 2 — SP_Q_AML_FSA_Report, BI_DB_PositionPnL) |
| 30 | RealizedEquity | money | YES | Sum of realized equity from V_Liabilities at quarter end date (@EndDateID). ISNULL defaults to 0 for customers without liabilities record. (Tier 2 — SP_Q_AML_FSA_Report, V_Liabilities) |
| 31 | Report_Start_Date | int | YES | Quarter-start date as integer in YYYYMMDD format (e.g., 20260101). Identifies which quarterly snapshot this row belongs to. Note: earlier snapshots used quarter-end dates; later snapshots use quarter-start dates. (Tier 2 — SP_Q_AML_FSA_Report) |
| 32 | UpdateDate | datetime | NO | ETL execution timestamp. GETDATE() at SP execution time. All rows in a quarterly batch share the same value. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | rename (RealCID → CID) via Fact_SnapshotCustomer |
| Regulation | Dictionary.Regulation | Name | dim-lookup (RegulationID=9 filter) |
| Country | Dictionary.Country | Name | dim-lookup via Dim_Country |
| PlayerStatus | Dictionary.PlayerStatus | Name | dim-lookup via Dim_PlayerStatus |
| PlayerStatusReasons | Dictionary.PlayerStatusReasons | Name | dim-lookup via Dim_PlayerStatusReasons |
| PlayerStatusSubReasonName | Dictionary.PlayerStatusSubReasons | PlayerStatusSubReasonName | dim-lookup via Dim_PlayerStatusSubReasons |
| EU | Dim_Country | EU | passthrough (source: Ext_Dim_Country) |
| Desk | Dim_Country | Desk | passthrough (source: Ext_Dim_Country_Region_Desk) |
| Region | Dim_Country | Region | passthrough (source: Dictionary.MarketingRegion) |
| RiskGroupID | Fact_SnapshotCustomer | RiskGroupID | passthrough |
| SeychellesCategorization | BackOffice.Customer | SeychellesCategorizationID | CASE: 2='Advanced', else 'Basic' |
| Account_Type_Group | Dim_AccountType | AccountTypeID | CASE: 1='Natural Persons', 2='Legal Entities', else 'Other' |
| Account_Type | Dim_AccountType | Name | dim-lookup passthrough |
| Age_Group, Age | Customer.CustomerStatic | BirthDate | computed age bucketing |
| MifidCategorization | Dim_MifidCategorization | Name | dim-lookup passthrough |
| ScreeningStatus | Dim_ScreeningStatus | Name | dim-lookup passthrough |
| Is_PEP | Dim_ScreeningStatus | ScreeningStatusID | CASE: 3=1, else 0 |
| Is_Closed_Account | Dim_PlayerStatus, Dim_PlayerStatusReasons | PlayerStatusID, PlayerStatusReasonID | compound CASE |
| Is_Suspended_Account | Dim_PlayerStatus | PlayerStatusID | CASE: NOT IN (1,2,4,5)=1 |
| Is_Seychelles_Investor | Dim_Country | CountryID | CASE: 181=1 |
| Is_United_States_Investor | Dim_Country | CountryID | CASE: 219=1 |
| Is_EU_Investor | Dim_Country | EU | CASE: 1=1 |
| Is_Other_Country_Investor | (computed) | — | residual flag |
| OpenedOrClosedPos | Dim_Position | CID | activity check during quarter |
| DepositesOrCashout | Fact_CustomerAction | CID | activity check during quarter |
| Is_Active | (computed) | — | OR of OpenedOrClosedPos and DepositesOrCashout |
| Is_High_Net_Worth | BI_DB_KYC_Panel | Q11_AnswerID | CASE: 38=1 |
| UnrealizedEquity | BI_DB_PositionPnL | Amount, PositionPnL | SUM(Amount+PositionPnL) at @EndDateID |
| RealizedEquity | V_Liabilities | RealizedEquity | SUM at @EndDateID |
| Report_Start_Date | (computed) | — | @StartDateID = quarter-start YYYYMMDD integer |
| UpdateDate | (computed) | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (primary — quarterly snapshot, RegulationID=9)
DWH_dbo.Dim_Customer (HASH(RealCID))
DWH_dbo.Dim_Country (REPLICATE)
DWH_dbo.Dim_Regulation (REPLICATE)
DWH_dbo.Dim_PlayerStatus (REPLICATE)
DWH_dbo.Dim_PlayerStatusReasons (REPLICATE)
DWH_dbo.Dim_PlayerStatusSubReasons (REPLICATE)
DWH_dbo.Dim_AccountType (REPLICATE)
DWH_dbo.Dim_MifidCategorization (REPLICATE)
DWH_dbo.Dim_ScreeningStatus (REPLICATE)
BI_DB_dbo.External_etoro_BackOffice_Customer (SeychellesCategorization)
BI_DB_dbo.BI_DB_KYC_Panel (High Net Worth Q11)
BI_DB_dbo.BI_DB_PositionPnL (unrealized equity)
DWH_dbo.V_Liabilities (realized equity)
DWH_dbo.Dim_Position (position activity)
DWH_dbo.Fact_CustomerAction (deposit/cashout activity)
  |
  |-- SP_Q_AML_FSA_Report (quarterly DELETE+INSERT per Report_Start_Date)
  |   Step 1: Filter Fact_SnapshotCustomer for RegulationID=9, IsDepositor=1,
  |           IsValidCustomer=1, VerificationLevelID=3 at @StartDateID via Dim_Range
  |   Step 2: JOIN to 8+ dimension tables for demographic/status attributes
  |   Step 3: Compute investor type flags (Seychelles/US/EU/Other)
  |   Step 4: Compute account status flags (Closed/Suspended/PEP)
  |   Step 5: Compute activity flags from Dim_Position + Fact_CustomerAction
  |   Step 6: Compute equity from BI_DB_PositionPnL + V_Liabilities (@EndDateID)
  |   Step 7: Compute High Net Worth from BI_DB_KYC_Panel
  |   Step 8: DELETE + INSERT into target table by Report_Start_Date
  v
BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start (~1.49M rows, ROUND_ROBIN HEAP)
  |-- No UC target (Not_Migrated) --|
  v
(Quarterly FSA Seychelles AML regulatory start-of-quarter report)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Primary customer dimension |
| Country | DWH_dbo.Dim_Country (Name) | Country dimension lookup |
| EU, Desk, Region | DWH_dbo.Dim_Country | Geographic attributes |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus (Name) | Account restriction status |
| PlayerStatusReasons | DWH_dbo.Dim_PlayerStatusReasons (Name) | Status change reason |
| PlayerStatusSubReasonName | DWH_dbo.Dim_PlayerStatusSubReasons | Status sub-reason |
| Regulation | DWH_dbo.Dim_Regulation (Name) | Regulatory authority |
| Account_Type_Group, Account_Type | DWH_dbo.Dim_AccountType | Account type classification |
| MifidCategorization | DWH_dbo.Dim_MifidCategorization | MiFID II categorization |
| ScreeningStatus, Is_PEP | DWH_dbo.Dim_ScreeningStatus | AML screening status |
| SeychellesCategorization | BI_DB_dbo.External_etoro_BackOffice_Customer | Seychelles regulatory classification |
| Is_High_Net_Worth | BI_DB_dbo.BI_DB_KYC_Panel | KYC Q11 net worth answer |
| UnrealizedEquity | BI_DB_dbo.BI_DB_PositionPnL | Open position equity |
| RealizedEquity | DWH_dbo.V_Liabilities | Closed position equity |
| OpenedOrClosedPos | DWH_dbo.Dim_Position | Position activity |
| DepositesOrCashout | DWH_dbo.Fact_CustomerAction | Monetary activity |

### 6.2 Referenced By (other objects point to this)

| Consuming Object | Relationship |
|-----------------|-------------|
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end | Sibling table — same SP, end-of-quarter counterpart for same CID population |

---

## 7. Sample Queries

### 7.1 PEP Customer Count by Quarter

```sql
SELECT
    Report_Start_Date,
    COUNT(*) AS Total_Customers,
    SUM(Is_PEP) AS PEP_Count,
    CAST(SUM(Is_PEP) AS FLOAT) / COUNT(*) * 100 AS PEP_Pct
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start
GROUP BY Report_Start_Date
ORDER BY Report_Start_Date
```

### 7.2 Investor Type Distribution — Latest Quarter

```sql
SELECT
    Report_Start_Date,
    SUM(Is_Seychelles_Investor) AS Seychelles,
    SUM(Is_United_States_Investor) AS US,
    SUM(Is_EU_Investor) AS EU,
    SUM(Is_Other_Country_Investor) AS Other_Country
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start
WHERE Report_Start_Date = (SELECT MAX(Report_Start_Date) FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start)
GROUP BY Report_Start_Date
```

### 7.3 Start vs End Customer Count Comparison

```sql
SELECT
    s.Report_Start_Date,
    COUNT(DISTINCT s.CID) AS Start_CIDs,
    COUNT(DISTINCT e.CID) AS End_CIDs
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start s
LEFT JOIN BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end e
    ON s.CID = e.CID
GROUP BY s.Report_Start_Date
ORDER BY s.Report_Start_Date
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found specific to this table. The FSA Seychelles AML report cluster is documented through the sibling `_end` table and associated regulatory compliance Confluence pages.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 2 T1, 27 T2, 2 T3, 0 T4, 1 T5 | Elements: 32/32, Logic: 9/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start | Type: Table | Production Source: DWH_dbo.Fact_SnapshotCustomer via SP_Q_AML_FSA_Report*
