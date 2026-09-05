-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- 부록 I  윈도우 함수 심화 - 누적합, 이동 평균, 백분위
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
-- 예제 1 · [ROWS BETWEEN 기본] 누적합 계산 - ROWS BETWEEN 기본
-- ============================================================

SELECT
   chart_date,
   daily_streams,
   SUM(daily_streams) OVER(
      ORDER BY chart_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
   ) AS `누적합`
FROM daily_charts
WHERE track_id=93
ORDER BY chart_date
LIMIT 5;
-- MySQL 전용(ANSI SQL: FETCH FIRST 5 ROWS ONLY)

-- ============================================================
-- 예제 2 · [최근 3일 평균] 이동 평균 계산하기 - 최근 3일 평균
-- ============================================================

SELECT
  chart_date,
  daily_streams,
  ROUND(AVG(daily_streams) OVER(
     ORDER BY chart_date
     ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ), 0) AS `이동 평균_3일`
FROM daily_charts
WHERE track_id=51
ORDER BY chart_date;

-- ============================================================
-- 예제 3 · [NTILE–균등하게 등급 나누기] 백분위 계산하기 - NTILE으로 균등 등급 나누기
-- ============================================================

SELECT
  track_id,
  daily_streams,
  NTILE(4) OVER(ORDER BY daily_streams DESC, track_id) AS `등급`
FROM daily_charts
WHERE chart_date='2026-07-24'
ORDER BY daily_streams DESC, track_id
LIMIT 5;

-- ============================================================
-- 예제 4 · [PERCENT_RANK–정확한 백분위] 백분위 계산하기 - PERCENT_RANK로 정확한 백분위
-- ============================================================

SELECT
  t.track_name,
  dc.track_id,
  dc.daily_streams,
  ROUND(PERCENT_RANK( ) OVER(ORDER BY dc.daily_streams DESC) * 100, 1) AS `상위_퍼센트`
FROM daily_charts dc
JOIN tracks t ON dc.track_id=t.track_id
WHERE dc.chart_date='2026-07-24'
ORDER BY dc.daily_streams DESC
LIMIT 5;

-- ============================================================
-- 예제 5 · [플랫폼별 합계] 크로스탭으로 보고서 만들기 - 플랫폼별 합계
-- ============================================================

SELECT platform, SUM(play_count) AS `total_plays`
FROM streaming
WHERE stream_date BETWEEN '2026-07-22' AND '2026-07-31'
GROUP BY platform
ORDER BY `total_plays` DESC;

-- ============================================================
-- 예제 6 · [CASE WHEN으로 행을 열로 변환하기] 크로스탭으로 보고서 만들기 - CASE WHEN으로 크로스탭 구성
-- ============================================================

SELECT
  platform,
  SUM(CASE WHEN stream_date='2026-07-22' THEN play_count ELSE 0 END) AS `7월22일`,
  SUM(CASE WHEN stream_date='2026-07-23' THEN play_count ELSE 0 END) AS `7월23일`,
  SUM(CASE WHEN stream_date='2026-07-24' THEN play_count ELSE 0 END) AS `7월24일`
FROM streaming
WHERE stream_date BETWEEN '2026-07-22' AND '2026-07-24'
GROUP BY platform
ORDER BY platform;
