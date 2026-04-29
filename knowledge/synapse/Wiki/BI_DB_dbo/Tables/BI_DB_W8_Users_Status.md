# BI_DB_dbo.BI_DB_W8_Users_Status

> 5.2M-row table tracking W8-BEN tax form status for all customers who have ever signed a W8-BEN document (DocumentTypeID=12). Provides expiry tracking, GAP compliance requirements (RequirementIDs 14/16/17), open US stocks positions, equity, customer grouping (A/B/C based on club tier and activity), and player status change history. Daily TRUNCATE+INSERT via SP_BI_DB_W8_Users_Status.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | External_etoro_BackOffice_CustomerDocument + DWH_dbo.Dim_Customer + ComplianceStateDB via `SP_BI_DB_W8_Users_Status` |
| **Refresh** | Daily (TRUNCATE+INSERT), Priority 0, SB_Daily |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Adi Meidan (2023-11-01), updated by Lior Ben Dor and Eitan Lipovetsky |
| **Row Count** | ~5,235,633 |

---

## 1. Business Meaning

`BI_DB_W8_Users_Status` is the central compliance table for W8-BEN tax form lifecycle management. It covers every customer who has ever signed a W8-BEN document (identified via DocumentTypeID=12 in BackOffice_CustomerDocument). The table answers three core compliance questions: (1) Is the customer's W8-BEN expired, expiring this year, or still valid? (2) Has the customer completed the required GAP compliance steps? (3) Does the customer hold open US stocks positions that make W8 compliance operationally critical?

Population: 5.2M rows, one per customer (latest W8-BEN document only, via ROW_NUMBER on ExpiryDate DESC).

W8_Group_Status_ID distribution: 3 (valid, expiry > year-end) = ~3M rows, 1 (expired, expiry < year-end) = ~1.3M rows, 2 (expiring this year, expiry = year-end) = ~822K rows.

Customer Group classification: A = Bronze/Silver/Gold tier with no recent activity (~2.8M), B = same tiers with recent activity (~2.2M), C = Platinum and above (~141K), Other = remainder.

---

## 2. Business Logic

### 2.1 W8-BEN Expiry Status Classification

**What**: Classifies each customer's W8 form status relative to the current calendar year-end.
**Columns Involved**: `W8_Group_Status_ID`, `ExpiryDate`
**Rules**:
- 1 = Expired: ExpiryDate < current year-end
- 2 = Expiring this year: ExpiryDate = current year-end
- 3 = Valid: ExpiryDate > current year-end

### 2.2 Customer Group Classification

**What**: Segments customers by club tier and activity for compliance prioritization.
**Columns Involved**: `Group`, `Club`
**Rules**:
- 'C' = Platinum and above tiers (high-value customers)
- 'B' = Bronze, Silver, or Gold tier with recent activity
- 'A' = Bronze, Silver, or Gold tier with no recent activity
- 'Other' = all remaining

### 2.3 GAP Compliance Requirements

**What**: Tracks whether specific compliance requirements are required or completed per customer.
**Columns Involved**: `W8BEN_Gap_Required`, `W8Ben_TIN_change_Required`, `W8BenExpired_Gap_Required`, `W8BEN_Gap_Completed`, `W8Ben_TIN_change_Completed`, `W8BenExpired_Gap_Completed`
**Rules**:
- RequirementID 14 = W8BEN GAP, RequirementID 16 = TIN change, RequirementID 17 = W8BEN Expired GAP
- OverviewStatusID=1 maps to _Required columns (open/pending)
- OverviewStatusID=6 maps to _Completed columns (done)
- Source: External_ComplianceStateDB_Compliance_CustomerRequirmentsHistoryViewForW8ben

### 2.4 US Stocks Position Detection

