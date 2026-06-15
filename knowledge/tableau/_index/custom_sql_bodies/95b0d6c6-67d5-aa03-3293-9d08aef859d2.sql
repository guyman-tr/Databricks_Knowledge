select distinct CID, Channel, SubChannel, Region, Country, FirstDepositAttempt, FirstDepositDate, Registered, SerialID
from BI_DB_Deposits
where FirstDepositAttempt is not null