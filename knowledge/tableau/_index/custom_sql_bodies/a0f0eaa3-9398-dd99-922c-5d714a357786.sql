SELECT
    Entity_Name,
    Provider_Name,
    Account_Name,
    Sub_Account_Name,
    Transfer_ID,
    Blockchain_Transaction_ID,
    From_Address,
    To_Address,
    Start_Date,
    Complete_Date,
    Type,
    Base_Asset_Code,
    Base_Asset_Name,

    CAST(NULLIF(REPLACE(TRIM(Base_Amount), ',', ''), '') AS DECIMAL(38, 8))          AS Base_Amount,
    CAST(NULLIF(REPLACE(TRIM(Base_Value_FIAT), ',', ''), '') AS DECIMAL(38, 8))      AS Base_Value_FIAT,

    Fee_Asset_Code,
    Fee_Asset_Name,
    CAST(NULLIF(REPLACE(TRIM(Fee_Amount), ',', ''), '') AS DECIMAL(38, 8))           AS Fee_Amount,
    CAST(NULLIF(REPLACE(TRIM(Fee_Asset_Value_FIAT), ',', ''), '') AS DECIMAL(38, 8)) AS Fee_Asset_Value_FIAT,

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
FROM main.general.gold_lukka_alltransfers_month