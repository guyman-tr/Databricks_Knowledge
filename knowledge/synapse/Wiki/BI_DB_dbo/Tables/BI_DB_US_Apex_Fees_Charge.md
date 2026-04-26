# BI_DB_dbo.BI_DB_US_Apex_Fees_Charge

> 209,246-row daily incremental log of non-corporate-action cash activity from Apex's SOD869 file for US eToro customers and the eToro MSB omnibus account (October 2021 – April 2026, 1,007 distinct processing dates). Written daily by SP_US_Apex_Fees_Charge using DELETE-date + INSERT. Captures money market purchases, ACH disbursements, margin transfers, paper statement fees, wire transfers, ADR fees, and management fees — specifically excluding the dividend/CA TerminalIDs that flow into BI_DB_US_Apex_Corporate_CA_Apex.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Apex SOD869 file (BI_DB_dbo.External_Sodreconciliation_apex_EXT869_CashActivity) via SP_US_Apex_Fees_Charge |
| **Refresh** | Daily — SP_US_Apex_Fees_Charge @Date; DELETE WHERE ProcessDate=@Date + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (ProcessDate) |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

209,246-row daily accumulating log of non-CA cash activity from Apex's SOD869 (Start-of-Day reconciliation) file for US eToro customers and the eToro MSB omnibus account (October 2021 – April 2026, 1,007 distinct processing dates). Each row represents one cash activity event for one Apex account on one processing date that is NOT a corporate action dividend event.

The table captures two populations:
- **Customers** (96.3%): Individual US client accounts (AccountType 1 or 2), all with Amount>0. Includes money market purchases, ACH disbursements, margin transfers, paper statement fees, wire transfers, ADR fees, and ACH reversal charges.
- **MSB** (3.7%): eToro's omnibus Money Services Business account (AccountNumber='3ET05007'), which routes client activity to Apex. Includes management/HWM fees, domestic wire fees, and operational charges. Amount can be negative (MSB branch has no positive-only filter).

The table is the **fee/transfer complement to BI_DB_US_Apex_Corporate_CA_Apex**: both draw from the same Apex SOD869 source, but CA_Apex captures dividend/CA events (specific TerminalIDs) and this table captures everything else (those TerminalIDs excluded).

**Event type breakdown by TerminalID**:
- FDFND (MM Purchase): 61.3% — money market fund purchases
- MGJRL (MSB HWM/fees): 7.4% — high watermark and management charges for MSB account
- SMFEE (paper statement): 6.1% — monthly paper statement fees
- COFEE (confirmation fee): 5.3% — paper confirmation fees
- 9DACH (ACH disbursement): 4.4% — outgoing ACH transfers
- Z$ADR (ADR fee): 3.4% — American Depositary Receipt fees
- 2TTFR (margin transfer): 3.4% — cash-to-margin or margin-to-cash transfers
- Other: 8.7% — wire transfers, reverse ACH, fund transfers, misc journals

---

## 2. Business Logic

### 2.1 Two-Population Pattern: MSB vs Customers

**What**: The SP produces one output table from two distinct account populations with different filtering logic.

**Columns Involved**: `Account`, `AccountNumber`, `AccountType`, `Amount`, `TerminalID`

**Rules**:
- **MSB branch** (Account='MSB'): AccountNumber='3ET05007' only; excludes TerminalID='OMJNL' and 'FWWRD'; no Amount filter — negative amounts (reversals/credits) are included
- **Customer branch** (Account='Customers'): AccountType IN ('1','2'); Amount>0 (positive charges only); excludes AccountNumber='3ET05007' and '3ET00001' (reserve accounts); excludes all dividend/CA TerminalIDs
- Account='MSB' or 'Customers' is hardcoded in the SP — not from the Apex SOD869 source

### 2.2 Non-CA TerminalID Filter

**What**: The SP excludes all dividend and corporate-action TerminalIDs from the customer branch to isolate fee/transfer events. These excluded events flow instead into BI_DB_US_Apex_Corporate_CA_Apex.

**Columns Involved**: `TerminalID`

**Rules**:
- Excluded TerminalIDs for customers: OMJNL (journal), DVRED (dividend reduction), $+DIV (dividend), RERTS (return/restore), OTMMR, OTINT (interest), MGJNL (mgmt journal), RGMER (merger), SPDIV (special dividend), DGDIV (special dividend variant), RGRED (redemption), DVDIV (dividend), DVREI (dividend reinvestment), DJDIV, XCINT
- Z$ADR (ADR fee) is NOT excluded — ADR fees appear in both this table and CA_Apex. Context determines which is appropriate for a given analysis.
- FWWRD (wire transfer) is excluded from MSB but NOT from customers — wire transfers appear only in customer rows

