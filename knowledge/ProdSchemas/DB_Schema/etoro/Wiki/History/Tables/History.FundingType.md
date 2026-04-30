# History.FundingType

> SQL Server system-versioned temporal history table for Dictionary.FundingType, recording every change to payment method (funding type) configurations including activation status, cashout eligibility, and payment generation classifications.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (FundingTypeID, ValidFrom, ValidTo) - no formal PK; temporal history semantics |
| **Partition** | No (stored on [DICTIONARY] filegroup) |
| **Indexes** | 1 (CLUSTERED on ValidTo ASC, ValidFrom ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Dictionary.FundingType`. SQL Server's system-versioning manages this table transparently: whenever a row in `Dictionary.FundingType` is inserted, updated, or deleted, the previous row state is written here with ValidFrom/ValidTo bracketing the validity window.

`Dictionary.FundingType` is a critical lookup table defining every payment method (funding type) available on eToro's platform. It controls which payment methods are active, whether cashout/withdrawal is supported, whether transactions are refundable, what the default currency is, and how the payment processor handles the method. With 44 funding types spanning legacy methods (BankDraft, WesternUnion) through modern payment rails (eToroCryptoWallet, OpenBanking, GCCInstantBankTransfer), the table represents eToro's entire payment processing landscape.

642 history rows span changes from September 2021 to March 2026, covering 39 distinct funding types. Notable mass-change events visible in the data: the PaymentGeneration upgrade from 0 to 1 across multiple active payment methods (indicating a payment system generation migration).

Unlike most other History schema temporal tables, this one uses SQL Server's native temporal versioning with **no INSERT trigger** - only UPDATE and DELETE events are captured.

---

## 2. Business Logic

### 2.1 Payment Method Registry

**What**: Each funding type defines a payment method with its operational capabilities and constraints.

**Columns/Parameters Involved**: `FundingTypeID`, `Name`, `IsFundingTypeActive`, `IsCashoutActive`, `IsRefundable`, `IsRedeemable`, `DefaultCurrency`, `MaxDepositAmount`

**Rules**:
- IsFundingTypeActive: 1 = method is available for deposits; 0 = method is disabled/legacy
- IsCashoutActive: 1 = method can be used for withdrawals (cashout); 0 = deposit-only method
- IsRefundable: 1 = deposits via this method can be refunded; 0 = non-refundable (e.g., crypto, wire transfers)
- IsRedeemable: 1 = method supports redemption flows (e.g., vouchers/wallet redemptions)
- DefaultCurrency: the currency ID that this payment method defaults to (e.g., 1=USD, 2=EUR, 3=GBP, 5=AUD, 38=CNY, 44=PLN)
- MaxDepositAmount: maximum deposit amount in cents or base currency units (e.g., 500000 for CryptoWallet)
- IsNewStyle: legacy/modern flag distinguishing old-style and new-style payment processing paths

**Known FundingType Values (as of 2026-03-19)**:

| ID | Name | Active | Cashout | Refundable | Redeemable | DefaultCurrency |
|----|------|--------|---------|------------|------------|-----------------|
| 1 | CreditCard | Yes | Yes | Yes | No | EUR(2) |
| 2 | WireTransfer | Yes | Yes | No | Yes | USD(1) |
| 3 | PayPal | Yes | Yes | No | No | - |
| 4 | BankDraft | No | - | - | - | - |
| 5 | WesternUnion | No | - | - | - | - |
| 6 | Neteller | Yes | Yes | No | Yes | - |
| 7 | NetellerOnePay | No | - | - | - | - |
| 8 | MoneyBookers | Yes | Yes | No | Yes | - |
| 9 | MoneyGram | No | - | - | - | - |
| 10 | WebMoney | No | Yes | No | Yes | - |
| 11 | Giropay | Yes | Yes | No | Yes | - |
| 12 | ELV | No | - | - | - | - |
| 13 | Direct24 | No | - | - | - | - |
| 14 | Payoneer (legacy) | No | - | - | - | - |
| 15 | Sofort | Yes | No | No | No | EUR(2) |
| 16 | InternalPayment | Yes | Yes | No | No | - |
| 17 | LocalBankWire | No | - | - | - | - |
| 18 | TestDeposit | Yes | Yes | No | No | - |
| 19 | IBDeposit | Yes | Yes | No | No | USD(1) |
| 20 | BankDetails | No | - | - | - | - |
| 21 | Yandex | No | Yes | No | No | - |
| 22 | UnionPay | Yes | Yes | No | No | CNY(38) |
| 23 | Qiwi | No | Yes | No | No | - |
| 24 | CashU | No | No | No | No | USD(1) |
| 25 | AliPay | No | No | No | No | CNY(38) |
| 26 | WeChat | No | No | No | No | CNY(38) |
| 27 | eToroCryptoWallet | Yes | Yes | No | No | - |
| 28 | OnlineBanking | Yes | Yes | No | Yes | USD(1) |
| 29 | ACH | No | Yes | No | No | USD(1) |
| 30 | RapidTransfer | Yes | No | No | Yes | EUR(2) |
| 31 | AstroPay | No | No | No | No | EUR(2) |
| 32 | PWMB | Yes | Yes | No | Yes | USD(1) |
| 33 | eToroMoney | Yes | Yes | No | No | EUR(2) |
| 34 | iDEAL | Yes | Yes | No | Yes | EUR(2) |
| 35 | Trustly | Yes | Yes | No | Yes | GBP(3) |
| 36 | Przelewy24 | Yes | Yes | No | Yes | PLN(44) |
| 37 | POLI | Yes | Yes | Yes | Yes | AUD(5) |
| 38 | OpenBanking | Yes | Yes | No | Yes | EUR(2) |
| 39 | Payoneer | Yes | Yes | Yes | Yes | USD(1) |
| 40 | NFT | Yes | Yes | No | No | - |
| 42 | EtoroOptions | Yes | Yes | No | Yes | USD(1) |
| 43 | GCCInstantBankTransfer | Yes | Yes | No | No | - |
| 44 | MoneyFarm | Yes | No | No | No | GBP(3) |

### 2.2 Payment Generation Classification

**What**: PaymentGeneration distinguishes current active payment processing paths from legacy/deprecated configurations.

**Columns/Parameters Involved**: `PaymentGeneration`

**Rules**:
- PaymentGeneration=0: legacy/inactive payment method (no active payment processor integration)
- PaymentGeneration=1: current payment generation - active processor integration
- History shows a mass migration event where many active funding types upgraded from PaymentGeneration=0 to PaymentGeneration=1 (reflecting a payment system generation upgrade)
- PaymentGeneration is used by Billing procedures to route deposit and cashout flows to the correct payment processor

### 2.3 Trace Column - Audit JSON

**What**: The Trace column captures the execution context at the time of any DML operation as a JSON string.

**Columns/Parameters Involved**: `Trace`

**Rules**:
- Computed in source: `concat('{"HostName": "', host_name(), '","AppName": "', app_name(), '","SUserName": "', suser_name(), '","SPID": "', @@spid, '","DBName": "', db_name(), '","ObjectName": "', object_name(@@procid), '"}')`
- Materialized in history as nvarchar(733) (max length of the concat result)
- Captures: host name, application name, SQL login, session ID, database name, calling stored procedure name
- Provides full audit context for every funding type configuration change

### 2.4 Single Funding Constraint

**What**: Some payment methods enforce that a customer can only have one active funding relationship at a time.

**Columns/Parameters Involved**: `IsSingleFunding`

**Rules**:
- IsSingleFunding=true: only one deposit/account can exist per customer for this funding type (e.g., IBDeposit=true = one IB relationship per customer)
- IsSingleFunding=false: multiple deposits or funding relationships allowed per customer

---

## 3. Data Overview

| FundingTypeID | Name | IsFundingTypeActive | PaymentGeneration | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|
| 27 | eToroCryptoWallet | 1 | 0 | 2025-09-09 | 2026-03-09 | PaymentGeneration upgraded from 0 to 1. Active for 181 days with old Gen 0 config before migration. |
| 1 | CreditCard | 1 | 0 | 2025-04-22 | 2026-03-09 | PaymentGeneration 0->1 migration. MaxDepositAmount=100000, DefaultCurrency=EUR. Refundable. |
| 32 | PWMB | 1 | 0 | 2021-09-19 | 2026-03-09 | Oldest history row - present since initial provisioning (2021-09-19), IsRedeemable=true, active. |
| 40 | NFT | 1 | 0 | 2022-08-11 | 2026-03-09 | NFT funding type added 2022-08. No DefaultCurrency, MaxDepositAmount=0 (unlimited). |
| 9 | 9 | 9 | 9 | 2025-12-25 | 2025-12-25 | INSERT capture pattern NOT used - this is pure temporal with no INSERT trigger. |

642 total history rows across 39 distinct FundingTypeIDs. Oldest record: 2021-09-19. Most recent superseded: 2026-03-09.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | CODE-BACKED | Identifier for the payment method type. NOT an IDENTITY in source - manually assigned IDs 1-44 (with gaps). Multiple history rows with same FundingTypeID = successive configuration versions. Used extensively in Billing schema procedures. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable name of the payment method. Examples: "CreditCard", "WireTransfer", "PayPal", "eToroCryptoWallet". Used in UI and reporting. Names are stable across versions (configuration changes rather than renaming). |
| 3 | IsNewStyle | bit | NO | - | CODE-BACKED | Distinguishes new-style (modern) from old-style payment processing paths. All active methods observed as IsNewStyle=true. Legacy value for backwards compatibility with older payment code paths. |
| 4 | IsSingleFunding | bit | NO | - | CODE-BACKED | 1 = only one active funding relationship allowed per customer (e.g., IBDeposit = single IB partner per customer). 0 = multiple funding relationships allowed. Used in Billing.GetCustomerLastFundingByFundingType to enforce single-funding constraints. |
| 5 | IsCashoutActive | bit | NO | - | VERIFIED | 1 = this payment method supports cashout/withdrawal. 0 = deposit-only (no cashout). Default 1 (IsCashoutActive=true) in source. Deposit-only examples: Sofort (15), MoneyFarm (44). |
| 6 | IsFundingTypeActive | tinyint | YES | - | VERIFIED | 0 = payment method is disabled (legacy/deprecated). 1 = active and available for customer use. NULL indicates unknown/unset status. Indexed with FundingTypeID in source for active-method lookups. |
| 7 | DefaultCurrency | int | YES | - | CODE-BACKED | Default currency for this payment method. References Dictionary.Currency (1=USD, 2=EUR, 3=GBP, 5=AUD, 38=CNY, 44=PLN). NULL for global methods without a default currency (e.g., CreditCard accepts multiple currencies). |
| 8 | MaxDepositAmount | int | YES | - | CODE-BACKED | Maximum deposit amount allowed via this method (in currency base units, likely cents or smallest denomination). NULL = no limit configured. 0 = unlimited or the method handles limits differently. |
| 9 | IsRefundable | bit | NO | - | VERIFIED | 1 = deposits can be refunded back to the source (e.g., POLI, Payoneer, CreditCard). 0 = non-refundable (most crypto/wallet methods). Default 0. Used in Billing refund eligibility checks. |
| 10 | IsCountryConflictActive | bit | YES | - | CODE-BACKED | 1 = country-level conflict rules are enforced for this funding type. NULL = not configured (most methods). 0 = no country conflict checking. Used by Billing.GetCountryConflictFundingType. Default 0. |
| 11 | PaymentGeneration | int | NO | - | CODE-BACKED | Payment processor generation classification. 0 = legacy/inactive generation. 1 = current active payment processing generation. A mass upgrade from 0 to 1 is visible in history data reflecting a platform-wide payment system migration. Default 0. |
| 12 | IsRedeemable | bit | NO | - | VERIFIED | 1 = method supports redemption flows (vouchers, wallet balances, partner accounts). Examples: WireTransfer, Neteller, MoneyBookers, Giropay, iDEAL, Trustly, OpenBanking. Default '0'. |
| 13 | Trace | nvarchar(733) | NO | - | CODE-BACKED | Computed JSON audit string capturing execution context at change time: HostName, AppName, SUserName (SQL login), SPID, DBName, ObjectName (calling procedure). Materialized from computed column in Dictionary.FundingType. Max 733 chars. Example: {"HostName": "SQLHOST01","AppName": ".Net SqlClient","SUserName": "app-svc","SPID": "87","DBName": "etoro","ObjectName": "Billing.UpdateFundingType"}. |
| 14 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version became active. SQL Server GENERATED ALWAYS AS ROW START column from the source table. Precision to 100-nanosecond ticks. |
| 15 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. CLUSTERED index leading column. Current rows in Dictionary.FundingType have ValidTo = 9999-12-31T23:59:59.9999999. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DefaultCurrency | Dictionary.Currency | Implicit | Links to the currency used by default for this payment method. FK enforced on source Dictionary.FundingType. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.FundingType | SYSTEM_VERSIONING | Temporal history source | All superseded row versions routed here automatically (no INSERT trigger - creation not captured). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.FundingType (table)
- no code-level dependencies (leaf table, temporal history)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.FundingType | Table | Source temporal table |
| Billing.GetDepositFundingType | Stored Procedure | Reads Dictionary.FundingType (current) for active deposit method lookup |
| Billing.GetCountryConflictFundingType | Stored Procedure | Reads Dictionary.FundingType for country-conflict enforcement |
| Billing.GetDepotsByFundingType | Stored Procedure | Reads by FundingTypeID for depot queries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_FundingType | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active (DATA_COMPRESSION=PAGE, on [DICTIONARY] filegroup) |

### 7.2 Constraints

None. Temporal history tables have no PK, FK, CHECK, UNIQUE, or DEFAULT constraints.

### 7.3 Important Notes

- **No INSERT trigger**: Unlike many other History schema temporal tables (FIXConnections, FeatureThresholdValues, etc.), this table has no INSERT trigger. Only UPDATE and DELETE operations on Dictionary.FundingType generate history rows. New row insertions are NOT captured in history.
- Stored on [DICTIONARY] filegroup - consistent with the source Dictionary.FundingType table.

---

## 8. Sample Queries

### 8.1 What was the configuration for a payment method on a specific date?

```sql
SELECT
    ft.FundingTypeID,
    ft.Name,
    ft.IsFundingTypeActive,
    ft.IsCashoutActive,
    ft.PaymentGeneration,
    ft.IsRefundable,
    ft.ValidFrom,
    ft.ValidTo
FROM Dictionary.FundingType FOR SYSTEM_TIME AS OF '2025-01-01T00:00:00' ft WITH (NOLOCK)
WHERE ft.FundingTypeID = @FundingTypeID;
```

### 8.2 Full change history for a funding type

```sql
SELECT
    h.FundingTypeID,
    h.Name,
    h.IsFundingTypeActive,
    h.PaymentGeneration,
    h.IsCashoutActive,
    h.IsRefundable,
    h.IsRedeemable,
    h.ValidFrom,
    h.ValidTo,
    DATEDIFF(DAY, h.ValidFrom, h.ValidTo) AS DaysActive,
    h.Trace
FROM History.FundingType h WITH (NOLOCK)
WHERE h.FundingTypeID = @FundingTypeID
ORDER BY h.ValidFrom;
```

### 8.3 All funding type changes in a time window

```sql
SELECT
    h.FundingTypeID,
    h.Name,
    h.IsFundingTypeActive,
    h.PaymentGeneration,
    h.ValidFrom,
    h.ValidTo,
    h.Trace
FROM History.FundingType h WITH (NOLOCK)
WHERE h.ValidTo >= @StartDate
  AND h.ValidTo < @EndDate
ORDER BY h.ValidTo DESC;
```

### 8.4 Active funding types with their cashout capabilities (current)

```sql
SELECT
    ft.FundingTypeID,
    ft.Name,
    ft.IsCashoutActive,
    ft.IsRefundable,
    ft.IsRedeemable,
    ft.DefaultCurrency,
    ft.MaxDepositAmount
FROM Dictionary.FundingType ft WITH (NOLOCK)
WHERE ft.IsFundingTypeActive = 1
ORDER BY ft.FundingTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.3/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Billing.GetDepositFundingType, Billing.GetCountryConflictFundingType) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FundingType | Type: Table | Source: etoro/etoro/History/Tables/History.FundingType.sql*
