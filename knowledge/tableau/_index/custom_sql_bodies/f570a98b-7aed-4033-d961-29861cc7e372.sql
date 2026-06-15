WITH nyse_holidays AS (
    SELECT TO_DATE(date_str) as date 
    FROM VALUES 
        ('2024-01-01'),('2024-01-15'),('2024-02-19'),('2024-03-29'),
        ('2024-05-27'),('2024-06-19'),('2024-07-04'),('2024-09-02'),
        ('2024-11-28'),('2024-12-25'),('2025-01-01'),('2025-01-20'),
        ('2025-02-17'),('2025-04-18'),('2025-05-26'),('2025-06-19'),
        ('2025-07-04'),('2025-09-01'),('2025-11-27'),('2025-12-25'),
        ('2026-01-01'),('2026-01-19'),('2026-02-16'),('2026-04-03'),
        ('2026-05-25'),('2026-06-19'),('2026-07-03'),('2026-09-07'),
        ('2026-11-26'),('2026-12-25') AS holidays(date_str)
),

date_sequence AS (
    SELECT explode(sequence(
        to_date('2024-01-01'), 
        to_date('2026-12-31'), 
        interval 1 day
    )) as date
),

trading_calendar AS (
    SELECT 
        date_seq.date,
        ROW_NUMBER() OVER (
            ORDER BY date_seq.date
        ) as date_id,
        CASE 
            WHEN DAYOFWEEK(date_seq.date) IN (1, 7) THEN 0
            WHEN h.date IS NOT NULL THEN 0
            ELSE 1
        END as is_trading_day
    FROM date_sequence date_seq
    LEFT JOIN nyse_holidays h ON date_seq.date = h.date
),

trading_day_window AS (
    WITH ranked_trading_days AS (
        SELECT 
            t1.date as review_date,
            t2.date as trading_day,
            ROW_NUMBER() OVER (PARTITION BY t1.date ORDER BY t2.date DESC) as rn,
            COUNT(*) OVER (PARTITION BY t1.date) as total_days
        FROM trading_calendar t1
        JOIN trading_calendar t2 
        ON t2.date <= t1.date 
        AND t2.date >= date_sub(t1.date, 10)  -- Look back up to 10 calendar days to ensure we get 5 trading days
        WHERE t1.is_trading_day = 1 
        AND t2.is_trading_day = 1
    )
    SELECT review_date, trading_day
    FROM (
        SELECT 
            review_date,
            trading_day,
            COUNT(*) OVER (PARTITION BY review_date) as day_count
        FROM ranked_trading_days
        WHERE rn <= 5
    ) sub
    WHERE day_count = 5  -- Ensure we have exactly 5 trading days
),

account_mapping AS (
    SELECT  
        ApexID as AccountNumber,
        GCID,
        'Equity' as AccountType
    FROM main.finance.bronze_usabroker_apex_apexdata
    group by ApexID, GCID

    UNION
    
    SELECT  
        op.OptionsApexID as AccountNumber,
        GCID,
        'Options' as AccountType
    FROM main.general.bronze_usabroker_apex_Options op
    join main.general.bronze_sodreconciliation_apex_ext765_accountmaster atm 
        on atm.AccountNumber=op.OptionsApexID
    where atm.Margin='Y'
    group by OptionsApexID, GCID
),

symbols_with_both_bs AS (
    SELECT 
        t.AccountNumber,
        t.TradeDate,
        CASE 
            WHEN CHARINDEX(' ', DisplaySymbol) = 0 THEN DisplaySymbol 
            ELSE LEFT(DisplaySymbol, CHARINDEX(' ', DisplaySymbol) - 1)
        END as SymbolRoot
    FROM main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity t
    WHERE TradeDate > to_date('2025-01-01')
    GROUP BY 
        t.AccountNumber,
        t.TradeDate,
        CASE 
            WHEN CHARINDEX(' ', DisplaySymbol) = 0 THEN DisplaySymbol 
            ELSE LEFT(DisplaySymbol, CHARINDEX(' ', DisplaySymbol) - 1)
        END
    HAVING 
        SUM(CASE WHEN BuySellCode = 'B' THEN 1 ELSE 0 END) > 0
        AND SUM(CASE WHEN BuySellCode = 'S' THEN 1 END) > 0
        AND MIN(CASE WHEN BuySellCode = 'B' THEN ExecutionTime END) <= 
            MAX(CASE WHEN BuySellCode = 'S' THEN ExecutionTime END)
),

