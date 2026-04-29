# BI_DB_dbo.BI_DB_W_AML_PEP_Customers

> 92,313-row weekly AML/Compliance PEP (Politically Exposed Person) customer snapshot covering 51 weeks from May 2025 to April 2026. Tracks verified depositors flagged as PEP (ScreeningStatusID=3) with selfie/SOF document freshness, eMoney account status, and country-level AML risk ranking. Refreshed weekly by SP_W_AML_PEP_Customers via SB_Daily (DELETE+INSERT by ReportDate).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: DWH_dbo.Dim_Customer (primary) + 5 dim lookups + BI_DB_AML_Documents_Request + External_RiskClassification + eMoney_Dim_Account via SP_W_AML_PEP_Customers |
| **Refresh** | Weekly (DELETE by ReportDate + INSERT), runs daily via SB_Daily but accumulates weekly snapshots (Monday–Sunday) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is a weekly compliance snapshot of all PEP-flagged customers across eToro's regulated entities. Each row represents one PEP customer for one reporting week, identified by CID + ReportDate.

The population is restricted to valid, depositing, fully-verified customers (IsValidCustomer=1, IsDepositor=1, VerificationLevelID=3) who have ScreeningStatusID=3 (PEP) in DWH_dbo.Dim_ScreeningStatus. As of the latest week (2026-04-18), there are ~6,772 PEP customers per snapshot.

SP_W_AML_PEP_Customers runs daily via the SB_Daily Service Broker process. It computes the Monday–Sunday week window from @Date, deletes any existing data for that week's end date, and inserts the current snapshot. This creates a rolling weekly history — 51 weeks currently stored.

The table enriches each PEP customer with:
- **Document freshness**: Whether selfie and Source of Funds (SOF/POIncome) documents exist and whether both are valid (uploaded within the last 12 months)
- **eMoney cross-check**: Whether the PEP customer has an active eToro Money account (non-blocked)
- **Country risk**: AML_Rank from Dim_Country.RiskGroupID (0=None through 4=Verified before deposit)
- **Risk classification**: RiskScoreName from the RiskClassification database (predominantly "High")

The same SP also writes a TRUNCATE+INSERT copy to BI_DB_W_AML_PEP_Customers_Trun (current-week-only snapshot).

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
- Most PEP customers lack both documents: ~49% have neither selfie nor SOF

### 2.3 eMoney Account Detection

**What**: Checks if the PEP customer has an active eToro Money account.
**Columns Involved**: Has_eMoney_Account, eMoney_BalanceStatus
**Rules**:
- LEFT JOIN to eMoney_dbo.eMoney_Dim_Account where IsValidETM=1, IsTestAccount=0, CurrencyBalanceStatusID<>4 (not Blocked)
- Has_eMoney_Account = 1 if a matching eMoney account exists
- eMoney_BalanceStatus shows the balance status name (NULL if no eMoney account)

### 2.4 Weekly Snapshot Accumulation

