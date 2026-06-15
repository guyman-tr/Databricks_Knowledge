# DWH_dbo.Fact_RegulationTransfer

> Records every customer regulatory entity transfer — when a customer's account moves from one regulation (e.g., FCA, CySEC, ASIC) to another — along with a snapshot of their complete financial position at the time of transfer.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact — event snapshot) |
| **Row Count** | Low millions (one row per CID × regulation change event) |
| **Production Source** | `DWH_staging.etoro_History_BackOfficeCustomer` → regulation change detection |
| **Refresh** | Daily — DELETE for date + re-insert from staging |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC, CID ASC) |
| **Synapse NCI** | IX_Fact_RegulationTransfer (DateID, CID) |
| | |
| **UC Target** | `compliance.gold_sql_dp_prod_we_dwh_dbo_fact_regulationtransfer` |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Fact_RegulationTransfer` captures the moment when a customer is transferred from one regulatory entity to another within the eToro platform. eToro operates under multiple regulatory frameworks globally (e.g., FCA in the UK, CySEC in Cyprus, ASIC in Australia, FinCEN in the US). When a customer's regulatory jurisdiction changes — due to relocation, regulatory restructuring, or Brexit-related migrations — this table records:

- **The transfer itself**: source and target regulation IDs, timestamp
- **A complete financial snapshot**: the customer's equity position as of the day before transfer, including cash, positions, PnL across asset classes (CFD, real stocks, crypto, futures, stock margin), liabilities, and AUM

This enables:
- **Regulatory reporting** — tracking customer migration between jurisdictions
- **Financial reconciliation** — verifying asset values at point of transfer
- **Risk analysis** — understanding the financial profile of migrating customers
- **Audit trail** — complete record of when and what financial position was transferred

### Data Sources

The regulation change is detected by comparing consecutive rows in `etoro_History_BackOfficeCustomer` (a temporal/SCD2 table with ValidFrom/ValidTo columns). When a customer's RegulationID changes, a transfer event is generated. The equity snapshot comes from `V_Liabilities` (a view aggregating customer financial data).

---

## 2. Business Logic

### 2.1 Regulation Change Detection

**What**: Identifies customers whose RegulationID changed on a given date.

**Logic** (in `SP_Fact_RegulationTransfer_DL_To_Synapse`):
```
1. Read DWH_staging.etoro_History_BackOfficeCustomer (deduplicate by CID + CustomerHistoryID)
2. For each CID, find the LATEST row where ValidFrom >= @dt (current regulation)
3. For the same CID, find the LATEST row where ValidFrom < @dt (previous regulation)
4. If a.RegulationID <> c.RegulationID → regulation change detected
5. Extract: CID, Occurred (ValidFrom), FromRegulationID (previous), ToRegulationID (current)
```

### 2.2 Equity Snapshot Capture

**What**: At transfer time, snapshot the customer's full financial position.

**Source**: `V_Liabilities` for DateID = day before transfer

**Computed columns**:
- `InvestedRealStocks = PositionPnLStocksReal + TotalRealStocks`
- `InvestedRealCrypto = PositionPnLCryptoReal + TotalRealCrypto`
- `InvestedRealFutures = PositionPnLFuturesReal + TotalRealFutures`
- `InvestedStocksMargin = PositionPnLStocksMargin + TotalStocksMargin`

All equity fields are ISNULL-wrapped to 0 for customers with no positions.

### 2.3 Final Day Record Selection

When multiple regulation changes occur for the same CID on the same day, the SP keeps:
- For `Ext_FRT_BackOffice_RegulationChangeLog_All`: the FIRST `FromRegulationID` (earliest change) and LAST `ToRegulationID` (final state)
- Only if `FromRegulationID <> ToRegulationID` (net change is real)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(CID) enables co-located JOINs with other CID-distributed tables (e.g., Fact_SnapshotEquity). The clustered index on (DateID, CID) supports date-range scans. Always filter on DateID for efficient queries.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All transfers on a date | `WHERE DateID = @dt` |
| Customer's transfer history | `WHERE CID = @cid ORDER BY DateID` |
| Transfers to a specific regulation | `WHERE ToRegulationID = @regId` |
| Total equity transferred per day | `SELECT DateID, SUM(RealizedEquity) FROM ... GROUP BY DateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Customer demographics |
| DWH_dbo.Dim_Regulation | ON FromRegulationID = RegulationID / ToRegulationID = RegulationID | Regulation entity names |
| DWH_dbo.Dim_Date | ON DateID = DateID | Calendar attributes |
| DWH_dbo.Fact_SnapshotEquity | ON CID = CID AND DateID = DateID | Compare transfer equity vs daily equity |

