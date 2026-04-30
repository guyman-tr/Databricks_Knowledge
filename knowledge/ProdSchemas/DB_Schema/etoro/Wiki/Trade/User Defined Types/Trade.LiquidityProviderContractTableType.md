# Trade.LiquidityProviderContractTableType

> A table-valued parameter type for bulk loading liquidity provider to instrument contract mappings, including ticker, exchange, and rate conversion metadata.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | LiquidityProviderID + InstrumentID (semantic) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.LiquidityProviderContractTableType is a table-valued parameter type that carries liquidity provider contract configuration. Each row links a liquidity provider to an instrument with ticker, exchange, and rate-conversion details. This enables bulk loading of provider-to-instrument mappings when configuring instruments for dealing or market data.

This type exists to support instrument setup and metadata operations. Procedures that insert instrument dealing configuration or security-ops API metadata accept batches of contract mappings via this TVP instead of row-by-row inserts.

The application or ETL builds the table and passes it as a READONLY parameter to Trade.InsertInstrumentDealing or Trade.InsertInstrumentMetadataSecurityOpsAPI. The procedures use the TVP to populate or update liquidity provider contract data.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. ProviderID + InstrumentID + Ticker + ExchangeID + RateConversionFactor form a bulk config row for instrument-contract mappings.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderID | int | YES | - | CODE-BACKED | Liquidity provider identifier. References provider dimension. |
| 2 | InstrumentID | int | YES | - | CODE-BACKED | Instrument identifier. References Trade.Instrument or similar. |
| 3 | Ticker | varchar(50) | YES | - | NAME-INFERRED | Symbol/ticker for the instrument at this provider. |
| 4 | ExchangeID | int | YES | - | CODE-BACKED | Exchange identifier for the contract. |
| 5 | RateConversionFactor | decimal(10,4) | YES | - | NAME-INFERRED | Factor used to convert rates for this provider-instrument pair. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. LiquidityProviderID, InstrumentID, and ExchangeID semantically reference dimension tables; there are no declared FKs on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertInstrumentDealing | @LiquidityProviderContracts | Parameter (TVP) | Bulk inserts liquidity provider contract mappings |
| Trade.InsertInstrumentMetadataSecurityOpsAPI | @Contracts | Parameter (TVP) | Inserts instrument metadata with contract mappings |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertInstrumentDealing | Stored Procedure | READONLY parameter for bulk contract insert |
| Trade.InsertInstrumentMetadataSecurityOpsAPI | Stored Procedure | READONLY parameter for metadata insert |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for bulk contract insert

```sql
DECLARE @Contracts Trade.LiquidityProviderContractTableType;
INSERT INTO @Contracts (LiquidityProviderID, InstrumentID, Ticker, ExchangeID, RateConversionFactor)
VALUES (1, 100, 'AAPL', 1, 1.0000), (1, 101, 'MSFT', 1, 1.0000);
EXEC Trade.InsertInstrumentDealing @LiquidityProviderContracts = @Contracts, ...;
```

### 8.2 Load from staging table

```sql
DECLARE @Contracts Trade.LiquidityProviderContractTableType;
INSERT INTO @Contracts (LiquidityProviderID, InstrumentID, Ticker, ExchangeID, RateConversionFactor)
SELECT ProviderID, InstrumentID, Ticker, ExchangeID, RateConversionFactor
FROM Staging.ProviderContracts;
EXEC Trade.InsertInstrumentMetadataSecurityOpsAPI @Contracts = @Contracts, ...;
```

### 8.3 Single contract mapping

```sql
DECLARE @Contracts Trade.LiquidityProviderContractTableType;
INSERT INTO @Contracts (LiquidityProviderID, InstrumentID, Ticker, ExchangeID, RateConversionFactor)
VALUES (2, 500, 'EURUSD', 2, 1.0000);
EXEC Trade.InsertInstrumentDealing @LiquidityProviderContracts = @Contracts, ...;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 8/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.LiquidityProviderContractTableType | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.LiquidityProviderContractTableType.sql*
