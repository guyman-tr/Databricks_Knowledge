# dbo.Get_Last_24HR_Downloads_Per_Minute_By_Countries

## 1. Overview

Returns a per-minute time series of started versus successful executable downloads recorded in `fiktivo.etoro_Download` over a configurable look-back window. Optionally filters the series by a comma-separated list of country IDs, resolving country from client IP via a CIDR range lookup. Zeros are produced for minutes with no activity so the result set always covers every minute in the window, enabling continuous charting.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | fiktivo.etoro_Download |
| Secondary Tables | fiktivo.CountryIP, #DateByMinute (temp) |
| Operation | SELECT |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

Returns one row per minute in the requested window, ordered most-recent first.

| Column | Type | Description |
|---|---|---|
| StartedDownloads | int | Count of all download attempts started in that minute (status != 1) plus successful |
| SuccessfulDownloads | int | Count of downloads that completed successfully (status = 1) |
| MinutesPerDate | varchar(16) | Minute bucket formatted as `YYYY-MM-DD HH:MM` |

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @NumOfMinutes | IN | int | 1440 | Number of minutes to look back from the most recent full minute. Maximum 5,256,000 (10 years). |
| @ListOfCountryIDs | IN | varchar(max) | NULL | Optional comma-separated list of integer country IDs. When NULL all countries are included. |

## 5. Business Logic

1. Validates `@NumOfMinutes` does not exceed 5,256,000; raises error 16/1 if so.
2. Computes `@MaxDate` as the start of the last completed minute (`GETDATE()` minus 30 seconds, truncated to SMALLDATETIME) and `@MinDate` as `@MaxDate` minus the look-back period.
3. Builds a complete minute-sequence temp table `#DateByMinute` using a recursive CTE (`MAXRECURSION 0`) from `@MaxDate` back to `@MinDate`.
4. **No country filter (`@ListOfCountryIDs IS NULL`):** Queries `fiktivo.etoro_Download` directly for the window, re-codes `status`: value 1 becomes "successful" (1), all others become -99 ("started"). Aggregates per minute and RIGHT JOINs to `#DateByMinute` to fill zero-download minutes. No `CountryID` column is surfaced in this branch.
5. **Country filter supplied:** Splits `@ListOfCountryIDs` via `Ufn_Turn_Var_List_Into_Table_Of_Ints` into a CTE `Countries`. Joins `etoro_Download` to `fiktivo.CountryIP` using a computed integer from the dotted IP, then applies the country filter. Same aggregation and RIGHT JOIN pattern as above.
6. `SET ARITHABORT ON` ensures divide-by-zero and overflow conditions abort cleanly.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| fiktivo.etoro_Download | Table | fiktivo | Source download event records with status and IP |
| fiktivo.CountryIP | Table | fiktivo | Maps IP ranges (IPFrom, IPTo integers) to CountryID |
| Ufn_Turn_Var_List_Into_Table_Of_Ints | Function | dbo | Splits a comma-separated list of integers into a table |
| #DateByMinute | Temp Table | tempdb | Holds the complete minute spine for RIGHT JOIN gap-filling |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- The recursive CTE with `MAXRECURSION 0` can be slow for very large look-back windows; for 14,400 minutes (10 days) it generates 14,400 rows.
- The IP-to-country join converts dotted-quad IPs to a BIGINT on every row using `PARSENAME`; this prevents index use on `fiktivo.CountryIP` and can be expensive on large datasets.
- `SET ARITHABORT ON` is set to satisfy query plan stability for grouped aggregates.
- The country-filter branch requires `ip LIKE '%.%'` to exclude non-IPv4 entries before the numeric conversion.

## 8. Usage Examples

```sql
-- Last 24 hours, all countries
EXEC dbo.Get_Last_24HR_Downloads_Per_Minute_By_Countries
    @NumOfMinutes = 1440,
    @ListOfCountryIDs = NULL;

-- Last 10 days, specific countries (Austria=31, Belgium=169, France=63)
EXEC dbo.Get_Last_24HR_Downloads_Per_Minute_By_Countries
    @NumOfMinutes = 14400,
    @ListOfCountryIDs = '169,31,63';
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| 2010-07-26 | Yoni Okun | N/A | Created: get started vs successful downloads per minute |
| 2010-08-01 | Adi | N/A | Removed CountryID from SELECT list; added zero-download rows for specified countries |

---
*Object: dbo.Get_Last_24HR_Downloads_Per_Minute_By_Countries | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.Get_Last_24HR_Downloads_Per_Minute_By_Countries.sql*