**What**: Flags customers with open US equity positions (operationally critical for W8 compliance).
**Columns Involved**: `Has_Open_US_Stocks_Position`, `Open_Pos`
**Rules**:
- Has_Open_US_Stocks_Position = 1 if customer has any open position in BI_DB_PositionPnL where InstrumentTypeID IN (5,6) AND ISINCountryCode='US'
- Open_Pos = total count of all open positions (not limited to US stocks)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) HEAP — optimized for CID-based lookups and joins. Filter on CID for single-customer queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Expired W8 customers with US stocks | `WHERE W8_Group_Status_ID = 1 AND Has_Open_US_Stocks_Position = 1` |
| Customers needing GAP completion | `WHERE W8BEN_Gap_Required = 1 AND W8BEN_Gap_Completed = 0` |
| High-value expiring customers | `WHERE W8_Group_Status_ID = 2 AND [Group] = 'C'` |
| Breakdown by group and status | `GROUP BY W8_Group_Status_ID, [Group]` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `CID = RealCID` | Full customer profile |
| BI_DB_dbo.BI_DB_PositionPnL | `CID = CID` | Position-level detail |
| DWH_dbo.V_Liabilities | `CID = RealCID` | Current financial snapshot |

### 3.4 Gotchas

- **Group is a reserved word**: Always quote as `[Group]` in queries
- **RN_W8SignDate is always 1**: The SP filters to the latest W8-BEN doc only; this column is a residual from the ROW_NUMBER window
- **W8_Group_Status_ID logic is year-relative**: Status values shift meaning at year boundaries — a "valid" status 3 becomes "expiring" (2) or "expired" (1) as the year progresses
- **Open_Pos includes all positions**: Not limited to US stocks; use Has_Open_US_Stocks_Position for US-specific filtering
- **money type columns**: RealizedEquity and Equity are money type — be cautious with arithmetic to avoid precision issues

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL metadata (UpdateDate, batch columns) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID (RealCID). Distribution key. One row per customer. (Tier 1 — Customer.CustomerStatic) |
| 2 | ExpiryDate | date | YES | W8-BEN document expiry date. From latest document with DocumentTypeID=12 (ROW_NUMBER DESC by ExpiryDate). (Tier 2 — SP via External_etoro_BackOffice_CustomerDocument) |
| 3 | SignedDate | date | YES | W8-BEN document signed date. From latest document with DocumentTypeID=12. (Tier 2 — SP via External_etoro_BackOffice_CustomerDocument) |
| 4 | RN_W8SignDate | bigint | YES | ROW_NUMBER() OVER (ORDER BY ExpiryDate DESC). Always 1 in output — only the latest W8-BEN doc is retained. (Tier 2 — SP via External_etoro_BackOffice_CustomerDocument) |
| 5 | GCID | int | YES | Group customer ID. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 6 | KYC_Country | varchar(50) | YES | Country name from Dim_Country via Dim_Customer.CountryID. (Tier 1 — Dictionary.Country) |
| 7 | last_Log_IN | datetime | YES | Last login timestamp. MAX datetime from Fact_CustomerAction WHERE ActionTypeID=14. (Tier 2 — SP via Fact_CustomerAction) |
| 8 | W8BEN_Gap_Required | int | YES | 1 if RequirementID=14 has OverviewStatusID=1 (open), else 0. Source: ComplianceStateDB. (Tier 2 — SP via ComplianceStateDB) |
| 9 | W8Ben_TIN_change_Required | int | YES | 1 if RequirementID=16 has OverviewStatusID=1 (open), else 0. Source: ComplianceStateDB. (Tier 2 — SP via ComplianceStateDB) |
| 10 | W8BenExpired_Gap_Required | int | YES | 1 if RequirementID=17 has OverviewStatusID=1 (open), else 0. Source: ComplianceStateDB. (Tier 2 — SP via ComplianceStateDB) |
| 11 | W8BEN_Gap_Completed | int | YES | 1 if RequirementID=14 has OverviewStatusID=6 (completed), else 0. Source: ComplianceStateDB. (Tier 2 — SP via ComplianceStateDB) |
| 12 | W8Ben_TIN_change_Completed | int | YES | 1 if RequirementID=16 has OverviewStatusID=6 (completed), else 0. Source: ComplianceStateDB. (Tier 2 — SP via ComplianceStateDB) |
| 13 | W8BenExpired_Gap_Completed | int | YES | 1 if RequirementID=17 has OverviewStatusID=6 (completed), else 0. Source: ComplianceStateDB. (Tier 2 — SP via ComplianceStateDB) |
| 14 | Open_Pos | int | NO | Count of all open positions from BI_DB_PositionPnL. Not limited to US stocks. (Tier 2 — SP via BI_DB_PositionPnL) |
| 15 | RealizedEquity | money | NO | Realized equity from V_Liabilities. (Tier 2 — SP via V_Liabilities) |
| 16 | W8_Group_Status_ID | int | NO | W8 expiry status: 1=expired (ExpiryDate < year-end), 2=expiring this year (= year-end), 3=valid (> year-end). (Tier 2 — SP computed) |
| 17 | UpdateDate | datetime | NO | ETL execution timestamp. GETDATE() at SP execution time. (Tier 5 — ETL metadata) |
| 18 | PlayerStatus | varchar(250) | YES | Player status name from Dim_PlayerStatus via Dim_Customer.PlayerStatusID. (Tier 1 — Dictionary.PlayerStatus) |
| 19 | VerificationLevelID | int | YES | Verification level ID from Dim_Customer. (Tier 2 — SP via Dim_Customer) |
| 20 | IsDepositor | int | YES | Depositor flag from Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 21 | Equity | money | YES | Total equity: ActualNWA + Liabilities from V_Liabilities. (Tier 2 — SP via V_Liabilities) |
| 22 | Club | varchar(250) | YES | Club tier name from Dim_PlayerLevel via Dim_Customer.PlayerLevelID. (Tier 1 — Dictionary.PlayerLevel) |
| 23 | Group | varchar(250) | YES | Customer group: 'A' (Bronze/Silver/Gold, no activity), 'B' (same tiers, with activity), 'C' (Platinum+), 'Other'. (Tier 2 — SP computed) |
| 24 | Has_Open_US_Stocks_Position | int | YES | 1 if customer has open position in US stocks/ETFs (InstrumentTypeID IN 5,6 AND ISINCountryCode='US'). (Tier 2 — SP via BI_DB_PositionPnL + Dim_Instrument) |
| 25 | PlayerStatusReason | varchar(250) | YES | Player status reason name from Dim_PlayerStatusReasons via Dim_Customer.PlayerStatusReasonID. (Tier 2 — SP via Dim_PlayerStatusReasons) |
| 26 | PlayerStatusSubReasonName | varchar(250) | YES | Player status sub-reason name from Dim_PlayerStatusSubReasons via Dim_Customer.PlayerStatusSubReasonID. (Tier 2 — SP via Dim_PlayerStatusSubReasons) |
| 27 | Previous_PlayerStatus | varchar(250) | YES | Previous player status from BI_DB_AML_PlayerStatus_Changes. (Tier 2 — SP via BI_DB_AML_PlayerStatus_Changes) |
| 28 | Previous_PlayerStatus_Reason | varchar(250) | YES | Previous player status reason from BI_DB_AML_PlayerStatus_Changes. (Tier 2 — SP via BI_DB_AML_PlayerStatus_Changes) |
| 29 | Previous_PlayerStatus_Sub_Reason | varchar(250) | YES | Previous player status sub-reason from BI_DB_AML_PlayerStatus_Changes. (Tier 2 — SP via BI_DB_AML_PlayerStatus_Changes) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | passthrough via Dim_Customer.RealCID |
| GCID | Customer.CustomerStatic | GCID | passthrough via Dim_Customer |
| KYC_Country | Dictionary.Country | Name | dim-lookup passthrough via Dim_Country |
| PlayerStatus | Dictionary.PlayerStatus | Name | dim-lookup passthrough via Dim_PlayerStatus |
| Club | Dictionary.PlayerLevel | Name | dim-lookup passthrough via Dim_PlayerLevel |

