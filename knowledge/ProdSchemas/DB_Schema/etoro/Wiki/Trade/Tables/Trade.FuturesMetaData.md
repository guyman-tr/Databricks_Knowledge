# Trade.FuturesMetaData

> Per-instrument futures contract metadata: contract size, tick, expiration, settlement, and pricing parameters.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK + IX_ExpirationDateTime) |
| **System Versioning** | Yes → History.FuturesMetaData |

---

## 1. Business Meaning

**WHAT**: Trade.FuturesMetaData stores contract-specific parameters for futures instruments. Each row corresponds to one Trade.Instrument that is a futures contract. It defines the multiplier (contract size), minimal tick (price granularity), last trading and expiration dates, settlement time, index point value, and optional settlement method and unit of measure.

**WHY**: Futures contracts have standardized terms that differ from spot instruments. The trading engine needs these values to calculate position sizing, margin, overnight fees (via Trade.CalcOverNightFeeRates), and API exposure for Security Ops. Without this table, the system cannot correctly price or risk-manage futures positions.

**HOW**: Data is bulk-inserted during instrument onboarding via `Trade.InsertInstrumentRealTable` from `##Trade_FuturesMetaData`, and instrument validation uses `Trade.CheckValidInstruments` to ensure futures have metadata. `Trade.UpdateFuturesMetadataSecurityOpsAPI` updates rows; reads come from `Trade.GetAllFuturesMetadataSecurityOpsAPI`, `Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI`, `Trade.GetAllInstrumentData`, `Trade.GetInstrumentDataForAPI`, and overnight fee calculations. System versioning maintains full history in History.FuturesMetaData.

---

## 2. Business Logic

### 2.1 Instrument One-to-One

**What**: Exactly one metadata row per futures InstrumentID.

**Rules**:
- InstrumentID is the primary key; each futures instrument has at most one row.
- LEFT JOIN from instrument views; only futures instruments have matches.
- Trade.CheckValidInstruments asserts existence of a row for futures before allowing use.

**Diagram**:
```
Trade.Instrument (InstrumentID)
        |
        | 1:1
        v
Trade.FuturesMetaData (InstrumentID, Multiplier, MinimalTick, ExpirationDateTime, ...)
        |
        v
History.FuturesMetaData (temporal history)
```

### 2.2 Contract Sizing and Tick

**What**: Multiplier and MinimalTick define contract economics.

**Rules**:
- Multiplier: contract size per point (e.g., 1, 2, 100). Used with price for notional.
- MinimalTick: smallest price increment (e.g., 0.25, 0.5, 0.01). Used for rounding and spread.
- IndexPointValue: value per point move (observed 1, 2, 3, 100).

### 2.3 Expiration and Settlement

**What**: LastTradingDateTime and ExpirationDateTime bound the contract lifecycle.

**Rules**:
- LastTradingDateTime: when trading ceases.
- ExpirationDateTime: contract maturity. Some use 2222-01-01 for perpetuals.
- SettlementTime: time-of-day for settlement (stored as time(7)).
- IX_ExpirationDateTime supports queries by expiration.

### 2.4 SettlementMethod and UnitOfMeasure

**What**: Optional taxonomy for settlement type and unit.

**Rules**:
- SettlementMethod (tinyint): 0 observed; NULL for legacy rows.
- UnitOfMeasure (tinyint): 0 or 1 observed; NULL for legacy rows.

---

## 3. Data Overview

| InstrumentID | Multiplier | MinimalTick | LastTradingDateTime | ExpirationDateTime | Meaning |
|--------------|------------|-------------|---------------------|--------------------|---------|
| 481 | 1 | 0.25 | 2025-12-19 10:29 | 2024-10-31 21:00 | Index futures, tight tick, short expiry. |
| 482 | 2 | 0.5 | 2025-12-14 10:29 | 2024-11-30 21:00 | Larger contract, wider tick. |
| 484 | 3 | 0.75 | 2025-09-27 11:58 | 2024-12-31 21:00 | Expired contract (historical). |
| 998 | 2 | 0.25 | 2025-11-12 12:13 | 2222-01-01 | Perpetual-style (far future expiry). |
| 999 | 100 | 0.01 | 2222-01-01 | 2222-01-01 | Large multiplier, fine tick; likely index. |

