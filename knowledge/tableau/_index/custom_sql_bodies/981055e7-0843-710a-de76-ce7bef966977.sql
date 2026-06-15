SELECT fd.CID
	  ,fd.Club
	  ,fd.Country
	  ,fd.Language
	  ,fd.Region
	  ,fd.PotentialDesk
	  ,fd.Blocked
	  ,fd.registered
	  ,fd.FirstTimeUser
	  ,fd.FirstLoggedIn
	  ,fd.FirstDemoLoggedIn
	  ,fd.FirstDemoPosOpenDate
	  ,fd.FirstDemoMirrorRegistrationDate
	  ,fd.LastDemoMirrorRegistrationDate
	  ,fd.FirstDemoMirrorPosOpenDate
	  ,fd.FirstDepositDate
	  ,fd.FirstDepositAmount
	  ,fd.FirstPosOpenDate
	  ,fd.CertifiedGuru
	  ,fd.Gender
	  ,fd.BirthDate
	  ,fd.CommunicationLanguage
	  ,fd.VerificationLevel1Date
	  ,fd.VerificationLevel2Date
	  ,fd.VerificationLevel3Date
	  ,fd.EmailVerifiedDate
	  ,fd.FirstInstallDate
	  ,fd.EvMatchStatusDate
	  ,fd.NewMarketingRegion
	  ,fd.IsFundedNew
	  ,fd.FirstNewFundedDate
	  ,fd.LastNewFundedDate
,fd.Verified
FROM [BI_DB].[dbo].[BI_DB_CIDFirstDates] fd WITH (NOLOCK)