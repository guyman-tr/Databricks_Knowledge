-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.vg_dealing_dealingdashboard_cid
-- Captured: 2026-05-19T15:19:50Z
-- ==========================================================================

SELECT Date
	 , HedgeServerID
	 , InstrumentType
	 , InstrumentID
	 , InstrumentDisplayName
	 , InstrumentName
	 , Symbol
	 , SellCurrency
	 , Exchange
	 , Regulation
	 , Country
	 , Region
	 , Mifid
	 , IsCopy
	 , IsCFD
	 , Leverage
	 , sum(NOP						) as NOP
	 , sum(LongOpenPositions		) as LongOpenPositions		
	 , sum(ShortOpenPositions		) as ShortOpenPositions		
	 , sum(UnitsNOP					) as UnitsNOP					
	 , sum(UnitsBuy					) as UnitsBuy					
	 , sum(UnitsSell				) as UnitsSell				
	 , sum(RealizedZero				) as RealizedZero				
	 , sum(ChangeInUnrealizedZero	) as ChangeInUnrealizedZero	
	 , sum(TotalZero				) as TotalZero				
	 , sum(VariableSpread			) as VariableSpread			
	 , sum(OverNightFee				) as OverNightFee				
	 , sum(Dividend					) as Dividend					
	 , sum(OverNightFee_Long		) as OverNightFee_Long		
	 , sum(OverNightFee_Short		) as OverNightFee_Short		
FROM main.dealing.bi_output_dealing_dealingdashboard_cid
GROUP BY 
	Date
	 , HedgeServerID
	 , InstrumentType
	 , InstrumentID
	 , InstrumentDisplayName
	 , InstrumentName
	 , Symbol
	 , SellCurrency
	 , Exchange
	 , Regulation
	 , Country
	 , Region
	 , Mifid
	 , IsCopy
	 , IsCFD
	 , Leverage
