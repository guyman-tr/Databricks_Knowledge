# DWH_dbo.Fact_Deposit_Fees

> 14.4M-row fact table recording approved deposit transactions with associated fee and payment details, sourced from BackOffice.BillingDepositsPCIVersion via ADF pipeline. Covers 2021-12-01 to 2024-06-30. Table appears dormant — no new data since June 2024. Loaded by SP_Fact_Deposit_Fees_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | BackOffice.BillingDepositsPCIVersion via SP_Fact_Deposit_Fees_DL_To_Synapse |
| **Refresh** | Dormant since 2024-06-30 (was daily incremental by StatusModificationTime) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (DWH → UC) |

---

## 1. Business Meaning

Fact_Deposit_Fees is a deposit-level fact table that captures every approved deposit transaction together with fee calculations (FeeinPIPs, PIPsinUSD), exchange rates, payment gateway details, and rollback information. The table contains 14.4M rows spanning 2021-12-01 through 2024-06-30 and is predominantly composed of approved deposits (~99.99% Approved in 2024 data).

The data originates from BackOffice.BillingDepositsPCIVersion (a PCI-compliant view of the billing deposits system) and is loaded via the ADF pipeline `etoroBackOfficeToDataLake` into `DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion`, then inserted into this table by `SP_Fact_Deposit_Fees_DL_To_Synapse`. The SP performs no JOINs or transformations on the 44 source columns — it passes them through verbatim. Two columns are computed at insert time: `ModificationDateID` (integer date key derived from `StatusModificationTime`) and `UpdateDate` (ETL run timestamp via `GETDATE()`).

The table appears dormant: no rows exist with ModificationDateID >= 20250101. The last data is from June 2024. The DELETE block in the SP is commented out, meaning the SP was running in append-only mode.

Key distributions (2024 data): CreditCard is the dominant funding method (56%), followed by eToroMoney (28%) and PayPal (12%). CySEC is the primary regulation (55%), followed by FCA (26%). EUR, GBP, and USD account for ~87% of deposit currencies.

---

## 2. Business Logic

### 2.1 Fee Calculation

**What**: Each deposit carries a fee expressed in PIPs and a USD equivalent.
**Columns Involved**: FeeinPIPs, PIPsinUSD
**Rules**:
- FeeinPIPs is typically 0 or 150 (observed in sample data)
- PIPsinUSD represents the dollar value of the fee, proportional to deposit amount
- Zero-fee deposits (FeeinPIPs=0) exist for certain funding methods and currencies

### 2.2 Exchange Rate Tracking

**What**: Two exchange rates track the deposit's currency conversion context.
**Columns Involved**: BaseExchangeRate, ExchangeRate, Currency, DepositAmount, DepositCollarAmount
**Rules**:
- BaseExchangeRate and ExchangeRate capture the rate at deposit time
- DepositCollarAmount appears to be the deposit amount converted to a base currency (often differs from DepositAmount for non-USD currencies)
- When Currency=USD, both rates are typically 1.0 and DepositCollarAmount equals DepositAmount

### 2.3 Deposit Status Lifecycle

**What**: Tracks the approval/reversal status of deposits.
**Columns Involved**: DepositStatus, DepositRiskStatus, Riskstatus, TransactionResponse, ResponseCode
**Rules**:
- DepositStatus is overwhelmingly "Approved" (only 1 ReversedDeposit in 2024 H1)
- Riskstatus is empty for ~96% of records; non-empty values indicate risk flags (BinInBlackList, WithdrawWithLowTradingRatio, HRCLoginToRegCountryConflict)
- TransactionResponse mirrors DepositStatus with gateway-level detail

### 2.4 3D Secure Authentication

**What**: Captures 3DS challenge/response data for card deposits.
**Columns Involved**: Threedsresponse, Threedsparameters
**Rules**:
- Threedsresponse values: "Success", "Unspecified", or empty
- Threedsparameters contains CAVV, ECI, and XID values when present (card-only)
- Non-card funding methods (PayPal, iDEAL, WireTransfer) have empty 3DS fields

