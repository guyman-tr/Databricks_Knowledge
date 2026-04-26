# BI_DB_dbo.BI_DB_CopyDailyData

| Property | Value |
|----------|-------|
| Schema | BI_DB_dbo |
| Object | BI_DB_CopyDailyData |
| Type | Table |
| Rows | Append-mode historical table (one batch per @date; volume grows daily) |
| Distribution | ROUND_ROBIN |
| Index | CLUSTERED INDEX(CID ASC) |
| Production Source | DWH_dbo.Fact_SnapshotCustomer (PI + Portfolio population) |
| Writer SP | BI_DB_dbo.SP_CopyDailyData |
| Refresh Cadence | Daily DELETE(WHERE Date=@date) + INSERT — append-mode, preserves history |
| UC Target | _Not_Migrated |
| Batch | 74 |
| Documented | 2026-04-23 |

---

## 1. Business Meaning

Daily per-PI and per-Portfolio-account performance snapshot. Each row represents one **Popular Investor (PI) or Portfolio account** on a specific `Date`, capturing their identity, PI tier, equity composition, AUM, copier count, commission earned, mirror flow activity (MIMO), and risk metrics.

The table is **append-mode** — each daily load adds rows for `Date=@date` without touching prior history. It is the primary input for PI performance dashboards, tier-change analysis, and account manager reporting. Coverage includes:
- **PIs**: Active Popular Investors (GuruStatusID >= 2, IsValidCustomer=1)
- **Portfolio accounts**: Accounts with AccountTypeID=9

Population is derived from `DWH_dbo.Fact_SnapshotCustomer` joined to `DWH_dbo.Dim_Range` to find which customers were active on the reporting date.

**Known column typos in DDL**: `CurrenyEquity` (→ CurrentEquity/CurrencyEquity), `ProtfoilioType` (→ PortfolioType), `MifidCatigorization` (→ MifidCategorization), `DaysInCurrnetStatus` (→ DaysInCurrentStatus). These are legacy column names and cannot be renamed without pipeline changes.

---

## 2. Business Logic & Derivation Rules

### Population Filter
```
Fact_SnapshotCustomer JOIN Dim_Range
WHERE (GuruStatusID >= 2 AND IsValidCustomer = 1) OR AccountTypeID = 9
AND @date_int BETWEEN Dim_Range.FromDateID AND Dim_Range.ToDateID
```
Uses `Dim_Range` date-range semantics (SCD-style validity windows) rather than a direct date column.

### Risk Score (`LastNightRiskScore`)
10-band volatility-to-score mapping from `DWH_dbo.V_Liabilities.StandardDeviation`:

| StandardDeviation Range | Score |
|------------------------|-------|
| < 0.0011 | 1 |
| < 0.0024 | 2 |
| < 0.0040 | 3 |
| < 0.0055 | 4 |
| < 0.0079 | 5 |
| < 0.0111 | 6 |
| < 0.0158 | 7 |
| < 0.0316 | 8 |
| < 0.0475 | 9 |
| >= 0.0475 | 10 |
| No match / NULL | 0 |

### Equity Decomposition (from `DWH_dbo.V_Liabilities`)

| Column | Formula |
|--------|---------|
| TotalEquity | Liabilities + ActualNWA |
| CurrenyEquity | TotalPositionsAmount + PositionPnL (typo: should be CurrentEquity) |
| PI_CopyAUM | AUM + CopyPositionPnL |
| PI_ManualStocks | TotalStockManualPosition + ManualStockPositionPnL |
| PI_ManualCrypto | TotalCryptoManualPosition + ManualCryptoPositionPnL |

**Manual trading estimate** (comment in SP): `ManualTrading ≈ TotalEquity − PI_CopyAUM − PI_ManualStocks − PI_ManualCrypto − Credit − InProcessCashouts`

### Commission Accumulation
**Accumulates from 2011-01-01** (hardcoded `@start_date = '20110101'`) to `@date`. Multi-condition logic per position:
- Position opened AND closed within window: `ISNULL(FullCommissionOnClose, CommissionOnClose)`
- Position opened within window but still open: `ISNULL(FullCommission, Commission)`
- Position closed within window but opened before: `ISNULL(FullCommissionOnClose - FullCommission, CommissionOnClose - Commission)`