### 3.4 Gotchas

- **Equity is from day BEFORE transfer**: The V_Liabilities snapshot is for `DateID = @beforedateid` (day before the transfer), not the transfer day itself
- **No transfer events = no rows**: If no regulation changes occurred on a date, no rows are inserted (not even empty placeholders)
- **CID not GCID**: This table uses CID (Real account), not GCID. JOIN on CID, not GCID
- **money type columns**: Many financial columns use the `money` type — be aware of implicit rounding in calculations

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromRegulationID | tinyint | NO | Regulatory entity the customer was under BEFORE the transfer. JOINs to Dim_Regulation. (Tier 2 — SP_Fact_RegulationTransfer_DL_To_Synapse) |
| 2 | ToRegulationID | tinyint | NO | Regulatory entity the customer was transferred TO. JOINs to Dim_Regulation. (Tier 2 — SP_Fact_RegulationTransfer_DL_To_Synapse) |
| 3 | Occurred | datetime | NO | Timestamp when the regulation transfer event occurred (ValidFrom of the new regulation record). (Tier 2 — SP_Fact_RegulationTransfer_DL_To_Synapse) |
| 4 | DateID | int | NO | Date of the regulation transfer in YYYYMMDD format. JOINs to Dim_Date. (Tier 2 — SP_Fact_RegulationTransfer_DL_To_Synapse) |
| 5 | UnrealizedPnL | decimal(16,8) | NO | Total unrealized PnL across all open positions at time of transfer. From V_Liabilities.PositionPnL (day before). (Tier 2 — SP_Fact_RegulationTransfer) |
| 6 | ActualNWA | decimal(16,2) | YES | Net Withdrawable Amount — cash available for withdrawal. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 7 | RealizedEquity | decimal(16,8) | YES | Realized equity balance — cash + realized PnL. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 8 | UpdateDate | datetime | NO | ETL load timestamp — GETDATE() during SP execution. (Tier 2 — SP_Fact_RegulationTransfer) |
| 9 | CID | int | YES | Customer ID (Real account). Distribution key. JOINs to Dim_Customer.RealCID. (Tier 2 — SP_Fact_RegulationTransfer_DL_To_Synapse) |
| 10 | TotalPositionsAmount | money | YES | Total value of all open CFD positions. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 11 | TotalCash | money | YES | Total cash balance in the account. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 12 | InProcessCashouts | money | YES | Cash amount locked in pending withdrawal requests. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 13 | TotalMirrorPositionsAmount | money | YES | Total value of copy trading (mirror) positions. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 14 | TotalMirrorCash | money | YES | Cash allocated to copy trading relationships. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 15 | TotalStockOrders | money | YES | Total value of pending stock orders. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 16 | TotalMirrorStockOrders | money | YES | Total value of pending stock orders via copy trading. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 17 | Credit | money | YES | Outstanding credit/bonus balance from Fact_SnapshotEquity (sourced from History.ActiveCredit); negative values represent outstanding obligations. ISNULL to 0. (Tier 2 - Fact_SnapshotEquity) |
| 18 | AUM | money | YES | Assets Under Management — total account value including positions, cash, and credits. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 19 | BonusCredit | money | YES | Bonus credit balance from promotional campaigns. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 20 | TotalLiability | money | YES | Total liabilities owed by eToro to the customer. From V_Liabilities.Liabilities. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 21 | WithdrawableLiability | money | YES | Portion of liabilities that are withdrawable. From V_Liabilities.WA_Liabilities. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 22 | LiabilityInUsedMargin | money | YES | Liabilities locked as used margin. From V_Liabilities.Liabilities_InUsedMargin. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 23 | InvestedRealStocks | money | YES | Total invested in real stocks: PositionPnLStocksReal + TotalRealStocks. Computed in SP. (Tier 2 — SP_Fact_RegulationTransfer) |
| 24 | InvestedRealCrypto | money | YES | Total invested in real crypto: PositionPnLCryptoReal + TotalRealCrypto. Computed in SP. (Tier 2 — SP_Fact_RegulationTransfer) |
| 25 | PositionPnLStocksReal | money | YES | Unrealized PnL on real stock positions. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 26 | PositionPnLCryptoReal | money | YES | Unrealized PnL on real crypto positions. ISNULL to 0. (Tier 2 — V_Liabilities) |
| 27 | PositionPnLFuturesReal | decimal(16,2) | YES | Unrealized PnL on real futures positions. ISNULL to 0. Added 2024-11. (Tier 2 — V_Liabilities) |
| 28 | InvestedRealFutures | decimal(16,2) | YES | Total invested in real futures: PositionPnLFuturesReal + TotalRealFutures. Computed in SP. Added 2024-11. (Tier 2 — SP_Fact_RegulationTransfer) |
| 29 | InvestedStocksMargin | decimal(16,2) | YES | Total invested in margin stocks: PositionPnLStocksMargin + TotalStocksMargin. Computed in SP. Added 2025-10. (Tier 2 — SP_Fact_RegulationTransfer) |
| 30 | PositionPnLStocksMargin | decimal(16,2) | YES | Unrealized PnL on stock margin positions. ISNULL to 0. Added 2025-10. (Tier 2 — V_Liabilities) |
| 31 | TotalStockMarginLoanValue | decimal(16,2) | YES | Total loan value for margin stock positions. ISNULL to 0. Added 2025-10. (Tier 2 — V_Liabilities) |

