# BI_DB_dbo.BI_DB_Tax_1099_PartA

> 1,701-row US IRS Form 1099 Part A tax reporting table. One row per customer in the 1099 population, containing gross proceeds, position counts, and dividend breakdowns by IRS tax code for US-listed instruments (real stocks and CFDs). Populated annually via conditional TRUNCATE+INSERT from SP_1099_part_A.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | External_Fivetran_google_sheets_population_1_1099 + DWH_dbo.Dim_Customer + DWH_dbo.Dim_Position + BI_DB_DailyDividendsByPosition via `SP_1099_part_A` |
| **Refresh** | Conditional TRUNCATE+INSERT (runs only when @Date > reporting year end and within 3 days of Fivetran sync) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~1,701 (as of 2026-04-26) |

---

## 1. Business Meaning

`BI_DB_Tax_1099_PartA` is the primary data source for US IRS Form 1099-B / 1099-DIV Part A reporting. Each row represents one customer from a population list maintained in a Google Sheets source (synced via Fivetran), enriched with their trading activity on US-listed instruments during the reporting calendar year.

The table captures:
- **Customer identity**: RealCID, GCID, player status, regulation (current and end-of-year), first deposit date, TIN (US Tax Identification Number), and block date if applicable.
- **Gross proceeds**: Summed (Amount + NetProfit) for closed positions on US exchanges (NYSE/Nasdaq) or US-ISIN instruments, split by long real stock, long CFD, and short CFD.
- **Position counts**: Number of closed positions per category.
- **Dividend income**: Aggregated from BI_DB_DailyDividendsByPosition, split by settlement type (real vs. CFD) and by 14 IRS tax codes (0, 1, 6, 8, 9, 23, 27, 33, 35, 36, 37, 40, 78).
- **Last login**: Country and date of last login, with special handling for blocked customers (uses pre-block login).

Population is driven by `External_Fivetran_google_sheets_population_1_1099` which lists CIDs for the reporting year. The SP only executes when the current date is past the reporting year-end and within a 3-day window of the latest Fivetran sync.

---

## 2. Business Logic

### 2.1 Conditional Execution Guard

**What**: The SP only runs if `@Date > @lastDayOfYear AND @Date >= DATEADD(dd,1,@LastDateUpdated) AND @Date <= DATEADD(dd,3,@LastDateUpdated)`. Otherwise it prints 'not yet' and exits.
**Columns Involved**: All (no data written if guard fails)
**Rules**:
- @lastDayOfYear is derived from the MAX(FullDate) of the reporting year in Dim_Date
- @LastDateUpdated is the MAX(_fivetran_synced) date from the population sheet
- This ensures data is only generated after the tax year closes and the population list is fresh

### 2.2 End-of-Year Regulation Snapshot

**What**: Captures the customer's regulation as of December 31 of the reporting year.
**Columns Involved**: `Regulation_EOY`
**Rules**:
- Uses Fact_SnapshotCustomer joined via Dim_Range where @lastDayOfYearDateID falls BETWEEN FromDateID AND ToDateID
- Resolves RegulationID to Dim_Regulation.Name

### 2.3 Block Date Detection

**What**: Identifies earliest date a customer was in a blocked state.
**Columns Involved**: `BlockDate`
**Rules**:
- MIN(FromDateID) from Fact_SnapshotCustomer where PlayerStatusID IN (2, 4, 9) — these represent blocked/restricted statuses
- NULL if the customer was never blocked

### 2.4 TIN Resolution

**What**: Retrieves US Tax Identification Number from extended user fields.
**Columns Involved**: `TIN_Value`
**Rules**:
- Source: External_UserApiDB_Customer_ExtendedUserField WHERE FieldId=6
- Filtered to CountryID=219 (United States)
- Short/empty values mapped to 'Null': `CASE WHEN LEN(ISNULL(Value, 0)) IN (0, 1) THEN 'Null' ELSE Value END`
- When multiple TINs exist for US, ROW_NUMBER by TIN_CountryID takes the first

### 2.5 Gross Proceeds Calculation

**What**: Aggregates closed position proceeds for US-listed instruments during the reporting year.
**Columns Involved**: `Gross_Proceeds_LongReal`, `Gross_Proceeds_LongCFD`, `Gross_Proceeds_ShortCFD`, position count columns
**Rules**:
- US filter: InstrumentTypeID IN (5,6) on Nasdaq/NYSE exchanges, OR ISIN starts with 'US', OR ISINCountryCode='US'
- Close date within reporting year
- Gross Proceeds = SUM(Amount + NetProfit)
- Split by IsBuy (1=long, 0=short) and IsSettled (1=real, 0=CFD)

