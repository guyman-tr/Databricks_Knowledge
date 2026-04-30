# BI_DB_dbo.BI_DB_EY_Audit_CashoutFees

> 6.1M-row EY audit table tracking processed cashout fees per withdrawal, enriched with customer regulation, country, eToro Club tier, account type, and Popular Investor status from the daily customer snapshot. Data spans 2023-01-01 to 2025-10-27 (1,028 distinct dates). Refreshed daily by SP_EY_Audit_CashoutFees via DELETE+INSERT per DateID.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Sources** | DWH_dbo.Fact_CustomerAction (ActionTypeID=30, processed cashouts) + DWH_dbo.Fact_SnapshotCustomer (customer attributes) + 5 dimension lookups |
| **Refresh** | Daily via SP_EY_Audit_CashoutFees (DELETE+INSERT per DateID, auto gap-fill for missing dates) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC, WithdrawID ASC) |
| | |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_EY_Audit_CashoutFees` is an audit-oriented BI table built for EY (Ernst & Young) regulatory audit reporting. It captures every processed cashout event (ActionTypeID=30 in Fact_CustomerAction) where the customer passes the credit report validity check (IsCreditReportValidCB=1) and the cashout is not a redeem (IsRedeem=0).

Each row represents one withdrawal (WithdrawID) on a given date, enriched with the customer's snapshot-state attributes at the time of the cashout: regulatory jurisdiction, eToro Club loyalty tier, registered country, account type, and Popular Investor program status. The Commission column is the negated sum of commissions (cashout fees) charged on the withdrawal, aggregated per WithdrawID.

The table is populated by `SP_EY_Audit_CashoutFees` (Author: Guy Manova, 2023-07-26). The SP accepts a @date parameter, performs a DELETE+INSERT for that date, and includes auto-completion logic that detects gaps between the last loaded date and the target date, recursively calling itself to fill missing dates.

The core query joins Fact_CustomerAction to Fact_SnapshotCustomer (on RealCID with Dim_Range date-range bridging), then enriches via five dimension lookups (Dim_Regulation, Dim_PlayerLevel, Dim_Country, Dim_AccountType, Dim_GuruStatus). Only rows where IsCreditReportValidCB=1 are included, ensuring the audit population matches credit bureau reporting eligibility criteria.

As of 2025-10-27: ~6.1M rows, 1,028 distinct dates, 147 distinct countries, 11 distinct regulations. Commission is predominantly 0.0 (most processed cashouts carry no fee).

---

## 2. Business Logic

### 2.1 Cashout Fee Extraction — ActionTypeID=30

**What**: The table captures only processed cashout events, not cashout requests or other cashout-related actions.

**Columns Involved**: All columns (source filter on Fact_CustomerAction)

**Rules**:
- ActionTypeID=30 (Processed Cashout) is the sole event filter — excludes ActionTypeID=8 (Cashout), ActionTypeID=10 (Cashout request), ActionTypeID=42 (Cashout Rollback)
- IsRedeem=0 — excludes redeem-based cashouts
- IsCreditReportValidCB=1 on Fact_SnapshotCustomer — ensures the customer meets credit bureau reporting eligibility (excludes demo accounts, blocked countries, excluded labels)
- Commission is negated (-1 * SUM) and aggregated per WithdrawID — multiple commission rows for the same withdrawal are summed into a single cashout fee amount

### 2.2 Customer Snapshot Point-in-Time Join

**What**: Customer attributes are resolved from Fact_SnapshotCustomer at the time of the cashout event, not the customer's current state.

**Columns Involved**: `Regulation`, `Club`, `Country`, `AccountType`, `PopularInvestors`

**Rules**:
- Fact_SnapshotCustomer is joined on RealCID with Dim_Range bridging: `f.DateRangeID = DR.DateRangeID AND ca.DateID BETWEEN DR.FromDateID AND DR.ToDateID`
- This ensures the customer's regulation, country, club tier, etc. reflect the state that was active on the cashout date
- If a customer changed regulation mid-year, the cashout row picks up the regulation that was in effect on that specific day

### 2.3 Date Gap-Fill Auto-Completion

**What**: The SP detects missing dates between the last loaded DateID and the target @date, and recursively fills them.

**Columns Involved**: `DateID`

**Rules**:
- On each execution, the SP checks MAX(DateID) against the target date
- If gaps exist, it iterates day-by-day calling itself recursively for each missing date
- This ensures continuous daily coverage even if the orchestration skips days

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN distribution means no data locality optimization — queries scan all distributions equally. The CLUSTERED INDEX on (DateID, WithdrawID) provides efficient date-range scans and per-withdrawal lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total cashout fees for a date range | `WHERE DateID BETWEEN @start AND @end` — leverages clustered index |
| Cashout fees by regulation | `GROUP BY Regulation WHERE DateID BETWEEN @start AND @end` |
| Cashout fees for a specific customer | `WHERE RealCID = @cid` |
| Withdrawals with non-zero fees | `WHERE Commission > 0` |
| Audit report by country and club tier | `GROUP BY Country, Club` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Date | ON DateID | Calendar attributes (month, quarter, year) |
| DWH_dbo.Dim_Customer | ON RealCID | Additional customer attributes not in the audit table |

### 3.4 Gotchas

- **Category is always 'CashOut'**: This is a hardcoded literal in the SP, not a variable. Do not filter on it expecting variation — every row has the same value.
- **Commission is NEGATED**: The SP applies `-1 * SUM(ca.Commission)`. In Fact_CustomerAction, cashout commissions are typically negative; the negation here makes them positive for reporting. A value of 0.0 means no fee was charged.
- **Point-in-time snapshot**: Customer attributes (Regulation, Country, Club, etc.) reflect the state at the cashout date, not the customer's current state. Comparing this table to current Dim_Customer values may show differences for customers who changed regulation or country.
- **IsCreditReportValidCB filter**: Not all customers appear — only those passing the credit bureau validity check (excludes demo, blocked countries, excluded labels). This is an audit-population filter, not a general cashout log.
- **Commission is aggregated per WithdrawID**: If Fact_CustomerAction has multiple rows for the same WithdrawID (rare), they are summed into a single row here.
- **No UC migration**: This table is BI_DB audit-specific and has no Unity Catalog target.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 | Upstream wiki verbatim (dim-lookup passthrough to production origin) |
| 3 stars | Tier 2 | SP code / ETL-computed |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Date of the cashout event as integer YYYYMMDD. Derived from the SP @date parameter: CAST(CONVERT(VARCHAR(8), @sdate, 112) AS INT). Part of the clustered index. (Tier 2 — SP_EY_Audit_CashoutFees) |
| 2 | RealCID | int | YES | Real-account Customer ID. HASH distribution key in source. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 3 | WithdrawID | bigint | YES | Withdrawal request ID for cashout events. 0 for non-cashout events. Part of the clustered index. (Tier 1 — History.Credit) |
| 4 | Occurred | datetime | YES | UTC timestamp when the action occurred. For credits: when the credit was recorded. (Tier 1 — source-dependent) |
| 5 | Regulation | varchar(100) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Passthrough from Dim_Regulation. 11 distinct values in 2025: CySEC, FCA, FSA Seychelles, FinCEN+FINRA, ASIC & GAML, FSRA, BVI, ASIC, eToroUS, MAS, FinCEN. (Tier 1 — Dictionary.Regulation) |
| 6 | Club | varchar(100) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel. (Tier 1 — Dictionary.PlayerLevel) |
| 7 | Country | varchar(100) | YES | Full country name in English. Unique per row in Dim_Country. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. 147 distinct values in 2025 data. (Tier 1 — Dictionary.Country) |
| 8 | AccountType | varchar(100) | YES | Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification. Passthrough from Dim_AccountType. (Tier 1 — Dictionary.AccountType) |
| 9 | PopularInvestors | varchar(100) | YES | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Passthrough from Dim_GuruStatus. (Tier 1 — Dictionary.GuruStatus) |
| 10 | Category | varchar(100) | YES | Hardcoded literal 'CashOut' for all rows. No variation — every row in this table represents a cashout event. (Tier 2 — SP_EY_Audit_CashoutFees) |
| 11 | Commission | float | YES | Cashout fee amount per withdrawal. Computed as -1 * SUM(ca.Commission) from Fact_CustomerAction — negates and aggregates the source commission. Predominantly 0.0 (most processed cashouts carry no fee). (Tier 2 — Fact_CustomerAction) |
| 12 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() when SP_EY_Audit_CashoutFees runs. Not a business date. (Tier 2 — SP_EY_Audit_CashoutFees) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| DateID | SP parameter | @sdate | CAST(CONVERT(VARCHAR(8), @sdate, 112) AS INT) |
| RealCID | Fact_CustomerAction | RealCID | Passthrough |
| WithdrawID | Fact_CustomerAction | WithdrawID | Passthrough |
| Occurred | Fact_CustomerAction | Occurred | Passthrough |
| Regulation | Dim_Regulation | Name | Dim-lookup via FSC.RegulationID = dr1.DWHRegulationID |
| Club | Dim_PlayerLevel | Name | Dim-lookup via FSC.PlayerLevelID = dpl.PlayerLevelID |
| Country | Dim_Country | Name | Dim-lookup via FSC.CountryID = dc.CountryID |
| AccountType | Dim_AccountType | Name | Dim-lookup via FSC.AccountTypeID = dat.AccountTypeID |
| PopularInvestors | Dim_GuruStatus | GuruStatusName | Dim-lookup via FSC.GuruStatusID = dgs.GuruStatusID |
| Category | (literal) | 'CashOut' | Hardcoded string |
| Commission | Fact_CustomerAction | Commission | -1 * SUM(Commission) per WithdrawID |
| UpdateDate | (ETL) | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (ActionTypeID=30, IsRedeem=0)
  + DWH_dbo.Fact_SnapshotCustomer (IsCreditReportValidCB=1)
    + DWH_dbo.Dim_Range (date-range bridging)
    + DWH_dbo.Dim_Regulation (Name)
    + DWH_dbo.Dim_PlayerLevel (Name)
    + DWH_dbo.Dim_Country (Name)
    + DWH_dbo.Dim_AccountType (Name)
    + DWH_dbo.Dim_GuruStatus (GuruStatusName)
  --> SP_EY_Audit_CashoutFees(@date)
      [DELETE WHERE DateID = @sdateID]
      [INSERT INTO #cashoutfees ... GROUP BY WithdrawID]
      [INSERT INTO BI_DB_EY_Audit_CashoutFees FROM #cashoutfees]
  --> BI_DB_dbo.BI_DB_EY_Audit_CashoutFees (6.1M rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source 1 | DWH_dbo.Fact_CustomerAction | Processed cashouts (ActionTypeID=30), non-redeem |
| Source 2 | DWH_dbo.Fact_SnapshotCustomer | Customer snapshot with IsCreditReportValidCB=1 |
| Bridge | DWH_dbo.Dim_Range | Resolves DateRangeID to active date range for point-in-time join |
| Lookups | Dim_Regulation, Dim_PlayerLevel, Dim_Country, Dim_AccountType, Dim_GuruStatus | Dimension name resolution |
| ETL | SP_EY_Audit_CashoutFees (Author: Guy Manova, 2023-07-26) | DELETE+INSERT per DateID. Auto gap-fill for missing dates. |
| Target | BI_DB_dbo.BI_DB_EY_Audit_CashoutFees | 6.1M rows, ROUND_ROBIN, CI(DateID, WithdrawID) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer demographics (implicit FK) |
| DateID | DWH_dbo.Dim_Date | Calendar attributes (implicit FK) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_EY_Audit_CashoutFees | (writer) | Populates this table daily |

---

## 7. Sample Queries

### 7.1 Total cashout fees by regulation for a month

```sql
SELECT
    Regulation,
    COUNT(DISTINCT WithdrawID) AS withdrawal_count,
    SUM(Commission) AS total_fees
FROM [BI_DB_dbo].[BI_DB_EY_Audit_CashoutFees]
WHERE DateID BETWEEN 20250901 AND 20250930
GROUP BY Regulation
ORDER BY total_fees DESC;
```

### 7.2 Daily cashout volume by country (top 10)

```sql
SELECT TOP 10
    Country,
    COUNT(*) AS cashout_count,
    SUM(Commission) AS total_fees
FROM [BI_DB_dbo].[BI_DB_EY_Audit_CashoutFees]
WHERE DateID = 20251027
GROUP BY Country
ORDER BY cashout_count DESC;
```

### 7.3 Popular Investor tier breakdown for cashouts with fees

```sql
SELECT
    PopularInvestors,
    COUNT(*) AS cashout_count,
    SUM(Commission) AS total_fees
FROM [BI_DB_dbo].[BI_DB_EY_Audit_CashoutFees]
WHERE Commission > 0
  AND DateID BETWEEN 20250101 AND 20251027
GROUP BY PopularInvestors
ORDER BY total_fees DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 7 T1, 5 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 12/12, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_EY_Audit_CashoutFees | Type: Table | Production Source: DWH_dbo.Fact_CustomerAction + DWH_dbo.Fact_SnapshotCustomer + 5 dimension lookups*
