import bulk_fix_deploy_sps as b

samples = [
    "SET V_date = cast(cast(current_timestamp() - INTERVAL 1 DAY  date) as TIMESTAMP)",
    "cast(date_format(x, 'yyyy') int)",
    "cast(x as int) + cast(y bigint)",
    "cast(coalesce(cast(a int), 0) as bigint)",
]
for s in samples:
    print("IN: ", s)
    print("OUT:", b.fix_cast_missing_as(s))
    print()
