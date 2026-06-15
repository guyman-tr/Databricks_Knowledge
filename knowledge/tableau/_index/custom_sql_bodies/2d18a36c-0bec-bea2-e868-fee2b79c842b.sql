SELECT http_requests.vizql_session AS vizql_session,
  MIN(http_requests.created_at) AS session_start_time
FROM public._http_requests http_requests
WHERE vizql_session IS NOT NULL
GROUP BY vizql_session