### 2.3 Amount Sign Convention

**What**: Amount is passed through from the Apex SOD869 source WITHOUT sign-flipping.

**Columns Involved**: `Amount`

**Rules**:
- Amount = raw Apex SOD869 value (no * -1 transform — contrast with CA_Apex which applies Amount * -1)
- Customer branch: Amount>0 filter ensures all customer rows have positive amounts (charges to customers)
- MSB branch: Amount can be negative (reversals, credits against the omnibus account)
- Amount range observed: -3,760.64 to 1,000,000; avg $464 overall

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on ProcessDate. Always include a ProcessDate filter — the clustered index makes date-range queries significantly faster than in the HEAP tables. Avoid full-table scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All charges for a specific date | `WHERE ProcessDate = '2026-04-10'` (clustered index scan) |
| Money market purchases only | `WHERE TerminalID = 'FDFND' AND ProcessDate >= '2026-01-01'` |
| MSB fee analysis | `WHERE Account = 'MSB' AND ProcessDate BETWEEN '2026-01-01' AND '2026-03-31'` |
| Paper statement fees by month | `WHERE TerminalID = 'SMFEE' GROUP BY ProcessDate, SUM(Amount)` |
| ACH reversals / NSF fees | `WHERE TerminalID IN ('L1RET', 'ACJRL') AND ProcessDate >= @date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_Apex | ProcessDate + AccountNumber | Compare fee vs CA events for same account on same day |
| DWH_dbo.Dim_Customer | (requires joining via Apex user table) | No direct CID in this table; must join via External_USABroker_Apex_UserData |

### 3.4 Gotchas

- **No CID column**: Unlike CA_Apex/CA_etoro, this table has no eToro CID. To link to eToro customers, join AccountNumber via External_USABroker_Apex_UserData to get the CID.
- **FDFND is the dominant type (61.3%) and is NOT a fee**: 'MM Purchase' is a money market fund purchase transfer, not a traditional fee charge. Filter by TerminalID to isolate actual fees (SMFEE, COFEE, Z$ADR, etc.).
- **Amount is NOT sign-flipped**: Unlike CA_Apex (which flips Amount * -1), this table passes Amount through unchanged. Positive = charged/transferred; do not apply a sign flip when comparing.
- **MSB negatives**: Negative amounts are only in the MSB branch. All customer rows have Amount>0 due to SP filter.
- **Cusip NULL is expected**: 30% of rows (62,777) have NULL Cusip. This is normal for non-security transactions (MM purchases, wire transfers, ACH).
- **Account = ETL artifact**: The 'MSB'/'Customers' split is determined by SP branch logic, not by any field in the Apex SOD869 file. Do not attempt to derive it from AccountType or AccountNumber for historical data.
- **Z$ADR appears in both tables**: ADR fees (Z$ADR) are NOT excluded from this table. If analysing ADR fees, be aware they also appear in CA_Apex — avoid double-counting.
- **FWWRD (wire transfer) excluded from MSB only**: Wire transfers for customers ARE present. FWWRD is absent only from the MSB row population.
- **EnteredBy 41 NULLs**: Negligible rate; cosmetic issue only.

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
| 1 | AccountNumber | varchar(40) | YES | Apex brokerage account number — unique identifier for the US client's Apex account (e.g., '3ET05007' for MSB, '5GU27056' format for customers). Used to link to eToro CID via External_USABroker_Apex_UserData when needed. (Tier 2 — SP_US_Apex_Fees_Charge) |
| 2 | AccountType | varchar(40) | YES | Apex account type code. Values: '1' (cash account, 88.2%) and '2' (margin account, 11.8%). The SP filters customer branch to AccountType IN ('1','2'). (Tier 2 — SP_US_Apex_Fees_Charge) |
| 3 | Amount | money | YES | Cash amount in USD. **NOT sign-flipped** (unlike CA_Apex.Amount which applies * -1). Positive = charged to or transferred by the account. Negative only for MSB branch (reversals/credits). Customer branch always positive (Amount>0 SP filter). Range: -3,760.64 to 1,000,000; avg $464. (Tier 2 — SP_US_Apex_Fees_Charge) |
| 4 | Description | varchar(200) | YES | Human-readable description from Apex SOD869 (e.g., 'MM Purchase', 'ACH DISBURSEMENT', 'TFR CASH TO MARGIN', 'HWM COVER', 'WIRE TRANSFER', 'MAR PAPER STATEMENT FEE'). Free-text; may include instrument names with leading asterisks for foreign ADR instruments. (Tier 2 — SP_US_Apex_Fees_Charge) |
| 5 | CurrencyCode | varchar(10) | YES | Currency of the Amount. Always 'USD' in practice (100% of 209,246 rows). (Tier 2 — SP_US_Apex_Fees_Charge) |
| 6 | ProcessDate | date | YES | Apex SOD869 file processing date — the date this event was recorded in the Apex file. Equals @Date parameter. Clustered index column — always filter on ProcessDate for best performance. (Tier 2 — SP_US_Apex_Fees_Charge) |
| 7 | BatchCode | varchar(40) | YES | Apex batch processing reference ID from the SOD869 file. Identifies the batch run that produced this record. Metadata field; not used in standard analytical queries. (Tier 2 — SP_US_Apex_Fees_Charge) |
| 8 | Cusip | varchar(40) | YES | CUSIP security identifier for the underlying instrument. NULL for ~30% of rows (62,777) where the event is not security-linked (MM purchases, wire transfers, ACH disbursements). Populated for ADR-related events (Z$ADR, ACJRL TerminalIDs). (Tier 2 — SP_US_Apex_Fees_Charge) |
| 9 | SourceProgram | varchar(40) | YES | Apex system program that generated this record in the SOD869 file. Identifies the Apex sub-system of origin. Metadata field. (Tier 2 — SP_US_Apex_Fees_Charge) |
| 10 | EnteredBy | varchar(40) | YES | Apex system user or automated process that entered the record. Populated for 99.98% of rows; 41 NULLs total (negligible). Metadata field. (Tier 2 — SP_US_Apex_Fees_Charge) |
| 11 | EntryTypeCode | varchar(40) | YES | Apex entry type classification from SOD869. Values: MD (money movement debit, 62.8%), CJ (cash journal, 37.1%), small counts of BG, CD, DI, LP, CR, SM, CP, ID. Determines the accounting classification of the event. (Tier 2 — SP_US_Apex_Fees_Charge) |
| 12 | PayTypeCode | varchar(40) | YES | Apex payment type code. Values: D (debit, 99.99%) and C (credit, 0.01% — 9 rows). Nearly always 'D'. (Tier 2 — SP_US_Apex_Fees_Charge) |
| 13 | TerminalID | varchar(40) | YES | Apex transaction type code — the primary categorization field. Key values: FDFND (MM Purchase, 61.3%), MGJRL (MSB HWM/management, 7.4%), SMFEE (paper statement fee, 6.1%), COFEE (paper confirmation, 5.3%), 9DACH (ACH disbursement, 4.4%), Z$ADR (ADR fee, 3.4%), 2TTFR (margin transfer, 3.4%), FWWRD (wire transfer, customers only), ACJRL, L1RET (reverse ACH), MGFEE, F7FND, 1TTFR, others. Dividend/CA TerminalIDs ($+DIV, DVDIV, etc.) are explicitly excluded by the SP. (Tier 2 — SP_US_Apex_Fees_Charge) |
| 14 | Account | varchar(40) | YES | ETL-derived account category. Hardcoded by SP branch logic: 'Customers' (96.3%, individual US client accounts) or 'MSB' (3.7%, eToro MSB omnibus account 3ET05007). Not a column in the Apex SOD869 source — assigned during ETL. (Tier 2 — SP_US_Apex_Fees_Charge) |
| 15 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last written by the ETL pipeline. Set to GETDATE() at SP execution time. (Tier 2 — SP_US_Apex_Fees_Charge) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|--------------|-----------|
| AccountNumber | External_Sodreconciliation_apex_EXT869_CashActivity | AccountNumber | Passthrough |
| AccountType | External_Sodreconciliation_apex_EXT869_CashActivity | AccountType | Passthrough |
| Amount | External_Sodreconciliation_apex_EXT869_CashActivity | Amount | Passthrough (no sign flip) |
| Description | External_Sodreconciliation_apex_EXT869_CashActivity | Description | Passthrough |
| CurrencyCode | External_Sodreconciliation_apex_EXT869_CashActivity | CurrencyCode | Passthrough |
| ProcessDate | External_Sodreconciliation_apex_EXT869_CashActivity | ProcessDate | Passthrough |
| BatchCode | External_Sodreconciliation_apex_EXT869_CashActivity | BatchCode | Passthrough |
| Cusip | External_Sodreconciliation_apex_EXT869_CashActivity | Cusip | Passthrough |
| SourceProgram | External_Sodreconciliation_apex_EXT869_CashActivity | SourceProgram | Passthrough |
| EnteredBy | External_Sodreconciliation_apex_EXT869_CashActivity | EnteredBy | Passthrough |
| EntryTypeCode | External_Sodreconciliation_apex_EXT869_CashActivity | EntryTypeCode | Passthrough |
| PayTypeCode | External_Sodreconciliation_apex_EXT869_CashActivity | PayTypeCode | Passthrough |
| TerminalID | External_Sodreconciliation_apex_EXT869_CashActivity | TerminalID | Passthrough |
| Account | — | — | ETL-derived: 'MSB' or 'Customers' based on SP branch |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
Apex SOD869 file (BI_DB_dbo.External_Sodreconciliation_apex_EXT869_CashActivity)
  + DWH_dbo.Sodreconciliation_apex_SodFiles  (most recent valid file for @Date, Status=2)
  |
  |-- #MSBfee: AccountNumber='3ET05007', TerminalID NOT IN(OMJNL, FWWRD)
  |-- #customersfee: AccountType IN('1','2'), Amount>0, NOT IN reserve accounts,
  |                  TerminalID NOT IN dividend/CA exclusion list (14 codes)
  |-- UNION #MSBfee + #customersfee → #final
    |-- SP_US_Apex_Fees_Charge @Date (Daily, step 04) ---|
    |   DELETE WHERE ProcessDate=@Date + INSERT
    v
BI_DB_dbo.BI_DB_US_Apex_Fees_Charge
  (209,246 rows, Oct 2021 – Apr 2026, ROUND_ROBIN, CLUSTERED(ProcessDate))
  (UC: Not Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AccountNumber | BI_DB_dbo.External_USABroker_Apex_ApexData | Indirect: AccountNumber→ApexID→CID for customer identification |

### 6.2 Referenced By

| Object | Reference Column | Description |
|--------|-----------------|-------------|
| BI_DB_dbo.BI_DB_US_Apex_Corporate_CA_Apex | AccountNumber / ProcessDate | Complement: CA_Apex has dividend events; this table has all other fee/transfer events from the same SOD869 source |

---

## 7. Sample Queries

### Daily Fee Summary by TerminalID

```sql
SELECT
    TerminalID,
    Account,
    COUNT(*) AS event_count,
    SUM(Amount) AS total_amount,
    AVG(Amount) AS avg_amount
