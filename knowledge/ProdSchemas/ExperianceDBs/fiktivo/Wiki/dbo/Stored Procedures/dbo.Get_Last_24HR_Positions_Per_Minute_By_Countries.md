# dbo.Get_Last_24HR_Positions_Per_Minute_By_Countries

## 1. Overview

Returns a per-minute time series of the average execution interval (in seconds) for a specified action type recorded in `dbo.ExternalLogs` over a configurable look-back window. Optionally filters by a comma-separated list of country IDs resolved from client IP. Zero is returned for minutes with no matching activity, ensuring a continuous time series suitable for monitoring dashboards.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.ExternalLogs |
| Secondary Tables | fiktivo.CountryIP, #DateByMinute / #DateByMinute2 (temp) |
| Operation | SELECT |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

Returns one row per minute in the requested window, ordered most-recent first.

| Column | Type | Description |
|---|---|---|
| Interval | float | Average ExecutionInterval across all matching log entries in the minute; 0 when no entries exist |
| MinutesPerDate | varchar(16) | Minute bucket formatted as `YYYY-MM-DD HH:MM` |

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @NumOfMinutes | IN | int | 1440 | Number of minutes to look back. Maximum 5,256,000 (10 years). |
| @Status | IN | nvarchar(200) | required | ActionString value to filter `ExternalLogs`; identifies the position/action type of interest. |
| @ListOfCountryIDs | IN | varchar(max) | NULL | Optional comma-separated country ID list. When NULL all countries are included. |

## 5. Business Logic

1. Validates `@NumOfMinutes` against the 10-year ceiling; raises error if exceeded.
2. Computes `@MaxDate` (last full minute) and `@MinDate`.
3. **No country filter:** Builds `#DateByMinute` via recursive CTE. Queries `ExternalLogs` filtering on `ActionString = @Status` and timestamp in window, computes `AVG(ExecutionInterval)` per minute. RIGHT JOINs to `#DateByMinute`; `ISNULL(..., 0)` fills missing minutes.
4. **Country filter:** Builds `#DateByMinute2` (separate temp table to avoid collision). Resolves country from `IP` column via BIGINT conversion against `fiktivo.CountryIP` ranges, then applies `CountryID IN (Countries CTE)`. Same aggregation and gap-filling pattern.
5. Country join requires `IP LIKE '%.%'` to skip non-IPv4 addresses.
6. Commented-out code shows that CountryID in the SELECT list was intentionally removed.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| dbo.ExternalLogs | Table | dbo | Source of action log entries with ExecutionInterval and ActionString |
| fiktivo.CountryIP | Table | fiktivo | Maps IP integer ranges to CountryID |
| Ufn_Turn_Var_List_Into_Table_Of_Ints | Function | dbo | Splits comma-separated integer list into a table |
| #DateByMinute / #DateByMinute2 | Temp Tables | tempdb | Minute spine for gap-filling via RIGHT JOIN |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- The IP-to-country join uses a computed integer expression; no index on `CountryIP` can be used for this range lookup without a persisted computed column.
- Two separate temp table names (`#DateByMinute` and `#DateByMinute2`) are used in the two branches because SQL Server would report an error if the same temp table name were created twice in the same batch scope even inside an IF/ELSE.
- For long windows the recursive CTE may be slow; `MAXRECURSION 0` lifts the default 100-iteration limit.

## 8. Usage Examples

```sql
-- Last 24 hours, all countries, for action "OpenPosition"
EXEC dbo.Get_Last_24HR_Positions_Per_Minute_By_Countries
    @NumOfMinutes = 1440,
    @Status = N'OpenPosition',
    @ListOfCountryIDs = NULL;

-- Last 60 minutes, filtered to UK (CountryID=12)
EXEC dbo.Get_Last_24HR_Positions_Per_Minute_By_Countries
    @NumOfMinutes = 60,
    @Status = N'OpenPosition',
    @ListOfCountryIDs = '12';
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| Unknown | Unknown | N/A | Initial creation |

---
*Object: dbo.Get_Last_24HR_Positions_Per_Minute_By_Countries | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.Get_Last_24HR_Positions_Per_Minute_By_Countries.sql*
