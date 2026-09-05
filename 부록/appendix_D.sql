-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- 부록 D  고급 집계 함수 - STDDEV, PERCENTILE, STRING_AGG
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
--   ▶ 실행해 보세요       실행해도 됩니다. 무엇을 보게 될지 같은 줄에 적어 두었습니다
--   ✕ 실행하지 마세요       일부러 주석 처리한 SQL입니다. 사유는 같은 줄에 적어 두었습니다
-- ============================================

-- ============================================================
-- 예제 1 · [D.1] STDDEV 함수로 데이터 분포 측정
-- ============================================================

SELECT
  platform,
  COUNT(*) AS `sessions`,
  ROUND(AVG(play_count), 1) AS `avg_plays`,
  ROUND(STDDEV(play_count), 1) AS `stddev_plays`
FROM streaming
WHERE stream_date='2026-07-22'
GROUP BY platform
ORDER BY `sessions` DESC
LIMIT 3;

-- ============================================================
-- 예제 2 · [D.2] PERCENTILE_CONT 함수로 백분위수 계산
-- ============================================================

-- ▶ 실행해 보세요 — 다른 DBMS(PostgreSQL·Oracle·SQL Server) 문법이라 MySQL에서는 문법 에러가 납니다
SELECT
  product_id,
  COUNT(*) AS `order_count`,
  PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY total_amount) AS `p25`,
  PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY total_amount) AS `median`,
  PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY total_amount) AS `p75`
FROM orders
WHERE order_date>='2025-07-01'
GROUP BY product_id
ORDER BY `order_count` DESC
LIMIT 3;

-- ============================================================
-- 예제 3 · [D.3] GROUP_CONCAT으로 문자열 합치기
-- ============================================================

SELECT
  artist_id,
  COUNT(*) AS `member_count`,
  GROUP_CONCAT(member_name SEPARATOR ', ') AS `members`
FROM members
WHERE artist_id <=3
GROUP BY artist_id
ORDER BY artist_id;

-- ============================================================
-- 예제 4 · [D.4] GROUP_CONCAT으로 정렬 순서 지정
-- ============================================================

SELECT
  artist_id,
  GROUP_CONCAT(album_name ORDER BY release_date SEPARATOR '→') AS `album_timeline`
FROM albums
WHERE artist_id <=3
GROUP BY artist_id;

-- ============================================================
-- 예제 5 · [부록 D] STDDEV 함수 (데이터베이스별)
-- ============================================================

-- ✕ 실행하지 마세요 — 다른 DBMS에서 같은 일을 하는 함수를 비교한 메모입니다. MySQL에서는 실행하지 않습니다
-- -- MySQL: ROUND(STDDEV(play_count), 1)
-- -- PostgreSQL: ROUND(STDDEV(play_count)::numeric, 1) -- numeric 타입으로 캐스팅 필요

-- ============================================================
-- 예제 6 · [부록 D] 백분위수 함수 (데이터베이스별)
-- ============================================================

-- ✕ 실행하지 마세요 — 다른 DBMS에서 같은 일을 하는 함수를 비교한 메모입니다. MySQL에서는 실행하지 않습니다
-- -- PostgreSQL, Oracle: 위 문법 그대로 사용
-- -- MySQL: 직접 지원 안 함(윈도우 함수로 우회 필요)

-- ============================================================
-- 예제 7 · [부록 D] 문자열 합치기 함수 (데이터베이스별)
-- ============================================================

-- ✕ 실행하지 마세요 — 다른 DBMS에서 같은 일을 하는 함수를 비교한 메모입니다. MySQL에서는 실행하지 않습니다
-- -- MySQL: GROUP_CONCAT(칼럼 SEPARATOR '구분자')
-- -- PostgreSQL, BigQuery: STRING_AGG(칼럼, '구분자')
-- -- Snowflake: LISTAGG(칼럼, '구분자')

-- ============================================================
-- 예제 8 · [부록 D] 정렬 순서 지정 (데이터베이스별)
-- ============================================================

-- ✕ 실행하지 마세요 — 다른 DBMS에서 같은 일을 하는 함수를 비교한 메모입니다. MySQL에서는 실행하지 않습니다
-- -- PostgreSQL: STRING_AGG(칼럼, '구분자' ORDER BY 정렬 기준)
-- -- Snowflake: LISTAGG(칼럼, '구분자') WITHIN GROUP(ORDER BY 정렬 기준)
