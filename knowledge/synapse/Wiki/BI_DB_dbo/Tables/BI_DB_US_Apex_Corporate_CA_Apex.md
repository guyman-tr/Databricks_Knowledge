# BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_Apex

> 455,993-row daily incremental log of cash corporate actions for US eToro customers sourced from Apex's SOD869 (Start-of-Day) file (October 2021 – April 2026, 1,025 distinct processing dates). Written daily by SP_US_Apex_Corporate_Cash_Actions_Recon using a DELETE-date + INSERT pattern. Companion to BI_DB_US_Apex_Corporate_CA_etoro which captures the same events from eToro's credit history. Together they form the US Corporate Action reconciliation pair: Apex side (this table) vs eToro side.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Apex SOD869 file (External_Sodreconciliation_apex_EXT869_CashActivity) via SP_US_Apex_Corporate_Cash_Actions_Recon |
| **Refresh** | Daily — SP_US_Apex_Corporate_Cash_Actions_Recon @Date; DELETE WHERE ProcessDate=@Date + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

455,993-row daily accumulating log of cash corporate actions from Apex's SOD869 (Start-of-Day reconciliation) file for US clients (RegulationID=8). Each row represents one cash corporate action event for one Apex account on one processing date — dividends, ADR fees, mergers, reinvestments, and other Apex-initiated cash adjustments.

The table serves the **Apex–eToro corporate action reconciliation**: the finance/operations team compares this table (Apex's view of CA events) against BI_DB_US_Apex_Corporate_CA_etoro (eToro's view) to identify discrepancies in timing, amounts, or event classification.

**Action type breakdown**: Dividend (87.5%), NULL/unmapped TerminalID (8.0%), ADR fee (3.0%), Paper Confirmation Fee (1.0%), and smaller types (Merger, Stock Dividend, Interest, Redemption, DRS, Exchange).

**Key data quirks**:
- eToroCID is NULL for ~2.4% of rows (Apex accounts with no matched eToro CID via `#apex`)
- CompensationReasonID is NULL for ~8% of rows (TerminalID with no eToro CA mapping)
- Cusip is NULL for ~7.7% of rows (non-equity actions: ADR fees, paper confirmation)
- Amount is **sign-flipped**: Amount * -1, so positive = cash received by customer (dividend payment)
- SOD869 filter: AccountType='2' and TerminalID != 'OMJNL' (excludes OMJNL = journal entries)

---

## 2. Business Logic

### 2.1 Apex SOD869 to eToro CA Mapping

**What**: Apex TerminalIDs are mapped to eToro's internal corporate action type system for cross-platform reconciliation.

**Columns Involved**: `TerminalID`, `eToroDescription`, `eToroCorporateActionTypeID`, `CompensationReasonID`

