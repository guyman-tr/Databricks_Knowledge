# BI_DB_dbo.BI_DB_TIN_Gap_Temp_pop

> 5.6K-row temporary population variant of BI_DB_TIN_Gap. Base population sourced from a Google Sheet (via Fivetran) rather than Freeze6, with relaxed eligibility filters and simplified A/B/C group classification (no B1/B2/B3 split). Tracks TIN gap remediation status across three tax countries for a manually curated CID list. TRUNCATE+INSERT via SP_TIN_Gap_Temp_pop.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | External_Fivetran_gsheets_tin_gep_temp_pop + Dim_Customer + Dim_Country + V_Liabilities + BI_DB_PositionPnL + BI_DB_CIDFirstDates via `SP_TIN_Gap_Temp_pop` |
| **Refresh** | Daily (TRUNCATE+INSERT, no date parameter) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Adi Meidan (TIN Gap Remediation) |
| **Row Count** | ~5,584 (as of 2026-04-26) |

---

## 1. Business Meaning

`BI_DB_TIN_Gap_Temp_pop` is a temporary population variant of the main `BI_DB_TIN_Gap` table. While the main TIN_Gap table draws its population from Freeze6 with extensive customer-level eligibility filters (FTD check, PlayerStatus, AccountStatus, VerificationLevel, Regulation, AccountType, CountryID, PlayerLevel), this variant uses a manually curated Google Sheet (`External_Fivetran_gsheets_tin_gep_temp_pop`) ingested via Fivetran as its base population, with all customer-level filters commented out.

The table identifies customers with TIN (Tax Identification Number) gaps across three categories:
1. **No TIN**: Customer has no TaxCode on file
2. **TIN Not Valid**: TaxCodeStatusID indicates the TIN is not validated
3. **TIN_Null_With_Reason**: TIN is NULL but a TaxReasonID is provided

For each CID, up to three tax countries are evaluated (TaxCountry1/2/3 from Dim_Country), and each is marked as Done or Not Done. The table includes customer enrichment (name, email, regulation, account type), financial context (equity, deposits, open positions), and a simplified Group classification (A/B/C) for prioritization.

The extra `Insert_date` column (not present in BI_DB_TIN_Gap) tracks when each CID was added to the Google Sheet, providing audit visibility into the source population timeline.

As of 2026-04-26: 5,584 rows — much smaller than BI_DB_TIN_Gap's ~335K rows, reflecting the targeted nature of this temporary population.

---

## 2. Business Logic

### 2.1 TIN Gap Type Classification

**What**: Each customer is classified into one of three TIN gap types.
**Columns Involved**: `TIN_Gap_Type`, `TaxCode`, `TaxCodeStatusID`, `TaxReasonID`
**Rules**:
- 'No TIN': No TaxCode on file for the relevant tax country
- 'TIN Not Valid': TaxCode exists but TaxCodeStatusID indicates it failed validation
- 'TIN_Null_With_Reason': TaxCode is NULL but a TaxReasonID is provided (customer gave a reason for not having a TIN)

### 2.2 Tax Country Pivot

**What**: Each CID is evaluated against up to three tax countries derived from the customer's country.
**Columns Involved**: `TIN_Country1`, `TIN_Country2`, `TIN_Country3`
**Rules**:
- Tax countries are sourced from Dim_Country (TaxCountry1, TaxCountry2, TaxCountry3)
- For each tax country, the gap is either 'Done' (resolved) or 'Not Done' (still outstanding)
- The Done/Not-Done union pattern: Done CIDs and Not-Done CIDs are unioned into the final result

### 2.3 Group Classification (Simplified)

**What**: Customers are grouped into priority tiers for remediation. Unlike BI_DB_TIN_Gap which uses A/B1/B2/B3/C (char(2)), this table uses A/B/C (char(1)).
**Columns Involved**: `[Group]`
**Rules**:
- **A**: PlayerLevelID in (1,3,5) AND no open positions AND equity < 10 — low-value, low-risk
- **B**: PlayerLevelID in (1,3,5) AND (equity >= 10 OR has open positions) — has financial activity, single group (no B1/B2/B3 subdivision)
- **C**: PlayerLevelID in (2,6,7) — higher-tier customers

### 2.4 Population Source Differences from BI_DB_TIN_Gap

