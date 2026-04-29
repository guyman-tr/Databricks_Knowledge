# BI_DB_dbo.BI_DB_Tax_1099_PartB

> US IRS Form 1099-B Part B (individual transaction detail) for reportable securities dispositions. One row per settled position closed during the tax year for customers in the 1099 reporting population. Contains cost basis, gross proceeds, net profit, holding period classification, and taxpayer identification. TRUNCATE+INSERT via SP_Tax_1099_PartB, guarded by post-year-end date and Fivetran sync window.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + Dim_Instrument + Dim_Customer + Fact_SnapshotCustomer + External_Fivetran_google_sheets_population_1_1099 via `SP_Tax_1099_PartB` |
| **Refresh** | Annual (TRUNCATE+INSERT, runs post-year-end within 3 days of last Fivetran sync) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **Author** | Adi Meidan (2024-10-01) |
| **Row Count** | 0 (as of 2026-04-26 — table is populated during annual 1099 tax reporting cycle only) |

---

## 1. Business Meaning

`BI_DB_Tax_1099_PartB` is the US IRS Form 1099-B Part B transaction-level detail table. It captures individual position dispositions (closed trades) for customers who are part of the annual 1099 reporting population. Each row represents one closed position for one customer during the tax year, containing all fields required for 1099-B reporting: cost basis, gross proceeds, net profit/loss, long-term vs short-term classification, instrument identifiers (ISIN, CUSIP), and taxpayer identification number (TIN).

The 1099 reporting population is externally managed via a Google Sheets list ingested through Fivetran (`External_Fivetran_google_sheets_population_1_1099`). The SP only fires post-year-end and within a narrow 3-day window after the population list is synced, ensuring the population is finalized before generating the report.

As of 2026-04-26: 0 rows (the table is empty between annual runs — it is truncated and reloaded each cycle).

---

## 2. Business Logic

### 2.1 Execution Guard

**What**: The SP only executes under strict timing conditions.
**Rules**:
- @Date must be AFTER the last day of the reporting year (derived from `External_Fivetran_google_sheets_population_1_1099.report_year`)
- @Date must be >= DATEADD(dd, 1, last Fivetran sync date) AND <= DATEADD(dd, 3, last Fivetran sync date)
- If conditions are not met, SP prints 'not yet' and exits without writing

### 2.2 Position Eligibility

**What**: Only settled, bought positions on US exchanges or with US ISIN are included.
**Columns Involved**: `Gross_Proceed`, `Cost`, `NetProfit`, `IsLongTerm`, `CloseDate`, `OpenDate`
**Rules**:
- IsBuy = 1 (buy-side positions only)
- IsSettled = 1 (settled positions only)
- InstrumentTypeID IN (5, 6) on Nasdaq/NYSE exchanges, OR ISINCode starts with 'US', OR ISINCountryCode = 'US'
- CloseDateID must fall within the reporting year (first day to last day)

### 2.3 Long-Term / Short-Term Classification

**What**: IRS holding period determination.
**Columns Involved**: `IsLongTerm`
**Rules**:
- DATEDIFF(DAY, OpenOccurred, CloseOccurred) >= 365 = 'Yes' (long-term)
- Otherwise = 'No' (short-term)
- This aligns with IRS 1-year holding period rule for capital gains classification

### 2.4 End-of-Year Regulation

**What**: Customer's regulation as of December 31 of the reporting year.
**Columns Involved**: `Regulation_EOY`
**Rules**:
- Resolved via Fact_SnapshotCustomer + Dim_Range using @lastDayOfYearDateID
- Captures the customer's regulatory status at year-end, not at trade date

### 2.5 TIN Resolution

**What**: US Taxpayer Identification Number retrieval.
**Columns Involved**: `TIN_Value`
**Rules**:
- Source: ExtendedUserField where FieldId = 6, CountryID = 219 (US)
- If Value length is 0 or 1, replaced with string 'Null'
- When multiple TIN records exist for a CID, ROW_NUMBER partitioned by CID, ordered by TIN_CountryID — first record used (LEFT JOIN, so NULL if no TIN)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no clustered index. Table is designed for full-scan bulk export during tax season.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All positions for a specific customer | `WHERE RealCID = X` |
| Long-term vs short-term breakdown | `GROUP BY IsLongTerm` with SUM(Gross_Proceed), SUM(NetProfit) |
| Positions by regulation at year-end | `GROUP BY Regulation_EOY` |
| Missing TIN records | `WHERE TIN_Value = 'Null' OR TIN_Value IS NULL` |

### 3.3 Gotchas

