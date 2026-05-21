# BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation

> 1,460-row compliance watchlist of non-US-regulated customers who registered a US mailing address (CountryID=219). VL3 depositors under FCA, CySEC, ASIC, FSA Seychelles, etc. Accumulation table: only NEW customers appended each day via `SP_US_Mailing_Address_Non_US_Regulation`. Covers DateRelevance 2023-11-13 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + External_etoro_Customer_Address + V_Liabilities via `SP_US_Mailing_Address_Non_US_Regulation` |
| **Refresh** | Daily (DELETE @Date + INSERT, accumulation — only new customers) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | — |
| **Row Count** | ~1,460 (as of 2026-04-08) |

---

## 1. Business Meaning

`BI_DB_US_Mailing_Address_Non_US_Regulation` is a compliance watchlist table that identifies non-US-regulated customers who have a US mailing address. These are VL3 (fully verified) depositors under regulations like FCA (571), CySEC (440), ASIC&GAML (232), FSA Seychelles (130), BVI (49), FSRA (24), and ASIC (14) who registered a US mailing address despite being under non-US regulation — a potential regulatory concern for FINRA/FinCEN compliance.

The table uses an accumulation pattern: each day, only NEW customers meeting the criteria are appended (LEFT JOIN excludes already-tracked RealCIDs). The population filter requires: non-US regulation (RegulationID NOT IN 6,7,8,12), VL3 verification, depositor status, valid customer, AND a US mailing address (External_etoro_Customer_Address WHERE CountryID=219).

---

## 2. Business Logic

### 2.1 Population Filter

**What**: Identifies non-US-regulated customers with US mailing addresses.
**Columns Involved**: `RealCID`, `Regulation`, `VerificationLevelID`
**Rules**:
- Step 1: VL3 depositor customers with valid status under NON-US regulations (RegulationID NOT IN 6,7,8,12)
- Step 1.1: Filter to those with US mailing address via External_etoro_Customer_Address WHERE CountryID=219
- Step 4: LEFT JOIN existing table — only NEW customers added (WHERE RealCID IS NULL)
- Excludes PlayerStatusID 2 and 4

### 2.2 Equity Calculation

**What**: Customer equity at time of detection.
**Columns Involved**: `Equity`
**Rules**:
- From V_Liabilities: Equity = Liabilities + ActualNWA

### 2.3 Accumulation Pattern