first_buys AS (
    SELECT 
        t.AccountNumber,
        t.TradeDate,
        CASE 
            WHEN CHARINDEX(' ', DisplaySymbol) = 0 THEN DisplaySymbol 
            ELSE LEFT(DisplaySymbol, CHARINDEX(' ', DisplaySymbol) - 1)
        END as SymbolRoot,
        MIN(t.ExecutionTime) as first_buy_time
    FROM main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity t
    JOIN symbols_with_both_bs sb 
        ON t.AccountNumber = sb.AccountNumber
        AND t.TradeDate = sb.TradeDate
        AND CASE 
            WHEN CHARINDEX(' ', t.DisplaySymbol) = 0 THEN t.DisplaySymbol 
            ELSE LEFT(t.DisplaySymbol, CHARINDEX(' ', t.DisplaySymbol) - 1)
        END = sb.SymbolRoot
    WHERE t.BuySellCode = 'B'
    GROUP BY 
        t.AccountNumber,
        t.TradeDate,
        CASE 
            WHEN CHARINDEX(' ', DisplaySymbol) = 0 THEN DisplaySymbol 
            ELSE LEFT(DisplaySymbol, CHARINDEX(' ', DisplaySymbol) - 1)
        END
),

valid_trades AS (
    SELECT DISTINCT
        t.AccountNumber,
        am.GCID,
        am.AccountType,
        t.TradeDate,
        t.ExecutionTime,
        t.BuySellCode,
        CASE 
            WHEN CHARINDEX(' ', DisplaySymbol) = 0 THEN DisplaySymbol 
            ELSE LEFT(DisplaySymbol, CHARINDEX(' ', DisplaySymbol) - 1)
        END as SymbolRoot,
        CASE WHEN EXISTS (
            SELECT 1
            FROM main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity t2
            WHERE t2.AccountNumber = t.AccountNumber
            AND t2.TradeDate = t.TradeDate
            AND t2.ExecutionTime = t.ExecutionTime
            AND CASE 
                WHEN CHARINDEX(' ', t2.DisplaySymbol) = 0 THEN t2.DisplaySymbol 
                ELSE LEFT(t2.DisplaySymbol, CHARINDEX(' ', t2.DisplaySymbol) - 1)
            END = CASE 
                WHEN CHARINDEX(' ', t.DisplaySymbol) = 0 THEN t.DisplaySymbol 
                ELSE LEFT(t.DisplaySymbol, CHARINDEX(' ', t.DisplaySymbol) - 1)
            END
            AND t2.BuySellCode <> t.BuySellCode
        ) THEN 1 ELSE 0 END as has_mixed_bs_in_minute,
        SUM(CASE WHEN BuySellCode = 'B' THEN 1 ELSE 0 END) OVER (
            PARTITION BY t.AccountNumber, t.TradeDate, t.ExecutionTime,
                CASE 
                    WHEN CHARINDEX(' ', DisplaySymbol) = 0 THEN DisplaySymbol 
                    ELSE LEFT(DisplaySymbol, CHARINDEX(' ', DisplaySymbol) - 1)
                END
            ORDER BY t.ExecutionTime
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) - 
        MAX(CASE WHEN BuySellCode = 'S' THEN 1 ELSE 0 END) OVER (
            PARTITION BY t.AccountNumber, t.TradeDate, t.ExecutionTime,
                CASE 
                    WHEN CHARINDEX(' ', DisplaySymbol) = 0 THEN DisplaySymbol 
                    ELSE LEFT(DisplaySymbol, CHARINDEX(' ', DisplaySymbol) - 1)
                END
            ORDER BY t.ExecutionTime
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) * 999999 as before_minute_buys_since_last_sell,
        OrderID
    FROM main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity t
    JOIN account_mapping am ON t.AccountNumber = am.AccountNumber
    JOIN symbols_with_both_bs sb 
        ON t.AccountNumber = sb.AccountNumber
        AND t.TradeDate = sb.TradeDate
        AND CASE 
            WHEN CHARINDEX(' ', t.DisplaySymbol) = 0 THEN t.DisplaySymbol 
            ELSE LEFT(t.DisplaySymbol, CHARINDEX(' ', t.DisplaySymbol) - 1)
        END = sb.SymbolRoot
    LEFT JOIN first_buys fb 
        ON t.AccountNumber = fb.AccountNumber
        AND t.TradeDate = fb.TradeDate
        AND CASE 
            WHEN CHARINDEX(' ', t.DisplaySymbol) = 0 THEN t.DisplaySymbol 
            ELSE LEFT(t.DisplaySymbol, CHARINDEX(' ', t.DisplaySymbol) - 1)
        END = fb.SymbolRoot
    WHERE t.ExecutionTime >= fb.first_buy_time
),

