# BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_etoro

> 987,192-row daily incremental log of cash credit events for US eToro customers (RegulationID=8) sourced from eToro's internal credit history (October 2021 – April 2026, 1,288 distinct dates). Written daily by SP_US_Apex_Corporate_Cash_Actions_Recon using DELETE-date + INSERT. Companion to BI_DB_US_Apex_Corporate_CA_Apex which captures the same events from Apex's SOD869 file. Together they form the US Corporate Action reconciliation pair: eToro side (this table) vs Apex side.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | External_etoro_history_credit_Apex_Artyom (CreditTypeID=14, RegulationID=8) via SP_US_Apex_Corporate_Cash_Actions_Recon |
| **Refresh** | Daily — SP_US_Apex_Corporate_Cash_Actions_Recon @Date; DELETE WHERE Date=@Date + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

987,192-row daily accumulating log of CreditTypeID=14 credit transactions from eToro's credit history for US-regulated (RegulationID=8) customers from October 2021 to April 2026 (1,288 distinct dates). Each row represents one credit event recorded in eToro's backoffice system for a US customer — including dividends, fees, and other corporate action-related credits/debits.

The table serves the **Apex–eToro corporate action reconciliation**: comparing eToro's internal credit view against the Apex SOD869 file (BI_DB_US_Apex_Corporate_CA_Apex) to detect discrepancies in amounts, timing, or event classification.

**Event type breakdown**: Cash Dividend (41.5%) and "Not defined" (58.5%). The large "Not defined" category includes fee records (OpenTotalFees, CloseTotalFees, etc.) where CompensationReasonID is NULL — these credit events have CreditTypeID=14 but no matching CompensationReason mapping in the eToro CA lookup tables.

**Key data quirks**:
- 58.5% of eToroDescription = 'Not defined': credits where CompensationReasonID is NULL but CreditTypeID=14; includes trading fees charged to US customers
- CA_Desc_ID: numeric extracted from Description text via PATINDEX (e.g., '14' extracted from 'OpenTotalFees14') — NULL/0 for unstructured descriptions
- ApexID: NULL when no matched Apex account for the CID

---

## 2. Business Logic

### 2.1 eToroDescription Assignment

**What**: Each credit event is mapped to a human-readable description via a cascading CASE logic.

**Columns Involved**: `eToroDescription`, `CompensationReasonID`, `Description`

**Rules**:
- If CompensationReasonID is NOT NULL and a #cadesc match exists → use the matched eToroDescription from External_etoro_Dictionary_CorporateAction
- If no #cadesc match AND Description LIKE '%Cash Dividend%' → eToroDescription = 'Cash Dividend'
- Otherwise → eToroDescription = 'Not defined'
- Result: only two distinct values in practice: 'Cash Dividend' (41.5%) and 'Not defined' (58.5%)

### 2.2 CA_Desc_ID Extraction

**What**: A numeric corporate action ID is extracted from the free-text Description field.

**Columns Involved**: `CA_Desc_ID`, `CA_Description`, `Description`

**Rules**:
- CA_Desc_ID = first numeric substring in Description (PATINDEX-based extraction)
- CA_Description = lookup in External_etoro_Dictionary_CorporateAction by CA_Desc_ID
- 0 or NULL CA_Desc_ID = no numeric ID found in Description (free-text only records)
- This is a best-effort extraction — not reliable for all description formats

### 2.3 Population Scope: US Only

**What**: This table contains ONLY US-regulated customers.

**Columns Involved**: `CID`

**Rules**:
- Filter at source: `External_etoro_BackOffice_Customer.RegulationID = 8` (USA)
- CreditTypeID=14: corporate action-related credits AND fees (broader than pure dividends)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN + HEAP — no distribution optimization. Filter on Date for performance. This table is ~2× larger than its companion (CA_Apex) due to the broader CreditTypeID=14 filter capturing fees.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Cash dividends paid to US customers | `WHERE eToroDescription = 'Cash Dividend' AND Date = @date` |
| All CA credits for a specific customer | `WHERE CID = 12345678 AND Date >= '2026-01-01'` |
| Days with highest CA volume | `GROUP BY Date, COUNT(*)` with Date filter |
| Reconciliation gap (in eToro but not Apex) | LEFT JOIN to CA_Apex on Date+CID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_Apex | Date = ProcessDate AND CID = CAST(eToroCID AS int) | CA reconciliation |
| DWH_dbo.Dim_Customer | CID = RealCID | Customer dimension enrichment |

