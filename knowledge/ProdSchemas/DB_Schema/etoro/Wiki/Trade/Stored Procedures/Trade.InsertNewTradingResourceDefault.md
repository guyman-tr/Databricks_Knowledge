# Trade.InsertNewTradingResourceDefault

> Bootstraps per-customer leverage restrictions for a new CID by copying the platform leverage options for all Forex (type 1), Commodity (type 2), and Indices (type 4) instruments into Trade.LeverageRestrictionsByCustomer - skipping any instrument where the customer already has a restriction row.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer for whom defaults are being created |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertNewTradingResourceDefault initializes the customer-specific leverage configuration for a new CID. It reads the current leverage options defined at the platform level (Trade.ProviderInstrumentToLeverage joined to Dictionary.Leverage and Trade.GetInstrument) for all active Forex, Commodity, and Indices instruments, and copies those leverage options into Trade.LeverageRestrictionsByCustomer for the specified customer.

This gives the customer a personal set of leverage restrictions that mirrors the platform defaults. Once these rows exist, Trade.GetLeverageRestrictionsByCid can serve the customer's allowed leverage options from the customer-specific table rather than falling back to country-level defaults.

The LEFT JOIN + IS NULL deduplication guard ensures idempotency: calling this SP twice for the same CID will not create duplicates. Only instruments not yet present in the customer's restriction table are inserted.

Note: A commented-out `@DefaultLeverage` parameter and associated UPDATE statements exist in the code, suggesting a prior design intent to allow the caller to specify a custom default leverage value (e.g., 50x). This was abandoned; the current implementation uses IsDefault as-is from ProviderInstrumentToLeverage.

---

## 2. Business Logic

### 2.1 Three-Phase Staging into #Leverages_tmp

**What**: Leverage options for three instrument types are collected into a local temp table before the final INSERT.

**Columns/Parameters Involved**: `#Leverages_tmp.InstrumentID`, `#Leverages_tmp.InstrumentTypeID`, `#Leverages_tmp.LeverageID`, `#Leverages_tmp.Value`, `#Leverages_tmp.IsDefault`

**Rules**:
- Three separate SELECT statements (INTO + two INSERTs) populate #Leverages_tmp sequentially:
  1. InstrumentTypeID = 1: Forex (e.g., EUR/USD, GBP/USD) - max leverage typically up to 400x
  2. InstrumentTypeID = 2: Commodity (e.g., Gold, Oil) - max leverage typically up to 25x
  3. InstrumentTypeID = 4: Indices (e.g., S&P 500, DAX) - max leverage typically up to 25x
- Source: Trade.ProviderInstrumentToLeverage JOIN Dictionary.Leverage JOIN Trade.GetInstrument
- IsDefault is taken directly from Trade.ProviderInstrumentToLeverage.IsDefault (platform default).
- Only InstrumentTypeIDs 1, 2, 4 are included. Crypto (3), Stocks (5), ETF (6) and other types are excluded.

### 2.2 Idempotent INSERT with LEFT JOIN Deduplication

**What**: Only instruments not yet in the customer's leverage restriction table are inserted.

**Columns/Parameters Involved**: `@CID`, `Trade.LeverageRestrictionsByCustomer.CID`, `Trade.LeverageRestrictionsByCustomer.InstrumentID`

**Rules**:
- `LEFT JOIN Trade.LeverageRestrictionsByCustomer L ON L.CID = @CID AND t.InstrumentID = L.InstrumentID`
- `WHERE L.InstrumentID IS NULL`: only rows where the customer does NOT yet have a restriction for that instrument are inserted.
- This makes the procedure safe to call multiple times: subsequent calls for the same CID are no-ops for already-configured instruments, and only add rows for newly onboarded instruments.
- The INSERT sets CID=@CID, InstrumentID=t.InstrumentID, PossibleLeverage=t.Value (Dictionary.Leverage.Value), IsDefault=t.IsDefault.

**Diagram**:
```
Trade.ProviderInstrumentToLeverage (platform leverage options)
    JOIN Dictionary.Leverage (leverage values)
    JOIN Trade.GetInstrument (instrument type filter: 1, 2, 4)
         |
         v
   #Leverages_tmp (staged rows: InstrumentID, InstrumentTypeID, LeverageID, Value, IsDefault)
         |
         v
   LEFT JOIN Trade.LeverageRestrictionsByCustomer WHERE L.InstrumentID IS NULL
         |
   (only instruments NOT yet in customer restrictions)
         |
         v
   INSERT Trade.LeverageRestrictionsByCustomer
   (CID=@CID, InstrumentID, PossibleLeverage=Value, IsDefault)
```

