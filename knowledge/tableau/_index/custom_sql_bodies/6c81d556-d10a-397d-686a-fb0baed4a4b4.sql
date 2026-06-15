SELECT *
FROM bi_output.bi_output_urban_notifications_daily_panel
where cast(Occurred as date) >= DATEADD(WEEK, -11, CURRENT_DATE)