**What**: The base population is fundamentally different from the main TIN_Gap table.
**Rules**:
- Population comes from `External_Fivetran_gsheets_tin_gep_temp_pop` (Google Sheets via Fivetran) instead of Freeze6
- No CID exclusion list filtering
- All customer-level filters are commented out in #data_CID: no FTD check, no PlayerStatus filter, no AccountStatus filter, no VerificationLevel, no Regulation, no AccountType, no CountryID, no PlayerLevel
- LastLoggedIn sourced from BI_DB_CIDFirstDates instead of Fact_CustomerAction
- No #trading_activity temp table (no Active_Ind check for Group)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — small table (~5.6K rows). Full scans are fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Unresolved TIN gaps | `WHERE Done_Not_Done = 'Not Done'` |
| Gap breakdown by type | `GROUP BY TIN_Gap_Type` |
| High-priority customers | `WHERE [Group] = 'C'` (highest PlayerLevel tier) |
| Recently added to Google Sheet | `ORDER BY Insert_date DESC` |
| Customers with equity at risk | `WHERE Equity > 0 AND Done_Not_Done = 'Not Done'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `CID = RealCID` | Full customer profile |
| BI_DB_dbo.BI_DB_TIN_Gap | `CID = CID` | Compare temp pop status vs. main TIN Gap |

### 3.4 Gotchas

- **[Group] is char(1)**: Unlike BI_DB_TIN_Gap where Group is char(2) with values A/B1/B2/B3/C, this table uses char(1) with values A/B/C only. Use square brackets: `[Group]`
- **Google Sheets dependency**: Base population depends on an external Google Sheet ingested via Fivetran — data freshness depends on Fivetran sync schedule
- **All customer filters commented out**: The SP has Freeze6-style filters in comments but none are active — the population is entirely determined by the Google Sheet
- **Insert_date is from the Google Sheet**: Not the ETL insert date — it reflects when the CID was added to the source sheet (base_pop.update_date)
- **PII columns**: Email, TaxCode, TaxCode2, TaxCode3 contain personally identifiable information

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 5 | External/non-DWH source (Google Sheets) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Base population from Google Sheet. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | bigint | YES | Group Customer ID — cross-product identity key. From Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 3 | FirstName | nvarchar(100) | YES | Customer first name. From Dim_Customer. PII. (Tier 1 — Customer.CustomerStatic) |
| 4 | LastName | nvarchar(100) | YES | Customer last name. From Dim_Customer. PII. (Tier 1 — Customer.CustomerStatic) |
| 5 | Email | nvarchar(200) | YES | Customer email address. From Dim_Customer. PII. (Tier 1 — Customer.CustomerStatic) |
| 6 | Country | nvarchar(100) | YES | Country name. From Dim_Country via Dim_Customer.CountryID. (Tier 1 — Dictionary.Country) |
| 7 | Regulation | nvarchar(100) | YES | Regulatory entity name. From Dim_Regulation via Dim_Customer.RegulationID. (Tier 1 — Dictionary.Regulation) |
| 8 | AccountType | nvarchar(100) | YES | Account type name. From Dim_AccountType via Dim_Customer.AccountTypeID. (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 9 | PlayerLevel | nvarchar(100) | YES | Player level name (e.g., Silver, Gold). From Dim_PlayerLevel via Dim_Customer.PlayerLevelID. (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 10 | PlayerStatus | nvarchar(100) | YES | Player status name (e.g., Active, Blocked). From Dim_PlayerStatus via Dim_Customer.PlayerStatusID. (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 11 | TIN_Gap_Type | varchar(50) | YES | TIN gap classification: 'No TIN', 'TIN Not Valid', or 'TIN_Null_With_Reason'. Derived from TaxCode/TaxCodeStatusID logic. (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 12 | TIN_Country1 | nvarchar(100) | YES | TIN gap status for tax country 1. Values: country name (Done) or country name (Not Done). From Dim_Country.TaxCountry1. (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 13 | TIN_Country2 | nvarchar(100) | YES | TIN gap status for tax country 2. Values: country name (Done) or country name (Not Done). From Dim_Country.TaxCountry2. NULL if country has no second tax jurisdiction. (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 14 | TIN_Country3 | nvarchar(100) | YES | TIN gap status for tax country 3. Values: country name (Done) or country name (Not Done). From Dim_Country.TaxCountry3. NULL if country has no third tax jurisdiction. (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 15 | TaxCode | nvarchar(100) | YES | Tax identification number for tax country 1. PII — contains the actual TIN value. (Tier 1 — Customer.CustomerStatic) |
| 16 | TaxCode2 | nvarchar(100) | YES | Tax identification number for tax country 2. PII. (Tier 1 — Customer.CustomerStatic) |
| 17 | TaxCode3 | nvarchar(100) | YES | Tax identification number for tax country 3. PII. (Tier 1 — Customer.CustomerStatic) |
| 18 | TaxCodeStatusID | int | YES | Validation status of TaxCode (tax country 1). Drives TIN_Gap_Type classification. (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 19 | TaxCodeStatusID2 | int | YES | Validation status of TaxCode2 (tax country 2). (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 20 | TaxCodeStatusID3 | int | YES | Validation status of TaxCode3 (tax country 3). (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 21 | TaxReasonID | int | YES | Reason code for missing TIN (tax country 1). Populated when TIN_Gap_Type = 'TIN_Null_With_Reason'. (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 22 | TaxReasonID2 | int | YES | Reason code for missing TIN (tax country 2). (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 23 | TaxReasonID3 | int | YES | Reason code for missing TIN (tax country 3). (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 24 | Equity | money | YES | Current customer equity balance. From V_Liabilities. Used in Group classification (A requires equity < 10). (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 25 | TotalDeposit | money | YES | Lifetime total deposits. From V_Liabilities. (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 26 | [Group] | char(1) | YES | Priority group for remediation: A (low-value, no positions, equity<10), B (has value or positions), C (high PlayerLevel). Simplified from BI_DB_TIN_Gap's char(2) A/B1/B2/B3/C. (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 27 | OpenPositions | int | YES | Count of open positions for the CID. From BI_DB_PositionPnL. Used in Group classification. (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 28 | LastLoggedIn | date | YES | Last login date. From BI_DB_CIDFirstDates (differs from BI_DB_TIN_Gap which uses Fact_CustomerAction). (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 29 | Done_Not_Done | varchar(20) | YES | Resolution status: 'Done' (TIN gap resolved) or 'Not Done' (still outstanding). (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 30 | updateDate | datetime | YES | ETL execution timestamp. GETDATE() at SP execution time. (Tier 2 — SP_TIN_Gap_Temp_pop) |
| 31 | Insert_date | date | YES | Date the CID was added to the Google Sheet source. Mapped from base_pop.update_date (External_Fivetran_gsheets_tin_gep_temp_pop). Not present in BI_DB_TIN_Gap. (Tier 5 — Google Sheets via Fivetran) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | passthrough via Google Sheet base population |
| GCID | Customer.CustomerStatic | GCID | passthrough via Dim_Customer |
| Country | Dictionary.Country | Name | dim-lookup via CountryID |
| Regulation | Dictionary.Regulation | Name | dim-lookup via RegulationID |
| Insert_date | External (Google Sheets) | update_date | passthrough from Fivetran-synced sheet |

### 5.2 ETL Pipeline

```
External_Fivetran_gsheets_tin_gep_temp_pop (Google Sheet — CID list + update_date)
  + DWH_dbo.Dim_Customer (customer attributes, TaxCode*, PlayerLevelID)
  + DWH_dbo.Dim_Country (country name, TaxCountry1/2/3)
  + DWH_dbo.Dim_Regulation (regulation name)
  + DWH_dbo.V_Liabilities (equity, total deposit)
  + BI_DB_dbo.BI_DB_PositionPnL (open position count)
  + BI_DB_dbo.BI_DB_CIDFirstDates (LastLoggedIn)
  |
  |-- SP_TIN_Gap_Temp_pop (TRUNCATE+INSERT, no @Date)
  |   Step 1: Load base population from Google Sheet (no customer filters)
  |   Step 2: Classify TIN gap types (No TIN / Not Valid / Null With Reason)
  |   Step 3: Pivot across 3 tax countries (Done / Not Done)
  |   Step 4: Enrich with customer, country, financial data
  |   Step 5: Assign Group (A/B/C — simplified, no B1/B2/B3)
  |   Step 6: UNION Done + Not Done populations
  v
