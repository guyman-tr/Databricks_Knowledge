# BI_DB_dbo.BI_DB_ASIC_CreditLine_At_transfer

> 655K-row daily-incremental table tracking customers who transferred their regulatory entity to ASIC (ID=4) or ASIC & GAML (ID=10), capturing their credit line amount at the time of transfer. Sourced from DWH_dbo.Fact_RegulationTransfer with credit line snapshot from BI_DB_Daily_CreditLine. Refreshed daily by SP_ASIC_CreditLine_At_transfer.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `DWH_dbo.Fact_RegulationTransfer` + `BI_DB_dbo.BI_DB_Daily_CreditLine` via `SP_ASIC_CreditLine_At_transfer` |
| **Refresh** | Daily — DELETE-INSERT by DateID |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_ASIC_CreditLine_At_transfer` records every customer who transferred their regulatory jurisdiction TO ASIC or ASIC & GAML, along with their open credit line amount at the moment of transfer. This supports ASIC compliance monitoring — specifically tracking whether customers carried leveraged credit line exposure when they moved under Australian Securities and Investments Commission (ASIC) oversight.

The table is built from `DWH_dbo.Fact_RegulationTransfer`, which detects regulation changes by comparing consecutive `BackOfficeCustomer` SCD2 history records. The SP filters to only transfers where `ToRegulationID IN (4, 10)` — ASIC and ASIC & GAML respectively. It then LEFT JOINs `BI_DB_dbo.BI_DB_Daily_CreditLine` to capture the customer's total credit line amount on the transfer date. Since this is a LEFT JOIN, the vast majority of rows (99.94%) have NULL `TotalCLAmount` — meaning most transferred customers had no active credit line.

Data spans from 2019-04-26 (earliest DateOccurred) to present, with 655K rows and 1,375 unique ETL dates. The SP runs daily as part of the SB_Daily process (Priority 20), executing a delete-insert per DateID — first removing any existing rows for that date, then inserting fresh results from the #cl temp table.

---

## 2. Business Logic

### 2.1 ASIC/GAML Transfer Filter

**What**: Only regulation transfers TO ASIC or ASIC & GAML are captured.

**Columns Involved**: `ToRegulation`, `FromRegulation`

**Rules**:
- SP filter: `WHERE frt.ToRegulationID IN (4, 10)` — RegulationID 4 = ASIC, RegulationID 10 = ASIC & GAML
- ToRegulation distribution: 76% "ASIC & GAML", 24% "ASIC"
- FromRegulation has 14 distinct values: BVI (68%), ASIC (15%), CySEC (15%), FCA (1.3%), and 10 others
- As of February 28, 2024, eToro no longer approves transfers INTO ASIC/GAML for non-Australian/NZ clients (Confluence: "ASIC Regulation Transfer Procedure")

### 2.2 Credit Line Snapshot at Transfer

**What**: Captures the customer's credit line amount on the exact date of regulation transfer.

**Columns Involved**: `TotalCLAmount`, `CID`, `DateID`

**Rules**:
- LEFT JOIN `BI_DB_Daily_CreditLine` on matching DateID + RealCID=CID
- NULL TotalCLAmount means no active credit line at transfer time (99.94% of rows — only 416 rows have a value)
- Credit line is leveraged buying power extended to customers — the Credit Line × 3 rule applies for cashout calculations (Confluence: "Credit Line COs")

### 2.3 Daily Incremental Load Pattern

**What**: The SP processes one date at a time via the @Date parameter.

**Columns Involved**: `DateID`, `DateOccurred`, `UpdateDate`

**Rules**:
- `@DateID = CONVERT(VARCHAR, @Date, 112)` — converts date to YYYYMMDD int
- DELETE all rows for that DateID, then INSERT fresh results
- Idempotent — safe to re-run for any date
- UpdateDate = GETDATE() — reflects SP execution time, not business date

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on CID. ROUND_ROBIN means JOINs on CID will require data movement (shuffle). Filter on CID for index seek; filter on DateID for date-range scans (but note DateID is not the leading index column — CID is).

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All transfers to ASIC on a specific date | `WHERE DateID = @dt` |
| Customer's transfer history | `WHERE CID = @cid ORDER BY DateID` |
| Transfers where customer had active credit line | `WHERE TotalCLAmount IS NOT NULL` (only 416 rows) |
| Count transfers by source regulation | `GROUP BY FromRegulation` |
| Monthly transfer volume | `GROUP BY LEFT(CAST(DateID AS VARCHAR), 6)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Customer demographics, verification level |
| DWH_dbo.Dim_Date | ON DateID = DateID | Calendar attributes for the transfer date |
| BI_DB_dbo.BI_DB_Daily_CreditLine | ON DateID = DateID AND RealCID = CID | Full credit line details (fee, ratio, exceeded status) |
| DWH_dbo.Fact_RegulationTransfer | ON CID = CID AND DateID = DateID | Full financial snapshot at transfer (equity, AUM, positions) |

