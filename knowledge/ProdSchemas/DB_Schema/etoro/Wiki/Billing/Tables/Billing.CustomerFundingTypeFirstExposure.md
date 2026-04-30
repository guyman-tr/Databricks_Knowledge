# Billing.CustomerFundingTypeFirstExposure

> First-exposure log table tracking the earliest date a customer encountered each payment method (funding type) - each row represents the unique first time a specific customer used or was presented with a specific funding type.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | Id (IDENTITY PK) |
| **Partition** | No (PRIMARY filegroup, FILLFACTOR 95) |
| **Indexes** | 2 (PK clustered + NC covering on CID, FundingTypeID) |

---

## 1. Business Meaning

`Billing.CustomerFundingTypeFirstExposure` records the first time each customer interacted with each payment method at eToro. One row per (CID, FundingTypeID) combination - subsequent encounters with the same payment method by the same customer are silently ignored by the insert procedure's deduplication logic.

The primary business use case is tracking **eToroMoney onboarding**: `Billing.GetCustomerDepositInfo` reads this table specifically for FundingTypeID=33 (eToroMoney) to return the customer's `eToroMoneyExposureDate` - the moment they first encountered the eToroMoney payment option. This is used in the deposit info payload sent to the client application, enabling the front-end to tailor the experience for customers who have or haven't yet been introduced to eToroMoney.

While all 40+ payment types are theoretically tracked, eToroMoney (FundingTypeID=33) dominates with 2,037 of 4,952 rows (41%), followed by CreditCard (FundingTypeID=1) with 1,503 rows (30%). The table was provisioned in July 2022 (PAYIL-4744) and is actively maintained through March 2026.

The covering index `IX_BCFTF_Cover` on `(CID, FundingTypeID)` with includes of `(Id, ExposureDate)` is specifically optimized for two access patterns: the INSERT-if-not-exists check (does this CID+FundingTypeID already exist?) and the lookup query (get ExposureDate for this CID+FundingTypeID).

---

## 2. Business Logic

### 2.1 Insert-If-Not-Exists (First-Exposure Deduplication)

**What**: Records only the first encounter between a customer and a funding type. Subsequent calls for the same (CID, FundingTypeID) pair are no-ops.

**Columns/Parameters Involved**: `CID`, `FundingTypeID`, `ExposureDate`

**Rules**:
- `Billing.CustomerFundingTypeFirstExposureUpdate(@CID, @FundingTypeID)` is the sole write path.
- The procedure uses INSERT ... SELECT ... LEFT JOIN WHERE NULL pattern:
  ```sql
  INSERT INTO [Billing].[CustomerFundingTypeFirstExposure] (CID, FundingTypeID, ExposureDate)
  SELECT @CID, @FundingTypeID, GETUTCDATE()
  FROM (SELECT @CID CID, @FundingTypeID FundingTypeID) AS List
      LEFT JOIN [Billing].[CustomerFundingTypeFirstExposure] tst
          ON tst.CID = List.CID AND tst.FundingTypeID = List.FundingTypeID
  WHERE tst.Id IS NULL;
  ```
- The LEFT JOIN + IS NULL check efficiently uses `IX_BCFTF_Cover` to detect duplicates without a separate SELECT.
- If the (CID, FundingTypeID) pair already exists: zero rows inserted (silent no-op).
- If new: one row inserted with ExposureDate = GETUTCDATE() (UTC timestamp of first exposure).
- No transaction or locking beyond the default - a concurrent double-insert could create duplicates, but the expected call pattern serializes per customer.

### 2.2 eToroMoney Exposure Date Lookup

**What**: The deposit info procedure queries this table specifically for eToroMoney (FundingTypeID=33) to drive client-side presentation logic.

**Columns/Parameters Involved**: `CID`, `FundingTypeID`, `ExposureDate`

**Rules**:
- `Billing.GetCustomerDepositInfo(@CID)` reads result set #31: `SELECT TOP(1) ExposureDate AS eToroMoneyExposureDate FROM [Billing].[CustomerFundingTypeFirstExposure] WHERE CID = @CID AND FundingTypeID = 33`
- Returns NULL if the customer has never been exposed to eToroMoney (no row exists).
- Returns the UTC datetime of first exposure if the customer has seen eToroMoney.
- The client application uses this to determine if eToroMoney is a new or familiar option for this customer.

---

## 3. Data Overview

| FundingTypeID | Name | CustomerCount | % of Total | Notes |
|--------------|------|--------------|------------|-------|
| 33 | eToroMoney | 2,037 | 41% | Dominant - primary tracked use case |
| 1 | CreditCard | 1,503 | 30% | Second largest - standard payment |
| 24 | CashU | 52 | 1% | - |
| 32 | PWMB | 48 | 1% | - |
| 6 | Neteller | 46 | 1% | - |
| 40 | NFT | 45 | 1% | - |
| 36 | Przelewy24 | 44 | 1% | - |
| 5 | WesternUnion | 44 | 1% | - |
| 3 | PayPal | 43 | 1% | - |
| Others (31 types) | Various | ~1,090 | 22% | 24-43 rows each |
| 0 | Unknown | 1 | <1% | Anomalous - FundingTypeID=0 not in Dictionary |

