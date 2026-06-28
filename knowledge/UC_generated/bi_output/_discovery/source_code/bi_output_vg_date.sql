-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_date
-- Captured: 2026-06-19T14:30:57Z
-- ==========================================================================

select DateKey AS DateID
      ,FullDate AS Date
			,SSWeekNumberOfYear WeekNumberYear
			,CalendarYearMonth
			,CalendarQuarter
			,CalendarYear
			,CASE WHEN DateKey = MAX(DateKey) over (Partition by CalendarYear,SSWeekNumberOfYear order by DateKey DESC) THEN 1 else 0 END IsLastDayWeek
			,CASE WHEN DateKey = MAX(DateKey) over (Partition by CalendarYear,CalendarQuarter order by DateKey DESC) THEN 1 else 0 END IsLastDayQuarter
			,CASE WHEN DateKey = MAX(DateKey) over (Partition by CalendarYearMonth order by DateKey DESC) THEN 1 else 0 END IsLastDayMonth
			,CASE WHEN DateKey = MAX(DateKey) over (Partition by CalendarYear order by DateKey DESC) THEN 1 else 0 END IsLastDayYear
from main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date
where FullDate < current_date()
