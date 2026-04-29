# BI_DB_dbo.BI_DB_W_AML_PEP_Customers_Trun

> 6,772-row current-week-only AML/Compliance PEP (Politically Exposed Person) customer snapshot as of 2026-04-18. TRUNCATE+INSERT sibling of BI_DB_W_AML_PEP_Customers — contains only the latest week's data (no historical accumulation). Tracks verified depositors flagged as PEP (ScreeningStatusID=3) with selfie/SOF document freshness, eMoney account status, and country-level AML risk ranking. Refreshed weekly by SP_W_AML_PEP_Customers via SB_Daily.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: DWH_dbo.Dim_Customer (primary) + 5 dim lookups + BI_DB_AML_Documents_Request + External_RiskClassification + eMoney_Dim_Account via SP_W_AML_PEP_Customers |
| **Refresh** | Weekly (TRUNCATE + INSERT), runs daily via SB_Daily — always contains only the current week's snapshot |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is the current-week-only companion to BI_DB_W_AML_PEP_Customers. Each row represents one PEP customer for the most recent reporting week. The table is TRUNCATED and reloaded on every SP execution, so it always contains exactly one week's worth of data.

The population, sources, and column logic are identical to BI_DB_W_AML_PEP_Customers — see that table for full details. The only difference is the load pattern:
- **BI_DB_W_AML_PEP_Customers**: DELETE+INSERT by ReportDate → accumulates 51+ weeks of history
- **BI_DB_W_AML_PEP_Customers_Trun**: TRUNCATE+INSERT → only the latest week (~6,772 rows)

This TRUNCATE variant is useful for dashboards and reports that only need the current PEP snapshot without scanning the full historical table.

SP_W_AML_PEP_Customers writes to BOTH tables in a single execution: first the accumulating table (DELETE+INSERT), then this TRUNCATE table.

---

## 2. Business Logic

### 2.1 PEP Population Filter

**What**: Restricts to verified depositors flagged as Politically Exposed Persons.
**Columns Involved**: CID, ScreeningStatus
**Rules**:
- Dim_Customer.IsValidCustomer = 1
- Dim_Customer.IsDepositor = 1
- Dim_Customer.VerificationLevelID = 3 (fully verified)
- Dim_ScreeningStatus.ScreeningStatusID = 3 (PEP)

### 2.2 Document Freshness Check

**What**: Determines whether selfie and SOF documents are current (within 12 months).
**Columns Involved**: Has_Selfie, Selfie_Date, Has_SOF, SOF_Date, Selfie_and_SOF_Valid
**Rules**:
- Has_Selfie = 1 if DocumentDateAdded_Selfie IS NOT NULL in BI_DB_AML_Documents_Request
- Has_SOF = 1 if DocumentDateAdded_POIncome IS NOT NULL in BI_DB_AML_Documents_Request
- Selfie_and_SOF_Valid = 'Yes' only if BOTH Selfie_Date AND SOF_Date >= DATEADD(MONTH, -12, GETDATE()), else 'No'

### 2.3 eMoney Account Detection

**What**: Checks if the PEP customer has an active eToro Money account.
**Columns Involved**: Has_eMoney_Account, eMoney_BalanceStatus
**Rules**:
- LEFT JOIN to eMoney_dbo.eMoney_Dim_Account where IsValidETM=1, IsTestAccount=0, CurrencyBalanceStatusID<>4 (not Blocked)
- Has_eMoney_Account = 1 if a matching eMoney account exists

### 2.4 Current-Week Snapshot (TRUNCATE Pattern)

