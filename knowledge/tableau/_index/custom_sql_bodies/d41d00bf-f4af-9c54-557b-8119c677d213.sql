SELECT hwi.CryptoID
	  ,hwi.WalletStatus
	  ,hwi.TotalWalletsInInventory
	  ,hwi.TotalAllocated
	  ,hwi.TotalFreeInventory
	  ,hwi.PromotionReadyAvailable
	  ,hwi.PromotionReadyAllocated
	  ,hwi.Created7Days
	  ,hwi.Allocated7Days
	  ,hwi.AllocatedToday
	  ,hwi.TodayAllocationPace
	  ,hwi.YesterdayAllocation
	  ,hwi.SameDayLastWeekAllocation
	  ,hwi.UpdateDate
	  ,hwi.ReportDate
	  ,edct.Name AS CryptoName 
	FROM EXW_dbo.Hourly_WalletInventory hwi
	JOIN EXW_Wallet.CryptoTypes  edct 	ON 		hwi.CryptoID = edct.CryptoID