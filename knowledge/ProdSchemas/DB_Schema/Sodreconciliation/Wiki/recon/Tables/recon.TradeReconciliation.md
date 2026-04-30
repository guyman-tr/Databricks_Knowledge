# recon.TradeReconciliation

> Stores trade-level reconciliation results comparing Apex Clearing's daily trade activity (EXT872) against eToro's internal trade data, highlighting discrepancies in quantities, prices, dates, and direction.

| Property | Value |
|----------|-------|
| **Schema** | recon |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (1 PK + 1 unique filtered NC + 1 NC on SodFileId) |

---

## 1. Business Meaning

This is the second core output table of the SOD reconciliation system. After the SOD Azure Function imports an EXT872 (Trade Activity) file, the reconciliation flow fetches eToro's internal trade data from the Data API, compares it against Apex trade records, and writes results here.

Each row represents a single trade comparison - matching an Apex trade to an eToro trade by order ID, account number, symbol, and trade date. Multiple fields are compared: quantity, price, date, and buy/sell direction. The `BreakValue` quantifies the overall discrepancy.

The reconciliation UI displays results, and corrections go through the Gateway API (tracked in fix.TradeReconciliationLogs, not in this table).

---

## 2. Business Logic

### 2.1 Trade Break Detection

**What**: Compares multiple trade attributes across Apex and eToro systems.

**Columns/Parameters Involved**: `ApexTradeQuantity`, `EtoroTradeQuantity`, `ApexTradePrice`, `EtoroTradePrice`, `ApexTradeDate`, `EtoroTradeDate`, `ApexTradeDirection`, `EtoroTradeDirection`, `BreakValue`

**Rules**:
- Quantity, price, date, and direction are each compared independently
- BreakValue summarizes the overall discrepancy magnitude (in dollar terms, computed as |ApexQty*ApexPrice - EtoroQty*EtoroPrice|)
- Direction codes: 'B' = Buy, 'S' = Sell, 'C' = Cover (short covering/close), 'U' = Unknown (default). 'C' appears in Apex data for short cover transactions
- Most breaks in practice are Apex-only trades (EtoroTradeQuantity=NULL, EtoroTradeDirection='U') where Apex recorded a trade that eToro's system does not have
- Trades are matched primarily by OrderId and TradeNumber
- Negative ApexTradeQuantity indicates a sell/short side of the trade

### 2.2 Trade Identity Linking

**What**: Links Apex and eToro trade identifiers for cross-reference.

**Columns/Parameters Involved**: `TradeActivityId`, `OrderId`, `TradeNumber`, `PositionId`, `MirrorId`

**Rules**:
- TradeActivityId: FK to apex.EXT872_TradeActivity.Id (the Apex trade row)
- OrderId: eToro's order identifier used for matching
- TradeNumber: Apex's trade number used for matching
- PositionId: eToro's position ID associated with this trade
- MirrorId: eToro's copy-trading mirror ID (non-zero for copied trades)

---

## 3. Data Overview

~1 million rows. Sample showing trade breaks (BreakValue <> 0) where Apex has trades not matched by eToro:

