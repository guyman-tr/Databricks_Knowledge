WITH cost AS (
    SELECT
        Country,
        year,
        month,
        Category,
        SubCategory,
        Type,
        Cost
    FROM main.bi_output_stg.bi_output_operations_bi_cy_cost_budget

    UNION ALL

    SELECT
        Country,
        year,
        month,
        Category,
        SubCategory,
        Type,
        Cost
    FROM main.bi_output_stg.bi_output_operations_telesign_sinch_cost
),

l3_ftd AS (
    SELECT
        m.Country,
        YEAR(m.MonthStart)  AS year,
        MONTH(m.MonthStart) AS month,
        CAST(NULL AS STRING) AS Category,
        CAST(NULL AS STRING) AS SubCategory,
        'Level 3' AS Type,
        COALESCE(l3.l3_cnt, 0) AS Cost
    FROM (
        SELECT DISTINCT
            DATE_TRUNC('month', registered) AS MonthStart,
            Country
        FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
        WHERE YEAR(registered) >= 2025
    ) m
    LEFT JOIN (
        SELECT
            DATE_TRUNC('month', VerificationLevel3Date) AS MonthStart,
            Country,
            COUNT(DISTINCT CID) AS l3_cnt
        FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
        WHERE VerificationLevel3Date IS NOT NULL
        GROUP BY
            DATE_TRUNC('month', VerificationLevel3Date),
            Country
    ) l3
      ON l3.MonthStart = m.MonthStart
     AND l3.Country    = m.Country

    UNION ALL

    SELECT
        m.Country,
        YEAR(m.MonthStart)  AS year,
        MONTH(m.MonthStart) AS month,
        CAST(NULL AS STRING) AS Category,
        CAST(NULL AS STRING) AS SubCategory,
        'FTD' AS Type,
        COALESCE(ftd.ftd_cnt, 0) AS Cost
    FROM (
        SELECT DISTINCT
            DATE_TRUNC('month', registered) AS MonthStart,
            Country
        FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
        WHERE YEAR(registered) >= 2025
    ) m
    LEFT JOIN (
        SELECT
            DATE_TRUNC('month', FirstDepositDate) AS MonthStart,
            Country,
            COUNT(DISTINCT CID) AS ftd_cnt
        FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked
        WHERE FirstDepositDate IS NOT NULL
        GROUP BY
            DATE_TRUNC('month', FirstDepositDate),
            Country
    ) ftd
      ON ftd.MonthStart = m.MonthStart
     AND ftd.Country    = m.Country
)
, cost_per_ftd AS (
    SELECT
        Country,
        year,
        month,
        CAST(NULL AS STRING) AS Category,
        CAST(NULL AS STRING) AS SubCategory,
        'Cost per FTD' AS Type,
        CASE
            WHEN SUM(CASE WHEN Type = 'FTD' THEN Cost END) = 0 THEN 0
            ELSE
                SUM(
                    CASE
                        WHEN Type IN (
                            '1 - Onboarding Vendors',
                            '2 - Onboarding - Outsourcing',
                            '3 - Onboarding - eTorians',
                            '4 - Deposits - Outsourcing - Onboarding',
                            '5 - Deposits - eTorians - Onboarding'
                        )
                        THEN Cost
                    END
                )
                /
                SUM(CASE WHEN Type = 'FTD' THEN Cost END)
        END AS Cost
    FROM (
        SELECT * FROM cost
        UNION ALL
        SELECT * FROM l3_ftd
    ) x
    GROUP BY
        Country,
        year,
        month
)
, cost_per_level_3 AS (
    SELECT
        Country,
        year,
        month,
        CAST(NULL AS STRING) AS Category,
        CAST(NULL AS STRING) AS SubCategory,
        'Cost per Level 3' AS Type,
        CASE
            WHEN SUM(CASE WHEN Type = 'Level 3' THEN Cost END) = 0 THEN 0
            ELSE
                SUM(
                    CASE
                        WHEN Type IN (
                            '1 - Onboarding Vendors',
                            '2 - Onboarding - Outsourcing',
                            '3 - Onboarding - eTorians'
                        )
                        THEN Cost
                    END
                )
                /
                SUM(CASE WHEN Type = 'Level 3' THEN Cost END)
        END AS Cost
    FROM (
        SELECT * FROM cost
        UNION ALL
        SELECT * FROM l3_ftd
    ) x
    GROUP BY
        Country,
        year,
        month
)

SELECT * FROM cost
UNION ALL
SELECT * FROM l3_ftd
UNION ALL
SELECT * FROM cost_per_ftd
UNION ALL
SELECT * FROM cost_per_level_3