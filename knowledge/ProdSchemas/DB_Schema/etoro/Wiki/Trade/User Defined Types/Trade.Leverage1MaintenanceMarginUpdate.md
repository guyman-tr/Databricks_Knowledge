# Trade.Leverage1MaintenanceMarginUpdate

> A table-valued parameter type for bulk updates of leverage-1 maintenance margin by provider and instrument, used when configuring futures trading margins.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | ProviderID, InstrumentID |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.Leverage1MaintenanceMarginUpdate is a table-valued parameter (TVP) type that carries provider-instrument pairs with their corresponding Leverage1MaintenanceMargin value. The maintenance margin at 1x leverage defines the minimum equity required to hold a position at no leverage - a risk parameter used in futures trading configurations.

This type exists to support bulk configuration updates when margins change across providers and instruments. Risk or operations teams apply margin changes in batch rather than one-by-one.

The application or config loader builds a Leverage1MaintenanceMarginUpdate table and passes it to UpdateFuturesTradingConfigurations or UpdateProviderToInstrumentLeverageMaintenance. Procedures apply the TVP data to update provider-instrument margin settings.

---

## 2. Business Logic

ProviderID + InstrumentID + Leverage1MaintenanceMargin triplets for bulk instrument configuration updates. Each row defines the maintenance margin (as decimal 5,2) for a specific provider-instrument combination.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | - | CODE-BACKED | Provider identifier - which liquidity provider or broker. References provider/liquidity entity. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument identifier - the traded asset. Combined with ProviderID forms unique config key. |
| 3 | Leverage1MaintenanceMargin | decimal(5,2) | NO | - | NAME-INFERRED | Maintenance margin at 1x leverage. Minimum equity required to hold the position at no leverage (e.g. 100.00 for 100 units). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. ProviderID and InstrumentID semantically reference provider and instrument tables; no declared FKs on the type.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateFuturesTradingConfigurations | @LeverageMaintenanceMarginUpdates | Parameter (TVP) | Applies leverage-1 maintenance margin updates for futures config |
| Trade.UpdateProviderToInstrumentLeverageMaintenance | @LeverageMaintenanceMarginUpdates | Parameter (TVP) | Updates provider-to-instrument leverage maintenance margins |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateFuturesTradingConfigurations | Stored Procedure | READONLY parameter for futures margin config |
| Trade.UpdateProviderToInstrumentLeverageMaintenance | Stored Procedure | READONLY parameter for provider-instrument margin updates |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bulk margin update for multiple instruments

```sql
DECLARE @Updates Trade.Leverage1MaintenanceMarginUpdate;
INSERT INTO @Updates (ProviderID, InstrumentID, Leverage1MaintenanceMargin)
VALUES (1, 100, 100.00), (1, 101, 150.00), (2, 100, 95.50);
EXEC Trade.UpdateProviderToInstrumentLeverageMaintenance @LeverageMaintenanceMarginUpdates = @Updates;
```

### 8.2 Single provider margin refresh

```sql
DECLARE @Updates Trade.Leverage1MaintenanceMarginUpdate;
INSERT INTO @Updates (ProviderID, InstrumentID, Leverage1MaintenanceMargin)
SELECT 1, InstrumentID, NewMargin FROM Staging.MarginConfig WHERE ProviderID = 1;
EXEC Trade.UpdateFuturesTradingConfigurations @LeverageMaintenanceMarginUpdates = @Updates;
```

### 8.3 Single instrument update

```sql
DECLARE @Updates Trade.Leverage1MaintenanceMarginUpdate;
INSERT INTO @Updates (ProviderID, InstrumentID, Leverage1MaintenanceMargin) VALUES (1, 42, 200.00);
EXEC Trade.UpdateProviderToInstrumentLeverageMaintenance @LeverageMaintenanceMarginUpdates = @Updates;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 9/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Leverage1MaintenanceMarginUpdate | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.Leverage1MaintenanceMarginUpdate.sql*
