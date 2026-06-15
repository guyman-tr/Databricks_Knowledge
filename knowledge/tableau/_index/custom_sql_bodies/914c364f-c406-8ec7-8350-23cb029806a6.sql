WITH max_date_val AS (
    -- העוגן הוא התאריך המקסימלי בטבלה
    SELECT MAX(date) AS max_date FROM main.etoro_kpi_prep.v_spaceship_mimo
)
SELECT 
    -- FTDs Yesterday (יום אחד אחורה מהמקסימום)
    SUM(CASE WHEN date = DATE_SUB(max_date, 1) AND is_ftd = 1 THEN 1 ELSE 0 END) AS ftds_yesterday,
    
    -- FTDs This Week (מתחיל ביום ראשון שלפני "אתמול")
    SUM(CASE WHEN date >= DATE_TRUNC('week', DATE_ADD(DATE_SUB(max_date, 1), 1)) - INTERVAL 1 DAY 
             AND date < max_date 
             AND is_ftd = 1 THEN 1 ELSE 0 END) AS ftds_this_week,
    
    -- FTDs This Month (מתחיל בתחילת החודש של "אתמול")
    SUM(CASE WHEN date >= DATE_TRUNC('month', DATE_SUB(max_date, 1)) 
             AND date < max_date 
             AND is_ftd = 1 THEN 1 ELSE 0 END) AS ftds_this_month,
    
    -- FTDs This Quarter
    SUM(CASE WHEN date >= DATE_TRUNC('quarter', DATE_SUB(max_date, 1)) 
             AND date < max_date 
             AND is_ftd = 1 THEN 1 ELSE 0 END) AS ftds_this_quarter,
    
    -- FTDs This Year
    SUM(CASE WHEN date >= DATE_TRUNC('year', DATE_SUB(max_date, 1)) 
             AND date < max_date 
             AND is_ftd = 1 THEN 1 ELSE 0 END) AS ftds_this_year

FROM main.etoro_kpi_prep.v_spaceship_mimo, max_date_val
-- סינון ה-WHERE הכללי כדי לשפר ביצועים (לוקחים מתחילת השנה של אתמול)
WHERE date >= DATE_TRUNC('year', DATE_SUB(max_date, 1)) 
AND date < max_date
AND is_internal_transfer = 'false'