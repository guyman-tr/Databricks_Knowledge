# History.Dividends

> Archive table for fully-paid stock dividend records - rows are moved here from Stocks.Dividends via OUTPUT...INTO when all customer positions for a dividend have been paid and the dividend lifecycle is complete.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | DividendID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on DividendID) |

---

## 1. Business Meaning

This table is the **paid dividend archive**. When eToro pays dividends to customers who held real stock positions on the ex-dividend date, the process runs through `Stocks.PayDividends`. Once all customer positions for a given dividend have been credited and paid, that dividend record is moved from the active `Stocks.Dividends` table into this archive.

The dividend lifecycle:
1. A stock dividend is declared and recorded in `Stocks.Dividends` (IsPaid=0).
2. `Stocks.PositionDividend` is populated with per-position payment calculations (one row per customer position that qualifies).
3. `Stocks.PayDividends` runs on a schedule, crediting each customer's balance and archiving completed records:
   - Customer balance credited via `Customer.SetBalance` (CreditTypeID=6)
   - Position dividend accumulated in `History.Position_Extra.Dividend`
   - Processed position rows moved to `History.PositionDividend`
   - Fully-paid dividend records moved here via `DELETE ... OUTPUT DELETED ... INTO History.Dividends`

The table currently has **0 rows** in this staging environment - no dividends have been processed to completion here.

**Schema difference from source**: `History.Dividends` does NOT include the `ConversionRate` column that exists in `Stocks.Dividends`. The `OUTPUT` statement in `Stocks.PayDividends` explicitly excludes it, meaning archived records lose the exchange rate used for currency conversion at payment time.

---

## 2. Business Logic

### 2.1 Archive-on-Completion Pattern (OUTPUT...INTO)

**What**: Dividend records are atomically deleted from Stocks.Dividends and inserted here in a single transaction.

**Columns/Parameters Involved**: All columns

**Rules**:
- `Stocks.PayDividends` uses `DELETE FROM Stocks.Dividends OUTPUT DELETED.* INTO History.Dividends` within a transaction that also archives paid `Stocks.PositionDividend` rows.
- Only dividends where `IsPaid=1` AND `PaymentDate < GETUTCDATE()` are archived.
- A dividend is only marked `IsPaid=1` once no unprocessed `PositionDividend` rows remain for it.
- The `IsPaid` column in this archive table is hardcoded to `1` in the OUTPUT statement - all rows here are fully paid dividends.
- The transaction ensures atomicity: if any error occurs, the DELETE from Stocks.Dividends is rolled back, keeping the live record intact.

**Diagram**:
```
Dividend declared: DividendID=500, AAPL, AmountPerShare=$0.25, PaymentDate=2024-02-15
  -> Stocks.Dividends: IsPaid=0
  -> Stocks.PositionDividend: rows for each AAPL position holder

Stocks.PayDividends runs on 2024-02-15:
  -> Each position holder credited via Customer.SetBalance
  -> Stocks.PositionDividend rows -> History.PositionDividend
  -> Stocks.Dividends IsPaid set to 1
  -> Stocks.Dividends row DELETED -> OUTPUT INTO History.Dividends (IsPaid=1)
```

### 2.2 Key Dividend Dates

**What**: Four dates define the dividend timeline.

**Columns/Parameters Involved**: `DeclarationDate`, `ExDate`, `RecordDate`, `PaymentDate`, `ProcessingDate`

**Rules**:
- `DeclarationDate`: when the company announced the dividend.
- `ExDate` (ex-dividend date): positions must be opened BEFORE this date to qualify. Positions opened on or after ExDate do NOT receive the dividend.
- `RecordDate`: the company's official shareholder-of-record date (typically ExDate + 2 settlement days).
- `PaymentDate`: when the company actually pays the dividend to shareholders. eToro credits customers on or after this date.
- `ProcessingDate`: when eToro's system calculated and queued the per-position dividend amounts in `Stocks.PositionDividend`.

---

## 3. Data Overview

The table currently contains **0 rows** in this staging environment. A representative paid dividend record would look like:

| DividendID | InstrumentID | DeclarationDate | ExDate | RecordDate | AmountPerShare | PaymentDate | ProcessingDate | IsPaid |
|---|---|---|---|---|---|---|---|---|
| 1 | 1234 (AAPL) | 2024-01-25 | 2024-02-09 | 2024-02-12 | 0.2500 | 2024-02-15 | 2024-02-08 | 1 |