### 5.2 ETL Pipeline

```
External_etoro_BackOffice_CustomerDocument (W8-BEN docs, DocumentTypeID=12)
  + External_etoro_BackOffice_CustomerDocumentToDocumentType
  + DWH_dbo.Dim_Customer (RealCID, GCID, CountryID, PlayerStatusID, PlayerLevelID, etc.)
  + DWH_dbo.Dim_Country / Dim_PlayerStatus / Dim_PlayerLevel / Dim_PlayerStatusReasons / Dim_PlayerStatusSubReasons
  + DWH_dbo.Fact_CustomerAction (ActionTypeID=14 → last login)
  + External_ComplianceStateDB (RequirementID IN 14,16,17)
  + BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Instrument (open positions, US stocks)
  + DWH_dbo.V_Liabilities (RealizedEquity, Equity)
  + BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes (previous status fields)
  |
  |-- SP_BI_DB_W8_Users_Status (daily TRUNCATE+INSERT)
  |   Step 1: Get latest W8-BEN doc per customer (ROW_NUMBER by ExpiryDate DESC, DocumentTypeID=12)
  |   Step 2: Join Dim_Customer for demographics and dim lookups
  |   Step 3: Get last login from Fact_CustomerAction (ActionTypeID=14)
  |   Step 4: Get GAP requirements from ComplianceStateDB (RequirementIDs 14,16,17)
  |   Step 5: Count open positions and detect US stocks from BI_DB_PositionPnL + Dim_Instrument
  |   Step 6: Get financial data from V_Liabilities
  |   Step 7: Compute W8_Group_Status_ID (1/2/3 based on ExpiryDate vs year-end)
  |   Step 8: Compute Group (A/B/C/Other based on PlayerLevelID and activity)
  |   Step 9: Get previous player status from BI_DB_AML_PlayerStatus_Changes
  |   Step 10: TRUNCATE + INSERT into target table
  v
BI_DB_dbo.BI_DB_W8_Users_Status (5.2M rows, HASH(CID) HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer dimension |
| KYC_Country | DWH_dbo.Dim_Country | Country lookup |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Player status lookup |
| Club | DWH_dbo.Dim_PlayerLevel | Club tier lookup |
| Open_Pos, Has_Open_US_Stocks_Position | BI_DB_dbo.BI_DB_PositionPnL | Position data |
| RealizedEquity, Equity | DWH_dbo.V_Liabilities | Financial data |
| Previous_PlayerStatus* | BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes | Previous status history |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 Expired W8 Customers with Open US Positions

```sql
SELECT CID, ExpiryDate, KYC_Country, PlayerStatus, [Group], Open_Pos, Equity
FROM BI_DB_dbo.BI_DB_W8_Users_Status
WHERE W8_Group_Status_ID = 1
  AND Has_Open_US_Stocks_Position = 1
ORDER BY Equity DESC
```

### 7.2 GAP Compliance Summary by Status

```sql
SELECT W8_Group_Status_ID,
       SUM(W8BEN_Gap_Required) AS Gap_Required,
       SUM(W8BEN_Gap_Completed) AS Gap_Completed,
       SUM(W8Ben_TIN_change_Required) AS TIN_Required,
       SUM(W8Ben_TIN_change_Completed) AS TIN_Completed
FROM BI_DB_dbo.BI_DB_W8_Users_Status
GROUP BY W8_Group_Status_ID
ORDER BY W8_Group_Status_ID
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable due to permissions).

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 5 T1, 23 T2, 0 T3, 0 T4, 1 T5 | Elements: 29/29, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_W8_Users_Status | Type: Table | Production Source: External_etoro_BackOffice_CustomerDocument + DWH_dbo.Dim_Customer + ComplianceStateDB via SP_BI_DB_W8_Users_Status*