**What**: Always contains only the latest week's data.
**Columns Involved**: ReportDate, UpdateDate
**Rules**:
- TRUNCATE TABLE before INSERT — no historical accumulation
- ReportDate = week end date (Sunday) computed from @Date parameter
- Only one distinct ReportDate exists at any time

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP — small table (~6.7K rows), no performance concerns. No ReportDate filter needed (only one week present).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current PEP count by regulation | `SELECT Regualtion, COUNT(*) FROM ... GROUP BY Regualtion` (no date filter needed) |
| PEP customers with expired documents | `WHERE Selfie_and_SOF_Valid = 'No'` |
| PEP customers with eMoney accounts | `WHERE Has_eMoney_Account = 1` |
| Compare with historical | JOIN to BI_DB_W_AML_PEP_Customers on CID for trend analysis |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer profile |
| BI_DB_dbo.BI_DB_W_AML_PEP_Customers | CID = CID AND ReportDate = ReportDate | Historical comparison |
| BI_DB_dbo.BI_DB_AML_Documents_Request | CID = CID | Detailed document breakdown |

### 3.4 Gotchas

- **Column name typo**: `Regualtion` is misspelled (should be "Regulation") — preserved from DDL, use as-is
- **PlayerStatus trailing spaces**: Apply RTRIM() for string comparisons
- **ScreeningStatus is always 'PEP'**: Constant column due to filter
- **UpdateDate is nullable**: Unlike the accumulating parent table where UpdateDate is NOT NULL
- **Single ReportDate**: No need for date filters — table always contains exactly one week

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data sampling |
| Tier 4 | Best available — limited confidence |
| Tier 5 | Standard ETL metadata or infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | ScreeningStatus | nvarchar(500) | YES | Internal code name for the screening outcome. Passthrough from ScreeningService.Dictionary.ScreeningStatus. Used in compliance reporting and case management. Always 'PEP' in this table due to ScreeningStatusID=3 filter. (Tier 3 — live data, via Dim_ScreeningStatus) |
| 3 | PlayerStatus | nvarchar(500) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for string comparisons. Values: Normal, Blocked, Block Deposit & Trading, Blocked Upon Request, Trade & MIMO Blocked, Deposit Blocked, Warning. (Tier 1 — Dictionary.PlayerStatus) |
| 4 | Regualtion | nvarchar(500) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Column name has typo (should be "Regulation"). Values: CySEC, FSA Seychelles, FCA, FSRA, ASIC & GAML, ASIC, FinCEN+FINRA, FinCEN. (Tier 1 — Dictionary.Regulation) |
| 5 | RegisteredReal | datetime | YES | Account registration date (renamed from Registered). Default=getdate(). (Tier 1 — Customer.CustomerStatic) |
| 6 | FirstDepositDate | datetime | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. (Tier 2 — SP_Dim_Customer) |
| 7 | FirstDepositAmount | money | YES | Amount of first deposit (in USD). Updated from FTDAmountInUsd. (Tier 2 — SP_Dim_Customer) |
| 8 | Country | nvarchar(500) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 9 | AML_Rank | int | YES | Granular country risk classification. 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. More nuanced than binary IsHighRiskCountry. IsHighRiskCountry is derived from this column. Renamed from RiskGroupID. (Tier 1 — Dictionary.Country) |
| 10 | Has_Selfie | int | YES | 1 if the customer has uploaded an accepted selfie document (Selfie, SelfieLiveliness, or Selfie Motion), 0 otherwise. Derived from BI_DB_AML_Documents_Request.DocumentDateAdded_Selfie IS NOT NULL. (Tier 2 — SP_W_AML_PEP_Customers) |
| 11 | Selfie_Date | date | YES | Upload date of the most recent accepted Selfie document. NULL if no selfie uploaded. CAST from DocumentDateAdded_Selfie. (Tier 2 — SP_W_AML_PEP_Customers via BI_DB_AML_Documents_Request) |
| 12 | Has_SOF | int | YES | 1 if the customer has uploaded an accepted Source of Funds (Proof of Income) document, 0 otherwise. Derived from BI_DB_AML_Documents_Request.DocumentDateAdded_POIncome IS NOT NULL. (Tier 2 — SP_W_AML_PEP_Customers) |
| 13 | SOF_Date | date | YES | Upload date of the most recent accepted Proof of Income document. NULL if no SOF document uploaded. CAST from DocumentDateAdded_POIncome. (Tier 2 — SP_W_AML_PEP_Customers via BI_DB_AML_Documents_Request) |
| 14 | Selfie_and_SOF_Valid | nvarchar(500) | YES | 'Yes' if both Selfie_Date and SOF_Date are within the last 12 months (>= DATEADD(MONTH,-12,GETDATE())), 'No' otherwise. Compliance freshness indicator for PEP document renewal tracking. (Tier 2 — SP_W_AML_PEP_Customers) |
| 15 | HasWallet | int | YES | 1 if the customer has an active eToro Money wallet linked to their trading account. Default=0. (Tier 1 — BackOffice.Customer) |
| 16 | ReportDate | date | YES | Week-end date (Sunday) for this snapshot. Computed from @Date parameter as the last day of the Monday–Sunday week. Only one value present (TRUNCATE pattern). (Tier 2 — SP_W_AML_PEP_Customers) |
| 17 | Has_eMoney_Account | int | YES | 1 if the customer has an active eToro Money account (IsValidETM=1, IsTestAccount=0, CurrencyBalanceStatusID<>4). 0 otherwise. (Tier 2 — SP_W_AML_PEP_Customers) |
| 18 | eMoney_BalanceStatus | nvarchar(500) | YES | Currency balance status display name for the eMoney account, resolved from eMoney_Dictionary_CurrencyBalanceStatus. NULL if no eMoney account. Values: Active, ReceiveOnly, SpendOnly, Suspended. (Tier 2 — SP_W_AML_PEP_Customers via eMoney_Dim_Account) |
| 19 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — ETL metadata) |
| 20 | RiskScoreName | nvarchar(250) | YES | Named risk level from RiskClassification database (Dictionary.RiskClassificationRegulation). Values in PEP population: High, Medium. NULL if customer not yet scored. Passthrough from V_RiskClassificationDataLake. (Tier 1 — RiskClassification.dbo.V_RiskClassificationDataLake) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | Rename: RealCID → CID via Dim_Customer |
| ScreeningStatus | ScreeningService.Dictionary.ScreeningStatus | Name | Dim lookup (always PEP) |
| PlayerStatus | Dictionary.PlayerStatus | Name | Dim lookup via Dim_PlayerStatus |
| Regualtion | Dictionary.Regulation | Name | Dim lookup via Dim_Regulation |
| RegisteredReal | Customer.CustomerStatic | Registered | Rename via Dim_Customer |
| FirstDepositDate | CustomerFinanceDB FTD data | FTDRecoveryDate | ETL-computed via SP_Dim_Customer |
| FirstDepositAmount | CustomerFinanceDB FTD data | FTDAmountInUsd | ETL-computed via SP_Dim_Customer |
| Country | Dictionary.Country | Name | Dim lookup via Dim_Country |
| AML_Rank | Dictionary.Country | RiskGroupID | Rename via Dim_Country |
| Has_Selfie | BackOffice.CustomerDocument | DocumentDateAdded | CASE IS NOT NULL via BI_DB_AML_Documents_Request |
| Selfie_Date | BackOffice.CustomerDocument | DocumentDateAdded | CAST DATE via BI_DB_AML_Documents_Request |
| Has_SOF | BackOffice.CustomerDocument | DocumentDateAdded | CASE IS NOT NULL via BI_DB_AML_Documents_Request |
| SOF_Date | BackOffice.CustomerDocument | DocumentDateAdded | CAST DATE via BI_DB_AML_Documents_Request |
| Selfie_and_SOF_Valid | SP computation | Selfie_Date, SOF_Date | CASE: both >= 12 months ago |
| HasWallet | BackOffice.Customer | HasWallet | Passthrough via Dim_Customer |
| ReportDate | SP parameter | @WeekEndDate | Computed week-end Sunday |
| Has_eMoney_Account | eMoney_dbo.eMoney_Dim_Account | CID | CASE IS NOT NULL |
| eMoney_BalanceStatus | eMoney_dbo.eMoney_Dim_Account | CurrencyBalanceStatus | Passthrough |
| UpdateDate | ETL | GETDATE() | Insert timestamp |
| RiskScoreName | RiskClassification.dbo.V_RiskClassificationDataLake | RiskScoreName | Passthrough |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (primary: PEP depositors, VerificationLevelID=3, ScreeningStatusID=3)
  + DWH_dbo.Dim_ScreeningStatus (JOIN ScreeningStatusID=3)
  + DWH_dbo.Dim_Regulation (JOIN DWHRegulationID)
  + DWH_dbo.Dim_PlayerStatus (JOIN PlayerStatusID)
  + DWH_dbo.Dim_Country (JOIN DWHCountryID → Name, RiskGroupID)
  + BI_DB_dbo.BI_DB_AML_Documents_Request (LEFT JOIN CID → selfie/SOF dates)
  + External_RiskClassification_dbo_V_RiskClassificationDataLake (LEFT JOIN CID → RiskScoreName)
    |-- #pop (temp table, HASH(CID)) ---|
    |
  + eMoney_dbo.eMoney_Dim_Account (LEFT JOIN CID → eMoney status)
    |-- #eMoney (temp table, HASH(CID)) ---|
    |
    |-- #final (JOIN #pop + #eMoney, add Selfie_and_SOF_Valid, Has_eMoney_Account) ---|
    v
  [First writes to BI_DB_W_AML_PEP_Customers (DELETE+INSERT)]
    v
  TRUNCATE TABLE BI_DB_dbo.BI_DB_W_AML_PEP_Customers_Trun
  INSERT INTO BI_DB_dbo.BI_DB_W_AML_PEP_Customers_Trun (current-week-only snapshot)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Primary customer dimension |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus.Name | Account restriction state |
