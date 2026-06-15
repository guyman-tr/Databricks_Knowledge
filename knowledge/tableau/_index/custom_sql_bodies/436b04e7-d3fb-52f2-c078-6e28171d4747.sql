SELECT instrumentId
       ,totalExposureInUSD
       ,exposureTime
       ,etr_ymd
FROM dealing.silver_dealingstreaming_exposures_instrument_exposures
WHERE etr_ymd >= <[Parameters].[Parameter 1]> 
AND etr_ymd <= <[Parameters].[Parameter 1 (copy)_768708188098871296]>
and instrumentId= <[Parameters].[Parameter 2]>