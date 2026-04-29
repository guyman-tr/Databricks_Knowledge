# BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_Apex

> 26.4K-row Apex Clearing side of the US stock/ETF activity reconciliation — capturing daily share received/delivered records from Apex SOD Format 870 files for eToro US accounts, from November 2021 to present. Paired with BI_DB_US_Apex_Stocks_Activity_eToroDB for cross-system reconciliation. Refreshed daily via SP_US_Apex_Stocks_Activity_Recon with DELETE+INSERT by EntryDate.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | External_Sodreconciliation_apex_EXT870_StockActivity (Apex SOD 870) + USABroker external tables (CID resolution) |
| **Refresh** | Daily (SP_US_Apex_Stocks_Activity_Recon, DELETE+INSERT by EntryDate, SB_Daily, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_US_Apex_Stocks_Activity_Apex` is one half of a two-table reconciliation pair that compares stock/ETF settlement activity between Apex Clearing (the US broker-dealer) and eToro's internal position records. This table contains the **Apex side** — daily share receipt and delivery records extracted from Apex's SOD (Start of Day) Format 870 files.

Each row represents a share movement event at Apex for an eToro US customer account on a specific date and CUSIP, with the number of units received or delivered. The SP filters to AccountType='2' (customer accounts), excludes the house account (3ET00001), and removes journal entries (TerminalID NOT IN MGJNL/RGJNL).

The companion table `BI_DB_US_Apex_Stocks_Activity_eToroDB` contains the same activity from eToro's Dim_Position perspective, enabling analysts to identify mismatches between the two systems.

---

## 2. Business Logic

### 2.1 Receive vs Deliver Category

**What**: Share movements are classified as received or delivered.
**Columns Involved**: `Category`
**Rules**:
- TradeSettleBasis = 'R' → 'Recieved' (shares coming in)
- TradeSettleBasis = 'D' → 'Delivered' (shares going out)
- Note: "Recieved" is the original spelling from the SP (typo preserved)

### 2.2 SOD File Validation

**What**: Only records from validated SOD 870 files are included.
**Rules**:
- ApexFormat = 870 (stock activity format)
- Status = 2 (validated/processed)
- Most recent ImportEndDate per ProcessDate is used (latest valid file)

### 2.3 Exclusion Filters

**What**: House accounts and journal entries are excluded.
**Rules**:
- AccountNumber != '3ET00001' (house/omnibus account)
- TerminalID NOT IN ('MGJNL', 'RGJNL') (manual/recon journal entries)
- AccountType = '2' (customer accounts only)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN, HEAP. Small table (26K rows). Full scan acceptable for all queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily activity for a CID | `WHERE CID = @cid ORDER BY EntryDate` |
| Reconciliation vs eToro side | FULL OUTER JOIN with BI_DB_US_Apex_Stocks_Activity_eToroDB on CID + CUSIP + Date + Category |
| Activity by CUSIP | `GROUP BY CUSIP, Category` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_eToroDB | CID + CUSIP + EntryDate=Date + Category | Reconciliation pair |

### 3.4 Gotchas

- **"Recieved" spelling**: Intentional SP output — not a typo in the table, it's in the source code. Use this exact spelling in queries
- **Units = 0**: Stock splits and corporate actions may show Units=0 (e.g., Trailer = "STOCK SPLIT")
- **CID from indirect JOIN**: CID is resolved via ApexData.GCID → UserData.GCID → UserData.CID. NULL if the chain breaks

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data + context |
| Tier 5 | ETL infrastructure / standard metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountNumber | varchar(50) | YES | Apex Clearing account number for the eToro customer. Format: alphanumeric (e.g., "3ET13835", "3FN19666"). Filtered to AccountType='2' (customer accounts), excludes '3ET00001' (house account). (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, External_Sodreconciliation_apex_EXT870_StockActivity) |
| 2 | CID | int | YES | Customer ID — platform-internal primary key. Resolved from Apex AccountNumber → ApexData.GCID → UserData.CID. NULL if the Apex-to-eToro mapping chain is incomplete. (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, External_USABroker_Apex_UserData) |
| 3 | EntryDate | date | YES | Date of the stock activity record from the Apex SOD 870 file. Filtered to @Date. Range: 2021-11-08 to present. (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, External_Sodreconciliation_apex_EXT870_StockActivity) |
| 4 | CUSIP | varchar(100) | YES | CUSIP identifier for the security involved in the activity. Standard 9-character CUSIP (e.g., "890516107", "946760105"). (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, External_Sodreconciliation_apex_EXT870_StockActivity) |
| 5 | Category | varchar(50) | YES | Direction of share movement. 'Recieved' (67%) = shares coming into account. 'Delivered' (33%) = shares going out. Derived from TradeSettleBasis: 'R'→'Recieved', 'D'→'Delivered'. (Tier 2 — SP_US_Apex_Stocks_Activity_Recon) |
| 6 | Trailer | varchar(200) | YES | Apex SOD 870 trailer field describing the activity type. Values include "STOCK SPLIT", trade descriptions, corporate action details. (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, External_Sodreconciliation_apex_EXT870_StockActivity) |
| 7 | TerminalID | varchar(50) | YES | Apex terminal/source identifier for the activity. Filtered to exclude 'MGJNL' and 'RGJNL' (manual/recon journal entries). Common value: "85". (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, External_Sodreconciliation_apex_EXT870_StockActivity) |
| 8 | Units | int | YES | Number of shares/units moved. SUM of Quantity from SOD 870 records. 0 for stock splits and corporate actions where no net share change occurred. (Tier 2 — SP_US_Apex_Stocks_Activity_Recon, External_Sodreconciliation_apex_EXT870_StockActivity) |
| 9 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_US_Apex_Stocks_Activity_Recon (GETDATE()). (Tier 5 — SP_US_Apex_Stocks_Activity_Recon) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| AccountNumber | EXT870_StockActivity | AccountNumber | Passthrough |
| CID | USABroker_Apex_UserData | CID | JOIN chain via GCID |
| EntryDate | EXT870_StockActivity | EntryDate | Passthrough |
| CUSIP | EXT870_StockActivity | Cusip | Passthrough |
| Category | EXT870_StockActivity | TradeSettleBasis | CASE R→Recieved, D→Delivered |
| Trailer | EXT870_StockActivity | Trailer | Passthrough |
| TerminalID | EXT870_StockActivity | TerminalID | Passthrough |
| Units | EXT870_StockActivity | Quantity | SUM |
| UpdateDate | ETL | GETDATE() | Insert timestamp |

### 5.2 ETL Pipeline

```
Apex Clearing (SOD Format 870 — Stock Activity)
  |-- Data Lake ingestion ---|
  v
BI_DB_dbo.External_Sodreconciliation_apex_EXT870_StockActivity
  |                                                        |
  |  + DWH_dbo.Sodreconciliation_apex_SodFiles (validation)|
  |  + External_USABroker_Apex_* (CID resolution)          |
  |                                                        |
  |-- SP_US_Apex_Stocks_Activity_Recon @date (daily) ------|
  v
BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_Apex (26.4K rows)
  |
  (UC: Not Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CUSIP | BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_eToroDB | Reconciliation counterpart (eToro side) |

### 6.2 Referenced By (other objects point to this)

No known consumers.

---

## 7. Sample Queries

### 7.1 Apex vs eToro Reconciliation for a Date

```sql
SELECT
    COALESCE(a.CID, e.CID) AS CID,
    COALESCE(a.CUSIP, e.CUSIP) AS CUSIP,
    COALESCE(a.Category, e.Category) AS Category,
    a.Units AS Apex_Units,
    e.RoundeUnits AS eToro_Units,
    ISNULL(a.Units, 0) - ISNULL(e.RoundeUnits, 0) AS Unit_Diff
FROM BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_Apex a
FULL OUTER JOIN BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_eToroDB e
    ON a.CID = e.CID AND a.CUSIP = e.CUSIP AND a.EntryDate = e.[Date] AND a.Category = e.Category
WHERE a.EntryDate = '2026-04-06' OR e.[Date] = '2026-04-06'
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 8 T2, 0 T3, 0 T4, 1 T5 | Elements: 9/9, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_US_Apex_Stocks_Activity_Apex | Type: Table | Production Source: Apex SOD 870 Stock Activity*