### 3.4 Gotchas

- **"Not defined" is not a data error**: 58.5% of rows have eToroDescription='Not defined'. This is correct — it means the credit had CreditTypeID=14 but no CA mapping (likely trading fees). Do not filter out 'Not defined' for volume analysis.
- **CompensationReasonID IS NULL is expected**: For all 'Not defined' rows, CompensationReasonID is NULL. This is a normal result of the LEFT JOIN logic.
- **CA_Desc_ID = 0**: Rows where Description has no leading numeric — not an error. eToroDescription='Not defined' rows typically have CA_Desc_ID=0.
- **ApexID NULL**: Not all eToro US customers have a linked Apex account. ApexID NULL is normal for customers who have not been assigned an Apex account number.
- **Date ≠ ProcessDate**: This table uses `Date` (eToro credit event date), CA_Apex uses `ProcessDate` (Apex SOD file date). These may differ by 1 day — join on both columns with tolerance or use Date range filters.
- **Payment vs TotalCashChange**: Payment = the CA-specific amount; TotalCashChange = net change including fees and other adjustments. Use Payment for CA amount analysis; TotalCashChange for balance impact.

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
| 1 | Date | date | YES | Credit event date — CAST(Occurred AS DATE) from eToro credit history. Equals @Date parameter. May differ from Apex ProcessDate by 1 day (different source recording times). (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 2 | CID | int | YES | eToro customer ID (integer). Always a US-regulated customer (RegulationID=8 filter at source). Used to join to DWH_dbo.Dim_Customer on RealCID. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 3 | CompensationReasonID | int | YES | eToro compensation reason ID for this CA credit. NULL for ~58.5% of rows where no CA mapping was found (fee records, unstructured credits). When populated, links to Dim_CashoutReason. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 4 | Payment | money | YES | Cash amount of this credit event in USD. The CA-specific payment (dividend amount, fee amount). Negative = charged to customer. Use this column for CA amount analysis. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 5 | TotalCashChange | money | YES | Net cash balance change including all adjustments. May differ from Payment when fees or offsets apply. Use for balance impact analysis; use Payment for CA amount. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 6 | Description | varchar(100) | YES | Raw description text from eToro credit history (e.g., 'OpenTotalFees', 'CloseTotalFees', 'Cash Dividend'). Source for CA_Desc_ID extraction. Free-text, not standardized. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 7 | ApexID | varchar(50) | YES | Apex brokerage account number linked to this CID. NULL when no Apex account is associated with the customer. Sourced via LEFT JOIN to External_USABroker_Apex_ApexData. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 8 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 9 | eToroCorporateActionTypeID | int | YES | eToro's internal CA type ID mapped from CompensationReasonID via External_etoro_Trade_TerminalIDToCorporateAction. NULL for unmatched rows (58.5%). (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 10 | CA_Desc_ID | int | YES | Numeric CA type ID extracted from Description text via PATINDEX. Best-effort extraction — 0 when no numeric found. Used to look up CA_Description. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 11 | CA_Description | varchar(100) | YES | Human-readable CA type description from External_etoro_Dictionary_CorporateAction, looked up by CA_Desc_ID. NULL when CA_Desc_ID=0 or no match. (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |
| 12 | eToroDescription | varchar(100) | YES | Mapped CA event description. CASE logic: matched CompensationReason→mapped desc; Description LIKE '%Cash Dividend%'→'Cash Dividend'; else→'Not defined'. Values: 'Cash Dividend' (41.5%), 'Not defined' (58.5%). (Tier 2 — SP_US_Apex_Corporate_Cash_Actions_Recon) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|--------------|-----------|
| Date | External_etoro_history_credit_Apex_Artyom | Occurred | CAST(Occurred AS DATE) |
| CID | External_etoro_history_credit_Apex_Artyom | CID | Passthrough |
| CompensationReasonID | External_etoro_history_credit_Apex_Artyom | CompensationReasonID | Passthrough |
| Payment | External_etoro_history_credit_Apex_Artyom | Payment | Passthrough |
| TotalCashChange | External_etoro_history_credit_Apex_Artyom | TotalCashChange | Passthrough |
| Description | External_etoro_history_credit_Apex_Artyom | Description | Passthrough |
| ApexID | External_USABroker_Apex_ApexData | ApexID | LEFT JOIN via CID |
| UpdateDate | — | — | GETDATE() |
| eToroCorporateActionTypeID | External_etoro_Trade_TerminalIDToCorporateAction | CorporateActionTypeID | Mapped from CompensationReasonID |
| CA_Desc_ID | External_etoro_history_credit_Apex_Artyom | Description | PATINDEX numeric extraction |
| CA_Description | External_etoro_Dictionary_CorporateAction | Description | Lookup by CA_Desc_ID |
| eToroDescription | External_etoro_Dictionary_CorporateAction | Description | CASE: matched→desc; like Cash Dividend→'Cash Dividend'; else→'Not defined' |

### 5.2 ETL Pipeline

```
External_etoro_history_credit_Apex_Artyom
  (CreditTypeID=14, RegulationID=8 USA, Occurred >= @Date AND < @Date+1)
  + External_etoro_BackOffice_Customer  (RegulationID=8 filter)
  + External_USABroker_Apex_ApexData    (ApexID lookup via CID)
  + External_etoro_Trade_TerminalIDToCorporateAction  (CA type mapping)
  + External_etoro_Dictionary_CorporateAction         (CA descriptions)
    |-- SP_US_Apex_Corporate_Cash_Actions_Recon @Date (Daily, step 7) ---|
    |   DELETE WHERE Date=@Date + INSERT
    v
BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_etoro
  (987,192 rows, Oct 2021 – Apr 2026, ROUND_ROBIN, HEAP)
  (UC: Not Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer lookup on RealCID |
| CompensationReasonID | DWH_dbo.Dim_CashoutReason | Compensation reason label |

### 6.2 Referenced By

| Object | Reference Column | Description |
|--------|-----------------|-------------|
| BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_Apex | ProcessDate / Date + eToroCID/CID | Companion table for CA reconciliation |

---

## 7. Sample Queries

### Cash Dividends by Day (2026 Q1)

```sql
SELECT
    Date,
    COUNT(*) AS dividend_events,
    SUM(Payment) AS total_payment
FROM [BI_DB_dbo].[BI_DB_US_Apex_Corporate_CA_etoro]
WHERE eToroDescription = 'Cash Dividend'
  AND Date BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY Date
ORDER BY Date DESC;
```

### Fee vs Dividend Breakdown by Month

```sql
SELECT
    YEAR(Date) AS yr,
    MONTH(Date) AS mo,
    eToroDescription,
    COUNT(*) AS event_count,
    SUM(Payment) AS total_payment
FROM [BI_DB_dbo].[BI_DB_US_Apex_Corporate_CA_etoro]
WHERE Date >= '2025-01-01'
GROUP BY YEAR(Date), MONTH(Date), eToroDescription
ORDER BY yr DESC, mo DESC, total_payment;
```

### Customers with Both Apex and eToro CA Records (Reconciliation)

```sql
SELECT
    e.Date,
    e.CID,
    e.Payment AS etoro_payment,
    a.Amount AS apex_amount,
    e.eToroDescription,
    a.eToroDescription AS apex_description
FROM [BI_DB_dbo].[BI_DB_US_Apex_Corporate_CA_etoro] e
INNER JOIN [BI_DB_dbo].[BI_DB_US_Apex_Corporate_CA_Apex] a
    ON e.Date = a.ProcessDate
   AND e.CID = CAST(a.eToroCID AS int)
WHERE e.Date = '2026-04-10'
  AND e.eToroDescription = 'Cash Dividend'
ORDER BY ABS(e.Payment - a.Amount) DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources found. Author: Artyom Bogomolsky (2021-10-27). Same SP as BI_DB_US_Apex_Corporate_CA_Apex.

---

*Generated: 2026-04-22 | Quality: 8.7/10 | Phases: 10/14*
*Tiers: 0 T1, 12 T2, 0 T3, 0 T4 | Elements: 12/12, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_etoro | Type: Table | Production Source: External_etoro_history_credit_Apex_Artyom via SP_US_Apex_Corporate_Cash_Actions_Recon*
