# Dealing_Fails_PI

## 1. Business Meaning

Row-level position fail detail table — one row per individual failed trade attempt. This is the highest-resolution fail tracking table in the Dealing_dbo schema: every failed position open, close, or hedge attempt is recorded here with full context including client, instrument, raw fail reason, classified error type, and hedge server routing.

Despite the `_PI` name, this table covers **all clients**, not just Popular Investors. The `IsPI` column flags PI-status clients inline. The name reflects the SP that writes it (`SP_Fails_PI`) rather than the population scope.

**Scale and activity:** January 2022 to 2026-03-10. **3.97 billion rows** — the largest table in Dealing_dbo by far. Row count required `COUNT_BIG(*)` to avoid INT overflow. Source is `Dealing_staging.PositionFailReal_History_PositionFail_DWH` (distinct from the `CopyFromLake.*` path used by the CommissionsAndFails family). Active daily pipeline.

**Key design features:**
- `Generic_FailReason` maps the numeric `ErrorCode` to a symbolic name via the `Dealing_Fails_PI_ErrorCodes` lookup (e.g., `INSUFFICIENT_FUNDS_ERROR`)
- `HedgeFailReason` extracts the hedge-server-specific detail from within the composite `FailReason` string (after `HedgeFailReason:` marker)
- `ErrorType` classifies fails as Opening / Closing / Hedging / Other based on CHARINDEX patterns
- `IsCopy` distinguishes manual trades from CopyTrading positions (MirrorID != 0)

## 2. Business Logic

### 2.1 Source and Scope

Written by `SP_Fails_PI`, which reads from `Dealing_staging.PositionFailReal_History_PositionFail_DWH`. This is the **staging-side** copy of PositionFail, not the CopyFromLake path. Standard DELETE/INSERT pattern on @Date:

```sql
DELETE FROM Dealing_dbo.Dealing_Fails_PI WHERE Date = @Date
INSERT INTO Dealing_dbo.Dealing_Fails_PI
SELECT ...
FROM Dealing_staging.PositionFailReal_History_PositionFail_DWH pf
LEFT JOIN DWH_dbo.Dim_Customer dc ON pf.CID = dc.RealCID
LEFT JOIN DWH_dbo.Dim_Instrument di ON pf.InstrumentID = di.InstrumentID
LEFT JOIN Dealing_dbo.Dealing_Fails_PI_ErrorCodes ec ON pf.ErrorCode = ec.ErrorCode
LEFT JOIN DWH_dbo.Fact_SnapshotCustomer sc ON ...
WHERE pf.FailOccurred >= @Date AND pf.FailOccurred < @NextDate
```

### 2.2 Error Type Classification

```sql
ErrorType = CASE
  WHEN CHARINDEX('Error closing', FailReason) > 0 THEN 'Closing'
  WHEN CHARINDEX('Error opening', FailReason) > 0 THEN 'Opening'
  WHEN CHARINDEX('Error hedging', FailReason) > 0 THEN 'Hedging'
  ELSE 'Other'
END
```

### 2.3 HedgeFailReason Extraction

The raw `FailReason` string is sometimes a composite like `"Error opening position. HedgeFailReason: REJECT_BY_RISK_MANAGEMENT"`. The SP extracts the hedge-specific part:

```sql
HedgeFailReason = CASE
  WHEN CHARINDEX('HedgeFailReason:', FailReason) > 0
  THEN SUBSTRING(FailReason, CHARINDEX('HedgeFailReason:', FailReason) + 17, LEN(FailReason))
  ELSE FailReason
END
```

### 2.4 PI Flag

```sql
IsPI = CASE WHEN sc.GuruStatusID IN (5,6) THEN 1 ELSE 0 END
```

Joined from `DWH_dbo.Fact_SnapshotCustomer` at `@Date`. Reflects PI status on the run date, not historical status.

### 2.5 IsCopy Flag

```sql
IsCopy = CASE WHEN pf.MirrorID = 0 THEN 0 ELSE 1 END
```

MirrorID = 0 means the position was placed manually. Any non-zero MirrorID indicates a copied position (CopyTrading).

## 3. Query Advisory

**Distribution:** ROUND_ROBIN, **3.97 billion rows**. Always filter on `Date` first — this is the partition key for DELETE/INSERT. Full table scans will be very expensive.

**COUNT(*) overflow risk:** This table exceeds INT range. Use `COUNT_BIG(*)` for row-count queries:

```sql
SELECT COUNT_BIG(*) FROM Dealing_dbo.Dealing_Fails_PI WHERE Date = '2026-03-10'
```

**Two fail reason columns:** `FailReason` is the raw platform text; `Generic_FailReason` is the human-readable symbolic name from ErrorCodes lookup. For aggregation and reporting use `Generic_FailReason` or `ErrorType`. For debugging specific hedge-server rejections use `HedgeFailReason`.

