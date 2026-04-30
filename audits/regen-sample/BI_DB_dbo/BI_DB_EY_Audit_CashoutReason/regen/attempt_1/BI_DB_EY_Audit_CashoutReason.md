# BI_DB_dbo.BI_DB_EY_Audit_CashoutReason

> 7.6M-row EY audit denormalization table capturing every processed withdrawal with its cashout reason, customer attributes (country, club tier, guru status, account type), and funding method — enriched at point-in-time via Fact_SnapshotCustomer. Covers 2023-01-01 to present, refreshed daily via DELETE+INSERT by SP_EY_Audit_Automation_CashoutReason with automatic backfill for missed dates.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_BillingWithdraw + Dim_CashoutReason + Fact_SnapshotCustomer + Dim_Country + Dim_PlayerLevel + Dim_GuruStatus + Dim_AccountType + Dim_FundingType + Dim_Customer via SP_EY_Audit_Automation_CashoutReason |
| **Key Identifier** | WithdrawID + WithdrawPaymentID (composite, no enforced PK) |
| **Refresh** | Daily (DELETE+INSERT by date, with auto-backfill for gaps) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |

---

## 1. Business Meaning

`BI_DB_EY_Audit_CashoutReason` is a pre-built audit denormalization table supporting EY (Ernst & Young) external audit requirements for withdrawal/cashout reason analysis. Each row represents a single withdrawal payment execution (WithdrawToFunding leg) enriched with the customer's point-in-time attributes at the time of the withdrawal.

The table joins `Fact_BillingWithdraw` to `Fact_SnapshotCustomer` using `Dim_Range` to capture the customer's state (country, eToro Club tier, Popular Investor status, account type) as of the withdrawal's modification date — not the customer's current state. This point-in-time join is critical for audit accuracy.

The SP (`SP_EY_Audit_Automation_CashoutReason`) runs daily for the previous day's data. It includes an automatic gap-detection mechanism: if any dates are missing between the last loaded date and the requested date, it recursively calls itself to backfill each missing day before processing the requested date.

As of 2025-10-27: **7.6M rows**, date range **2023-01-01 to 2025-10-27**. Dominant cashout reason: "Requested by User" (~95% of 2025 rows). Dominant account type: Private (~99.7%).

---

## 2. Business Logic

### 2.1 Point-in-Time Customer State via Dim_Range

**What**: Customer attributes are captured as of the withdrawal date, not the customer's current state.

**Columns Involved**: `Country`, `Club`, `GuruStatusName`, `AccountType`, `ExternalID`

**Rules**:
- The SP joins `Fact_SnapshotCustomer fsc` to `Fact_BillingWithdraw effbw` on `fsc.RealCID = effbw.CID`
- The temporal filter uses `Dim_Range`: `fsc.DateRangeID = dr.DateRangeID AND effbw.ModificationDateID BETWEEN dr.FromDateID AND dr.ToDateID`
- This ensures the customer snapshot row active at the time of the withdrawal modification is used
- Customer-facing columns (Country, Club, GuruStatusName, AccountType) reflect the customer's state at withdrawal time, not their current state

### 2.2 ModificationDate_WithdrawToFunding_DateID Computation

**What**: Integer date key derived from the WithdrawToFunding execution timestamp.

**Columns Involved**: `ModificationDate_WithdrawToFunding_DateID`

**Rules**:
- Computed inline in the SP: `CAST(CONVERT(VARCHAR(10), CAST(effbw.ModificationDate_WithdrawToFunding AS DATE), 112) AS INT)`
- Format: YYYYMMDD integer (e.g., 20250101)
- This is the partition/filter key for the DELETE+INSERT ETL pattern
- Note: Fact_BillingWithdraw already has a `ModificationDateID` column (based on ModificationDate from Billing.Withdraw), but this SP computes a separate date key from `ModificationDate_WithdrawToFunding` (the payment execution leg timestamp)

### 2.3 Automatic Gap Backfill

