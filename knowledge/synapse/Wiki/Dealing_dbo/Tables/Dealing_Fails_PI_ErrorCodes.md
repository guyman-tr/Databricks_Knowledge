# Dealing_Fails_PI_ErrorCodes

## 1. Business Meaning

Static lookup table mapping numeric platform error codes to symbolic constant names. Used by `SP_Fails_PI` as a reference join to enrich `Dealing_Fails_PI.Generic_FailReason` with human-readable error labels.

This table is a dictionary of the eToro trading platform's error code registry — each row defines a numeric code (e.g., `1012`) and its symbolic name (e.g., `INSUFFICIENT_FUNDS_ERROR`). The 234 defined codes cover all known position fail scenarios from the trading engine.

**Scale and activity:** 234 rows. **Static reference data** — no automated ETL SP. Updated manually or via ad-hoc load when the platform introduces new error codes. This table does not grow on a daily basis; it is a definition table, not a fact table.

**Usage pattern:** `SP_Fails_PI` does `LEFT JOIN Dealing_Fails_PI_ErrorCodes ON pf.ErrorCode = ec.ErrorCode`. When `Generic_FailReason IS NULL` on a row in `Dealing_Fails_PI`, it means the platform emitted an error code that was not yet in this lookup — a sign that the lookup needs updating.

## 2. Business Logic

### 2.1 Error Code to Name Mapping

```sql
-- How SP_Fails_PI uses this table
LEFT JOIN Dealing_dbo.Dealing_Fails_PI_ErrorCodes ec
    ON pf.ErrorCode = ec.ErrorCode
-- Result: ec.FailReason → Generic_FailReason in Dealing_Fails_PI
```

### 2.2 Code 0 Special Case

ErrorCode = 0 is defined as `NO_ERROR` but represents a fail event that was recorded without a specific error code (the fail occurred but no code was set by the platform at the time).

### 2.3 Coverage

234 codes defined. Any `ErrorCode` value in `Dealing_Fails_PI` that does not match will yield NULL in `Generic_FailReason`. NULL Generic_FailReason = unknown/new error code not yet in the registry.

## 3. Query Advisory

**Distribution:** ROUND_ROBIN, 234 rows. Full table scans are negligible cost.

**Not date-partitioned:** No `Date` column. Do not attempt time-based filtering.

**Maintenance check — find unmapped error codes:**

```sql
-- Error codes in Dealing_Fails_PI that have no lookup entry
SELECT DISTINCT fp.ErrorCode, COUNT_BIG(*) AS fail_count
FROM Dealing_dbo.Dealing_Fails_PI fp
LEFT JOIN Dealing_dbo.Dealing_Fails_PI_ErrorCodes ec
    ON fp.ErrorCode = ec.ErrorCode
WHERE ec.ErrorCode IS NULL
  AND fp.Date >= DATEADD(DAY, -30, GETDATE())
GROUP BY fp.ErrorCode
ORDER BY fail_count DESC
```

```sql
-- Full lookup: all defined error codes
SELECT ErrorCode, FailReason
FROM Dealing_dbo.Dealing_Fails_PI_ErrorCodes
ORDER BY ErrorCode
```

## 4. Elements

| Column | Type | Description |
|--------|------|-------------|
| ErrorCode | int | Numeric platform error code. Primary key. 0 = NO_ERROR (fail without code). (Tier 2 — platform registry) |
| FailReason | varchar(200) | Symbolic constant name for the error (e.g., `INSUFFICIENT_FUNDS_ERROR`, `WRONG_PARAMS_ERROR`). Snake-case uppercase. (Tier 2 — platform registry) |

## 5. Lineage

| Source | Role |
|--------|------|
| eToro platform error code registry | Static definition of all trading engine error codes |

**ETL:** No automated SP — manually maintained.

**Referenced by:** `Dealing_dbo.SP_Fails_PI` → `Dealing_dbo.Dealing_Fails_PI.Generic_FailReason`

## 6. Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_dbo.Dealing_Fails_PI` | Consumer — joins on ErrorCode to populate Generic_FailReason column |

## 7. Sample Queries

```sql
-- Look up a specific error code
SELECT * FROM Dealing_dbo.Dealing_Fails_PI_ErrorCodes
WHERE ErrorCode = 1012

-- Check for unmapped error codes in recent fails (last 7 days)
SELECT fp.ErrorCode, COUNT_BIG(*) AS occurrences
FROM Dealing_dbo.Dealing_Fails_PI fp
LEFT JOIN Dealing_dbo.Dealing_Fails_PI_ErrorCodes ec ON fp.ErrorCode = ec.ErrorCode
WHERE fp.Date >= DATEADD(DAY, -7, GETDATE())
  AND ec.ErrorCode IS NULL
GROUP BY fp.ErrorCode
ORDER BY occurrences DESC
```

## 8. Atlassian Sources

Phase 10 skipped — Atlassian MCP not available in this environment.
