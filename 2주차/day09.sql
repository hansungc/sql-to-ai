-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 9  '차트 순위 변화, 숫자로 잡아내기' - 윈도우 함수
--
-- 이 파일은 교재의 '실습 재료'입니다. 쿼리를 왜 그렇게 쓰는지, 결과를 어떻게 읽고
-- 무엇을 판단하는지는 교재 본문에 있습니다. 예제 제목의 절 번호가 교재의 절 번호와
-- 같으니, 막히는 곳이 있으면 해당 절을 펼쳐 보세요.
--
-- 실행 전제: harmony_db에 harmony_v1.sql(HARMONY 데이터셋) 적재
--
-- 읽는 법
--   -- ======  구분선     이 줄부터 새 예제입니다
--   주석 없는 SQL           그대로 실행하면 됩니다
-- ============================================

-- ============================================================
-- 예제 1 · [9.1] GROUP BY로 플랫폼별 총 재생 수 집계
-- ============================================================

SELECT platform, SUM(play_count) AS `total`
FROM streaming
GROUP BY platform
ORDER BY `total` DESC;

-- ============================================================
-- 예제 2 · [9.1] 윈도우 함수로 플랫폼별 합계 계산
-- ============================================================

SELECT
  stream_date,
  platform,
  play_count,
  SUM(play_count) OVER(PARTITION BY platform) AS `platform_total`
FROM streaming
WHERE stream_date='2026-07-22'
ORDER BY stream_id
LIMIT 5;

-- ============================================================
-- 예제 3 · [9.1] ROW_NUMBER로 고유 번호 매기기
-- ============================================================

SELECT
  t.track_name,
  s.track_id,
  SUM(s.play_count) AS `total_streams`,
  ROW_NUMBER() OVER(ORDER BY SUM(s.play_count) DESC) AS `순위`
FROM streaming s
JOIN tracks t ON s.track_id=t.track_id
WHERE s.stream_date='2026-07-22'
GROUP BY s.track_id, t.track_name
LIMIT 5;

-- ============================================================
-- 예제 4 · [9.1] RANK로 동점자 처리하기
-- ============================================================

SELECT
  track_id,
  SUM(play_count) AS `total_streams`,
  RANK() OVER(ORDER BY SUM(play_count) DESC) AS `순위`
FROM streaming
WHERE stream_date='2026-07-23'
GROUP BY track_id
LIMIT 5;

-- ============================================================
-- 예제 5 · [9.2] LAG로 이전 행 값 가져오기
-- ============================================================

SELECT
  stream_date,
  SUM(play_count) AS `today`,
  LAG(SUM(play_count), 1) OVER(ORDER BY stream_date) AS `yesterday`
FROM streaming
WHERE track_id=93
GROUP BY stream_date
ORDER BY stream_date
LIMIT 4;

-- ============================================================
-- 예제 6 · [9.2] 변화량 계산하기
-- ============================================================

SELECT
  stream_date,
  SUM(play_count) AS `today`,
  LAG(SUM(play_count), 1) OVER(ORDER BY stream_date) AS `yesterday`,
  SUM(play_count)-LAG(SUM(play_count), 1) OVER(ORDER BY stream_date) AS `변화량`
FROM streaming
WHERE track_id=93
GROUP BY stream_date
ORDER BY stream_date
LIMIT 4;

-- ============================================================
-- 예제 7 · [9.2] 플랫폼별 순위 매기기
-- ============================================================

SELECT
  s.platform,
  t.track_name,
  s.track_id,
  SUM(s.play_count) AS `plays`,
  RANK() OVER(PARTITION BY s.platform ORDER BY SUM(s.play_count) DESC) AS `플랫폼 내 순위`
FROM streaming s
JOIN tracks t ON s.track_id=t.track_id
WHERE s.stream_date='2026-07-23'
GROUP BY s.platform, s.track_id, t.track_name
ORDER BY s.platform, `플랫폼 내 순위`
LIMIT 10;

-- ============================================================
-- 예제 8 · [9.2] 트랙별 전일 비교
-- ============================================================

SELECT
  s.stream_date,
  t.track_name,
  s.track_id,
  SUM(s.play_count) AS `today`,
  LAG(SUM(s.play_count), 1) OVER(PARTITION BY s.track_id ORDER BY s.stream_date) AS `yesterday`
FROM streaming s
JOIN tracks t ON s.track_id=t.track_id
WHERE s.track_id IN(93, 1)
  AND s.stream_date BETWEEN '2026-07-22' AND '2026-07-25'
