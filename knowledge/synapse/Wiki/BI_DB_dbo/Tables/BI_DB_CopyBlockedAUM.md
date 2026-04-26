# BI_DB_dbo.BI_DB_CopyBlockedAUM

| Property | Value |
|----------|-------|
| Schema | BI_DB_dbo |
| Object | BI_DB_CopyBlockedAUM |
| Type | Table |
| Rows | ~691 (as of 2026-04-12) |
| Distribution | HASH(CID) |
| Index | CLUSTERED INDEX(CID ASC) |
| Production Source | etoro.Customer.BlockedCustomerOperations (OperationTypeID=2) |
| Writer SP | BI_DB_dbo.SP_CopyBlockedAUM |
| Refresh Cadence | Daily TRUNCATE+INSERT |
| UC Target | _Not_Migrated |
| Batch | 74 |
| Documented | 2026-04-23 |

---

## 1. Business Meaning

Daily snapshot of **Popular Investors (PIs) whose copy-trading portfolio is currently blocked** (OperationTypeID=2). Each row represents one active block event, capturing the PI's identity, the block reason, their AUM and copier counts, equity, account manager, and a 151-day risk score history at the time of the daily refresh.

The table reflects the **current population** of blocked PIs only — it is fully replaced each day via TRUNCATE+INSERT. Historical block events are tracked separately in `BI_DB_dbo.BI_DB_CopyBlockedAUMHistory`. The 691-row population (as of 2026-04-12) is a risk-monitoring and compliance input: it shows which high-AUM PIs have been operationally blocked and for how long their risk scores have been elevated.

Authored by Dan (2021-11-22); migrated to Synapse by Tom Boksenbojm (2023-12-18).

---

## 2. Business Logic & Derivation Rules

### Block Scope
The SP filters `etoro.Customer.BlockedCustomerOperations WHERE OperationTypeID = 2` — exclusively PI copy blocks. Unblock events and other operation types are excluded.

### Risk Score Columns (151-day lookback from `BI_DB_dbo.DWH_CIDsDailyRisk`)

| Column | Logic |
|--------|-------|
| `DaysUnderRisk6` | nvarchar(5). Number of days since the PI's risk score last exceeded 6. NULL when Equity=0 (PI has no funds). `'31+'` when over threshold for 31+ consecutive days. Numeric string (`'0'`–`'30'`) otherwise. Do NOT cast to INT — contains non-numeric sentinels. |
| `AvgRiskPreviousMonth` | `CAST(ROUND(AVG(RiskScore), 0, 1) AS INT)` over the prior full calendar month. |
| `DaysSinceMaxRiskScore8` | `DATEDIFF(day, MAX(FullDate WHERE RiskScore>=8), @date)`. Returns `-1` if the PI has never reached a risk score of 8. |

### AUM & Equity (`general.etoroGeneral_History_GuruCopiers`, `DWH_dbo.V_Liabilities`)

| Column | Logic |
|--------|-------|
| `AUM` | `ISNULL(SUM(Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL), 0)` as of @date. |
| `NumOfCopiers` | `ISNULL(COUNT(*), 0)` of active copier rows as of @date. |
| `Equity` | `ActualNWA + Liabilities` from `DWH_dbo.V_Liabilities`. |

### Date Key
`OccurredID = CAST(CONVERT(CHAR(8), Occurred, 112) AS INT)` — produces an integer date key in YYYYMMDD format.

### Manager Composite
`Manager = FirstName + ' ' + LastName` from `DWH_dbo.Dim_Manager`. `LastName='*'` indicates a functional/shared account.

---

## 3. Query Advisory

- **Full SELECT is safe** — 691 rows, small table.
- **HASH(CID) distributed** — `WHERE CID = ?` queries hit a single distribution node.
- **`DaysUnderRisk6` is NVARCHAR(5)** — contains `'31+'` and `NULL` sentinels. Do not `CAST` to INT without handling these values.
- **`OperationTypeID` is always 2** — filtering on it is redundant.
- **No history here** — this table is TRUNCATE+INSERT daily. For trend analysis, join to `BI_DB_CopyBlockedAUMHistory`.
- **`DaysSinceMaxRiskScore8 = -1`** means the PI has never reached risk score 8 (not a missing value).

---

## 4. Elements

