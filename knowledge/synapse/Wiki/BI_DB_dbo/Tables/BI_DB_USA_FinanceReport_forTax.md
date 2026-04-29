# BI_DB_dbo.BI_DB_USA_FinanceReport_forTax

> 813K-row daily US tax-related finance report for eToroUS (RegulationID=6) and FinCEN (RegulationID=7) regulated customers. Tracks compensation (ActionTypeID=36), closed positions, volume, and realized PnL per customer per day. Includes SSN (PII, masked) for IRS reporting. DELETE+INSERT by DateID via SP_USA_FinanceReport_forTax.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + Fact_CustomerAction + Dim_Position + External_UserApiDB via `SP_USA_FinanceReport_forTax` |
| **Refresh** | Daily (DELETE WHERE DateID=@DateID + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | — |
| **Row Count** | ~813,000 (as of 2026-04-27) |

---

## 1. Business Meaning

`BI_DB_USA_FinanceReport_forTax` is a daily finance report supporting IRS 1099 tax reporting and compliance for US-regulated customers. It captures:

- **Compensation**: Aggregated compensation amounts (ActionTypeID=36 from Fact_CustomerAction) per customer per day
- **Closed positions**: Count of positions closed on the reporting date
- **Volume on close**: Sum of volume at position close
- **Realized PnL**: Sum of net profit from closed positions
- **Customer demographics**: SSN/TIN (PII, masked with `default()`), City, State, AffiliateID

The population includes customers under eToroUS (RegulationID=6) and FinCEN (RegulationID=7) regulations. The SP uses a FULL OUTER JOIN between compensation and closed positions, so a customer appears if they had either compensation OR closed positions on a given day.

The SP also creates a dynamic external table for History.Credit via SP_Create_External_etoro_History_Credit, and writes to a secondary table BI_DB_USA_FinanceReport_forTax_CreditID (not this target).

As of 2026-04-27: 813K rows from DateID 20190225 to 20260411. PII table — SSN column uses dynamic data masking.

---

## 2. Business Logic

### 2.1 US Customer Population

**What**: Identifies all eToroUS and FinCEN regulated customers.
**Columns Involved**: `RealCID`, `City`, `State`, `AffiliateID`
**Rules**:
- #US: Dim_Customer WHERE RegulationID IN (6, 7) — eToroUS and FinCEN
- State resolved from Dim_State_and_Province via StateID
- City from Dim_Customer.City

### 2.2 Compensation Aggregation

**What**: Daily compensation amounts per customer.
**Columns Involved**: `Compensation`
**Rules**:
- #US_comp_CID_LastDay: CIDs with ActionTypeID=36 on @DateID from Fact_CustomerAction
- #US_comp_CID: Union of existing report CIDs + new compensation CIDs (ensures continuity)
- #US_comp: SUM(Amount) from Fact_CustomerAction WHERE ActionTypeID=36, grouped by CID + DateID

### 2.3 Closed Position Metrics

**What**: Position close activity on the reporting date.
**Columns Involved**: `ClosePositions`, `VolumeOnClose`, `Realized_PnL`
**Rules**:
- #Close_positions: From Dim_Position WHERE CloseDateID=@DateID
- ClosePositions = COUNT(*)
- VolumeOnClose = SUM(VolumeOnClose)
- Realized_PnL = SUM(NetProfit)

### 2.4 SSN/TIN Retrieval

**What**: Social Security Number or Tax Identification Number for IRS reporting.
**Columns Involved**: `SSN`
**Rules**:
- From External_UserApiDB_Customer_ExtendedUserField WHERE FieldId=6 AND CountryId=219
- PII — masked with dynamic data masking (default()) in DDL

### 2.5 Final Assembly

**What**: FULL OUTER JOIN compensation + close positions, then enrich with demographics.
**Columns Involved**: All
**Rules**:
- #CID_Date: FULL OUTER JOIN #US_comp + #Close_positions on CID and DateID
- #US_Finance: JOIN with #US (demographics) and #SSN
- Load: DELETE WHERE DateID=@DateID + INSERT

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on DateID — efficient for date-range queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily finance for a customer | `WHERE RealCID = X ORDER BY DateID DESC` |
| All activity on a date | `WHERE DateID = 20260401` |
| Customers with compensation | `WHERE Compensation IS NOT NULL AND Compensation > 0` |
| Realized PnL summary | `SELECT RealCID, SUM(Realized_PnL) ... GROUP BY RealCID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `RealCID = RealCID` | Full customer profile |
| DWH_dbo.Dim_State_and_Province | `State = Name` | State details |

### 3.4 Gotchas

- **PII table**: SSN column contains Social Security Numbers — masked with dynamic data masking. Requires UNMASK permission to view
- **City column also masked**: Uses `default()` masking function
- **FULL OUTER JOIN**: A customer appears if they had compensation OR closed positions — not necessarily both
- **DateID is int format YYYYMMDD**: Not a date type — join carefully with date dimensions
- **Column count**: DDL has 12 columns (not 13 as originally assigned)
- **Secondary table**: SP also writes to BI_DB_USA_FinanceReport_forTax_CreditID — not this table

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Reporting date in YYYYMMDD integer format. @DateID parameter from SP invocation. Clustered index key. (Tier 2 — SP_USA_FinanceReport_forTax) |
| 2 | Date | date | YES | Reporting date as date type. @Date parameter from SP invocation. (Tier 2 — SP_USA_FinanceReport_forTax) |
| 3 | RealCID | int | NO | Customer identifier. FK to Dim_Customer.RealCID. Only eToroUS (RegulationID=6) and FinCEN (RegulationID=7) customers. (Tier 1 — Customer.CustomerStatic) |
| 4 | SSN | nvarchar(128) | YES | Social Security Number or Tax Identification Number for IRS reporting. From External_UserApiDB_Customer_ExtendedUserField WHERE FieldId=6 AND CountryId=219. PII — masked with dynamic data masking. (Tier 2 — SP_USA_FinanceReport_forTax) |
| 5 | City | nvarchar(50) | YES | Customer city in Unicode. From Dim_Customer.City. Masked with dynamic data masking (default()). (Tier 1 — Customer.CustomerStatic) |
| 6 | State | varchar(100) | YES | US state name. From Dim_State_and_Province.Name via StateID join. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 7 | AffiliateID | int | YES | Affiliate identifier. From Dim_Customer.AffiliateID. Used for affiliate commission tracking. (Tier 1 — Customer.CustomerStatic) |
| 8 | Compensation | numeric(38,2) | YES | Total compensation amount for the customer on this date. SUM(Amount) from Fact_CustomerAction WHERE ActionTypeID=36. NULL if no compensation on this date. (Tier 2 — SP_USA_FinanceReport_forTax) |
| 9 | ClosePositions | int | YES | Count of positions closed on this date. COUNT(*) from Dim_Position WHERE CloseDateID=@DateID. NULL if no closes. (Tier 2 — SP_USA_FinanceReport_forTax) |
| 10 | VolumeOnClose | int | YES | Sum of trading volume at position close. SUM(VolumeOnClose) from Dim_Position. NULL if no closes. (Tier 2 — SP_USA_FinanceReport_forTax) |
| 11 | Realized_PnL | money | YES | Sum of realized profit/loss from closed positions. SUM(NetProfit) from Dim_Position. Can be negative (loss). (Tier 2 — SP_USA_FinanceReport_forTax) |
| 12 | UpdateDate | datetime | NO | ETL execution timestamp. GETDATE() at SP execution time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | Customer.CustomerStatic | CID | passthrough via Dim_Customer |
| City | Customer.CustomerStatic | City | passthrough via Dim_Customer |
| AffiliateID | Customer.CustomerStatic | AffiliateID | passthrough via Dim_Customer |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (RegulationID IN 6,7 — eToroUS + FinCEN)
  + DWH_dbo.Dim_State_and_Province (State name)
  + DWH_dbo.Fact_CustomerAction (compensation — ActionTypeID=36)
  + DWH_dbo.Dim_Position (closed positions, volume, net profit)
  + External_UserApiDB_Customer_ExtendedUserField (SSN — FieldId=6, CountryId=219)
  + History.Credit (dynamic external table)
  |
  |-- SP_USA_FinanceReport_forTax @DateID, @Date
  |   Step 1: #US — US regulated customers + state
  |   Step 2: #US_comp — compensation aggregation (ActionTypeID=36)
  |   Step 3: #Close_positions — close count, volume, PnL
  |   Step 4: #SSN — SSN/TIN from extended user fields
  |   Step 5: #CID_Date — FULL OUTER JOIN compensation + closes
  |   Step 6: #US_Finance — enrich with demographics + SSN
  |   DELETE WHERE DateID=@DateID + INSERT
  v
BI_DB_dbo.BI_DB_USA_FinanceReport_forTax (813K rows, ROUND_ROBIN CI(DateID))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer (RealCID) | Customer dimension |
| Compensation | DWH_dbo.Fact_CustomerAction | ActionTypeID=36 compensation amounts |
| ClosePositions, VolumeOnClose, Realized_PnL | DWH_dbo.Dim_Position | Closed position metrics |
| SSN | External_UserApiDB_Customer_ExtendedUserField | Tax ID (PII) |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 Customer Tax Summary for a Year

```sql
SELECT RealCID,
       SUM(Compensation) AS TotalCompensation,
       SUM(ClosePositions) AS TotalCloses,
       SUM(Realized_PnL) AS TotalPnL
FROM BI_DB_dbo.BI_DB_USA_FinanceReport_forTax
WHERE DateID BETWEEN 20250101 AND 20251231
GROUP BY RealCID
ORDER BY TotalPnL DESC
```

### 7.2 Daily Compensation Activity

```sql
SELECT DateID, COUNT(DISTINCT RealCID) AS CustomersWithComp,
       SUM(Compensation) AS TotalCompensation
FROM BI_DB_dbo.BI_DB_USA_FinanceReport_forTax
WHERE Compensation > 0
GROUP BY DateID
ORDER BY DateID DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 3 T1, 8 T2, 0 T3, 0 T4, 1 T5 | Elements: 12/12, Logic: 8/10, Lineage: 7/10*
*Object: BI_DB_dbo.BI_DB_USA_FinanceReport_forTax | Type: Table | Production Source: Dim_Customer + Fact_CustomerAction + Dim_Position via SP_USA_FinanceReport_forTax*
