SELECT 
    REPLACE(Parameter, '_Response', '') AS Parameter,
    SUM(CASE WHEN Response IS NULL OR Response = 'NULL' THEN 1 ELSE 0 END) AS NullCount,
    SUM(CASE WHEN Response IS NOT NULL AND Response <> 'NULL' THEN 1 ELSE 0 END) AS NonNullCount,
    CAST(1.0 * SUM(CASE WHEN Response IS NULL OR Response = 'NULL' THEN 1 ELSE 0 END) / COUNT(*) AS FLOAT) AS NullRatio
FROM (
    SELECT 
        P1_Response, P2_Response, P3_Response, P4_Response, P5_Response, P6_Response, P7_Response, P8_Response,
        P9_Response, P10_Response, P11_Response, P12_Response, P13_Response, P14_Response, P15_Response, P16_Response,
        P17_Response, P18_Response, P19_Response, P20_Response, P21_Response, P22_Response, P23_Response, P24_Response,
        P25_Response, P26_Response, P27_Response, P28_Response, P29_Response, P30_Response, P31_Response, P32_Response
    FROM eMoney_dbo.eMoney_Customer_Risk_Assessment
) src
UNPIVOT (
    Response FOR Parameter IN (
        P1_Response, P2_Response, P3_Response, P4_Response, P5_Response, P6_Response, P7_Response, P8_Response,
        P9_Response, P10_Response, P11_Response, P12_Response, P13_Response, P14_Response, P15_Response, P16_Response,
        P17_Response, P18_Response, P19_Response, P20_Response, P21_Response, P22_Response, P23_Response, P24_Response,
        P25_Response, P26_Response, P27_Response, P28_Response, P29_Response, P30_Response, P31_Response, P32_Response
    )
) AS unpvt
GROUP BY REPLACE(Parameter, '_Response', '')