**What**: Each day only appends newly detected customers.
**Rules**:
- DELETE WHERE DateRelevance=@Date (prevents duplicates for reruns)
- INSERT only customers NOT already present in the table

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — small table (1,460 rows), no performance concerns.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All flagged customers | `SELECT * FROM ... ORDER BY DateRelevance DESC` |
| New detections today | `WHERE DateRelevance = (SELECT MAX(DateRelevance) FROM ...)` |
| Breakdown by regulation | `GROUP BY Regulation ORDER BY COUNT(*) DESC` |
| High-equity flagged customers | `ORDER BY Equity DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `RealCID = RealCID` | Full customer profile |
| DWH_dbo.Dim_VerificationLevel | `VerificationLevelID = VerificationLevelID` | KYC level name |
| BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation_Email | `RealCID = RealCID` | Email snapshot subset |

### 3.4 Gotchas

- **Accumulation, not snapshot**: Each customer appears once — the DateRelevance shows when they were first detected, not current status
- **Equity is point-in-time**: Captured when the customer was first flagged, not updated daily
- **PlayerStatusID exclusions**: PlayerStatusID 2 and 4 are excluded from the population

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
| 1 | RealCID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 2 | FirstDepositDate | date | NO | Date of first deposit. CAST to date from Dim_Customer.FirstDepositDate. (Tier 2 — Customer.CustomerStatic) |
| 3 | VerificationLevelID | int | NO | KYC verification level. FK to Dictionary.VerificationLevel. All rows are VL3 by construction. (Tier 1 — BackOffice.Customer) |
| 4 | Regulation | varchar(50) | NO | Short code for the regulation. Dim-lookup from Dim_Regulation via RegulationID. Values: FCA, CySEC, ASIC&GAML, FSA Seychelles, BVI, FSRA, ASIC. (Tier 1 — Dictionary.Regulation) |
| 5 | PlayerStatus | varchar(50) | NO | Active trading tier/status classification. Passthrough from Dim_PlayerStatus via PlayerStatusID. Values filtered to exclude PlayerStatusID 2 and 4. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 6 | VerificationLevel3Date | date | YES | Date when the customer first reached VL3 verification. From BI_DB_CIDFirstDates. (Tier 2 — SP_CIDFirstDates, Fact_SnapshotCustomer) |
| 7 | Equity | money | YES | Customer equity at time of detection. Computed as V_Liabilities.Liabilities + ActualNWA. (Tier 2 — SP_US_Mailing_Address_Non_US_Regulation) |
| 8 | DateRelevance | date | NO | Date when this customer was first detected and appended. The @Date parameter passed to the SP. (Tier 2 — SP_US_Mailing_Address_Non_US_Regulation) |
| 9 | UpdateDate | datetime | NO | ETL execution timestamp. GETDATE() at SP execution time. (Tier 5 — ETL metadata) |
| 10 | KYC_Country | varchar(250) | YES | Full country name in English. Dim-lookup from Dim_Country via Dim_Customer.CountryID. (Tier 1 — Dictionary.Country) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | Customer.CustomerStatic | CID | passthrough via Dim_Customer |
| FirstDepositDate | Customer.CustomerStatic | FirstDepositDate | CAST to date via Dim_Customer |
| VerificationLevelID | BackOffice.Customer | VerificationLevelID | passthrough via Dim_Customer |
| Regulation | Dictionary.Regulation | Name | dim-lookup |
| KYC_Country | Dictionary.Country | Name | dim-lookup |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (VL3, depositor, valid, NON-US regulation)
  + External_etoro_Customer_Address WHERE CountryID=219 (US mailing address)
  + BI_DB_dbo.BI_DB_CIDFirstDates (VL3 date)
  + DWH_dbo.V_Liabilities (equity)
  + DWH_dbo.Dim_Regulation, Dim_PlayerStatus, Dim_Country (dim lookups)
  |
  |-- LEFT JOIN existing BI_DB_US_Mailing_Address_Non_US_Regulation
  |   WHERE RealCID IS NULL (only NEW customers)
  |
  |-- SP_US_Mailing_Address_Non_US_Regulation @Date
  |   DELETE WHERE DateRelevance=@Date, INSERT new customers
  v
BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation (1,460 rows, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer (RealCID) | Customer record |
| VerificationLevelID | DWH_dbo.Dim_VerificationLevel | KYC level |
| Regulation | DWH_dbo.Dim_Regulation | Regulation dimension |
| VerificationLevel3Date | BI_DB_dbo.BI_DB_CIDFirstDates | VL3 date source |
| Equity | DWH_dbo.V_Liabilities | Equity source |

### 6.2 Referenced By (other objects point to this)

| Element | Referencing Object | Description |
|---------|-------------------|-------------|
| (all columns) | BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation_Email | Email delivery snapshot (latest DateRelevance) |

---

## 7. Sample Queries

### 7.1 Latest Detected Customers

```sql
SELECT RealCID, Regulation, PlayerStatus, Equity, KYC_Country, DateRelevance
FROM BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation
WHERE DateRelevance = (SELECT MAX(DateRelevance) FROM BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation)
ORDER BY Equity DESC
```

### 7.2 Distribution by Regulation

```sql
SELECT Regulation, COUNT(*) AS customer_count, SUM(Equity) AS total_equity
FROM BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation
GROUP BY Regulation
ORDER BY customer_count DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 4 T1, 5 T2, 0 T3, 0 T4, 1 T5 | Elements: 10/10, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation | Type: Table | Production Source: Dim_Customer + Customer_Address + V_Liabilities via SP_US_Mailing_Address_Non_US_Regulation*