### MIMO (Mirror In / Mirror Out) from `Fact_CustomerAction` — DateID = @date only
| Column | Action Types | Logic |
|--------|-------------|-------|
| MI | 15 (Mirror In), 17 (New Mirror) | SUM(-Amount) |
| MO | 16 (Mirror Out), 18 (UnMirror) | SUM(Amount) |
| netMI | 15, 16, 17, 18 | SUM(-Amount) net |
| NewMirror | 17 | COUNT of new copy-start events |
| UnMirror | 18 | COUNT of copy-stop events |

### DaysInCurrnetStatus (typo for DaysInCurrentStatus)
Finds the first date the PI entered their current GuruStatus tier by examining status-change transitions in `Fact_SnapshotCustomer`. Uses two branches:
1. **Status has changed before**: MIN(FromDateID) after the last status transition
2. **Status has never changed**: MIN(FromDateID) in Fact_SnapshotCustomer for the CID

### LastContactDate
Most recent `Phone_Call_Succeed__c` or `Completed_Contact_Email__c` action in `BI_DB_UsageTracking_SF`, where `CreatedByManagerID = ManagerID` (manager-matched contact). Sentinel: `ISNULL(CreatedDate, '1900-01-01')` — use `> '1900-01-01'` to filter for actual contacts.

### PI_Level_Previous
Yesterday's GuruStatusName from `Fact_SnapshotCustomer` at `@date - 1`. NULL if the PI had no prior snapshot record.

### PnL Section (Commented Out)
The `--,[PnL]` column is in the SP's INSERT column list but commented out. The `#PnL` calculation block is also commented. This column does NOT exist in the table.

---

## 3. Query Advisory

- **ROUND_ROBIN distributed** — filter on `Date` or `DateID` for efficiency; joins on `CID` will trigger data movement.
- **Append-mode table** — always filter by `Date` or `DateID`. Without a date filter, the query scans all history.
- **`commission` accumulates from 2011-01-01** — not a daily delta. Do not SUM across dates; each row already contains the cumulative figure for that PI.
- **`LastContactDate = '1900-01-01'`** means no contact recorded (sentinel, not a real date).
- **`LastNightRiskScore = 0`** means no V_Liabilities row or StandardDeviation was NULL.
- **`PI_Level_Previous` is NULL** for PIs without a prior day's record (e.g., new PIs).
- **`CurrenyEquity`** (typo) = `TotalPositionsAmount + PositionPnL` (current open position value including unrealized P&L). Do NOT confuse with `TotalEquity`.
- **`Language` is char(500)** — grossly over-provisioned; actual language names are short (< 30 chars). RTRIM() if needed.
- **`Country` and `Region` are varchar(500)** — similarly over-provisioned.
- **`CopyType`**: 'Portfolio' for AccountTypeID=9, 'PI' for all others.
- **Duplicate-run safety**: DELETE WHERE Date=@date before INSERT ensures idempotent loads.

---

## 4. Elements

