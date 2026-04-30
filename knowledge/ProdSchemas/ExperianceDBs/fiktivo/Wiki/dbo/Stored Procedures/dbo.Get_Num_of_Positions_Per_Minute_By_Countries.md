# dbo.Get_Num_of_Positions_Per_Minute_By_Countries

## 1. Overview

Returns a per-minute time series from `dbo.ExternalLogs` for a specified action type, reporting the count of timed-out requests, the count of successful requests, and the average duration of successful requests. A configurable timeout threshold distinguishes timed-out from successful executions. Optionally filters by a comma-separated country ID list resolved from client IP. Zero values are returned for minutes with no activity, enabling continuous charting and alerting on system health.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.ExternalLogs |
| Secondary Tables | fiktivo.CountryIP, #DateByMinute / #DateByMinute2 (temp), #IDs (temp) |
| Operation | SELECT |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

Returns one row per minute in the requested window, ordered most-recent first.

| Column | Type | Description |
|---|---|---|
| MinutesPerDate | varchar(16) | Minute bucket (`YYYY-MM-DD HH:MM`) |
| NumOfTimeOut | int | Count of entries where ExecutionInterval >= @TimeOutLimit |
| NumOfSuccessfull | int | Count of entries where ExecutionInterval < @TimeOutLimit |
| AvgSuccessfulTime | float | Average ExecutionInterval of successful entries; 0 if none |

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @NumOfMinutes | IN | int | 1440 | Look-back window in minutes. Maximum 5,256,000 (10 years). |
| @Status | IN | nvarchar(200) | required | ActionString value to filter `ExternalLogs`. |
| @ListOfCountryIDs | IN | varchar(max) | NULL | Optional comma-separated country ID list. NULL includes all countries. |
| @TimeOutLimit | IN | smallint | 12000 | Threshold in seconds; entries at or above this value are counted as timeouts. |

## 5. Business Logic

1. Validates `@NumOfMinutes` <= 5,256,000; raises error if exceeded.
2. Computes `@MaxDate` and `@MinDate` for the look-back window.
3. **No country filter:** Builds `#DateByMinute` via recursive CTE with `MAXRECURSION 0`. Aggregates `ExternalLogs` per minute using CASE expressions to split counts by timeout threshold; computes `AvgSuccessfulTime` via sum/count to avoid including timeout rows. RIGHT JOINs to `#DateByMinute` with `ISNULL(..., 0)` for zero-activity minutes.
4. **Country filter:** Builds a `#IDs` temp table by dynamically constructing and executing an `INSERT...SELECT UNION SELECT` statement from the parsed `@ListOfCountryIDs` string. Builds `#DateByMinute2`. Joins `ExternalLogs` to `fiktivo.CountryIP` (BIGINT IP conversion) then to `#IDs`. Same aggregation and gap-filling.
5. Dynamic SQL in the country-filter branch: `@ListOfCountryIDs` is transformed from `'1,2,3'` to `INSERT INTO #IDs (ID) SELECT 1 UNION SELECT 2 UNION SELECT 3` and executed via `EXEC()`.
6. `SET ARITHABORT ON` ensures arithmetic exceptions abort the query.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.ExternalLogs | Table | dbo | Source log entries with ActionString, ExecutionInterval, TimeStamp, IP |
| fiktivo.CountryIP | Table | fiktivo | IP range to CountryID mapping |
| #DateByMinute / #DateByMinute2 | Temp Tables | tempdb | Minute spine for gap-filling |
| #IDs | Temp Table | tempdb | Parsed country ID list for filtered branch |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- Dynamic SQL construction of `#IDs` is a simple alternative to a split-function call; it is safe for integer-only inputs but would require validation if the parameter were user-supplied text.
- The IP-to-BIGINT join expression prevents index seek on `CountryIP`; performance degrades proportionally with dataset size.
- `@TimeOutLimit` is declared as `smallint`, which caps its maximum value at 32,767 seconds (~9 hours); callers passing larger values will cause an implicit truncation warning.

## 8. Usage Examples

```sql
-- Last 24 hours, all countries, 3-second timeout threshold
EXEC dbo.Get_Num_of_Positions_Per_Minute_By_Countries
    @NumOfMinutes = 1440,
    @Status = N'ClosePosition',
    @ListOfCountryIDs = NULL,
    @TimeOutLimit = 3;

-- Last 2 hours, UK only (CountryID=12), default timeout
EXEC dbo.Get_Num_of_Positions_Per_Minute_By_Countries
    @NumOfMinutes = 120,
    @Status = N'ClosePosition',
    @ListOfCountryIDs = '12';
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| Unknown | Unknown | N/A | Initial creation |

---
*Object: dbo.Get_Num_of_Positions_Per_Minute_By_Countries | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.Get_Num_of_Positions_Per_Minute_By_Countries.sql*
