select  cast  (date as date) Date,mo_2,exp
 from [ThirdParty_Fivetran].[Fivetran].[reg].[brent_futures_roll]
 where mo_2=0 and cast  (date as date) =   cast(getdate ()+1 as date)