| Symbol | Cusip | ApexTradeQty | EtoroTradeQty | ApexPrice | EtoroPrice | ApexDir | EtoroDir | BreakValue | Meaning |
|---|---|---|---|---|---|---|---|---|---|
| HAL | 406216101 | 2.06327 | NULL | 36.35 | NULL | B | U | 75.00 | Halliburton buy at Apex not found in eToro. EtoroDir='U' (unknown). |
| TTE | 89151E109 | 18.37 | NULL | 54.45 | NULL | B | U | 1000.23 | TotalEnergies buy - large break value ($1000). Apex-only trade. |
| WEAT | 88166A508 | -2 | NULL | 11.61 | NULL | S | U | 23.22 | Wheat ETF sell at Apex not in eToro. |
| SOLO | 284849205 | -27 | NULL | 1.68 | NULL | S | U | 45.38 | Electrameccanica sell. ApexDir='S', quantity negative for sells. |
| VOOV | 921932703 | 0.34538 | NULL | 144.77 | NULL | B | U | 50.00 | Vanguard S&P500 Value buy - fractional share. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | - | CODE-BACKED | Primary key for the reconciliation result row. |
| 2 | SodFileId | uniqueidentifier | NO | - | VERIFIED | FK to apex.SodFiles.Id. Links to the EXT872 file import that triggered reconciliation. CASCADE DELETE. |
| 3 | TradeActivityId | uniqueidentifier | YES | - | VERIFIED | FK to apex.EXT872_TradeActivity.Id. The Apex trade row being compared. NULL when eToro has a trade that Apex does not. Unique filtered index ensures 1:1. |
| 4 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex account number (MASKED). |
| 5 | Cusip | varchar(12) | YES | - | CODE-BACKED | CUSIP of the traded security. |
| 6 | ApexTradeQuantity | decimal(28,10) | YES | - | VERIFIED | Trade quantity per Apex EXT872. |
| 7 | EtoroTradeQuantity | decimal(28,10) | YES | - | VERIFIED | Trade quantity per eToro Data API. |
| 8 | ApexTradePrice | decimal(28,10) | YES | - | VERIFIED | Execution price per Apex. |
| 9 | EtoroTradePrice | decimal(28,10) | YES | - | VERIFIED | Execution price per eToro. |
| 10 | ApexTradeDate | datetime2(7) | YES | - | VERIFIED | Trade date per Apex. |
| 11 | EtoroTradeDate | datetime2(7) | YES | - | VERIFIED | Trade date per eToro. |
| 12 | Symbol | varchar(35) | YES | - | CODE-BACKED | Ticker symbol of the traded security. |
| 13 | IsBuy | bit | YES | - | CODE-BACKED | eToro's buy/sell flag: 1=Buy, 0=Sell. Legacy field alongside the direction chars. |
| 14 | OrderId | varchar(35) | YES | - | CODE-BACKED | eToro order identifier. Primary matching key between systems. |
| 15 | InstrumentId | int | YES | - | CODE-BACKED | eToro internal instrument identifier. |
| 16 | PositionId | bigint | YES | - | CODE-BACKED | eToro position ID associated with this trade. |
| 17 | ApexTradeDirection | char(1) | NO | 'U' | VERIFIED | Apex trade direction: 'B'=Buy, 'S'=Sell, 'C'=Cover (short covering), 'U'=Unknown (default). Live data shows 'C' for short cover transactions alongside 'B' and 'S'. |
| 18 | EtoroTradeDirection | char(1) | NO | 'U' | VERIFIED | eToro trade direction: 'B'=Buy, 'S'=Sell, 'U'=Unknown (default). For Apex-only breaks (no eToro match), this remains 'U'. |
| 19 | BreakValue | decimal(28,2) | NO | - | VERIFIED | Quantified overall discrepancy. 0=matched, non-zero=break. |
| 20 | TradeNumber | varchar(15) | YES | - | CODE-BACKED | Apex trade number. Secondary matching key. |
| 21 | Hidden | bit | NO | CONVERT(bit,0) | VERIFIED | Whether suppressed in UI. 0=visible (default), 1=hidden. |
| 22 | MirrorId | int | YES | - | CODE-BACKED | eToro copy-trading mirror ID. Non-zero for trades that were auto-copied from another trader. Used for copy-trade reconciliation context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (ON DELETE CASCADE) | Links to the EXT872 file import |
| TradeActivityId | apex.EXT872_TradeActivity | FK | Links to the Apex trade row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SOD Reconciliation UI | N/A | Read | Displays trade reconciliation results |
| fix.TradeReconciliationLogs | N/A | Related | Tracks corrections applied to trade breaks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
recon.TradeReconciliation (table)
├── apex.SodFiles (table) [SodFileId FK]
└── apex.EXT872_TradeActivity (table) [TradeActivityId FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId (CASCADE DELETE) |
| apex.EXT872_TradeActivity | Table | FK from TradeActivityId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SOD Reconciliation UI | External | Reads and displays results |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeReconciliation | CLUSTERED PK | Id | - | - | Active |
| IX_TradeReconciliation_TradeActivityId | UNIQUE NC | TradeActivityId | - | WHERE TradeActivityId IS NOT NULL | Active |
| IX_TradeReconciliation_SodFileId | NC | SodFileId | - | - | Active |
| IX_AccountNumber | NC | AccountNumber, SodFileId, Symbol | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_TradeReconciliation_SodFiles_SodFileId | FOREIGN KEY | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| FK_TradeReconciliation_EXT872_TradeActivity_TradeActivityId | FOREIGN KEY | TradeActivityId -> apex.EXT872_TradeActivity.Id |
| (default) | DEFAULT | 'U' for ApexTradeDirection and EtoroTradeDirection |
| (default) | DEFAULT | CONVERT(bit,0) for Hidden |

---

## 8. Sample Queries

### 8.1 Find trade breaks for a date

```sql
SELECT tr.AccountNumber, tr.Symbol, tr.OrderId, tr.TradeNumber,
       tr.ApexTradeQuantity, tr.EtoroTradeQuantity,
       tr.ApexTradePrice, tr.EtoroTradePrice, tr.BreakValue
FROM recon.TradeReconciliation tr WITH (NOLOCK)
JOIN apex.SodFiles f WITH (NOLOCK) ON tr.SodFileId = f.Id
WHERE f.ProcessDate = '2026-04-10' AND tr.BreakValue <> 0 AND tr.Hidden = 0
ORDER BY ABS(tr.BreakValue) DESC;
```

### 8.2 Find direction mismatches

```sql
SELECT AccountNumber, Symbol, ApexTradeDirection, EtoroTradeDirection, BreakValue
FROM recon.TradeReconciliation WITH (NOLOCK)
WHERE ApexTradeDirection <> EtoroTradeDirection AND ApexTradeDirection <> 'U' AND EtoroTradeDirection <> 'U'
ORDER BY SodFileId DESC;
```

### 8.3 Reconciliation summary by date

```sql
SELECT f.ProcessDate,
       COUNT(*) AS TotalTrades,
       SUM(CASE WHEN tr.BreakValue = 0 THEN 1 ELSE 0 END) AS Matched,
       SUM(CASE WHEN tr.BreakValue <> 0 THEN 1 ELSE 0 END) AS Breaks
FROM recon.TradeReconciliation tr WITH (NOLOCK)
JOIN apex.SodFiles f WITH (NOLOCK) ON tr.SodFileId = f.Id
WHERE f.ProcessDate >= DATEADD(day, -7, GETDATE())
GROUP BY f.ProcessDate
ORDER BY f.ProcessDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | Flow 2: Trades data fetched if EXT872, compared to Apex, discrepancies written to recon.TradeReconciliation. UI allows manual corrections via Gateway API. |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: recon.TradeReconciliation | Type: Table | Source: Sodreconciliation/Sodreconciliation/recon/Tables/recon.TradeReconciliation.sql*