| Column | Nullable | Type | Description |
|--------|----------|------|-------------|
| CID | NOT NULL | int | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic via Fact_SnapshotCustomer) |
| UserName | NULL | varchar(20) | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — DWH_dbo.Dim_Customer via Customer.CustomerStatic) |
| ID | NOT NULL | uniqueidentifier | System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). (Tier 1 — DWH_dbo.Dim_Customer via Customer.CustomerStatic) |
| Language | NULL | char(500) | Language display name. UNIQUE constraint. Used in back-office language selectors and reporting. NOTE: char(500) is over-provisioned — RTRIM() before use. (Tier 1 — DWH_dbo.Dim_Language via Dictionary.Language) |
| Country | NULL | varchar(500) | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 — DWH_dbo.Dim_Country via Dictionary.Country) |
| Region | NULL | nvarchar(500) | Geographic region grouping for Country. Used in regional reporting aggregations. (Tier 2 — DWH_dbo.Dim_Country) |
| Manager | NULL | nvarchar(500) | Account manager display name: FirstName + ' ' + LastName from Dim_Manager. (Tier 2 — DWH_dbo.Dim_Manager) |
| Gender | NULL | char(1) | Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. Used in LinkedAccountHash1. (Tier 1 — DWH_dbo.Dim_Customer via Customer.CustomerStatic) |
| GuruStatusID | NULL | smallint | eToro Popular Investor/Guru program status — whether the customer is an active copy trading strategy provider. FK to Dictionary.GuruStatus. Values: 0=No, 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected. (Tier 1 — DWH_dbo.Dim_Customer via BackOffice.Customer) |
| PI_Level | NULL | varchar(50) | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. (Tier 1 — DWH_dbo.Dim_GuruStatus via Dictionary.GuruStatus) |
| MifidCatigorization | NULL | varchar(50) | Human-readable MiFID II classification label. Column name is a typo (should be MifidCategorization). MiFID II client tiers: 0=None (non-EU), 1=Retail, 2=Professional, 3=Elective Professional, 4=Retail Pending, 5=Pending. (Tier 1 — DWH_dbo.Dim_MifidCategorization via Dictionary.MifidCategorization) |
| Registered | NULL | datetime | Account registration date (renamed from Dim_Customer.RegisteredReal). Default=getdate() at registration. (Tier 1 — DWH_dbo.Dim_Customer via Customer.CustomerStatic) |
| FirstDepositDate | NULL | datetime | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 — DWH_dbo.Dim_Customer via SP_Dim_Customer) |
| Club | NULL | varchar(500) | Tier display name from Dim_PlayerLevel: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. (Tier 1 — DWH_dbo.Dim_PlayerLevel via Dictionary.PlayerLevel) |
| CopyType | NOT NULL | varchar(9) | PI category: 'Portfolio' for AccountTypeID=9 (Copy Portfolio accounts), 'PI' for all other active Popular Investors. (Tier 2 — derived from Fact_SnapshotCustomer.AccountTypeID) |
| ProtfoilioType | NULL | varchar(50) | Portfolio fund type name from Dim_FundType. Column name is a typo (should be PortfolioType). NULL for PI accounts. (Tier 2 — DWH_dbo.Dim_FundType via Dim_Fund) |
| AffiliateAccount | NULL | int | Affiliate (partner) ID under which the customer was acquired (renamed from Dim_Customer.AffiliateID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 — DWH_dbo.Dim_Customer via Customer.CustomerStatic) |
| Acc_RiskIndex | NULL | int | Account-level risk classification index from BI_DB_User_Segment_Snapshot as of @date. (Tier 2 — BI_DB_dbo.BI_DB_User_Segment_Snapshot) |
| LastNightRiskScore | NOT NULL | int | Portfolio volatility score 1–10 mapped from V_Liabilities.StandardDeviation using 10-band thresholds. 0 = no V_Liabilities record or StandardDeviation is NULL. Higher score = higher portfolio volatility. (Tier 2 — DWH_dbo.V_Liabilities.StandardDeviation) |
| TotalEquity | NULL | decimal(23,4) | PI's total equity: Liabilities + ActualNWA from V_Liabilities. Represents total account value including liabilities. (Tier 2 — DWH_dbo.V_Liabilities) |
| CurrenyEquity | NULL | decimal(20,4) | Current open-position equity: TotalPositionsAmount + PositionPnL. Column name is a typo (should be CurrentEquity). Different from TotalEquity — excludes cash, includes unrealized P&L. (Tier 2 — DWH_dbo.V_Liabilities) |
| RealizedEquity | NULL | money | Realized equity from closed positions. Source: V_Liabilities.RealizedEquity. (Tier 2 — DWH_dbo.V_Liabilities) |
| TotalPositionsAmount | NULL | money | Total invested amount across all open positions (excluding P&L). Source: V_Liabilities.TotalPositionsAmount. (Tier 2 — DWH_dbo.V_Liabilities) |
| Credit | NULL | money | Credit balance (bonus funds) in the account. Source: V_Liabilities.Credit. (Tier 2 — DWH_dbo.V_Liabilities) |
| PI_CopyAUM | NULL | decimal(20,4) | Copy-trading AUM: V_Liabilities.AUM + V_Liabilities.CopyPositionPnL. Total value managed through copy relationships. (Tier 2 — DWH_dbo.V_Liabilities) |
| PI_ManualStocks | NULL | decimal(20,4) | PI's manually-managed stock portfolio: TotalStockManualPosition + ManualStockPositionPnL. (Tier 2 — DWH_dbo.V_Liabilities) |
| PI_ManualCrypto | NULL | decimal(20,4) | PI's manually-managed crypto portfolio: TotalCryptoManualPosition + ManualCryptoPositionPnL. (Tier 2 — DWH_dbo.V_Liabilities) |
| InProcessCashouts | NULL | money | Pending withdrawal amounts not yet settled. Source: V_Liabilities.InProcessCashouts. (Tier 2 — DWH_dbo.V_Liabilities) |
| NumOfCopiers | NULL | int | Number of valid depositor customers currently copying this PI as of @date. Source: COUNT(*) from etoroGeneral_History_GuruCopiers. (Tier 2 — general.etoroGeneral_History_GuruCopiers) |
| CopyAUM | NULL | money | Total AUM managed by this PI through copy relationships: ISNULL(SUM(Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL), 0). Source: etoroGeneral_History_GuruCopiers. (Tier 2 — general.etoroGeneral_History_GuruCopiers) |
| Date | NULL | date | Reporting date (the business day this snapshot covers = @date = GETDATE()-1). (Tier 2 — ETL parameter) |
| DateID | NULL | int | Integer date key: CONVERT(VARCHAR(8), @date, 112) — YYYYMMDD format. (Tier 2 — derived from Date) |
| DaysAsPI | NULL | int | Number of days since this customer first achieved PI status (GuruStatusID >= 2): DATEDIFF(DAY, MIN(FullDate), @date) from Fact_SnapshotCustomer. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| commission | NULL | money | Cumulative copy commissions earned by this PI since 2011-01-01 through @date. Multi-condition formula across open, closed, and straddling positions via Dim_Position+Dim_Mirror. NOTE: not a daily delta — each row is cumulative. (Tier 2 — DWH_dbo.Dim_Position via Dim_Mirror) |
| MI | NULL | decimal(38,2) | Money In for @date: SUM(-Amount) for mirror-in flows (ActionTypeID 15=Mirror In, 17=New Mirror) from Fact_CustomerAction. (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| MO | NULL | decimal(38,2) | Money Out for @date: SUM(Amount) for mirror-out flows (ActionTypeID 16=Mirror Out, 18=UnMirror) from Fact_CustomerAction. (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| netMI | NULL | decimal(38,2) | Net mirror flow for @date: SUM(-Amount) for all ActionTypeID IN (15,16,17,18) from Fact_CustomerAction. Positive = net inflow, negative = net outflow. (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| NewMirror | NULL | int | Number of new copy-start events on @date (ActionTypeID=17) from Fact_CustomerAction. (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| UnMirror | NULL | int | Number of copy-stop events on @date (ActionTypeID=18) from Fact_CustomerAction. (Tier 2 — DWH_dbo.Fact_CustomerAction) |
| DaysInCurrnetStatus | NULL | int | Days since the PI entered their current GuruStatus tier. Column name is a typo (should be DaysInCurrentStatus). Computed from Fact_SnapshotCustomer status-change transitions. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| UpdateDate | NOT NULL | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Propagation) |
| CopyPnL | NULL | int | Copiers' unrealized P&L attributed to this PI: ISNULL(SUM(PnL+DetachedPosInvestment+Dit_PnL), 0) from etoroGeneral_History_GuruCopiers. (Tier 2 — general.etoroGeneral_History_GuruCopiers) |
| LastContactDate | NULL | datetime | Most recent successful manager contact (phone call or email) recorded in Salesforce for this PI, where contact was by the PI's own account manager. Sentinel: '1900-01-01' = no contact on record. (Tier 2 — BI_DB_dbo.BI_DB_UsageTracking_SF) |
| PI_Level_Previous | NULL | varchar(50) | PI tier name (GuruStatusName) as of @date - 1 day. Used to detect tier changes. NULL if no prior-day snapshot exists. (Tier 2 — DWH_dbo.Dim_GuruStatus via DWH_dbo.Fact_SnapshotCustomer) |

---

## 5. Lineage

### 5.1 Source Objects

| Source | Usage |
|--------|-------|
| DWH_dbo.Fact_SnapshotCustomer + Dim_Range | Population filter (PIs + Portfolio), DaysAsPI, DaysInCurrnetStatus |
| DWH_dbo.Dim_Customer | UserName, ID, Gender, Registered, FirstDepositDate, AffiliateAccount |
| DWH_dbo.Dim_Language | Language name lookup |
| DWH_dbo.Dim_Country | Country name, Region lookup |
| DWH_dbo.Dim_Manager | Manager composite name |
| DWH_dbo.Dim_GuruStatus | PI_Level (today), PI_Level_Previous (yesterday) |
| DWH_dbo.Dim_PlayerLevel | Club (tier name) |
| DWH_dbo.Dim_MifidCategorization | MifidCatigorization label |
| DWH_dbo.Dim_Fund + Dim_FundType | ProtfoilioType for Portfolio accounts |
| DWH_dbo.V_Liabilities | All equity, AUM, credit, position, and risk columns |
| DWH_dbo.Dim_Mirror + Dim_Position | commission accumulation |
| DWH_dbo.Fact_CustomerAction | MI, MO, netMI, NewMirror, UnMirror |
| general.etoroGeneral_History_GuruCopiers | NumOfCopiers, CopyAUM, CopyPnL |
| BI_DB_dbo.BI_DB_User_Segment_Snapshot | Acc_RiskIndex |
| BI_DB_dbo.BI_DB_UsageTracking_SF | LastContactDate |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer JOIN Dim_Range → @date population (PIs + Portfolios)
  |
  +--> DWH_dbo.Dim_Customer, Dim_Language, Dim_Country, Dim_Manager, Dim_GuruStatus,
  |    Dim_PlayerLevel, Dim_MifidCategorization, Dim_Fund, Dim_FundType
  |    → #basicdata (identity + equity + copier aggregates)
  |
  +--> DWH_dbo.Fact_SnapshotCustomer (DaysAsPI)
  +--> DWH_dbo.Dim_Position + Dim_Mirror (commission since 2011-01-01)
  +--> DWH_dbo.Fact_CustomerAction (MIMO for @date)
  +--> DWH_dbo.Fact_SnapshotCustomer transitions (DaysInCurrnetStatus)
  +--> BI_DB_dbo.BI_DB_UsageTracking_SF (LastContactDate)
  |
  v
SP_CopyDailyData — DELETE(Date=@date) + INSERT (append-mode)
  |
  v
BI_DB_dbo.BI_DB_CopyDailyData (ROUND_ROBIN, CLUSTERED INDEX(CID))
  |
  v
UC Target: _Not_Migrated (not in Generic Pipeline)
```

---

## 6. Relationships & Cross-References

| Related Object | Relationship |
|----------------|-------------|
| BI_DB_dbo.BI_DB_User_Segment_Snapshot | Source of Acc_RiskIndex; joined on RealCID and Date. |
| BI_DB_dbo.BI_DB_UsageTracking_SF | Source of LastContactDate; filtered to PI's account manager and successful contact types. |
| DWH_dbo.Fact_SnapshotCustomer | Primary population source and basis for DaysAsPI, DaysInCurrnetStatus. |
| DWH_dbo.V_Liabilities | Source of all equity and financial position columns. |
| DWH_dbo.Fact_CustomerAction | Source of all MIMO columns (MI, MO, netMI, NewMirror, UnMirror). |
| general.etoroGeneral_History_GuruCopiers | Source of copier metrics (NumOfCopiers, CopyAUM, CopyPnL). |

---

## 7. Sample Queries

```sql
-- PI daily snapshot for a specific date (filter required)
SELECT CID, UserName, PI_Level, Country, Manager,
       TotalEquity, PI_CopyAUM, NumOfCopiers, CopyAUM,
       LastNightRiskScore, DaysAsPI, DaysInCurrnetStatus
FROM [BI_DB_dbo].[BI_DB_CopyDailyData]
WHERE DateID = 20260401
ORDER BY CopyAUM DESC;

-- Detect tier changes (PI_Level changed vs prior day)
SELECT CID, UserName, Date, PI_Level, PI_Level_Previous
FROM [BI_DB_dbo].[BI_DB_CopyDailyData]
WHERE DateID = 20260401
  AND PI_Level <> PI_Level_Previous
  AND PI_Level_Previous IS NOT NULL;

-- MIMO daily activity for a specific date
SELECT CID, UserName, MI, MO, netMI, NewMirror, UnMirror
FROM [BI_DB_dbo].[BI_DB_CopyDailyData]
WHERE DateID = 20260401
  AND (NewMirror > 0 OR UnMirror > 0)
ORDER BY NewMirror DESC;

-- PIs with no recent manager contact (>30 days)
SELECT CID, UserName, Manager, LastContactDate,
       DATEDIFF(DAY, LastContactDate, GETDATE()) AS DaysSinceContact
FROM [BI_DB_dbo].[BI_DB_CopyDailyData]
WHERE DateID = 20260401
  AND LastContactDate > '1900-01-01'  -- exclude sentinel
  AND DATEDIFF(DAY, LastContactDate, GETDATE()) > 30
ORDER BY DaysSinceContact DESC;
```

---

## 8. Atlassian Sources

No Confluence pages identified for this object. Contact the Data Platform team or check the DATA Confluence space for PI performance reporting documentation.
