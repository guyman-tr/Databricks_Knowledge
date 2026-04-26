---
object: BI_DB_dbo.BI_DB_InvestorsDetail
type: table
schema: BI_DB_dbo
status: documented
quality: 8.8
batch: 27
documented_by: claude-sonnet-4-6
documented_date: 2026-04-22
---

# BI_DB_dbo.BI_DB_InvestorsDetail

## 1. Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Incremental Daily) |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED INDEX (DateID ASC) |
| **Column Count** | 16 |
| **Row Count** | ~898,447,000 (898.4M) |
| **Grain** | One row per (Date, RealCID, InstrumentType, ParentUserName, ActionType, AssetType, Occurred) — trade/copy event level |
| **Refresh Pattern** | DELETE WHERE DateID=@EndddINT + INSERT (date-keyed incremental) |
| **Writer SP** | `SP_InvestorReportDetails` |
| **Author** | Bar Arian (2024-02-29) |
| **Last Updated** | 2024-08-05 (Nitsan Sharabi — Bronze tier sub-division) |
| **Date Range** | 2021-05-01 — 2026-04-12 |
| **Last SP Run** | 2026-04-13 |
| **UC Target** | Not Migrated |

---

## 2. Business Meaning

**BI_DB_InvestorsDetail** is the Account Manager reporting fact table, capturing individual trade and copy-investment events with associated account manager contact attribution.

The table answers: *"For each trade or copy action a customer took on a given day, which account manager was responsible, when did they last contact the customer, and how much money moved?"*

**Two pipelines merged**:
- **Manual** (98.4% of rows): Position opens (ActionTypeID=1) and closes (ActionTypeID=4) in Fact_CustomerAction, attributed to instrument type
- **Copy** (1.6% of rows): Copy invest/stop/add/clear actions (ActionTypeID=15–18), attributed to the Popular Investor being copied

**Grain**: Event-level — one row per (customer, date, instrument/copy entity, occurred-timestamp, action type). A single customer can have many rows on a single date if they trade multiple instruments or execute multiple actions.

**Scale**: 898.4M rows across ~4.8M distinct customers and 1,808 dates (May 2021 – Apr 2026).

**Instrument distribution** (2026 YTD): Commodities (38.3%), Stocks (31.2%), Indices (10.6%), Crypto Currencies (10.2%), ETF (5.5%), Currencies (2.3%), Copy Trading (1.1%), Copy Portfolio (0.5%).

---

## 3. Key Gotchas

### 3.1 ParentUserName — Dual Meaning
`ParentUserName` stores different things depending on `ActionType`:
- **Manual** rows: `Dim_Instrument.InstrumentDisplayName` — the instrument's human-readable name (e.g., 'Oil (Non Expiry)', 'Bitcoin', 'Apple Inc')
- **Copy** rows: `Dim_Mirror.ParentUserName` — the Popular Investor's username being copied

The column name is misleading for Manual rows. Filter on `ActionType` before interpreting this value.

### 3.2 MoneyIn Uses -1 Multiplier
In Fact_CustomerAction, the `Amount` for open/invest actions (ActionTypeID 1, 15, 17) is stored as a negative value (debit). The SP applies `-1 × Amount` to make MoneyIn positive. No such adjustment is needed for close/stop actions (MoneyOut). Amounts represent USD.

### 3.3 DaysContacted — 87% NULL
Most rows (87%) have NULL DaysContacted and NULL DaysContactedPhone. A contact event only registers when the account manager made an email or phone contact in the 90 days before the trade date. Rows with NULL indicate no qualifying contact in the 90-day window.

### 3.4 Club — Bronze Sub-Divided
The standard Dim_PlayerLevel 'Bronze' (PlayerLevelID=1) is split into two values:
- `'Low Bronze'`: PlayerLevelID=1 AND (ActualNWA + Liabilities) < $1,000
- `'High Bronze'`: PlayerLevelID=1 AND (ActualNWA + Liabilities) ≥ $1,000

All other PlayerLevels (Silver, Gold, Platinum, Platinum Plus, Diamond) pass through unchanged.

### 3.5 DELETE Bug — Identical Conditions
The SP DELETE statement reads:
```sql
DELETE FROM BI_DB_InvestorsDetail WHERE DateID = @EndddINT OR DateID = @EndddINT
```
Both conditions are identical (copy-paste artifact). The original commented code was `WHERE DateID < @StartddINT OR DateID = @EndddINT` (to prune old data and re-insert today). The current code only re-inserts today's data without any historical pruning — the table grows unbounded.

### 3.6 CountryID — FK Not Label
`CountryID` stores the integer foreign key to `DWH_dbo.Dim_Country`, not the country name. Join to `Dim_Country` for reporting.

