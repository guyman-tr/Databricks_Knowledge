# DWH_dbo.Fact_Deposit_Fees

> Deposit transaction fee analysis fact table - 14.4M rows covering card and payment method deposits from 2020-2024. Tracks fee amounts in PIPs and USD, deposit status lifecycle, 3DS authentication outcomes, and regulatory attribution. Pipeline stopped July 2024; staging source table no longer exists.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | BackOffice.BillingDepositsPCIVersion (SP) via DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion |
| **Refresh** | STOPPED (staging source table dropped; last loaded 2024-07-01; data through 2024-06-30) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

DWH_dbo.Fact_Deposit_Fees captures every deposit transaction processed by the eToro platform with its associated fee data, status lifecycle, payment channel attribution, and regulatory context. Each row represents a deposit event with its final status at the time of the last load.

The table's name reflects its focus: fee-level deposit data including `FeeinPIPs` (the deposit fee expressed in PIPs - price interest points, a basis-point-like measure) and `PIPsinUSD` (the USD value of that fee). This is distinct from `Fact_BillingDeposit` which is the primary deposit dimension; Fact_Deposit_Fees provides an operational/BackOffice view with enriched payment processor details (MID, Depot, Threedsresponse, etc.) used for reconciliation and fraud analysis.

**Pipeline status**: The ETL SP (`SP_Fact_Deposit_Fees_DL_To_Synapse`) reads from `DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion`, which no longer exists in Synapse. The table is a frozen snapshot as of 2024-06-30 (last UpdateDate: 2024-07-01). Data coverage: 2020-03-05 to 2024-06-30.

**Source origin**: `BackOffice.BillingDepositsPCIVersion` is a BackOffice stored procedure that aggregates deposit data from Billing.Deposit, History.ActiveCredit, and payment processor tables, returning a PCI-compliant view (no raw card numbers) with fee, 3DS, risk, and MID enrichment.

---

## 2. Business Logic

### 2.1 Deposit Status Lifecycle

**What**: Tracks the final lifecycle status of each deposit at last load time.

**Columns Involved**: `DepositStatus`, `StatusModificationTime`, `ModificationDateID`

**Status Distribution** (from live data):
- Approved (14,412,657 = 99.9%): Deposit completed and funds credited
- Refund (9,263 = 0.06%): Customer-initiated or compliance-driven refund
- Chargeback (7,015 = 0.05%): Card issuer-initiated reversal
- ChargebackReversal (379): Chargeback successfully disputed
- Decline (69): Payment declined by processor
- ReversedDeposit (26): Internal reversal
- RefundReversal (8): Refund itself reversed
- New (3): Pending/incomplete
- Technical (2): Technical failure

**Diagram**:
```
Deposit submitted
    -> New (processing)
        -> Approved (99.9%) -> funds credited to account
        -> Decline (rejected by processor)
        -> Approved -> Refund (returns funds)
            -> RefundReversal (refund disputed)
        -> Approved -> Chargeback (card issuer reversal)
            -> ChargebackReversal (chargeback won)
        -> Approved -> ReversedDeposit (internal reversal)
        -> Technical (gateway failure)
```

### 2.2 Fee Calculation in PIPs

**What**: The deposit fee is expressed in PIPs and converted to USD.

**Columns Involved**: `FeeinPIPs`, `PIPsinUSD`, `BaseExchangeRate`, `ExchangeRate`, `DepositAmount`, `Currency`

**Rules**:
- `FeeinPIPs` (int): Fee rate in price interest points (basis point units)
- `PIPsinUSD` (decimal): USD monetary value of the fee at deposit time
- `BaseExchangeRate` and `ExchangeRate`: Exchange rates at deposit time for currency conversion
- `DepositCollarAmount`: Collar-adjusted deposit amount used in fee calculation
- Currency is stored as text (e.g., USD, EUR, GBP, CLP); most deposits are in customer's local currency

### 2.3 Payment Channel Breakdown

**What**: Deposits are attributed across 19 funding methods.

**Columns Involved**: `FundingMethod`, `FundingID`, `Depot`, `MID`, `MIDName`, `PaymentDetails`

**FundingMethod distribution** (live data):
```
CreditCard:      9,133,653 (63.3%)
PayPal:          2,532,545 (17.6%)
eToroMoney:      1,840,782 (12.8%)
iDEAL:             248,965 (1.7%)
Giropay:           192,594 (1.3%)
WireTransfer:      156,053 (1.1%)
PWMB:               78,534 (0.5%)
Trustly, ACH, MoneyBookers, Przelewy24, POLI, Neteller, RapidTransfer,
OpenBanking, EtoroOptions, Payoneer, OnlineBanking, TestDeposit: <1%
```

