# Trade.GetActiveIndexDividends

> Filtered view of Trade.IndexDividends exposing only pending and correction-pending dividends for CFD and REAL position types, excluding ILLEGAL.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | DividendID (from base table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetActiveIndexDividends is a filtered view over Trade.IndexDividends that exposes only dividend events which are **active** in the processing pipeline. "Active" means the dividend is either pending (Status=0) or correction-pending (Status=4), and the position type is valid (not ILLEGAL). This view answers: "Which dividends need processing or are awaiting payment?"

The view exists so the DividendsApp service and dividend-related procedures can query only the subset of dividends that are actionable. Without it, callers would need to repeat the WHERE (Status IN (0,4) AND PositionType <> 255) filter everywhere. Trade.GetCIDsForIndexDividends, Trade.GetDividendsForSnapshot, and the Index Dividend Process all depend on this filtered set.

Data flows: The view reads from Trade.IndexDividends with NOLOCK. Rows are created by Trade.InsertIndexDividend, Trade.InsertDividend, and Trade.Merge_IndexDividends_DryRun. Status advances from 0/4 to 1 (In Progress) when PaymentDate passes, then to 2 (Completed). Once Status leaves 0 or 4, rows disappear from this view.

---

## 2. Business Logic

### 2.1 Active Status Filter

**What**: Only dividends in pending or correction-pending state appear in the view.

**Columns/Parameters Involved**: `Status`

**Rules**:
- Status=0 (Pending): New dividend, default. Can be deleted. Ready for snapshot when PaymentDate passes.
- Status=4 (Correction Pending): Correction dividend (CorrectionDividendID is not NULL). Treated like 0 for active listing.
- Status=1 (In Progress) and Status=2 (Completed) are excluded - those dividends have moved past the "active" stage.

**Diagram**:
```
Status IN (0, 4) -> IN view (active)
Status IN (1, 2) -> EXCLUDED (already processing or done)
```

### 2.2 Position Type Exclusion

**What**: PositionType=255 (ILLEGAL) is excluded from the view.

**Columns/Parameters Involved**: `PositionType`

**Rules**:
- PositionType=0 (CFD): Dividend applies to CFD holders. Included.
- PositionType=1 (REAL): Dividend applies to REAL stock holders. Included.
- PositionType=255 (ILLEGAL): System placeholder. Excluded - never used for real dividend processing.

---

## 3. Data Overview

| DividendID | InstrumentID | PositionType | Status | ExDate | PaymentDate | DividendValueInCurrency | DividendCurrencyID | Meaning |
|---|---|---|---|---|---|---|---|---|
| 84 | 1180 | 1 | 0 | 2024-02-19 | 2024-02-19 | 10.0161 | 1 | Pending REAL dividend in USD. Will advance to Status=1 when PaymentDate passes. |
| 86 | 1180 | 1 | 0 | 2024-02-19 | 2024-02-19 | 0.0129 | 3 | Same instrument, different currency (CurrencyID=3). Illustrates multi-currency dividends. |
| 87 | 1180 | 0 | 0 | 2024-02-09 | 2024-02-09 | 10.0091 | 2 | CFD dividend for same instrument. CFD and REAL have separate rows per instrument. |
| 91 | 1180 | 1 | 0 | 2024-02-19 | 2024-02-19 | 0.015 | 1 | Another pending REAL dividend in USD. |
| 92 | 1180 | 1 | 0 | 2024-02-19 | 2024-02-19 | 0.009 | 2 | Pending dividend in EUR (CurrencyID=2). |

**Selection criteria**: Picked from live MCP sample. Mix of CFD (0) and REAL (1), variety of dividend currencies. All Status=0 (pending).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DividendID | int | NO | - | CODE-BACKED | Primary key from base table. Surrogate ID for the dividend event. (From Trade.IndexDividends) |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. The instrument (stock/index) for which this dividend is declared. (From Trade.IndexDividends) |
| 3 | PositionType | tinyint | NO | - | CODE-BACKED | FK to Dictionary.PositionType. 0=CFD, 1=REAL. 255 excluded by view filter. (From Trade.IndexDividends) |
| 4 | TaxCode | varchar(40) | NO | - | CODE-BACKED | Tax code/label for withholding. Passed from InsertIndexDividend; may map to jurisdiction. (From Trade.IndexDividends) |
| 5 | EventType | varchar(40) | NO | - | CODE-BACKED | Type of corporate action (e.g., dividend, special dividend). (From Trade.IndexDividends) |
| 6 | ExDate | date | NO | - | CODE-BACKED | Ex-dividend date. Holder must own position on this date to receive dividend. (From Trade.IndexDividends) |
| 7 | PaymentDate | date | NO | - | CODE-BACKED | Date when dividend is paid. Trade.GetCIDsForIndexDividends uses PaymentDate < today to advance Status. (From Trade.IndexDividends) |
| 8 | DividendValueInCurrency | money | NO | - | CODE-BACKED | Dividend amount per share/unit in DividendCurrencyID. (From Trade.IndexDividends) |
| 9 | DividendCurrencyID | int | NO | - | CODE-BACKED | FK to Dictionary.Currency. Currency of DividendValueInCurrency. (From Trade.IndexDividends) |
| 10 | BuyTax | decimal(6,4) | NO | - | CODE-BACKED | Tax rate for buy-side (long) positions. Fraction, e.g., 0.15 = 15%. (From Trade.IndexDividends) |
| 11 | SellTax | decimal(6,4) | NO | - | CODE-BACKED | Tax rate for sell-side (short) positions. (From Trade.IndexDividends) |
| 12 | Status | tinyint | NO | - | CODE-BACKED | Lifecycle: 0=Pending, 4=Correction Pending (only these appear in view). (From Trade.IndexDividends) |
| 13 | CorrectionDividendID | int | YES | - | CODE-BACKED | FK to self. DividendID being corrected. When set, Status=4. (From Trade.IndexDividends) |
| 14 | NegativeDividendAllowed | bit | YES | - | CODE-BACKED | 1 = negative (special) dividend allowed. NULL = default no. (From Trade.IndexDividends) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Lookup | Instrument for this dividend. |
| PositionType | Dictionary.PositionType | Lookup | CFD (0), REAL (1). |
| DividendCurrencyID | Dictionary.Currency | Lookup | Currency of dividend amount. |
| CorrectionDividendID | Trade.IndexDividends | Self-Reference | Original dividend being corrected. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DividendsApp | - | GRANT SELECT | Application role with SELECT permission. |
| Trade.GetCIDsForIndexDividends | FROM | Reader | Feeds dividend processing pipeline. |
| Trade.GetDividendsForSnapshot | FROM | Reader | Snapshot eligibility. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetActiveIndexDividends (view)
└── Trade.IndexDividends (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.IndexDividends | Table | FROM - base table with filter (Status IN (0,4), PositionType <> 255) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DividendsApp | Role | GRANT SELECT for dividend processing |
| Trade.GetCIDsForIndexDividends | Procedure | Feeds processing pipeline |
| Trade.GetDividendsForSnapshot | Procedure | Snapshot eligibility |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Active dividends for an instrument
```sql
SELECT DividendID, InstrumentID, PositionType, ExDate, PaymentDate,
       DividendValueInCurrency, DividendCurrencyID, Status
  FROM Trade.GetActiveIndexDividends WITH (NOLOCK)
 WHERE InstrumentID = 1180
 ORDER BY PaymentDate;
```

### 8.2 Pending dividends with instrument symbol
```sql
SELECT D.DividendID, D.InstrumentID, IMD.Symbol, D.PositionType, D.ExDate, D.PaymentDate,
       D.DividendValueInCurrency, DC.Abbreviation AS DivCurrency
  FROM Trade.GetActiveIndexDividends D WITH (NOLOCK)
  JOIN Trade.InstrumentMetaData IMD WITH (NOLOCK) ON D.InstrumentID = IMD.InstrumentID
  JOIN Dictionary.Currency DC WITH (NOLOCK) ON D.DividendCurrencyID = DC.CurrencyID
 ORDER BY D.PaymentDate;
```

### 8.3 Correction dividends (Status=4)
```sql
SELECT D.DividendID, D.InstrumentID, D.CorrectionDividendID, D.ExDate, D.PaymentDate,
       D.DividendValueInCurrency, D.Status
  FROM Trade.GetActiveIndexDividends D WITH (NOLOCK)
 WHERE D.CorrectionDividendID IS NOT NULL
 ORDER BY D.PaymentDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetActiveIndexDividends | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetActiveIndexDividends.sql*
