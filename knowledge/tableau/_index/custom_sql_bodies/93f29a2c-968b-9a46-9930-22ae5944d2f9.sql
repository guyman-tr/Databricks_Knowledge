SELECT	esac.Country
	   ,esac.CountryID
	   ,esac.Club
	   ,esac.PlayerLevelID
	    ,esac.CryptoID
	   ,esac.Crypto
	    ,esac.[Coin Transfer Allowed]
	    ,esac.RegulationID
	   ,esac.Regulation
	   , esac.RegionByIP_ID
	   , esac.StateProvince
	   FROM EXW_dbo.EXW_Coin_Transfer_Allowed_Country  esac