-- 구독 상태별 팬 수 집계 (이탈 분석 기초)
SELECT status, COUNT(DISTINCT fan_id) AS fan_count
FROM subscription_history
GROUP BY status
ORDER BY fan_count DESC;

-- 이탈 팬 명단 예시
SELECT f.fan_id,
  f.fan_name,
  sh.end_date AS churned_date
FROM fans f
JOIN subscription_history sh
  ON f.fan_id = sh.fan_id
  AND sh.status = 'churned'
ORDER BY sh.end_date
LIMIT 5;
