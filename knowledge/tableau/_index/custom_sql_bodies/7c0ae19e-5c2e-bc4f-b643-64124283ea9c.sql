SELECT
    Entity_Name,
    Account_Name,
    Asset_Code,
    Asset_Name,

    -- Units
    CAST(
      CASE 
        WHEN API_Amount_Units IS NULL OR lower(trim(API_Amount_Units)) = 'null' OR trim(API_Amount_Units) = '' THEN NULL
        WHEN API_Amount_Units LIKE '(%' 
          THEN concat('-', regexp_replace(API_Amount_Units, '[(),]', ''))   -- (1,793.04) -> -1793.04
        ELSE regexp_replace(API_Amount_Units, ',', '')                      -- 136,184.4688 -> 136184.4688
      END AS DOUBLE
    ) AS API_Amount_Units_num,

    CAST(
      CASE 
        WHEN eToro_Units IS NULL OR lower(trim(eToro_Units)) = 'null' OR trim(eToro_Units) = '' THEN NULL
        WHEN eToro_Units LIKE '(%' 
          THEN concat('-', regexp_replace(eToro_Units, '[(),]', ''))
        ELSE regexp_replace(eToro_Units, ',', '')
      END AS DOUBLE
    ) AS eToro_Units_num,

    CAST(
      CASE 
        WHEN Unit_Difference IS NULL OR lower(trim(Unit_Difference)) = 'null' OR trim(Unit_Difference) = '' THEN NULL
        WHEN Unit_Difference LIKE '(%' 
          THEN concat('-', regexp_replace(Unit_Difference, '[(),]', ''))
        ELSE regexp_replace(Unit_Difference, ',', '')
      END AS DOUBLE
    ) AS Unit_Difference_num,

    -- Dollar amounts
    CAST(
      CASE 
        WHEN API_Dollar_Amount IS NULL OR lower(trim(API_Dollar_Amount)) = 'null' OR trim(API_Dollar_Amount) = '' THEN NULL
        WHEN API_Dollar_Amount LIKE '(%' 
          THEN concat('-', regexp_replace(API_Dollar_Amount, '[(),]', ''))
        ELSE regexp_replace(API_Dollar_Amount, ',', '')
      END AS DOUBLE
    ) AS API_Dollar_Amount_num,

    CAST(
      CASE 
        WHEN eToro_Dollar_Amount IS NULL OR lower(trim(eToro_Dollar_Amount)) = 'null' OR trim(eToro_Dollar_Amount) = '' THEN NULL
        WHEN eToro_Dollar_Amount LIKE '(%' 
          THEN concat('-', regexp_replace(eToro_Dollar_Amount, '[(),]', ''))
        ELSE regexp_replace(eToro_Dollar_Amount, ',', '')
      END AS DOUBLE
    ) AS eToro_Dollar_Amount_num,

    CAST(
      CASE 
        WHEN Dollar_Difference IS NULL OR lower(trim(Dollar_Difference)) = 'null' OR trim(Dollar_Difference) = '' THEN NULL
        WHEN Dollar_Difference LIKE '(%' 
          THEN concat('-', regexp_replace(Dollar_Difference, '[(),]', ''))
        ELSE regexp_replace(Dollar_Difference, ',', '')
      END AS DOUBLE
    ) AS Dollar_Difference_num,

    FileName,
    ReportDateID,
    etr_y,
    etr_ym,
    etr_ymd

FROM main.general.gold_lukka_net_flow_reconciliation
WHERE etr_ymd = <[Parameters].[Parameter 2]>