- **Table is empty most of the year**: Data only exists during the annual 1099 processing window. Do not assume 0 rows = broken pipeline.
- **TIN_Value = 'Null' (string)**: Missing TINs are stored as the string literal 'Null', not SQL NULL.
- **Gross_Proceed = Cost + NetProfit**: This is a computed field; do not sum Gross_Proceed AND NetProfit together (double-counting).
- **No history**: TRUNCATE+INSERT replaces all data each run. No historical snapshots.
- **PII content**: Contains customer names, email, TIN — handle as PII/sensitive.

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
| 1 | RealCID | int | NO | Customer real CID. Join key to Dim_Customer. Identifies the 1099 reporting subject. Population sourced from External_Fivetran_google_sheets_population_1_1099. (Tier 2 — SP_Tax_1099_PartB, Dim_Customer.RealCID) |
| 2 | Regulation_EOY | varchar(50) | YES | Customer regulation name as of December 31 of the reporting year. Resolved via Fact_SnapshotCustomer + Dim_Range at @lastDayOfYearDateID, then Dim_Regulation.Name. (Tier 2 — SP_Tax_1099_PartB, Dim_Regulation.Name via Fact_SnapshotCustomer) |
| 3 | ClientName | nvarchar(200) | YES | Full client name. CONCAT(FirstName, ' ', MiddleName, ' ', LastName) from Dim_Customer. Used for 1099-B payee name field. (Tier 2 — SP_Tax_1099_PartB, Dim_Customer.FirstName + MiddleName + LastName) |
| 4 | Client_Middle_Name | nvarchar(50) | YES | Client middle name. Direct from Dim_Customer.MiddleName. (Tier 2 — SP_Tax_1099_PartB, Dim_Customer.MiddleName) |
| 5 | Client_Surname | nvarchar(50) | YES | Client last name / surname. Direct from Dim_Customer.LastName. (Tier 2 — SP_Tax_1099_PartB, Dim_Customer.LastName) |
| 6 | Email | varchar(50) | YES | Client email address. Direct from Dim_Customer.Email. (Tier 2 — SP_Tax_1099_PartB, Dim_Customer.Email) |
| 7 | TIN_Value | nvarchar(4000) | YES | US Taxpayer Identification Number. From ExtendedUserField (FieldId=6, CountryID=219). Short/empty values replaced with string 'Null'. LEFT JOIN — may be NULL if no TIN on file. (Tier 2 — SP_Tax_1099_PartB, External_UserApiDB_Customer_ExtendedUserField.Value) |
| 8 | Gross_Proceed | money | YES | Gross proceeds from position disposal. Computed: Amount + NetProfit from Dim_Position. Represents total sale value for 1099-B Box 1d. (Tier 2 — SP_Tax_1099_PartB, Dim_Position.Amount + NetProfit) |
| 9 | Cost | money | YES | Cost basis (original investment amount). Direct from Dim_Position.Amount. Represents 1099-B Box 1e. (Tier 2 — SP_Tax_1099_PartB, Dim_Position.Amount) |
| 10 | NetProfit | money | YES | Net profit or loss on the position. Direct from Dim_Position.NetProfit. Gross_Proceed minus Cost. (Tier 2 — SP_Tax_1099_PartB, Dim_Position.NetProfit) |
| 11 | IsLongTerm | varchar(3) | YES | IRS holding period classification. 'Yes' if held >= 365 days (DATEDIFF(DAY, OpenOccurred, CloseOccurred) >= 365), 'No' otherwise. Maps to 1099-B Box 2 (short-term vs long-term). (Tier 2 — SP_Tax_1099_PartB, computed from Dim_Position.OpenOccurred/CloseOccurred) |
| 12 | CloseDate | date | YES | Position close (disposal) date. CAST(Dim_Position.CloseOccurred AS DATE). Maps to 1099-B Box 1c (date sold). (Tier 2 — SP_Tax_1099_PartB, Dim_Position.CloseOccurred) |
| 13 | OpenDate | date | YES | Position open (acquisition) date. CAST(Dim_Position.OpenOccurred AS DATE). Maps to 1099-B Box 1b (date acquired). (Tier 2 — SP_Tax_1099_PartB, Dim_Position.OpenOccurred) |
| 14 | InstrumentDisplayName | varchar(100) | YES | Instrument display name from Dim_Instrument. Human-readable security name. Maps to 1099-B Box 1a (description of property). (Tier 2 — SP_Tax_1099_PartB, Dim_Instrument.InstrumentDisplayName) |
| 15 | ISINCode | varchar(100) | YES | International Securities Identification Number. From Dim_Instrument.ISINCode. Used for security identification; filtered to US-prefixed ISINs or US exchanges. (Tier 2 — SP_Tax_1099_PartB, Dim_Instrument.ISINCode) |
| 16 | Exchange | varchar(100) | YES | Stock exchange name. From Dim_Instrument.Exchange. Filtered to Nasdaq/NYSE for InstrumentTypeID 5,6. (Tier 2 — SP_Tax_1099_PartB, Dim_Instrument.Exchange) |
| 17 | CUSIP | varchar(500) | YES | Committee on Uniform Securities Identification Procedures number. From Dim_Instrument.CUSIP. Standard US security identifier for 1099-B reporting. (Tier 2 — SP_Tax_1099_PartB, Dim_Instrument.CUSIP) |
| 18 | PositionID | bigint | YES | Unique position identifier from Dim_Position. Grain column — one row per closed position. (Tier 2 — SP_Tax_1099_PartB, Dim_Position.PositionID) |
| 19 | UpdateDate | date | NO | ETL execution timestamp. GETDATE() at SP runtime. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Regulation_EOY | Dictionary.Regulation | Name | via Fact_SnapshotCustomer end-of-year snapshot |
| ClientName, Client_Middle_Name, Client_Surname, Email | Customer.CustomerStatic | FirstName, MiddleName, LastName, Email | via Dim_Customer |
| Gross_Proceed, Cost, NetProfit, IsLongTerm, CloseDate, OpenDate, PositionID | Position data | Amount, NetProfit, OpenOccurred, CloseOccurred, PositionID | via Dim_Position |
| InstrumentDisplayName, ISINCode, Exchange, CUSIP | Instrument data | InstrumentDisplayName, ISINCode, Exchange, CUSIP | via Dim_Instrument |
| TIN_Value | UserApiDB | ExtendedUserField.Value | FieldId=6, CountryID=219 |

