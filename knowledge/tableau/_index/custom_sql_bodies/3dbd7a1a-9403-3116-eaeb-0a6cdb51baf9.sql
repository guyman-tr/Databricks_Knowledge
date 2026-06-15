select CID, SUM(CommissionOnClose) as Revenue
from main.dwh.dim_position
group by CID