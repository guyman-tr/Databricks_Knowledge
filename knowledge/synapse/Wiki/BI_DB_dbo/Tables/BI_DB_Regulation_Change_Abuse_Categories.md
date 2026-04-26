# BI_DB_dbo.BI_DB_Regulation_Change_Abuse_Categories

> Daily full-rebuild frequency distribution (260K rows) of regulation-change behavior across all depositing customers, grouped by FTD cohort month × regulatory jurisdiction × geographic segment × account attributes × exact change count — used to identify which demographic clusters are most affected by regulation-switching patterns.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer (LAG-based change detection) + Dim_Customer (population) + Dim_Regulation + Dim_Country + Dim_AccountType + Dim_PlayerLevel + Dim_PlayerStatus |
| **Refresh** | Daily — SP_Regulation_Change_Abuse @Date; full TRUNCATE + INSERT (co-authored with BI_DB_Regulation_Change_Abuse_CIDs in same SP execution) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | Not Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_Regulation_Change_Abuse_Categories` provides a **demographic frequency distribution** of how many times eToro depositing customers changed their regulatory jurisdiction. It answers questions like: "Among customers who first deposited in Jan 2024 and are governed by CySEC in Spain — how many have changed regulation exactly 3 times?"

Every qualifying depositing customer (IsValidCustomer=1, IsDepositor=1) is represented in this table. The table groups them by seven demographic dimensions and their exact regulation change count. Customers with zero changes have `Total_RegChangeCount = NULL`. The `CIDsCount` column shows how many customers fall into each bucket.

This table is the **aggregate/distribution** sibling to `BI_DB_Regulation_Change_Abuse_CIDs`, which holds the individual-level records for the subset of customers with ≥6 changes (flagged as potential abusers). Both tables are populated by the same SP execution.

As of 2026-04-13: 260,077 rows. CySEC dominates (51% of rows), followed by FCA (19%), FSA Seychelles (15%), ASIC & GAML (7.5%). Mean change counts per regulation: CySEC avg 2.24 (max 21), FCA avg 3.02 (max 12), NYDFS+FINRA avg 4.08 (highest average — 13 rows only). Change counts range from NULL (no changes) up to 46 in isolated outlier cases.

---

## 2. Business Logic

### 2.1 Population: All Depositing Valid Customers

**What**: The base population includes ALL customers who have deposited at least once and are "valid" (non-internal, non-excluded).
**Columns Involved**: All
**Rules**:
- `DWH_dbo.Dim_Customer WHERE IsValidCustomer=1 AND IsDepositor=1` — includes ~15M+ customers
- Demographic attributes (Regulation, Country, etc.) are the customer's **current** values at run time, not at time of change
- The population is a snapshot of today's customer state

### 2.2 Regulation Change Detection (LAG Pattern)

**What**: Changes are detected by comparing each customer's daily regulation assignment to the previous day's assignment.
**Columns Involved**: `Total_RegChangeCount`
**Rules**:
- Source: `DWH_dbo.Fact_SnapshotCustomer` — daily snapshot of all customers with their RegulationID
- Change event: `LAG(RegulationID,1,0) OVER(PARTITION BY RealCID ORDER BY UpdateDate)` → row flagged where `RegulationID <> Previous_RegulationID`
- Each flagged row is numbered per CID: `ROW_NUMBER() OVER(PARTITION BY CID ORDER BY UpdateDate)` → `RegChangeRowNum`
- Final per-CID total: `MAX(RegChangeRowNum)` → `Total_RegChangeCount`
- Customers with zero detected changes: LEFT JOIN produces NULL for Total_RegChangeCount

```
Change detection:
  Day 1: CID=100, RegulationID=1 (CySEC)
  Day 2: CID=100, RegulationID=5 (BVI)     ← change #1
  Day 3: CID=100, RegulationID=1 (CySEC)   ← change #2
  → Total_RegChangeCount = 2 for this CID
