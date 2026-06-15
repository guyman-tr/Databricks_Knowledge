SELECT
    x.Open_Real_NOP,
    x.Open_Real_Units,
    z.Close_Real_NOP,
    z.Close_Real_Units,
	x.EquityReal_Open,
	z.EquityReal_Close,
    COALESCE(x.CID, z.CID) AS CID,
    CASE
        WHEN x.TanganyStatus_yesterday not in ( 'ConsentCustomer')
        THEN 'New'
        ELSE 'Old'
    END AS CustomerStatus,
    COALESCE(x.InstrumentName, z.InstrumentName) AS InstrumentName
FROM
(
    /* Closing balance (Today) */
    SELECT
        SUM(Real_NOP)   AS Close_Real_NOP,
        SUM(Real_Units) AS Close_Real_Units,
		sum(bdcnc.EquityReal) AS EquityReal_Close,
        bdcnc.CID,
        bdcnc.InstrumentName,
        bdcnc.TanganyStatus AS TanganyStatus_Today
    FROM BI_DB_dbo.BI_DB_Crypto_NOP_CID bdcnc
    WHERE bdcnc.Date = CAST(<[Parameters].[ToDateID (copy)]> AS DATE)
      AND bdcnc.CID IN (
          SELECT DISTINCT bdcbcln.CID
          FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New bdcbcln
          WHERE bdcbcln.DateID IN (
              /* Today */
              YEAR(CAST(<[Parameters].[ToDateID (copy)]> AS DATE)) * 10000
            + MONTH(CAST(<[Parameters].[ToDateID (copy)]> AS DATE)) * 100
            + DAY(CAST(<[Parameters].[ToDateID (copy)]> AS DATE))
          )
          AND bdcbcln.TanganyStatus = 'ConsentCustomer'
      )
    GROUP BY bdcnc.CID, bdcnc.InstrumentName, bdcnc.TanganyStatus
) z

FULL OUTER JOIN
(
    /* Opening balance (Yesterday) */
    SELECT
        SUM(Real_NOP)   AS Open_Real_NOP,
        SUM(Real_Units) AS Open_Real_Units,
        bdcnc.CID,
        bdcnc.InstrumentName,
        bdcnc.TanganyStatus AS TanganyStatus_yesterday,
		sum(bdcnc.EquityReal) AS EquityReal_Open
    FROM BI_DB_dbo.BI_DB_Crypto_NOP_CID bdcnc
    WHERE bdcnc.Date = DATEADD(day, -1, CAST(<[Parameters].[ToDateID (copy)]> AS DATE))
      AND bdcnc.CID IN (
          SELECT DISTINCT bdcbcln.CID
          FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New bdcbcln
          WHERE bdcbcln.DateID IN (
              /* Yesterday */
              YEAR(DATEADD(day, -1, CAST(<[Parameters].[ToDateID (copy)]> AS DATE))) * 10000
            + MONTH(DATEADD(day, -1, CAST(<[Parameters].[ToDateID (copy)]> AS DATE))) * 100
            + DAY(DATEADD(day, -1, CAST(<[Parameters].[ToDateID (copy)]> AS DATE))),
              /* Today */
              YEAR(CAST(<[Parameters].[ToDateID (copy)]> AS DATE)) * 10000
            + MONTH(CAST(<[Parameters].[ToDateID (copy)]> AS DATE)) * 100
            + DAY(CAST(<[Parameters].[ToDateID (copy)]> AS DATE))
          )
          AND bdcbcln.TanganyStatus = 'ConsentCustomer'
      )
    GROUP BY bdcnc.CID, bdcnc.InstrumentName, bdcnc.TanganyStatus
) x
ON x.CID = z.CID
AND x.InstrumentName = z.InstrumentName