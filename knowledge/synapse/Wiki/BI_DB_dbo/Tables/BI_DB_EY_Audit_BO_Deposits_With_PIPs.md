# BI_DB_dbo.BI_DB_EY_Audit_BO_Deposits_With_PIPs

> 15.1M-row EY audit reporting table capturing daily approved deposits for credit-report-valid (CB-valid) customers, enriched with rollback amounts, exchange rate PIPs calculations, MID routing details, and card/funding metadata. Populated daily by SP_EY_Audit_BO_Deposits_With_PIPs from History Credit, Billing.Deposit, Fact_SnapshotCustomer (point-in-time CB validity), and Fact_BillingDeposit (payment instrument metadata). Data spans 2023-01-01 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: etoro.History.Credit (deposit population), etoro.Billing.Deposit (deposit details), DWH_dbo.Fact_SnapshotCustomer (CB validity), DWH_dbo.Fact_BillingDeposit (card/funding metadata) |
| **Refresh** | Daily (DELETE + INSERT by ModificationDate window via SP_EY_Audit_BO_Deposits_With_PIPs, with auto-fill for missing dates) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_EY_Audit_BO_Deposits_With_PIPs` is an EY (Ernst & Young) audit reporting table that replicates the BackOffice deposit query logic in Synapse, enriched with PIPs (Payment In Pips) conversion fee calculations. It records every deposit for customers who are credit-report-valid (IsCreditReportValidCB=1) at the time of the deposit, using point-in-time lookups against `Fact_SnapshotCustomer` via `Dim_Range`.

The table serves regulatory audit requirements by providing a complete daily deposit record with:
- Full deposit lifecycle details (amount, currency, status, exchange rates)
- Rollback/chargeback tracking (TotalRollbackUSDAmount, TotalRollbackAmount)
- PIPs-related fields (ExchangeRate, BaseExchangeRate, ExchangeFee, ConversionOverridePIPSConfig, Reciprocal)
- Payment routing metadata (Depot, FundingType, MID, MIDName, CardType)
- Customer context (Regulation, WhiteLabel, CountryByRegIP)

The SP uses a multi-step temp table pipeline: first it extracts deposit events from History Credit (CreditTypeID=1), joins to Billing.Deposit for full deposit details, enriches with dimension lookups, then filters to CB-valid customers via Fact_SnapshotCustomer. A second pass adds payment instrument metadata from Fact_BillingDeposit. The final INSERT targets only `IsCreditReportValidCB=1` rows.

The SP includes auto-fill logic: if dates are missing between the last loaded DateID and the requested date, it recursively calls itself for each missing date before processing the target date.

As of 2025-10-27: 15.1M rows, 99.998% Approved status, spanning 2023-01-01 to 2025-10-27. Top regulations: CySEC (53.5%), FCA (28.5%), ASIC & GAML (6.9%).

---

## 2. Business Logic

### 2.1 Credit-Report-Valid Filter (CB-Valid)

**What**: Only deposits from customers who are credit-report-valid at the time of the deposit are included.

**Columns Involved**: `IsCreditReportValidCB`, `CountryID`, `CID`

**Rules**:
- The SP joins `Fact_SnapshotCustomer` + `Dim_Range` to determine `IsCreditReportValidCB` at the point-in-time of the deposit's `ModificationDate`
- The final INSERT has `WHERE IsCreditReportValidCB = 1`
- IsCreditReportValidCB=1 when: NOT (PlayerLevelID=4 AND AccountTypeID<>2) AND LabelID NOT IN (26,30) AND NOT (CountryID=250 AND CID NOT IN specific exceptions)

### 2.2 PIPs / Conversion Fee Calculation

**What**: The table captures exchange rate components needed to compute the conversion fee (PIPs) that eToro earns on non-USD deposits.

**Columns Involved**: `ExchangeRate`, `BaseExchangeRate`, `ExchangeFee`, `ConversionOverridePIPSConfig`, `Reciprocal`

**Rules**:
- PIPs formula (computed in SP but not stored as a column): `(Amount * BaseExchangeRateComputed) - (Amount * ExchangeRate)`
- `BaseExchangeRateComputed` = for WireTransfer (FundingTypeID=2) with non-USD currency: `ExchangeRate + ExchangeRate/10000`; otherwise: `BaseExchangeRate`
- `Reciprocal` = 1 when CurrencyID=1 (USD deposit), 0 otherwise
- `ConversionOverridePIPSConfig` = override fee from `Billing.ConversionFeeOverride` table, matched on PlayerLevelID + CurrencyID + FundingTypeID

### 2.3 Rollback Amount Calculation

**What**: Computes the total rollback (chargeback/refund) amount for each deposit.

**Columns Involved**: `TotalRollbackUSDAmount`, `TotalRollbackAmount`

**Rules**:
- If `DepositRollbackTracking` has a record (IsCanceled=0): use `TotalRollbackAmountInUSD` / `TotalRollbackAmountInCurrency`
- Else if PaymentStatusID=2 (Approved, no rollback): 0
- Else: `-1 * RollbackAmount` from History.Credit (CreditTypeID IN 11,12,16 = chargeback/refund/reversal), divided by ExchangeRate for currency amount

### 2.4 Missing Date Auto-Fill

**What**: The SP automatically backfills any gaps between the last loaded date and the requested date.

**Columns Involved**: `DateID`, `ModificationDate`

**Rules**:
- On invocation, the SP checks `MAX(DateID)` against the target date
- If gaps exist, it recursively calls itself for each missing date (day by day) before processing the target date
- This ensures no gaps in the daily audit record

### 2.5 Customer Name Disclosure for Wire Transfers

**What**: Customer name is only disclosed for wire transfer deposits (regulatory requirement for wire audit trail).

**Columns Involved**: `CustomerNameForWires`, `FundingType`

**Rules**:
- `CASE WHEN FundingType = 'WireTransfer' THEN FirstName + ' ' + LastName ELSE 'NA' END`
- Only wire transfers expose customer PII in this column; all other funding types show 'NA'

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP index. No clustered index or distribution key — full scans are required for any query. For large date ranges, always filter on `DateID` or `ModificationDateID`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily deposit volume for audit period | `WHERE DateID BETWEEN @start AND @end GROUP BY DateID` |
| PIPs revenue for a period | Compute `(Amount * BaseExchangeRate) - (Amount * ExchangeRate)` with `WHERE Reciprocal = 0` (non-USD only) |
| Deposits with chargebacks | `WHERE TotalRollbackUSDAmount <> 0` |
| Wire transfer deposits with customer names | `WHERE FundingType = 'WireTransfer'` |
| Deposits by regulation | `GROUP BY Regulation` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Additional customer attributes not in this table |
| DWH_dbo.Dim_Date | ON DateID = DateID | Calendar attributes for the deposit date |
| DWH_dbo.Dim_Country | ON CountryID = CountryID | Full country attributes (IsHighRiskCountry, Region, etc.) |

### 3.4 Gotchas

- **Column name typo**: `CountyByRegIP` is missing the "r" — should be "CountryByRegIP" but is stored as `CountyByRegIP` in DDL. Use as-is.
- **IsCreditReportValidCB is always 1**: The SP filters to CB-valid rows only, so this column is always 1 in the output. It exists for audit traceability, not filtering.
- **Status is nearly always 'Approved'**: 99.998% of rows are Approved (PaymentStatusID=2). Non-approved rows appear because the History Credit CreditTypeID=1 filter captures deposits regardless of their final status, but the Billing.Deposit record may have a different PaymentStatusID.
- **HCAmountUSD vs Amount**: `HCAmountUSD` is `TotalCashChange` from History Credit (the actual USD cash impact); `Amount` is the deposit amount in the deposit currency from Billing.Deposit. For USD deposits these are usually equal; for non-USD deposits they differ due to exchange rates.
- **ROUND_ROBIN + HEAP**: No index optimization possible. Full table scans on all queries. Always filter by `DateID` for performance.
- **ConversionOverridePIPSConfig may be NULL**: Only populated when a matching override exists in `Billing.ConversionFeeOverride` for the customer's PlayerLevelID + CurrencyID + FundingTypeID combination.
- **MIDName comes from Dim_Regulation**: `MIDName` is the regulation name associated with the ProtocolMIDSettings record, not the MID name itself. `MID` is the actual MID value (ISNULL(Description, Value) from ProtocolMIDSettings).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag | Meaning |
|------|-----|---------|
| Tier 1 | `(Tier 1 — source)` | Upstream wiki verbatim — passthrough or dim-lookup |
| Tier 2 | `(Tier 2 — source)` | ETL-computed or SP-derived |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ExternalID | varchar(100) | YES | APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 2 | CID | int | YES | Customer ID. Identifies the eToro customer who made this deposit. (Tier 1 — Billing.Deposit) |
| 3 | HCAmountUSD | float | YES | Total cash change in USD from History Credit for this deposit event. Represents the actual USD cash impact on the customer's account. (Tier 2 — External_etoro_History_Credit_Yesterday) |
| 4 | DepositID | bigint | YES | Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). (Tier 1 — Billing.Deposit) |
| 5 | Amount | float | YES | Deposit amount in the deposit currency (CurrencyID). CAST to DECIMAL(16,2) in SP. (Tier 1 — Billing.Deposit) |
| 6 | Currency | varchar(100) | YES | Ticker symbol for the deposit currency. "USD", "EUR", "GBP", etc. Resolved from Dim_Currency.Abbreviation via CurrencyID JOIN. (Tier 1 — Dictionary.Currency) |
| 7 | Status | varchar(100) | YES | Human-readable deposit status label. Resolved from Dim_PaymentStatus.Name via PaymentStatusID JOIN. 99.998% = 'Approved'. (Tier 1 — Dictionary.PaymentStatus) |
| 8 | PaymentDate | datetime | YES | UTC timestamp when the deposit was submitted (set at INSERT in production). Not the approval time. (Tier 1 — Billing.Deposit) |
| 9 | ModificationDate | datetime | YES | UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection. (Tier 1 — Billing.Deposit) |
| 10 | ProcessorValueDate | datetime | YES | Value date from the payment processor. Mandatory for offline/wire deposits. NULL for instant payment methods. (Tier 1 — Billing.Deposit) |
| 11 | IPAddress | varchar(100) | YES | Customer IP address at deposit time, converted from numeric to dotted-quad string via DWH_dbo.IPNumToIPAddress() UDF. Empty string if NULL in source. (Tier 2 — Billing.Deposit) |
| 12 | PaymentStatusID | int | YES | Current deposit status ID. 1=New, 2=Approved, 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE. FK to Dim_PaymentStatus. (Tier 1 — Billing.Deposit) |
| 13 | CurrencyID | int | YES | Currency of the deposit amount. 1=USD, 2=EUR, 5=AUD, 6=CHF, etc. FK to Dim_Currency. (Tier 1 — Billing.Deposit) |
| 14 | TotalRollbackUSDAmount | float | YES | Total rollback (chargeback/refund) amount in USD. 0 for approved deposits with no rollback. Computed from DepositRollbackTracking or History Credit chargeback/refund entries. (Tier 2 — External_etoro_Billing_DepositRollbackTracking / External_etoro_History_Credit_Yesterday) |
| 15 | TotalRollbackAmount | float | YES | Total rollback amount in the deposit currency. 0 for approved deposits with no rollback. Computed from DepositRollbackTracking or History Credit entries divided by ExchangeRate. (Tier 2 — External_etoro_Billing_DepositRollbackTracking / External_etoro_History_Credit_Yesterday) |
| 16 | Funnel | varchar(100) | YES | Acquisition funnel name for the deposit. Resolved from Dim_Funnel.Name via FunnelID JOIN. (Tier 1 — Dictionary.Funnel) |
| 17 | Regulation | varchar(100) | YES | Short code for the regulatory entity governing the customer. Resolved from Dim_Regulation.Name via Dim_Customer.RegulationID. Top values: CySEC (53.5%), FCA (28.5%), ASIC & GAML (6.9%). (Tier 1 — Dictionary.Regulation) |
| 18 | WhiteLabel | varchar(100) | YES | Brand name of the white-label broker the customer was acquired under. Resolved from Dim_Label.Name via Dim_Customer.LabelID. (Tier 1 — Dictionary.Label) |
| 19 | CountyByRegIP | varchar(100) | YES | Full country name based on the customer's registration IP address. Resolved from Dim_Country.Name via Dim_Customer.CountryIDByIP. Note: column name has typo ("County" instead of "Country"). (Tier 1 — Dictionary.Country) |
| 20 | DepositType | varchar(100) | YES | Description of the deposit type (e.g., "Regular payment", "Recurring payment"). Resolved from External_etoro_Dictionary_Deposittype.Description via DepositTypeID JOIN. (Tier 2 — External_etoro_Dictionary_Deposittype) |
| 21 | MIDName | varchar(100) | YES | Regulation name associated with the ProtocolMIDSettings record used for routing this deposit. Resolved from Dim_Regulation.Name via ProtocolMIDSettings.RegulationID. NULL when no MID settings exist. (Tier 1 — Dictionary.Regulation) |
| 22 | MID | varchar(100) | YES | Merchant ID configuration value for this deposit. ISNULL(Description, Value) from ProtocolMIDSettings. NULL when no MID settings exist. (Tier 2 — External_etoro_Billimg_ProtocolMIDSettings) |
| 23 | TransactionID | varchar(100) | YES | Internal transaction identifier from Billing.Deposit. (Tier 1 — Billing.Deposit) |
| 24 | ExTransactionID | varchar(100) | YES | External (payment provider) transaction ID. Used for provider-side reconciliation and dispute resolution. (Tier 1 — Billing.Deposit) |
| 25 | ExchangeRate | float | YES | Exchange rate from deposit currency to USD at processing time. 1.0 for USD deposits. (Tier 1 — Billing.Deposit) |
| 26 | BaseExchangeRate | float | YES | Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. (Tier 1 — Billing.Deposit) |
| 27 | ExchangeFee | float | YES | Exchange fee in provider-specific integer encoding (basis points). 0 for USD deposits. (Tier 1 — Billing.Deposit) |
| 28 | ModificationDateID | int | YES | Integer date key derived from ModificationDate as YYYYMMDD. Used for ETL DELETE+INSERT window and date-based filtering. (Tier 2 — SP_EY_Audit_BO_Deposits_With_PIPs) |
| 29 | IsCreditReportValidCB | int | YES | DWH-computed flag indicating credit-report-valid customer. Always 1 in this table (SP filters to CB-valid only). Point-in-time value from Fact_SnapshotCustomer via Dim_Range. (Tier 2 — Fact_SnapshotCustomer) |
| 30 | CountryID | int | YES | Customer's registered country at the time of the deposit. Point-in-time value from Fact_SnapshotCustomer via Dim_Range. FK to Dim_Country. (Tier 2 — Fact_SnapshotCustomer) |
| 31 | Depot | varchar(100) | YES | Acquirer/gateway name used for this deposit. Resolved from External_etoro_Billing_Depot.Name via Fact_BillingDeposit.DepotID. (Tier 2 — External_etoro_Billing_Depot) |
| 32 | FundingType | varchar(100) | YES | Payment method name (e.g., CreditCard, PayPal, eToroMoney, WireTransfer). Resolved from Dim_FundingType.Name via Fact_BillingDeposit.FundingTypeID. Top values: CreditCard (53.9%), eToroMoney (29.7%), PayPal (12.1%). (Tier 1 — Dictionary.FundingType) |
| 33 | BankNameAsString | varchar(100) | YES | Bank name extracted from Billing.Deposit PaymentData XML. Passthrough from Fact_BillingDeposit. NULL for non-bank payment methods. (Tier 2 — Fact_BillingDeposit) |
| 34 | CardType | varchar(100) | YES | Card network brand name. Resolved from Dim_CardType.CarTypeName via Fact_BillingDeposit.CardTypeIDAsInteger. Values: Visa, Master Card, Diners, Maestro, etc. NULL for non-card payment methods. (Tier 1 — Dictionary.CardType) |
| 35 | CustomerNameForWires | varchar(100) | YES | Customer full name (FirstName + ' ' + LastName) for wire transfer deposits only. 'NA' for all other funding types. PII field — only disclosed for wire transfer audit trail. (Tier 2 — Dim_Customer) |
| 36 | ConversionOverridePIPSConfig | varchar(100) | YES | Conversion fee override value from Billing.ConversionFeeOverride, matched on PlayerLevelID + CurrencyID + FundingTypeID. NULL when no override exists for this combination. (Tier 2 — External_etoro_Billing_ConversionFeeOverride) |
| 37 | Reciprocal | int | YES | Flag indicating whether the deposit is in USD (reciprocal=1) or non-USD (reciprocal=0). Used in PIPs calculations — non-USD deposits have exchange fee revenue. (Tier 2 — Billing.Deposit) |
| 38 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at SP execution time. Not a business date. (Tier 2 — SP_EY_Audit_BO_Deposits_With_PIPs) |
| 39 | DateID | int | YES | Date key for the processing date in YYYYMMDD format. Set to @StartDateBO_Int (the SP input date parameter). Used for daily partitioning and gap detection. (Tier 2 — SP_EY_Audit_BO_Deposits_With_PIPs) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| ExternalID | Customer.CustomerStatic (via Dim_Customer) | ExternalID | Passthrough |
| CID | Billing.Deposit | CID | Passthrough |
| HCAmountUSD | History.Credit | TotalCashChange | Passthrough (CreditTypeID=1 filter) |
| DepositID | Billing.Deposit | DepositID | Passthrough |
| Amount | Billing.Deposit | Amount | CAST to DECIMAL(16,2) |
| Currency | Dictionary.Currency (via Dim_Currency) | Abbreviation | Lookup on CurrencyID |
| Status | Dictionary.PaymentStatus (via Dim_PaymentStatus) | Name | Lookup on PaymentStatusID |
| PaymentDate | Billing.Deposit | PaymentDate | Passthrough |
| ModificationDate | Billing.Deposit | ModificationDate | Passthrough |
| ProcessorValueDate | Billing.Deposit | ProcessorValueDate | Passthrough |
| IPAddress | Billing.Deposit | IPAddress | IPNumToIPAddress() UDF conversion |
| PaymentStatusID | Billing.Deposit | PaymentStatusID | Passthrough |
| CurrencyID | Billing.Deposit | CurrencyID | Passthrough |
| TotalRollbackUSDAmount | Billing.DepositRollbackTracking / History.Credit | TotalRollbackAmountInUSD / Payment | CASE logic (see Section 2.3) |
| TotalRollbackAmount | Billing.DepositRollbackTracking / History.Credit | TotalRollbackAmountInCurrency / Payment | CASE logic / ExchangeRate division |
| Funnel | Dictionary.Funnel (via Dim_Funnel) | Name | Lookup on FunnelID |
| Regulation | Dictionary.Regulation (via Dim_Regulation) | Name | Lookup via Dim_Customer.RegulationID |
| WhiteLabel | Dictionary.Label (via Dim_Label) | Name | Lookup via Dim_Customer.LabelID |
| CountyByRegIP | Dictionary.Country (via Dim_Country) | Name | Lookup via Dim_Customer.CountryIDByIP |
| DepositType | Dictionary.Deposittype | Description | Lookup on DepositTypeID |
| MIDName | Dictionary.Regulation (via Dim_Regulation) | Name | Lookup via ProtocolMIDSettings.RegulationID |
| MID | Billing.ProtocolMIDSettings | Description / Value | ISNULL(Description, Value) |
| TransactionID | Billing.Deposit | TransactionID | Passthrough |
| ExTransactionID | Billing.Deposit | ExTransactionID | Passthrough |
| ExchangeRate | Billing.Deposit | ExchangeRate | Passthrough |
| BaseExchangeRate | Billing.Deposit | BaseExchangeRate | Passthrough |
| ExchangeFee | Billing.Deposit | ExchangeFee | Passthrough |
| ModificationDateID | Billing.Deposit | ModificationDate | CAST(CONVERT(VARCHAR(8), date, 112) AS INT) |
| IsCreditReportValidCB | Fact_SnapshotCustomer | IsCreditReportValidCB | Point-in-time via Dim_Range |
| CountryID | Fact_SnapshotCustomer | CountryID | Point-in-time via Dim_Range |
| Depot | Billing.Depot (via Fact_BillingDeposit) | Name | Lookup on DepotID |
| FundingType | Dictionary.FundingType (via Dim_FundingType) | Name | Lookup on FundingTypeID |
| BankNameAsString | Billing.Deposit PaymentData XML (via Fact_BillingDeposit) | BankNameAsString | XML extraction passthrough |
| CardType | Dictionary.CardType (via Dim_CardType) | CarTypeName | Lookup on CardTypeIDAsInteger |
| CustomerNameForWires | Customer.CustomerStatic (via Dim_Customer) | FirstName, LastName | CASE: WireTransfer=concat, else 'NA' |
| ConversionOverridePIPSConfig | Billing.ConversionFeeOverride | DepositFee | Lookup on PlayerLevelID+CurrencyID+FundingTypeID |
| Reciprocal | Billing.Deposit | CurrencyID | CASE WHEN CurrencyID=1 THEN 1 ELSE 0 |
| UpdateDate | — | — | GETDATE() |
| DateID | — | — | @StartDateBO_Int parameter |

### 5.2 ETL Pipeline

```
etoro.History.Credit (CreditTypeID=1, daily window)
  |-- SP_Create_External_etoro_History_Credit @date ---|
  v
