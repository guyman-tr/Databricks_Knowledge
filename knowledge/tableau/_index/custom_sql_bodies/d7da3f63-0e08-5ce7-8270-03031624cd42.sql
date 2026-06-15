WITH pop AS (
  SELECT   
      dc.RegulationID,
      dc.DesignatedRegulationID,
      dc.RealCID,
      dc.GCID,
      CAST(cfd.Registered AS DATE)             AS Reg, 
      CAST(cfd.VerificationLevel1Date AS DATE) AS VerificationLevel1Date, 
      CAST(cfd.VerificationLevel2Date AS DATE) AS VerificationLevel2Date, 
      CAST(cfd.VerificationLevel3Date AS DATE) AS VerificationLevel3Date,
      case 
        when cast(dc.FirstDepositDate AS DATE)='1900-01-01' then null 
            else cast(dc.FirstDepositDate AS DATE) end AS MSB_FTDDate
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
  JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked cfd 
    ON dc.RealCID = cfd.CID 
  where dc.IsValidCustomer=1
    and dc.RegulationID in (6,7,8,12,14)
)

, apex_accounts as (
  SELECT GCID, ApexID
  FROM main.finance.bronze_usabroker_apex_apexdata -- 3e accounts
  union 
  SELECT GCID, OptionsApexID
  FROM  main.general.bronze_usabroker_apex_options -- 4gs accounts: UK & US
)

, apex_accts_map as (
  SELECT aa.GCID, am.AccountNumber, am.OfficeCode, am.RegisteredRepCode, am.OpenDDate
  FROM apex_accounts aa 
  join main.general.bronze_sodreconciliation_apex_ext765_accountmaster am 
    on aa.ApexID=am.AccountNumber
  group by aa.GCID, am.AccountNumber, am.OfficeCode, am.RegisteredRepCode, am.OpenDDate
)
/*
SELECT *
FROM apex_accts_map
WHERE RegisteredRepCode='UK1'
*/
, apex_accts_open as (
  SELECT 
        aam.GCID, --aam.AccountNumber ,aam.OfficeCode,
        aam.RegisteredRepCode, 
         MAX(case when RegisteredRepCode in ('FO1','UK1') then aam.OpenDDate end)  as apex_acct_openDate,
         MAX(case when RegisteredRepCode in ('GAT','NY1') then aam.OpenDDate end)        as options_acct_openDate,
         MAX(case when RegisteredRepCode in ('ETA','NY1') then aam.OpenDDate end)        as equities_acct_openDate
  FROM apex_accts_map aam 
  --where RegisteredRepCode='UK1'
  GROUP BY aam.GCID, aam.RegisteredRepCode 
)

, fo1_uk1_ny1_funded_dates as (
  SELECT 
        aam.GCID, 
        aam.RegisteredRepCode,
        MIN(ca.ProcessDate) AS Apex_FTDDate
  FROM apex_accts_map aam
  join main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ca 
    ON ca.AccountNumber = aam.AccountNumber 
  where ca.PayTypeCode = 'C' 
       AND ca.EnteredBy IN ('ACH','WRD') --OR TerminalID = 'OMJNL')
       and aam.RegisteredRepCode in ('FO1', 'UK1', 'NY1')
  GROUP BY aam.GCID, 
        aam.RegisteredRepCode
)