**What**: Maintains rolling weekly history using DELETE+INSERT by ReportDate.
**Columns Involved**: ReportDate, UpdateDate
**Rules**:
- ReportDate = week end date (Sunday) computed from @Date parameter
- DELETE existing rows for the same ReportDate before INSERT (idempotent re-runs within the same week)
- UpdateDate = GETDATE() at insert time

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP — no distribution key optimization. For weekly snapshot analysis, always filter by ReportDate to avoid scanning all 51 weeks.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current PEP customer count by regulation | `WHERE ReportDate = (SELECT MAX(ReportDate) FROM ...) GROUP BY Regualtion` |
| Document freshness trends over time | `GROUP BY ReportDate, Selfie_and_SOF_Valid` — tracks improvement |
| PEP customers with eMoney accounts | `WHERE Has_eMoney_Account = 1 AND ReportDate = MAX(ReportDate)` |
| High-risk PEP customers | `WHERE AML_Rank > 0 AND ReportDate = MAX(ReportDate)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer profile |
| BI_DB_dbo.BI_DB_W_AML_PEP_Customers_Trun | CID = CID | Compare historical vs current snapshot |
| BI_DB_dbo.BI_DB_AML_Documents_Request | CID = CID | Detailed document request breakdown |

### 3.4 Gotchas

- **Column name typo**: `Regualtion` is misspelled (should be "Regulation") — preserved from DDL, use as-is in queries
- **PlayerStatus trailing spaces**: Some values from Dim_PlayerStatus have trailing whitespace (e.g., 'Blocked' with spaces) — use RTRIM() for string comparisons
- **ScreeningStatus is always 'PEP'**: The filter ensures ScreeningStatusID=3, so this column is constant — useful only for documentation/joins
- **eMoney_BalanceStatus NULL**: NULL means no eMoney account (not a missing value)
- **RiskScoreName NULL**: Possible for customers not yet scored by RiskClassification; ~99% are "High" for PEP population
- **ReportDate is Sunday**: Week boundary is Monday–Sunday; the ReportDate value is the Sunday

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
| 16 | ReportDate | date | YES | Week-end date (Sunday) for this snapshot. Computed from @Date parameter as the last day of the Monday–Sunday week. Used as the partition key for DELETE+INSERT idempotency. (Tier 2 — SP_W_AML_PEP_Customers) |
| 17 | Has_eMoney_Account | int | YES | 1 if the customer has an active eToro Money account (IsValidETM=1, IsTestAccount=0, CurrencyBalanceStatusID<>4). 0 otherwise. (Tier 2 — SP_W_AML_PEP_Customers) |
| 18 | eMoney_BalanceStatus | nvarchar(500) | YES | Currency balance status display name for the eMoney account, resolved from eMoney_Dictionary_CurrencyBalanceStatus. NULL if no eMoney account. Values: Active, ReceiveOnly, SpendOnly, Suspended. (Tier 2 — SP_W_AML_PEP_Customers via eMoney_Dim_Account) |
| 19 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — ETL metadata) |
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
  DELETE FROM BI_DB_dbo.BI_DB_W_AML_PEP_Customers WHERE ReportDate = @WeekEndDate
  INSERT INTO BI_DB_dbo.BI_DB_W_AML_PEP_Customers (weekly accumulation)
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
| BI_DB_dbo.BI_DB_W_AML_PEP_Customers_Trun | Sibling — same SP | Current-week-only TRUNCATE copy of this table |

---

## 7. Sample Queries

### 7.1 Current Week PEP Count by Regulation

```sql
SELECT Regualtion,
       COUNT(*) AS PEP_Count,
       SUM(CASE WHEN Selfie_and_SOF_Valid = 'Yes' THEN 1 ELSE 0 END) AS Docs_Valid,
       SUM(Has_eMoney_Account) AS With_eMoney
FROM BI_DB_dbo.BI_DB_W_AML_PEP_Customers
WHERE ReportDate = (SELECT MAX(ReportDate) FROM BI_DB_dbo.BI_DB_W_AML_PEP_Customers)
GROUP BY Regualtion
ORDER BY PEP_Count DESC
```

### 7.2 Document Freshness Trend Over Time

```sql
SELECT ReportDate,
       COUNT(*) AS Total_PEP,
       SUM(Has_Selfie) AS Has_Selfie,
       SUM(Has_SOF) AS Has_SOF,
       SUM(CASE WHEN Selfie_and_SOF_Valid = 'Yes' THEN 1 ELSE 0 END) AS Both_Valid
FROM BI_DB_dbo.BI_DB_W_AML_PEP_Customers
GROUP BY ReportDate
ORDER BY ReportDate DESC
```

### 7.3 High-Risk PEP Customers Without Valid Documents

```sql
SELECT CID, Country, AML_Rank, RiskScoreName,
       RTRIM(PlayerStatus) AS PlayerStatus,
       Selfie_and_SOF_Valid, Has_eMoney_Account
FROM BI_DB_dbo.BI_DB_W_AML_PEP_Customers
WHERE ReportDate = (SELECT MAX(ReportDate) FROM BI_DB_dbo.BI_DB_W_AML_PEP_Customers)
  AND AML_Rank > 0
  AND Selfie_and_SOF_Valid = 'No'
ORDER BY AML_Rank DESC, Country
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found specific to this table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 7 T1, 10 T2, 1 T3, 0 T4, 1 T5 | Elements: 20/20, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_W_AML_PEP_Customers | Type: Table | Production Source: Multi-source via SP_W_AML_PEP_Customers*
