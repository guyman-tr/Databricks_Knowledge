# Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping

> Upserts initial margin requirements for futures instruments per liquidity provider using a TVP MERGE: updates InitialMargin when (InstrumentID, ProviderID) exists, inserts a new row when it does not.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FuturesInstrumentsInitialMarginByProviderMapping (TVP - Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping is the write path for maintaining initial margin requirements for futures contracts. The initial margin is the cash deposit a customer must have to open a futures position - it is specific to both the instrument (contract size, volatility) and the liquidity provider (each provider sets its own margin schedule).

When eToro onboards a new futures instrument or renegotiates margin terms with a liquidity provider, this procedure updates `Trade.FuturesInstrumentsInitialMarginByProviderMapping` with the new requirements. The MERGE semantics handle both new provider-instrument combinations (NOT MATCHED -> INSERT) and updates to existing ones (MATCHED -> UPDATE InitialMargin). The OpsFlowAPI role has EXECUTE permission, indicating this is called via the trading operations API.

The table is system-versioned (temporal), so every InitialMargin change is automatically audited in History.FuturesInstrumentsInitialMarginByProviderMapping - critical for regulatory compliance in futures trading.

---

## 2. Business Logic

### 2.1 MERGE Upsert on Composite Key

**What**: The MERGE targets Trade.FuturesInstrumentsInitialMarginByProviderMapping using a two-column composite key: (InstrumentID, ProviderID). Matching rows get InitialMargin updated; missing rows get a new record inserted.

**Columns/Parameters Involved**: `Source.InstrumentID`, `Source.ProviderID`, `Source.InitialMargin`, `Target.InitialMargin`

**Rules**:
- MERGE match condition: `Target.InstrumentID = Source.InstrumentID AND Target.ProviderID = Source.ProviderID`
- WHEN MATCHED -> UPDATE: `InitialMargin = Source.InitialMargin`
- WHEN NOT MATCHED BY TARGET -> INSERT: `(InstrumentID, ProviderID, InitialMargin)` with source values
- No WHEN NOT MATCHED BY SOURCE clause: rows in the target not in the TVP are left unchanged (no deletes)
- No explicit transaction; MERGE is atomic by default

**Diagram**:
```
TVP:
  InstrumentID=500, ProviderID=3, InitialMargin=1250.00  <- existing, update
  InstrumentID=501, ProviderID=3, InitialMargin=875.00   <- new, insert
          |
          v
  MERGE FuturesInstrumentsInitialMarginByProviderMapping
    MATCHED     -> UPDATE InitialMargin
    NOT MATCHED -> INSERT row
  All other rows: untouched
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FuturesInstrumentsInitialMarginByProviderMapping | Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping READONLY | NO | - | CODE-BACKED | TVP containing the batch of initial margin mappings to upsert. Each row: InstrumentID (FK to Trade.Instrument, part of composite key), ProviderID (FK to Trade.LiquidityProvider, part of composite key), InitialMargin (decimal - cash margin required to open one futures contract with this provider). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FuturesInstrumentsInitialMarginByProviderMapping | Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping | TVP | Input parameter type (InstrumentID, ProviderID, InitialMargin) |
| MERGE target | Trade.FuturesInstrumentsInitialMarginByProviderMapping | Modifier | Upserts InitialMargin per (InstrumentID, ProviderID) composite key |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| OpsFlowAPI (DB role) | GRANT EXECUTE | Permission | Trading operations API calls this to maintain futures margin schedules |
| Trade.UpdateFuturesOpsConfigurations | EXEC call | Caller | Bulk futures operations procedure also calls this to update margin data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping (procedure)
+-- Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping (TVP type)
+-- Trade.FuturesInstrumentsInitialMarginByProviderMapping (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping | User Defined Type (TVP) | Input parameter type (InstrumentID, ProviderID, InitialMargin) |
| Trade.FuturesInstrumentsInitialMarginByProviderMapping | Table | MERGE target - InitialMargin updated or new row inserted |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateFuturesOpsConfigurations | Stored Procedure | Calls this as part of bulk futures configuration updates |
| OpsFlowAPI (DB role) | Permission grantee | Operations API uses this to update margin requirements |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. No TRY/CATCH. No input validation beyond what the TVP type enforces. MERGE is atomic.

---

## 8. Sample Queries

### 8.1 Upsert initial margin for a batch of futures instruments
```sql
DECLARE @Margins Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping;

INSERT INTO @Margins (InstrumentID, ProviderID, InitialMargin)
VALUES
  (500, 3, 1250.00),
  (501, 3,  875.00),
  (502, 3,  650.00);

EXEC Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping
    @FuturesInstrumentsInitialMarginByProviderMapping = @Margins;
```

### 8.2 Check current initial margins for futures instruments
```sql
SELECT f.InstrumentID, f.ProviderID, f.InitialMargin,
       f.AppLoginName, f.SysStartTime
FROM   Trade.FuturesInstrumentsInitialMarginByProviderMapping f WITH (NOLOCK)
ORDER  BY f.InstrumentID, f.ProviderID;
```

### 8.3 Review temporal history of margin changes
```sql
SELECT TOP 20 *
FROM   History.FuturesInstrumentsInitialMarginByProviderMapping WITH (NOLOCK)
ORDER  BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping.sql*