Note: `IsPaid` is always `1` in this archive table (paid dividends only). All values represent completed, paid dividends moved from `Stocks.Dividends`.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | int | NO | - | CODE-BACKED | The dividend identifier, carried from Stocks.Dividends (IDENTITY there, NOT FOR REPLICATION). CLUSTERED PK in this archive table. Same DividendID exists in History.PositionDividend rows for the associated per-position payments. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The stock instrument (e.g., AAPL, MSFT) that declared this dividend. FK to Trade.InstrumentMetaData (implicit). Used to identify which positions qualified (positions in this instrument opened before ExDate). |
| 3 | DeclarationDate | datetime | NO | - | CODE-BACKED | UTC datetime when the company declared the dividend. The announcement date - marks when the dividend became known to the market. |
| 4 | ExDate | datetime | NO | - | VERIFIED | Ex-dividend date. Positions in this instrument must have been opened BEFORE this date to qualify for the dividend. The primary eligibility cutoff used when populating Stocks.PositionDividend. |
| 5 | RecordDate | datetime | NO | - | CODE-BACKED | The company's official shareholder-of-record date. Typically ExDate + 1-2 settlement days. Positions held as of this date receive the dividend (determined at the exchange level). |
| 6 | AmountPerShare | money | NO | - | VERIFIED | The dividend payment amount per share, in the instrument's native currency (typically USD for US stocks). Each qualifying customer's payment = AmountPerShare * shares_held. Stored as `money` type (4 decimal places). |
| 7 | PaymentDate | datetime | NO | - | VERIFIED | The date the company pays the dividend to shareholders. eToro credits customer accounts on or after this date (Stocks.PayDividends checks PaymentDate <= GETUTCDATE()). |
| 8 | ProcessingDate | datetime | NO | - | CODE-BACKED | When eToro's system calculated and queued per-position dividend amounts in Stocks.PositionDividend. NOT NULL in this archive (nullable in source Stocks.Dividends - indicates the source record was always processed before being paid and archived). |
| 9 | IsPaid | bit | NO | - | VERIFIED | Always 1 in this table. The OUTPUT statement in Stocks.PayDividends hardcodes `1` for IsPaid when archiving. All rows here represent fully-paid dividends. |

**Note**: `ConversionRate` exists in `Stocks.Dividends` (money, NULL) but is NOT present in this archive table. This column holds the currency conversion rate applied when the dividend was paid. It is excluded from the OUTPUT statement in Stocks.PayDividends, meaning the exchange rate used at payment time is not preserved in the archive.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DividendID | Stocks.Dividends | Implicit | The dividend record archived here originated from this table |
| InstrumentID | Trade.InstrumentMetaData | Implicit | The stock that paid this dividend |
| DividendID | History.PositionDividend | Implicit | Per-position payment records archived alongside this dividend |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Stocks.PayDividends | History.Dividends | Writer | Moves paid dividends here via DELETE...OUTPUT...INTO |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Dividends (table)
- Leaf node - no code-level dependencies
- Written from Stocks.Dividends (table) via Stocks.PayDividends (procedure)
- Related to History.PositionDividend (archived per-position payments)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Stocks.PayDividends | Stored Procedure | Writer - archives fully-paid dividend records here |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DividendDetails | CLUSTERED (PK) | DividendID ASC | - | - | Active |

**Filegroup**: [PRIMARY] - unlike most History schema tables which use [HISTORY].
**Storage**: No DATA_COMPRESSION specified (default = none).
**No replication**: No NOT FOR REPLICATION on the PK constraint (the IDENTITY is on the source table, not here).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DividendDetails | PRIMARY KEY (CLUSTERED) | Uniqueness on DividendID |

Note: The same constraint name `PK_DividendDetails` exists on both `History.Dividends` and `Stocks.Dividends`. This is allowed since they are in different schemas but is worth noting for disambiguation.

---

## 8. Sample Queries

### 8.1 View dividend history for a specific instrument
```sql
SELECT DividendID, InstrumentID, DeclarationDate, ExDate, RecordDate,
       AmountPerShare, PaymentDate, ProcessingDate
FROM [History].[Dividends] WITH (NOLOCK)
WHERE InstrumentID = 1234
ORDER BY PaymentDate DESC
```

### 8.2 Dividends paid in a date range (annual summary)
```sql
SELECT YEAR(PaymentDate) AS PaymentYear, MONTH(PaymentDate) AS PaymentMonth,
       COUNT(*) AS DividendCount,
       COUNT(DISTINCT InstrumentID) AS DistinctInstruments,
       SUM(AmountPerShare) AS TotalAmountPerShare
FROM [History].[Dividends] WITH (NOLOCK)
WHERE PaymentDate BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY YEAR(PaymentDate), MONTH(PaymentDate)
ORDER BY PaymentYear, PaymentMonth
```

### 8.3 Cross-reference: paid dividends with their per-position archives
```sql
SELECT hd.DividendID, hd.InstrumentID, hd.AmountPerShare, hd.PaymentDate,
       COUNT(pd.PositionDividendID) AS PaidPositions,
       SUM(pd.Amount) AS TotalPaid
FROM [History].[Dividends] hd WITH (NOLOCK)
LEFT JOIN [History].[PositionDividend] pd WITH (NOLOCK) ON hd.DividendID = pd.DividendID
GROUP BY hd.DividendID, hd.InstrumentID, hd.AmountPerShare, hd.PaymentDate
ORDER BY hd.PaymentDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Note: Table has 0 rows in staging - business logic inferred from Stocks.PayDividends SP code*
*Object: History.Dividends | Type: Table | Source: etoro/etoro/History/Tables/History.Dividends.sql*
