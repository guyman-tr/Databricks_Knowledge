# Trade.UpdateFuturesMetadataSecurityOpsAPI

> Updates LastTradingDateTime for a single futures instrument, then returns the full combined InstrumentMetaData + FuturesMetaData record in a single roundtrip.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID - identifies the futures instrument to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateFuturesMetadataSecurityOpsAPI is the Security Operations API write path for updating the `LastTradingDateTime` of a futures contract. LastTradingDateTime is the last date-time at which the contract can be traded before it expires - a critical scheduling parameter for the trading engine, UI display, and front-office risk systems.

The procedure follows a write-then-read pattern: after updating the field, it immediately returns the full combined metadata for the instrument (joining `Trade.FuturesMetaData` with `Trade.InstrumentMetaData`) so the caller receives the confirmed post-update state in a single database roundtrip. This is the API contract for the Security Ops system - update a value and get back the full object.

The "SecurityOpsAPI" suffix indicates this is part of the Security Operations API layer, which manages instrument lifecycle operations (creating instruments, updating contract terms, managing expirations). The `SMOpsAPI` and `PSConfigurations` roles both have EXECUTE permission.

---

## 2. Business Logic

### 2.1 LastTradingDateTime Update

**What**: Updates the single field LastTradingDateTime in Trade.FuturesMetaData for the given instrument.

**Columns/Parameters Involved**: `@InstrumentID`, `@LastTradingDateTime`, `Trade.FuturesMetaData.LastTradingDateTime`

**Rules**:
- `UPDATE Trade.FuturesMetaData SET LastTradingDateTime = @LastTradingDateTime WHERE InstrumentID = @InstrumentID`
- Targets exactly one row (InstrumentID is the PK)
- No explicit check for existence; if the InstrumentID has no FuturesMetaData row, @@ROWCOUNT=0 but no error is raised
- No SET NOCOUNT ON - @@ROWCOUNT feedback is implicitly available to the caller
- Table is system-versioned: the change is automatically audited in History.FuturesMetaData

### 2.2 Post-Update Metadata Read (Write-Then-Read Pattern)

**What**: After the UPDATE, a SELECT returns the full instrument metadata (both base metadata and futures-specific fields) for the updated instrument.

**Columns/Parameters Involved**: All selected columns from `Trade.InstrumentMetaData` and `Trade.FuturesMetaData`

**Rules**:
- LEFT JOIN: `Trade.FuturesMetaData fm LEFT JOIN Trade.InstrumentMetaData im ON im.InstrumentID = fm.InstrumentID`
- WHERE: `fm.InstrumentID = @InstrumentID`
- Returns from InstrumentMetaData: InstrumentID, InstrumentDisplayName, Exchange, Industry, CompanyInfo, InstrumentVisible, Symbol, CandleTimeframeGroup, SymbolFull, Tradable, ExchangeID, StocksIndustryID, ISINCode, ISINCountryCode, ContractExpire, InstrumentTypeSubCategoryID, InstrumentTypeID, PriceSourceID, Cusip, UnderlyingExchangeID, SubCategory
- Returns from FuturesMetaData: Multiplier, MinimalTick, LastTradingDateTime (the just-updated value), ExpirationDateTime, SettlementTime, IndexPointValue, SettlementMethod
- WITH (NOLOCK) on both tables - acceptable since we just committed the UPDATE in the same batch

**Diagram**:
```
EXEC Trade.UpdateFuturesMetadataSecurityOpsAPI(@InstrumentID, @LastTradingDateTime)
  |
  +-> UPDATE Trade.FuturesMetaData SET LastTradingDateTime=@LastTradingDateTime
        WHERE InstrumentID=@InstrumentID
  |
  +-> SELECT im.* + fm.* from FuturesMetaData fm
        LEFT JOIN InstrumentMetaData im ON im.InstrumentID=fm.InstrumentID
        WHERE fm.InstrumentID=@InstrumentID
  |
  v
Returns: full instrument + futures metadata record (1 row)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Primary key of the futures instrument to update. Targets Trade.FuturesMetaData.InstrumentID. Also used in the post-update SELECT to return the full combined metadata record. |
| 2 | @LastTradingDateTime | DATETIME | NO | - | CODE-BACKED | The last date-time at which this futures contract can be traded before expiry. Replaces the existing value in Trade.FuturesMetaData.LastTradingDateTime. Distinct from ExpirationDateTime (settlement date) - LastTradingDateTime is when trading stops, which may be before the final settlement. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE target | Trade.FuturesMetaData | Modifier | Updates LastTradingDateTime for @InstrumentID |
| SELECT source | Trade.FuturesMetaData | Read | Returns futures-specific columns after update |
| SELECT source | Trade.InstrumentMetaData | Read | Returns base instrument metadata joined to futures data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SMOpsAPI (DB role) | GRANT EXECUTE | Permission | Security Market Operations API - primary consumer |
| PSConfigurations (DB role) | GRANT EXECUTE | Permission | Platform security configurations service |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateFuturesMetadataSecurityOpsAPI (procedure)
+-- Trade.FuturesMetaData (table)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FuturesMetaData | Table | UPDATE target for LastTradingDateTime; SELECT source for futures-specific columns |
| Trade.InstrumentMetaData | Table | LEFT JOIN in SELECT for base instrument metadata columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SMOpsAPI (DB role) | Permission grantee | Security Market Ops API calls this to update futures contract last-trading dates |
| PSConfigurations (DB role) | Permission grantee | Platform security config service also has execute access |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. No explicit transaction; UPDATE and SELECT run as separate statements. No TRY/CATCH. No existence check before UPDATE (silent no-op if InstrumentID not found).

---

## 8. Sample Queries

### 8.1 Update LastTradingDateTime for a futures instrument
```sql
EXEC Trade.UpdateFuturesMetadataSecurityOpsAPI
    @InstrumentID        = 7001,
    @LastTradingDateTime = '2026-06-20 14:30:00';
-- Returns: full InstrumentMetaData + FuturesMetaData row for InstrumentID=7001
```

### 8.2 Check current LastTradingDateTime for futures instruments
```sql
SELECT InstrumentID, LastTradingDateTime, ExpirationDateTime, SettlementTime
FROM   Trade.FuturesMetaData WITH (NOLOCK)
WHERE  LastTradingDateTime >= GETUTCDATE()
ORDER  BY LastTradingDateTime;
```

### 8.3 Review temporal history of LastTradingDateTime changes
```sql
SELECT TOP 20 InstrumentID, LastTradingDateTime,
              SysStartTime, SysEndTime
FROM   History.FuturesMetaData WITH (NOLOCK)
WHERE  InstrumentID = 7001
ORDER  BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateFuturesMetadataSecurityOpsAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateFuturesMetadataSecurityOpsAPI.sql*
