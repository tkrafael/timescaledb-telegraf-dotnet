 SELECT time_bucket('00:10:00'::interval, wee."time") AS "time",
    wee.worker,
    sum(wee."count.meter") AS total
   FROM metrics.worker_executions_executions wee
  WHERE ((wee.worker IS NOT NULL) AND (wee.worker <> 'worker_01'::text))
  GROUP BY (time_bucket('00:10:00'::interval, wee."time")), wee.worker
  ORDER BY (time_bucket('00:10:00'::interval, wee."time"));