### 2.6 Dividend Tax Code Breakdown

**What**: Aggregates dividends from BI_DB_DailyDividendsByPosition, split by settlement type and IRS tax code.
**Columns Involved**: All `Dividends_*` columns
**Rules**:
- Same US instrument filter as positions
- DateID within reporting year
- Each tax code column: SUM(Amount) WHERE IsBuy/IsSettled match AND TaxCode = N
- 14 tax codes: 0, 1, 6, 8, 9, 23, 27, 33, 35, 36, 37, 40, 78

### 2.7 Last Login Country Logic

**What**: Determines last login country with blocked-customer override.
**Columns Involved**: `LastLogInCountry`, `LastLogDate`
**Rules**:
- For blocked customers: last login BEFORE BlockDate (Fact_CustomerAction WHERE ActionTypeID=14 AND DateID <= BlockDate)
- For non-blocked customers: most recent login overall
- Country resolved via Dim_Country.Name joined on CountryIDByIP

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no clustered index. For single-customer lookups, filter on RealCID. Full table scans are acceptable given the small row count (~1,701 rows).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Full 1099 report for a customer | `WHERE RealCID = {cid}` |
| All blocked customers in population | `WHERE BlockDate IS NOT NULL` |
| Customers with dividends | `WHERE Dividends_LongReal <> 0 OR Dividends_LongCFD <> 0` |
| Missing TIN values | `WHERE TIN_Value = 'Null' OR TIN_Value IS NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `RealCID = RealCID` | Full customer profile |
| BI_DB_dbo.BI_DB_Tax_1099_PartB (if exists) | `RealCID = RealCID` | Part B of the 1099 report |

### 3.4 Gotchas

- **Conditional execution**: The SP will silently skip if run outside its 3-day Fivetran sync window — check UpdateDate to verify freshness
- **TIN sensitivity**: TIN_Value contains US Social Security Numbers / ITINs — handle as PII
- **NULL financial columns**: Customers with no US positions or dividends will have NULL (not zero) in financial columns
- **BlockDate semantics**: PlayerStatusID IN (2,4,9) — this may include statuses beyond simple blocking; verify mapping
- **Column count**: DDL has 47 columns matching the SP's INSERT list exactly

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with origin tag) |
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | NO | Customer identifier, primary key equivalent. Sourced from Dim_Customer joined to the 1099 Fivetran population list. (Tier 2 — SP_1099_part_A) |
| 2 | GCID | int | NO | Global Customer ID from Dim_Customer. (Tier 2 — SP_1099_part_A) |
| 3 | PlayerStatus | varchar(100) | YES | Current player status name from Dim_PlayerStatus.Name. (Tier 2 — SP_1099_part_A) |
| 4 | Regulation | varchar(100) | YES | Current regulation name from Dim_Regulation.Name. (Tier 1 — Dictionary.Regulation) |
| 5 | FTD | date | YES | First deposit date, CAST from Dim_Customer.FirstDepositDate. (Tier 2 — SP_1099_part_A) |
| 6 | Regulation_EOY | varchar(50) | YES | End-of-year regulation name from Dim_Regulation.Name via Fact_SnapshotCustomer at @lastDayOfYearDateID. (Tier 2 — SP_1099_part_A) |
| 7 | BlockDate | date | YES | Earliest date the customer entered a blocked status (PlayerStatusID IN 2,4,9). NULL if never blocked. (Tier 2 — SP_1099_part_A) |
| 8 | TIN_Value | nvarchar(100) | YES | US Tax Identification Number (SSN/ITIN). Sourced from ExtendedUserField FieldId=6 for CountryID=219. 'Null' string if empty/short. (Tier 2 — SP_1099_part_A) |
| 9 | LastLogInCountry | varchar(100) | YES | Country name of last login by IP. For blocked customers, last login before block date; otherwise most recent. From Dim_Country.Name. (Tier 1 — Dictionary.Country) |
| 10 | LastLogDate | date | YES | Date of last login action (ActionTypeID=14). For blocked customers, last login before block date. (Tier 2 — SP_1099_part_A) |
| 11 | Gross_Proceeds_LongReal | money | YES | Total gross proceeds (Amount+NetProfit) for long real stock positions on US instruments closed during reporting year. (Tier 2 — SP_1099_part_A) |
| 12 | PositionCountLongReal | int | YES | Count of closed long real stock positions on US instruments during reporting year. (Tier 2 — SP_1099_part_A) |
| 13 | Gross_Proceeds_LongCFD | money | YES | Total gross proceeds (Amount+NetProfit) for long CFD positions on US instruments closed during reporting year. (Tier 2 — SP_1099_part_A) |
| 14 | PositionCountLongCFD | int | YES | Count of closed long CFD positions on US instruments during reporting year. (Tier 2 — SP_1099_part_A) |
| 15 | Gross_Proceeds_ShortCFD | money | YES | Total gross proceeds (Amount+NetProfit) for short CFD positions on US instruments closed during reporting year. (Tier 2 — SP_1099_part_A) |
| 16 | PositionCountShortCFD | int | YES | Count of closed short CFD positions on US instruments during reporting year. (Tier 2 — SP_1099_part_A) |
| 17 | Dividends_LongReal | money | YES | Total dividend amount for long real stock positions on US instruments during reporting year. (Tier 2 — SP_1099_part_A) |
| 18 | Dividends_LongCFD | money | YES | Total dividend amount for long CFD positions on US instruments during reporting year. (Tier 2 — SP_1099_part_A) |
| 19 | Dividends_LongReal_0 | money | YES | Dividend amount for long real stock positions with IRS TaxCode=0 (unclassified/exempt). (Tier 2 — SP_1099_part_A) |
| 20 | Dividends_LongCFD_0 | money | YES | Dividend amount for long CFD positions with IRS TaxCode=0. (Tier 2 — SP_1099_part_A) |
| 21 | Dividends_LongReal_1 | money | YES | Dividend amount for long real stock positions with IRS TaxCode=1 (ordinary dividends). (Tier 2 — SP_1099_part_A) |
| 22 | Dividends_LongCFD_1 | money | YES | Dividend amount for long CFD positions with IRS TaxCode=1. (Tier 2 — SP_1099_part_A) |
| 23 | Dividends_LongReal_6 | money | YES | Dividend amount for long real stock positions with IRS TaxCode=6 (qualified dividends). (Tier 2 — SP_1099_part_A) |
| 24 | Dividends_LongCFD_6 | money | YES | Dividend amount for long CFD positions with IRS TaxCode=6. (Tier 2 — SP_1099_part_A) |
| 25 | Dividends_LongReal_8 | money | YES | Dividend amount for long real stock positions with IRS TaxCode=8 (section 199A). (Tier 2 — SP_1099_part_A) |
| 26 | Dividends_LongCFD_8 | money | YES | Dividend amount for long CFD positions with IRS TaxCode=8. (Tier 2 — SP_1099_part_A) |
| 27 | Dividends_LongReal_9 | money | YES | Dividend amount for long real stock positions with IRS TaxCode=9. (Tier 2 — SP_1099_part_A) |
| 28 | Dividends_LongCFD_9 | money | YES | Dividend amount for long CFD positions with IRS TaxCode=9. (Tier 2 — SP_1099_part_A) |
| 29 | Dividends_LongReal_23 | money | YES | Dividend amount for long real stock positions with IRS TaxCode=23. (Tier 2 — SP_1099_part_A) |
| 30 | Dividends_LongCFD_23 | money | YES | Dividend amount for long CFD positions with IRS TaxCode=23. (Tier 2 — SP_1099_part_A) |
| 31 | Dividends_LongReal_27 | money | YES | Dividend amount for long real stock positions with IRS TaxCode=27. (Tier 2 — SP_1099_part_A) |
| 32 | Dividends_LongCFD_27 | money | YES | Dividend amount for long CFD positions with IRS TaxCode=27. (Tier 2 — SP_1099_part_A) |
| 33 | Dividends_LongReal_33 | money | YES | Dividend amount for long real stock positions with IRS TaxCode=33. (Tier 2 — SP_1099_part_A) |
| 34 | Dividends_LongCFD_33 | money | YES | Dividend amount for long CFD positions with IRS TaxCode=33. (Tier 2 — SP_1099_part_A) |
| 35 | Dividends_LongReal_35 | money | YES | Dividend amount for long real stock positions with IRS TaxCode=35. (Tier 2 — SP_1099_part_A) |
| 36 | Dividends_LongCFD_35 | money | YES | Dividend amount for long CFD positions with IRS TaxCode=35. (Tier 2 — SP_1099_part_A) |
| 37 | Dividends_LongReal_36 | money | YES | Dividend amount for long real stock positions with IRS TaxCode=36. (Tier 2 — SP_1099_part_A) |
| 38 | Dividends_LongCFD_36 | money | YES | Dividend amount for long CFD positions with IRS TaxCode=36. (Tier 2 — SP_1099_part_A) |
| 39 | Dividends_LongReal_37 | money | YES | Dividend amount for long real stock positions with IRS TaxCode=37. (Tier 2 — SP_1099_part_A) |
| 40 | Dividends_LongCFD_37 | money | YES | Dividend amount for long CFD positions with IRS TaxCode=37. (Tier 2 — SP_1099_part_A) |
| 41 | Dividends_LongReal_40 | money | YES | Dividend amount for long real stock positions with IRS TaxCode=40. (Tier 2 — SP_1099_part_A) |
| 42 | Dividends_LongCFD_40 | money | YES | Dividend amount for long CFD positions with IRS TaxCode=40. (Tier 2 — SP_1099_part_A) |
| 43 | Dividends_LongReal_78 | money | YES | Dividend amount for long real stock positions with IRS TaxCode=78. (Tier 2 — SP_1099_part_A) |
| 44 | Dividends_LongCFD_78 | money | YES | Dividend amount for long CFD positions with IRS TaxCode=78. (Tier 2 — SP_1099_part_A) |
| 45 | UpdateDate | date | YES | ETL execution timestamp, GETDATE() at SP run time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | passthrough via population join |
| GCID | DWH_dbo.Dim_Customer | GCID | passthrough |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | passthrough (current) |
| Regulation_EOY | DWH_dbo.Dim_Regulation | Name | EOY snapshot via Fact_SnapshotCustomer |
| LastLogInCountry | DWH_dbo.Dim_Country | Name | last login country by IP |
| TIN_Value | BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField | Value | FieldId=6, CountryID=219 |

### 5.2 ETL Pipeline

```
External_Fivetran_google_sheets_population_1_1099 (CID list + report_year)
  + DWH_dbo.Dim_Date (year boundaries)
  |
  |-- SP_1099_part_A @Date (conditional TRUNCATE+INSERT)
  |   Guard: @Date > lastDayOfYear AND within 3 days of Fivetran sync
  |   Step 1: Build #Users1099 population (Dim_Customer + Dim_PlayerStatus + Dim_Regulation)
  |           + #regulation_31_12_23 (EOY regulation via Fact_SnapshotCustomer)
  |   Step 2: #blockdate (MIN FromDateID where PlayerStatusID IN 2,4,9)
  |   Step 3: #taxdata (TIN from ExtendedUserField, FieldId=6, US only)
  |   Step 4: #positions (gross proceeds + counts from Dim_Position, US instruments)
  |   Step 5: #dividends (dividend sums by tax code from BI_DB_DailyDividendsByPosition)
  |   Step 6: #lastloginBLOCKED + #lastloginALL (Fact_CustomerAction ActionTypeID=14)
  |   Final:  LEFT JOIN all temp tables -> TRUNCATE + INSERT
  v
