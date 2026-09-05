-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 5  월 100만 스트리밍 아티스트 선별 - HAVING
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
-- ============================================

-- ============================================================
-- 예제 1 · [5.1] WHERE에 집계 함수 사용 (오류 예제)
-- ============================================================

-- ▶ 실행해 보세요 — WHERE에 집계 함수를 써서 "Invalid use of group function" 에러가 납니다. 예제 2의 HAVING과 비교해 보세요
SELECT product_id, SUM(total_amount) AS `total_revenue`
FROM orders
WHERE SUM(total_amount) >=1000000
GROUP BY product_id;

-- ============================================================
-- 예제 2 · [5.1] HAVING 기본 사용법 - 집계 결과로 거르기
-- ============================================================

SELECT
  product_id,
  SUM(total_amount) AS `total_revenue`
FROM orders
GROUP BY product_id
HAVING SUM(total_amount) >=1000000
ORDER BY `total_revenue` DESC
LIMIT 3;

-- ============================================================
-- 예제 3 · [5.1] WHERE와 HAVING 함께 쓰기 - 개별 행 조건과 집계 조건
-- ============================================================

SELECT
  product_id,
  SUM(total_amount) AS `total_revenue`,
  COUNT(*) AS `order_count`
FROM orders
WHERE order_date >='2025-07-01'
  AND order_date <='2025-07-31'
GROUP BY product_id
HAVING SUM(total_amount) >=100000
ORDER BY `total_revenue` DESC
LIMIT 3;

-- ============================================================
-- 예제 4 · [5.1] N회 이상 재생된 트랙
-- ============================================================

SELECT
  track_id,
  COUNT(*) AS `stream_count`
FROM streaming
WHERE stream_date >='2026-07-01'
  AND stream_date <='2026-07-31'
GROUP BY track_id
HAVING COUNT(*) >=10
ORDER BY `stream_count` DESC
LIMIT 3;

-- ============================================================
-- 예제 5 · [5.1] 평균 주문 금액이 높은 고객
-- ============================================================

SELECT
  fan_id,
  COUNT(*) AS `order_count`,
  ROUND(AVG(total_amount), 0) AS `avg_order_value`
FROM orders
WHERE order_date >='2025-07-01'
GROUP BY fan_id
HAVING AVG(total_amount) >=300000
ORDER BY `avg_order_value` DESC
LIMIT 3;

-- ============================================================
-- 예제 6 · [5.1] WHERE와 HAVING 구분하기 - 일반 조건을 HAVING에 (권장하지 않음)
-- ============================================================

SELECT platform, COUNT(*)
FROM streaming
GROUP BY platform
HAVING platform='Melon';

-- ============================================================
-- 예제 7 · [5.1] WHERE와 HAVING 구분하기 - 일반 조건을 WHERE에 (권장)
-- ============================================================

SELECT platform, COUNT(*)
FROM streaming
WHERE platform='Melon'
GROUP BY platform;

-- ============================================================
-- 예제 8 · [5.1] WHERE와 HAVING 함께 쓰기 - 날짜·플랫폼·집계 조건
-- ============================================================

SELECT
  track_id,
  COUNT(*) AS `stream_count`,
  SUM(play_count) AS `total_plays`
FROM streaming
WHERE stream_date >='2026-07-01'
  AND stream_date <='2026-07-31'
  AND platform='Melon'
GROUP BY track_id
HAVING SUM(play_count) >=100
ORDER BY `total_plays` DESC
LIMIT 3;

-- ============================================================
-- 예제 9 · [5.1] HAVING의 기본 문법
-- ============================================================

-- ▶ 실행해 보세요 — 대괄호는 자리를 표시한 것이라 그대로 실행하면 문법 에러가 납니다
SELECT 그룹_칼럼, 집계 함수
FROM 테이블명
WHERE 개별_행_조건               -- 그룹화 전, 개별 행 필터링
GROUP BY 그룹_칼럼              -- 그룹화
HAVING 집계_결과_조건             -- 그룹화 후 집계 결과 필터링
ORDER BY 정렬 기준;             -- 정렬
-- ============================================================
-- 예제 10 · [5.2] HAVING에 여러 조건 연결하기 - AND
-- ============================================================

SELECT
  product_id,
  COUNT(*) AS `order_count`,
  SUM(total_amount) AS `total_revenue`
FROM orders
WHERE order_date >='2025-07-01'
  AND order_date <='2025-07-31'
GROUP BY product_id
HAVING COUNT(*) >=2
  AND SUM(total_amount) >=100000
ORDER BY `total_revenue` DESC
LIMIT 3;

-- ============================================================
-- 예제 11 · [5.2] AND와 OR를 괄호로 묶어 쓰기
-- ============================================================

SELECT
  track_id,
  COUNT(*) AS `stream_count`,
  SUM(play_count) AS `total_plays`,
  ROUND(AVG(play_count), 1) AS `avg_plays`
