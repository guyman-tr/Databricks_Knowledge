# BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions

> 22.9M-row table storing the first 5 open-position actions for each of 5.4M depositing customers, tracking instrument, leverage, amount, and trade direction from the eToro platform's inception (2007) to present. Refreshed daily by SP_CustomerFirst5OpenPositions via incremental DELETE+INSERT for customers with new positions.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_CustomerAction + DWH_dbo.Dim_Position via SP_CustomerFirst5OpenPositions |
| **Refresh** | Daily (SB_Daily, Priority 0). Incremental: recalculate for customers with new opens yesterday who haven't reached 5 actions yet |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Dan (2020-08-31), IsBuy added by Amir (2020-09-09), logic changes by Eti (2022-07-05, 2022-07-12) |

---

## 1. Business Meaning

`BI_DB_CustomerFirst5OpenPositions` captures the first 5 position-opening actions for each customer across the platform. Each row is one action (up to 5 per customer), ordered chronologically by `ActionNumber` (1 = earliest, 5 = latest of the first five). This table answers "what were a customer's first trades?" — useful for onboarding analysis, first-trade behavior, and cross-selling funnels.

The population includes all valid depositors (IsDepositor=1, IsValidCustomer=1) from Dim_Customer. Only ActionTypeID 1 (Open Position) and 17 (Copy Open) are tracked. AirDrop positions are excluded (IsAirDrop IS NULL).

The SP uses an incremental pattern: each day, it identifies customers who opened new positions yesterday but haven't yet accumulated 5 actions in the table. For these customers, it deletes all existing rows and re-inserts the first ≤5 actions using ROW_NUMBER(). Once a customer reaches ActionNumber=5, they are excluded from future processing.

This table also serves as the data source for the sibling cross tables: `BI_DB_CustomerCross` and `BI_DB_CustomerCross_New`, which are populated in the same SP run.

---

## 2. Business Logic

### 2.1 Action Numbering

**What**: Each customer's actions are numbered chronologically. Only the first 5 are kept.
**Columns Involved**: `ActionNumber`
**Rules**:
- `ROW_NUMBER() OVER(PARTITION BY RealCID ORDER BY Occurred)` — chronological order within customer
- Only rows with ActionNumber < 6 are inserted (first 5 actions)
- Distribution: ActionNumber 1 = 5.4M rows, 2 = 4.9M, 3 = 4.5M, 4 = 4.2M, 5 = 3.9M — attrition is customers with fewer than 5 lifetime actions

### 2.2 Action Type Filter

**What**: Only open-position actions are tracked.
**Columns Involved**: `ActionTypeID`
**Rules**:
- ActionTypeID=1 → Open Position (91% of rows, 5.1M distinct CIDs)
- ActionTypeID=17 → Copy Open (9% of rows, 912K distinct CIDs)
- All other action types are excluded (close, deposit, withdrawal, etc.)
- IsAirDrop IS NULL filter excludes promotional AirDrop positions

### 2.3 Incremental Processing