### 2.3 Commented-Out DefaultLeverage Override

**What**: The procedure originally supported overriding which leverage value is marked as IsDefault.

**Rules**:
- `@DefaultLeverage int = 50` parameter is commented out in the CREATE PROC signature.
- Three UPDATE statements (one per instrument type) that would set `IsDefault = 1 WHERE Value = @DefaultLeverage` are also commented out.
- Current behavior: IsDefault is copied verbatim from ProviderInstrumentToLeverage - the platform default is used as-is.
- This means: for a new customer, the default leverage shown in the UI is the platform's default for each instrument, not a customer-specific value.

### 2.4 Transaction + THROW

**What**: All INSERTs are atomic - either all complete or none commit.

**Rules**:
- BEGIN TRAN wraps the #Leverages_tmp population and the final INSERT.
- COMMIT TRAN on success. ROLLBACK TRAN + THROW on any error.
- THROW re-raises the original exception to the caller.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID for whom default leverage restrictions will be created. All inserted rows into Trade.LeverageRestrictionsByCustomer use this CID. Must be a valid customer CID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Leverage options source | Trade.ProviderInstrumentToLeverage | Read (SELECT) | Reads all available leverage options (LeverageID, IsDefault) per instrument |
| Leverage values | Dictionary.Leverage | Read (JOIN) | Resolves LeverageID to numeric Value (e.g., 1, 2, 5, 25, 50, 400) |
| Instrument type filter | Trade.GetInstrument | Read (JOIN) | Filters instruments to types 1 (Forex), 2 (Commodity), 4 (Indices) only |
| Dedup check | Trade.LeverageRestrictionsByCustomer | Read (LEFT JOIN) | Checks which instruments the customer already has restrictions for |
| INSERT target | Trade.LeverageRestrictionsByCustomer | Write (INSERT) | Creates per-customer leverage restriction rows for missing instruments |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called during new customer account setup workflows.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertNewTradingResourceDefault (procedure)
+-- Trade.ProviderInstrumentToLeverage (table) - leverage options source
+-- Dictionary.Leverage (table) - leverage value resolution
+-- Trade.GetInstrument (view) - instrument type filter
+-- Trade.LeverageRestrictionsByCustomer (table) - dedup check + INSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderInstrumentToLeverage | Table | SELECT source for instrument leverage options and IsDefault flag |
| Dictionary.Leverage | Table | JOIN to resolve LeverageID to numeric leverage Value |
| Trade.GetInstrument | View | JOIN to filter by InstrumentTypeID (1, 2, 4 only) |
| Trade.LeverageRestrictionsByCustomer | Table | LEFT JOIN dedup check + INSERT target for customer leverage rows |

### 6.2 Objects That Depend On This

No dependents found in stored procedures. Called externally by new customer onboarding workflows.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| LEFT JOIN IS NULL guard | Deduplication | Prevents duplicate (CID, InstrumentID, PossibleLeverage) PK violations; safe to re-run |
| InstrumentTypeID filter | Scope | Only Forex (1), Commodity (2), Indices (4) - Crypto/Stocks/ETF excluded |
| @DefaultLeverage commented out | Legacy | Original default-leverage override feature disabled; IsDefault copied from platform |
| Explicit transaction | Atomicity | BEGIN TRAN / COMMIT wraps all staging + INSERT |
| THROW on error | Error propagation | Re-raises exception after ROLLBACK |

---

## 8. Sample Queries

### 8.1 Initialize default leverage restrictions for a new customer

```sql
EXEC Trade.InsertNewTradingResourceDefault @CID = 12345
```

### 8.2 Verify inserted leverage restrictions for the customer

```sql
SELECT CID, InstrumentID, PossibleLeverage, IsDefault
FROM   Trade.LeverageRestrictionsByCustomer WITH (NOLOCK)
WHERE  CID = 12345
ORDER  BY InstrumentID, PossibleLeverage;
```

### 8.3 Count instruments per type that would be initialized (dry-run preview)

```sql
SELECT TGI.InstrumentTypeID, COUNT(DISTINCT TPL.InstrumentID) AS InstrumentCount
FROM   Trade.ProviderInstrumentToLeverage TPL
       JOIN Dictionary.Leverage DL ON TPL.LeverageID = DL.LeverageID
       JOIN Trade.GetInstrument TGI ON TGI.InstrumentID = TPL.InstrumentID
WHERE  TGI.InstrumentTypeID IN (1, 2, 4)
GROUP  BY TGI.InstrumentTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 8/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertNewTradingResourceDefault | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertNewTradingResourceDefault.sql*