/*SELECT *
FROM fo1_uk1_funded_dates where RegisteredRepCode='UK1'
*/
, base as (
  SELECT 
    COALESCE(pop.GCID, aao.GCID) AS GCID,
    case when pop.RegulationID = 6 then
          case when pop.DesignatedRegulationID = 7  then dr2.Name--'FinCEN'
               when pop.DesignatedRegulationID = 8  then dr2.Name--'FinCEN+FINRA'
               when pop.DesignatedRegulationID = 12 then dr2.Name--'FINRAONLY'
               when pop.DesignatedRegulationID = 14 then dr2.Name--'NYDFS+FINRA'
              END 
        ELSE 
          case when pop.RegulationID is null then 'FCA'
            else dr.Name
            end
      end  
      as Adj_Regulation,
    pop.Reg, 
    pop.VerificationLevel1Date, 
    pop.VerificationLevel2Date, 
    pop.VerificationLevel3Date, 
    MSB_FTDDate,
    aao.RegisteredRepCode, 
    aao.equities_acct_openDate, 
    aao.options_acct_openDate, 
    aao.apex_acct_openDate,
    fofd.Apex_FTDDate
FROM pop
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr 
    ON pop.RegulationID = dr.ID 
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr2 
    ON pop.DesignatedRegulationID = dr2.ID
full outer join apex_accts_open aao 
  on pop.GCID=aao.GCID
left join fo1_uk1_ny1_funded_dates fofd 
  on aao.GCID=fofd.GCID
--where aao.RegisteredRepCode<>'UK1'
)

-- Now unpivot the 10 date fields using UNION ALL instead of LATERAL VIEW
SELECT
  Adj_Regulation,
  GCID,
  'Reg' AS EventType,
  Reg AS EventDate
FROM base
WHERE Reg IS NOT NULL AND Reg >= '2024-10-01'

UNION ALL

SELECT
  Adj_Regulation,
  GCID,
  'V1' AS EventType,
  VerificationLevel1Date AS EventDate
FROM base
WHERE VerificationLevel1Date IS NOT NULL AND VerificationLevel1Date >= '2024-10-01'

UNION ALL

SELECT
  Adj_Regulation,
  GCID,
  'V2' AS EventType,
  VerificationLevel2Date AS EventDate
FROM base
WHERE VerificationLevel2Date IS NOT NULL AND VerificationLevel2Date >= '2024-10-01'

UNION ALL

SELECT
  Adj_Regulation,
  GCID,
  'V3' AS EventType,
  VerificationLevel3Date AS EventDate
FROM base
WHERE VerificationLevel3Date IS NOT NULL AND VerificationLevel3Date >= '2024-10-01'

UNION ALL

SELECT
  Adj_Regulation,
  GCID,
  'Equity Acct Open' AS EventType,
  equities_acct_openDate AS EventDate
FROM base
WHERE equities_acct_openDate IS NOT NULL AND equities_acct_openDate >= '2024-10-01'

UNION ALL

SELECT
  Adj_Regulation,
  GCID,
  'Options Acct Open' AS EventType,
  options_acct_openDate AS EventDate
FROM base
WHERE options_acct_openDate IS NOT NULL AND options_acct_openDate >= '2024-10-01'

UNION ALL

SELECT
  Adj_Regulation,
  GCID,
  'Apex Acct Open (FO1, UK1)' AS EventType,
  apex_acct_openDate AS EventDate
FROM base
WHERE apex_acct_openDate IS NOT NULL AND apex_acct_openDate >= '2024-10-01'

UNION ALL

SELECT
  Adj_Regulation,
  GCID,
  'MSB FTD' AS EventType,
  MSB_FTDDate AS EventDate
FROM base
WHERE MSB_FTDDate IS NOT NULL AND MSB_FTDDate >= '2024-10-01'

UNION ALL

SELECT
  Adj_Regulation,
  GCID,
  'Apex FTD' AS EventType,
  Apex_FTDDate AS EventDate
FROM base
WHERE Apex_FTDDate IS NOT NULL AND Apex_FTDDate >= '2024-10-01'


UNION ALL

SELECT
  Adj_Regulation,
  GCID,
  'Unified FTD' AS EventType,
  case 
    when Adj_Regulation in ('FINRAONLY','FCA') then Apex_FTDDate 
        else MSB_FTDDate 
    end AS EventDate

FROM base
WHERE (
        case 
            when Adj_Regulation in ('FINRAONLY','FCA') then Apex_FTDDate 
                else MSB_FTDDate 
            end
    ) IS NOT NULL 
    AND (
        case 
        when Adj_Regulation in ('FINRAONLY','FCA') then Apex_FTDDate 
            else MSB_FTDDate 
        end
        ) >= '2024-10-01'