**Rules**:
- TerminalID (Apex's CA code, e.g., '$+DIV', 'Z$ADR') is looked up in External_etoro_Trade_TerminalIDToCorporateAction
- Match found → fills eToroCorporateActionTypeID, eToroDescription, CompensationReasonID
- No match (CompensationReasonID IS NULL) → NULL for those columns; 8% of rows are unmapped

### 2.2 eToroCID Resolution

**What**: Apex accounts are linked to eToro customer IDs via the Apex user data lookup.

**Columns Involved**: `AccountNumber`, `eToroCID`

**Rules**:
- AccountNumber (Apex's brokerage account number) is joined to External_USABroker_Apex_UserData via ApexID
- LEFT JOIN: ~2.4% of AccountNumbers have no matched eToroCID (orphan Apex accounts)
- eToroCID is stored as varchar(40) — convert to int for DWH joins

### 2.3 Amount Sign Convention

**What**: Amount is sign-flipped relative to Apex's raw file value.

**Columns Involved**: `Amount`

**Rules**:
- SP computes: `ISNULL(Amount * -1, 0)` — Apex files use negative for customer receipts, eToro convention is positive
- Positive Amount = cash received by customer (dividend, merger proceeds)
- Negative Amount = cash charged to customer (ADR fee, paper confirmation)
- ISNULL=0 used when Amount is missing (rare)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN + HEAP — no distribution optimization. Full table scans by default. Filter on ProcessDate for performance; every query should include a ProcessDate range filter. No clustered index means sequential scan only.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All dividend payments for a specific date | `WHERE ProcessDate = '2026-04-10' AND eToroDescription = 'Dividend'` |
| Total CA amount by type for date range | `WHERE ProcessDate BETWEEN '2026-01-01' AND '2026-03-31' GROUP BY eToroDescription SUM(Amount)` |
| Unmatched CA events (no eToro mapping) | `WHERE CompensationReasonID IS NULL AND ProcessDate = @date` |
| All CAs for a specific eToro customer | `WHERE eToroCID = '12345678'` (remember: varchar, quote it) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_etoro | ProcessDate = Date AND eToroCID = CAST(CID AS varchar) | Reconciliation between Apex and eToro views |
| DWH_dbo.Dim_Customer | CAST(eToroCID AS int) = RealCID | Customer dimension enrichment |

### 3.4 Gotchas

- **Amount is sign-flipped**: Positive = received by customer. Do NOT compare directly to raw Apex source without sign adjustment.
- **eToroCID is varchar**: Cast to int before joining to DWH integer CID columns. NULL rows (~2.4%) must be excluded.
- **Cusip for non-equity**: Cusip NULL means this is a non-equity CA (ADR fee, paper confirmation). Do not filter out NULL Cusip unless restricting to equity events.
- **NULL descriptions**: eToroDescription/eToroCorporateActionTypeID NULL = TerminalID with no eToro mapping (8% of rows). These are Apex-side events not yet reconciled on eToro side.
- **OMJNL exclusion**: TerminalID = 'OMJNL' (journal/memo entries) is explicitly excluded by the SP. These do not appear in this table.
- **ProcessDate ≠ EventDate**: The Apex SOD file date is the processing date, not the corporate action record date. Events may appear 1+ days after they occurred.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Copied verbatim from an upstream wiki |
| Tier 2 | Derived from SP code or external source analysis |
| Tier 3 | Inferred from data sampling and business context |
| Tier 4 | Best available knowledge; requires SME validation |
| Tier 5 | Cross-schema canonical definition |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountNumber | varchar(40) | YES | Apex brokerage account number — unique identifier for the US client's Apex account (e.g., '3ER29861'). Used to link to eToroCID via the Apex user data lookup. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 2 | eToroCID | varchar(40) | YES | eToro customer ID matched from Apex user data via AccountNumber. NULL for ~2.4% of rows where no eToro CID is stored in the Apex user table. Cast to int before joining DWH integer CID columns. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 3 | ProcessDate | date | YES | Apex SOD869 file processing date — the date this corporate action was recorded by Apex. Equals @Date parameter. May differ from actual corporate action effective date by 1+ days. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 4 | TerminalID | varchar(40) | YES | Apex corporate action type code from SOD869. Examples: '$+DIV'=dividend receipt, 'Z$ADR'=ADR fee, 'PCON'=paper confirmation. Used as the join key to map to eToro CA descriptions. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 5 | Cusip | varchar(40) | YES | CUSIP security identifier for the underlying instrument. NULL for non-equity corporate actions (ADR fees, paper confirmation). (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 6 | ApexDescription | varchar(100) | YES | Full instrument or action description from the Apex SOD869 file (e.g., 'AGNC INVESTMENT CORP', '***ENI S P A SPONSORED ADR'). Asterisks prefix indicate foreign instruments with ADR. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 7 | eToroDescription | varchar(100) | YES | eToro's mapped description for this Apex corporate action type, derived from TerminalID lookup. 1=Dividend, 27=ADR fee, etc. NULL when TerminalID has no eToro mapping. Values: Dividend, ADR fee, Paper Confirmation Fee, Merger, Dividend Reinvestments (DRS), Stock Dividend, Interest, Redemption, Exchange, Reverse split, REORG Cash, Cash in Lieu, and NULL. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 8 | eToroCorporateActionTypeID | int | YES | eToro's internal corporate action type ID, mapped from TerminalID via External_etoro_Trade_TerminalIDToCorporateAction. NULL when TerminalID has no mapping. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 9 | CompensationReasonID | int | YES | eToro compensation reason ID for this corporate action, derived from the CA type mapping. NULL for ~8% of rows where TerminalID is not mapped. Links to Dim_CashoutReason for label. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 10 | OriginalQuantity | int | YES | Number of shares involved in the corporate action. ISNULL→0. For stock dividends and splits, reflects share count. 0 for cash-only events (dividends, fees). (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 11 | Amount | money | YES | Cash amount of the corporate action in USD. **Sign-flipped from Apex source** (Amount * -1): positive = cash received by customer; negative = cash charged. ISNULL→0. Range includes negative ADR fees and positive dividend payments. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 12 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|--------------|-----------|
| AccountNumber | Apex SOD869 (EXT869_CashActivity) | AccountNumber | Passthrough |
| eToroCID | External_USABroker_Apex_UserData | CID | LEFT JOIN via AccountNumber→ApexID |
| ProcessDate | Apex SOD869 (EXT869_CashActivity) | ProcessDate | Passthrough |
| TerminalID | Apex SOD869 (EXT869_CashActivity) | TerminalID | Passthrough |
| Cusip | Apex SOD869 (EXT869_CashActivity) | Cusip | Passthrough |
| ApexDescription | Apex SOD869 (EXT869_CashActivity) | Description | Passthrough |
| eToroDescription | External_etoro_Dictionary_CorporateAction | Description | Mapped from TerminalID |
| eToroCorporateActionTypeID | External_etoro_Trade_TerminalIDToCorporateAction | CorporateActionTypeID | Mapped from TerminalID |
| CompensationReasonID | External_etoro_BackOffice_CompensationReason | CompensationReasonID | Mapped from CA type |
| OriginalQuantity | Apex SOD869 (EXT869_CashActivity) | OriginalQuantity | ISNULL→0 |
| Amount | Apex SOD869 (EXT869_CashActivity) | Amount | * -1, ISNULL→0 |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
Apex SOD869 file (External_Sodreconciliation_apex_EXT869_CashActivity)
  AccountType='2', TerminalID != 'OMJNL', ProcessDate = @Date
  + External_Sodreconciliation_apex_SodFiles (latest Status=2, ApexFormat=869 file)
  + External_USABroker_Apex_ApexData / UserData (eToroCID resolution)
  + External_etoro_Trade_TerminalIDToCorporateAction (TerminalID → CA mapping)
  + External_etoro_Dictionary_CorporateAction (CA type descriptions)
  + External_etoro_BackOffice_CompensationReason (CompensationReason lookup)
    |-- SP_US_Apex_Corporate_Cash_Actions_Recon @Date (Daily, step 8) ---|
    |   DELETE WHERE ProcessDate=@Date + INSERT
    v
BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_Apex
  (455,993 rows, Oct 2021 – Apr 2026, ROUND_ROBIN, HEAP)
  (UC: Not Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| eToroCID | DWH_dbo.Dim_Customer | Customer lookup (cast eToroCID to int) |
| CompensationReasonID | DWH_dbo.Dim_CashoutReason | Compensation reason label |

### 6.2 Referenced By

| Object | Reference Column | Description |
|--------|-----------------|-------------|
| BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_etoro | ProcessDate / Date + eToroCID | Companion table for CA reconciliation |

---

## 7. Sample Queries

### Daily Dividend Summary for US Clients

```sql
SELECT
    ProcessDate,
    COUNT(*) AS dividend_count,
    SUM(Amount) AS total_dividend_amount
FROM [BI_DB_dbo].[BI_DB_US_Apex_Corporate_CA_Apex]
WHERE eToroDescription = 'Dividend'
  AND ProcessDate >= '2026-01-01'
GROUP BY ProcessDate
ORDER BY ProcessDate DESC;
```

### Unreconciled Events (No eToro CA Mapping)

```sql
SELECT
    TerminalID,
    COUNT(*) AS unmatched_count,
    SUM(Amount) AS total_amount
FROM [BI_DB_dbo].[BI_DB_US_Apex_Corporate_CA_Apex]
WHERE CompensationReasonID IS NULL
  AND ProcessDate >= '2026-01-01'
GROUP BY TerminalID
ORDER BY unmatched_count DESC;
```

### CA Reconciliation Between Apex and eToro Views

```sql
SELECT
    a.ProcessDate,
    a.AccountNumber,
    a.eToroCID,
    a.eToroDescription AS apex_event_type,
    a.Amount AS apex_amount,
    e.eToroDescription AS etoro_event_type,
    e.Payment AS etoro_payment
FROM [BI_DB_dbo].[BI_DB_US_Apex_Corporate_CA_Apex] a
LEFT JOIN [BI_DB_dbo].[BI_DB_US_Apex_Corporate_CA_etoro] e
    ON a.ProcessDate = e.Date
   AND a.eToroCID = CAST(e.CID AS varchar(40))
WHERE a.ProcessDate = '2026-04-10'
  AND a.eToroDescription = 'Dividend'
ORDER BY a.Amount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources found. Author: Artyom Bogomolsky (2021-10-27). Description: "Show Cash Corporate Actions For USA Clients under regulation 8 from Apex and eToro DB."

---

*Generated: 2026-04-22 | Quality: 8.7/10 | Phases: 10/14*
*Tiers: 0 T1, 12 T2, 0 T3, 0 T4 | Elements: 12/12, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_Apex | Type: Table | Production Source: Apex SOD869 via SP_US_Apex_Corporate_Cash_Actions_Recon*