### 3.7 AssetType = 'Investment' for Copy
All Copy rows have `AssetType='Investment'` (hardcoded). For Manual rows, 'Investment' applies only when `InstrumentTypeID IN (4,5,6)` AND `Leverage < 3` — low-leverage positions in specific instrument types are classified as investments rather than trades.

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Calendar date of the trade or copy-investment event. CAST(Fact_CustomerAction.Occurred AS DATE). (Tier 2 — SP_InvestorReportDetails) |
| 2 | DateID | int | YES | Integer date key (YYYYMMDD format). Clustered index key. Derived from Fact_CustomerAction.DateID. (Tier 2 — SP_InvestorReportDetails) |
| 3 | RealCID | int | YES | Customer ID who performed the trade or copy action. Passthrough from Fact_CustomerAction.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 4 | InstrumentType | varchar(50) | YES | Asset class of the traded instrument. Manual: Dim_Instrument.InstrumentType (Stocks, Commodities, Currencies, Indices, Crypto Currencies, ETF). Copy: 'Copy Trading' (MirrorTypeID 1/2) or 'Copy Portfolio' (MirrorTypeID 4). (Tier 2 — SP_InvestorReportDetails) |
| 5 | ParentUserName | varchar(100) | YES | **DUAL SOURCE**: For Manual rows, holds Dim_Instrument.InstrumentDisplayName (instrument name, e.g., 'Bitcoin', 'Oil (Non Expiry)'). For Copy rows, holds Dim_Mirror.ParentUserName (Popular Investor's username). Always filter on ActionType before interpreting this column. (Tier 2 — SP_InvestorReportDetails) |
| 6 | ActionType | varchar(6) | YES | Pipeline type: 'Manual' (position opened/closed directly) or 'Copy' (copy investment start/stop/add/clear). (Tier 2 — SP_InvestorReportDetails) |
| 7 | AssetType | varchar(10) | YES | Classification of the action's economic nature. 'Investment': low-leverage Manual positions (InstrumentTypeID IN 4,5,6 AND Leverage<3), or all Copy actions. 'Trade': all other Manual positions. (Tier 2 — SP_InvestorReportDetails) |
| 8 | MoneyOut | decimal(38,2) | YES | Total USD amount out (withdrawals/closes). Manual: ActionTypeID=4 (close). Copy: ActionTypeID IN (16,18) (stop/clear). Zero if no qualifying action on Date. (Tier 2 — SP_InvestorReportDetails) |
| 9 | MoneyIn | decimal(38,2) | YES | Total USD amount in (deposits/opens). Manual: (-1×Amount) for ActionTypeID=1 (open). Copy: (-1×Amount) for ActionTypeID IN (15,17) (start/add). The -1 reverses the negative sign convention in Fact_CustomerAction. Zero if no qualifying action. (Tier 2 — SP_InvestorReportDetails) |
| 10 | DaysContacted | int | YES | Minimum days elapsed between the account manager's most recent contact (phone or email, from BI_DB_UsageTracking_SF) and the trade date. Lookback window: 90 days. NULL if no contact in 90 days (~87% of rows). (Tier 2 — SP_InvestorReportDetails) |
| 11 | AccountManagerID | int | YES | ID of the account manager responsible for this customer at the time of the trade. Sourced from Fact_SnapshotCustomer at @date. FK to DWH_dbo.Dim_Manager. (Tier 2 — SP_InvestorReportDetails) |
| 12 | CountryID | int | YES | Customer's country of registration at @date. Integer FK to DWH_dbo.Dim_Country — join for country name. Sourced from Fact_SnapshotCustomer. (Tier 2 — SP_InvestorReportDetails) |
| 13 | UpdateDate | datetime | YES | ETL run timestamp. Set to GETDATE() at INSERT time. (Tier 3 — SP_InvestorReportDetails) |
| 14 | DaysContactedPhone | int | YES | Same as DaysContacted but restricted to phone contacts only (ActionName='Phone_Call_Succeed__c'). NULL if no phone contact in the 90-day window (~91% of rows). (Tier 2 — SP_InvestorReportDetails) |
| 15 | IsDepositor | int | YES | Whether the customer has ever deposited (1=yes, 0=no). Sourced from Fact_SnapshotCustomer.IsDepositor at @date. (Tier 2 — SP_InvestorReportDetails) |
| 16 | Club | varchar(max) | YES | Customer VIP/experience tier. Standard Dim_PlayerLevel names (Silver, Gold, Platinum, Platinum Plus, Diamond) plus sub-divided Bronze: 'Low Bronze' (Bronze AND portfolio<$1K) or 'High Bronze' (Bronze AND portfolio≥$1K). Distribution (2026 YTD): Low Bronze 20.6%, Gold 17.8%, Platinum Plus 15.4%, Platinum 15.0%, High Bronze 14.3%, Silver 13.5%, Diamond 3.1%. (Tier 2 — SP_InvestorReportDetails) |

---

## 5. Business Logic

### 5.1 Manual vs Copy Pipeline

```
#fca (ActionTypeID 1,4)         → #Trade (Manual positions)
#fca_copy (ActionTypeID 15-18)  → #CopyInvestment (Copy actions)
                  ↕ UNION
              #union → INSERT
```

Both pipelines use the same JOIN structure: Fact_SnapshotCustomer (at @StartddINT via Dim_Range), V_Liabilities, #contacted (contact history OUTER APPLY). `IsValidCustomer=1` filter applied in both pipelines.

### 5.2 Contact Attribution (DaysContacted)

Contact lookback window: 90 days before @date. Qualifies if:
- `BI_DB_UsageTracking_SF.ActionName IN ('Phone_Call_Succeed__c', 'Completed_Contact_Email__c')` (any contact)
- OR `ActionName = 'Phone_Call_Succeed__c'` only (for DaysContactedPhone)
- AND contact was by the **same account manager** assigned to the customer at trade time

`DaysContacted` = DATEDIFF(DAY, ContactedDate, trade_Occurred) — number of days between contact and trade. MIN across all qualifying contacts. A value of 0 means the contact happened on the same day as the trade; a value of 7 means contact was 7 days before the trade.

### 5.3 Bronze Tier Split

Introduced 2024-08-05 (Nitsan Sharabi). Portfolio value threshold:
```sql
ISNULL(vl.ActualNWA, 0) + ISNULL(vl.Liabilities, 0) < 1000
```
`ActualNWA` = net worth available (unrealized gains); `Liabilities` = cash balance. Sum < $1,000 → 'Low Bronze'; ≥ $1,000 → 'High Bronze'.

### 5.4 AssetType Investment Classification

Low-leverage positions in specific instrument types are classified as 'Investment' to distinguish them from speculative trades:
- `InstrumentTypeID IN (4, 5, 6)` — (confirm type names with domain expert)
- `Leverage < 3` — 1x or 2x leverage only

---

## 6. Data Evidence

| Metric | Value | Source |
|--------|-------|--------|
| Total rows | 898,447,000 | COUNT(*) live |
| Unique CIDs | 4,769,443 | COUNT(DISTINCT) |
| Unique dates | 1,808 | COUNT(DISTINCT DateID) |
| Date range | 2021-05-01 — 2026-04-12 | MIN/MAX |
| Last SP run | 2026-04-13 | MAX(UpdateDate) |
| ActionType | Manual 98.4%, Copy 1.6% | GROUP BY (2026 YTD) |
| AssetType | Trade 69.3%, Investment 30.7% | GROUP BY (2026 YTD) |
| Top InstrumentTypes | Commodities 38.3%, Stocks 31.2%, Indices 10.6%, Crypto 10.2% | GROUP BY (2026 YTD) |
| Null DaysContacted | 87.4% | COUNT |
| Null DaysContactedPhone | 91.2% | COUNT |

---

## 7. Source Objects

| Source | Role |
|--------|------|
| DWH_dbo.Fact_CustomerAction | Primary event source (ActionTypeID 1,4,15,16,17,18) |
| DWH_dbo.Dim_Instrument | Instrument metadata for manual trades |
| DWH_dbo.Dim_Mirror | Copy mirror relationship (ParentUserName, MirrorTypeID) |
| DWH_dbo.Dim_MirrorType | Copy type label |
| DWH_dbo.Fact_SnapshotCustomer | Customer snapshot (AccountManagerID, CountryID, IsDepositor) |
| DWH_dbo.Dim_Range | Snapshot date range |
| DWH_dbo.Dim_Manager | Account manager dimension |
| DWH_dbo.Dim_PlayerLevel | Club/VIP level label |
| DWH_dbo.V_Liabilities | Portfolio value for Bronze sub-tier calculation |
| BI_DB_dbo.BI_DB_UsageTracking_SF | Salesforce contact history |

---

## 8. Dependencies & Usage

**Upstream dependency**: `BI_DB_UsageTracking_SF` must be current before SP runs. `Fact_SnapshotCustomer` must cover @date (via Dim_Range).

**Typical query pattern**:
```sql
-- Account manager performance: trades by managed customers, with contact lag
SELECT AccountManagerID, InstrumentType, 
       COUNT(*) AS Trades,
       AVG(CAST(DaysContacted AS FLOAT)) AS AvgDaysSinceContact,
       SUM(MoneyIn) AS TotalMoneyIn, SUM(MoneyOut) AS TotalMoneyOut
FROM BI_DB_dbo.BI_DB_InvestorsDetail
WHERE DateID = 20260412
  AND ActionType = 'Manual'
GROUP BY AccountManagerID, InstrumentType
ORDER BY TotalMoneyIn DESC;
```