GROUP BY s.stream_date, s.track_id, t.track_name
ORDER BY s.track_id, s.stream_date;

-- ============================================================
-- 예제 9 · [9.2] WINDOW 절로 반복되는 OVER 절 정리
-- ============================================================

SELECT
  stream_date,
  SUM(play_count) AS `today`,
  LAG(SUM(play_count), 1) OVER w AS `yesterday`,
  SUM(play_count)-LAG(SUM(play_count), 1) OVER w AS `변화량`
FROM streaming
WHERE track_id=93
GROUP BY stream_date
WINDOW w AS(ORDER BY stream_date)
ORDER BY stream_date
LIMIT 4;

-- ============================================================
-- 예제 10 · [9.3] 전날 순위 비교하기
-- ============================================================

SELECT
  dc.chart_date,
  t.track_name,
  dc.chart_rank AS `오늘 순위`,
  LAG(dc.chart_rank, 1) OVER(PARTITION BY dc.track_id ORDER BY dc.chart_date) AS `어제 순위`,
  LAG(dc.chart_rank, 1) OVER(PARTITION BY dc.track_id ORDER BY dc.chart_date)-dc.chart_rank AS `순위 변동`
FROM daily_charts dc
JOIN tracks t ON dc.track_id=t.track_id
WHERE dc.track_id=1
ORDER BY dc.chart_date
LIMIT 4;

-- ============================================================
-- 예제 11 · [9.3] 상승 중인 트랙 찾기
-- ============================================================

WITH ranked AS(
   SELECT
     dc.chart_date,
     t.track_name,
     ar.artist_name,
     dc.chart_rank,
     LAG(dc.chart_rank, 1) OVER(PARTITION BY dc.track_id ORDER BY dc.chart_date)
       -dc.chart_rank AS `변동`
   FROM daily_charts dc
   JOIN tracks t ON dc.track_id=t.track_id
   JOIN albums al ON t.album_id=al.album_id
   JOIN artists ar ON al.artist_id=ar.artist_id
)
SELECT chart_date AS `날짜`, track_name AS `트랙명`, artist_name AS `아티스트`, chart_rank AS `순위`, 변동
FROM ranked
WHERE chart_date='2026-07-23'
  AND 변동 > 0
ORDER BY `변동` DESC;

-- ============================================================
-- 예제 12 · [9.3] 2일 연속 상승 트랙 찾기
-- ============================================================

WITH ranked AS(
   SELECT
     dc.chart_date,
     t.track_name,
     ar.artist_name,
     dc.chart_rank,
     LAG(dc.chart_rank, 1) OVER w-dc.chart_rank AS `전일 변동`,
     LAG(dc.chart_rank, 2) OVER w-LAG(dc.chart_rank, 1) OVER w AS `전전일 변동`
   FROM daily_charts dc
   JOIN tracks t ON dc.track_id=t.track_id
   JOIN albums al ON t.album_id=al.album_id
   JOIN artists ar ON al.artist_id=ar.artist_id
   WINDOW w AS(PARTITION BY dc.track_id ORDER BY dc.chart_date)
)
SELECT chart_date AS `날짜`, track_name AS `트랙명`, artist_name AS `아티스트`, chart_rank AS `순위`,
`전일 변동`, `전전일 변동`
FROM ranked
WHERE chart_date='2026-07-23'
  AND `전일 변동` > 0
  AND `전전일 변동` > 0
ORDER BY `전일 변동` DESC;

-- ============================================================
-- 예제 13 · [9.3] 상태 표시 추가 - 상승/하락 자동 분류
-- ============================================================

WITH ranked AS(
  SELECT
    dc.chart_date,
    t.track_name,
    dc.chart_rank,
    LAG(dc.chart_rank, 1) OVER(PARTITION BY dc.track_id ORDER BY dc.chart_date)-dc.chart_rank AS `변동`
  FROM daily_charts dc
  JOIN tracks t ON dc.track_id=t.track_id
)
SELECT
  chart_date AS `날짜`,
  track_name AS `트랙명`,
  chart_rank AS `순위`,
  `변동`,
  CASE
    WHEN `변동` IS NULL THEN '신규'
    WHEN `변동` > 0 THEN '상승'
    WHEN `변동` < 0 THEN '하락'
    ELSE '유지'
  END AS `상태`
FROM ranked
WHERE chart_date='2026-07-22'
ORDER BY chart_rank
LIMIT 7;