BI_DB_dbo.External_etoro_History_Credit_Yesterday
  |
  +-- LEFT JOIN External_etoro_Billing_Deposit (on DepositID)
  +-- LEFT JOIN External_etoro_Billing_DepositRollbackTracking
  +-- LEFT JOIN DWH_dbo.Dim_Customer (on CID=RealCID)
  +-- LEFT JOIN DWH_dbo.Dim_Label, Dim_Country, Dim_Regulation, Dim_Funnel
  +-- LEFT JOIN External_etoro_Billing_Funding_Datafactory
  +-- LEFT JOIN DWH_dbo.Dim_Currency, Dim_PaymentStatus
  +-- LEFT JOIN External_etoro_Dictionary_Deposittype
  +-- LEFT JOIN External_etoro_Billimg_ProtocolMIDSettings
  |
  v
#allDeps (temp table — all deposits for the date)
  |
  +-- JOIN DWH_dbo.Fact_SnapshotCustomer + Dim_Range (point-in-time CB validity)
  |
  v
#allDepsWithCBValid (temp table — deposits with CB flag)
  |
  +-- LEFT JOIN DWH_dbo.Fact_BillingDeposit → #meta (CardType, BankName, Depot, FundingType)
  +-- LEFT JOIN DWH_dbo.Dim_CardType
  +-- LEFT JOIN External_etoro_Billing_ConversionFeeOverride
  |
  v (WHERE IsCreditReportValidCB = 1)