sequenced_minute_trade AS (
    SELECT 
        vt.*,
        ROW_NUMBER() OVER (
            PARTITION BY AccountNumber, TradeDate, SymbolRoot, ExecutionTime
            ORDER BY 
                CASE 
                    WHEN has_mixed_bs_in_minute = 1 THEN
                        CASE 
                            WHEN before_minute_buys_since_last_sell > 0 THEN
                                CASE BuySellCode
                                    WHEN 'S' THEN 1
                                    WHEN 'B' THEN 2
                                END
                            WHEN before_minute_buys_since_last_sell <= 0 OR before_minute_buys_since_last_sell IS NULL THEN
                                CASE BuySellCode
                                    WHEN 'B' THEN 1
                                    WHEN 'S' THEN 2
                                END
                        END
                END
        ) as minute_sequence
    FROM valid_trades vt
),

final_sequence AS (
    SELECT 
        smt.*,
        ROW_NUMBER() OVER (
            PARTITION BY AccountNumber, TradeDate, SymbolRoot
            ORDER BY 
                ExecutionTime,
                minute_sequence
        ) as trade_sequence,
        LAG(BuySellCode) OVER (
            PARTITION BY AccountNumber, TradeDate, SymbolRoot
            ORDER BY 
                ExecutionTime,
                minute_sequence
        ) as prev_bs_code,
        CASE 
            WHEN BuySellCode = 'S' AND 
                 LAG(BuySellCode) OVER (
                     PARTITION BY AccountNumber, TradeDate, SymbolRoot
                     ORDER BY 
                         ExecutionTime,
                         minute_sequence
                 ) = 'B'
            THEN 1 
            ELSE 0 
        END as is_round_trip
    FROM sequenced_minute_trade smt
),

daily_round_trips AS (
    SELECT 
        AccountNumber,
        GCID,
        AccountType,
        TradeDate,
        SymbolRoot,
        SUM(is_round_trip) as round_trips,
        ARRAY_JOIN(
            COLLECT_LIST(
                CONCAT(
                    ExecutionTime, 
                    ': ',
                    BuySellCode,
                    ' (', 
                    CASE WHEN is_round_trip = 1 THEN 'RT' ELSE '--' END,
                    ')'
                )
            ),
            ' -> '
        ) as trade_pattern
    FROM final_sequence
    GROUP BY 
        AccountNumber,
        GCID,
        AccountType,
        TradeDate,
        SymbolRoot
),

gcid_daily_totals AS (
    WITH rt_by_acct_type AS (
        SELECT
            GCID,
            TradeDate,
            AccountType,
            -- Sum the round trips for each (GCID, TradeDate, AccountType)
            SUM(round_trips) AS acct_round_trips,
            -- Collect each symbol's detail into one comma-separated string
            ARRAY_JOIN(
                COLLECT_LIST(
                    CONCAT(SymbolRoot, '-', round_trips, ' RT')
                ),
                ', '
            ) AS symbol_details
        FROM daily_round_trips
        GROUP BY
            GCID,
            TradeDate,
            AccountType
    )
    SELECT
        GCID,
        TradeDate,
        -- Total round trips (across all account types) for this GCID/TradeDate
        SUM(acct_round_trips) AS total_round_trips,
        -- Concatenate each account type's symbols in a single cell using ' | '
        ARRAY_JOIN(
            COLLECT_LIST(
                CONCAT(AccountType, ': ', symbol_details)
            ),
            ' | '
        ) AS account_details
    FROM rt_by_acct_type
    GROUP BY
        GCID,
        TradeDate
),

