with apex_account_mapping AS (
    select COALESCE(e.GCID, g.GCID) as GCID,
       e.AccountNumber as Equity_Acct_ID, 
       g.AccountNumber as Options_Acct_ID,
       cast(e.OpenDDate as date) as Equity_Open_Date,
       cast(g.OpenDDate as date) as Options_Open_Date,
       COALESCE(e.Apex_StateShortName, g.Apex_StateShortName) as Apex_StateShortName
       --CASE WHEN e.AccountNumber IS NOT NULL THEN 'Equity' ELSE 'Options' END as AccountType
    from 
    (
    SELECT  
            ApexID as AccountNumber,
            GCID,
            atm.OpenDDate,
            atm.State as Apex_StateShortName
            --, 'Equity' as AccountType
        FROM main.finance.bronze_usabroker_apex_apexdata ap
        join main.general.bronze_sodreconciliation_apex_ext765_accountmaster atm 
            on atm.AccountNumber=ap.ApexID
        group by ApexID, GCID, atm.OpenDDate, atm.State
    )e    
    full outer join 
        
    (
        SELECT  
            op.OptionsApexID as AccountNumber,
            GCID,
            atm.OpenDDate,
            atm.State as Apex_StateShortName
            --,'Options' as AccountType
        FROM main.general.bronze_usabroker_apex_Options op
        join main.general.bronze_sodreconciliation_apex_ext765_accountmaster atm 
            on atm.AccountNumber=op.OptionsApexID
        group by OptionsApexID, GCID, atm.OpenDDate, atm.State
    )g
    on e.GCID=g.GCID 
)


, pop as (
    SELECT DISTINCT
        dc.GCID, 
        dc.RealCID, 
        Equity_Acct_ID, 
        Options_Acct_ID,
        Equity_Open_Date,
        Options_Open_Date,
        Apex_StateShortName,
        dc.VerificationLevelID AS Current_VerificationLevelID,
        ps.Name                as PlayerStatus
    FROM  apex_account_mapping acm
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
        ON acm.GCID = dc.GCID 
    left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps 
        on dc.PlayerStatusID = ps.PlayerStatusID
)

, pop_firsts as (
    SELECT p.RealCID, cast(fd.registered as date) RegisteredDate, 
    cast(fd.VerificationLevel2Date as date) as VerificationLevel2Date, 
    cast(fd.VerificationLevel3Date as date) as VerificationLevel3Date, 
    cast(fd.FirstDepositDate as date) MSB_FTD_date
    FROM pop p 
    join main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked fd 
        on p.RealCID=fd.cid
)

, etoro_state_regulation as (
    SELECT pop.RealCID, 
        dsap.ShortName      AS eToroFunnel_StateShortName,
        dsap.Name           AS eToroFunnel_State,
        r.Name              as Regulation,
        min(FromDateID)     FromDateID, 
        max(ToDateID)       ToDateID
    FROM pop 
    join main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
        on fsc.RealCID=pop.RealCID 
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r 
            ON r.ID = fsc.RegulationID AND r.ID IN (6,7,8,12) 
    join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_state_and_province dsap 
            on dsap.RegionByIP_ID=fsc.RegionID
    group by pop.RealCID, dsap.ShortName, dsap.Name, r.Name
)

, etoro_state as (
    SELECT 
        RealCID,
        eToroFunnel_StateShortName,
        eToroFunnel_State,
        min(FromDateID)     FromDateID, 
        max(ToDateID)       ToDateID
    FROM etoro_state_regulation
    group by RealCID,
        eToroFunnel_StateShortName,
        eToroFunnel_State
) 

, inc_reg12 as (
    SELECT 
        RealCID
    FROM etoro_state_regulation
    where Regulation='FINRAONLY'
    group by RealCID
) 

, cid_w_multi_states as (
    SELECT RealCID
    FROM etoro_state
    GROUP BY RealCID
    having count(RealCID) >1
)

, cid_state_regulation as (
    SELECT sr.*
    FROM etoro_state_regulation sr 
    join cid_w_multi_states s on s.RealCID=sr.RealCID
    join inc_reg12 ir on ir.RealCID=sr.RealCID
)

SELECT c.RealCID,  
    c.eToroFunnel_State as eToro_State, 
    c.eToroFunnel_StateShortName as eToro_StateShort, 
    c.Regulation, 
    p.Apex_StateShortName as Apex_State,
    c.FromDateID, c.ToDateID, to_date(cast(c.FromDateID as string), 'yyyyMMdd') as FromDate, to_date(cast(c.ToDateID as string), 'yyyyMMdd') as ToDate,
    Equity_Acct_ID, 
        Options_Acct_ID,
        Equity_Open_Date,
        Options_Open_Date,
    pf.RegisteredDate as Reg_Date, 
    pf.VerificationLevel2Date as VL2_Date, 
    pf.VerificationLevel3Date as VL3_Date, 
    p.Current_VerificationLevelID as Current_VL, 
    pf.MSB_FTD_date, --p.CustomerName, 
    p.GCID,
    p.PlayerStatus
FROM cid_state_regulation c
JOIN pop p on c.RealCID=p.RealCID
join pop_firsts pf on c.RealCID=pf.RealCID
--order by RealCID, FromDateID