Total: 4,952 rows | Date range: 2023-01-05 to 2026-03-02

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key. Auto-incremented, no business significance. FILLFACTOR 95 on clustered PK. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer who was exposed to the funding type. Explicit FK to Customer.CustomerStatic(CID) via constraint FK_CCST_CFTFE. Part of the covering index key. Used in the deduplication check and lookup queries: `WHERE CID = @CID`. |
| 3 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method the customer was first exposed to. Implicit FK to Dictionary.FundingType. Observed values: 1=CreditCard, 2=WireTransfer, 3=PayPal, 5=WesternUnion, 6=Neteller, 8=MoneyBookers, 10=WebMoney, 11=Giropay, 12=ELV, 13=Direct24, 14=Payoneer, 15=Sofort, 16=InternalPayment, 17=LocalBankWire, 18=TestDeposit, 19=IBDeposit, 20=BankDetails, 21=Yandex, 22=UnionPay, 23=Qiwi, 24=CashU, 25=AliPay, 26=WeChat, 27=eToroCryptoWallet, 28=OnlineBanking, 29=ACH, 30=RapidTransfer, 31=AstroPay, 32=PWMB, 33=eToroMoney, 34=iDEAL, 35=Trustly, 36=Przelewy24, 37=POLI, 38=OpenBanking, 39=Payoneer, 40=NFT. Part of the covering index key (position 2). |
| 4 | ExposureDate | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp of first exposure. Auto-populated via DEFAULT (getutcdate()) when no explicit value is passed. The writer procedure calls GETUTCDATE() explicitly rather than relying on the DEFAULT. Precision: millisecond. Note: constraint name contains a typo ("ExpoaureDate" instead of "ExposureDate") - cosmetic only, no functional impact. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Explicit FK (FK_CCST_CFTFE) | Enforces referential integrity: only valid eToro customers can have exposure records. |
| FundingTypeID | Dictionary.FundingType | Implicit FK | Identifies which payment method the customer was first exposed to. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CustomerFundingTypeFirstExposureUpdate | @CID, @FundingTypeID | WRITER | Inserts first-exposure record using INSERT-if-not-exists pattern. Only write path. |
| Billing.GetCustomerDepositInfo | CID, FundingTypeID=33 | READER | Reads eToroMoney exposure date (result set #31) as part of deposit info payload returned to client. |

---

## 6. Dependencies

### 6.0 Dependency Chain

Customer.CustomerStatic -> Billing.CustomerFundingTypeFirstExposure

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | CID FK target - customer must exist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerFundingTypeFirstExposureUpdate | Stored Procedure | WRITER - inserts first-exposure records (INSERT-if-not-exists) |
| Billing.GetCustomerDepositInfo | Stored Procedure | READER - returns eToroMoney exposure date in deposit info result set |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingCustomerFundingTypeFirstExposure | CLUSTERED PK | Id ASC | - | - | Active |
| IX_BCFTF_Cover | NONCLUSTERED (covering) | CID ASC, FundingTypeID ASC | Id, ExposureDate | - | Active |

`IX_BCFTF_Cover` covers both the INSERT-if-not-exists LEFT JOIN check and the `GetCustomerDepositInfo` lookup, returning all needed columns from the index without touching the base clustered index.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingCustomerFundingTypeFirstExposure | PRIMARY KEY | Id - unique row identifier |
| FK_CCST_CFTFE | FOREIGN KEY | CID -> Customer.CustomerStatic(CID) - WITH CHECK enforced |
| DF_CustomerFundingTypeFirstExposure_ExpoaureDate | DEFAULT | getutcdate() - auto-stamps exposure time in UTC (note: constraint name has typo "ExpoaureDate") |

---

## 8. Sample Queries

### 8.1 Check if a customer has been exposed to eToroMoney

```sql
SELECT TOP(1) ExposureDate AS eToroMoneyExposureDate
FROM [Billing].[CustomerFundingTypeFirstExposure] WITH (NOLOCK)
WHERE CID = @CID AND FundingTypeID = 33;
```

### 8.2 Get all funding type exposures for a customer

```sql
SELECT cfe.FundingTypeID, ft.Name AS FundingTypeName, cfe.ExposureDate
FROM [Billing].[CustomerFundingTypeFirstExposure] cfe WITH (NOLOCK)
LEFT JOIN [Dictionary].[FundingType] ft WITH (NOLOCK) ON cfe.FundingTypeID = ft.FundingTypeID
WHERE cfe.CID = @CID
ORDER BY cfe.ExposureDate ASC;
```

### 8.3 Funding types ranked by distinct customer exposures

```sql
SELECT ft.Name AS FundingTypeName, COUNT(*) AS UniqueCustomers
FROM [Billing].[CustomerFundingTypeFirstExposure] cfe WITH (NOLOCK)
LEFT JOIN [Dictionary].[FundingType] ft WITH (NOLOCK) ON cfe.FundingTypeID = ft.FundingTypeID
GROUP BY ft.Name
ORDER BY UniqueCustomers DESC;
```

### 8.4 Monthly new eToroMoney exposure trend

```sql
SELECT YEAR(ExposureDate) AS Yr, MONTH(ExposureDate) AS Mo, COUNT(*) AS NewExposures
FROM [Billing].[CustomerFundingTypeFirstExposure] WITH (NOLOCK)
WHERE FundingTypeID = 33
GROUP BY YEAR(ExposureDate), MONTH(ExposureDate)
ORDER BY Yr DESC, Mo DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| PAYIL-4744 | Jira (code comment) | Initial version created by Elrom B., 07/08/2022. Ticket not accessible via API (archived/gone). Establishes the table's origin as a feature tracking eToroMoney first exposure. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira (PAYIL-4744 archived) | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CustomerFundingTypeFirstExposure | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.CustomerFundingTypeFirstExposure.sql*