BI_DB_dbo.BI_DB_Tax_1099_PartA (1,701 rows, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID, GCID | DWH_dbo.Dim_Customer | Customer profile |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Status name lookup |
| Regulation, Regulation_EOY | DWH_dbo.Dim_Regulation | Regulation name lookup |
| BlockDate | DWH_dbo.Fact_SnapshotCustomer | Snapshot for blocked status detection |
| TIN_Value | BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField | US TIN values |
| Gross_Proceeds_* | DWH_dbo.Dim_Position + DWH_dbo.Dim_Instrument | Closed US positions |
| Dividends_* | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Position-level dividends |
| LastLogInCountry | DWH_dbo.Dim_Country + DWH_dbo.Fact_CustomerAction | Login country by IP |
| Population | BI_DB_dbo.External_Fivetran_google_sheets_population_1_1099 | 1099 population list |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory. Likely consumed by downstream 1099 filing/reporting processes.

---

## 7. Sample Queries

### 7.1 Customers with Highest Gross Proceeds

```sql
SELECT RealCID, GCID, PlayerStatus, Regulation,
       Gross_Proceeds_LongReal, Gross_Proceeds_LongCFD, Gross_Proceeds_ShortCFD
FROM BI_DB_dbo.BI_DB_Tax_1099_PartA
WHERE Gross_Proceeds_LongReal IS NOT NULL
ORDER BY Gross_Proceeds_LongReal DESC
```

### 7.2 Blocked Customers with US Last Login

```sql
SELECT RealCID, BlockDate, LastLogInCountry, LastLogDate, TIN_Value
FROM BI_DB_dbo.BI_DB_Tax_1099_PartA
WHERE BlockDate IS NOT NULL AND LastLogInCountry = 'United States'
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 2 T1, 42 T2, 0 T3, 0 T4, 1 T5 | Elements: 45/45, Logic: 9/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Tax_1099_PartA | Type: Table | Production Source: External_Fivetran population + Dim_Customer + Dim_Position + BI_DB_DailyDividendsByPosition via SP_1099_part_A*
