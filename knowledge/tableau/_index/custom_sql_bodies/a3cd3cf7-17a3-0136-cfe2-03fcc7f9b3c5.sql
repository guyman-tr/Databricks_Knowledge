select  
    pe.ID, 
    pe.InstrumentID,
    pe.Details,
    pe.Occurred, 
    di.Name as EventType
from dealing.bronze_dealinglogs_price_instrumenteventlog pe
join bi_db.bronze_dealinglogs_dictionary_instrumenteventtype di  on pe.EventType=di.ID