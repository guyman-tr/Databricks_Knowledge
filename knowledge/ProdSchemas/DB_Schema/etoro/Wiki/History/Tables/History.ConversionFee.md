# History.ConversionFee

> Application-managed temporal history of currency conversion fee configurations - 94 versioned fee snapshots (2021-2024) tracking deposit/cashout fee changes per CurrencyID/InstrumentID pair, with JSON audit trace.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - application temporal table (clustered on ValidTo ASC, ValidFrom ASC) |
| **Partition** | No |
| **Temporal** | Application-managed (NOT SQL Server SYSTEM_VERSIONING) |
| **Indexes** | 1 (clustered on ValidTo ASC, ValidFrom ASC) |
| **Compression** | DATA_COMPRESSION=PAGE |

---

## 1. Business Meaning

History.ConversionFee stores the versioned history of currency conversion fees - the flat fees and percentage fees charged when customers deposit or cash out in different currencies. When a fee configuration changes in the base table (likely Trade.ConversionFee or a similarly named table), the application writes the old row here before updating the current record.

This is an **application-managed temporal table**, not a SQL Server SYSTEM_VERSIONING table. The application code explicitly inserts old rows here when fee configs change. ValidFrom and ValidTo are application-set timestamps marking each row's validity window.

94 rows covering 2021-09-19 to 2024-07-04. 35 distinct currencies and 36 distinct instruments. The Trace column stores a JSON audit object containing HostName and AppName at time of change - observed values show changes were made manually via "Microsoft SQL Server Management Studio."

ConversionFeeID is always 0 in the observed rows, suggesting the base table's identity column was not populated in these rows (possibly a legacy insert pattern where ID was not captured).

---

## 2. Business Logic

### 2.1 Fee Versioning

**What**: When a currency conversion fee is changed, the previous fee configuration is written here with ValidFrom/ValidTo marking its effective window.

**Rules**:
- ValidFrom = timestamp when this fee version became effective
- ValidTo = timestamp when this fee version was superseded by a new value
- ValidFrom of a new row = ValidTo of the prior row for the same (CurrencyID, InstrumentID) pair
- Changes were made manually via SSMS (as evidenced by Trace JSON showing SSMS as the AppName)

### 2.2 Fee Types

| Column | Type | Description |
|--------|------|-------------|
| DepositFee | int | Flat deposit fee in base currency units (e.g., 150 = $1.50 or 150 cents) |
| CashoutFee | int | Flat cashout fee in base currency units |
| DepositFeePercentage | decimal(18,2) | Percentage deposit fee (NULL for flat-fee-only configs) |
| CashoutFeePercentage | decimal(18,2) | Percentage cashout fee (NULL for flat-fee-only configs) |

### 2.3 JSON Audit Trace

The Trace column stores a JSON object capturing the change context:
```json
{"HostName": "PF1B1N9J", "AppName": "Microsoft SQL Server Management Studio - Query"}
```
This indicates all fee changes were made directly via SSMS rather than through an application API.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 94 |
| **ValidFrom Range** | 2021-09-19 to 2024-07-04 |
| **Distinct Currencies** | 35 |
| **Distinct Instruments** | 36 |
| **ConversionFeeID** | Always 0 (not captured in history rows) |

Sample fee history:

| CurrencyID | InstrumentID | DepositFee | CashoutFee | ValidFrom | ValidTo |
|-----------|-------------|------------|------------|-----------|---------|
| 6 | 6 | 150 | 150 | 2024-05-02 | 2024-07-04 |
| 5 | 7 | 250 | 150 | 2024-01-24 | 2024-05-02 |
| 38 | 45 | 200 | 200 | 2024-01-23 | 2024-05-02 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyID | int | NO | - | VERIFIED | Currency for which this fee applies. Implicit FK to Dictionary.Currency. |
| 2 | InstrumentID | int | NO | - | VERIFIED | Instrument associated with this conversion fee. Implicit FK to Dictionary.Instrument or Trade.InstrumentTbl. CurrencyID and InstrumentID together identify the fee entry. |
| 3 | DepositFee | int | NO | - | VERIFIED | Flat deposit fee in minor currency units (e.g., cents). Observed: 150, 200, 250. |
| 4 | CashoutFee | int | NO | - | VERIFIED | Flat cashout fee in minor currency units. |
| 5 | ModificationDate | datetime | NO | - | VERIFIED | Wall-clock datetime when the fee change was made. Set by the operator/script. |
| 6 | Trace | nvarchar(733) | NO | - | VERIFIED | JSON audit string capturing the change context. Keys: HostName (machine name), AppName (application used). All observed: "Microsoft SQL Server Management Studio - Query". |
| 7 | ValidFrom | datetime2(7) | NO | - | VERIFIED | Application-managed start of this fee version's validity. Set by the application/script when inserting the history row. |
| 8 | ValidTo | datetime2(7) | NO | - | VERIFIED | Application-managed end of this fee version's validity. Set to the new effective time when the fee changes. Clustered index leading column. |
| 9 | DepositFeePercentage | decimal(18,2) | YES | - | CODE-BACKED | Percentage-based deposit fee. NULL when flat fee applies. Used alongside DepositFee for mixed flat+percentage fee structures. |
| 10 | CashoutFeePercentage | decimal(18,2) | YES | - | CODE-BACKED | Percentage-based cashout fee. NULL when flat fee applies. |
| 11 | ConversionFeeID | int | NO | - | CODE-BACKED | ID from the base ConversionFee table. Always 0 in observed data - not captured in this history pattern. Likely added to schema later. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | Implicit | Currency for which the conversion fee applies. |
| InstrumentID | Dictionary.Instrument / Trade.InstrumentTbl | Implicit | Instrument associated with the fee record. |
| ConversionFeeID | (base ConversionFee table) | Application-managed | ID linking back to the current fee table row (always 0 in practice). |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Compression |
|-----------|------|-------------|-------------|
| ix_ConversionFee | CLUSTERED | ValidTo ASC, ValidFrom ASC | PAGE |

ValidTo-first ordering enables efficient point-in-time lookups: `WHERE ValidFrom <= @date AND ValidTo > @date`.

---

## 8. Sample Queries

### 8.1 Get fee that was active at a specific point in time
```sql
SELECT CurrencyID, InstrumentID, DepositFee, CashoutFee, ValidFrom, ValidTo
FROM History.ConversionFee WITH (NOLOCK)
WHERE CurrencyID = 6
  AND ValidFrom <= '2024-03-01'
  AND ValidTo > '2024-03-01'
ORDER BY ValidFrom;
```

### 8.2 Full fee change history for a currency/instrument
```sql
SELECT ConversionFeeID, DepositFee, CashoutFee, ModificationDate, ValidFrom, ValidTo, Trace
FROM History.ConversionFee WITH (NOLOCK)
WHERE CurrencyID = 6 AND InstrumentID = 6
ORDER BY ValidFrom;
```

---

*Generated: 2026-03-19 | Quality: 8.9/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.ConversionFee | Type: Table | Source: etoro/etoro/History/Tables/History.ConversionFee.sql*