FROM streaming
WHERE stream_date >='2026-07-01'
  AND stream_date <='2026-07-31'
GROUP BY track_id
HAVING COUNT(*) >=10
  AND(
    SUM(play_count) >=300
    OR AVG(play_count) >=20
  )
ORDER BY `total_plays` DESC;

-- ============================================================
-- 예제 12 · [5.2] CASE WHEN으로 조건부 집계하기 - 플랫폼 비중
-- ============================================================

SELECT
  track_id,
  COUNT(*) AS `total_streams`,
  SUM(CASE WHEN platform='Melon' THEN 1 ELSE 0 END) AS `melon_streams`,
  ROUND(
    SUM(CASE WHEN platform='Melon' THEN 1 ELSE 0 END) * 100.0/COUNT(*)
  , 1) AS `melon_ratio`
FROM streaming
WHERE stream_date >='2026-07-01'
  AND stream_date <='2026-07-31'
GROUP BY track_id
HAVING SUM(CASE WHEN platform='Melon' THEN 1 ELSE 0 END) * 100.0
    /COUNT(*) >=50
ORDER BY `melon_ratio` DESC
LIMIT 3;

-- ============================================================
-- 예제 13 · [5.2] DATE_FORMAT으로 월별 매출 집계하기
-- ============================================================

SELECT
  DATE_FORMAT(order_date, '%Y-%m') AS `order_month`,
  COUNT(*) AS `order_count`,
  SUM(total_amount) AS `monthly_revenue`,
  ROUND(AVG(total_amount), 0) AS `avg_order_value`
FROM orders
WHERE order_date >='2025-01-01'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
HAVING SUM(total_amount) >=1000000
ORDER BY `order_month`;

-- ============================================================
-- 예제 14 · [5.2] 조건부 집계로 국가별 VIP 팬 수 구하기
-- ============================================================

SELECT
  country,
  COUNT(*) AS `total_fans`,
  SUM(CASE
    WHEN membership_level='VIP' THEN 1
    ELSE 0
  END) AS `vip_count`
FROM fans
GROUP BY country
HAVING SUM(CASE
      WHEN membership_level='VIP' THEN 1
      ELSE 0
    END) >=3
ORDER BY `vip_count` DESC;

-- ============================================================
-- 예제 15 · [5.3] 세 가지 조건과 MIN/MAX로 상위 1% 트랙 찾기
-- ============================================================

SELECT
  track_id,
  COUNT(*) AS `stream_count`,
  SUM(play_count) AS `total_plays`,
  ROUND(AVG(play_count), 1) AS `avg_plays`,
  MIN(play_count) AS `min_plays`,
  MAX(play_count) AS `max_plays`
FROM streaming
WHERE stream_date >='2026-07-01'
  AND stream_date <='2026-07-31'
GROUP BY track_id
HAVING COUNT(*) >=5
  AND SUM(play_count) >=100
  AND AVG(play_count) >=15
ORDER BY `total_plays` DESC
LIMIT 3;

-- ============================================================
-- 예제 16 · [5.3] STDDEV로 표준편차 분석하기
-- ============================================================

SELECT
  track_id,
  COUNT(*) AS `stream_count`,
  ROUND(AVG(play_count), 1) AS `avg_plays`,
  ROUND(STDDEV(play_count), 1) AS `stddev_plays`
FROM streaming
WHERE stream_date >='2026-07-01'
  AND stream_date <='2026-07-31'
GROUP BY track_id
HAVING COUNT(*) >=5
  AND SUM(play_count) >=100
  AND AVG(play_count) >=15
ORDER BY `stddev_plays`;

-- ============================================================
-- 예제 17 · [5.3] PERCENTILE_CONT로 중앙값 비교 (PostgreSQL·Oracle·SQL Server)
-- ============================================================

-- ▶ 실행해 보세요 — 다른 DBMS(PostgreSQL·Oracle·SQL Server) 문법이라 MySQL에서는 문법 에러가 납니다
SELECT
  track_id,
  ROUND(AVG(play_count), 1) AS `avg_plays`,
  PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY play_count) AS `median_plays`,
  ROUND(STDDEV(play_count), 1) AS `stddev_plays`
FROM streaming
WHERE stream_date >='2026-07-01'
  AND stream_date <='2026-07-31'
GROUP BY track_id
HAVING COUNT(*) >=5
ORDER BY `stddev_plays`;

-- ============================================================
-- 예제 18 · [5.3] 상위 트랙의 플랫폼별 성과 분석
-- ============================================================

SELECT
  platform,
  COUNT(*) AS `stream_count`,
  SUM(play_count) AS `total_plays`,
  ROUND(AVG(play_count), 1) AS `avg_plays`
FROM streaming
WHERE stream_date >='2026-07-01'
  AND stream_date <='2026-07-31'
  AND track_id IN(93, 22, 95)
GROUP BY platform
HAVING COUNT(*) >=2
ORDER BY `total_plays` DESC;

