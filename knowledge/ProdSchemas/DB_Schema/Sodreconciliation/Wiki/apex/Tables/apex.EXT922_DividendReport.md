# apex.EXT922_DividendReport

> Dividend and interest report from Apex Clearing EXT922 extract: ex-dates, record dates, pay dates, dividend rates, and withholding per security and account.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (1 PK + 2 NC) |

---

## 1. Business Meaning

This table stores the daily dividend and interest report from Apex Clearing's EXT922 extract. Each row represents a dividend or interest event for a specific security and account combination, including key dates (ex-date, record date, pay date), the dividend/coupon rate, position quantities, and any withholding amounts. The data covers both equity dividends and fixed-income coupon payments.

The EXT922 data enables reconciliation of dividend and interest income. It provides the authoritative Apex view of what dividends are expected, what positions are entitled, and what amounts should be credited to customer accounts. This data can be cross-referenced with EXT869 cash activity to verify actual dividend payments match expectations.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT922 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Dividend Timeline

**What**: Each dividend event has multiple critical dates.

**Columns Involved**: `ExchangeDate`, `RecordDate`, `PayDate`

**Rules**:
- ExchangeDate (ex-date) is when the stock begins trading without the dividend
- RecordDate is the date shareholders must be on record to receive the dividend
- PayDate is when the dividend is actually paid to entitled shareholders
- Position at RecordDate determines entitlement

### 2.2 Bond Coupon Data

**What**: Fixed-income coupon information is included for bond positions.

**Columns Involved**: `CouponDate`, `FirstCouponDate`, `CouponRate`, `MaturityDate`

**Rules**:
- CouponRate holds the annual coupon rate for bonds
- CouponDate and FirstCouponDate track the coupon payment schedule
- MaturityDate is the bond's maturity date

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT922 file import. CASCADE DELETE. |
| 3 | ReportDate | datetime | YES | - | CODE-BACKED | Date the dividend/interest report was generated. |
| 4 | ReportNumber | varchar(12) | YES | - | CODE-BACKED | Apex report identifier number. |
| 5 | ReportName | varchar(20) | YES | - | CODE-BACKED | Name/title of the report. |
| 6 | Symbol | varchar(12) | YES | - | CODE-BACKED | Trading symbol of the security. |
| 7 | Cusip | varchar(12) | YES | - | CODE-BACKED | CUSIP identifier of the security. |
| 8 | Description1 | varchar(20) | YES | - | CODE-BACKED | Security description line 1. |
| 9 | Description2 | varchar(20) | YES | - | CODE-BACKED | Security description line 2. |
| 10 | Description3 | varchar(20) | YES | - | CODE-BACKED | Security description line 3. |
| 11 | SecurityTypeCode | varchar(30) | YES | - | CODE-BACKED | Security type classification code. |
| 12 | CurrencyCode | nvarchar(max) | YES | - | CODE-BACKED | ISO currency code for the dividend/interest payment. |
| 13 | ExchangeDate | datetime | YES | - | CODE-BACKED | Ex-dividend date (date the stock trades without the dividend). |
| 14 | RecordDate | datetime | YES | - | CODE-BACKED | Record date for dividend entitlement. |
| 15 | PayDate | datetime | YES | - | CODE-BACKED | Payment date when dividends/interest are distributed. |
| 16 | DividendRate | decimal(28,10) | YES | - | CODE-BACKED | Dividend or interest rate per share/unit. |
| 17 | MaturityDate | datetime | YES | - | CODE-BACKED | Bond maturity date (for fixed-income securities). |
| 18 | CouponDate | datetime | YES | - | CODE-BACKED | Next coupon payment date for bonds. |
| 19 | FirstCouponDate | datetime | YES | - | CODE-BACKED | First coupon payment date for newly issued bonds. |
| 20 | CouponRate | varchar(20) | YES | - | CODE-BACKED | Annual coupon rate for bonds (stored as string). |
| 21 | IssueDate | datetime | YES | - | CODE-BACKED | Original issue date of the security. |
| 22 | AccountNumber | varchar(20) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 23 | AccountType | varchar(15) | YES | - | CODE-BACKED | Account type code. |
| 24 | AccountName | varchar(50) | YES | - | CODE-BACKED | Account holder name. MASKED (PII). |
| 25 | Position | varchar(20) | YES | - | CODE-BACKED | Position quantity as a string value. |
| 26 | PositionQuantityLongOrShort | varchar(30) | YES | - | NAME-INFERRED | Indicates whether the position is long or short and its quantity. |
| 27 | DividendInterest | decimal(16,6) | YES | - | CODE-BACKED | Calculated dividend or interest amount for the account. |
| 28 | WithHoldAmount | decimal(9,6) | YES | - | CODE-BACKED | Tax withholding amount deducted from the dividend/interest. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (ON DELETE CASCADE) | Links to source file import |

### 5.2 Referenced By (other objects point to this)

No known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
apex.EXT922_DividendReport (table)
  └── apex.SodFiles (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EXT922_DividendReport | CLUSTERED PK | Id | - | - | Active |
| IX_EXT922_DividendReport_PayDate | NC | SodFileId, PayDate | - | - | Active |
| IX_EXT922_DividendReport_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT922_DividendReport | PRIMARY KEY | Unique Id per row |
| FK_EXT922_DividendReport_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get upcoming dividend payments

```sql
SELECT Symbol, Cusip, DividendRate, ExchangeDate, RecordDate, PayDate, AccountNumber, DividendInterest
FROM apex.EXT922_DividendReport WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 922 AND Status = 2 ORDER BY ProcessDate DESC)
  AND PayDate >= GETDATE()
ORDER BY PayDate, Symbol;
```

### 8.2 Find dividends with tax withholding

```sql
SELECT AccountNumber, Symbol, DividendRate, DividendInterest, WithHoldAmount, PayDate
FROM apex.EXT922_DividendReport WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 922 AND Status = 2 ORDER BY ProcessDate DESC)
  AND WithHoldAmount > 0
ORDER BY WithHoldAmount DESC;
```

### 8.3 Summarize dividend amounts by security

```sql
SELECT Symbol, Cusip, DividendRate, PayDate,
       COUNT(*) AS AccountCount, SUM(DividendInterest) AS TotalDividends
FROM apex.EXT922_DividendReport WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 922 AND Status = 2 ORDER BY ProcessDate DESC)
GROUP BY Symbol, Cusip, DividendRate, PayDate
ORDER BY TotalDividends DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT922_DividendReport | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT922_DividendReport.sql*
