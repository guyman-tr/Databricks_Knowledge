# Dealing_dbo.Dealing_Best_Execution_Compensation_HBC_HOLD

> **Decommissioned May 2023** — frozen HOLD snapshot of **position-level best-execution compensation** for the **HBC** LP routing context (**HSBC → BofA → Citadel** order); same column layout as **CBH_HOLD** but materially smaller volume, reflecting narrower routing penetration.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | N/A — frozen snapshot; writer SP not in current SSDT |
| **Refresh** | Frozen — decommissioned |
| | |
| **Synapse Distribution** | HASH(`CID`) |
| **Synapse Index** | CLUSTERED INDEX (`Date` ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Dealing_Best_Execution_Compensation_HBC_HOLD` is the **HBC** routing twin of **`Dealing_Best_Execution_Compensation_CBH_HOLD`**: same **business question** (did execution meet best execution, what was the **LP rate**, what **compensation** does policy allow / record?) and the **same 48-column layout**, but populated for positions that flowed through the **HBC** stack.

**HBC routing (documentation convention for this wiki)**: **HSBC / BofA / Citadel** LP routing ordering — inverse emphasis compared with **CBH** (**Citadel / BofA / HSBC** on the sibling table). Analysts reconciling **routing mix** should read **both** HOLD wikis side by side.

**Volume signal**: on the order of **~49,413 rows** over **2022-06-01 → 2023-05-16** versus **~10.2M** rows in **CBH_HOLD** — consistent with **HBC** being a **smaller** execution path (narrower instrument / client / routing rules — confirm with Dealing if precise gate logic is required).

**Freeze alignment**: last business date **2023-05-16**, last pipeline touch **2023-05-17** — **same** as **CBH_HOLD**, indicating a **single coordinated** compensation pipeline shutdown for both variants.

**PII**: `CID` (also the **HASH** distribution key).

---

## 2. Business Logic

All **business rules** mirror **`Dealing_Best_Execution_Compensation_CBH_HOLD`**:

- **Slippage**: `SlippageInDollar`, `[slippage %]`, `ChosenToTrigger`, `TriggerToReceived`.
- **LP transparency**: `Bid`, `Ask`, `Spread`, `LP_Rate`, `Percent_Diff` vs `CustomerChosenRate` / `ClientViewRate`.
- **Compensation**: `Compensation_Limit` caps **`Compensation`**; `OverThreshold` marks eligibility; `IsDiscounted` flags discounted paths.
- **Timing**: `Occurred`, `OccurredAtServer`, `FinalOccurred`, `RequestTime`.
- **Routing detail**: `LiquidityAccountID`, `LiquidityAccountName` identify the **HBC** sub-account / venue slice (parallel semantics to CBH columns).

Because the writer SP is **absent** from repo, treat formulas as **documented inference** — validate with historical exports or Dealing SMEs before legal or regulatory submissions.

---

## 3. Query Advisory

- **HASH(`CID`)** + **cluster on `Date`**: same guidance as **CBH_HOLD** — predicate on **`Date`** first; use **`CID`** for client-scoped queries to stay distribution-local.
- **Small absolute row count** (~49K total): full-table scans are **cheaper** than for CBH, but still apply **date** filters for consistency with adjacent pipelines.
- **Joins**: `DWH_dbo.Dim_Instrument` on `InstrumentID`; customer dims on **`CID`** (PII).
- **Compare variants**: use **UNION ALL** with a variant column when stacking **CBH_HOLD** vs **HBC_HOLD** (see Sample Queries).

---

## 4. Elements

### Confidence Tier Legend

> Identical schema to **CBH_HOLD**; descriptions follow the same **structure-first** tiering (no live SP trace).

| Stars | Tier | Inline tag (in Description) |
|-------|------|------------------------------|
| ★★★★ | Tier 1 — upstream wiki | `(Tier 1 — upstream wiki, …)` |
| ★★★ | Tier 2 — structure / DDL | `(Tier 2 — inferred from structure)` or `(Tier 2 — DDL)` |
| ★★ | Tier 3 — live data | `(Tier 3 — live data)` |
| ★ | Tier 4 — inferred | `(Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date of the execution / compensation analysis row. (Tier 2 — inferred from structure) |
| 2 | PositionID | bigint | YES | Trade position identifier. (Tier 2 — inferred from structure) |
| 3 | CID | int | YES | **Customer ID** — **PII**; **HASH** distribution key. (Tier 2 — inferred from structure) |
| 4 | InstrumentID | int | YES | Instrument key. (Tier 2 — inferred from structure) |
| 5 | InstrumentName | varchar(50) | YES | Display name. (Tier 2 — inferred from structure) |
| 6 | InstrumentTypeID | int | YES | Instrument type code. (Tier 2 — inferred from structure) |
| 7 | InstrumentType | varchar(50) | YES | Instrument type label. (Tier 2 — inferred from structure) |
| 8 | HedgeServerID | int | YES | Hedge server routing id. (Tier 2 — inferred from structure) |
| 9 | MirrorID | int | YES | Copy / mirror id (**0** = not copy). (Tier 2 — inferred from structure) |
| 10 | IsBuy | int | YES | Direction **1** buy / **0** sell. (Tier 2 — inferred from structure) |
| 11 | OrigIsBuy | int | YES | Pre-reversal direction. (Tier 2 — inferred from structure) |
| 12 | ExecutionAmountInUnits | decimal(16,8) | YES | LP units (8 dp). (Tier 2 — inferred from structure) |
| 13 | AmountInUnitsDecimal | decimal(16,6) | YES | Position units (6 dp). (Tier 2 — inferred from structure) |
| 14 | Occurred | datetime | YES | Execution time. (Tier 2 — inferred from structure) |
| 15 | EndForexRate | decimal(16,8) | YES | FX at execution. (Tier 2 — inferred from structure) |
| 16 | ConversionRate | decimal(16,8) | YES | USD normalisation. (Tier 2 — inferred from structure) |
| 17 | ActionTypeID | int | YES | Action code. (Tier 2 — inferred from structure) |
| 18 | ActionType | varchar(50) | YES | Action label. (Tier 2 — inferred from structure) |
| 19 | IsOpen | int | YES | Open vs closed. (Tier 2 — inferred from structure) |
| 20 | Bid | float | YES | LP bid. (Tier 2 — inferred from structure) |
| 21 | Ask | float | YES | LP ask. (Tier 2 — inferred from structure) |
| 22 | OccurredAtServer | datetime | YES | Server receipt time. (Tier 2 — inferred from structure) |
| 23 | StopRate | decimal(16,8) | YES | Stop rate. (Tier 2 — inferred from structure) |
| 24 | LimitRate | decimal(16,8) | YES | Limit rate. (Tier 2 — inferred from structure) |
| 25 | ClientViewRate | numeric(16,8) | YES | UI rate. (Tier 2 — inferred from structure) |
| 26 | CustomerChosenRate | decimal(16,8) | YES | Client-accepted rate. (Tier 2 — inferred from structure) |
| 27 | SlippageInDollar | money | YES | USD slippage. (Tier 2 — inferred from structure) |
| 28 | slippage % | decimal(38,21) | YES | Slippage percent; bracket in SQL. (Tier 2 — inferred from structure) |
| 29 | RequestTime | datetime | YES | Request timestamp. (Tier 2 — inferred from structure) |
| 30 | OverThreshold | tinyint | YES | Threshold breach flag. (Tier 2 — inferred from structure) |
| 31 | OpenSession | int | YES | Open session code. (Tier 2 — inferred from structure) |
| 32 | Volume | int | YES | Volume. (Tier 2 — inferred from structure) |
| 33 | Regulation | varchar(50) | YES | Regulation label. (Tier 2 — inferred from structure) |
| 34 | TriggerRate | decimal(16,8) | YES | Trigger rate. (Tier 2 — inferred from structure) |
| 35 | ChosenToTrigger | money | YES | Chosen → trigger component. (Tier 2 — inferred from structure) |
| 36 | TriggerToReceived | money | YES | Trigger → fill component. (Tier 2 — inferred from structure) |
| 37 | IsDiscounted | int | YES | Discounted path flag. (Tier 2 — inferred from structure) |
| 38 | PriceRateID | bigint | YES | Price feed id. (Tier 2 — inferred from structure) |
| 39 | FinalOccurred | datetime | YES | Final fill time. (Tier 2 — inferred from structure) |
| 40 | HedgingMode | varchar(10) | YES | Hedging mode. (Tier 2 — inferred from structure) |
| 41 | LiquidityAccountID | int | YES | **HBC** LP sub-account id. (Tier 2 — inferred from structure) |
| 42 | LiquidityAccountName | varchar(50) | YES | **HBC** LP sub-account label. (Tier 2 — inferred from structure) |
| 43 | Spread | decimal(16,6) | YES | Execution spread. (Tier 2 — inferred from structure) |
| 44 | LP_Rate | float | YES | LP execution rate (**HBC** path). (Tier 2 — inferred from structure) |
| 45 | Percent_Diff | float | YES | Client vs LP percent gap. (Tier 2 — inferred from structure) |
| 46 | Compensation_Limit | decimal(16,6) | YES | Policy cap. (Tier 2 — inferred from structure) |
| 47 | Compensation | decimal(16,6) | YES | Recorded compensation. (Tier 2 — inferred from structure) |
| 48 | UpdateDate | datetime | YES | ETL update timestamp. (Tier 4 — inferred) |

---

## 5. Lineage

See **`Dealing_Best_Execution_Compensation_HBC_HOLD.lineage.md`**. **HBC** and **CBH** HOLD loads **stopped together** (May 2023); narrative is brief because the pipeline is **retired** and **not** mapped to Generic Pipeline.

---

## 6. Relationships

| Object | Relationship |
|--------|--------------|
| `Dealing_dbo.Dealing_Best_Execution_Compensation_CBH_HOLD` | **Structural twin** — **CBH** = **Citadel / BofA / HSBC** ordering; **~200×** more rows — primary comparison for routing volume. |
| `Dealing_dbo.Dealing_Best_Execution_Compensation_HBC` | Non-HOLD **HBC** table (later decommissioned per platform notes). |
| `Dealing_dbo.Daily_Slippage_Positions_HOLD` | Related **client slippage** HOLD snapshot (different freeze date — Jun 2023). |
| `DWH_dbo.Dim_Instrument` | Instrument dimension join. |

---

## 7. Sample Queries

```sql
-- Full HBC HOLD population profile by month
SELECT DATEFROMPARTS(YEAR(Date), MONTH(Date), 1) AS MonthStart,
       COUNT(*) AS Rows,
       SUM(CASE WHEN OverThreshold = 1 THEN 1 ELSE 0 END) AS OverThresholdRows
FROM Dealing_dbo.Dealing_Best_Execution_Compensation_HBC_HOLD
GROUP BY DATEFROMPARTS(YEAR(Date), MONTH(Date), 1)
ORDER BY MonthStart;
```

```sql
-- Positions appearing in BOTH variants (if any) — intersection diagnostic
SELECT h.PositionID, h.Date, h.CID
FROM Dealing_dbo.Dealing_Best_Execution_Compensation_HBC_HOLD h
INNER JOIN Dealing_dbo.Dealing_Best_Execution_Compensation_CBH_HOLD c
  ON h.PositionID = c.PositionID AND h.Date = c.Date;
```

```sql
-- Top compensation rows in HBC path (PII)
SELECT TOP 200 Date, CID, PositionID, InstrumentID, Compensation, Compensation_Limit, LP_Rate, CustomerChosenRate
FROM Dealing_dbo.Dealing_Best_Execution_Compensation_HBC_HOLD
WHERE Compensation <> 0
ORDER BY Date DESC, Compensation DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Quality: 5.5/10 (★★★☆☆) | Batch: 7 (redo)*

*Tiers: 0 T1, 47 T2, 0 T3, 1 T4 | Elements: 5.5/10, Logic: 5.5/10, Relationships: 6/10, Sources: 3/10*

*Object: Dealing_dbo.Dealing_Best_Execution_Compensation_HBC_HOLD | Type: Table | Production Source: N/A (decommissioned)*