| Regualtion | DWH_dbo.Dim_Regulation.Name | Regulatory entity name |
| Country | DWH_dbo.Dim_Country.Name | Country of residence |
| AML_Rank | DWH_dbo.Dim_Country.RiskGroupID | Country AML risk tier |
| Has_Selfie, Selfie_Date | BI_DB_dbo.BI_DB_AML_Documents_Request | Document upload tracking |
| Has_SOF, SOF_Date | BI_DB_dbo.BI_DB_AML_Documents_Request | SOF document tracking |
| RiskScoreName | External_RiskClassification_dbo_V_RiskClassificationDataLake | Risk classification score |
| Has_eMoney_Account, eMoney_BalanceStatus | eMoney_dbo.eMoney_Dim_Account | eToro Money account status |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| BI_DB_dbo.BI_DB_W_AML_PEP_Customers | Sibling — same SP | Accumulating historical version of this table |

---

## 7. Sample Queries

### 7.1 Current PEP Snapshot by Regulation and Document Status

```sql
SELECT Regualtion,
       COUNT(*) AS Total_PEP,
       SUM(CASE WHEN Selfie_and_SOF_Valid = 'Yes' THEN 1 ELSE 0 END) AS Valid_Docs,
       SUM(Has_eMoney_Account) AS With_eMoney
FROM BI_DB_dbo.BI_DB_W_AML_PEP_Customers_Trun
GROUP BY Regualtion
ORDER BY Total_PEP DESC
```

### 7.2 High-Risk PEP Customers Needing Document Renewal

```sql
SELECT CID, Country, AML_Rank, RiskScoreName,
       RTRIM(PlayerStatus) AS PlayerStatus,
       Selfie_Date, SOF_Date
FROM BI_DB_dbo.BI_DB_W_AML_PEP_Customers_Trun
WHERE AML_Rank > 0
  AND Selfie_and_SOF_Valid = 'No'
ORDER BY AML_Rank DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found specific to this table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 7 T1, 10 T2, 1 T3, 0 T4, 1 T5 | Elements: 20/20, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_W_AML_PEP_Customers_Trun | Type: Table | Production Source: Multi-source via SP_W_AML_PEP_Customers*