### 2.5 First-Time Deposit Flag

**What**: Identifies whether this deposit is the customer's first approved deposit.
**Columns Involved**: FTD
**Rules**:
- "YES" = first-time deposit; empty/blank = not first-time
- ~8% of 2024 deposits are marked as FTD

### 2.6 Rollback Tracking

**What**: Tracks deposit reversals/rollbacks.
**Columns Involved**: TotalRollbackDollarAmount, TotalRollbackAmount, RollbackReason
**Rules**:
- In 2024 data, TotalRollbackDollarAmount and TotalRollbackAmount are all zero
- RollbackReason has only 1 non-empty value in 2024 — rollbacks are extremely rare in this dataset

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN** distribution: no skew advantage, but no co-location benefit either. Queries joining on CID will trigger data movement.
- **CLUSTERED INDEX on CID**: efficient for point lookups and range scans by customer ID.
- For time-based filtering, use `ModificationDateID` (integer, YYYYMMDD format) — it is more efficient than filtering on datetime columns.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Deposits for a specific customer | `WHERE CID = @cid` (uses clustered index) |
| Deposits in a date range | `WHERE ModificationDateID BETWEEN 20230101 AND 20231231` |
| Fee revenue by period | `SUM(PIPsinUSD) WHERE ModificationDateID BETWEEN ...` |
| FTD analysis | `WHERE FTD = 'YES' AND ModificationDateID BETWEEN ...` |
| Deposits by funding method | `GROUP BY FundingMethod WHERE ModificationDateID >= ...` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer demographics, status |
| DWH_dbo.Dim_Date | ModificationDateID = DateID | Calendar attributes |
| DWH_dbo.Dim_Affiliate | AffiliateID = AffiliateID | Affiliate details |

### 3.4 Gotchas

