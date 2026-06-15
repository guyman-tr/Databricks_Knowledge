SELECT fca.RealCID CID,
		         aa.GCID,
				 aa.VerificationLevelID, 
			     cntr.Name,
				 aa.FunnelID, 
				 aa.AffiliateID, 
				 dps.IsBlocked, 
				 dr.Name as Regulation, 
                 a.Name as CompensationCategory,
                 SUM(fca.Amount) as  CompensationAmount,
				 aa.RegisteredReal,
				 aa.FirstDepositDate

            FROM DWH_dbo.Fact_CustomerAction    AS fca
            JOIN DWH_dbo.Dim_Customer           AS aa WITH (NOLOCK)   ON aa.RealCID = fca.RealCID
            JOIN DWH_dbo.Dim_CompensationReason AS a WITH (NOLOCK)    ON a.CompensationReasonID=fca.CompensationReasonID
	        JOIN DWH_dbo.Dim_Country            AS cntr WITH (NOLOCK) ON aa.CountryID = cntr.CountryID
			JOIN DWH_dbo.Dim_PlayerStatus       AS dps WITH (NOLOCK)  ON aa.PlayerStatusID = dps.PlayerStatusID
			JOIN DWH_dbo.Dim_Regulation         AS dr WITH (NOLOCK)   ON aa.RegulationID = dr.ID

            WHERE ActionTypeID = 36
                AND IsValidCustomer = 1
                AND IsDepositor = 1
                AND aa.FunnelID = 113
                AND fca.CompensationReasonID=20
                AND CAST(aa.FirstDepositDate AS DATE) >='2023-01-01'
				AND aa.CountryID IN (217)

				group by

				 fca.RealCID,
		         aa.GCID,
				 aa.VerificationLevelID, 
			     cntr.Name,
				 aa.FunnelID, 
				 aa.AffiliateID, 
				 dps.IsBlocked, 
				 dr.Name, 
                 a.Name,
				 aa.RegisteredReal,
				 aa.FirstDepositDate