BI_DB_dbo.BI_DB_EY_Audit_BO_Deposits_With_PIPs (DELETE + INSERT by ModificationDate window)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.History.Credit | Deposit events (CreditTypeID=1) for the target date |
| Source | etoro.Billing.Deposit | Full deposit record with payment details |
| Source | DWH_dbo.Fact_SnapshotCustomer | Point-in-time customer CB validity |
| Source | DWH_dbo.Fact_BillingDeposit | Payment instrument metadata (card type, bank, depot) |
| ETL | BI_DB_dbo.SP_EY_Audit_BO_Deposits_With_PIPs | Multi-step temp table pipeline with CB filter. Author: Guy Manova (2023-05-28) |
| Target | BI_DB_dbo.BI_DB_EY_Audit_BO_Deposits_With_PIPs | 15.1M rows, ROUND_ROBIN/HEAP |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer who made the deposit |
| PaymentStatusID | DWH_dbo.Dim_PaymentStatus | Deposit status lookup |
| CurrencyID | DWH_dbo.Dim_Currency | Deposit currency lookup |
| CountryID | DWH_dbo.Dim_Country | Customer's registered country |
| DateID | DWH_dbo.Dim_Date | Calendar date dimension |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_EY_Audit_BO_Deposits_With_PIPs | (writes this table) | Daily ETL writer SP |

