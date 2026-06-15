select 
		fd.CID,
		dc.Name as Country,
		'Noarmal' as KYC_flow,
		fd.VerificationLevel2Date as V2_date,
		fd.VerificationLevel3Date as V3_date,
		fd.FirstDepositDate as FTD_date,
		fd.FirstPosOpenDate as FTT_date,

		case when fd.VerificationLevel3Date is not null then 1 else 0 end V3,
		case when fd.VerificationLevel3Date between fd.VerificationLevel2Date and DATEADD(DAY, 15, fd.VerificationLevel2Date) and fd.VerificationLevel3Date is not null then 1 else 0 end V3_in_15_days_range_since_V2,
		case when fd.VerificationLevel3Date > DATEADD(DAY, 15, fd.VerificationLevel2Date) and fd.VerificationLevel3Date is not null then 1 else 0 end V3_not_in_15_days_range_since_V2,  

		case when fd.FirstDepositDate is not null then 1 else 0 end FTD,
		case when (((fd.VerificationLevel3Date > DATEADD(DAY, 15, fd.VerificationLevel2Date)) and fd.VerificationLevel3Date is not null and fd.FirstDepositDate < fd.VerificationLevel3Date and fd.FirstDepositDate is not null))
					or (fd.VerificationLevel3Date is null and fd.FirstDepositDate is not null)
			then 1 else 0 
		end no_valid_FTD,
		case when (((fd.VerificationLevel3Date > DATEADD(DAY, 15, fd.VerificationLevel2Date)) and fd.VerificationLevel3Date is not null and fd.FirstDepositDate > fd.VerificationLevel3Date and fd.FirstDepositDate is not null))
					or (fd.VerificationLevel3Date between fd.VerificationLevel2Date and DATEADD(DAY, 15, fd.VerificationLevel2Date) and fd.VerificationLevel3Date is not null and fd.FirstDepositDate is not null)
			then 1 else 0
		end valid_FTD,

		case when fd.FirstPosOpenDate is not null then 1 else 0 end FTT,
		case when (((fd.VerificationLevel3Date > DATEADD(DAY, 15, fd.VerificationLevel2Date)) and fd.VerificationLevel3Date is not null and fd.FirstPosOpenDate < fd.VerificationLevel3Date and fd.FirstPosOpenDate is not null))
					or (fd.VerificationLevel3Date is null and fd.FirstPosOpenDate is not null)
			then 1 else 0 
		end no_valid_FTT,
		case when (((fd.VerificationLevel3Date > DATEADD(DAY, 15, fd.VerificationLevel2Date)) and fd.VerificationLevel3Date is not null and fd.FirstPosOpenDate > fd.VerificationLevel3Date and fd.FirstPosOpenDate is not null))
					or (fd.VerificationLevel3Date between fd.VerificationLevel2Date and DATEADD(DAY, 15, fd.VerificationLevel2Date) and fd.VerificationLevel3Date is not null and fd.FirstPosOpenDate is not null)
			then 1 else 0
		end valid_FTT
	from [dbo].[BI_DB_CIDFirstDates] fd
	join DWH.[dbo].[Dim_Country] dc
	on fd.CountryID = dc.CountryID
	where
		fd.VerificationLevel2Date between '2022-01-01' and '2022-04-26'
	-- Normal flow countries
	AND fd.CountryID IN (1,243,6,7,239,10,11,13,14,203,18,19,21,22,245,25,26,27,32,33,34,37,38,39,42,29,45,46,48,49,56,50,35,52,246,54,55,57,58,59,
						65,66,67,68,69,70,71,72,241,75,77,204,78,80,82,83,85,88,89,212,94,95,98,99,100,228,104,106,108,110,112,113,114,115,116,117,118,119,73,121,
						122,124,125,126,127,128,129,130,131,133,134,135,238,137,138,139,141,142,144,145,146,150,151,152,154,156,157,159,163,164,165,236,168,169,170,247,172,173,248,220,
						177,178,232,182,249,184,185,186,187,175,193,240,195,196,197,198,200,201,205,206,207,208,209,210,211,176,213,215,222,223,224,30,227,229,230,231,41,76,148,235)