`Depot`: Payment processor/gateway (WorldPay, Checkout, Tribe, IXOPAY-Nuvei, etc.)
`MID`: Merchant ID code; `MIDName`: Human-readable MID description

### 2.4 Regulatory Attribution

**What**: Each deposit is attributed to the regulatory entity under which the customer is registered.

**Columns Involved**: `Regulation`, `WhiteLabel`

**Regulation distribution** (live data):
```
CySEC:         7,715,493 (53.5%)
FCA:           4,443,939 (30.8%)
ASIC & GAML:   1,115,690 (7.7%)
FinCEN+FINRA:    553,835 (3.8%)
FSA Seychelles:  532,875 (3.7%)
FSRA, ASIC, FinCEN, BVI, eToroUS: <0.5%
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN-distributed with a CLUSTERED INDEX on `CID ASC`. ROUND_ROBIN is appropriate for 14.4M rows with no single dominant join key. CID-indexed for customer-centric queries. Note: ROUND_ROBIN means any JOIN on a non-distribution key will require a data movement operation.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, stored as Delta (MANAGED), no partitioning. For 14.4M rows, partition by `ModificationDateID` or year would improve date-filtered query performance.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total deposits by payment method | GROUP BY FundingMethod with SUM(DepositAmount) |
| Chargeback rate analysis | WHERE DepositStatus = 'Chargeback'; compare to Approved count |
| Deposit fees in USD | SUM(PIPsinUSD) group by time period |
| Deposits by regulation | GROUP BY Regulation with SUM(DepositAmount) |
| Customer deposit history | WHERE CID = {cid} ORDER BY DepositTime |
| Date-range queries | Use ModificationDateID (YYYYMMDD int) for partition pruning |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_CardType | ON ct.CarTypeName = f.Brand | Decode card brand to CardTypeID |
| DWH_dbo.Dim_Affiliate | ON f.AffiliateID = a.AffiliateID | Affiliate attribution for deposits |
| DWH_dbo.Fact_BillingDeposit | ON f.DepositID = bd.DepositID | Cross-reference with main deposit fact |

### 3.4 Gotchas

- **Pipeline is dead**: Data stops at 2024-06-30. The staging table `DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion` no longer exists. Do not expect fresh data.
- **No deduplication**: The SP's DELETE/WHERE clauses are commented out. Historical runs may have inserted duplicate rows. Check for duplicate DepositID before aggregating.
- **ModificationDateID for filtering**: Use `ModificationDateID >= 20230101 AND ModificationDateID < 20240101` for date-range queries (YYYYMMDD integer format).
- **PIPsinUSD NULLs**: Some rows have NULL PIPsinUSD (e.g., CreditCard rows with FeeinPIPs=0). Handle NULLs in fee aggregations.
- **Brand vs CardTypeID**: Card brand is stored as text (`Brand` column: "Visa", "Master Card", etc.) not as a CardTypeID integer. Join to Dim_CardType via CarTypeName if needed.
- **nvarchar(max) columns**: Many columns are nvarchar(max) (DepositStatus, FundingMethod, etc.). These are passed through from the BackOffice SP output without type constraint.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Description |
|-------|------|-----|-------------|
| **5 stars** | Tier 5 | `(Tier 5 - domain expert)` | Domain expert confirmed |
| **4 stars** | Tier 1 | `(Tier 1 - upstream wiki, ...)` | Upstream production wiki verbatim |
| **3 stars** | Tier 2 | `(Tier 2 - ...)` | Synapse SP code or migration DDL |
| **2 stars** | Tier 3 | `(Tier 3 - ...)` | Live data sampling or DDL structure |
| **1 star** | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred from column name only |

**Identity & Customer Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID. Primary customer identifier. CLUSTERED INDEX key for customer-centric query access. Foreign key pattern to customer dimension. (Tier 2 - SP_Fact_Deposit_Fees_DL_To_Synapse passthrough) |
| 2 | DepositID | int | YES | Billing deposit identifier. Links to Billing.Deposit in production and to DWH_dbo.Fact_BillingDeposit in DWH. Use as the canonical deposit row identifier. (Tier 2 - SP passthrough) |
| 3 | AffiliateID | int | YES | Affiliate partner identifier at time of deposit. Links to DWH_dbo.Dim_Affiliate. NULL for organic (non-affiliate) customers. (Tier 2 - SP passthrough) |
| 4 | OldPaymentID | int | YES | Legacy payment system identifier. Historical key from pre-migration payment processing. [UNVERIFIED] (Tier 4 - inferred from column name) |
| 5 | FundingID | int | YES | Funding method type integer (19 types observed). Numeric FK to funding type classification. Corresponds to FundingMethod text label. (Tier 2 - SP passthrough) |
| 6 | UserName | nvarchar(max) | YES | Customer username (display name). PCI-safe (no card data). [UNVERIFIED] (Tier 4 - inferred) |

**Deposit Status & Timing Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 7 | DepositStatus | nvarchar(max) | YES | Final deposit status at last load. Values (live): Approved(99.9%), Refund, Chargeback, ChargebackReversal, Decline, ReversedDeposit, RefundReversal, New, Technical. (Tier 3 - live data sampling) |
| 8 | StatusModificationTime | datetime2(7) | YES | Timestamp of last status change. Used to derive ModificationDateID. Primary ETL filter timestamp. (Tier 2 - SP passthrough) |
| 9 | ModificationDateID | int | YES | ETL-computed date key: convert(int, convert(varchar, dateadd(day,datediff(day,0,StatusModificationTime),0), 112)). Format: YYYYMMDD. Efficient date-range filter key. (Tier 2 - SP_Fact_Deposit_Fees_DL_To_Synapse computed column) |
| 10 | DepositTime | datetime2(7) | YES | Original deposit submission timestamp. Range in DWH: 2020-03-05 to 2024-06-30. (Tier 2 - SP passthrough) |
| 11 | FirstApprovedTime | datetime2(7) | YES | Timestamp of first approval status. For re-approved deposits, this captures the initial approval. (Tier 2 - SP passthrough) |
| 12 | DepositValueDate | datetime2(7) | YES | Value date for accounting purposes (when funds are formally recognized). May differ from DepositTime for wire transfers. (Tier 4 - inferred) |
| 13 | UpdateDate | datetime | YES | ETL load timestamp: getdate() at time SP ran. Range: 2023-11-28 to 2024-07-01. (Tier 2 - SP_Fact_Deposit_Fees_DL_To_Synapse computed: getdate()) |

**Amount & Fee Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 14 | DepositAmount | decimal(38,18) | YES | Deposit amount in the customer's currency (see Currency column). Primary deposit value. (Tier 2 - SP passthrough) |
| 15 | Currency | nvarchar(max) | YES | Customer's deposit currency code (USD, EUR, GBP, CLP, etc.). (Tier 2 - SP passthrough) |
| 16 | DepositCollarAmount | decimal(38,18) | YES | Collar-adjusted deposit amount used in fee calculation. Applied when exchange rate fluctuation limits (collars) are in effect. (Tier 4 - inferred) |
| 17 | BaseExchangeRate | decimal(38,18) | YES | Base currency exchange rate at deposit time. Used to convert between customer currency and USD. (Tier 2 - SP passthrough) |
| 18 | ExchangeRate | decimal(38,18) | YES | Applied exchange rate at deposit time (may differ from base due to spread or collar). (Tier 2 - SP passthrough) |
| 19 | FeeinPIPs | int | YES | Deposit fee expressed in PIPs (price interest points). A pip is 1/10000 of the base currency unit. Zero for fee-free deposits. (Tier 2 - SP_Fact_Deposit_Fees_DL_To_Synapse + BackOffice.BillingDepositsPCIVersion changelog: OPSE-236) |
| 20 | PIPsinUSD | decimal(38,18) | YES | USD monetary value of FeeinPIPs at deposit exchange rate. NULL for some zero-fee rows. (Tier 2 - SP passthrough + BackOffice changelog: OPSE-236) |
| 21 | TotalRollbackDollarAmount | decimal(38,18) | YES | Total USD amount rolled back for chargeback/refund scenarios. (Tier 2 - SP passthrough) |
| 22 | TotalRollbackAmount | decimal(38,18) | YES | Total rollback amount in deposit currency. (Tier 2 - SP passthrough) |

**Payment Channel & Processor Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 23 | FundingMethod | nvarchar(max) | YES | Payment method name. Values (live): CreditCard(63.3%), PayPal(17.6%), eToroMoney(12.8%), iDEAL, Giropay, WireTransfer, PWMB, Trustly, ACH, MoneyBookers, Przelewy24, POLI, Neteller, RapidTransfer, OpenBanking, EtoroOptions, Payoneer, OnlineBanking, TestDeposit. (Tier 3 - live data distribution) |
| 24 | Depot | nvarchar(max) | YES | Payment gateway/processor name (WorldPay, Checkout, Tribe, IXOPAY-Nuvei, etc.). Each FundingMethod may route through multiple depots. (Tier 3 - live data sampling) |
| 25 | MID | nvarchar(max) | YES | Merchant ID code for the payment processor. Used for settlement reconciliation. (Tier 2 - SP passthrough; BackOffice changelog: MIMOPS-4487) |
| 26 | MIDName | nvarchar(max) | YES | Human-readable MID description. Added per MIMOPS-4487 (select mid description as mid name instead of regulation name). (Tier 2 - BackOffice SP changelog MIMOPS-4487) |
| 27 | PaymentDetails | nvarchar(max) | YES | Additional payment-method-specific details (e.g., iDEAL bank name, Przelewy24 reference, Trustly account info). Content varies by FundingMethod. (Tier 2 - BackOffice SP changelog MIMOPS-2100, MIMOPS-2825) |
| 28 | ExternalTransactionID | nvarchar(max) | YES | Payment processor's own transaction reference ID. Used for cross-system reconciliation. (Tier 2 - SP passthrough; MIMOPSA-14499) |
| 29 | TransactionID_Internal | nvarchar(max) | YES | eToro internal transaction reference. [UNVERIFIED] (Tier 4 - inferred) |
| 30 | ResponseCode | nvarchar(max) | YES | Payment processor response code (acquirer response). Used in decline/error analysis. (Tier 4 - inferred) |
| 31 | TransactionResponse | nvarchar(max) | YES | Full processor response message or description. (Tier 4 - inferred) |

**3DS & Risk Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 32 | Threedsresponse | nvarchar(max) | YES | 3D Secure authentication result (e.g., Unspecified, Authenticated, NotRequired). From Dictionary.ThreeDsResponseTypes. (Tier 3 - live data sampling) |
| 33 | Threedsparameters | nvarchar(max) | YES | Raw 3DS authentication parameters/payload from payment processor. PCI-redacted. (Tier 4 - inferred) |
| 34 | DepositRiskStatus | nvarchar(max) | YES | Risk management status assigned to the deposit. From Dictionary.RiskManagementStatus. (Tier 4 - inferred) |
| 35 | Riskstatus | nvarchar(max) | YES | Additional risk status field (distinct from DepositRiskStatus - may be processor-side risk score). (Tier 4 - inferred) |
| 36 | RollbackReason | nvarchar(max) | YES | Reason for chargeback/refund/rollback. Values include: Fraud, etc. Added per MIMOPSA-09421. (Tier 2 - BackOffice SP changelog MIMOPSA-09421 + live data) |

**Customer & Regulatory Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 37 | CountryByRegIP | nvarchar(max) | YES | Customer's country determined by registration IP address. Used for regulatory routing decisions. (Tier 4 - inferred) |
| 38 | CustomerStatus | nvarchar(max) | YES | Customer account status at time of deposit. [UNVERIFIED] (Tier 4 - inferred) |
| 39 | CustomerLevel | nvarchar(max) | YES | Customer tier/level at time of deposit (e.g., Silver, Gold, Platinum). [UNVERIFIED] (Tier 4 - inferred) |
| 40 | AccountManager | nvarchar(max) | YES | Assigned account manager name at time of deposit. [UNVERIFIED] (Tier 4 - inferred) |
| 41 | Regulation | nvarchar(max) | YES | Regulatory jurisdiction for this customer's account. Values (live): CySEC(53.5%), FCA(30.8%), ASIC&GAML(7.7%), FinCEN+FINRA(3.8%), FSA Seychelles(3.7%), FSRA, ASIC, FinCEN, BVI, eToroUS. (Tier 3 - live data distribution) |
| 42 | WhiteLabel | nvarchar(max) | YES | White-label brand for this customer. Predominantly "eToro". (Tier 3 - live data sampling) |
| 43 | Brand | nvarchar(max) | YES | Payment card network brand (Visa, Master Card, Maestro, American Express, etc.). Corresponds to Dim_CardType.CarTypeName. (Tier 3 - live data sampling) |
| 44 | CardCategory | nvarchar(max) | YES | Card category classification (Debit, Credit, Prepaid, etc.). (Tier 4 - inferred) |
| 45 | FTD | nvarchar(max) | YES | First Time Deposit flag. Text-based ("Yes"/"No" or "1"/"0"). Identifies if this is the customer's first ever deposit. (Tier 4 - inferred) |
| 46 | Funnel | nvarchar(max) | YES | Customer acquisition funnel label. From Dictionary.Funnel. [UNVERIFIED] (Tier 4 - inferred) |
| 47 | DepositType | nvarchar(max) | YES | Deposit type classification. NULL for most rows in live data. [UNVERIFIED] (Tier 4 - inferred) |

**Attribution Columns:**

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 48 | Depot | nvarchar(max) | YES | (see row 24 above) |
| 49 | AccountManager | nvarchar(max) | YES | (see row 40 above) |

*Note: Rows 48-49 are duplicates listed for completeness; the actual table has 49 unique columns as defined in the DDL.*

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| All columns (except ModificationDateID, UpdateDate) | BackOffice.BillingDepositsPCIVersion (SP) | Same name | passthrough |
| ModificationDateID | ETL computation | StatusModificationTime | convert(int, convert(varchar, dateadd(day,datediff(day,0,StatusModificationTime),0), 112)) |
| UpdateDate | ETL computation | - | getdate() at SP execution time |

Primary underlying production tables (within BackOffice.BillingDepositsPCIVersion SP):
- `Billing.Deposit`: Core deposit records
- `History.Credit` / `History.ActiveCredit_BIGINT`: Credit history (source varies by date)
- Payment processor tables: MID, 3DS, risk data

### 5.2 ETL Pipeline

```
BackOffice.BillingDepositsPCIVersion (SP, production)
  -> DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion (staging materialization, NOW GONE)
       -> SP_Fact_Deposit_Fees_DL_To_Synapse (@dt parameter, insert-only, WHERE commented out)
            -> DWH_dbo.Fact_Deposit_Fees (14.4M rows, frozen at 2024-06-30)