FROM [BI_DB_dbo].[BI_DB_US_Apex_Fees_Charge]
WHERE ProcessDate = '2026-04-10'
GROUP BY TerminalID, Account
ORDER BY total_amount DESC;
```

### Paper Statement Fees by Month (2026)

```sql
SELECT
    YEAR(ProcessDate) AS yr,
    MONTH(ProcessDate) AS mo,
    COUNT(*) AS fee_count,
    SUM(Amount) AS total_fees
FROM [BI_DB_dbo].[BI_DB_US_Apex_Fees_Charge]
WHERE TerminalID = 'SMFEE'
  AND ProcessDate >= '2026-01-01'
GROUP BY YEAR(ProcessDate), MONTH(ProcessDate)
ORDER BY yr DESC, mo DESC;
```

### MSB Account Monthly Charges

```sql
SELECT
    YEAR(ProcessDate) AS yr,
    MONTH(ProcessDate) AS mo,
    TerminalID,
    Description,
    COUNT(*) AS event_count,
    SUM(Amount) AS net_amount
FROM [BI_DB_dbo].[BI_DB_US_Apex_Fees_Charge]
WHERE Account = 'MSB'
  AND ProcessDate >= '2026-01-01'
GROUP BY YEAR(ProcessDate), MONTH(ProcessDate), TerminalID, Description
ORDER BY yr DESC, mo DESC, net_amount DESC;
```

### All Non-CA Activity for a Specific Account

```sql
SELECT
    ProcessDate,
    AccountNumber,
    TerminalID,
    Description,
    Amount,
    Account
FROM [BI_DB_dbo].[BI_DB_US_Apex_Fees_Charge]
WHERE AccountNumber = '3ET05007'
  AND ProcessDate >= '2026-01-01'
ORDER BY ProcessDate DESC, Amount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources found. Author: Artyom Bogomolsky (2021-11-11). Description: "This sp is used to fees charging from Clients and MSB account." Expanded 2022-03-21 to AccountType 1 and 2.

---

*Generated: 2026-04-22 | Quality: 8.6/10 | Phases: 10/14*
*Tiers: 0 T1, 15 T2, 0 T3, 0 T4 | Elements: 15/15, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_US_Apex_Fees_Charge | Type: Table | Production Source: External_Sodreconciliation_apex_EXT869_CashActivity via SP_US_Apex_Fees_Charge*