| Column | Nullable | Type | Description |
|--------|----------|------|-------------|
| CID | NOT NULL | int | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| UserName | NULL | varchar(20) | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — DWH_dbo.Dim_Customer) |
| Manager | NULL | varchar(101) | Account manager display name: FirstName + ' ' + LastName from Dim_Manager. LastName='*' indicates a functional/shared account. (Tier 2 — DWH_dbo.Dim_Manager) |
| OperationTypeID | NULL | int | Block operation type code. Always 2 in this table (PI copy block). Source: etoro.Customer.BlockedCustomerOperations. (Tier 2 — etoro.Customer.BlockedCustomerOperations) |
| BlockReasonID | NULL | int | Numeric code identifying the reason the PI was blocked. FK to etoro.Dictionary.BlockUnBlockReason. (Tier 2 — etoro.Customer.BlockedCustomerOperations) |
| Occurred | NULL | datetime | UTC timestamp when the block event occurred in the etoro production system. (Tier 2 — etoro.Customer.BlockedCustomerOperations) |
| OccurredID | NULL | int | Integer date key derived from Occurred: CAST(CONVERT(CHAR(8), Occurred, 112) AS INT) — YYYYMMDD format. (Tier 2 — derived from Occurred) |
| OperationDescription | NULL | varchar(50) | Human-readable label for OperationTypeID. Source: etoro.Dictionary.OperationTypesForBlocking. (Tier 2 — etoro.Dictionary.OperationTypesForBlocking) |
| Reason | NULL | nvarchar(50) | Human-readable label for BlockReasonID. Source: etoro.Dictionary.BlockUnBlockReason. (Tier 2 — etoro.Dictionary.BlockUnBlockReason) |
| Country | NULL | varchar(50) | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 — DWH_dbo.Dim_Country via Dictionary.Country) |
| GuruStatusID | NULL | smallint | eToro Popular Investor/Guru program status — whether the customer is an active copy trading strategy provider. FK to Dictionary.GuruStatus. Values: 0=No, 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected. (Tier 1 — DWH_dbo.Dim_Customer via BackOffice.Customer) |
| GuruStatusName | NULL | varchar(50) | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. (Tier 1 — DWH_dbo.Dim_GuruStatus via Dictionary.GuruStatus) |
| AUM | NULL | money | Assets Under Management as of @date: ISNULL(SUM(Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL), 0) from etoroGeneral_History_GuruCopiers. (Tier 2 — general.etoroGeneral_History_GuruCopiers) |
| NumOfCopiers | NULL | int | Number of active copiers as of @date: ISNULL(COUNT(*), 0) from etoroGeneral_History_GuruCopiers. (Tier 2 — general.etoroGeneral_History_GuruCopiers) |
| Equity | NULL | decimal(23,4) | PI's net equity: ActualNWA + Liabilities from DWH_dbo.V_Liabilities. (Tier 2 — DWH_dbo.V_Liabilities) |
| DaysUnderRisk6 | NULL | nvarchar(5) | Days since the PI's risk score last exceeded 6 (151-day lookback). NULL = Equity is 0. '31+' = over threshold 31+ consecutive days. Numeric string '0'–'30' otherwise. (Tier 2 — BI_DB_dbo.DWH_CIDsDailyRisk) |
| UpdateDate | NOT NULL | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Propagation) |
| AvgRiskPreviousMonth | NULL | int | Average risk score for the prior calendar month: CAST(ROUND(AVG(RiskScore), 0, 1) AS INT) from DWH_CIDsDailyRisk. (Tier 2 — BI_DB_dbo.DWH_CIDsDailyRisk) |
| DaysSinceMaxRiskScore8 | NULL | int | Days since the PI last reached risk score ≥ 8. -1 if the PI has never reached a risk score of 8. (Tier 2 — BI_DB_dbo.DWH_CIDsDailyRisk) |

---

## 5. Lineage

### 5.1 Source Objects

| Source | Usage |
|--------|-------|
| etoro.Customer.BlockedCustomerOperations | Primary source: CID, BlockReasonID, Occurred, OperationTypeID (filter: =2, current blocks) |
| DWH_dbo.Dim_Customer | UserName, GuruStatusID, CountryID, AccountManagerID lookup |
| DWH_dbo.Dim_GuruStatus | GuruStatusName lookup |
| DWH_dbo.Dim_Country | Country (Name) lookup |
| DWH_dbo.Dim_Manager | Manager composite (FirstName+' '+LastName) |
| DWH_dbo.V_Liabilities | Equity: ActualNWA + Liabilities |
| general.etoroGeneral_History_GuruCopiers | AUM, NumOfCopiers as of @date |
| BI_DB_dbo.DWH_CIDsDailyRisk | DaysUnderRisk6, AvgRiskPreviousMonth, DaysSinceMaxRiskScore8 (151-day lookback) |
| etoro.Dictionary.OperationTypesForBlocking | OperationDescription lookup |
| etoro.Dictionary.BlockUnBlockReason | Reason lookup |
| etoro.Internal.RiskScore | Risk threshold configuration |

