# Function_Population_First_Trading_Action

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Population / Cohort |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 20 (T1: 2, T2: 18) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Returns each customer’s **first eligible trading-platform action** row: **`Fact_CustomerAction`** with **`ActionTypeID IN (1, 17, 39)`** (open / mirror-style opens), **`(IsAirDrop = 0 OR IsAirDrop IS NULL)`**, ordered by **`DateID`, `Occurred`**, **`ROW_NUMBER` = 1** per `RealCID`. Optional **`@IsDepositor`** filters to **`Dim_Customer.IsDepositor = 1`**. **FirstActionType** rolls up instrument type and copy-fund mirror type.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @IsDepositor | BIT | 0 = all, 1 = depositors only |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Fact_CustomerAction | DWH_dbo |
| Dim_Instrument | DWH_dbo |
| Dim_Mirror | DWH_dbo |
| Dim_Customer | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | RealCID | Fact_CustomerAction.RealCID | From row **WHERE** `ActionTypeID IN (1,17,39)` and airdrop excluded, **`RN = 1`** | T2 |
| 2 | PositionID | Fact_CustomerAction.PositionID | Same first-action filter as row 1 | T2 |
| 3 | InstrumentID | Fact_CustomerAction.InstrumentID | Same first-action filter as row 1 | T2 |
| 4 | Instrument | Dim_Instrument.Name | Joined on first-action `InstrumentID` | T2 |
| 5 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | Same join as row 4 | T2 |
| 6 | InstrumentType | Dim_Instrument.InstrumentType | Same join as row 4 | T2 |
| 7 | IsSettled | Fact_CustomerAction.IsSettled | Same first-action filter as row 1 | T5 |
| 8 | MirrorID | Fact_CustomerAction.MirrorID | Same first-action filter as row 1 | T2 |
| 9 | Exchange | Dim_Instrument.Exchange | Same join as row 4 | T2 |
| 10 | ISINCode | Dim_Instrument.ISINCode | Same join as row 4 | T2 |
| 11 | IsAirDrop | Fact_CustomerAction.IsAirDrop | `ISNULL(IsAirDrop, 0)` on first-action row (expected 0 given `WHERE`) | T2 |
| 12 | RN | Fact_CustomerAction | `ROW_NUMBER() OVER (PARTITION BY RealCID ORDER BY DateID, Occurred)`; output keeps **`RN = 1`** | T2 |
| 13 | IsCopyFund | Dim_Mirror.MirrorTypeID | `CASE WHEN ISNULL(MirrorTypeID, 0) = 4 THEN 1 ELSE 0 END` on first-action row | T2 |
| 14 | FirstTradeDateID | Fact_CustomerAction.DateID | **`DateID` WHERE** same **`ActionTypeID IN (1,17,39)`** and airdrop filter, **`RN = 1`** | T2 |
| 15 | Occurred | Fact_CustomerAction.Occurred | **`Occurred` WHERE** same filters as row 14 | T2 |
| 16 | IsDepositor | Dim_Customer.IsDepositor | Direct from `Dim_Customer` | T2 |
| 17 | FirstDepositDate | Dim_Customer.FirstDepositDate | Direct from `Dim_Customer` | T2 |
| 18 | FirstTradeDate | Fact_CustomerAction.Occurred | **`Occurred AS FirstTradeDate`** — same value as row 15 on first-action row | T2 |
| 19 | FirstDepositDateID | Dim_Customer.FirstDepositDate | `CAST(FORMAT(CAST(FirstDepositDate AS DATE), 'yyyyMMdd') AS INT)` | T2 |
| 20 | FirstActionType | Dim_Instrument, Fact_CustomerAction | `CASE` on `InstrumentTypeID`, `MirrorID`, `IsCopyFund` → Forex / Crypto / Copy / Copy Fund / Stocks / NA | T2 |

## 5. Change History (only if found in SQL comments)

| Date | Author | Description |
|------|--------|-------------|
| 2025-11-26 | Guy M | First instrument + exchange (US stock context) |

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
