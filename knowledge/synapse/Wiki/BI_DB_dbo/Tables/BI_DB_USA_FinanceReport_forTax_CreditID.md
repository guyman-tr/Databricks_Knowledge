# BI_DB_dbo.BI_DB_USA_FinanceReport_forTax_CreditID

> 450K-row daily credit-level detail table for US tax reporting, capturing individual compensation credit entries (CreditTypeID=6) for eToroUS (RegulationID=6) and FinCEN (RegulationID=7) regulated customers from 2019-03-05 to present. Companion to BI_DB_USA_FinanceReport_forTax (customer-level daily summary). Includes SSN (PII), credit category, and money movement reason. DELETE+INSERT by DateID via SP_USA_FinanceReport_forTax.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.History.Credit (CreditTypeID=6) + Dim_CreditType + Dim_CompensationReason + Dictionary.MoveMoneyReason + UserApiDB.Customer.ExtendedUserField via `SP_USA_FinanceReport_forTax` |
| **Refresh** | Daily (DELETE WHERE DateID=@DateID + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | — |
| **Row Count** | ~449,556 (as of 2026-04-27) |

---

## 1. Business Meaning

`BI_DB_USA_FinanceReport_forTax_CreditID` is a daily credit-level detail table supporting IRS tax reporting for US-regulated eToro customers. While its sibling table `BI_DB_USA_FinanceReport_forTax` provides a customer-level daily summary (compensation totals, closed positions, PnL), this table captures individual credit transactions from the History.Credit ledger.

Each row represents a single compensation credit entry (CreditTypeID=6 from History.Credit) for a US-regulated customer. The table provides:

- **Credit identity**: CreditID, CreditTypeName (always "Compensation" due to CreditTypeID=6 filter)
- **Financial details**: Amount (original Payment value), Category (from Dim_CompensationReason — 39 reason codes), Reason (from Dictionary.MoveMoneyReason — Adjustment, Staking, Airdrop, Bonus Abuser)
- **PII**: SSN/TIN from UserApiDB.Customer.ExtendedUserField (FieldId=6, CountryId=219)
- **Audit trail**: Note (original Description from History.Credit), Time (Occurred timestamp)

The SP first builds the US customer population (Dim_Customer WHERE RegulationID IN (6,7) AND IsValidCustomer=1), creates a dynamic external table for History.Credit via SP_Create_External_etoro_History_Credit, filters to CreditTypeID=6, then enriches with dimension lookups and SSN. Load pattern: DELETE WHERE DateID=@DateID + INSERT. The SP is shared with the sibling summary table — it writes to both tables in a single execution.

Top compensation categories: Position Airdrop (40%), Staking (38%), Special Promotion (5%), RAF Invited/Inviting Friend (8%), Deposit Adjustment (3%). The Reason column is 86% empty, with "Adjustment" (11%) and "Staking" (3%) as the only significant values.

---

## 2. Business Logic

### 2.1 US Customer Population Filter

**What**: Identifies eToroUS and FinCEN regulated customers eligible for US tax reporting.
**Columns Involved**: `CID`
**Rules**:
- #US: Dim_Customer WHERE RegulationID IN (6, 7) AND IsValidCustomer=1
- CID is matched against this US population via #US_comp_CID
- Only compensation CIDs (from existing report rows UNION new ActionTypeID=36 CIDs) are included

### 2.2 Credit Entry Extraction

**What**: Pulls individual credit entries from the History.Credit production ledger.
**Columns Involved**: `CreditID`, `Credit`, `Amount`, `Category`, `Reason`, `Time`, `Note`
**Rules**:
- Source: External_etoro_History_Credit_Yesterday (dynamic external table created by SP_Create_External_etoro_History_Credit)
- Filter: CreditTypeID=6 (Compensation only) AND Occurred >= @Date
- CreditID → unique credit transaction ID
- Amount ← Payment (renamed)
- Time ← Occurred (renamed)
- Note ← Description (renamed)

### 2.3 Dimension Lookups

**What**: Enriches credit entries with human-readable names from three dimension/dictionary tables.
**Columns Involved**: `Credit`, `Category`, `Reason`
**Rules**:
- Credit ← Dim_CreditType.CreditTypeName via CreditTypeID JOIN (always "Compensation" due to CreditTypeID=6 filter)
- Category ← Dim_CompensationReason.Name via CompensationReasonID JOIN (39 distinct values)
- Reason ← Dictionary.MoveMoneyReason via MoveMoneyReasonID JOIN (5 values: Adjustment, Staking, Airdrop, Bonus Abuser, plus empty)

### 2.4 SSN/TIN Retrieval

**What**: Social Security Number or Tax Identification Number for IRS reporting.
**Columns Involved**: `SSN`
**Rules**:
- From External_UserApiDB_Customer_ExtendedUserField WHERE FieldId=6 AND CountryId=219
- Joined via GCID from Dim_Customer
- PII field — 99.1% populated (4,228 rows without SSN)

### 2.5 Date Computation

**What**: DateID derived from the credit entry timestamp.
**Columns Involved**: `DateID`
**Rules**:
- DateID = CAST(CONVERT(VARCHAR(8), [Time], 112) AS INT) — YYYYMMDD integer from Occurred timestamp
- Clustered index key — queries by date range are efficient

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on DateID — efficient for date-range scans. No distribution key skew.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All credits for a customer | `WHERE CID = X ORDER BY Time DESC` |
| Credits on a specific date | `WHERE DateID = 20260401` |
| Top compensation categories | `SELECT Category, SUM(Amount) GROUP BY Category ORDER BY SUM(Amount) DESC` |
| Staking rewards total | `WHERE Category = 'Staking'` |
| Credits with SSN | `WHERE SSN IS NOT NULL AND SSN <> ''` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_USA_FinanceReport_forTax | `CID = RealCID AND DateID = DateID` | Customer-level summary alongside credit details |
| DWH_dbo.Dim_Customer | `CID = RealCID` | Full customer demographics |

### 3.4 Gotchas

- **PII table**: SSN column contains Social Security Numbers — handle with appropriate access controls
- **Credit column is char(50)**: Always "Compensation" with trailing spaces. Use `RTRIM(Credit)` when comparing or displaying
- **Reason is 86% empty**: Most credits have no MoveMoneyReason assigned (NULL/empty in source Dictionary.MoveMoneyReason)
- **DateID is bigint YYYYMMDD**: Not a date type — join with date dimensions carefully
- **Shared SP**: SP_USA_FinanceReport_forTax writes to BOTH this table AND BI_DB_USA_FinanceReport_forTax in a single execution
- **CID vs RealCID**: This table uses `CID` (from History.Credit) which maps to `RealCID` in Dim_Customer. The SP joins on `c.CID = f.RealCID`
- **Amount can be zero or negative**: Foreclosure entries have Amount=0; Transferred Out entries can be negative

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
| 1 | CID | int | NO | Customer ID from History.Credit. Maps to Dim_Customer.RealCID. Only eToroUS (RegulationID=6) and FinCEN (RegulationID=7) customers are included. (Tier 2 — SP_USA_FinanceReport_forTax) |
| 2 | CreditID | bigint | YES | Unique identifier for the credit entry from History.Credit. Links back to the individual credit transaction in the production accounting system. (Tier 2 — SP_USA_FinanceReport_forTax) |
| 3 | Credit | char(50) | YES | Human-readable operation name. Unique constraint ensures no duplicate names. Used in financial reports, transaction history, and reconciliation tools. Note: char(50) with trailing spaces — always RTRIM when displaying. DWH note: always "Compensation" in this table due to CreditTypeID=6 filter. Passthrough from Dim_CreditType. (Tier 1 — Dictionary.CreditType) |
| 4 | Amount | money | NO | Compensation payment amount from History.Credit.Payment (renamed Payment → Amount). Can be positive (credits), zero (foreclosures), or negative (transferred out, chargebacks). (Tier 2 — SP_USA_FinanceReport_forTax) |
| 5 | Category | varchar(100) | YES | Human-readable reason label used in BackOffice UI and reports. E.g., "Satisfaction Bonus", "Cash Dividend", "Dormant Fee". Passed through unchanged from production. Passthrough from Dim_CompensationReason. 39 distinct values; top: Position Airdrop, Staking, Special Promotion. (Tier 1 — BackOffice.CompensationReason) |
| 6 | Reason | varchar(30) | YES | Human-readable reason label for money movement classification. Note: column name matches table name (denormalized pattern). Displayed in account statements, credit history, and BackOffice audit screens. Passthrough from Dictionary.MoveMoneyReason. 86% empty; significant values: Adjustment, Staking, Airdrop. (Tier 1 — Dictionary.MoveMoneyReason) |
| 7 | Time | datetime | NO | Timestamp when the credit entry occurred. From History.Credit.Occurred (renamed Occurred → Time). Represents the actual credit event time in production. (Tier 2 — SP_USA_FinanceReport_forTax) |
| 8 | Note | varchar(255) | YES | Free-text description from History.Credit.Description (renamed Description → Note). Contains operational details such as wire transfer references, deposit IDs, or tax reporting identifiers (e.g., "CT & PA Early Spring 2026 AP Sovos"). 99.8% populated. (Tier 2 — SP_USA_FinanceReport_forTax) |
| 9 | SSN | nvarchar(128) | YES | Social Security Number or Tax Identification Number for IRS reporting. From External_UserApiDB_Customer_ExtendedUserField WHERE FieldId=6 AND CountryId=219. PII field — 99.1% populated. Joined via GCID from Dim_Customer. (Tier 2 — SP_USA_FinanceReport_forTax) |
| 10 | DateID | bigint | YES | Reporting date in YYYYMMDD integer format. Computed from Time: CAST(CONVERT(VARCHAR(8),[Time],112) AS INT). Clustered index key. Used for DELETE+INSERT partitioning on daily loads. (Tier 2 — SP_USA_FinanceReport_forTax) |
| 11 | UpdateDate | datetime | NO | ETL execution timestamp. GETDATE() at SP execution time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | etoro.History.Credit | CID | Passthrough (filtered to US CIDs) |
| CreditID | etoro.History.Credit | CreditID | Passthrough |
| Credit | etoro.Dictionary.CreditType | CreditTypeName | Dim-lookup via CreditTypeID (always "Compensation") |
| Amount | etoro.History.Credit | Payment | Rename (Payment → Amount) |
| Category | etoro.BackOffice.CompensationReason | Name | Dim-lookup via CompensationReasonID |
| Reason | etoro.Dictionary.MoveMoneyReason | MoveMoneyReason | Lookup via MoveMoneyReasonID |
| Time | etoro.History.Credit | Occurred | Rename (Occurred → Time) |
| Note | etoro.History.Credit | Description | Rename (Description → Note) |
| SSN | UserApiDB.Customer.ExtendedUserField | Value | Lookup (FieldId=6, CountryId=219) |
| DateID | — | — | ETL-computed from Time |
| UpdateDate | — | — | ETL-computed (GETDATE()) |

### 5.2 ETL Pipeline

```
etoro.History.Credit (production, CreditTypeID=6 compensation entries)
  |-- SP_Create_External_etoro_History_Credit @Date, 'Yesterday' ---|
  v
BI_DB_dbo.External_etoro_History_Credit_Yesterday (dynamic external table)
  |
  + etoro.Dictionary.MoveMoneyReason (external) → Reason
  + DWH_dbo.Dim_CreditType (CreditTypeID JOIN) → Credit name
  + DWH_dbo.Dim_CompensationReason (CompensationReasonID JOIN) → Category
  + UserApiDB.Customer.ExtendedUserField (external, FieldId=6) → SSN
  + DWH_dbo.Dim_Customer (RegulationID IN (6,7)) → US population filter
  |
  |-- SP_USA_FinanceReport_forTax @Date ---|
  |-- DELETE WHERE DateID=@DateID + INSERT ---|
  v
BI_DB_dbo.BI_DB_USA_FinanceReport_forTax_CreditID (~450K rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | US-regulated customer identifier |
| CreditID | etoro.History.Credit.CreditID | Production credit ledger entry |
| Credit | DWH_dbo.Dim_CreditType.CreditTypeName | Credit type classification (always "Compensation") |
| Category | DWH_dbo.Dim_CompensationReason.Name | Compensation reason classification |
| Reason | etoro.Dictionary.MoveMoneyReason.MoveMoneyReason | Money movement reason |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| BI_DB_dbo.BI_DB_USA_FinanceReport_forTax | Sibling table | Written by same SP — customer-level daily summary vs. this credit-level detail |

---

## 7. Sample Queries

### 7.1 Daily Credit Summary by Category

```sql
SELECT
    DateID,
    Category,
    COUNT(*) AS credit_count,
    SUM(Amount) AS total_amount,
    AVG(Amount) AS avg_amount
FROM [BI_DB_dbo].[BI_DB_USA_FinanceReport_forTax_CreditID]
WHERE DateID >= 20260401
GROUP BY DateID, Category
ORDER BY DateID DESC, total_amount DESC
```

### 7.2 Customer Credit Details with Demographics

```sql
SELECT
    c.CID,
    dc.FirstName,
    dc.LastName,
    c.Category,
    c.Amount,
    c.Note,
    c.Time
FROM [BI_DB_dbo].[BI_DB_USA_FinanceReport_forTax_CreditID] c
JOIN [DWH_dbo].[Dim_Customer] dc ON c.CID = dc.RealCID
WHERE c.DateID = 20260410
ORDER BY c.Amount DESC
```

### 7.3 Large Compensation Entries (Audit)

```sql
SELECT
    CID,
    CreditID,
    Amount,
    Category,
    Reason,
    RTRIM(Credit) AS CreditType,
    Note,
    Time
FROM [BI_DB_dbo].[BI_DB_USA_FinanceReport_forTax_CreditID]
WHERE ABS(Amount) > 10000
ORDER BY Time DESC
```

---

## 8. Atlassian Knowledge Sources

No relevant Confluence or Jira sources found for this table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 3 T1, 7 T2, 0 T3, 0 T4, 1 T5 | Elements: 11/11, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_USA_FinanceReport_forTax_CreditID | Type: Table | Production Source: etoro.History.Credit via SP_USA_FinanceReport_forTax*
