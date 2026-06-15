SELECT 
  [BI_DB_ClubLevel_Bronze_UpgradeType].[UpdateDate] AS [UpdateDate],
  [BI_DB_ClubLevel_Bronze_Upgrade].[RealCID] AS [RealCID],
  [BI_DB_ClubLevel_Bronze_Upgrade].[StartOfMonthID] AS [StartOfMonthID],
  [BI_DB_ClubLevel_Bronze_Upgrade].[Manager] AS [Manager],
  [BI_DB_ClubLevel_Bronze_Upgrade].[ManagerID] AS [ManagerID],
  [BI_DB_ClubLevel_Bronze_Upgrade].[UpgradeTypeContacted] AS [UpgradeTypeContacted],
  [BI_DB_ClubLevel_Bronze_Upgrade].[UpgradePointsContacted] AS [UpgradePointsContacted],
  [BI_DB_ClubLevel_Bronze_Upgrade].[UpgradeType] AS UpgradeType,
  [BI_DB_ClubLevel_Bronze_Upgrade].[UpgradePoints] AS [UpgradePoints],
  [BI_DB_ClubLevel_Bronze_Upgrade].[UpdateDate] AS [UpdateDate (BI_DB_ClubLevel_Bronze_Upgrade)],
  [BI_DB_AccountManagers_List].[_row] AS [_row],
  [BI_DB_AccountManagers_List].[_fivetran_deleted] AS [_fivetran_deleted],
  [BI_DB_AccountManagers_List].[first_name] AS [first_name],
  [BI_DB_AccountManagers_List].[last_name] AS [last_name],
  [BI_DB_AccountManagers_List].[position] AS [position],
  [BI_DB_AccountManagers_List].[desk] AS [desk],
  [BI_DB_AccountManagers_List].[manager_id] AS [manager_id],
  [BI_DB_AccountManagers_List].[full_name] AS [full_name],
  [BI_DB_AccountManagers_List].[sales_team_leader] AS [sales_team_leader],
  [BI_DB_AccountManagers_List].[is_active] AS [is_active],
  [BI_DB_AccountManagers_List].[previous_position] AS [previous_position],
  [BI_DB_AccountManagers_List].[previous_position_2] AS [previous_position_2],
  [BI_DB_AccountManagers_List].[_fivetran_synced] AS [_fivetran_synced],
  [BI_DB_AccountManagers_List].[manager_type] AS [manager_type],
  [BI_DB_AccountManagers_List].[office] AS [office],
  [BI_DB_AccountManagers_List].[customers] AS [customers]
FROM [dbo].[BI_DB_ClubLevel_Bronze_UpgradeType] [BI_DB_ClubLevel_Bronze_UpgradeType]
  INNER JOIN [dbo].[BI_DB_ClubLevel_Bronze_Upgrade] [BI_DB_ClubLevel_Bronze_Upgrade] ON ([BI_DB_ClubLevel_Bronze_UpgradeType].[UpgradeType] = [BI_DB_ClubLevel_Bronze_Upgrade].[UpgradeType])
  INNER JOIN [dbo].[BI_DB_AccountManagers_List] [BI_DB_AccountManagers_List] ON ([BI_DB_ClubLevel_Bronze_Upgrade].[ManagerID] = [BI_DB_AccountManagers_List].[manager_id])