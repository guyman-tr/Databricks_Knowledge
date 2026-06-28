-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.v_external_france_wealth_contracts_transactions
-- Captured: 2026-06-19T14:33:12Z
-- ==========================================================================

SELECT
  data.cliendId AS ClientId,
  data.contractNo AS contractNo,
  CAST(data.netAmount AS DOUBLE) AS netAmount,
  CAST(data.taxAmount AS DOUBLE) AS taxAmount,
  CAST(data.grossAmount AS DOUBLE) AS grossAmount,
  CAST(data.introducerCommission AS DOUBLE) AS introducerCommission,
  CAST(data.taxAmountExcludingWithholdingTaxes AS DOUBLE) AS taxAmountExcludingWithholdingTaxes,
  TO_DATE(data.creationDate) AS creationDate,
  TO_DATE(data.effectiveDate) AS effectiveDate,
  data.transactionId AS transactionId,
  data.transactionType AS transactionType,
  data.referenceCurrency AS referenceCurrency,
  data.transactionStatus AS transactionStatus
FROM (
  SELECT *
  FROM bi_db.bronze_wealth_france_wealth_france_users_data
  LATERAL VIEW
    EXPLODE(
      FROM_JSON(
        json_text,
        'array<struct<
          cliendId:string,
          contractNo:string,
          netAmount:double,
          taxAmount:double,
          grossAmount:double,
          creationDate:string,
          effectiveDate:string,
          transactionId:string,
          transactionType:string,
          referenceCurrency:string,
          transactionStatus:string,
          introducerCommission:double,
          taxAmountExcludingWithholdingTaxes:double
        >>'
      )
    ) exploded AS data
  WHERE INSTR(file_name, 'contracts_transactions') > 0
) t
