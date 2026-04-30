# Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping

> Table-valued parameter type for futures instrument initial margin by provider - maps (InstrumentID, ProviderID) to InitialMargin amount.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int), ProviderID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Tv_FuturesInstrumentsInitialMarginByProviderMapping carries provider-specific initial margin requirements for futures instruments. Each row maps (InstrumentID, ProviderID) to an InitialMargin (decimal). Different providers may require different initial margins for the same instrument.

This type exists to bulk-update or upsert initial margin mappings. Admin and ops procedures receive batches of (instrument, provider, margin) and merge them into the configuration tables.

The type flows from admin tools or provider onboarding into Trade.UpdateFuturesOpsConfigurations, Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping, and Trade.UpdateFuturesInstrumentsInitialMarginByProviderMappingEladGet. Procedures use the TVP to update or query initial margin mappings.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Composite key (InstrumentID, ProviderID) with InitialMargin value.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier |
| 2 | ProviderID | int | NO | - | CODE-BACKED | Provider/liquidity provider identifier |
| 3 | InitialMargin | decimal(10,2) | NO | - | CODE-BACKED | Initial margin amount for (instrument, provider) |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateFuturesOpsConfigurations | @FuturesInstrumentsInitialMarginByProviderMapping | Parameter (TVP) | Updates futures ops config including initial margin mapping |
| Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping | @FuturesInstrumentsInitialMarginByProviderMapping | Parameter (TVP) | Updates initial margin by provider mapping |
| Trade.UpdateFuturesInstrumentsInitialMarginByProviderMappingEladGet | @i | Parameter (TVP) | Elad/query variant for initial margin mapping |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateFuturesOpsConfigurations | Stored Procedure | READONLY parameter for futures ops config |
| Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping | Stored Procedure | READONLY parameter for mapping update |
| Trade.UpdateFuturesInstrumentsInitialMarginByProviderMappingEladGet | Stored Procedure | READONLY parameter for query/Elad flow |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update initial margin mapping
```sql
DECLARE @FuturesInstrumentsInitialMarginByProviderMapping Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping;
INSERT INTO @FuturesInstrumentsInitialMarginByProviderMapping (InstrumentID, ProviderID, InitialMargin)
VALUES (1001, 5, 5000.00);
EXEC Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping @FuturesInstrumentsInitialMarginByProviderMapping = @FuturesInstrumentsInitialMarginByProviderMapping;
```

### 8.2 Multi-provider batch update
```sql
DECLARE @FuturesInstrumentsInitialMarginByProviderMapping Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping;
INSERT INTO @FuturesInstrumentsInitialMarginByProviderMapping (InstrumentID, ProviderID, InitialMargin)
VALUES (1001, 5, 5000.00), (1001, 6, 5500.00), (1002, 5, 3000.00);
EXEC Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping @FuturesInstrumentsInitialMarginByProviderMapping = @FuturesInstrumentsInitialMarginByProviderMapping;
```

### 8.3 Via UpdateFuturesOpsConfigurations
```sql
DECLARE @FuturesInstrumentsInitialMarginByProviderMapping Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping;
INSERT INTO @FuturesInstrumentsInitialMarginByProviderMapping (InstrumentID, ProviderID, InitialMargin)
VALUES (1001, 5, 5000.00);
EXEC Trade.UpdateFuturesOpsConfigurations @FuturesInstrumentsInitialMarginByProviderMapping = @FuturesInstrumentsInitialMarginByProviderMapping;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 3/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping.sql*
