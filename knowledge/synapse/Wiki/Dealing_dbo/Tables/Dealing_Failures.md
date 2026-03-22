# Dealing_dbo.Dealing_Failures

> Daily aggregation of dealing execution failures by error code, with masked descriptions — the error code distribution table.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.History.OrdersFail`, `PositionFailReal.History.PositionFail`, `etoro.History.OrdersMarketFail` |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on Date |

---

## 1. Business Meaning

This table records the daily count of dealing execution failures grouped by error code. Each row represents one error code with its generalized description and occurrence count for a single day. The descriptions are sanitized: numeric values in the original fail reason are replaced with 'X' to create a generic pattern (e.g., "Position AmountToDeduct was smaller than MinPositionTolerance. MinPositionTolerance: X, AmountToDeduct: X.XXXX").

Three production fail sources are UNIONed:
- `CopyFromLake.etoro_History_OrdersFail` — standard order failures
- `Dealing_staging.PositionFailReal_History_PositionFail_DWH` — real position failures
- `CopyFromLake.etoro_History_OrdersMarketFail` — market order failures

Loaded by `SP_Failures(@Date)` using DELETE+INSERT. Author: Sarah Benchitrit, created 2022-03-23.

---

## 2. Business Logic

### 2.1 Description Masking

**What**: Original fail reasons contain instance-specific values (amounts, IDs). The SP replaces all digits 0-9 with 'X' for non-NULL ErrorCode rows (preserving the pattern). For NULL ErrorCode rows, digits are stripped entirely.

**Columns Involved**: `Description`

**Rules**:
- Non-NULL ErrorCode: nested REPLACE of '0'-'9' with 'X'. One representative FailReason per ErrorCode (ROW_NUMBER PARTITION BY ErrorCode ORDER BY FailOccurred DESC, rn=1).
- NULL ErrorCode: digits replaced with empty string, grouped by resulting pattern.

### 2.2 Companion Table

This table is always loaded together with `Dealing_Failures_Rate` in the same SP call. `Dealing_Failures` provides the error breakdown; `Dealing_Failures_Rate` provides the overall failure ratio.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on Date. Always filter on Date.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Top error codes today | `WHERE Date = @date ORDER BY Count DESC` |
| Error trend over time | `GROUP BY Date, ErrorCode WHERE Date BETWEEN ...` |
| Total failures per day | `SELECT Date, SUM(Count) FROM ... GROUP BY Date` |

### 3.3 Gotchas

- **Description is masked**: Numeric values replaced with 'X'. Cannot reconstruct original error details from this table.
- **NULL ErrorCode**: Some failures have NULL ErrorCode. These are grouped by a digit-stripped FailReason pattern.
- **Multiple fail sources**: UNIONed from 3 sources. Duplicates across sources are eliminated by UNION (not UNION ALL).

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Report date. One day per SP_Failures execution. (Tier 2 — SP_Failures) |
| 2 | ErrorCode | int | YES | Numeric error code from the dealing execution engine. Common codes: 2002=Alignment/Tolerance, 1069=Provider balance, 797=User blocked, 609=General error. See [Error List Page](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/2173337945) for full mapping. NULL when error has no code. (Tier 2 — SP_Failures) |
| 3 | Description | varchar(max) | YES | Generalized fail reason. Numbers replaced with 'X' to create reusable patterns. One representative description per ErrorCode per day. (Tier 2 — SP_Failures) |
| 4 | Count | int | YES | Number of occurrences of this error code on this day. `COUNT(*)` across all three fail sources. (Tier 2 — SP_Failures) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp. `GETDATE()`. (Tier 2 — SP_Failures) |

---

## 5. Lineage

### 5.1 ETL Pipeline

```
OrdersFail + PositionFail + OrdersMarketFail → UNION → #Fails → GROUP BY ErrorCode → Dealing_Failures
```

### 5.2 Production Sources

| Source | Description |
|--------|-------------|
| CopyFromLake.etoro_History_OrdersFail | Standard order execution failures |
| Dealing_staging.PositionFailReal_History_PositionFail_DWH | Real position execution failures (separate database) |
| CopyFromLake.etoro_History_OrdersMarketFail | Market order execution failures |

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| ErrorCode | Error List Page (Confluence) | Maps to dealing error code definitions |

### 6.2 Companion Objects

| Object | Relationship |
|--------|-------------|
| Dealing_dbo.Dealing_Failures_Rate | Loaded by same SP. Provides overall failure ratio. |

---

## 7. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Error List Page](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/2173337945) | Confluence | Full error code descriptions and meanings |
| [HBC Execution Monitoring](https://etoro-jira.atlassian.net/wiki/spaces/TKB/pages/11858675769) | Confluence | Possible execution failures and their cost implications |
| SR-286854 | Jira | Replaced execution log path with CopyFromLake |

---

*Generated: 2026-03-21 | Quality: 7.2/10 (★★★★☆) | Phases: 7/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 8/10*
*Object: Dealing_dbo.Dealing_Failures | Type: Table | Production Source: Derived (multi-source ETL)*
