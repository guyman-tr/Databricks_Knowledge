# BI_DB_dbo.BI_DB_Deposits_WiresFromGooglesheets

> 48,472-row near-real-time wire deposit operations tracking table sourced from a Google Sheets working file used by the payments department — TRUNCATE+INSERT with no history, containing wire transfer details (CID, amounts, bank info, SWIFT codes, IBAN, processing status) for Tableau dashboards, refreshed hourly/daily via SP_H_Deposits_Wires_From_Googlesheet (author: Guy Manova, 2021-02-18).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.External_Fivetran_google_sheets_wire_deposits_ops (Google Sheets via Fivetran) via SP_H_Deposits_Wires_From_Googlesheet |
| **Refresh** | Daily (SB_Daily, Priority 0) — TRUNCATE + INSERT (no history retained) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_Deposits_WiresFromGooglesheets is an operational tracking table for wire transfer deposits processed by the eToro payments team. The Google Sheets source is the active working file where payment operations staff track incoming wire deposits, their processing status, and resolution.

The table contains 48,472 rows representing individual wire deposit transactions. It is TRUNCATE+INSERT with no history — each refresh completely replaces the table contents with the current state of the Google Sheet. This means the table reflects the latest status of all tracked wires, not a historical log.

All columns are varchar(1000) (except UpdateDate) because the source is a Google Sheet with inconsistent data types. The SP applies minimal cleanup: replacing Google Sheets null indicators (values containing 'N', which includes '#N/A', 'NA', 'N/A') with defaults ('0' for amounts, '1' for IDs, NULL for Account ID).

The primary consumer is a Tableau dashboard for near-real-time wire deposit monitoring. Status values track the wire processing lifecycle: Pool (unmatched) → Processed/Mass processed → Returned/Reversed.

**PII WARNING**: This table contains sensitive banking information (IBAN, SWIFT codes, bank account numbers, client names, bank names). Handle per data governance policies.

---

## 2. Business Logic

### 2.1 Wire Processing Status Lifecycle

**What**: Tracks the processing status of incoming wire deposits through the payments pipeline.
**Columns Involved**: Status
**Rules**:
- Mass processed (76%): Automatically processed in batch
- Returned (14%): Wire returned to sender
- Processed (7%): Manually processed
- Reversed (1%): Transaction reversed after processing
- Pool statuses: Unidentified/Below $10/Client — wires awaiting matching
- Other: Recalled, Duplicate, Internal Settlement, Handle

### 2.2 Null Cleanup from Google Sheets