```sql
-- Error type distribution for a given date
SELECT Date, ErrorType, IsPI,
    COUNT_BIG(*) AS fail_count
FROM Dealing_dbo.Dealing_Fails_PI
WHERE Date = '2026-03-10'
GROUP BY Date, ErrorType, IsPI
ORDER BY fail_count DESC

-- CopyTrade vs Manual fail breakdown
SELECT Date,
    SUM(CASE WHEN IsCopy = 1 THEN 1 ELSE 0 END) AS copy_fails,
    SUM(CASE WHEN IsCopy = 0 THEN 1 ELSE 0 END) AS manual_fails
FROM Dealing_dbo.Dealing_Fails_PI
WHERE Date >= '2026-03-01'
GROUP BY Date
ORDER BY Date DESC
```

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| Date | date | Business date (partition key). Equals `@Date` SP parameter. (Tier 2 — SP_Fails_PI) |
| FailOccurred | datetime | Exact datetime the fail event was recorded. More precise than Date. (Tier 2 — Trade.PositionFail passthrough) |
| CID | int | Client account ID of the failing trade. (Tier 2 — Trade.PositionFail passthrough) |
| UserName | nvarchar | Display name of the client. Joined from `DWH_dbo.Dim_Customer`. (Tier 2 — join-enriched) |
| InstrumentID | int | Instrument that failed to trade. (Tier 2 — Trade.PositionFail passthrough) |
| InstrumentDisplayName | nvarchar | Human-readable instrument name. Joined from `DWH_dbo.Dim_Instrument`. (Tier 2 — join-enriched) |
| FailReason | nvarchar | Raw unclassified fail reason string from the trading platform. May be composite (contains `HedgeFailReason:` sub-marker). (Tier 2 — Trade.PositionFail passthrough) |
| ErrorCode | int | Numeric platform error code. Join to `Dealing_Fails_PI_ErrorCodes` for symbolic name. (Tier 2 — Trade.PositionFail passthrough) |
| Generic_FailReason | varchar | Symbolic error name from error code lookup (e.g., `INSUFFICIENT_FUNDS_ERROR`). NULL if ErrorCode not in lookup table. (Tier 2 — join-enriched from Dealing_Fails_PI_ErrorCodes) |
| UpdateDate | datetime | Row insertion timestamp (GETDATE()). Not a business date. (Tier 2 — SP_Fails_PI) |
| HedgeFailReason | nvarchar | Hedge-server-specific failure detail extracted from composite FailReason string. Falls back to full FailReason when no `HedgeFailReason:` marker present. (Tier 2 — ETL-computed) |
| ErrorType | varchar | Fail category: `Opening` / `Closing` / `Hedging` / `Other`. Based on CHARINDEX patterns in FailReason. (Tier 2 — ETL-computed) |
| HedgeServerID | int | Hedge server that processed the request. NULL = platform-level rejection before routing. (Tier 2 — Trade.PositionFail passthrough) |
| IsCopy | bit | 1 = CopyTrading position (MirrorID ≠ 0); 0 = manual trade. (Tier 2 — ETL-computed from MirrorID) |
| IsPI | bit | 1 = Popular Investor (GuruStatusID IN (5,6)) at time of SP run. (Tier 2 — ETL-computed from Fact_SnapshotCustomer) |
| Amount | decimal | Attempted position amount in USD at time of failure. (Tier 2 — Trade.PositionFail passthrough) |

## 5. Lineage

| Source | Role |
|--------|------|
| `Dealing_staging.PositionFailReal_History_PositionFail_DWH` | Primary: raw fail rows (CID, InstrumentID, FailReason, ErrorCode, HedgeServerID, Amount, MirrorID) |
| `DWH_dbo.Dim_Customer` | UserName enrichment |
| `DWH_dbo.Dim_Instrument` | InstrumentDisplayName enrichment |
| `DWH_dbo.Fact_SnapshotCustomer` | GuruStatusID for IsPI flag |
| `Dealing_dbo.Dealing_Fails_PI_ErrorCodes` | ErrorCode → Generic_FailReason lookup |

**ETL:** `Dealing_dbo.SP_Fails_PI` → `Dealing_dbo.Dealing_Fails_PI`

**Coverage:** January 2022 to present (active).

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Fails_PI_ErrorCodes` | Lookup table for ErrorCode → Generic_FailReason (234 codes) |
| `Dealing_dbo.Dealing_FailReasons` | Aggregated version — same source, 28-bucket classification, no row-level detail |
| `Dealing_dbo.Dealing_FailReasons_PIs` | Aggregated PI-only version |
| `Dealing_dbo.Dealing_PlayerLevel_Fails` | Aggregated by PlayerLevel — cross-tier fail analysis |

## 7. Sample Queries

```sql
-- PI fails on a specific date with instrument breakdown
SELECT Date, InstrumentDisplayName, ErrorType,
    COUNT_BIG(*) AS fail_count
FROM Dealing_dbo.Dealing_Fails_PI
WHERE Date = '2026-03-10'
  AND IsPI = 1
GROUP BY Date, InstrumentDisplayName, ErrorType
ORDER BY fail_count DESC

-- Top Generic_FailReasons for Closing failures in the last month
SELECT Generic_FailReason,
    COUNT_BIG(*) AS fail_count
FROM Dealing_dbo.Dealing_Fails_PI
WHERE Date >= '2026-02-10'
  AND ErrorType = 'Closing'
GROUP BY Generic_FailReason
ORDER BY fail_count DESC

-- Hedge server failure rate by day (hedging errors only)
SELECT Date, HedgeServerID,
    COUNT_BIG(*) AS hedging_fails
FROM Dealing_dbo.Dealing_Fails_PI
WHERE Date BETWEEN '2026-03-01' AND '2026-03-10'
  AND ErrorType = 'Hedging'
  AND HedgeServerID IS NOT NULL
GROUP BY Date, HedgeServerID
ORDER BY Date DESC, hedging_fails DESC
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.
