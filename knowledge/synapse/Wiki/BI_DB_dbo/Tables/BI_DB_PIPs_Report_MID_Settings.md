# BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings

> 15.8M-row daily MID (Merchant ID) routing lookup table that resolves the correct **MIDName** (eToro legal entity) and **MID** (payment processor endpoint identifier) for every deposit and withdrawal transaction processed on a given date. Populated daily by **SP_PIPs_Report_MID_Settings**, which replicates production back-office MID routing logic in the DWH to supplement the **BI_DB_DepositWithdrawFee** report in Tableau. Data spans 2024-01-01 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 7 |
| **Production Source** | Computed in DWH — SP_PIPs_Report_MID_Settings replicates production Billing/BackOffice MID routing functions |
| **Refresh** | Daily (part of FinanceReportSPS package) |
| **ETL Pattern** | DELETE by Date, INSERT from UNION of deposit + withdraw MID resolutions |
| **Parameter** | @date (DATE) |
| **Distribution** | HASH(TransactionID) |
| **Clustered Index** | CLUSTERED INDEX (Date ASC) |

---

## 1. Business Meaning

`BI_DB_PIPs_Report_MID_Settings` is a daily metadata lookup table that resolves the **Merchant ID (MID)** and **legal entity name (MIDName)** for every deposit and withdrawal transaction. It exists because the production MID routing logic (implemented in `Billing.GetMerchantDetailsForOneAccountByDepotOnly`, `BackOffice.GetMerchantDetails`, and `BackOffice.CalculateDepositPIPsUSD`) relies on complex UDF-based lookups that cannot run directly in Synapse (Synapse does not support SELECT statements within UDFs). Instead, `SP_PIPs_Report_MID_Settings` translates these production functions into temp table joins and CROSS APPLY patterns.

The table is joined to `BI_DB_DepositWithdrawFee` in the Tableau **DepositWithdrawFee** report on `(Date, TransactionID)` to display the correct **MIDValue** and **Entity** columns. It is intentionally separated from the finance report pipeline because it depends on multiple external lake tables (`MerchantAccountRouting`, `MerchantAccount`, `MapMerchantCodeToMid`, `vWithdrawToFunding_Alltime`) that cannot be allowed to block the financial report ETL.

As noted in the SP comments, this is a **temporary solution** — the long-term plan is to receive MID routing data directly from DBAs via production views, since the current approach recomputes hard-coded logic that can diverge from production if source configurations change.

---

## 2. Business Logic

### 2.1 Deposit MID Resolution

**What**: For each deposit on the target date, resolves the MID identifier and legal entity name through a multi-step lookup chain.

**Columns Involved**: `TransactionID`, `MIDName`, `MID`, `ActionType`

**Rules**:
- Source: `BI_DB_DepositWithdrawFee` (filtered to `TransactionType = 'Deposit'`) joined to `Fact_BillingDeposit` on `DepositID`
- **FundingTypeID = 2** (wire transfer): MIDName = `Dim_BillingProtocolMIDSettingsID.Description`; MID = `Dim_BillingProtocolMIDSettingsID.Value`
- **DepotID IN (78, 79, 80, 4, 75, 86)**: MIDName = `MerchantAccount.BODescription` (via MerchantAccountRouting depot+regulation match); MID = `MerchantAccount.Name`
- **All other depots**: MIDName = `COALESCE(DMA.BODescription, ma.BODescription, BillingGetMerchantDetail, Regulation.Name)`; MID = `COALESCE(DMA.Name, ma.Name, BPMS.Description, BillingGetMerchantDetail, BMMC.MID, BPMS.Value)`
- Fallback fix for unresolved deposits: maps RegulationID to entity name (1,3,5 = eToroEU; 2 = eToroUK; 4,10 = eToroAU; 6,7,8 = '0'; 9,11 = pattern match on BPMS Description/BMMC MID for EU/AU/UK suffix)
- Wire transfers (FundingTypeID=2) with MIDName='NA' get a secondary fix based on MID suffix pattern (%)AU → eToroAU, %)UK → eToroUK, etc.)

