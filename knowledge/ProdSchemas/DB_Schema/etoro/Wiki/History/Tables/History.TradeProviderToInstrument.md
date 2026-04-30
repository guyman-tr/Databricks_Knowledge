# History.TradeProviderToInstrument

> SQL Server system-versioned temporal history table for Trade.ProviderToInstrument - stores superseded full instrument configuration snapshots (92 trading parameters) per provider/instrument, enabling point-in-time auditing of all instrument trading rules.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No - stored on [MAIN] filegroup with PAGE compression |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.TradeProviderToInstrument is the temporal history backing table for Trade.ProviderToInstrument, which is the master configuration table defining all trading parameters for each instrument/provider combination. It contains 92 columns covering every aspect of how an instrument can be traded: spreads, fees, leverage limits, stop-loss/take-profit rules, position size limits, direction permissions (buy/sell), order types allowed, and many more.

When any parameter in Trade.ProviderToInstrument changes - such as adjusting the min stop-loss percentage, enabling/disabling trading for an instrument, or changing overnight fees - SQL Server system-versioning automatically archives the complete old row here. This makes History.TradeProviderToInstrument the most comprehensive audit trail in the History schema, capturing the full state of every instrument's trading rules at every point in time.

This table is critical for compliance, regulatory reporting, dispute resolution, and understanding what rules were in effect when a specific position was opened or modified. For example, if a customer disputes a position closure, the exact stop-loss rules active at that time can be reconstructed from this history.

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: Every change to any of the 92 configuration columns in Trade.ProviderToInstrument creates a full-row snapshot here.

**Columns/Parameters Involved**: All 92 columns + SysStartTime, SysEndTime

**Rules**:
- A change to ANY column triggers a new history row with the ENTIRE row state (not just the changed column)
- SysStartTime = when this complete configuration was in effect
- SysEndTime = when any column of this row was changed or the row deleted
- DbLoginName and AppLoginName provide change attribution (who/what service made the change)
- High-change instruments (e.g., volatile crypto) accumulate many history rows per day
- PAGE compression significantly reduces storage for these wide (92-column) rows

### 2.2 Key Trading Permission Columns

**What**: The source table contains binary flags controlling what traders can do with each instrument.

**Columns/Parameters Involved**: `AllowBuy`, `AllowSell`, `AllowPendingOrders`, `AllowEntryOrders`, `AllowClosePosition`, `AllowExitOrder`, `AllowManualTrading`, `AllowRedeem`, `AllowPartialClosePosition`

**Rules**:
- Changes to these flags are immediately effective and affect all new operations - history here shows when restrictions were imposed/lifted
- AllowRedeem is TINYINT (not BIT) - values beyond 0/1 possible (application-defined)
- AllowPartialClosePosition is TINYINT - multi-value enum for partial close modes

---

## 3. Data Overview

Table is typically empty or sparsely populated in non-production environments. In production, it accumulates rows with every instrument configuration change - frequently for actively-managed instruments.

---

## 4. Elements

