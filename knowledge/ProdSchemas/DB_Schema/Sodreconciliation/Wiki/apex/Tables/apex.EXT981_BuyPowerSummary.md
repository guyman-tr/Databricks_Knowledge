# apex.EXT981_BuyPowerSummary

> Account buying power summary from Apex Clearing EXT981 extract: equity, margin, requirements, SMA, and available to withdraw per account.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (1 PK + 2 NC) |

---

## 1. Business Meaning

This table stores the daily account-level buying power summary from Apex Clearing's EXT981 extract. Each row represents a comprehensive snapshot of an account's financial position including total equity, margin equity, maintenance and cash requirements, excess equity, buying power calculations (overnight, day-trade, Reg T), SMA (Special Memorandum Account), and available-to-withdraw amounts. It also includes market value breakdowns by position type (long equity, short equity, long option, short option).

The EXT981 data is critical for monitoring account health, margin compliance, and trading capacity. It enables eToro to verify that buying power displayed to customers matches the clearing firm's calculations and to identify accounts approaching margin call thresholds before they are triggered.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT981 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Buying Power Calculation

**What**: Multiple buying power metrics are tracked, each with calculated and issued values.

**Columns Involved**: `OvernightBuyingPowerCalculated`, `OvernightBuyingPowerIssued`, `DayTradeBuyingPowerIssued`, `RegTBuyingPowerCalculated`, `RegTBuyingPowerIssued`

**Rules**:
- Calculated values are system-derived based on equity and requirements
- Issued values may differ from calculated if Apex has applied manual overrides
- Overnight buying power determines how much can be purchased and held overnight
- Day trade buying power is typically 4x maintenance excess equity for pattern day traders
- Reg T buying power is based on the 50% initial margin requirement

### 2.2 Equity and Requirement Breakdown

**What**: Equity is tracked across margin and cash segments with associated requirements.

**Columns Involved**: `TotalEquity`, `MarginEquity`, `MarginRequirement`, `MarginExcessEquity`, `CashEquity`, `CashRequirement`, `CashExcessEquity`, `MarginRequirementWithConcentration`, `MarginExcessEquityWithConcentration`

