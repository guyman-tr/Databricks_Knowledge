# Hedge.Report_StocksClients

> Net open position (NOP) report for stock instruments (InstrumentID > 99) excluding test customers (PlayerLevelID=4): returns total lot count per instrument name and ID for real customer positions only. Used by the hedge desk to assess equity exposure.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Zero-parameter SELECT; DATA_READER has EXECUTE; uses #A temp table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.Report_StocksClients` computes the Net Open Position (NOP) for stock instruments (all instruments with InstrumentID > 99, which includes equities and crypto, as opposed to forex which occupies IDs 1-99). Unlike the OTW reports which compute net buy-minus-sell, this procedure returns the raw lot sum per instrument (positive = net long, signed by the IsBuy direction implicitly through LotCountDecimal convention).

**Test customer exclusion**: The procedure uses a LEFT JOIN to `Customer.Customer` with a filter `PlayerLevelID = 4` (test/eToro employee accounts) and then excludes those rows via `AND C.CID IS NULL` - the classic "anti-join" pattern to exclude matched rows. This ensures NOP reflects only real customer positions, not internal test accounts.

A hardcoded test result set is commented out in the procedure body, suggesting this was developed iteratively with known test values (GOOG/USD, AMZN/USD, YHOO/USD, FB/USD, MSFT/USD, AAPL/USD, ZNGA/USD with specific NOP values). This comment provides a snapshot of the original instrument scope this report was built for.

DATA_READER has EXECUTE - this is a BI/analytics reporting tool.

---

## 2. Business Logic

### 2.1 Stock NOP Aggregation (Excluding Test Customers)

**What**: Sum of all open lot counts for stock instruments, excluding internal test accounts.

**Columns/Parameters Involved**: `InstrumentID`, `LotCountDecimal`, `PlayerLevelID`

**Rules**:
- `InstrumentID > 99`: selects only non-forex instruments (stocks, ETFs, crypto, etc.). Forex instruments use IDs 1-99.
- `LEFT JOIN Customer.Customer ON P.CID = C.CID AND C.PlayerLevelID = 4`: finds test customer rows.
- `AND C.CID IS NULL`: keeps only Trade.Position rows where no matching test customer was found (anti-join). Real customer positions have no match = C.CID IS NULL.
- `SUM(P.LotCountDecimal)`: sums all lot counts per instrument without sign adjustment. LotCountDecimal convention: positive for buys, negative for sells (or the sign is handled upstream).
- Results loaded into temp table `#A`, then joined with `Trade.GetInstrument` for instrument names.

### 2.2 Commented Test Data

**What**: A hardcoded test UNION SELECT is commented out in the procedure, providing known test values.

**Rules**:
- The comment lists 7 instruments (GOOG, AMZN, YHOO, FB, MSFT, AAPL, ZNGA) with their NOP values at the time the test data was written.
- These values are NOT used in production execution - they are preceded by `RETURN` to short-circuit the real query.
- Purpose: allow developers to test downstream consumers of this report without needing live Trade.Position data.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure accepts no parameters. Result set:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | Name | VARCHAR | Instrument display name (from Trade.GetInstrument), e.g., "AAPL/USD", "BTC/USD" |
| 2 | InstrumentID | INT | Instrument identifier (always > 99 in results) |
| 3 | NOP | DECIMAL | Net Open Position: sum of LotCountDecimal for all real customer positions in this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Trade.Position | Reader (NOLOCK) | Open positions with InstrumentID, LotCountDecimal, CID |
| - | Customer.Customer | Reader (NOLOCK) | Anti-join to exclude test customer (PlayerLevelID=4) positions |
| - | Trade.GetInstrument | Reader | InstrumentID -> Name lookup |

### 5.2 Referenced By (other objects point to this)

DATA_READER role holds EXECUTE. Used by hedge desk for equity exposure monitoring.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.Report_StocksClients (procedure)
|-- Trade.Position (table) [READ - stock instrument positions]
|-- Customer.Customer (table) [READ - anti-join to exclude PlayerLevelID=4]
+-- Trade.GetInstrument (view/table) [READ - instrument name resolution]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | Table | Source of open positions (InstrumentID > 99) |
| Customer.Customer | Table | Anti-join: exclude test customers (PlayerLevelID=4) |
| Trade.GetInstrument | View/Table | InstrumentID -> Name lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DATA_READER (role) | Permission | EXECUTE - BI/analytics access |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| InstrumentID > 99 | Filter | Only stock/crypto/equity instruments. Forex (IDs 1-99) excluded. |
| LEFT JOIN anti-join pattern | Test customer exclusion | C.CID IS NULL after LEFT JOIN on PlayerLevelID=4 = keep only non-test-customer rows. |
| Temp table #A | Staging | Aggregation staged into #A before joining to GetInstrument. Dropped at end. |

---

## 8. Sample Queries

### 8.1 Execute the stocks NOP report
```sql
EXEC [Hedge].[Report_StocksClients]
-- Returns: Name | InstrumentID | NOP (total lots for real customers)
```

### 8.2 Add instrument name to cross-reference with Netting
```sql
EXEC [Hedge].[Report_StocksClients]
-- Then JOIN result to Hedge.Netting on InstrumentID to compare customer NOP vs hedge NOP
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.Report_StocksClients | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.Report_StocksClients.sql*
