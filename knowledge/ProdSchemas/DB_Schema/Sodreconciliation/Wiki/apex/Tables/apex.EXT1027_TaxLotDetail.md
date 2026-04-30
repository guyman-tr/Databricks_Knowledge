# apex.EXT1027_TaxLotDetail

> Tax lot detail from Apex Clearing EXT1027 extract: cost basis, gains/losses, wash sales, and covered/uncovered status per lot.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores the daily tax lot detail from Apex Clearing's EXT1027 extract. Each row represents a single tax lot -- a specific purchase or acquisition of a security that is tracked separately for cost basis and gain/loss calculations. The data includes open and closed lot information, original cost, proceeds, realized gains/losses, wash sale adjustments, and covered/uncovered status under IRS cost basis reporting rules.

The EXT1027 data is essential for tax reporting (1099-B generation) and for providing accurate cost basis information to customers. It tracks each individual lot from acquisition through disposition, including wash sale disallowed losses and adjustments. This supports eToro's regulatory obligation to report accurate cost basis to the IRS.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT1027 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Tax Lot Lifecycle

**What**: Each lot tracks from acquisition to disposition.

**Columns Involved**: `TaxLotOpenBuyDate`, `TaxLotCloseSellDate`, `RealizedIndicator`, `LongTermShortTermIndicator`

**Rules**:
- TaxLotOpenBuyDate is when the lot was acquired
- TaxLotCloseSellDate is when the lot was sold/disposed (NULL for open lots)
- RealizedIndicator flags whether the gain/loss has been realized
- LongTermShortTermIndicator classifies the holding period for tax rates (long-term > 1 year)

### 2.2 Wash Sale Tracking

**What**: IRS wash sale rules require adjusting losses on repurchased securities.

**Columns Involved**: `WashSalesIndicator`, `WashSalesDisAllowed`, `WashSaleAdjustmentDate`, `WashSaleAdjustmentAmount`, `BuyBackIndicator`

**Rules**:
- WashSalesIndicator flags if the lot is affected by wash sale rules
- WashSalesDisAllowed is the portion of the loss disallowed under wash sale rules
- WashSaleAdjustmentAmount is added to the cost basis of the replacement lot
- BuyBackIndicator flags if the lot represents a wash sale repurchase

### 2.3 Covered vs. Uncovered

**What**: IRS rules distinguish lots acquired before and after cost basis reporting requirements.

**Columns Involved**: `CoveredIndicator`, `CostMethod`