### 3.4 Gotchas

- **TotalCLAmount is 99.94% NULL**: Most customers have no credit line at transfer time. Only 416 out of 655K rows have a non-NULL value. Do not assume this column is reliably populated.
- **FromRegulation can be "ASIC"**: Transfers FROM ASIC TO ASIC & GAML appear in this table (101K rows). This is not circular — ASIC and ASIC & GAML are distinct regulatory entities.
- **CID not GCID**: This table uses CID (Real account ID), matching Fact_RegulationTransfer. JOIN on CID, not GCID.
- **Column names have spaces**: `TotalCLAmount` has no spaces, but the SP aliases use single-quoted column names (`'FromRegulation'`). The DDL column names are clean.
- **DateOccurred vs UpdateDate**: DateOccurred is the business date of the transfer; UpdateDate is when the SP ran. They differ by ~1 day (SP runs the day after the event).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 — Upstream wiki verbatim | `(Tier 1 — source)` |
| ★★★☆☆ | Tier 2 — Synapse SP code | `(Tier 2 — source)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FromRegulation | varchar(100) | YES | Short code for the regulation the customer was under BEFORE the transfer. Values match production Dictionary.Regulation.Name. 14 distinct values: BVI (68%), ASIC (15%), CySEC (15%), FCA (1.3%), eToroUS, NFA, FSA Seychelles, FSRA, ASIC & GAML, FinCEN, None, FinCEN+FINRA, FINRAONLY, MAS. (Tier 1 — Dictionary.Regulation, join-enriched via Fact_RegulationTransfer.FromRegulationID) |
| 2 | ToRegulation | varchar(100) | YES | Short code for the regulation the customer was transferred TO. Values match production Dictionary.Regulation.Name. Strict 2-value enum: "ASIC & GAML" (76%), "ASIC" (24%). Filtered by SP to ToRegulationID IN (4, 10). (Tier 1 — Dictionary.Regulation, join-enriched via Fact_RegulationTransfer.ToRegulationID) |
| 3 | CID | int | NO | Customer ID (Real account). Distribution key in Fact_RegulationTransfer. JOINs to Dim_Customer.RealCID. Clustered index column. (Tier 2 — SP_Fact_RegulationTransfer_DL_To_Synapse) |
| 4 | TotalCLAmount | decimal(11,2) | YES | Total credit line amount in USD at the time of regulation transfer. Carried forward from previous day + any new credit line actions. LEFT JOINed from BI_DB_Daily_CreditLine on DateID + RealCID=CID — NULL when customer had no active credit line (99.94% of rows). Only 416 out of 655K rows have a non-NULL value. (Tier 2 — SP_Daily_CreditLine, join-enriched) |
| 5 | DateID | int | NO | Date of the regulation transfer in YYYYMMDD format. Converted from @Date parameter via `CONVERT(VARCHAR, @Date, 112)`. JOINs to Dim_Date. Used as DELETE scope for daily incremental reload. (Tier 2 — SP_Fact_RegulationTransfer_DL_To_Synapse) |
| 6 | DateOccurred | date | YES | Business date of the regulation transfer event. Set from the SP @Date parameter. Represents when the customer's regulation actually changed — not when the SP ran. (Tier 2 — SP_ASIC_CreditLine_At_transfer) |
| 7 | UpdateDate | datetime | YES | ETL execution timestamp — GETDATE() during SP execution. Indicates when the SP ran, not the business event date. (Tier 2 — SP_ASIC_CreditLine_At_transfer) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| FromRegulation | DWH_dbo.Dim_Regulation (← etoro.Dictionary.Regulation) | Name | join-enriched via FromRegulationID |
| ToRegulation | DWH_dbo.Dim_Regulation (← etoro.Dictionary.Regulation) | Name | join-enriched via ToRegulationID |
| CID | DWH_dbo.Fact_RegulationTransfer (← etoro.History.BackOfficeCustomer) | CID | passthrough |
| TotalCLAmount | BI_DB_dbo.BI_DB_Daily_CreditLine | TotalCLAmount | join-enriched (LEFT JOIN) |
| DateID | DWH_dbo.Fact_RegulationTransfer | DateID | passthrough |
| DateOccurred | — | @Date | ETL-computed (SP parameter) |
| UpdateDate | — | — | ETL-computed (GETDATE()) |

Full upstream documentation:
- [Fact_RegulationTransfer](../../../DWH_dbo/Tables/Fact_RegulationTransfer.md)
- [Dim_Regulation](../../../DWH_dbo/Tables/Dim_Regulation.md)
- [BI_DB_Daily_CreditLine](BI_DB_Daily_CreditLine.md)

### 5.2 ETL Pipeline

```
etoro.History.BackOfficeCustomer (SCD2 customer history)
    │
    └─ SP_Fact_RegulationTransfer_DL_To_Synapse
        └─ DWH_dbo.Fact_RegulationTransfer (regulation change events)
                │
                ├── JOIN DWH_dbo.Dim_Regulation (×2, FROM/TO regulation names)
                ├── LEFT JOIN BI_DB_dbo.BI_DB_Daily_CreditLine (credit line snapshot)
                │
                └─ SP_ASIC_CreditLine_At_transfer @Date
                    ├─ CTAS #cl (WHERE ToRegulationID IN (4,10))
                    ├─ DELETE WHERE DateID = @DateID
                    └─ INSERT → BI_DB_dbo.BI_DB_ASIC_CreditLine_At_transfer (655K rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Ultimate Source | etoro.History.BackOfficeCustomer | SCD2 customer history with RegulationID changes |
| DWH Source | DWH_dbo.Fact_RegulationTransfer | Regulation change events with DateID, CID, From/ToRegulationID |
| Lookup | DWH_dbo.Dim_Regulation | 15-row regulation dimension for name resolution |
| Enrichment | BI_DB_dbo.BI_DB_Daily_CreditLine | Daily credit line snapshot for TotalCLAmount |
| ETL | SP_ASIC_CreditLine_At_transfer | CTAS→DELETE→INSERT, filtered to ASIC/GAML transfers |
| Target | BI_DB_dbo.BI_DB_ASIC_CreditLine_At_transfer | 655K rows, daily incremental |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer demographics via RealCID |
| DateID | DWH_dbo.Dim_Date | Calendar date attributes |
| FromRegulation / ToRegulation | DWH_dbo.Dim_Regulation | Regulation names (already resolved by SP — no ID column stored) |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers in the SSDT repo. Used for ASIC compliance reporting and ad-hoc regulatory analysis.

---

## 7. Sample Queries

### 7.1 Daily transfer volume by source regulation

```sql
SELECT
    DateID,
    FromRegulation,
    COUNT(*) AS TransferCount,
    SUM(CASE WHEN TotalCLAmount IS NOT NULL THEN 1 ELSE 0 END) AS WithCreditLine
FROM [BI_DB_dbo].[BI_DB_ASIC_CreditLine_At_transfer]
WHERE DateID >= 20260101
GROUP BY DateID, FromRegulation
ORDER BY DateID DESC, TransferCount DESC;
```

### 7.2 Customers who transferred with an active credit line

```sql
SELECT
    CID,
    FromRegulation,
    ToRegulation,
    TotalCLAmount,
    DateOccurred
FROM [BI_DB_dbo].[BI_DB_ASIC_CreditLine_At_transfer]
WHERE TotalCLAmount IS NOT NULL
ORDER BY TotalCLAmount DESC;
```

### 7.3 Monthly transfer trend with customer demographics

```sql
SELECT
    LEFT(CAST(a.DateID AS VARCHAR), 6) AS YearMonth,
    a.ToRegulation,
    COUNT(DISTINCT a.CID) AS UniqueCustomers,
    SUM(ISNULL(a.TotalCLAmount, 0)) AS TotalCreditLineExposure
FROM [BI_DB_dbo].[BI_DB_ASIC_CreditLine_At_transfer] a
GROUP BY LEFT(CAST(a.DateID AS VARCHAR), 6), a.ToRegulation
ORDER BY YearMonth DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [ASIC Regulation Transfer Procedure](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/11845697772/ASIC+Regulation+Transfer+Procedure) | Confluence | Transfer procedure for ASIC/GAML — covers clients with open credit line facilities |
| [Moving regulation / regulation transfer](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/1722319409/Moving+regulation+regulation+transfer) | Confluence | As of Feb 28 2024, no exceptions for non-AUS/NZ clients transferring to ASIC/GAML |
| [Credit Line COs](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/12002099381/Credit+Line+COs) | Confluence | Credit Line × 3 = AAA; Equity - AAA = cashout limit. Applies across ASIC, CySEC, FCA |

---

*Generated: 2026-03-28 | Quality: 8.5/10 (★★★★☆) | Phases: 14/14*
*Tiers: 2 T1, 5 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 10/10*
*Object: BI_DB_dbo.BI_DB_ASIC_CreditLine_At_transfer | Type: Table | Production Source: DWH_dbo.Fact_RegulationTransfer*