---

## 5. Lineage

### 5.1 Pipeline

```
DWH_staging.etoro_History_BackOfficeCustomer (SCD2 history)
    │
    └─ SP_Fact_RegulationTransfer_DL_To_Synapse
        ├─ Regulation change detection → Ext_FRT_BackOffice_RegulationChangeLog
        ├─ Net daily change → Ext_FRT_BackOffice_RegulationChangeLog_All
        └─ EXEC SP_Fact_RegulationTransfer
            ├─ Read: Ext_FRT_BackOffice_RegulationChangeLog_All (transfer events)
            ├─ Read: V_Liabilities (equity snapshot, day before)
            └─ INSERT → Fact_RegulationTransfer
```

### 5.2 Key Source Objects

| Object | Type | Role |
|--------|------|------|
| DWH_staging.etoro_History_BackOfficeCustomer | Staging | SCD2 customer history with RegulationID |
| Ext_FRT_BackOffice_RegulationChangeLog | Staging | Raw regulation change events |
| Ext_FRT_BackOffice_RegulationChangeLog_All | Staging | Net daily regulation changes (first FROM, last TO) |
| V_Liabilities | View | Customer equity snapshot (positions, cash, liabilities) |

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer (Real account) |
| FromRegulationID, ToRegulationID | DWH_dbo.Dim_Regulation | Regulatory entities |
| DateID | DWH_dbo.Dim_Date | Transfer date |

### 6.2 Referenced By

No known downstream consumers — used for regulatory reporting and audit queries.

---

## 7. Sample Queries

### 7.1 Daily regulation transfer summary

```sql
SELECT
    DateID,
    r_from.RegulationName AS FromRegulation,
    r_to.RegulationName AS ToRegulation,
    COUNT(*) AS TransferCount,
    SUM(AUM) AS TotalAUMTransferred
FROM DWH_dbo.Fact_RegulationTransfer f
JOIN DWH_dbo.Dim_Regulation r_from ON f.FromRegulationID = r_from.RegulationID
JOIN DWH_dbo.Dim_Regulation r_to ON f.ToRegulationID = r_to.RegulationID
WHERE DateID >= 20260101
GROUP BY DateID, r_from.RegulationName, r_to.RegulationName
ORDER BY DateID DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian search performed — regulatory transfer logic fully documented via SP analysis.

---

*Generated: 2026-03-19 | Quality: 7.8/10 (★★★★☆) | Phases: 7/14 (P2,P3 skipped — Synapse MCP unavailable)*
*Tiers: 0 T1, 31 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 8/10*
*Object: DWH_dbo.Fact_RegulationTransfer | Type: Table | Production Source: etoro_History_BackOfficeCustomer*