**What**: The SP avoids reprocessing customers who have already reached their 5-action maximum.
**Rules**:
- Customers with ActionNumber=5 already in the table are excluded (#exclude_users_with_5_actions_already)
- Only customers with at least one Dim_Position opened yesterday (OpenDateID=@yesterdayINT) are processed
- For qualifying customers, ALL existing rows are deleted and the first ≤5 are re-inserted
- Eti's 2022-07-05 change ensures future-dated actions are included when rerunning historical days

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on DateID. Date-range queries are efficient. JOIN to Dim_Customer requires data movement.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer's first 5 actions | `WHERE RealCID = @cid ORDER BY ActionNumber` |
| Distribution of first-action instruments | `WHERE ActionNumber = 1 GROUP BY InstrumentID` |
| Average first-trade amount | `WHERE ActionNumber = 1 SELECT AVG(Amount)` |
| Copy vs direct first trades | `WHERE ActionNumber = 1 GROUP BY CASE WHEN MirrorID = 0 THEN 'Direct' ELSE 'Copy' END` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID = RealCID | Customer demographics |
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Instrument name and type |
| DWH_dbo.Dim_ActionType | ActionTypeID = ActionTypeID | Action type description |

### 3.4 Gotchas

- **Amount is negative**: The Amount column stores investment amounts as negative values (e.g., -50.00). Use ABS(Amount) for positive display.
- **ActionNumber attrition**: Not all customers have 5 rows. Customers with fewer than 5 lifetime open-position actions have fewer rows. ActionNumber 5 has 3.9M rows vs 5.4M for ActionNumber 1.
- **IsBuy from Dim_Position (LEFT JOIN)**: IsBuy comes from a LEFT JOIN to Dim_Position, so it may be NULL if the position record is missing for a Copy Open (ActionTypeID=17).
- **No internal accounts excluded**: Unlike many BI_DB tables, this SP does NOT filter out PlayerLevelID=4 (Internal). It includes all valid depositors.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest |
| Tier 2 | SP code analysis | High |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | NO | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | Occurred | datetime | NO | Timestamp when the position was opened. Passthrough from Fact_CustomerAction.Occurred. (Tier 2 — SP_CustomerFirst5OpenPositions) |
| 3 | ActionTypeID | smallint | NO | Action type identifier. 1=Open Position, 17=Copy Open. Only these two values exist in this table. FK to Dim_ActionType. (Tier 2 — SP_CustomerFirst5OpenPositions) |
| 4 | MirrorID | int | NO | Copy-trading mirror relationship ID. 0=direct (manual) trade, >0=copy trade (FK to Dim_Mirror). (Tier 2 — SP_CustomerFirst5OpenPositions) |
| 5 | InstrumentID | int | NO | Financial instrument identifier. FK to Dim_Instrument. Determines the asset traded (stocks, crypto, FX, etc.). (Tier 2 — SP_CustomerFirst5OpenPositions) |
| 6 | Leverage | int | NO | Position leverage multiplier. 1=unleveraged (real asset), >1=leveraged (CFD). Passthrough from Fact_CustomerAction. (Tier 2 — SP_CustomerFirst5OpenPositions) |
| 7 | Amount | decimal(11,2) | NO | Investment amount for the position (stored as negative values, e.g., -50.00). Passthrough from Fact_CustomerAction. Use ABS() for positive display. (Tier 2 — SP_CustomerFirst5OpenPositions) |
| 8 | DateID | int | NO | Date integer (YYYYMMDD) when the action occurred. Passthrough from Fact_CustomerAction.DateID. Part of clustered index. (Tier 2 — SP_CustomerFirst5OpenPositions) |
| 9 | ActionNumber | bigint | YES | Chronological position number within the customer's trade history (1 = first trade, 5 = fifth trade). ETL-computed: ROW_NUMBER() OVER(PARTITION BY RealCID ORDER BY Occurred). Values 1-5 only. (Tier 2 — SP_CustomerFirst5OpenPositions) |
| 10 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — Propagation) |
| 11 | IsBuy | tinyint | YES | Trade direction flag. 1=Buy, 0=Sell. Passthrough from Dim_Position.IsBuy via PositionID JOIN. May be NULL if position record is missing (LEFT JOIN). Added 2020-09-09 by Amir. (Tier 2 — SP_CustomerFirst5OpenPositions) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | DWH_dbo.Fact_CustomerAction | RealCID | Passthrough |
| Occurred | DWH_dbo.Fact_CustomerAction | Occurred | Passthrough |
| ActionTypeID | DWH_dbo.Fact_CustomerAction | ActionTypeID | Passthrough (filtered to 1, 17) |
| MirrorID | DWH_dbo.Fact_CustomerAction | MirrorID | Passthrough |
| InstrumentID | DWH_dbo.Fact_CustomerAction | InstrumentID | Passthrough |
| Leverage | DWH_dbo.Fact_CustomerAction | Leverage | Passthrough |
| Amount | DWH_dbo.Fact_CustomerAction | Amount | Passthrough |
| DateID | DWH_dbo.Fact_CustomerAction | DateID | Passthrough |
| ActionNumber | — | — | ROW_NUMBER() OVER(PARTITION BY RealCID ORDER BY Occurred) |
| UpdateDate | — | — | GETDATE() |
| IsBuy | DWH_dbo.Dim_Position | IsBuy | LEFT JOIN on PositionID |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (population: IsDepositor=1, IsValidCustomer=1)
  |-- #pop ---|
  v
BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions (exclude ActionNumber=5)
  |-- #exclude_users_with_5_actions_already ---|
  v
DWH_dbo.Dim_Position (OpenDateID=@yesterdayINT, IsAirDrop IS NULL)
  |-- #users_open_positions_yesterday ---|
  v
DWH_dbo.Fact_CustomerAction (ActionTypeID IN (1,17), IsAirDrop IS NULL)
  + DWH_dbo.Dim_Position (IsBuy LEFT JOIN)
  |-- #yesterdayactions ---|
  v
  |-- #ExistingTotalAction (ROW_NUMBER ActionNumber) ---|
  v
  |-- DELETE existing + INSERT WHERE ActionNumber<6 ---|
  v
BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions (22.9M rows)

UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument dimension |
| ActionTypeID | DWH_dbo.Dim_ActionType | Action type dimension |
| MirrorID | DWH_dbo.Dim_Mirror | Copy-trading mirror dimension |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship |
|--------|-------------|
| BI_DB_dbo.BI_DB_CustomerCross | Same SP; reads this table to exclude users with ActionNumber=5 |
| BI_DB_dbo.BI_DB_CustomerCross_New | Same SP; reads this table to exclude users with ActionNumber=5 |

---

## 7. Sample Queries

### 7.1 Customer's First 5 Trades with Instrument Names

```sql
SELECT f.RealCID, f.ActionNumber, f.Occurred, di.Name AS InstrumentName,
       f.Leverage, ABS(f.Amount) AS Amount, f.IsBuy
FROM BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions f
JOIN DWH_dbo.Dim_Instrument di ON f.InstrumentID = di.InstrumentID
WHERE f.RealCID = 12345678
ORDER BY f.ActionNumber
```

### 7.2 First-Trade Instrument Distribution

```sql
SELECT di.Name, COUNT(*) AS first_trades
FROM BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions f
JOIN DWH_dbo.Dim_Instrument di ON f.InstrumentID = di.InstrumentID
WHERE f.ActionNumber = 1
GROUP BY di.Name
ORDER BY first_trades DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 1 T1, 9 T2, 0 T3, 0 T4, 1 T5 | Elements: 11/11, Logic: 9/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions | Type: Table | Production Source: DWH_dbo.Fact_CustomerAction + Dim_Position via SP_CustomerFirst5OpenPositions*