pdt_status AS (
    WITH window_bounds AS (
        SELECT DISTINCT  -- Ensure unique window bounds
            review_date,
            FIRST_VALUE(trading_day) OVER (PARTITION BY review_date ORDER BY trading_day) as first_day,
            FIRST_VALUE(trading_day) OVER (PARTITION BY review_date ORDER BY trading_day DESC) as last_day
        FROM trading_day_window
    ),
    daily_totals_window AS (
        SELECT DISTINCT  -- Deduplicate the daily totals within window
            gdt.GCID,
            tdw.review_date,
            wb.first_day,
            wb.last_day,
            gdt.TradeDate,
            gdt.total_round_trips,
            gdt.account_details,
            gdt2.TradeDate as window_trade_date,
            gdt2.total_round_trips as window_round_trips
        FROM trading_day_window tdw
        JOIN window_bounds wb ON tdw.review_date = wb.review_date
        LEFT JOIN gcid_daily_totals gdt 
            ON CAST(gdt.TradeDate as DATE) = tdw.review_date
        LEFT JOIN gcid_daily_totals gdt2 
            ON gdt2.GCID = gdt.GCID 
            AND CAST(gdt2.TradeDate as DATE) = tdw.trading_day
        WHERE gdt.GCID IS NOT NULL  -- Only include GCIDs that have trades
    )
    SELECT 
        GCID,
        review_date as ReviewDate,
        TradeDate,
        total_round_trips as daily_round_trips,
        account_details,
        SUM(window_round_trips) as rolling_5day_round_trips,
        COUNT(CASE WHEN window_round_trips > 0 THEN 1 END) as days_with_round_trips,
        -- collect all trade dates, format as MMM-dd, then sort, then join
        ARRAY_JOIN(
            SORT_ARRAY(
                COLLECT_LIST(DISTINCT INITCAP(DATE_FORMAT(CAST(window_trade_date AS DATE), 'MMM-dd'))), 
                TRUE
            ),
            '; '
        ) AS dates_included,
        -- Get first and last day of the window using the actual window bounds
        INITCAP(DATE_FORMAT(MIN(first_day), 'MMM-dd')) as window_start_date,
        INITCAP(DATE_FORMAT(MAX(last_day), 'MMM-dd')) as window_end_date
    FROM daily_totals_window
    GROUP BY 
        GCID,
        review_date,
        TradeDate,
        total_round_trips,
        account_details
),

gcid_accounts AS (
    SELECT DISTINCT
        GCID,
        MAX(CASE WHEN AccountType = 'Equity' THEN AccountNumber END) as EquitiesApexID,
        MAX(CASE WHEN AccountType = 'Options' THEN AccountNumber END) as OptionsApexID
    FROM account_mapping
    GROUP BY GCID
)

-- Final output with review date handling
SELECT 
    p.GCID,
    p.ReviewDate,
    p.TradeDate,
    p.window_start_date as `Start Date`,
    p.window_end_date as `End Date`,
    p.daily_round_trips,
    p.account_details,
    p.rolling_5day_round_trips,
    p.days_with_round_trips,
    p.dates_included,
    ga.EquitiesApexID,
    ga.OptionsApexID,
    CASE 
        WHEN rolling_5day_round_trips >= 4 THEN 'PDT Rule Hit'
        WHEN rolling_5day_round_trips >= 3 THEN 'Warning: Close!'
        ELSE 'Within Limits'
    END as pdt_status,
    CASE 
        WHEN rolling_5day_round_trips >= 4 THEN 
            CONCAT(
                CAST(rolling_5day_round_trips as STRING),
                ' Day Trades | ', 
                CAST(days_with_round_trips as STRING),
                ' trading days (',
                dates_included,
                ')'
                )
        ELSE NULL
    END as violation_details,
    -- Add debug columns
    (SELECT COUNT(DISTINCT trading_day) 
     FROM trading_day_window tdw 
     WHERE tdw.review_date = p.ReviewDate) as debug_window_days,
    (SELECT CONCAT_WS(', ', 
            COLLECT_LIST(CAST(trading_day as STRING))
        ) 
     FROM (
         SELECT trading_day
         FROM trading_day_window tdw 
         WHERE tdw.review_date = p.ReviewDate
         ORDER BY trading_day
     ) t
    ) as debug_window_dates
FROM pdt_status p
LEFT JOIN gcid_accounts ga ON p.GCID = ga.GCID
WHERE (daily_round_trips > 0 OR rolling_5day_round_trips >= 3)
    AND p.GCID IN (
        SELECT DISTINCT GCID 
        FROM daily_round_trips 
    )
    AND ReviewDate <= date_sub(CURRENT_DATE(), 1)  -- Can only review up to yesterday due to T+1
ORDER BY p.GCID, ReviewDate