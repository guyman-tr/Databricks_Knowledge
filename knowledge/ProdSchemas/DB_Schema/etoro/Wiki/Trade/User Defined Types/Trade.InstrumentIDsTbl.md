# Trade.InstrumentIDsTbl

> A table-valued parameter type for passing batches of instrument IDs to stored procedures, enabling bulk instrument-level operations such as OME order matching, margin calculations, and fee configuration retrieval.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.InstrumentIDsTbl is a table-valued parameter (TVP) type for passing sets of instrument IDs into stored procedures. InstrumentID is the primary key of Trade.Instrument - the central reference table for every tradable financial instrument (stocks, ETFs, currencies, commodities, indices, crypto) on the eToro platform. This type enables bulk instrument-scoped operations.

This type supports operations that span multiple instruments simultaneously: Order Matching Engine (OME) order retrieval by instrument batch, margin calculations for futures instruments, slippage configuration lookups, fee configuration retrieval, and interest rate queries. Without it, each instrument would require a separate procedure call.

Application services, OME components, and ops tools populate an InstrumentIDsTbl with the instruments they need to process and pass it as a single parameter. Procedures JOIN against it to filter their working set to the specified instruments.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a single-column utility type specialized for the InstrumentID domain.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | Instrument ID - the primary identifier for tradable financial instruments in Trade.Instrument. Each InstrumentID uniquely identifies a single tradable asset (stock, ETF, currency pair, commodity, index, crypto). Used for bulk instrument filtering in OME order matching, margin calculations, fee lookups, interest rate queries, and halt management. No primary key constraint on the type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. InstrumentID semantically references Trade.Instrument.InstrumentID but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetOrderMatchingItemsByInstrumentID_OMEOrders | @InstrumentIDs | Parameter (TVP) | Retrieves OME orders for matching by instrument batch |
| Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees | @InstrumentIDs | Parameter (TVP) | Retrieves OME tree data by instrument batch |
| Trade.GetOrderMatchingItemsByInstrumentID_OmeTreesTest | @InstrumentIDs | Parameter (TVP) | Test version of OME tree retrieval |
| Trade.GetOrderMatchingItemsByInstrumentID_EntryOrders | @InstrumentIDs | Parameter (TVP) | Retrieves entry orders by instrument batch for matching |
| Trade.GetOrderMatchingItemsByInstrumentID_ExitOrders | @InstrumentIDs | Parameter (TVP) | Retrieves exit orders by instrument batch for matching |
| Trade.GetOrderMatchingItemsByInstrumentID_OrdersForOpen | @InstrumentIDs | Parameter (TVP) | Retrieves open orders by instrument batch for matching |
| Trade.GetOrderMatchingItemsByInstrumentID_OrdersForClose | @InstrumentIDs | Parameter (TVP) | Retrieves close orders by instrument batch for matching |
| Trade.GetInstrumentMarginsForFutures | @InstrumentIDs | Parameter (TVP) | Retrieves futures margin settings for specified instruments |
| Trade.GetInstrumentInterestRates_TRDOPS | @InstrumentIDs | Parameter (TVP) | Retrieves interest rate configurations for trading ops |
| Trade.GetCalculatedFeesConfig_TRDOPS | @InstrumentIDs | Parameter (TVP) | Retrieves calculated fee configurations for trading ops |
| Trade.GetInstrumentsUpdatableDataForOpsAPI | @InstrumentIDs | Parameter (TVP) | Retrieves updatable instrument data for ops API |
| Trade.GetInstrumentSlippage | @InstrumentIDs | Parameter (TVP) | Retrieves slippage configurations per instrument |
| Trade.InsertInstrumentHalt | @InstrumentIDs | Parameter (TVP) | Bulk-inserts instrument halt records |
| Trade.RemoveInstrumentHalt | @InstrumentIDs | Parameter (TVP) | Bulk-removes instrument halt records |
| Trade.TAPI_GetPositionsAggregatedInvestedAmountByInstrumentIds | @InstrumentIDs | Parameter (TVP) | Aggregates invested amounts by instrument for TAPI |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOrderMatchingItemsByInstrumentID_OMEOrders | Stored Procedure | READONLY parameter for OME order matching |
| Trade.GetOrderMatchingItemsByInstrumentID_OmeTrees | Stored Procedure | READONLY parameter for OME tree matching |
| Trade.GetOrderMatchingItemsByInstrumentID_EntryOrders | Stored Procedure | READONLY parameter for entry order matching |
| Trade.GetOrderMatchingItemsByInstrumentID_ExitOrders | Stored Procedure | READONLY parameter for exit order matching |
| Trade.GetOrderMatchingItemsByInstrumentID_OrdersForOpen | Stored Procedure | READONLY parameter for open order matching |
| Trade.GetOrderMatchingItemsByInstrumentID_OrdersForClose | Stored Procedure | READONLY parameter for close order matching |
| Trade.GetInstrumentMarginsForFutures | Stored Procedure | READONLY parameter for futures margin lookup |
| Trade.GetInstrumentInterestRates_TRDOPS | Stored Procedure | READONLY parameter for interest rate lookup |
| Trade.GetCalculatedFeesConfig_TRDOPS | Stored Procedure | READONLY parameter for fee config lookup |
| Trade.GetInstrumentsUpdatableDataForOpsAPI | Stored Procedure | READONLY parameter for ops API data |
| Trade.GetInstrumentSlippage | Stored Procedure | READONLY parameter for slippage lookup |
| Trade.InsertInstrumentHalt | Stored Procedure | READONLY parameter for bulk halt insertion |
| Trade.RemoveInstrumentHalt | Stored Procedure | READONLY parameter for bulk halt removal |
| Trade.TAPI_GetPositionsAggregatedInvestedAmountByInstrumentIds | Stored Procedure | READONLY parameter for TAPI aggregation |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for OME order matching

```sql
DECLARE @Instruments Trade.InstrumentIDsTbl;
INSERT INTO @Instruments (InstrumentID) VALUES (1001), (1002), (1003);
EXEC Trade.GetOrderMatchingItemsByInstrumentID_OMEOrders @InstrumentIDs = @Instruments;
```

### 8.2 Use InstrumentIDsTbl to fetch futures margins

```sql
DECLARE @FuturesInstruments Trade.InstrumentIDsTbl;
INSERT INTO @FuturesInstruments (InstrumentID)
SELECT  InstrumentID
FROM    Trade.Instrument WITH (NOLOCK)
WHERE   InstrumentTypeID = 14;

EXEC Trade.GetInstrumentMarginsForFutures @InstrumentIDs = @FuturesInstruments;
```

### 8.3 Use InstrumentIDsTbl to bulk-halt instruments

```sql
DECLARE @ToHalt Trade.InstrumentIDsTbl;
INSERT INTO @ToHalt (InstrumentID) VALUES (2001), (2002);
EXEC Trade.InsertInstrumentHalt @InstrumentIDs = @ToHalt;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentIDsTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentIDsTbl.sql*