**Rules**:
- CoveredIndicator = covered means the broker must report cost basis to the IRS
- CostMethod indicates the accounting method (FIFO, specific lot, average cost)

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT1027 file import. CASCADE DELETE. |
| 3 | RecordNumber | varchar(3) | YES | - | NAME-INFERRED | Record number within the extract file. |
| 4 | ClientNumber | varchar(3) | YES | - | CODE-BACKED | Apex client number identifier. |
| 5 | CorrespondentCode | varchar(5) | YES | - | CODE-BACKED | Correspondent firm code. |
| 6 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 7 | Currency | varchar(3) | YES | - | CODE-BACKED | ISO currency code for monetary values. |
| 8 | TRID | varchar(4) | YES | - | NAME-INFERRED | Transaction ID or record type identifier. |
| 9 | SequenceNumber | varchar(9) | YES | - | CODE-BACKED | Sequence number for ordering lots within the extract. |
| 10 | Cusip | varchar(12) | YES | - | CODE-BACKED | CUSIP identifier of the security. |
| 11 | SecurityType | varchar(4) | YES | - | CODE-BACKED | Security type classification code. |
| 12 | SymbolMSD | varchar(12) | YES | - | NAME-INFERRED | Symbol from the Master Security Database. |
| 13 | NumberMSD | varchar(12) | YES | - | NAME-INFERRED | Number from the Master Security Database. |
| 14 | TaxLotOpenBuyDate | datetime2(7) | YES | - | CODE-BACKED | Date the tax lot was opened (acquisition/buy date). |
| 15 | TaxLotCloseSellDate | datetime2(7) | YES | - | CODE-BACKED | Date the tax lot was closed (sale/disposition date). NULL for open lots. |
| 16 | SettlementDate | datetime2(7) | YES | - | CODE-BACKED | Settlement date of the transaction. |
| 17 | Quantity | decimal(19,5) | YES | - | CODE-BACKED | Number of shares/units in the tax lot. |
| 18 | Cost | decimal(19,2) | YES | - | CODE-BACKED | Total cost basis of the tax lot. |
| 19 | NetProceed | decimal(19,2) | YES | - | CODE-BACKED | Net proceeds from the sale (for closed lots). |
| 20 | RealizedGainLoss | decimal(19,2) | YES | - | CODE-BACKED | Realized gain or loss amount (NetProceed - Cost). |
| 21 | LongTermShortTermIndicator | varchar(1) | YES | - | CODE-BACKED | Long-term (L) or short-term (S) holding period classification for tax rates. |
| 22 | RealizedIndicator | varchar(1) | YES | - | CODE-BACKED | Flag indicating if the gain/loss has been realized (lot closed). |
| 23 | ZeroIndicator | varchar(1) | YES | - | NAME-INFERRED | Flag for zero-cost or zero-quantity lots. |
| 24 | LMBuyDateIndicator | varchar(1) | YES | - | NAME-INFERRED | Lot management buy date indicator/flag. |
| 25 | LMCostDateIndicator | varchar(1) | YES | - | NAME-INFERRED | Lot management cost date indicator/flag. |
| 26 | LMMarketValueIndicator | varchar(1) | YES | - | NAME-INFERRED | Lot management market value indicator/flag. |
| 27 | LMGainLossIndicator | varchar(1) | YES | - | NAME-INFERRED | Lot management gain/loss indicator/flag. |
| 28 | SecurityNumberMSD | varchar(9) | YES | - | NAME-INFERRED | Security number from Master Security Database. MASKED (PII). |
| 29 | DescriptionNumber | varchar(1) | YES | - | NAME-INFERRED | Number indicating which description line contains the primary name. |
| 30 | Description1 | nvarchar(30) | YES | - | CODE-BACKED | Security description line 1. |
| 31 | Description2 | nvarchar(30) | YES | - | CODE-BACKED | Security description line 2. |
| 32 | Description3 | nvarchar(30) | YES | - | CODE-BACKED | Security description line 3. |
| 33 | OpenBuyPrice | decimal(19,8) | YES | - | CODE-BACKED | Price per share at which the lot was acquired. |
| 34 | OpenBuyCostAmount | decimal(19,5) | YES | - | CODE-BACKED | Total cost amount of the open buy transaction. |
| 35 | OpenLotID | nvarchar(18) | YES | - | CODE-BACKED | Unique identifier for the open (buy) side of the lot. |
| 36 | ClosedLotID | nvarchar(18) | YES | - | CODE-BACKED | Unique identifier for the closed (sell) side of the lot. |
| 37 | WashSalesIndicator | nvarchar(2) | YES | - | CODE-BACKED | Flag indicating if the lot is affected by wash sale rules. |
| 38 | BuyBackIndicator | varchar(1) | YES | - | CODE-BACKED | Flag indicating if this lot is a wash sale repurchase. |
| 39 | OpenTransactionID | varchar(30) | YES | - | CODE-BACKED | Transaction ID for the opening (buy) transaction. |
| 40 | ClosedTransactionID | varchar(30) | YES | - | CODE-BACKED | Transaction ID for the closing (sell) transaction. |
| 41 | GiftIndicator | varchar(1) | YES | - | NAME-INFERRED | Flag indicating if the lot was acquired as a gift. |
| 42 | InheritanceIndicator | varchar(1) | YES | - | NAME-INFERRED | Flag indicating if the lot was acquired by inheritance. |
| 43 | WashSaleAdjustmentDate | datetime2(7) | YES | - | CODE-BACKED | Date of the wash sale adjustment. |
| 44 | CoveredIndicator | varchar(1) | YES | - | CODE-BACKED | Indicates if the lot is covered under IRS cost basis reporting rules. |
| 45 | WashSalesDisAllowed | decimal(19,5) | YES | - | CODE-BACKED | Portion of the loss disallowed under wash sale rules. |
| 46 | CostMethod | varchar(1) | YES | - | CODE-BACKED | Cost basis accounting method (FIFO, specific lot, average cost). |
| 47 | WashSaleAdjustmentAmount | decimal(19,5) | YES | - | CODE-BACKED | Wash sale adjustment amount added to replacement lot cost basis. |
| 48 | CostPerShare | decimal(19,8) | YES | - | CODE-BACKED | Cost basis per share. |
| 49 | UnadjustedAmount | decimal(19,8) | YES | - | NAME-INFERRED | Unadjusted cost or proceeds amount (before wash sale adjustments). |
| 50 | PrincipleAmount | decimal(19,5) | YES | - | NAME-INFERRED | Principal amount of the transaction. Note: column name has typo ("Principle"). |
| 51 | PrincipleCommissionFee | decimal(19,2) | YES | - | NAME-INFERRED | Commission and fees associated with the principal transaction. Note: column name has typo ("Principle"). |

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
apex.EXT1027_TaxLotDetail (table)
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
| PK_EXT1027_TaxLotDetail | CLUSTERED PK | Id | - | - | Active |
| IX_EXT1027_TaxLotDetail_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT1027_TaxLotDetail | PRIMARY KEY | Unique Id per row |
| FK_EXT1027_TaxLotDetail_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get open tax lots from the latest import

```sql
SELECT AccountNumber, Cusip, Description1, Quantity, Cost, CostPerShare,
       TaxLotOpenBuyDate, CoveredIndicator, CostMethod
FROM apex.EXT1027_TaxLotDetail WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1027 AND Status = 2 ORDER BY ProcessDate DESC)
  AND TaxLotCloseSellDate IS NULL
ORDER BY AccountNumber, Cusip, TaxLotOpenBuyDate;
```

### 8.2 Find lots affected by wash sale rules

```sql
SELECT AccountNumber, Cusip, Quantity, Cost, RealizedGainLoss,
       WashSalesDisAllowed, WashSaleAdjustmentAmount, WashSaleAdjustmentDate
FROM apex.EXT1027_TaxLotDetail WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1027 AND Status = 2 ORDER BY ProcessDate DESC)
  AND WashSalesIndicator IS NOT NULL
ORDER BY WashSalesDisAllowed DESC;
```

### 8.3 Summarize realized gains/losses by long-term vs short-term

```sql
SELECT LongTermShortTermIndicator,
       COUNT(*) AS LotCount,
       SUM(RealizedGainLoss) AS TotalGainLoss,
       SUM(CASE WHEN RealizedGainLoss > 0 THEN RealizedGainLoss ELSE 0 END) AS TotalGains,
       SUM(CASE WHEN RealizedGainLoss < 0 THEN RealizedGainLoss ELSE 0 END) AS TotalLosses
FROM apex.EXT1027_TaxLotDetail WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 1027 AND Status = 2 ORDER BY ProcessDate DESC)
  AND RealizedIndicator IS NOT NULL
GROUP BY LongTermShortTermIndicator;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 33 CODE-BACKED, 0 ATLASSIAN-ONLY, 18 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT1027_TaxLotDetail | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT1027_TaxLotDetail.sql*