### 2.2 Withdraw MID Resolution

**What**: For each withdrawal processed on the target date, resolves MID through a different lookup path involving withdraw-specific billing tables.

**Columns Involved**: `TransactionID`, `MIDName`, `MID`, `ActionType`

**Rules**:
- Source: `Fact_CustomerAction` (ActionTypeID=8, cashouts for the date) joined to `Fact_BillingWithdraw` on `WithdrawPaymentID`
- Customer regulation resolved via `Fact_SnapshotCustomer` + `Dim_Range` for the processing date
- **DepotID IN (35-43)**: MIDName = Regulation name from `Dim_Regulation`; MID = `Dim_BillingProtocolMIDSettingsID.Value` (from deposit's BPMS)
- **DepotID IN (1,24,25,26,78,79,80,4,75,86)**: MIDName = `MerchantAccount.BODescription` (via MerchantAccountRouting); MID = `MerchantAccount.Name`
- **FundingTypeID_Funding = 2** (wire): Uses BPMS Description/Value
- **DepotID = 18**: MID = BPMS Value
- **All other**: `COALESCE(BackOffice.BODescription, BackOffice2.BODescription, Regulation.Name)` for MIDName; `COALESCE(BackOffice.Name, BackOffice2.Name, BPMS.Description, BMMC.MID, BPMS.Value)` for MID
- Special case: FundingTypeID_Funding=32 with NULL MID/MIDName → hardcoded to MID='PWMBUS', MIDName='eToroUS'
- MerchantAccountID for withdraws resolved from `History.WithdrawToFundingAction` (latest CashoutStatusID=3 row by ModificationDate)

### 2.3 TransactionID Construction

**What**: Synthetic transaction identifier matching the `BI_DB_DepositWithdrawFee.TransactionID` format for join compatibility.

**Columns Involved**: `TransactionID`

**Rules**:
- Deposits: `CAST(DepositID AS VARCHAR(20)) + 'D'` — the DepositID from `BI_DB_DepositWithdrawFee.DepositWithdrawID`
- Withdraws: `CAST(WithdrawPaymentID AS VARCHAR(20)) + 'W'` — the `Fact_BillingWithdraw.WithdrawPaymentID`
- Suffix identifies the transaction type: **D** = deposit, **W** = withdraw

### 2.4 ETL Pattern

**What**: Daily delete-and-reload by date.

**Rules**:
- `DELETE FROM BI_DB_PIPs_Report_MID_Settings WHERE [Date] = @StartDate`
- `INSERT` from UNION ALL of deposit MID resolutions and withdraw MID resolutions
- Idempotent — re-running for the same date replaces previous results

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(TransactionID) distribution aligns with the primary join pattern to `BI_DB_DepositWithdrawFee` (also keyed on TransactionID). The clustered index on Date supports the daily DELETE + date-range queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| MID details for a specific transaction | `WHERE TransactionID = '12345D'` |
| All MID assignments for a date | `WHERE [Date] = '2025-09-10'` |
| Entity distribution for a date range | `GROUP BY MIDName WHERE DateID BETWEEN @start AND @end` |
| Join to DepositWithdrawFee | `JOIN BI_DB_PIPs_Report_MID_Settings ON Date = Date AND TransactionID = TransactionID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_DepositWithdrawFee | ON bddwf.Date = bdprms.Date AND bddwf.TransactionID = bdprms.TransactionID | Primary consumer — adds MIDValue and Entity columns to the finance report |

### 3.4 Gotchas

- **Blank MIDName/MID**: ~11% of recent rows have empty (not NULL) MIDName and MID values — these represent transactions where the routing logic could not resolve a merchant configuration. Investigate by checking ProtocolMIDSettingsID and MerchantAccountID in source tables.
- **'NA' MIDName**: Distinct from blank — represents transactions where regulation-to-entity mapping failed in the fallback logic.
- **Temporary solution**: The SP author notes this replicates hard-coded production logic that can diverge from actual production routing if source configurations change without notification.
- **Not a standalone report table**: Designed exclusively as a Tableau join supplement for `BI_DB_DepositWithdrawFee`. Do not query in isolation for financial reporting.
- **Data starts 2024-01-01**: Historical data before this date is not available in this table.
- **Wire transfer special handling**: FundingTypeID=2 follows a separate MID resolution path using `Dim_BillingProtocolMIDSettingsID.Description/Value` directly.
- **PWMBUS hardcode**: FundingTypeID_Funding=32 withdrawals with unresolved MIDs are hardcoded to MID='PWMBUS', MIDName='eToroUS'.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 2 — SP ETL code | (Tier 2 — source) |

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | date | YES | Calendar date for the MID routing resolution. Corresponds to the SP input parameter @StartDate. Used as the primary join key alongside TransactionID when linking to BI_DB_DepositWithdrawFee. (Tier 2 — SP_PIPs_Report_MID_Settings) |
| 2 | DateID | int | YES | Integer date key in YYYYMMDD format. Derived from @StartDate via `CONVERT(VARCHAR(8), @StartDate, 112)`. Used for partition-style filtering. (Tier 2 — SP_PIPs_Report_MID_Settings) |
| 3 | TransactionID | varchar(20) | YES | Synthetic transaction identifier: DepositID + 'D' for deposits, WithdrawPaymentID + 'W' for withdrawals. Matches the TransactionID format in BI_DB_DepositWithdrawFee for join compatibility. (Tier 2 — BI_DB_DepositWithdrawFee / Fact_BillingWithdraw) |
| 4 | MIDName | varchar(50) | YES | eToro legal entity name resolved for this transaction (e.g., eToroEU, eToroUK, eToroAU, eToroME, eToroUS, EMUK). Derived from complex CASE-based routing logic using MerchantAccount.BODescription, Dim_BillingProtocolMIDSettingsID.Description, and Dim_Regulation.Name. Empty string when routing logic cannot resolve an entity. (Tier 2 — Dim_BillingProtocolMIDSettingsID / Dictionary.MerchantAccount / Dim_Regulation) |
| 5 | MID | varchar(50) | YES | Payment processor endpoint identifier resolved for this transaction (e.g., eToroMoneyEU, NuveiEU, PayPalEU, WorldpayEU, CheckoutME). Derived from complex CASE-based routing logic using Dim_BillingProtocolMIDSettingsID.Value, MerchantAccount.Name, and MapMerchantCodeToMid.MID. Empty string when routing logic cannot resolve an endpoint. (Tier 2 — Dim_BillingProtocolMIDSettingsID / Dictionary.MerchantAccount / Dictionary.MapMerchantCodeToMid) |
| 6 | ActionType | varchar(50) | YES | Transaction direction: **Deposit** or **Withdraw**. Literal string assigned based on the UNION branch in the SP (deposit resolution vs withdraw resolution). (Tier 2 — SP_PIPs_Report_MID_Settings) |
| 7 | UpdateDate | datetime | YES | Row load timestamp set to GETDATE() at INSERT time. Not a business date. (Tier 2 — SP_PIPs_Report_MID_Settings) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| Date | SP parameter | @StartDate | Literal passthrough |
| DateID | SP parameter | @StartDate | CONVERT(VARCHAR(8), @StartDate, 112) |
| TransactionID | BI_DB_DepositWithdrawFee.DepositWithdrawID / Fact_BillingWithdraw.WithdrawPaymentID | DepositWithdrawID / WithdrawPaymentID | CAST(ID AS VARCHAR(20)) + 'D' or + 'W' |
| MIDName | Dim_BillingProtocolMIDSettingsID / Dictionary.MerchantAccount / Dim_Regulation | Description / BODescription / Name | Complex CASE by FundingTypeID and DepotID |
| MID | Dim_BillingProtocolMIDSettingsID / Dictionary.MerchantAccount / Dictionary.MapMerchantCodeToMid | Value / Name / MID | Complex CASE by FundingTypeID and DepotID |
| ActionType | SP logic | Literal | 'Deposit' or 'Withdraw' based on UNION branch |
| UpdateDate | SP logic | GETDATE() | Row load timestamp |

### 5.2 ETL Pipeline

```
Deposit path:
  BI_DB_dbo.BI_DB_DepositWithdrawFee (DateID filter, TransactionType='Deposit')
    + DWH_dbo.Fact_BillingDeposit (JOIN on DepositID)
    + DWH_dbo.Dim_BillingProtocolMIDSettingsID (JOIN on ProtocolMIDSettingsID)
    + DWH_dbo.Dim_Regulation (JOIN on RegulationID)
    + External: MerchantAccount, MerchantAccountRouting, MapMerchantCodeToMid
    → #midPrep → #midPrep2 (CASE-based MID resolution)
    → #final (UNION branch: Deposit)

Withdraw path:
  DWH_dbo.Fact_CustomerAction (ActionTypeID=8, DateID filter)
    + DWH_dbo.Fact_BillingWithdraw (JOIN on WithdrawPaymentID, ModificationDate filter)
    + DWH_dbo.Fact_SnapshotCustomer + Dim_Range (customer regulation for date)
    + DWH_dbo.Dim_BillingProtocolMIDSettingsID + Dim_Regulation
    + External: MerchantAccount, MerchantAccountRouting, WithdrawToFundingAction
    → #ProcessTracking (CASE-based MID resolution)
    → #final (UNION branch: Withdraw)

#final (UNION ALL of Deposits + Withdrawals)
  → DELETE BI_DB_PIPs_Report_MID_Settings WHERE Date = @StartDate
  → INSERT INTO BI_DB_PIPs_Report_MID_Settings
BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings (~15.8M rows, 2024-01-01 to present)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| TransactionID | BI_DB_dbo.BI_DB_DepositWithdrawFee | Same TransactionID format — designed for join on (Date, TransactionID) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Tableau DepositWithdrawFee report | Date + TransactionID | Joined to provide MIDValue (MID) and Entity (MIDName) columns in the finance deposit/withdraw report |

---

## 7. Sample Queries

### 7.1 Join to DepositWithdrawFee for Tableau report

```sql
SELECT bddwf.DateID,
       bddwf.CID,
       bddwf.TransactionID,
       bdprms.MID AS MIDValue,
       bdprms.MIDName AS Entity
FROM BI_DB_dbo.BI_DB_DepositWithdrawFee bddwf
JOIN BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings bdprms
    ON bddwf.[Date] = bdprms.[Date]
    AND bddwf.TransactionID = bdprms.TransactionID
WHERE bddwf.[Date] = '2025-09-10'
```

### 7.2 Entity distribution for a date

```sql
SELECT MIDName, ActionType, COUNT(*) AS TxCount
FROM BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings
WHERE DateID = 20250910
GROUP BY MIDName, ActionType
ORDER BY TxCount DESC
```

### 7.3 Unresolved MIDs (blank values)

```sql
SELECT [Date], ActionType, COUNT(*) AS UnresolvedCount
FROM BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings
WHERE MIDName = '' OR MID = ''
GROUP BY [Date], ActionType
ORDER BY [Date] DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — regen harness mode.)

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 0 T1, 7 T2, 0 T3, 0 T4, 0 T5 | Elements: 7/7, Logic: 9/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_PIPs_Report_MID_Settings | Type: Table | Production Source: SP_PIPs_Report_MID_Settings (computed from Dim_BillingProtocolMIDSettingsID, Dictionary.MerchantAccount, Dim_Regulation, BI_DB_DepositWithdrawFee, Fact_BillingDeposit, Fact_BillingWithdraw)*