---

## 7. Sample Queries

### 7.1 Daily deposit volume and PIPs revenue for a date range

```sql
SELECT
    DateID,
    COUNT(*) AS DepositCount,
    SUM(HCAmountUSD) AS TotalUSD,
    SUM(CASE WHEN Reciprocal = 0
        THEN (Amount * BaseExchangeRate) - (Amount * ExchangeRate)
        ELSE 0
    END) AS EstimatedPIPsRevenue
FROM [BI_DB_dbo].[BI_DB_EY_Audit_BO_Deposits_With_PIPs]
WHERE DateID BETWEEN 20250101 AND 20250331
GROUP BY DateID
ORDER BY DateID;
```

### 7.2 Deposits with chargebacks/rollbacks by regulation

```sql
SELECT
    Regulation,
    COUNT(*) AS TotalDeposits,
    SUM(CASE WHEN TotalRollbackUSDAmount <> 0 THEN 1 ELSE 0 END) AS RolledBackCount,
    SUM(TotalRollbackUSDAmount) AS TotalRollbackUSD
FROM [BI_DB_dbo].[BI_DB_EY_Audit_BO_Deposits_With_PIPs]
WHERE DateID BETWEEN 20250101 AND 20250331
GROUP BY Regulation
ORDER BY TotalRollbackUSD DESC;
```

### 7.3 Wire transfer deposits with customer names

```sql
SELECT
    CID,
    DepositID,
    Amount,
    Currency,
    CustomerNameForWires,
    BankNameAsString,
    PaymentDate
FROM [BI_DB_dbo].[BI_DB_EY_Audit_BO_Deposits_With_PIPs]
WHERE FundingType = 'WireTransfer'
  AND DateID >= 20250101
ORDER BY PaymentDate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in this session.)

---

*Generated: 2026-04-29 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Tiers: 20 T1, 19 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 39/38 (DDL has 38 cols, table includes DateID), Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_EY_Audit_BO_Deposits_With_PIPs | Type: Table | Production Source: Multi-source (History.Credit + Billing.Deposit + Fact_SnapshotCustomer + Fact_BillingDeposit)*