**Rules**:
- MarginExcessEquity = MarginEquity - MarginRequirement
- Concentration requirements apply when positions are overly concentrated in a single security
- CashExcessEquity = CashEquity - CashRequirement

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT981 file import. CASCADE DELETE. |
| 3 | OvernightBuyingPowerID | int | YES | - | NAME-INFERRED | Apex internal identifier for the buying power calculation record. |
| 4 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 5 | Firm | varchar(2) | YES | - | CODE-BACKED | Clearing firm identifier. |
| 6 | OfficeCode | varchar(3) | YES | - | CODE-BACKED | Apex office/branch code associated with the account. |
| 7 | CorrespondentCode | varchar(4) | YES | - | CODE-BACKED | Correspondent firm code. |
| 8 | ProcessDate | smalldatetime | YES | - | CODE-BACKED | Business date of the Apex extract file. |
| 9 | CurrencyCode | varchar(3) | YES | - | CODE-BACKED | ISO currency code for all monetary values. |
| 10 | TotalEquity | decimal(28,10) | YES | - | CODE-BACKED | Total account equity (long market value - short market value + cash balances). |
| 11 | MarginEquity | decimal(28,10) | YES | - | CODE-BACKED | Equity in the margin segment of the account. |
| 12 | MarginRequirement | decimal(28,10) | YES | - | CODE-BACKED | Maintenance margin requirement for the margin segment. |
| 13 | MarginExcessEquity | decimal(28,10) | YES | - | CODE-BACKED | Excess equity above margin requirement (MarginEquity - MarginRequirement). |
| 14 | CashEquity | decimal(28,10) | YES | - | CODE-BACKED | Equity in the cash segment of the account. |
| 15 | CashRequirement | decimal(28,10) | YES | - | CODE-BACKED | Requirement for the cash segment. |
| 16 | CashExcessEquity | decimal(28,10) | YES | - | CODE-BACKED | Excess equity in the cash segment. |
| 17 | MarginRequirementWithConcentration | decimal(28,10) | YES | - | CODE-BACKED | Margin requirement including concentration surcharge for overweight positions. |
| 18 | MarginExcessEquityWithConcentration | decimal(28,10) | YES | - | CODE-BACKED | Excess equity after applying concentration requirement. |
| 19 | OvernightBuyingPowerCalculated | decimal(28,10) | YES | - | CODE-BACKED | System-calculated overnight buying power. |
| 20 | OvernightBuyingPowerIssued | decimal(28,10) | YES | - | CODE-BACKED | Overnight buying power issued to the account (may differ from calculated). |
| 21 | DayTradeBuyingPowerIssued | decimal(18,2) | YES | - | CODE-BACKED | Day trade buying power issued to the account. |
| 22 | RegTBuyingPowerCalculated | decimal(28,10) | YES | - | CODE-BACKED | Reg T buying power calculated (based on 50% initial margin). |
| 23 | RegTBuyingPowerIssued | decimal(28,10) | YES | - | CODE-BACKED | Reg T buying power issued to the account. |
| 24 | OvernightFactorCalculated | decimal(28,10) | YES | - | NAME-INFERRED | Calculated overnight leverage factor. |
| 25 | OvernightFactorIssued | decimal(28,10) | YES | - | NAME-INFERRED | Issued overnight leverage factor. |
| 26 | DayTradeFactorCalculated | decimal(28,10) | YES | - | NAME-INFERRED | Calculated day trade leverage factor. |
| 27 | DayTradeFactorIssued | decimal(28,10) | YES | - | NAME-INFERRED | Issued day trade leverage factor. |
| 28 | MarginEquityPercent | decimal(28,10) | YES | - | CODE-BACKED | Margin equity as a percentage of total position value. |
| 29 | PositionMarketValue | decimal(28,10) | YES | - | CODE-BACKED | Total market value of all positions. |
| 30 | LongEquityMarketValue | decimal(28,10) | YES | - | CODE-BACKED | Market value of long equity positions. |
| 31 | ShortEquityMarketValue | decimal(28,10) | YES | - | CODE-BACKED | Market value of short equity positions. |
| 32 | LongOptionMarketValue | decimal(28,10) | YES | - | CODE-BACKED | Market value of long option positions. |
| 33 | ShortOptionMarketValue | decimal(28,10) | YES | - | CODE-BACKED | Market value of short option positions. |
| 34 | TotalTradeBalance | decimal(28,10) | YES | - | CODE-BACKED | Total trade-date cash balance across all sub-accounts. |
| 35 | TotalSettleBalance | decimal(28,10) | YES | - | CODE-BACKED | Total settle-date cash balance across all sub-accounts. |
| 36 | CashTradeBalance | decimal(28,10) | YES | - | CODE-BACKED | Trade-date balance in the cash sub-account. |
| 37 | MarginTradeBalance | decimal(28,10) | YES | - | CODE-BACKED | Trade-date balance in the margin sub-account. |
| 38 | ShortTradeBalance | decimal(28,10) | YES | - | CODE-BACKED | Trade-date balance in the short sub-account. |
| 39 | MoneyMarketTradeBalance | decimal(28,10) | YES | - | CODE-BACKED | Trade-date balance in the money market sub-account. |
| 40 | CashSettleBalance | decimal(28,10) | YES | - | CODE-BACKED | Settle-date balance in the cash sub-account. |
| 41 | MarginSettleBalance | decimal(28,10) | YES | - | CODE-BACKED | Settle-date balance in the margin sub-account. |
| 42 | ShortSettleBalance | decimal(28,10) | YES | - | CODE-BACKED | Settle-date balance in the short sub-account. |
| 43 | MoneyMarketSettleBalance | decimal(28,10) | YES | - | CODE-BACKED | Settle-date balance in the money market sub-account. |
| 44 | FreeCash | decimal(28,10) | YES | - | CODE-BACKED | Free cash available without impacting margin requirements. |
| 45 | SMA | decimal(28,10) | YES | - | CODE-BACKED | Special Memorandum Account balance (Reg T excess). |
| 46 | AvailableToWithdraw | decimal(28,10) | YES | - | CODE-BACKED | Maximum cash amount available for withdrawal. |
| 47 | FutureBalance | decimal(28,10) | YES | - | NAME-INFERRED | Projected future cash balance after pending activity. |
| 48 | FutureEquity | decimal(28,10) | YES | - | NAME-INFERRED | Projected future equity after pending activity. |
| 49 | FutureRequirement | decimal(28,10) | YES | - | NAME-INFERRED | Projected future margin requirement after pending activity. |
| 50 | OptionsRequirement | decimal(28,10) | YES | - | CODE-BACKED | Margin requirement attributable to option positions. |
| 51 | NonOptionsRequirement | decimal(28,10) | YES | - | CODE-BACKED | Margin requirement attributable to non-option positions. |
| 52 | LastUpdate | datetime | YES | - | CODE-BACKED | Timestamp of the last update to this buying power record. |
| 53 | NonOptionsRequirementNotConcentrated | decimal(28,10) | YES | - | NAME-INFERRED | Non-option requirement excluding concentration surcharges. |
| 54 | TypeIUnavailableCashProceeds | decimal(28,10) | YES | - | NAME-INFERRED | Type I unavailable cash proceeds (free-riding restriction). |
| 55 | TypeIIUnavailableCashProceeds | decimal(28,10) | YES | - | NAME-INFERRED | Type II unavailable cash proceeds (liquidation restriction). |
| 56 | NetBalance | decimal(28,10) | YES | - | CODE-BACKED | Net cash balance across all sub-accounts. |
| 57 | SMACommitted | decimal(28,10) | YES | - | NAME-INFERRED | Portion of SMA committed to pending orders. |
| 58 | HighWaterMark | decimal(28,10) | YES | - | NAME-INFERRED | Highest equity value reached (used for day trade buying power calculation). |

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
apex.EXT981_BuyPowerSummary (table)
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
| PK_EXT981_BuyPowerSummary | CLUSTERED PK | Id | - | - | Active |
| IX_EXT981_BuyPowerSummary_SodFileId | NC | SodFileId | - | - | Active |
| ix_ProcessDate | NC | ProcessDate | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT981_BuyPowerSummary | PRIMARY KEY | Unique Id per row |
| FK_EXT981_BuyPowerSummary_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get buying power summary for latest import