**Row count**: ~250 (live query). Selection: TOP 5 by InstrumentID.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | Primary key. FK to Trade.Instrument. One row per futures instrument. |
| 2 | Multiplier | decimal(20,10) | NO | - | VERIFIED | Contract size per point. Used for notional and fee calculation. |
| 3 | MinimalTick | decimal(20,10) | NO | - | VERIFIED | Smallest price increment in contract units. |
| 4 | LastTradingDateTime | datetime | NO | - | VERIFIED | When trading stops for this contract. |
| 5 | ExpirationDateTime | datetime | NO | - | VERIFIED | Contract maturity. 2222-01-01 for perpetuals. |
| 6 | SettlementTime | time(7) | NO | - | VERIFIED | Time of day for settlement. |
| 7 | IndexPointValue | decimal(20,10) | NO | - | CODE-BACKED | Dollar/value per point move. Used in exposure and fee calc. |
| 8 | DbLoginName | nvarchar(128) | - | AS (suser_name()) | NAME-INFERRED | Computed; database login at insert. |
| 9 | AppLoginName | varchar(500) | - | AS (CONVERT(varchar(500),context_info())) | NAME-INFERRED | Computed; application context at insert. |
| 10 | SysStartTime | datetime2(7) | NO | GENERATED | VERIFIED | Row start for system versioning. |
| 11 | SysEndTime | datetime2(7) | NO | GENERATED | VERIFIED | Row end for system versioning. |
| 12 | SettlementMethod | tinyint | YES | - | CODE-BACKED | Settlement type; 0 or NULL. |
| 13 | UnitOfMeasure | tinyint | YES | - | CODE-BACKED | Unit of measure; 0, 1, or NULL. |

---

## 5. Relationships

### 5.1 References To

| Referenced Table | Join Column | Description |
|------------------|-------------|-------------|
| Trade.Instrument | InstrumentID | Each futures instrument must exist in Instrument. |

### 5.2 Referenced By

| Referencing Object | Purpose |
|--------------------|---------|
| Trade.InsertInstrumentRealTable | Bulk insert from ##Trade_FuturesMetaData. |
| Trade.UpdateFuturesMetadataSecurityOpsAPI | Updates metadata. |
| Trade.GetAllFuturesMetadataSecurityOpsAPI | Returns all futures metadata. |
| Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI | Returns metadata by InstrumentID. |
| Trade.GetInstrumentDataForAPI, Trade.GetInstrumentDataForAPITest | LEFT JOIN for API instrument payload. |
| Trade.GetAllInstrumentData, Trade.GetAllInstrumentDisplayDatasForAPI | LEFT JOIN for instrument display. |
| Trade.CalcOverNightFeeRates, Trade.CalcOverNightFeeRates_TRDOPS, Trade.Elad111 | LEFT JOIN for overnight fee calculation. |
| Trade.CheckValidInstruments | Validates futures have metadata. |
| History.FuturesMetaData | Temporal history table. |

---

## 6. Dependencies

### 6.0 Chain

```
Trade.Instrument → Trade.FuturesMetaData → History.FuturesMetaData
```

### 6.1 Depends On

| Object | Type |
|--------|------|
| Trade.Instrument | Table |

### 6.2 Depended On By

| Object | Type |
|--------|------|
| History.FuturesMetaData | History Table |
| Trade.InsertInstrumentRealTable | Procedure |
| Trade.UpdateFuturesMetadataSecurityOpsAPI | Procedure |
| Trade.GetAllFuturesMetadataSecurityOpsAPI | Procedure |
| Trade.GetFuturesMetadataByInstrumentIdSecurityOpsAPI | Procedure |
| Trade.GetInstrumentDataForAPI | Procedure |
| Trade.GetInstrumentDataForAPITest | Procedure |
| Trade.GetAllInstrumentData | Procedure |
| Trade.GetAllInstrumentDisplayDatasForAPI | Procedure |
| Trade.CalcOverNightFeeRates | Procedure |
| Trade.CalcOverNightFeeRates_TRDOPS | Procedure |
| Trade.Elad111 | Procedure |
| Trade.CheckValidInstruments | Procedure |

---

## 7. Technical Details

### 7.1 Indexes

| Index | Type | Key Columns | Purpose |
|-------|------|-------------|---------|
| PK_FuturesMetaData | CLUSTERED | InstrumentID | Primary key. |
| IX_ExpirationDateTime | NONCLUSTERED | ExpirationDateTime | Expiration-based queries. |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| PK_FuturesMetaData | PRIMARY KEY | InstrumentID |
| PERIOD FOR SYSTEM_TIME | System Versioning | (SysStartTime, SysEndTime) |

**Trigger**: Tr_T_FuturesMetaData_INSERT — no-op UPDATE on insert (legacy pattern).

---

## 8. Sample Queries

```sql
-- Count futures contracts with metadata
SELECT COUNT(*) AS Cnt
FROM Trade.FuturesMetaData WITH (NOLOCK);

-- Top 5 futures by InstrumentID
SELECT TOP 5 InstrumentID, Multiplier, MinimalTick, LastTradingDateTime, ExpirationDateTime, IndexPointValue
FROM Trade.FuturesMetaData WITH (NOLOCK)
ORDER BY InstrumentID;

-- Expiring soon (next 30 days)
SELECT InstrumentID, Multiplier, MinimalTick, ExpirationDateTime
FROM Trade.FuturesMetaData WITH (NOLOCK)
WHERE ExpirationDateTime BETWEEN GETUTCDATE() AND DATEADD(DAY, 30, GETUTCDATE())
ORDER BY ExpirationDateTime;
```

---

## 9. Atlassian Knowledge Sources

- Jira/Confluence: Not yet linked for this table.
- Code references: 14+ procedures/views in Trade schema.

---

*Generated: 2026-03-14 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