The source table Trade.ProviderToInstrument has 92 columns. All are preserved in this history table. Below are the key structural and audit columns; trading parameters mirror Trade.ProviderToInstrument exactly.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | INT | NO | - | CODE-BACKED | Liquidity provider identifier. Part of composite PK in source table (ProviderID, InstrumentID). |
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. Combined with ProviderID identifies which instrument config row changed. |
| 3 | Precision | TINYINT | NO | - | CODE-BACKED | Price decimal precision for this instrument (e.g., 2 for EUR/USD = 1.23, 5 for crypto). |
| 4 | PaymentBid / PaymentAsk | INT | NO | - | CODE-BACKED | Bid/Ask spread payment in pips. Used in overnight fee calculations. |
| 5 | StopLossPercentage | INT | NO | - | CODE-BACKED | Default stop-loss as percentage of position value. Deprecated in favor of Min/Max/DefaultStopLossPercentage fields. |
| 6 | EndOfWeekFee | MONEY | NO | - | CODE-BACKED | Weekly rollover fee charged on positions held over the weekend. |
| 7 | Enabled | TINYINT | NO | - | CODE-BACKED | Whether this instrument is enabled for trading on this provider: 0=disabled, 1=enabled. A change here in history marks when an instrument was suspended or re-enabled. |
| 8 | AllowBuy | BIT | NO | - | CODE-BACKED | Whether buy/long positions are allowed for this instrument. 0=buy blocked, 1=buy allowed. |
| 9 | AllowSell | BIT | NO | - | CODE-BACKED | Whether sell/short positions are allowed. Often false for real stocks (long-only). |
| 10 | MaxTakeProfitPercentage | DECIMAL(7,2) | NO | - | CODE-BACKED | Maximum take-profit as percentage above entry price (e.g., 200 = max 200% gain). |
| 11 | MinStopLossPercentage | DECIMAL(5,2) | NO | - | CODE-BACKED | Minimum stop-loss distance as % below entry. Prevents setting SL too close to market. |
| 12 | MaxStopLossPercentage | DECIMAL(5,2) | NO | - | CODE-BACKED | Maximum stop-loss distance as % below entry. Caps maximum SL distance. |
| 13 | AllowTrailingStopLoss | BIT | NO | - | CODE-BACKED | Whether trailing stop-loss (TSL) is permitted for this instrument. |
| 14 | AllowRedeem | TINYINT | NO | - | CODE-BACKED | Whether redemption (selling real stock shares) is permitted for this instrument. TINYINT for multi-mode support. |
| 15 | DesignatedExecutionSystem | TINYINT | NO | - | CODE-BACKED | Which execution system routes orders for this instrument (e.g., 0=internal, 1=external broker, etc.). |
| 16 | DbLoginName | NVARCHAR(128) | YES | NULL | CODE-BACKED | SQL Server login that made the change, from suser_name() at DML time. |
| 17 | AppLoginName | VARCHAR(500) | YES | NULL | CODE-BACKED | Application login from context_info() at DML time. Identifies calling service. |
| 18 | SysStartTime | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this instrument configuration became active. |
| 19 | SysEndTime | DATETIME2(7) | NO | - | CODE-BACKED | UTC timestamp when this configuration was superseded. Clustered index leading column. |
| 20-92 | (Additional columns) | Various | - | - | CODE-BACKED | All remaining 73 trading parameter columns from Trade.ProviderToInstrument are preserved verbatim. See Trade.ProviderToInstrument documentation for full column list. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID + InstrumentID | Trade.ProviderToInstrument | Temporal (parent) | Each history row is a snapshot of a Trade.ProviderToInstrument row. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ProviderToInstrument | SYSTEM_VERSIONING | Temporal parent | Writes superseded configuration snapshots here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.TradeProviderToInstrument (table)
  (leaf - temporal history table; uses dbo.dtPrice UDT)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type | Column type for MinimumSpread, SpreadPct (inherited from Trade.ProviderToInstrument) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | Temporal parent - writes full configuration snapshots here automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_TradeProviderToInstrument | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (PAGE compression) |

Note: PAGE compression is especially impactful here due to the 92-column row width.

### 7.2 Constraints

None. Temporal history tables have no PK, FK, or CHECK constraints.

---

## 8. Sample Queries

### 8.1 View full instrument configuration as of a specific date
```sql
SELECT *
FROM Trade.ProviderToInstrument
FOR SYSTEM_TIME AS OF '2023-06-01T00:00:00'
WHERE InstrumentID = 7
    AND ProviderID = 1;
```

### 8.2 Find when a specific instrument was disabled/re-enabled
```sql
SELECT h.ProviderID, h.InstrumentID, h.Enabled, h.SysStartTime, h.SysEndTime, h.DbLoginName
FROM History.TradeProviderToInstrument h WITH (NOLOCK)
WHERE h.InstrumentID = 7
    AND h.ProviderID = 1
ORDER BY h.SysStartTime;
```

### 8.3 Audit changes to stop-loss rules for an instrument
```sql
SELECT
    h.InstrumentID,
    h.MinStopLossPercentage,
    h.MaxStopLossPercentage,
    h.DefaultStopLossPercentage,
    h.SysStartTime,
    h.SysEndTime,
    h.DbLoginName,
    h.AppLoginName
FROM History.TradeProviderToInstrument h WITH (NOLOCK)
WHERE h.InstrumentID = 7
ORDER BY h.SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.7/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 (temporal - SQL Server managed) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.TradeProviderToInstrument | Type: Table | Source: etoro/etoro/History/Tables/History.TradeProviderToInstrument.sql*