```sql
SELECT AccountNumber, TotalEquity, MarginExcessEquity, OvernightBuyingPowerIssued,
       DayTradeBuyingPowerIssued, SMA, AvailableToWithdraw, ProcessDate
FROM apex.EXT981_BuyPowerSummary WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 981 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY TotalEquity DESC;
```

### 8.2 Find accounts with low margin excess

```sql
SELECT AccountNumber, MarginEquity, MarginRequirement, MarginExcessEquity,
       MarginEquityPercent, ProcessDate
FROM apex.EXT981_BuyPowerSummary WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 981 AND Status = 2 ORDER BY ProcessDate DESC)
  AND MarginExcessEquity < 1000 AND MarginRequirement > 0
ORDER BY MarginExcessEquity ASC;
```

### 8.3 Compare calculated vs issued buying power

```sql
SELECT AccountNumber, OvernightBuyingPowerCalculated, OvernightBuyingPowerIssued,
       (OvernightBuyingPowerCalculated - OvernightBuyingPowerIssued) AS Difference
FROM apex.EXT981_BuyPowerSummary WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 981 AND Status = 2 ORDER BY ProcessDate DESC)
  AND OvernightBuyingPowerCalculated <> OvernightBuyingPowerIssued
ORDER BY ABS(OvernightBuyingPowerCalculated - OvernightBuyingPowerIssued) DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 44 CODE-BACKED, 0 ATLASSIAN-ONLY, 14 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT981_BuyPowerSummary | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT981_BuyPowerSummary.sql*