### 5.2 ETL Pipeline

```
External_Fivetran_google_sheets_population_1_1099 (1099 population list, report_year)
  + DWH_dbo.Dim_Date (year boundaries)
  |
  |-- Guard: @Date > lastDayOfYear AND within 3 days of last Fivetran sync
  |
  +-- #Users1099 (RealCID, GCID, PlayerStatus, Regulation, FTD)
  |     via Dim_Customer + Dim_PlayerStatus + Dim_Regulation
  |
  +-- #pop (RealCID, GCID, Regulation, FirstName, MiddleName, LastName, Email)
  |     via Dim_Customer + Dim_Regulation
  |
  +-- #regulation_EOY (RealCID, Regulation_EOY)
  |     via Fact_SnapshotCustomer + Dim_Range + Dim_Regulation at year-end snapshot
  |
  +-- #extended_user_field → #usertaxdataone → #taxdata (CID, TIN_Value)
  |     via ExtendedUserField (FieldId=6) + KYC_CountryTaxType + ExtendedUserValueType
  |     filtered to CountryID=219 (US), ROW_NUMBER to deduplicate
  |
  +-- #positions (CID, Gross_Proceed, Cost, NetProfit, IsLongTerm, dates, instrument fields)
  |     via Dim_Position + Dim_Instrument
  |     IsBuy=1, IsSettled=1, US exchange/ISIN, closed within reporting year
  |
  v
  #final = JOIN(#pop, #positions, #regulation_EOY, LEFT JOIN #taxdata)
  |
  |-- TRUNCATE BI_DB_Tax_1099_PartB
  |-- INSERT INTO BI_DB_Tax_1099_PartB
  v
BI_DB_dbo.BI_DB_Tax_1099_PartB (ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer (RealCID) | Customer dimension — demographics, name, email |
| Regulation_EOY | DWH_dbo.Dim_Regulation (Name) | Regulation name via end-of-year snapshot |
| Regulation_EOY | DWH_dbo.Fact_SnapshotCustomer | Point-in-time regulation resolution |
| TIN_Value | BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField | Tax ID from extended user fields |
| Gross_Proceed, Cost, NetProfit, PositionID | DWH_dbo.Dim_Position | Position financial data |
| InstrumentDisplayName, ISINCode, Exchange, CUSIP | DWH_dbo.Dim_Instrument | Instrument identifiers |
| (population) | BI_DB_dbo.External_Fivetran_google_sheets_population_1_1099 | 1099 reporting population and year |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers in the current wiki inventory. Likely consumed by external tax reporting/filing systems.

---

## 7. Sample Queries

### 7.1 Customer 1099-B Summary

```sql
SELECT RealCID, ClientName, Regulation_EOY,
       COUNT(*) AS position_count,
       SUM(Gross_Proceed) AS total_proceeds,
       SUM(Cost) AS total_cost,
       SUM(NetProfit) AS total_pnl
FROM BI_DB_dbo.BI_DB_Tax_1099_PartB
GROUP BY RealCID, ClientName, Regulation_EOY
ORDER BY total_proceeds DESC
```

### 7.2 Long-Term vs Short-Term Breakdown

```sql
SELECT IsLongTerm,
       COUNT(*) AS positions,
       SUM(Gross_Proceed) AS total_proceeds,
       SUM(NetProfit) AS total_pnl
FROM BI_DB_dbo.BI_DB_Tax_1099_PartB
GROUP BY IsLongTerm
```

### 7.3 Missing TIN Report

```sql
SELECT RealCID, ClientName, Email
FROM BI_DB_dbo.BI_DB_Tax_1099_PartB
WHERE TIN_Value = 'Null' OR TIN_Value IS NULL
GROUP BY RealCID, ClientName, Email
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources identified for this object. The 1099 reporting process may be documented in Finance/Compliance team spaces.

---

*Generated: 2026-04-26 | Quality: 7.5/10 | Phases: 14/14*
*Tiers: 0 T1, 18 T2, 0 T3, 0 T4, 1 T5 | Elements: 19/19, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Tax_1099_PartB | Type: Table | Production Source: Dim_Position + Dim_Instrument + Dim_Customer + Fivetran 1099 population via SP_Tax_1099_PartB*
