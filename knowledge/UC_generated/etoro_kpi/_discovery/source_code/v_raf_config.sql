-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.v_raf_config
-- Captured: 2026-05-19T15:18:02Z
-- ==========================================================================

SELECT
  --CountryID,
  CountryName,
  --RegulationID,
  DR.Name as RegulationName,
  ReferringCompensationInCents/100 as ReferringCompensationInDollar,
  ReferredCompensationInCents/100 as ReferredCompensationInDollar,
  MaxNumberOfCompensations,
  FraudScore,
  LevelName,
 -- RafModelTypeID,
 -- RafConfigurationID,
  ValidFrom,
  ReferringMinDepositInCents/100 as ReferringMinDepositInDollar,
  ReferredMinDepositInCents/100 as ReferredMinDepositInDollar,
  RafProgramStartDate,
  DaysToWaitFromFTD,
  ReferringMinPositionsAmountInCents/100 as ReferringMinPositionsAmountInDollar,
  ReferredMinPositionsAmountInCents/100 as ReferredMinPositionsAmountInDollar,
  DaysToCheckMinPositionsAmountFromRegistration
FROM main.experience.bronze_rafcompensations_config_viewconfig RC INNER JOIN
main.general.bronze_etoro_dictionary_regulation DR ON RC.RegulationID = DR.ID