```

### 2.3 Demographic Aggregation

**What**: The table is a GROUP BY of all depositing customers at the intersection of demographic dimensions and exact change count.
**Columns Involved**: FTDMonthYear, Regulation, Country, Region, AccountType, PlayerLevel, PlayerStatus, Total_RegChangeCount, CIDsCount
**Rules**:
- One row per unique combination of (FTDMonthYear, Regulation, Country, Region, AccountType, PlayerLevel, PlayerStatus, Total_RegChangeCount)
- `CIDsCount = COUNT(CID)` within each bucket
- High cardinality: 260K rows reflects the many distinct demographic combinations
- Rows with `Total_RegChangeCount = NULL` represent customer groups with no detected regulation changes

### 2.4 Same-SP Co-authorship

**What**: Both `BI_DB_Regulation_Change_Abuse_Categories` and `BI_DB_Regulation_Change_Abuse_CIDs` are written by the same SP execution of `SP_Regulation_Change_Abuse`.
**Implication**: The two tables are always consistent with each other — they reflect the same underlying change detection run. If one is being refreshed (during the ETL window), both may be in a transitional state simultaneously.

---

## 3. Query Advisory

### 3.1 Distribution & Index

ROUND_ROBIN with HEAP. At 260K rows this is a small table — full scans are fast. No broadcast/hash optimization needed. Use standard SELECT with WHERE clauses.

### 3.2 NULL Total_RegChangeCount Means Zero Changes

A row with `Total_RegChangeCount IS NULL` represents the population of customers in that demographic bucket who have **never changed regulation**. This is not missing data — it is the zero-change group, which is typically the largest bucket.

### 3.3 Current Demographics, Not Historical

Demographic attributes (Regulation, Country, etc.) in this table reflect the customer's **current** regulation/country/status at the time of the daily run, NOT the regulation they were in when they made changes. A customer currently in CySEC who previously changed from BVI→CySEC will be counted under CySEC, even if most of their changes were from another regulation.

### 3.4 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Which regulation has the most "regulation switchers"? | `WHERE Total_RegChangeCount >= 6 GROUP BY Regulation ORDER BY SUM(CIDsCount) DESC` |
| Distribution of change counts for FCA customers | `WHERE Regulation = 'FCA' AND Total_RegChangeCount IS NOT NULL GROUP BY Total_RegChangeCount ORDER BY Total_RegChangeCount` |
| How many customers changed regulation at all? | `WHERE Total_RegChangeCount IS NOT NULL GROUP BY Regulation, SUM(CIDsCount)` |
| FTD cohort vs. regulation change propensity | `GROUP BY FTDMonthYear, Regulation, SUM(CASE WHEN Total_RegChangeCount >= 1 THEN CIDsCount ELSE 0 END)` |

---

## 4. Elements

| # | Column | Type | Nullable | Confidence | Tier | Description |
|---|--------|------|----------|------------|------|-------------|
| 1 | FTDMonthYear | varchar | YES | CODE-BACKED | T2 | FTD cohort month as text (e.g., 'Jan-2024'). Groups customers by when they first deposited. |
| 2 | Regulation | varchar | YES | CODE-BACKED | T1 | Regulatory jurisdiction governing this customer group (current regulation at run time). From Dim_Regulation. Values: CySEC, FCA, ASIC, FSA Seychelles, FinCEN+FINRA, etc. |
| 3 | Country | varchar | YES | CODE-BACKED | T1 | Customer country name. From Dim_Country. |
| 4 | Region | varchar | YES | CODE-BACKED | T1 | Marketing region label. From Dim_Country (e.g., 'EMEA', 'LatAm', 'APAC'). |
| 5 | AccountType | varchar | YES | CODE-BACKED | T1 | Account type name. From Dim_AccountType. |
| 6 | PlayerLevel | varchar | YES | CODE-BACKED | T1 | eToro Club loyalty tier. From Dim_PlayerLevel (Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond). |
| 7 | PlayerStatus | varchar | YES | CODE-BACKED | T1 | Customer account status. From Dim_PlayerStatus. |
| 8 | Total_RegChangeCount | int | YES | CODE-BACKED | T2 | Number of regulation changes detected for customers in this demographic bucket (via LAG on Fact_SnapshotCustomer). NULL = customers with zero regulation changes. See §2.2. |
| 9 | CIDsCount | int | YES | CODE-BACKED | T2 | Number of customers (CIDs) in this demographic × change-count bucket. Aggregate COUNT from the SP grouping step. |
| 10 | UpdateDate | datetime | YES | CODE-BACKED | T2 | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

---

## 5. Lineage

See `BI_DB_Regulation_Change_Abuse_Categories.lineage.md` for full source chain.

### ETL Pipeline Summary

```
DWH_dbo.Fact_SnapshotCustomer (daily regulatory snapshot)
  └── LAG(RegulationID) change detection → #regulation01 → #regulation02
        └── MAX(RegChangeRowNum) per CID → #maxchanges

DWH_dbo.Dim_Customer (IsValidCustomer=1, IsDepositor=1) → #ftdpop
  + dimension enrichment (Dim_Regulation, Dim_Country, Dim_AccountType, Dim_PlayerLevel, Dim_PlayerStatus)
  └── LEFT JOIN #maxchanges → #categorytable → GROUP BY all dims → #finalagg

  └── SP_Regulation_Change_Abuse (@Date) — TRUNCATE + INSERT
        v
BI_DB_dbo.BI_DB_Regulation_Change_Abuse_Categories (260K rows, ROUND_ROBIN)
```

---

## 6. Relationships

### Produced By
| SP | Schedule | Priority | Pattern |
|----|----------|----------|---------|
| SP_Regulation_Change_Abuse | Daily | P20 (third wave) | TRUNCATE + full INSERT (co-written with BI_DB_Regulation_Change_Abuse_CIDs in same execution) |

### Co-authored With
- `BI_DB_Regulation_Change_Abuse_CIDs` — individual abuser list (Total_RegChangeCount ≥ 6). Always consistent with this table since both are populated in the same SP run.

---

## 7. Tier Legend

| Tier | Meaning |
|------|---------|
| T1 | Verbatim from upstream wiki (DWH_dbo Dim* docs) |
| T2 | ETL-computed — traced to SP code |
| T3 | Inferred |

---

*Documented 2026-04-22 — Batch 33 | SP: SP_Regulation_Change_Abuse | Quality target: 8.5+*
