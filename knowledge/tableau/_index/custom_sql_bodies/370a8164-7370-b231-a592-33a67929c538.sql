SELECT
    Entity_Name,
    Provider_Name,
    Account_Name,
    Sub_Account_Name,
    Trade_Date,
    Order_ID,
    Trade_ID,
    Type,
    Base_Asset_Code,
    Base_Asset_Name,

    CAST(NULLIF(REPLACE(TRIM(Base_Amount), ',', ''), '') AS DECIMAL(38,8))      AS Base_Amount,
    Counter_Asset_Code,
    Counter_Asset_Name,
    CAST(NULLIF(REPLACE(TRIM(Counter_Amount), ',', ''), '') AS DECIMAL(38,8))   AS Counter_Amount,

    Fee_Asset_Code,
    Fee_Asset_Name,
    CAST(NULLIF(REPLACE(TRIM(Fee_Amount), ',', ''), '') AS DECIMAL(38,8))       AS Fee_Amount,

    Rebate_Asset_Code,
    Rebate_Asset_Name,
    CAST(NULLIF(REPLACE(TRIM(Rebate_Asset_Amount), ',', ''), '') AS DECIMAL(38,8)) AS Rebate_Asset_Amount,

    Price,
    Total_Value_FIAT,
    Source,
    Process,
    Counterparty,
    Tags,
    Notes,
    Reference_Currency,
    `Cr/Dr`,
    Account_Number,
    FileName,
    ReportDateID,
    etr_y,
    etr_ym,
    etr_ymd
FROM main.general.gold_lukka_alltrades_month