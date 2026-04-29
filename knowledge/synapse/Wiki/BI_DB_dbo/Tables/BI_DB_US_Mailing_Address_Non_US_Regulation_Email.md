# BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation_Email

> Email delivery snapshot table — daily TRUNCATE+INSERT of only the latest DateRelevance records from the parent `BI_DB_US_Mailing_Address_Non_US_Regulation` table. Used to generate automated compliance email alerts for new US-address non-US-regulation customers detected that day. Currently 1 row.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation via `SP_US_Mailing_Address_Non_US_Regulation` |
| **Refresh** | Daily (TRUNCATE+INSERT, latest DateRelevance snapshot) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | — |
| **Row Count** | ~1 (as of 2026-04-08) |

---

## 1. Business Meaning

`BI_DB_US_Mailing_Address_Non_US_Regulation_Email` is a daily snapshot table that feeds automated compliance email alerts. Each day, the SP truncates this table and inserts only the records from the parent table (`BI_DB_US_Mailing_Address_Non_US_Regulation`) where `DateRelevance = MAX(DateRelevance)`. This provides a clean, small dataset of newly detected customers for email delivery systems.

The table has identical columns to the parent table. Its sole purpose is to decouple the email delivery layer from the accumulation table, ensuring that only the latest day's detections are surfaced in compliance notifications.

---

## 2. Business Logic

### 2.1 Latest-Day Snapshot

**What**: Extracts only the most recent DateRelevance records from the parent table.
**Columns Involved**: `DateRelevance` (all columns)
**Rules**:
- Read from BI_DB_US_Mailing_Address_Non_US_Regulation WHERE DateRelevance = MAX(DateRelevance)
- TRUNCATE target table, INSERT snapshot
- All column values are passthrough from parent table

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — trivially small table (typically 0-5 rows per day).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Today's compliance alert customers | `SELECT * FROM ...` (entire table is the answer) |
| Full history | Use parent table `BI_DB_US_Mailing_Address_Non_US_Regulation` instead |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `RealCID = RealCID` | Full customer profile |
| BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation | `RealCID = RealCID` | Parent accumulation table |

### 3.4 Gotchas

- **TRUNCATE+INSERT**: Table contains only the latest day's records — not cumulative
- **May be empty**: If no new customers were detected on the latest run date, the table will be empty
- **Same SP as parent**: Both this table and the parent are written by SP_US_Mailing_Address_Non_US_Regulation

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
| 1 | RealCID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Passthrough from parent table. (Tier 1 — Customer.CustomerStatic) |
| 2 | FirstDepositDate | date | NO | Date of first deposit. Passthrough from parent table. (Tier 1 — Customer.CustomerStatic) |
| 3 | VerificationLevelID | int | NO | KYC verification level. FK to Dictionary.VerificationLevel. All rows are VL3 by construction. Passthrough from parent table. (Tier 1 — BackOffice.Customer) |
| 4 | Regulation | varchar(50) | NO | Short code for the regulation. Values: FCA, CySEC, ASIC&GAML, FSA Seychelles, BVI, FSRA, ASIC. Passthrough from parent table. (Tier 1 — Dictionary.Regulation) |
| 5 | PlayerStatus | varchar(50) | NO | Active trading tier/status classification. Values filtered to exclude PlayerStatusID 2 and 4. Passthrough from parent table. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 6 | VerificationLevel3Date | date | YES | Date when the customer first reached VL3 verification. Passthrough from parent table. (Tier 2 — SP_CIDFirstDates, Fact_SnapshotCustomer) |
| 7 | Equity | money | YES | Customer equity at time of detection. Computed as V_Liabilities.Liabilities + ActualNWA. Passthrough from parent table. (Tier 2 — SP_US_Mailing_Address_Non_US_Regulation) |
| 8 | DateRelevance | date | NO | Date when this customer was first detected. Equals MAX(DateRelevance) from parent table. Passthrough from parent table. (Tier 2 — SP_US_Mailing_Address_Non_US_Regulation) |
| 9 | UpdateDate | datetime | NO | ETL execution timestamp. Passthrough from parent table. (Tier 5 — ETL metadata) |
| 10 | KYC_Country | varchar(250) | YES | Full country name in English. Passthrough from parent table. (Tier 1 — Dictionary.Country) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | Customer.CustomerStatic | CID | passthrough via parent table |
| FirstDepositDate | Customer.CustomerStatic | FirstDepositDate | passthrough via parent table |
| VerificationLevelID | BackOffice.Customer | VerificationLevelID | passthrough via parent table |
| Regulation | Dictionary.Regulation | Name | passthrough via parent table |
| KYC_Country | Dictionary.Country | Name | passthrough via parent table |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation
  WHERE DateRelevance = MAX(DateRelevance)
  |
  |-- SP_US_Mailing_Address_Non_US_Regulation (last portion)
  |   TRUNCATE + INSERT
  v
BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation_Email (1 row, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| (all columns) | BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation | Parent accumulation table |
| RealCID | DWH_dbo.Dim_Customer (RealCID) | Customer record |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory. Consumed by email delivery system (external).

---

## 7. Sample Queries

### 7.1 Current Email Alert Recipients

```sql
SELECT RealCID, Regulation, PlayerStatus, Equity, KYC_Country, DateRelevance
FROM BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation_Email
```

### 7.2 Compare Email Snapshot to Full History

```sql
SELECT e.RealCID, e.DateRelevance AS email_date, h.DateRelevance AS first_detected
FROM BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation_Email e
JOIN BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation h ON e.RealCID = h.RealCID
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-27 | Quality: 7.5/10 | Phases: 13/14*
*Tiers: 4 T1, 5 T2, 0 T3, 0 T4, 1 T5 | Elements: 10/10, Logic: 7/10, Lineage: 7/10*
*Object: BI_DB_dbo.BI_DB_US_Mailing_Address_Non_US_Regulation_Email | Type: Table | Production Source: BI_DB_US_Mailing_Address_Non_US_Regulation via SP_US_Mailing_Address_Non_US_Regulation*
