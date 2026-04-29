# BI_DB_dbo.BI_DB_PTM_Levy_Report

> 8,312-row daily report of UK PTM (Panel on Takeovers and Mergers) Levy-eligible transactions from December 2023 to present -- capturing settled LSE positions (open and close) in GB/GG/JE/IM-prefixed ISINs with GBP equivalent >= 10,000, sourced from Dim_Position + Dim_Instrument + Fact_CurrencyPriceWithSplit via SP_Tax_PTM_Levy_Report.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + DWH_dbo.Dim_Instrument (Exchange='LSE', ISIN prefix GB/GG/JE/IM) + DWH_dbo.Fact_CurrencyPriceWithSplit (GBP/USD rate) via SP_Tax_PTM_Levy_Report |
| **Refresh** | Daily (DELETE+INSERT by Date) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_PTM_Levy_Report` is a UK tax compliance table tracking positions that are subject to the PTM (Panel on Takeovers and Mergers) Levy. The PTM Levy is a statutory charge on transactions in UK-listed securities where the sterling equivalent exceeds GBP 10,000. This table captures both opens and closes of settled (real stock, not CFD) positions on the London Stock Exchange (LSE) with ISIN prefixes indicating UK Crown Dependencies (GB, GG=Guernsey, JE=Jersey, IM=Isle of Man).

The ETL runs daily via `SP_Tax_PTM_Levy_Report` (Adi Meidan; Units column added 2024-03-27). For each date:
1. **Open positions**: From Dim_Position where OpenDateID = @DateID, IsSettled=1, IsPartialCloseChild=0, joined to Dim_Instrument (Exchange='LSE', ISIN prefix filter). USD amount from InitialAmountCents/100, converted to GBP using Fact_CurrencyPriceWithSplit.Bid (InstrumentID=2 = GBP/USD rate on that date). Filtered to GBP >= 10,000.
2. **Close positions**: Same logic but from CloseDateID, Amount field. No partial-close filter on closes. Filtered to GBP >= 10,000.
3. UNIONs opens and closes, then DELETE+INSERT into target by Date.

8,312 rows (4,398 opens, 3,914 closes) covering 1,478 distinct customers from Dec 2023 to Apr 2026. Average transaction size: ~GBP 24,500.

---

## 2. Business Logic

### 2.1 PTM Levy Eligibility Criteria

**What**: Multiple filters determine which transactions are PTM-reportable.

**Columns Involved**: `ISINCode`, `IsSettled`, `InitialAmount_GBP`, `TransactionType`

**Rules**:
- Exchange = 'LSE' (London Stock Exchange only)
- ISIN prefix must be GB, GG (Guernsey), JE (Jersey), or IM (Isle of Man)
- IsSettled = 1 (real stock transactions, not CFDs)
- GBP equivalent >= 10,000 (the PTM Levy threshold)
- IsPartialCloseChild = 0 for opens (avoids double-counting partial close children)

### 2.2 USD-to-GBP Conversion

**What**: Position amounts are stored in USD in Dim_Position. The SP converts to GBP using the daily exchange rate.

**Columns Involved**: `InitialAmount_USD`, `Bid`, `InitialAmount_GBP`

**Rules**:
- Bid = GBP/USD exchange rate from Fact_CurrencyPriceWithSplit where InstrumentID=2 and OccurredDateID = position open/close DateID
- InitialAmount_GBP = InitialAmount_USD / Bid
- For opens: InitialAmount_USD = InitialAmountCents / 100
- For closes: InitialAmount_USD = Amount (already in USD)
- The GBP 10,000 threshold is applied AFTER conversion

### 2.3 Dual Transaction Types

**What**: Each position can appear twice -- once when opened and once when closed.

**Columns Involved**: `TransactionType`, `Date`, `PositionID`

**Rules**:
- 'Open Position': Date = CAST(OpenOccurred AS DATE), amount from InitialAmountCents
- 'Close Position': Date = CAST(CloseOccurred AS DATE), amount from Amount
- The same PositionID can appear in both types on different dates
- Open and close amounts may differ (Amount vs InitialAmountCents/100)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **HASH(CID)** distribution -- efficient for per-customer aggregations
- **HEAP** -- no clustered index; use Date or PositionID filters for efficient scans

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily PTM levy exposure | `SELECT Date, SUM(InitialAmount_GBP) FROM ... GROUP BY Date` |
| Top instruments by volume | `GROUP BY Symbol, [Instrument Name]` |
| Per-customer PTM exposure | `GROUP BY CID` |
| Open vs close breakdown | `GROUP BY TransactionType` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer demographics for tax reporting |
| DWH_dbo.Dim_Position | PositionID = PositionID | Full position details |
| DWH_dbo.Dim_Instrument | ISINCode = ISINCode OR Symbol = Symbol | Full instrument metadata |

### 3.4 Gotchas

- **Column name with space**: `[Instrument Name]` has a space -- must be bracket-quoted in queries.
- **Dual entries per position**: A position that opens and closes above GBP 10,000 appears twice. Do not SUM without filtering TransactionType.
- **Bid is GBP/USD rate, not bid price**: The Bid column is the GBP/USD currency exchange rate, not the instrument's bid price. It comes from Fact_CurrencyPriceWithSplit InstrumentID=2.
- **IsSettled always 1**: The table only contains settled (real stock) positions. CFDs are excluded.
- **Amounts differ between opens/closes**: Opens use InitialAmountCents/100, closes use Amount. These can diverge if the position size changed.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data patterns |
| Tier 5 | Expert review / manually verified |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | YES | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 2 | InitialAmount_USD | money | YES | Position value in USD. For opens: InitialAmountCents/100 from Dim_Position. For closes: Amount from Dim_Position. (Tier 2 — SP_Tax_PTM_Levy_Report) |
| 3 | Bid | float | YES | GBP/USD exchange rate on the transaction date. From Fact_CurrencyPriceWithSplit where InstrumentID=2. Used to convert USD to GBP for PTM threshold check. (Tier 2 — SP_Tax_PTM_Levy_Report) |
| 4 | InitialAmount_GBP | money | YES | Position value in GBP. Computed as InitialAmount_USD / Bid. Only positions >= GBP 10,000 are included (PTM Levy threshold). Average ~GBP 24,500. (Tier 2 — SP_Tax_PTM_Levy_Report) |
| 5 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. Always 1 in this table (filtered in WHERE clause). (Tier 5 — Expert Review) |
| 6 | CID | int | YES | Customer ID. References Customer.Customer. Passthrough from Dim_Position.CID. HASH distribution key. (Tier 1 — Trade.PositionTbl) |
| 7 | ISINCode | varchar(100) | YES | International Securities Identification Number -- 12-character alphanumeric code standardized by ISO 6166. Filtered to GB/GG/JE/IM prefixes (UK Crown Dependencies). Passthrough from Dim_Instrument. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 8 | TransactionType | varchar(50) | YES | Hardcoded: 'Open Position' or 'Close Position'. Identifies whether this row represents a position opening or closing event. (Tier 2 — SP_Tax_PTM_Levy_Report) |
| 9 | Date | date | YES | Transaction date. CAST(OpenOccurred AS DATE) for opens, CAST(CloseOccurred AS DATE) for closes. Used for daily DELETE+INSERT partitioning. (Tier 2 — SP_Tax_PTM_Levy_Report) |
| 10 | Instrument Name | varchar(100) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Rolls-Royce', 'BP', 'AstraZeneca'). Passthrough from Dim_Instrument.InstrumentDisplayName. (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) |
| 11 | Symbol | varchar(20) | YES | Ticker symbol for the instrument (e.g., RR, BP, AZN, BATS, SMT.L). Used for display, search, and price feed identification. Passthrough from Dim_Instrument. (Tier 3 — live data, etoro.Trade.GetInstrument) |
| 12 | UpdateDate | date | YES | ETL metadata: date when this row was last inserted (GETDATE()). Note: type is date, not datetime. (Tier 2 — SP_Tax_PTM_Levy_Report) |
| 13 | Units | float | YES | Position size in units/shares. Fractional lots. Passthrough from Dim_Position.AmountInUnitsDecimal. Added 2024-03-27 by Adi Meidan. (Tier 1 — Trade.PositionTbl) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| PositionID | Trade.PositionTbl | PositionID | Passthrough via Dim_Position |
| InitialAmount_USD | Trade.PositionTbl | InitialAmountCents / Amount | Division by 100 (opens) / passthrough (closes) |
| Bid | Fact_CurrencyPriceWithSplit | Bid | Passthrough (InstrumentID=2, matched on DateID) |
| InitialAmount_GBP | ETL | — | Computed: InitialAmount_USD / Bid |
| IsSettled | Dim_Position | IsSettled | Passthrough (always 1) |
| CID | Trade.PositionTbl | CID | Passthrough via Dim_Position |
| ISINCode | Trade.InstrumentMetaData | ISINCode | Passthrough via Dim_Instrument |
| TransactionType | ETL | — | Hardcoded 'Open Position' / 'Close Position' |
| Date | Trade.PositionTbl | OpenOccurred / CloseOccurred | CAST to DATE |
| Instrument Name | Trade.InstrumentMetaData | InstrumentDisplayName | Passthrough via Dim_Instrument |
| Symbol | Trade.GetInstrument | Symbol | Passthrough via Dim_Instrument |
| UpdateDate | ETL | GETDATE() | ETL metadata |
| Units | Trade.PositionTbl | AmountInUnitsDecimal | Passthrough via Dim_Position |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (settled LSE positions, ISIN prefix GB/GG/JE/IM)
  |-- Open positions: OpenDateID = @DateID, IsSettled=1, IsPartialCloseChild=0
  |-- Close positions: CloseDateID = @DateID, IsSettled=1
  |
  |-- JOIN DWH_dbo.Dim_Instrument ON InstrumentID (Exchange='LSE', ISIN filter)
  |-- JOIN DWH_dbo.Fact_CurrencyPriceWithSplit ON DateID + InstrumentID=2 (GBP/USD rate)
  |
  |-- USD-to-GBP conversion: amount / Bid
  |-- GBP >= 10,000 threshold filter
  |-- UNION ALL opens + closes
  v
SP_Tax_PTM_Levy_Report @Date (daily DELETE+INSERT, Adi Meidan)
  v
BI_DB_dbo.BI_DB_PTM_Levy_Report (8,312 rows, HASH(CID))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| PositionID | DWH_dbo.Dim_Position | Position dimension |
| CID | DWH_dbo.Dim_Customer | Customer dimension via RealCID |
| ISINCode | DWH_dbo.Dim_Instrument | Instrument via ISIN |
| Symbol | DWH_dbo.Dim_Instrument | Instrument via ticker |

### 6.2 Referenced By (other objects point to this)

No known consumers in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Daily PTM Levy Exposure

```sql
SELECT Date, TransactionType,
       COUNT(*) AS transactions,
       SUM(InitialAmount_GBP) AS total_gbp
FROM BI_DB_dbo.BI_DB_PTM_Levy_Report
GROUP BY Date, TransactionType
ORDER BY Date DESC
```

### 7.2 Top Instruments by PTM Volume

```sql
SELECT Symbol, [Instrument Name],
       COUNT(*) AS transactions,
       SUM(InitialAmount_GBP) AS total_gbp,
       AVG(Units) AS avg_units
FROM BI_DB_dbo.BI_DB_PTM_Levy_Report
GROUP BY Symbol, [Instrument Name]
ORDER BY total_gbp DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 3 T1, 8 T2, 1 T3, 0 T4, 1 T5 | Elements: 13/13, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_PTM_Levy_Report | Type: Table | Production Source: Dim_Position + Dim_Instrument + Fact_CurrencyPriceWithSplit via SP_Tax_PTM_Levy_Report*
