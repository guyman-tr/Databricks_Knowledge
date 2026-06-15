SELECT
  pvt.CID,
  pvt.GCID,
  (CASE WHEN pvt.[1] IS NOT NULL THEN pvt.[1] ELSE '' END
   + CASE WHEN pvt.[2] IS NOT NULL THEN ', ' + pvt.[2] ELSE '' END
   + CASE WHEN pvt.[3] IS NOT NULL THEN ', ' + pvt.[3] ELSE '' END) AS Stocks
FROM (
  SELECT
      p.CID,
      dc.GCID,
      di.InstrumentDisplayName,
      ROW_NUMBER() OVER (
        PARTITION BY p.CID
        ORDER BY di.InstrumentDisplayName
      ) AS rn
  FROM (
      SELECT DISTINCT dp.CID, dp.InstrumentID
      FROM DWH_dbo.Dim_Position AS dp
      WHERE dp.IsBuy = 0
        AND dp.CloseDateID = 0
        AND dp.MirrorID = 0

        -- ✅ Optional multi-value parameter filter for Tableau:
        -- If InstrumentIDsParam is blank, include all; otherwise filter
        AND (
            <[Parameters].[Parameter 1]> IS NULL
            OR <[Parameters].[Parameter 1]> = ''
            OR dp.InstrumentID IN (
                SELECT TRY_CAST(value AS INT)
                FROM STRING_SPLIT(<[Parameters].[Parameter 1]>, ',')
            )
        )
  ) AS p
  INNER JOIN DWH_dbo.Dim_Customer AS dc WITH (NOLOCK)
    ON dc.RealCID = p.CID
  INNER JOIN DWH_dbo.Dim_Instrument AS di WITH (NOLOCK)
    ON di.InstrumentID = p.InstrumentID
) AS src
PIVOT (
  MAX(InstrumentDisplayName)
  FOR rn IN ([1],[2],[3],[4],[5],[6],[7],[8],[9])
) AS pvt