**What**: The SP detects and fills missing dates before processing the requested date.

**Columns Involved**: `ModificationDate_WithdrawToFunding_DateID`

**Rules**:
- On each run, the SP checks `MAX(ModificationDate_WithdrawToFunding_DateID)` against the requested `@Date`
- If the max loaded date is earlier than the target date, it loops day-by-day from `MAX + 1` to `@Date - 1`, recursively calling itself for each missing date
- This prevents audit gaps caused by missed daily runs or pipeline outages

### 2.4 DELETE+INSERT ETL Pattern

**What**: Daily idempotent reload by date.

**Rules**:
- `DELETE FROM BI_DB_EY_Audit_CashoutReason WHERE ModificationDate_WithdrawToFunding_DateID = @DateID`
- Then `INSERT` all qualifying rows for that date from the temp table
- Re-running the SP for the same date produces identical results (idempotent)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP index. No clustered index or distribution key — queries must scan all distributions. For large date ranges, always filter on `ModificationDate_WithdrawToFunding_DateID` to limit scan scope.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Withdrawals by cashout reason for a date range | `WHERE ModificationDate_WithdrawToFunding_DateID BETWEEN @from AND @to GROUP BY CashoutReason` |
| Country-level cashout breakdown | `GROUP BY Country, CashoutReason` with date filter |
| Audit trail for a specific withdrawal | `WHERE WithdrawID = @id` |
| Popular Investor withdrawals | `WHERE GuruStatusName <> 'No'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_BillingWithdraw | ON WithdrawID | Full withdrawal details (amounts, fees, status) |
| DWH_dbo.Dim_CashoutReason | ON CashoutReasonID | Additional reason metadata |

### 3.4 Gotchas

- **Point-in-time, not current state**: Country, Club, GuruStatusName, and AccountType reflect the customer's attributes at withdrawal time. Do not assume they match the customer's current attributes in Dim_Customer.
- **ROUND_ROBIN + HEAP**: No distribution key or index. Full table scans are expensive at 7.6M rows — always filter by `ModificationDate_WithdrawToFunding_DateID`.
- **ExternalID is varchar(200) here**: In Dim_Customer it is `decimal(38,0)`. The SP selects it without explicit CAST, so implicit conversion to varchar occurs. Some ExternalID values are 20-digit numeric strings.
- **FundingType is from FundingTypeID_Funding**: The SP joins `Dim_FundingType ON dft.FundingTypeID = effbw.FundingTypeID_Funding` — this is the funding instrument's payment method, not the withdrawal request's payment method (FundingTypeID_Withdraw).
- **No NULL rows expected**: All JOINs except Dim_GuruStatus and Dim_FundingType are INNER JOINs. GuruStatusName and FundingType may be NULL if the LEFT JOIN finds no match.
- **UpdateDate is ETL run date**: Reflects when the SP ran, not the withdrawal date. Typically one day after ModificationDate_WithdrawToFunding_DateID.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 — upstream wiki verbatim | `(Tier 1 — {source})` |
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — {source})` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | WithdrawID | bigint | YES | Withdrawal request identifier. Primary key, IDENTITY starting at 1. HASH distribution key and clustered index column. Passthrough from Fact_BillingWithdraw. (Tier 1 — Billing.Withdraw) |
| 2 | CID | int | YES | Customer ID. FK to Customer.CustomerStatic. Passthrough from Fact_BillingWithdraw. (Tier 1 — Billing.Withdraw) |
| 3 | WithdrawPaymentID | bigint | YES | Surrogate primary key of the WithdrawToFunding execution leg. Renamed from ID. Passthrough from Fact_BillingWithdraw. (Tier 1 — Billing.WithdrawToFunding) |
| 4 | ModificationDate_WithdrawToFunding_DateID | int | YES | Integer date key (YYYYMMDD) derived from Fact_BillingWithdraw.ModificationDate_WithdrawToFunding via CAST(CONVERT(VARCHAR(10), CAST(date, 112) AS INT). Used as the DELETE+INSERT partition key and the Dim_Range temporal join filter. (Tier 2 — Fact_BillingWithdraw) |
| 5 | CashoutReasonID | int | YES | Internal reason code for the withdrawal decision (e.g., why cancelled or flagged). FK to Dim_CashoutReason. Passthrough from Fact_BillingWithdraw. (Tier 1 — Billing.Withdraw) |
| 6 | CashoutReason | varchar(200) | YES | Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history. Dim-lookup passthrough from Dim_CashoutReason.Name. (Tier 1 — Dictionary.CashoutReason) |
| 7 | Country | varchar(200) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via Fact_SnapshotCustomer.CountryID at point-in-time. (Tier 1 — Dictionary.Country) |
| 8 | Club | varchar(200) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup passthrough from Dim_PlayerLevel.Name via Fact_SnapshotCustomer.PlayerLevelID at point-in-time. (Tier 1 — Dictionary.PlayerLevel) |
| 9 | GuruStatusName | varchar(200) | YES | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Dim-lookup passthrough from Dim_GuruStatus.GuruStatusName via Fact_SnapshotCustomer.GuruStatusID at point-in-time. (Tier 1 — Dictionary.GuruStatus) |
| 10 | AccountType | varchar(200) | YES | Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification. Dim-lookup passthrough from Dim_AccountType.Name via Fact_SnapshotCustomer.AccountTypeID at point-in-time. (Tier 1 — Dictionary.AccountType) |
| 11 | ExternalID | varchar(200) | YES | APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. Passthrough from Dim_Customer.ExternalID (joined via Fact_SnapshotCustomer.RealCID). Stored as varchar(200) in this table. (Tier 1 — Customer.CustomerStatic) |
| 12 | FundingType | varchar(200) | YES | Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Dim-lookup passthrough from Dim_FundingType.Name via Fact_BillingWithdraw.FundingTypeID_Funding. (Tier 1 — Dictionary.FundingType) |
| 13 | UpdateDate | date | YES | ETL run timestamp set to GETDATE() when SP_EY_Audit_Automation_CashoutReason executes. Reflects the SP execution date, not the withdrawal modification date. (Tier 2 — SP_EY_Audit_Automation_CashoutReason) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| WithdrawID | Fact_BillingWithdraw | WithdrawID | Passthrough |
| CID | Fact_BillingWithdraw | CID | Passthrough |
| WithdrawPaymentID | Fact_BillingWithdraw | WithdrawPaymentID | Passthrough |
| ModificationDate_WithdrawToFunding_DateID | Fact_BillingWithdraw | ModificationDate_WithdrawToFunding | CAST(CONVERT(VARCHAR(10), CAST(date, 112) AS INT) |
| CashoutReasonID | Fact_BillingWithdraw | CashoutReasonID | Passthrough |
| CashoutReason | Dim_CashoutReason | Name | Rename (Name → CashoutReason) |
| Country | Dim_Country | Name | Rename (Name → Country) via FSC.CountryID |
| Club | Dim_PlayerLevel | Name | Rename (Name → Club) via FSC.PlayerLevelID |
| GuruStatusName | Dim_GuruStatus | GuruStatusName | Passthrough via FSC.GuruStatusID |
| AccountType | Dim_AccountType | Name | Rename (Name → AccountType) via FSC.AccountTypeID |
| ExternalID | Dim_Customer | ExternalID | Passthrough (implicit decimal→varchar) |
| FundingType | Dim_FundingType | Name | Rename (Name → FundingType) via FBW.FundingTypeID_Funding |
| UpdateDate | — | — | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_BillingWithdraw (primary withdrawal fact)
  |-- JOIN DWH_dbo.Dim_CashoutReason ON CashoutReasonID
  |-- JOIN DWH_dbo.Fact_SnapshotCustomer ON RealCID = CID
  |       |-- JOIN DWH_dbo.Dim_Range ON DateRangeID (temporal filter)
  |       |-- JOIN DWH_dbo.Dim_Country ON CountryID
  |       |-- JOIN DWH_dbo.Dim_PlayerLevel ON PlayerLevelID
  |       |-- LEFT JOIN DWH_dbo.Dim_GuruStatus ON GuruStatusID
  |       |-- JOIN DWH_dbo.Dim_AccountType ON AccountTypeID
  |-- LEFT JOIN DWH_dbo.Dim_FundingType ON FundingTypeID_Funding
  |-- JOIN DWH_dbo.Dim_Customer ON RealCID
  v
#cashoutreasons (temp table, HEAP, ROUND_ROBIN)
  |-- DELETE existing rows for @DateID
  |-- INSERT into BI_DB_EY_Audit_CashoutReason + GETDATE() AS UpdateDate
  v
BI_DB_dbo.BI_DB_EY_Audit_CashoutReason (7.6M rows; daily DELETE+INSERT by date)
```

| Step | Object | Description |
|------|--------|-------------|
| Gap Check | SP_EY_Audit_Automation_CashoutReason | Detects missing dates, recursively backfills gaps |
| Source Query | #cashoutreasons temp table | 10-way JOIN: FBW + DCR + FSC + DR + DC + DPL + DGS + DAT + DFT + DC1 |
| Delete | BI_DB_EY_Audit_CashoutReason | DELETE WHERE ModificationDate_WithdrawToFunding_DateID = @DateID |
| Insert | BI_DB_EY_Audit_CashoutReason | INSERT from #cashoutreasons with GETDATE() |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| WithdrawID | DWH_dbo.Fact_BillingWithdraw | Withdrawal fact table |
| CID | DWH_dbo.Dim_Customer | Customer dimension (via RealCID) |
| CashoutReasonID | DWH_dbo.Dim_CashoutReason | Cashout reason lookup |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers. This is a terminal audit/reporting table.

---

## 7. Sample Queries

### 7.1 Cashout reason breakdown for a date range

```sql
SELECT CashoutReason,
       COUNT(*) AS WithdrawalCount
FROM   BI_DB_dbo.BI_DB_EY_Audit_CashoutReason
WHERE  ModificationDate_WithdrawToFunding_DateID BETWEEN 20250101 AND 20250331
GROUP BY CashoutReason
ORDER BY WithdrawalCount DESC;
```

### 7.2 Country-level audit for user-requested cashouts

```sql
SELECT Country,
       Club,
       COUNT(*) AS WithdrawalCount
FROM   BI_DB_dbo.BI_DB_EY_Audit_CashoutReason
WHERE  CashoutReason = 'Requested by User'
  AND  ModificationDate_WithdrawToFunding_DateID BETWEEN 20250101 AND 20250331
GROUP BY Country, Club
ORDER BY WithdrawalCount DESC;
```

### 7.3 Popular Investor withdrawals by funding type

```sql
SELECT GuruStatusName,
       FundingType,
       COUNT(*) AS WithdrawalCount
FROM   BI_DB_dbo.BI_DB_EY_Audit_CashoutReason
WHERE  GuruStatusName <> 'No'
  AND  ModificationDate_WithdrawToFunding_DateID >= 20250101
GROUP BY GuruStatusName, FundingType
ORDER BY WithdrawalCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business context derived from SP code analysis (Author: Adi Meidan, 2023-06-14; modified by Guy M, 2024-07-03 for missing date backfill).

---

*Generated: 2026-04-29 | Quality: 9.0/10*
*Tiers: 11 T1, 2 T2, 0 T3, 0 T4 | Phases: 1,2,3,4,5,6,8,9,9B,10A,10B,11*
*Object: BI_DB_dbo.BI_DB_EY_Audit_CashoutReason | Type: Table | Production Source: DWH_dbo.Fact_BillingWithdraw + 9 dimension/fact tables via SP_EY_Audit_Automation_CashoutReason*
