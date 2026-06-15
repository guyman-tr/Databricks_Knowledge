SELECT
      epac.CountryID
	  ,epac.Country
	  ,epac.StateProvince
	  ,ISNULL(epac.RegionByIP_ID, 0)StateID
	  ,epac.Crypto
	  ,epac.PaymentAllowed
	 , s.StakingAllowed
	 , c.FromConversionAllowed
	 , c.ToConversionAllowed
  FROM EXW_dbo.EXW_Payment_Allowed_Country epac
  JOIN EXW_dbo.EXW_Staking_Allowed_Country s ON epac.CountryID = s.CountryID AND epac.RegionByIP_ID = s.RegionByIP_ID AND epac.CryptoID = s.CryptoID
  JOIN EXW_dbo.EXW_Conversion_Allowed_Country c ON epac.CountryID = c.CountryID AND epac.RegionByIP_ID = c.RegionByIP_ID AND epac.CryptoID = c.CryptoID