# BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_CIDs

> 1,284-row daily reference table listing 951 specific customer accounts flagged by the AML team across 5 risk classification lists (PEP, Complex/Unusual Transactions, High-Risk SAR, High-Risk HNWI, Gaming/eGambling). Source: AML-maintained Google Sheets spreadsheet synced via Fivetran to Azure Data Lake (Silver/SharePoint/compliance_help_cids). Refreshed daily by TRUNCATE+INSERT.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | AML Google Sheets (compliance_help_cids) via Fivetran → Silver/SharePoint |
| **Refresh** | Daily — TRUNCATE + INSERT (full rebuild each run) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_Compliance_Restriction_Lists_CIDs is a small AML compliance reference table that lists specific customer accounts (CIDs) flagged by the eToro AML team for enhanced monitoring or risk classification. The data originates from a Google Sheets spreadsheet maintained manually by the AML compliance team (originally linked at https://bit.ly/3ccznBr), synced to the data lake via Fivetran (Google Sheets connector) and exposed through a Synapse External Table before being loaded here.

Each row represents one customer's membership in one risk list for a specific date range. A customer may appear on multiple lists across multiple date ranges (1,284 rows for 951 distinct CIDs). The five list types reflect AML investigation categories: PEP (Politically Exposed Persons), Complex/Unusual Transactions, SARS-related high risk, High Net Worth Individual risk, and Gaming/eGambling.

This table is consumed by downstream compliance SPs: SP_Compliance_Forbidden_Trades, SP_RBSF, and SP_Y_RBSF use the restriction data to flag or filter customer activity.

**Note**: The column `cid` in the External Table source is stored as nvarchar(4000) and is implicitly cast to int at INSERT time. Similarly, `from_date` and `to_date` are nvarchar in the source but date in the physical table.

---

## 2. Business Logic

### 2.1 Risk List Classification

**What**: AML team classifies customers into named risk categories with effective date ranges.

**Columns Involved**: CID, List, FromDate, ToDate

**Rules**:
- One row = one customer on one list for one date range
- Date ranges specify when the customer was/is actively flagged on that list
- Multiple rows per CID are possible (different lists or different date periods)
- NULL ToDate = open-ended (flag still active as of last update)

### 2.2 List Type Semantics

**What**: Each List value represents a distinct AML risk category.

**Columns Involved**: List

**Rules**:
- `Complex/Unusual_TXs` (472 rows): Customers with complex or unusual transaction patterns requiring enhanced monitoring
- `Other_High_Risk_SARS` (436 rows): High-risk customers relevant to Suspicious Activity Reports
- `PEP` (300 rows): Politically Exposed Persons — heightened due-diligence category
- `Other_High_Risk_HNWI` (38 rows): High Net Worth Individuals flagged for enhanced scrutiny
- `Gaming/eGamling` (38 rows): Customers with gaming/eGambling activity (note: typo in source — 'eGamling' not 'eGambling', preserved from Google Sheet)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**Distribution**: ROUND_ROBIN — small table (1,284 rows), distribution irrelevant for performance.

**Index**: CLUSTERED INDEX (CID ASC) — efficient for CID-based lookups but the table is so small that full scans are equally fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Is a customer on any AML list? | `WHERE CID = @cid` (check rows exist) |
| Currently active flags only | `WHERE (ToDate IS NULL OR ToDate >= CAST(GETDATE() AS date)) AND FromDate <= CAST(GETDATE() AS date)` |
| Customers on PEP list | `WHERE List = 'PEP'` |
| All lists for a CID | `WHERE CID = @cid ORDER BY FromDate` |
| Count per list type | `GROUP BY List ORDER BY COUNT(*) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON crl.CID = dc.RealCID | Customer attributes for flagged accounts |
| BI_DB_dbo.BI_DB_CIDFirstDates | ON crl.CID = fd.CID | Registration and FTD dates |

### 3.4 Gotchas

- **'Gaming/eGamling' typo**: The List value has a misspelling from the source Google Sheet ('eGamling' not 'eGambling'). Cannot be fixed in SP without changing the source sheet. Filter with the exact misspelled string.
- **Full rebuild daily**: TRUNCATE+INSERT means rows from yesterday are gone — no historical trend data. This is a current-state list, not a log.
- **nvarchar implicit cast**: External Table source has CID as nvarchar(4000). Invalid non-numeric values in the Google Sheet would cause INSERT failures. If SP fails, check source sheet for data quality.
- **No grain key**: A CID can appear multiple times (different lists, different date ranges). There is no unique constraint.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| *** | Tier 2 — SP code / ETL logic | (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer account on this AML risk list. Sourced from AML team's Google Sheet (nvarchar implicitly cast to int at INSERT). FK to Dim_Customer.RealCID for customer attributes. (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |
| 2 | List | varchar(100) | YES | AML risk classification name. Values: 'Complex/Unusual_TXs', 'Other_High_Risk_SARS', 'PEP', 'Other_High_Risk_HNWI', 'Gaming/eGamling' (eGambling typo from source). (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |
| 3 | FromDate | date | YES | Start date of this customer's active period on this risk list, as entered by the AML team. (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |
| 4 | ToDate | date | YES | End date of this customer's active period on this risk list. NULL = open-ended (flag still active). (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |
| 5 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 2 — SP_CID_Compliance_CID_And_Country_Risk_Lists) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | compliance_help_cids Google Sheet | cid (nvarchar) | Implicit cast nvarchar → int |
| List | compliance_help_cids Google Sheet | list | Passthrough |
| FromDate | compliance_help_cids Google Sheet | from_date (nvarchar) | Implicit cast nvarchar → date |
| ToDate | compliance_help_cids Google Sheet | to_date (nvarchar) | Implicit cast nvarchar → date |
| UpdateDate | ETL | GETDATE() | Set at INSERT time |

### 5.2 ETL Pipeline

```
AML team Google Sheets (compliance_help_cids tab)
  |-- Fivetran (Google Sheets connector, SharePoint/compliance_help_cids) ---|
  v
Azure Data Lake: Silver/SharePoint/compliance_help_cids/ (Parquet)
  |-- External Table: BI_DB_dbo.External_Fivetran_gsheets_compliance_help_cids
  |-- SP_CID_Compliance_CID_And_Country_Risk_Lists (TRUNCATE + INSERT SELECT)
  v
BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_CIDs (1,284 rows)
  |-- UC: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension for flagged accounts |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| SP_Compliance_Forbidden_Trades | BI_DB_Compliance_Restriction_Lists_CIDs | Compliance forbidden trade checks |
| SP_RBSF | BI_DB_Compliance_Restriction_Lists_CIDs | Risk-based supervision framework |
| SP_Y_RBSF | BI_DB_Compliance_Restriction_Lists_CIDs | Yearly RBSF variant |

---

## 7. Sample Queries

### 7.1 Currently active AML flags

```sql
SELECT CID, List, FromDate, ToDate
FROM   [BI_DB_dbo].[BI_DB_Compliance_Restriction_Lists_CIDs]
WHERE  FromDate <= CAST(GETDATE() AS date)
  AND  (ToDate IS NULL OR ToDate >= CAST(GETDATE() AS date))
ORDER BY List, CID;
```

### 7.2 PEP customers with their registration dates

```sql
SELECT c.CID,
       c.List,
       c.FromDate,
       c.ToDate,
       dc.RegisteredReal
FROM   [BI_DB_dbo].[BI_DB_Compliance_Restriction_Lists_CIDs] c
JOIN   [DWH_dbo].[Dim_Customer] dc ON c.CID = dc.RealCID
WHERE  c.List = 'PEP'
ORDER BY dc.RegisteredReal DESC;
```

### 7.3 Distribution by list type

```sql
SELECT List,
       COUNT(*)         AS TotalEntries,
       COUNT(DISTINCT CID) AS DistinctCIDs
FROM   [BI_DB_dbo].[BI_DB_Compliance_Restriction_Lists_CIDs]
GROUP BY List
ORDER BY TotalEntries DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-21 | Quality: 9.0/10 | Phases: 14/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 0 T5 | Elements: 5/5, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_Compliance_Restriction_Lists_CIDs | Type: Table | Production Source: AML Google Sheets (compliance_help_cids) via Fivetran*