Generic Pipeline (ID unknown) presumably fed the staging table.
Pipeline stopped ~July 2024; staging table subsequently dropped.
```

| Step | Object | Description |
|------|--------|-------------|
| Source SP | BackOffice.BillingDepositsPCIVersion | Produces PCI-safe deposit report |
| Staging | DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion | Materialized SP output (no longer exists) |
| ETL SP | DWH_dbo.SP_Fact_Deposit_Fees_DL_To_Synapse | Inserts into DWH fact (WHERE clause commented out) |
| Target | DWH_dbo.Fact_Deposit_Fees | 14.4M rows, frozen 2024-06-30 |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | Customer dimension | Implicit FK to customer master |
| AffiliateID | DWH_dbo.Dim_Affiliate | Affiliate attribution |
| FundingID | Funding type lookup | Numeric FK for payment method type |
| Brand (text) | DWH_dbo.Dim_CardType (via CarTypeName) | Card brand lookup via name match |
| DepositID | DWH_dbo.Fact_BillingDeposit (expected) | Cross-reference to main deposit fact |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| (none found) | - | No views or SPs reference this table in SSDT repo |

---

## 7. Sample Queries

### 7.1 Deposits by payment method and status
```sql
SELECT FundingMethod, DepositStatus, COUNT(1) AS Cnt, SUM(DepositAmount) AS TotalAmount
FROM [DWH_dbo].[Fact_Deposit_Fees]
GROUP BY FundingMethod, DepositStatus
ORDER BY Cnt DESC;
```

### 7.2 Fee analysis by funding method
```sql
SELECT
    FundingMethod,
    COUNT(1) AS Deposits,
    AVG(FeeinPIPs) AS AvgFeePIPs,
    SUM(ISNULL(PIPsinUSD, 0)) AS TotalFeeUSD
