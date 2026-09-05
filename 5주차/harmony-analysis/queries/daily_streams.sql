SELECT s.stream_date, SUM(s.play_count) AS daily_streams
FROM streaming s
JOIN tracks t ON s.track_id = t.track_id
WHERE t.track_name = 'Universe'
  AND s.stream_date >= '2026-07-01'
  AND s.stream_date < '2026-08-01'
GROUP BY s.stream_date
ORDER BY s.stream_date;