**What**: Handles Google Sheets null/error values that arrive as text.
**Columns Involved**: Amount received, CID, Deposit ID, Rate, USD amount
**Rules**:
- Values containing 'N' (catches #N/A, NA, N/A) → replaced with defaults
- Amount received, Rate, USD amount → '0' (zero string)
- CID, Deposit ID → '1' (placeholder non-null value)
- Account ID → always NULL (hardcoded in SP due to data quality issues)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN
- **Index**: HEAP — no optimization (small table, frequently truncated)

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Pending wires | `WHERE Status LIKE 'Pool%'` |
| Processed today | `WHERE [Processed date in BO] LIKE '2026-04%' AND Status IN ('Processed', 'Mass processed')` |
| Wire by CID | `WHERE CID = @cid` (CID is varchar, not int!) |
| Total USD volume by status | `SUM(CAST([USD amount] AS FLOAT)) GROUP BY Status` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CAST(CID AS INT) = RealCID | Customer profile |
| BI_DB_dbo.BI_DB_CIDFirstDates | ON CAST(CID AS INT) = CID | First dates context |

### 3.4 Gotchas

- **ALL columns are varchar(1000)** — CAST is required for numeric comparisons or aggregations. CID, Amount, Rate, USD amount are all stored as strings
- **No history** — TRUNCATE+INSERT means historical status changes are lost. The table always shows the current Google Sheet state
- **CID = '1'** is a placeholder for null values (cleanup from Google Sheets #N/A). Filter `WHERE CID <> '1'` for valid records
- **Account ID is always NULL** — hardcoded in SP due to persistent data quality issues in the Google Sheet
- **Date columns are varchar** — 'Date received', 'Processed date in BO', etc. are all varchar(1000), not date types. Parse carefully
- **PII present**: IBAN, SWIFT codes, client names, bank details. Do not expose in non-secured dashboards
- **Exponential notation** — some numeric values arrive in scientific notation (e.g., '1.40E+08') from Google Sheets. Tableau handles this at import, but SQL queries need explicit CAST

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 2 | SP code / ETL logic analysis | High |
| Tier 5 | Propagation rule (ETL metadata pattern) | Standard |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Account ID | varchar(1000) | YES | Always NULL. Hardcoded in SP due to persistent data quality issues in the Google Sheet source. Not usable. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 2 | Amount received | varchar(1000) | YES | Wire deposit amount in the original currency. String type — CAST to numeric for calculations. '0' when source was null/N/A. May contain scientific notation. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 3 | Assignee Name | varchar(1000) | YES | Payments team member assigned to handle this wire. From the Google Sheet's assignee column. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 4 | Bank reference number | varchar(1000) | YES | Bank's reference/transaction number for the wire transfer. May include quoted strings from the Google Sheet (leading double-quote observed in data). (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 5 | CID | varchar(1000) | YES | eToro customer ID as a string. CAST to INT for joins to Dim_Customer. '1' is a placeholder for null/N/A values from Google Sheets. **PII**. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 6 | Client Bank Name | varchar(1000) | YES | Name of the client's sending bank (e.g., "REVOLUT BANK UAB", "WISE PAYMENTS LIMITED", "Sparkasse Bochum"). (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 7 | Comments | varchar(1000) | YES | Free-text comments from payments team (e.g., "Missing documents"). (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 8 | Country | varchar(1000) | YES | Client's country (e.g., "Germany", "United States", "Hong Kong"). (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 9 | Currency | varchar(1000) | YES | Original currency of the wire transfer (e.g., "EUR", "USD", "AED", "GBP"). (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 10 | Date received | varchar(1000) | YES | Date the wire was received by eToro's bank. String type — parse as date. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 11 | Deposit ID | varchar(1000) | YES | eToro deposit identifier. String type — '1' is a placeholder for null/N/A. CAST to INT for joins. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 12 | eToro Bank Name | varchar(1000) | YES | Receiving eToro bank (e.g., "DeutscheBank", "JPM UK", "JPM UAE"). Indicates which eToro bank entity received the wire. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 13 | Full description for MEMO BO | varchar(1000) | YES | Full SWIFT message description/memo for back-office reference. Contains transaction details, reference numbers, and sender information. **PII**. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 14 | IBAN / Account number | varchar(1000) | YES | Client's IBAN or account number for the sending bank. **PII — sensitive banking data**. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 15 | Pool date added | varchar(1000) | YES | Date the wire was added to the unmatched pool. String type — parse as date. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 16 | Pool date deducted | varchar(1000) | YES | Date the wire was removed from the pool (matched or returned). String type — parse as date. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 17 | Processed date in BO | varchar(1000) | YES | Date the wire was processed in back-office systems. String type — parse as date. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 18 | Rate | varchar(1000) | YES | Currency conversion rate applied. String type — '0' when source was null/N/A. CAST to numeric for calculations. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 19 | Regulation | varchar(1000) | YES | Regulatory entity for the client (e.g., "FCA", "CySEC"). (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 20 | Return date | varchar(1000) | YES | Date the wire was returned to sender (for returned wires). String type — parse as date. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 21 | Status | varchar(1000) | YES | Wire processing status. 18 distinct values. Mass processed (76%), Returned (14%), Processed (7%), Reversed (1%), Pool/Unidentified, Pool/Below $10, Duplicate, etc. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 22 | Swift Code | varchar(1000) | YES | SWIFT/BIC code of the sending bank (e.g., "REVOLT21XXX", "HSBCHKHHHKH"). (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 23 | Ticket number | varchar(1000) | YES | Support ticket number associated with the wire (e.g., Zendesk/Salesforce ticket). (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 24 | Transaction name originator/Payment recipient | varchar(1000) | YES | Name of the wire sender or payment recipient. **PII**. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 25 | USD amount | varchar(1000) | YES | Wire amount converted to USD. String type — '0' when source was null/N/A. CAST to numeric for calculations. May contain scientific notation. (Tier 2 — SP_H_Deposits_Wires_From_Googlesheet) |
| 26 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at INSERT time. (Tier 5 — Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| All columns | External_Fivetran_google_sheets_wire_deposits_ops | Various | Passthrough with null cleanup (LIKE '%N%' → defaults) |

### 5.2 ETL Pipeline

```
Google Sheets (wire_deposits_ops — payments team working file)
  |-- Fivetran sync (hourly) ---|
  v
BI_DB_dbo.External_Fivetran_google_sheets_wire_deposits_ops
  |-- SP_H_Deposits_Wires_From_Googlesheet ---|
  |-- Null cleanup (CASE LIKE '%N%') ---|
  |-- Account ID → NULL (hardcoded) ---|
  |-- TRUNCATE + INSERT ---|
  v
BI_DB_dbo.BI_DB_Deposits_WiresFromGooglesheets (48K rows, ROUND_ROBIN, HEAP)
  |-- Tableau dashboard ---|
  v
Payments team wire deposit monitoring
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension (requires CAST to INT) |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| (none found in SSDT) | — | Tableau wire deposit monitoring dashboards |

---

## 7. Sample Queries

### 7.1 Wire Status Summary

```sql
SELECT Status, COUNT(*) AS wires,
       SUM(CASE WHEN TRY_CAST([USD amount] AS FLOAT) > 0
           THEN TRY_CAST([USD amount] AS FLOAT) ELSE 0 END) AS total_usd
FROM [BI_DB_dbo].[BI_DB_Deposits_WiresFromGooglesheets]
WHERE CID <> '1'
GROUP BY Status
ORDER BY wires DESC;
```

### 7.2 Wires by eToro Bank

```sql
SELECT [eToro Bank Name], COUNT(*) AS wires,
       SUM(CASE WHEN TRY_CAST([USD amount] AS FLOAT) > 0
           THEN TRY_CAST([USD amount] AS FLOAT) ELSE 0 END) AS total_usd
FROM [BI_DB_dbo].[BI_DB_Deposits_WiresFromGooglesheets]
WHERE Status IN ('Processed', 'Mass processed')
GROUP BY [eToro Bank Name]
ORDER BY total_usd DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14 (P10 Atlassian unavailable)*
*Tiers: 0 T1, 25 T2, 0 T3, 0 T4, 1 T5 | Elements: 26/26, Logic: 7/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Deposits_WiresFromGooglesheets | Type: Table | Production Source: Google Sheets via Fivetran via SP_H_Deposits_Wires_From_Googlesheet*