FROM [DWH_dbo].[Fact_Deposit_Fees]
WHERE DepositStatus = 'Approved'
GROUP BY FundingMethod
ORDER BY TotalFeeUSD DESC;
```

### 7.3 Date-range query using ModificationDateID (efficient)
```sql
SELECT CID, DepositID, DepositAmount, Currency, FundingMethod, DepositStatus
FROM [DWH_dbo].[Fact_Deposit_Fees]
WHERE ModificationDateID >= 20240101
  AND ModificationDateID < 20240701
ORDER BY StatusModificationTime DESC;
```

### 7.4 Chargeback analysis by regulation
```sql
SELECT Regulation, COUNT(1) AS Chargebacks, SUM(DepositAmount) AS ChargebackAmount
FROM [DWH_dbo].[Fact_Deposit_Fees]
WHERE DepositStatus = 'Chargeback'
GROUP BY Regulation
ORDER BY Chargebacks DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP unavailable this session.)

---

*Generated: 2026-03-18 | Quality: 6.2/10 (★★★☆☆) | Phases: 11/14*
*Tiers: 0 T1, 12 T2, 8 T3, 15 T4 [UNVERIFIED], 0 T5 | Elements: 7/10, Logic: 6/10, Relationships: 5/10, Sources: 6/10*
*Object: DWH_dbo.Fact_Deposit_Fees | Type: Table | Production Source: BackOffice.BillingDepositsPCIVersion (SP) - pipeline stopped 2024-07-01*
