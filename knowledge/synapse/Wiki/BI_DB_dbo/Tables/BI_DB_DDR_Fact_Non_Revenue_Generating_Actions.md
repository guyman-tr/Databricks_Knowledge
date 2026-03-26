# BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions

> 1.8B-row DDR non-revenue actions fact table — daily per-customer aggregated counts and amounts for logins, registrations, copy operations, investments, compensations, social activity, and bonus/PnL adjustments, powering the DDR Daily Data Report engagement and operational metrics.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact — DDR non-revenue actions) |
| **Production Source** | Derived from `Fact_CustomerAction`, `Dim_ActionType`, `Dim_CompensationReason`, `Dim_Position`, `Dim_Mirror`, `Fact_SnapshotCustomer` via `SP_DDR_Fact_Non_Revenue_Generating_Actions` |
| **Refresh** | Daily — `DELETE WHERE DateID = @dateID` + `INSERT` per business date |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_DDR_Fact_Non_Revenue_Generating_Actions` stores **non-revenue customer actions** for the DDR framework. While revenue-generating activities (spreads, fees, commissions) are tracked in other DDR fact tables, this table captures **engagement and operational activities**: logins, registrations, copy operations, trade investments, compensations, social activity, and adjustments.

Each row represents a **CID + Date + ActionType + IsCopyFund** combination with aggregated `Amount` and `CountActions`. The grain is finer than customer-day but coarser than individual transactions.

The table was created in July 2024 by Guy Manova. Key additions include IsCopyFund (May 2025), BonusComp (Nov 2025), and C2P compensations (Nov 2025).

**ETL**: `SP_DDR_Fact_Non_Revenue_Generating_Actions` runs daily (Priority 60, SB_Daily). It deletes and reinserts rows for a single `@dateID`.

Data spans from 2007-08-27 to present with ~1.8B rows across ~44M distinct CIDs.

---

## 2. Business Logic

### 2.1 Action Type Classification

**What**: Maps raw `ActionTypeID` + `CompensationReasonID` from `Fact_CustomerAction` into business-friendly action type strings.

**Columns Involved**: `ActionType`, `Amount`

**Action Type Mapping**:

| ActionType String | ActionTypeID | CompensationReasonID | Amount Sign |
|-------------------|-------------|---------------------|-------------|
| CompensationRAFInvitedInviting | 36 | 53, 54 | Positive |
| CompensationOther | 36 | NOT IN (41,50,51,52,53,54) | Positive |
| CompensationPIWithCashout | 36 | 41 | Positive |
| CompensationPINoCashout | 36 | 50 | Positive |
| CompensationToAffiliateWithCashout | 36 | 51 | Positive |
| CompensationToAffiliateNoCashout | 36 | 52 | Positive |
| C2P | 36 | 134 | Positive |
| PnLAdjustment | 36 | 22 | Positive |
| EditStoploss | 32 | — | Negative (−1 × Amount) |
| InvestmentAmountInNewTrades | 1, 2, 3, 39 | — | Negative (−1 × Amount) |
| InvestmentAmountClosedTrades | 4, 5, 6, 28, 40 | — | Positive |
| DepositorsLoggedIn | 14 | — (IsDepositor=1) | 0 |
| LoggedIn | 14 | — (IsDepositor=0) | 0 |
| Registred | 41 | — | 0 |
| AddToCopy | 15 | — | Negative (−1 × Amount) |
| RemoveFromCopy | 16 | — | Positive |
| NewCopy | 17 | — | Negative (−1 × Amount) |
| StopCopy | 18 | — | Positive |
| PublishPost | 21 | — | 0 |
| PublishComment | 22 | — | 0 |
| PublishLike | 23 | — | 0 |
| BonusComp | 9 | — | Positive |

Rows with ActionType = 'NA' are excluded from the final insert.

### 2.2 IsCopyFund Detection

**What**: Identifies whether the action is related to a copy fund (CopyPortfolio).

**Columns Involved**: `IsCopyFund`

**Rules**:
- Joins `Fact_CustomerAction.PositionID` → `Dim_Position.MirrorID` → `Dim_Mirror` where `MirrorTypeID = 4`
- Also checks `Fact_CustomerAction.MirrorID` directly for actions without position IDs (e.g., money allocation to copy)
- `IsCopyFund = 1` when either mirror path yields a valid MirrorID

### 2.3 Depositor Login Split

**What**: Logins (ActionTypeID 14) are split into two categories based on depositor status.

**Rules**:
- `DepositorsLoggedIn` — customer has `IsDepositor = 1` in `Fact_SnapshotCustomer` for the date range
- `LoggedIn` — customer is not a depositor

### 2.4 Amount Sign Convention

**What**: Amounts are sign-adjusted to represent economic direction.

**Rules**:
- **Negative**: Money going into positions/copies (new trades, add to copy, new copy, edit stoploss)
- **Positive**: Money coming out (closed trades, remove from copy, stop copy, compensations)
- **Zero**: Non-financial actions (logins, registrations, social activity)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(RealCID) with CLUSTERED COLUMNSTORE. Always filter on `DateID` and `ActionType` for optimal performance. The 1.8B row count means full scans are expensive.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily depositor logins | `WHERE ActionType = 'DepositorsLoggedIn' AND DateID = @dateID` |
| New trades investment | `WHERE ActionType = 'InvestmentAmountInNewTrades' AND DateID = @dateID` |
| Copy operations by type | `WHERE ActionType IN ('NewCopy','StopCopy','AddToCopy','RemoveFromCopy')` |
| Compensation breakdown | `WHERE ActionType LIKE 'Compensation%'` |
| FTD registrations | `WHERE ActionType = 'Registred'` (note spelling) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID | Customer attributes |
| DWH_dbo.Dim_Date | DateID | Calendar dimension |
| BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | RealCID + DateID | Customer segmentation for DDR |

### 3.4 Gotchas

- **"Registred" spelling**: The ActionType value is `'Registred'` (not "Registered") — preserved from original code.
- **Amount sign convention**: Negative amounts mean money flowing into positions (investments), not losses. Always check the ActionType context.
- **IsCopyFund workaround**: The SP notes that `Fact_CustomerAction` doesn't have MirrorID for ActionTypeID 5, requiring a position-based lookup.
- **Multiple aggregation levels**: Data is GROUP BY CID + ActionType + IsCopyFund, so a single CID can have multiple rows per day (one per action type + copy flag combination).
- **ActionTypeID 36 is highly overloaded**: One ActionTypeID maps to 8 different ActionType strings based on CompensationReasonID.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — Synapse SP code | (Tier 2 — SP_DDR_Fact_Non_Revenue_Generating_Actions) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Business date as YYYYMMDD integer. Delete/replace key. CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). (Tier 2 — SP_DDR_Fact_Non_Revenue_Generating_Actions) |
| 2 | Date | date | YES | Calendar date — equals parameter `@date`. (Tier 2 — SP_DDR_Fact_Non_Revenue_Generating_Actions) |
| 3 | RealCID | int | YES | Real customer ID from Fact_CustomerAction. HASH distribution key. (Tier 2 — SP_DDR_Fact_Non_Revenue_Generating_Actions) |
| 4 | ActionType | varchar(100) | YES | Business-friendly action type. CASE mapping from ActionTypeID + CompensationReasonID — 20+ categories including CompensationRAFInvitedInviting, InvestmentAmountInNewTrades, DepositorsLoggedIn, NewCopy, BonusComp, C2P, etc. See §2.1 for full mapping. (Tier 2 — SP_DDR_Fact_Non_Revenue_Generating_Actions) |
| 5 | Amount | decimal(16,6) | YES | Aggregated amount in USD. SUM with sign convention: negative for money into positions/copies, positive for money out, 0 for non-financial actions. (Tier 2 — SP_DDR_Fact_Non_Revenue_Generating_Actions) |
| 6 | CountActions | int | YES | Count of individual actions in this group. SUM(COUNT(RealCID)) per CID/DateID/ActionType/IsCopyFund. (Tier 2 — SP_DDR_Fact_Non_Revenue_Generating_Actions) |
| 7 | UpdateDate | datetime | YES | ETL load timestamp — GETDATE() at insert time. (Tier 2 — SP_DDR_Fact_Non_Revenue_Generating_Actions) |
| 8 | IsCopyFund | int | YES | Copy fund flag. 1 when action relates to a CopyPortfolio (MirrorTypeID=4 in Dim_Mirror, checked via both Dim_Position.MirrorID and Fact_CustomerAction.MirrorID). Added May 2025. (Tier 2 — SP_DDR_Fact_Non_Revenue_Generating_Actions) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column Group | Production Source | Key Columns | Transform |
|---------------------|-------------------|-------------|-----------|
| Core (cols 1-3) | Fact_CustomerAction + SP params | RealCID, DateID | passthrough |
| ActionType (col 4) | Fact_CustomerAction + Dim_ActionType + Dim_CompensationReason | ActionTypeID, CompensationReasonID | CASE mapping to 20+ categories |
| Amount (col 5) | Fact_CustomerAction | Amount | SUM with sign flip per action type |
| CountActions (col 6) | Fact_CustomerAction | COUNT(RealCID) | Aggregated |
| IsCopyFund (col 8) | Dim_Position + Dim_Mirror | MirrorID, MirrorTypeID | CASE check |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (for @dateID)
  +
DWH_dbo.Dim_ActionType (action type name)
DWH_dbo.Dim_CompensationReason (compensation reason name)
DWH_dbo.Dim_Position (position → mirror mapping)
DWH_dbo.Dim_Mirror (MirrorTypeID = 4 check)
DWH_dbo.Fact_SnapshotCustomer + Dim_Range (IsDepositor flag)
  |
  └─ #fcaPrep → #fca (GROUP BY + mirror join)
       └─ #fcaBizPrep (CASE mapping to business names)
            └─ #fcaBiz (final GROUP BY, exclude NULL/NA)
                 |
                 └─ SP_DDR_Fact_Non_Revenue_Generating_Actions(@date) [Priority 60, SB_Daily]
                      |-- DELETE WHERE DateID = @dateID
                      |-- INSERT from #fcaBiz WHERE ActionType <> 'NA'
                      v
                 BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions (1.8B rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |
| DateID | DWH_dbo.Dim_Date | Calendar dimension |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Generating_Actions | — | DDR view on this fact for aggregation functions |

---

## 7. Sample Queries

### 7.1 Daily depositor login count

```sql
SELECT DateID, SUM(CountActions) AS LoginCount
FROM BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions
WHERE ActionType = 'DepositorsLoggedIn'
  AND DateID BETWEEN 20260301 AND 20260310
GROUP BY DateID
ORDER BY DateID
```

### 7.2 Investment in new trades by month

```sql
SELECT DateID / 100 AS YearMonth,
       SUM(ABS(Amount)) AS TotalInvestment,
       SUM(CountActions) AS TradeCount
FROM BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions
WHERE ActionType = 'InvestmentAmountInNewTrades'
  AND DateID BETWEEN 20260101 AND 20260310
GROUP BY DateID / 100
ORDER BY YearMonth
```

### 7.3 Compensation breakdown by type

```sql
SELECT ActionType,
       SUM(Amount) AS TotalAmount,
       SUM(CountActions) AS Count
FROM BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions
WHERE ActionType LIKE 'Compensation%'
  AND DateID = 20260310
GROUP BY ActionType
ORDER BY TotalAmount DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-26 | Quality: 8.5/10 (★★★★☆) | Phases: 12/14*
*Tiers: 0 T1, 8 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions | Type: Table | Production Source: SP_DDR_Fact_Non_Revenue_Generating_Actions*