BI_DB_dbo.BI_DB_TIN_Gap_Temp_pop (5.6K rows, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer dimension |
| Country | DWH_dbo.Dim_Country | Country name lookup |
| Regulation | DWH_dbo.Dim_Regulation | Regulation name lookup |
| Equity, TotalDeposit | DWH_dbo.V_Liabilities | Financial balances |
| OpenPositions | BI_DB_dbo.BI_DB_PositionPnL | Position count |
| LastLoggedIn | BI_DB_dbo.BI_DB_CIDFirstDates | Login activity |
| Insert_date | External_Fivetran_gsheets_tin_gep_temp_pop | Google Sheet source |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 Unresolved TIN Gaps by Group

```sql
SELECT [Group], TIN_Gap_Type, COUNT(*) AS GapCount
FROM BI_DB_dbo.BI_DB_TIN_Gap_Temp_pop
WHERE Done_Not_Done = 'Not Done'
GROUP BY [Group], TIN_Gap_Type
ORDER BY [Group], GapCount DESC
```

### 7.2 Recently Added CIDs with Outstanding Gaps

```sql
SELECT CID, GCID, Country, Regulation, TIN_Gap_Type,
       Equity, [Group], Insert_date
FROM BI_DB_dbo.BI_DB_TIN_Gap_Temp_pop
WHERE Done_Not_Done = 'Not Done'
  AND Insert_date >= DATEADD(DAY, -30, GETDATE())
ORDER BY Insert_date DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-26 | Quality: 7.5/10 | Phases: 14/14*
*Tiers: 10 T1, 20 T2, 0 T3, 0 T4, 1 T5 | Elements: 31/31*
*Object: BI_DB_dbo.BI_DB_TIN_Gap_Temp_pop | Type: Table | Production Source: Google Sheets (Fivetran) + Dim_Customer + Dim_Country + V_Liabilities via SP_TIN_Gap_Temp_pop*
