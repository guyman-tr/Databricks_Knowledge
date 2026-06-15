select round(net_perc_gain, 2) as net_perc_gain
from unnest(generate_array(0, 1.01, .05000000)) as net_perc_gain