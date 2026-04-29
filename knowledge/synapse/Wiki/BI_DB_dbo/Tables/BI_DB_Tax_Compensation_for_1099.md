# BI_DB_dbo.BI_DB_Tax_Compensation_for_1099

> 215K-row table of US IRS 1099-reportable compensation events for US-regulated customers (eToroUS, FinCEN, FinCEN+FINRA). One row per compensation event per customer, enriched with customer PII (name, address, SSN, equity) for 1099 tax filing. Daily TRUNCATE+INSERT from BI_DB_BO_Generated_Compensations joined with Dim_Customer, Dim_PlayerStatus, Dim_State_and_Province, BI_DB_USA_FinanceReport_forTax, and V_Liabilities.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_BO_Generated_Compensations + DWH_dbo.Dim_Customer + DWH_dbo.Dim_PlayerStatus + DWH_dbo.Dim_State_and_Province + BI_DB_dbo.BI_DB_USA_FinanceReport_forTax + DWH_dbo.V_Liabilities via `SP_Tax_Compensation_for_1099` |
| **Refresh** | Daily (TRUNCATE+INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **Author** | Lior Ben Dor (2024-12-22) |
| **Row Count** | ~215,242 (as of 2026-04-26) |

---

## 1. Business Meaning

`BI_DB_Tax_Compensation_for_1099` is a US tax compliance table that captures all back-office generated compensation events issued to customers under US regulations (eToroUS, FinCEN, FinCEN+FINRA) from 2023 onward. Each row represents one compensation event for one customer, enriched with the customer's personal identifying information (name, address, SSN, equity) required for IRS Form 1099 reporting.

The table is a filtered and PII-enriched derivative of `BI_DB_BO_Generated_Compensations`, which contains all compensation events globally. This table narrows the scope to US-regulated customers only and adds tax-relevant fields (SSN from BI_DB_USA_FinanceReport_forTax, equity from V_Liabilities, full address from Dim_Customer and Dim_State_and_Province).

Grain: one compensation event per row (CID + Time + Amount combination). A single customer may have multiple rows for different compensation events.

---

## 2. Business Logic

### 2.1 US Regulation Filter

**What**: Only US-regulated compensation events are included.
**Columns Involved**: `Regulation`
**Rules**:
- Filter: `Regulation IN ('eToroUS', 'FinCEN', 'FinCEN+FINRA')`
- Year filter: `YEAR(Time) >= 2023` — no pre-2023 compensations are included
- This filter is applied at Step 1 against BI_DB_BO_Generated_Compensations.Regulation

### 2.2 Equity Calculation

**What**: Customer equity is computed from yesterday's liabilities data.
**Columns Involved**: `Equity`
**Rules**:
- `Equity = ISNULL(V_Liabilities.Liabilities, 0) + ISNULL(V_Liabilities.ActualNWA, 0)`
- Date filter: `DateID = CAST(CONVERT(CHAR(8), GETDATE()-1, 112) AS INT)` — yesterday's snapshot
- LEFT JOIN: if no V_Liabilities row exists, Equity defaults to 0
- Represents the customer's total account value (liabilities + net withdrawable amount) as of the day before the SP runs

### 2.3 SSN Lookup

**What**: Social Security Number is retrieved from the US tax finance report.
**Columns Involved**: `SSN`
**Rules**:
- Source: `BI_DB_USA_FinanceReport_forTax` joined on RealCID
- LEFT JOIN: SSN is NULL if no matching record exists or if the source SSN is NULL
- DISTINCT applied to avoid duplicates

### 2.4 Manager Name Bug (Inherited)

**What**: The Manager column contains concatenated first+last names without a space separator.
**Columns Involved**: `Manager`
**Rules**:
- This is inherited from BI_DB_BO_Generated_Compensations where the upstream SP uses `CONCAT(FirstName, '', LastName)` with empty string separator
- Values appear like 'AdminNistrator' instead of 'Admin Nistrator'
- Known production bug — do not attempt to parse

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no clustered index. For large scans, filter on YEAR or Regulation first.

### 3.2 PII Sensitivity

This table contains highly sensitive PII: SSN, FirstName, LastName, Email, full address (Address, City, State, Zip, BuildingNumber). Access should be restricted to authorized tax/compliance personnel only.

### 3.3 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| 1099 compensation totals by year | `WHERE YEAR = {year} GROUP BY CID` with `SUM(Amount)` |
| Missing SSN for 1099 filing | `WHERE SSN IS NULL AND YEAR = {year}` |
| Compensation by regulation | `GROUP BY Regulation, YEAR` |
| Customer tax profile | `WHERE CID = {cid} ORDER BY Time DESC` |

### 3.4 Gotchas

- **SSN may be NULL**: Not all US customers have SSN on file. ~some rows will have NULL SSN
- **Equity is a snapshot**: Equity reflects yesterday's value at time of SP run, not the value at time of compensation
- **Manager has no space**: Inherited bug from upstream — see Section 2.4
- **Type is always 'Compensation'**: Inherited from BI_DB_BO_Generated_Compensations (CreditTypeID=6 filter upstream)
- **Country is always United States**: The regulation filter restricts to US entities, so Country is functionally constant

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki — description copied verbatim with origin tag |
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID. Identifies the customer who received the compensation. Passthrough from BI_DB_BO_Generated_Compensations. (Tier 1 — BI_DB_BO_Generated_Compensations.CID) |
| 2 | Amount | money | YES | Compensation amount in account currency. Passthrough from BI_DB_BO_Generated_Compensations. (Tier 1 — BI_DB_BO_Generated_Compensations.Amount) |
| 3 | Type | varchar(250) | YES | Credit type name. Always 'Compensation' (CreditTypeID=6 filter applied upstream). Passthrough from BI_DB_BO_Generated_Compensations. (Tier 1 — BI_DB_BO_Generated_Compensations.Type) |
| 4 | Time | datetime | YES | Datetime of the compensation event. Passthrough from BI_DB_BO_Generated_Compensations. (Tier 1 — BI_DB_BO_Generated_Compensations.Time) |
| 5 | YEAR | int | YES | Calendar year extracted from Time. Computed as YEAR(bdbgc.Time). Filter: >= 2023. (Tier 2 — SP_Tax_Compensation_for_1099) |
| 6 | Description | varchar(max) | YES | Free-text compensation description entered by back-office. Passthrough from BI_DB_BO_Generated_Compensations. (Tier 1 — BI_DB_BO_Generated_Compensations.Description) |
| 7 | Category | varchar(max) | YES | Compensation category label from the CompensationReason dictionary. Passthrough from BI_DB_BO_Generated_Compensations. (Tier 1 — BI_DB_BO_Generated_Compensations.Category) |
| 8 | Reason | varchar(250) | YES | Secondary reason label from Dim_MoveMoneyReason. Passthrough from BI_DB_BO_Generated_Compensations. NULL in ~87% of upstream rows. (Tier 1 — BI_DB_BO_Generated_Compensations.Reason) |
| 9 | Manager | varchar(250) | YES | Full name of the back-office agent who issued the compensation (FirstName + LastName, no space — known bug). Passthrough from BI_DB_BO_Generated_Compensations. (Tier 1 — BI_DB_BO_Generated_Compensations.Manager) |
| 10 | AffiliateID | int | YES | Affiliate ID associated with the customer. Renamed from BI_DB_BO_Generated_Compensations.Affiliate. (Tier 1 — BI_DB_BO_Generated_Compensations.Affiliate) |
| 11 | Club | varchar(250) | YES | Customer player-level name at time of compensation. Renamed from BI_DB_BO_Generated_Compensations.[Player Level]. (Tier 1 — BI_DB_BO_Generated_Compensations.[Player Level]) |
| 12 | Regulation | varchar(250) | YES | Regulatory jurisdiction. Filtered to US regulations only: 'eToroUS', 'FinCEN', 'FinCEN+FINRA'. Passthrough from BI_DB_BO_Generated_Compensations. (Tier 1 — BI_DB_BO_Generated_Compensations.Regulation → Dictionary.Regulation) |
| 13 | PlayerStatus | varchar(250) | YES | Customer player status name. Resolved via Dim_Customer.PlayerStatusID -> Dim_PlayerStatus.Name. (Tier 2 — SP_Tax_Compensation_for_1099, Dim_PlayerStatus.Name) |
| 14 | VerificationLevelID | int | YES | Customer verification level identifier. Direct from Dim_Customer. (Tier 2 — SP_Tax_Compensation_for_1099, Dim_Customer.VerificationLevelID) |
| 15 | IsDepositor | int | YES | Flag indicating whether the customer has deposited funds. Direct from Dim_Customer. (Tier 2 — SP_Tax_Compensation_for_1099, Dim_Customer.IsDepositor) |
| 16 | FirstName | varchar(250) | YES | Customer first name from Dim_Customer. PII field for 1099 reporting. (Tier 2 — SP_Tax_Compensation_for_1099, Dim_Customer.FirstName) |
| 17 | LastName | varchar(250) | YES | Customer last name from Dim_Customer. PII field for 1099 reporting. (Tier 2 — SP_Tax_Compensation_for_1099, Dim_Customer.LastName) |
| 18 | Email | varchar(250) | YES | Customer email address from Dim_Customer. PII field. (Tier 2 — SP_Tax_Compensation_for_1099, Dim_Customer.Email) |
| 19 | Country | varchar(250) | YES | Full country name from customer registration form. Renamed from BI_DB_BO_Generated_Compensations.[Country (Reg Form)]. Functionally always 'United States' due to US regulation filter. (Tier 1 — BI_DB_BO_Generated_Compensations.[Country (Reg Form)]) |
| 20 | Address | varchar(250) | YES | Customer street address from Dim_Customer. PII field for 1099 reporting. (Tier 2 — SP_Tax_Compensation_for_1099, Dim_Customer.Address) |
| 21 | State | varchar(250) | YES | US state name. Resolved via Dim_Customer.RegionID -> Dim_State_and_Province.Name (LEFT JOIN on RegionByIP_ID). May be NULL if region not mapped. (Tier 2 — SP_Tax_Compensation_for_1099, Dim_State_and_Province.Name) |
| 22 | City | varchar(250) | YES | Customer city from Dim_Customer. PII field for 1099 reporting. (Tier 2 — SP_Tax_Compensation_for_1099, Dim_Customer.City) |
| 23 | BuildingNumber | varchar(250) | YES | Customer building/house number from Dim_Customer. PII field for 1099 reporting. (Tier 2 — SP_Tax_Compensation_for_1099, Dim_Customer.BuildingNumber) |
| 24 | Zip | varchar(250) | YES | Customer ZIP/postal code from Dim_Customer. PII field for 1099 reporting. (Tier 2 — SP_Tax_Compensation_for_1099, Dim_Customer.Zip) |
| 25 | SSN | varchar(250) | YES | Social Security Number from BI_DB_USA_FinanceReport_forTax. LEFT JOIN — NULL if not on file. Critical PII for 1099 filing. (Tier 2 — SP_Tax_Compensation_for_1099, BI_DB_USA_FinanceReport_forTax.SSN) |
| 26 | Equity | money | YES | Customer total equity as of yesterday: ISNULL(Liabilities,0) + ISNULL(ActualNWA,0) from V_Liabilities. Defaults to 0 if no match. Snapshot value, not compensation-time value. (Tier 2 — SP_Tax_Compensation_for_1099, V_Liabilities) |
| 27 | UpdateDate | datetime | NO | ETL execution timestamp. GETDATE() at SP execution time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Object | Layer | Role |
|---------------|-------|------|
| BI_DB_dbo.BI_DB_BO_Generated_Compensations | BI_DB | Primary — compensation events (CID, Amount, Type, Time, Description, Category, Reason, Manager, Affiliate, Player Level, Country, Regulation) |
| DWH_dbo.Dim_Customer | DWH dimension | Customer profile — VerificationLevelID, IsDepositor, FirstName, LastName, Email, Address, City, BuildingNumber, Zip, PlayerStatusID, RegionID |
| DWH_dbo.Dim_PlayerStatus | DWH dimension | PlayerStatus name resolution |
| DWH_dbo.Dim_State_and_Province | DWH dimension | US state name from RegionByIP_ID |
| BI_DB_dbo.BI_DB_USA_FinanceReport_forTax | BI_DB | SSN lookup for US tax customers |
| DWH_dbo.V_Liabilities | DWH view | Customer equity (Liabilities + ActualNWA) as of yesterday |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_BO_Generated_Compensations (bdbgc)
  |-- Filter: Regulation IN ('eToroUS','FinCEN','FinCEN+FINRA')
  |-- Filter: YEAR(Time) >= 2023
  |-- JOIN DWH_dbo.Dim_Customer (dc) ON CID = RealCID
  |-- JOIN DWH_dbo.Dim_PlayerStatus (dps) ON PlayerStatusID
  |-- LEFT JOIN DWH_dbo.Dim_State_and_Province (dsap) ON RegionID = RegionByIP_ID
  v
#pop_comp (Step 1: US-regulated compensations with customer profile)
  |
  |-- LEFT JOIN BI_DB_dbo.BI_DB_USA_FinanceReport_forTax (SSN lookup)
  v
#final (Step 3: compensations + SSN)
  |
  |-- LEFT JOIN DWH_dbo.V_Liabilities (yesterday's equity)
  |   Equity = ISNULL(Liabilities,0) + ISNULL(ActualNWA,0)
  v
#final1 (Step 3b: compensations + SSN + Equity)
  |
  |-- SP_Tax_Compensation_for_1099 (daily TRUNCATE+INSERT)
  |-- GETDATE() -> UpdateDate
  v
BI_DB_dbo.BI_DB_Tax_Compensation_for_1099 (~215K rows, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID, Amount, Type, Time, Description, Category, Reason, Manager, AffiliateID, Club, Regulation, Country | BI_DB_dbo.BI_DB_BO_Generated_Compensations | Primary upstream — US-filtered compensation events |
| PlayerStatus, VerificationLevelID, IsDepositor, FirstName, LastName, Email, Address, City, BuildingNumber, Zip | DWH_dbo.Dim_Customer | Customer profile and PII |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Player status name lookup |
| State | DWH_dbo.Dim_State_and_Province | State name from region ID |
| SSN | BI_DB_dbo.BI_DB_USA_FinanceReport_forTax | SSN for 1099 filing |
| Equity | DWH_dbo.V_Liabilities | Yesterday's customer equity |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 Total Compensation by Year for 1099 Filing

```sql
SELECT CID, FirstName, LastName, SSN, YEAR,
       SUM(Amount) AS total_compensation,
       COUNT(*) AS num_events
FROM BI_DB_dbo.BI_DB_Tax_Compensation_for_1099
WHERE YEAR = 2025
GROUP BY CID, FirstName, LastName, SSN, YEAR
ORDER BY total_compensation DESC
```

### 7.2 Customers Missing SSN (1099 Filing Gap)

```sql
SELECT CID, FirstName, LastName, Email, Regulation,
       SUM(Amount) AS total_compensation
FROM BI_DB_dbo.BI_DB_Tax_Compensation_for_1099
WHERE YEAR = 2025 AND SSN IS NULL
GROUP BY CID, FirstName, LastName, Email, Regulation
ORDER BY total_compensation DESC
```

### 7.3 Compensation Breakdown by Regulation and Category

```sql
SELECT Regulation, Category, YEAR,
       COUNT(*) AS events,
       SUM(Amount) AS total_amount,
       COUNT(DISTINCT CID) AS unique_customers
FROM BI_DB_dbo.BI_DB_Tax_Compensation_for_1099
GROUP BY Regulation, Category, YEAR
ORDER BY YEAR DESC, total_amount DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object. SP header credits Lior Ben Dor (2024-12-22) with description "Clients Compensation for 1099". No change history entries recorded.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 12 T1, 13 T2, 0 T3, 0 T4, 1 T5 | Elements: 27/27, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_Tax_Compensation_for_1099 | Type: Table | Production Source: BI_DB_BO_Generated_Compensations + Dim_Customer + V_Liabilities via SP_Tax_Compensation_for_1099*