- **Table is dormant**: No data after 2024-06-30. Do not expect current deposit data here.
- **PCI-filtered source**: Originates from `BillingDepositsPCIVersion` — sensitive payment data (full card numbers, CVV) is stripped at source.
- **Commented-out DELETE**: The SP's DELETE block is commented out, so the table was running in append-only mode — duplicate rows may exist for re-processed deposits.
- **FTD is text, not boolean**: FTD column is nvarchar with values "YES" or empty string — not a bit flag.
- **Currency codes are mixed**: Some entries use compound codes like "AEDUSD", "USDRON" rather than standard ISO 4217 codes.
- **Riskstatus vs DepositRiskStatus**: Two separate risk columns exist — Riskstatus (customer-level risk flags) and DepositRiskStatus (deposit-level risk assessment). Both are typically empty.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (production source documented) |
| Tier 2 | ETL-computed — derived from SP logic or transformation |
| Tier 3 | Passthrough from production source with no upstream wiki — description grounded in DDL, SP code, and live data |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID. Identifies the depositing customer. Clustered index column. Values observed range across millions of distinct customers. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 2 | DepositStatus | nvarchar(max) | YES | Status of the deposit transaction. Overwhelmingly "Approved"; rare "ReversedDeposit" values exist. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 3 | Threedsresponse | nvarchar(max) | YES | 3D Secure authentication response for card deposits. Values: "Success", "Unspecified", or empty (non-card or no 3DS challenge). (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 4 | DepositRiskStatus | nvarchar(max) | YES | Deposit-level risk assessment status. Typically empty for approved deposits. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 5 | DepositAmount | decimal(38,18) | YES | Deposit amount in the original Currency. Represents the face value of the deposit as submitted by the customer. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 6 | Currency | nvarchar(max) | YES | Currency code of the deposit. Predominantly EUR, GBP, USD. Some compound codes exist (e.g. "AEDUSD", "USDRON") indicating cross-currency pairs. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 7 | StatusModificationTime | datetime2(7) | YES | Timestamp when the deposit status was last modified (e.g. approved). Used as the basis for ModificationDateID computation. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 8 | ModificationDateID | int | YES | Integer date key in YYYYMMDD format, derived from StatusModificationTime. ETL-computed: `CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY, 0, StatusModificationTime), 0), 112))`. Range: 20211201–20240630. (Tier 2 — SP_Fact_Deposit_Fees_DL_To_Synapse) |
| 9 | DepositTime | datetime2(7) | YES | Timestamp when the deposit was initially submitted by the customer. Typically seconds before StatusModificationTime for instant approvals. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 10 | FirstApprovedTime | datetime2(7) | YES | Timestamp of the first approval for this deposit. NULL for deposits that were not approved or where the value was not recorded. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 11 | DepositValueDate | datetime2(7) | YES | Value date of the deposit (settlement date). NULL for some payment methods where value dating does not apply. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 12 | DepositCollarAmount | decimal(38,18) | YES | Deposit amount converted to a base currency (USD equivalent). When Currency=USD, equals DepositAmount. For non-USD deposits, reflects the converted value using the applicable exchange rate. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 13 | FundingMethod | nvarchar(max) | YES | Payment method used for the deposit. Values include: CreditCard, eToroMoney, PayPal, iDEAL, WireTransfer, Giropay, PWMB, Przelewy24, MoneyBookers, Trustly, EtoroOptions, Neteller. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 14 | Depot | nvarchar(max) | YES | Payment gateway/processor that handled the deposit. Values include: Checkout, Tribe, PayPal, WorldPay, IXOPAY-Nuvei, IXOPAY-Worldpay, Giropay, PWMB, Wire(DeutscheBank). Distinct from FundingMethod — Depot is the provider, FundingMethod is the instrument type. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 15 | OldPaymentID | int | YES | Legacy payment identifier from a previous billing system. NULL for most recent deposits. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 16 | DepositID | int | YES | Unique identifier for the deposit transaction in the billing system. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 17 | TransactionID_Internal | nvarchar(max) | YES | Internal transaction identifier (short hex string, e.g. "BC73F8"). Used for internal tracking and reconciliation. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 18 | CountryByRegIP | nvarchar(max) | YES | Country name resolved from the customer's registration IP address. Full country names (e.g. "France", "Germany", "Australia"). (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 19 | Riskstatus | nvarchar(max) | YES | Customer-level risk flag at the time of deposit. Empty for ~96% of records. Non-empty values indicate flagged conditions: BinInBlackList, WithdrawWithLowTradingRatio, HRCLoginToRegCountryConflict, WithdrawWithShortTermTrades. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 20 | FTD | nvarchar(max) | YES | First-time deposit indicator. "YES" if this is the customer's first approved deposit; empty string otherwise. ~8% of deposits are FTD in 2024 data. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 21 | BaseExchangeRate | decimal(38,18) | YES | Base exchange rate from the deposit currency to USD at the time of the deposit. 1.0 when Currency=USD. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 22 | ExchangeRate | decimal(38,18) | YES | Applied exchange rate for the deposit. May differ from BaseExchangeRate due to spread or fee adjustments. 1.0 when Currency=USD. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 23 | FeeinPIPs | int | YES | Deposit fee expressed in PIPs (price interest points). Common values: 0 (no fee) or 150. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 24 | PIPsinUSD | decimal(38,18) | YES | Dollar value of the fee in PIPs. Represents the actual fee amount charged in USD. Zero when FeeinPIPs=0. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 25 | CustomerStatus | nvarchar(max) | YES | Customer account status at the time of deposit. Values: Normal, Warning, Deposit Blocked, Trade & MIMO Blocked, Block Deposit & Trading, Copy Block, Blocked Upon Request, Pending Verification, Blocked. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 26 | Brand | nvarchar(max) | YES | Card brand for credit card deposits. Values: Master Card, Visa. NULL/empty for non-card funding methods. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 27 | CardCategory | nvarchar(max) | YES | Card category/tier for credit card deposits. Values include: WORLD, CLASSIC, BUSINESS SIGNATURE, PLATINUM, STANDART. NULL/empty for non-card funding methods. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 28 | PaymentDetails | nvarchar(max) | YES | Additional payment details. For cards: BinCode prefix (e.g. "BinCode:535585"). For bank transfers: BIC, IBAN, bank name, account holder. Empty for PayPal/eToroMoney. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 29 | FundingID | int | YES | Identifier for the funding record in the billing system. Links back to the funding/payment source record. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 30 | ResponseCode | nvarchar(max) | YES | Payment gateway response code. Format varies by gateway (e.g. "2_000" for PayPal success, "43_10000" for Checkout success, "23_0" for WorldPay success). (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 31 | TransactionResponse | nvarchar(max) | YES | Human-readable transaction response from the payment gateway. Typically "Approved" or " Approved " (note: some values have leading/trailing spaces). (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 32 | CustomerLevel | nvarchar(max) | YES | Customer loyalty tier at deposit time. Values: Bronze, Gold, Silver, Platinum, Platinum Plus, Internal, Diamond. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 33 | AccountManager | nvarchar(max) | YES | Name of the account manager assigned to the customer at the time of deposit. First name only (e.g. "Emmanuel", "Alexander", "Kyra"). (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 34 | TotalRollbackDollarAmount | decimal(38,18) | YES | Total rollback amount in USD. Zero for the vast majority of deposits. Non-zero when a deposit is partially or fully reversed. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 35 | TotalRollbackAmount | decimal(38,18) | YES | Total rollback amount in the original deposit currency. Zero for the vast majority of deposits. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 36 | RollbackReason | nvarchar(max) | YES | Reason for deposit rollback/reversal. NULL/empty for non-rolled-back deposits (nearly all records). (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 37 | UserName | nvarchar(max) | YES | Customer's eToro username at the time of deposit. Contains PII. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 38 | AffiliateID | int | YES | Identifier of the affiliate that referred the customer. Common values include 2 (direct/organic), 56662, 76142, etc. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 39 | ExternalTransactionID | nvarchar(max) | YES | Transaction identifier from the external payment provider. Format varies by gateway: PayPal transaction IDs, Checkout pay_ tokens, WorldPay D_ prefixed IDs. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 40 | Funnel | nvarchar(max) | YES | Deposit funnel/channel. Values: Retoro (web platform, ~99.6%), BackOffice (manual), reToroiOS (legacy iOS). (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 41 | Regulation | nvarchar(max) | YES | Regulatory entity under which the deposit was processed. Values: CySEC, FCA, ASIC & GAML, FSA Seychelles, FinCEN+FINRA, FSRA, ASIC, BVI, FinCEN, eToroUS. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 42 | WhiteLabel | nvarchar(max) | YES | White-label brand under which the deposit was made. Predominantly "eToro" (~99.3%). Other values: eToroRussia, Royal-CM, eToroUSA, U-FOREX, ILQ, RetailFX, JCLyons. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 43 | DepositType | nvarchar(max) | YES | Type of deposit. Values: empty (standard one-time, ~97%), "Recurring payment", "Internal Transfer", "Regular payment". (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 44 | Threedsparameters | nvarchar(max) | YES | Raw 3D Secure authentication parameters for card deposits. Contains CAVV, ECI, and XID values in comma-separated format. Empty for non-card deposits. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 45 | MIDName | nvarchar(max) | YES | Merchant ID name identifying the payment processing configuration. Combines entity and gateway (e.g. "eToroEU", "eToroUK"). Empty for some older records. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 46 | MID | nvarchar(max) | YES | Merchant ID code for the payment processing configuration. Combines gateway and region (e.g. "CheckoutEUEEA", "WorldpayUK", "PayPalEU", "iDEALEU"). Empty for some older records. (Tier 3 — BackOffice.BillingDepositsPCIVersion) |
| 47 | UpdateDate | datetime | YES | ETL load timestamp. Set to `GETDATE()` when the row is inserted by SP_Fact_Deposit_Fees_DL_To_Synapse. Reflects when the row was loaded into the DWH, not when the deposit occurred. (Tier 2 — SP_Fact_Deposit_Fees_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-------------------|---------------|-----------|
| CID | BackOffice.BillingDepositsPCIVersion | CID | Passthrough |
| DepositStatus | BackOffice.BillingDepositsPCIVersion | DepositStatus | Passthrough |
| Threedsresponse | BackOffice.BillingDepositsPCIVersion | Threedsresponse | Passthrough |
| DepositRiskStatus | BackOffice.BillingDepositsPCIVersion | DepositRiskStatus | Passthrough |
| DepositAmount | BackOffice.BillingDepositsPCIVersion | DepositAmount | Passthrough |
| Currency | BackOffice.BillingDepositsPCIVersion | Currency | Passthrough |
| StatusModificationTime | BackOffice.BillingDepositsPCIVersion | StatusModificationTime | Passthrough |
| ModificationDateID | — | StatusModificationTime | `CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY, 0, StatusModificationTime), 0), 112))` |
| DepositTime–MID (36 cols) | BackOffice.BillingDepositsPCIVersion | Same name | Passthrough |
| UpdateDate | — | — | `GETDATE()` at insert time |

### 5.2 ETL Pipeline

```
BackOffice.BillingDepositsPCIVersion (production, etoro-REAL)
  |-- ADF: etoroBackOfficeToDataLake (Bronze export) ---|
  v
Data Lake: Bronze/BackOffice/BillingDepositsPCIVersion/
  |-- ADF: BackOffice-QG2-DLBronzetoSynapseSilver ---|
  v
DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion
  |-- SP_Fact_Deposit_Fees_DL_To_Synapse @dt ---|
  v
DWH_dbo.Fact_Deposit_Fees (14.4M rows, DORMANT since 2024-06-30)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees (UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|----------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension (join on CID = RealCID) |
| ModificationDateID | DWH_dbo.Dim_Date | Date dimension (join on ModificationDateID = DateID) |
| AffiliateID | DWH_dbo.Dim_Affiliate | Affiliate dimension |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Relationship | Description |
|--------------------|--------------|-------------|
| — | — | No known downstream consumers found in Synapse SSDT |

---

## 7. Sample Queries

### 7.1 Fee Revenue by Month

```sql
SELECT
    ModificationDateID / 100 AS YearMonth,
    COUNT(*) AS DepositCount,
    SUM(PIPsinUSD) AS TotalFeeUSD,
    AVG(PIPsinUSD) AS AvgFeeUSD
FROM DWH_dbo.Fact_Deposit_Fees
WHERE ModificationDateID BETWEEN 20230101 AND 20231231
GROUP BY ModificationDateID / 100
ORDER BY YearMonth
```

### 7.2 First-Time Deposits by Regulation

```sql
SELECT
    Regulation,
    COUNT(*) AS FTD_Count,
    SUM(DepositCollarAmount) AS TotalUSD
FROM DWH_dbo.Fact_Deposit_Fees
WHERE FTD = 'YES'
    AND ModificationDateID BETWEEN 20240101 AND 20240630
GROUP BY Regulation
ORDER BY FTD_Count DESC
```

### 7.3 Funding Method Mix by Quarter

```sql
SELECT
    ModificationDateID / 100 AS YearMonth,
    FundingMethod,
    COUNT(*) AS Cnt,
    SUM(DepositCollarAmount) AS VolumeUSD
FROM DWH_dbo.Fact_Deposit_Fees
WHERE ModificationDateID BETWEEN 20230101 AND 20240630
GROUP BY ModificationDateID / 100, FundingMethod
ORDER BY YearMonth, Cnt DESC
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources searched (regen harness mode — Atlassian scan skipped for dormant table).

---

*Generated: 2026-04-27 | Quality: 7.0/10 | Phases: 12/14*
*Tiers: 0 T1, 2 T2, 45 T3, 0 T4, 0 T5 | Elements: 47/47, Logic: 6/10, Lineage: 8/10*
*Object: DWH_dbo.Fact_Deposit_Fees | Type: Table | Production Source: BackOffice.BillingDepositsPCIVersion (dormant)*