### 5.2 ETL Pipeline

```
etoro.Customer.BlockedCustomerOperations (OperationTypeID=2, current blocks only)
  |
  +-- DWH_dbo.Dim_Customer (UserName, GuruStatusID, CountryID, AccountManagerID)
  +-- DWH_dbo.Dim_GuruStatus (GuruStatusName)
  +-- DWH_dbo.Dim_Country (Country Name)
  +-- DWH_dbo.Dim_Manager (FirstName+' '+LastName)
  +-- DWH_dbo.V_Liabilities (Equity = ActualNWA + Liabilities)
  +-- general.etoroGeneral_History_GuruCopiers (AUM, NumOfCopiers as of @date)
  +-- BI_DB_dbo.DWH_CIDsDailyRisk (risk score history, 151-day lookback)
  +-- etoro.Dictionary.OperationTypesForBlocking (OperationDescription)
  +-- etoro.Dictionary.BlockUnBlockReason (Reason)
  +-- etoro.Internal.RiskScore (risk thresholds)
  |
  v
SP_CopyBlockedAUM (Dan, 2021-11-22; Synapse: Tom Boksenbojm, 2023-12-18)
  TRUNCATE + INSERT daily
  |
  v
BI_DB_dbo.BI_DB_CopyBlockedAUM (~691 rows, HASH(CID))
  |
  v
UC Target: _Not_Migrated (not in Generic Pipeline)
```

---

## 6. Relationships & Cross-References

| Related Object | Relationship |
|----------------|-------------|
| BI_DB_dbo.BI_DB_CopyBlockedAUMHistory | History table: written by same SP (SP_CopyBlockedAUM). Contains risk-score history for currently-blocked PIs only (JOIN #blockedusers). |
| BI_DB_dbo.DWH_CIDsDailyRisk | Source of all three risk score columns. 151-day rolling window. |
| DWH_dbo.V_Liabilities | Source of Equity column. |
| general.etoroGeneral_History_GuruCopiers | Source of AUM and NumOfCopiers. |
| DWH_dbo.Dim_Customer | Enrichment for UserName, GuruStatusID, CountryID. |
| DWH_dbo.Dim_Manager | Enrichment for Manager display name. |

---

## 7. Sample Queries

```sql
-- Current blocked PIs with high AUM
SELECT CID, UserName, Manager, Country, GuruStatusName,
       AUM, NumOfCopiers, Equity,
       DaysUnderRisk6, AvgRiskPreviousMonth, DaysSinceMaxRiskScore8
FROM [BI_DB_dbo].[BI_DB_CopyBlockedAUM]
WHERE AUM > 100000
ORDER BY AUM DESC;

-- PIs blocked for 31+ days at elevated risk
SELECT CID, UserName, Occurred, Reason, DaysUnderRisk6, AvgRiskPreviousMonth
FROM [BI_DB_dbo].[BI_DB_CopyBlockedAUM]
WHERE DaysUnderRisk6 = '31+'
ORDER BY AUM DESC;

-- Distribution by block reason
SELECT Reason, COUNT(*) AS BlockedPIs, SUM(AUM) AS TotalAUM
FROM [BI_DB_dbo].[BI_DB_CopyBlockedAUM]
GROUP BY Reason
ORDER BY TotalAUM DESC;

-- PIs that have reached risk score 8 at some point
SELECT CID, UserName, DaysSinceMaxRiskScore8, AvgRiskPreviousMonth, AUM
FROM [BI_DB_dbo].[BI_DB_CopyBlockedAUM]
WHERE DaysSinceMaxRiskScore8 >= 0
ORDER BY DaysSinceMaxRiskScore8 ASC;
```

---

## 8. Atlassian Sources

No Confluence pages identified for this object. Contact the Data Platform team or check the DATA Confluence space for block policy documentation.
