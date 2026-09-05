-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 6  '팬 이탈 원인을 데이터로 증명하기' - JOIN
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
-- 예제 1 · [6.1] WHERE에 조건을 넣은 LEFT JOIN 예제
-- ============================================================

SELECT f.fan_name, f.membership_level, o.order_date, o.total_amount
FROM fans f
LEFT JOIN orders o ON f.fan_id=o.fan_id
WHERE f.membership_level='VIP'
  AND o.order_date >= '2026-07-22'
ORDER BY f.fan_id
LIMIT 5;

-- ============================================================
-- 예제 2 · [6.1] ON에 조건을 넣은 LEFT JOIN 예제
-- ============================================================

SELECT f.fan_name, f.membership_level, o.order_date, o.total_amount
FROM fans f
LEFT JOIN orders o ON f.fan_id=o.fan_id
  AND o.order_date >= '2026-07-22'
WHERE f.membership_level='VIP'
ORDER BY f.fan_id
LIMIT 5;

-- ============================================================
-- 예제 3 · [6.2] 3개 테이블 연결: 팬의 구매 상품 조회
-- ============================================================

SELECT
  f.fan_name AS `팬명`,
  o.order_date AS `주문일`,
  p.product_name AS `상품명`,
  o.quantity AS `수량`,
  o.total_amount AS `주문 금액`
FROM fans f
INNER JOIN orders o ON f.fan_id=o.fan_id
INNER JOIN products p ON o.product_id=p.product_id
ORDER BY o.order_id
LIMIT 5;

-- ============================================================
-- 예제 4 · [6.2] 4개 테이블 연결: 아티스트 정보 포함
-- ============================================================

SELECT
  f.fan_name AS `팬명`,
  p.product_name AS `상품명`,
  a.artist_name AS `아티스트`,
  o.total_amount AS `주문 금액`
FROM fans f
INNER JOIN orders o ON f.fan_id=o.fan_id
INNER JOIN products p ON o.product_id=p.product_id
INNER JOIN artists a ON p.artist_id=a.artist_id
ORDER BY o.order_id
LIMIT 5;

-- ============================================================
-- 예제 5 · [6.2] INNER JOIN과 LEFT JOIN 혼합: 7월 판매 현황
-- ============================================================

SELECT
  p.product_name AS `상품명`,
  a.artist_name AS `아티스트명`,
  COUNT(o.order_id) AS `주문 건수`,
  SUM(o.total_amount) AS `총 주문 금액`
FROM products p
INNER JOIN artists a ON p.artist_id=a.artist_id
LEFT JOIN orders o ON p.product_id=o.product_id
  AND o.order_date >= '2026-07-01'
  AND o.order_date < '2026-08-01'
GROUP BY p.product_id, p.product_name, a.artist_name
ORDER BY p.product_id
LIMIT 5;

-- ============================================================
-- 예제 6 · [6.2] 효율적인 JOIN 작성: ON과 WHERE 역할 분리
-- ============================================================

SELECT f.fan_name, f.membership_level, o.total_amount
FROM fans f
INNER JOIN orders o ON f.fan_id=o.fan_id
WHERE f.membership_level IN ('VIP', '프리미엄')
  AND o.total_amount > 50000
ORDER BY o.order_id
LIMIT 5;

-- ============================================================
-- 예제 7 · [6.3] 구독 상태별 팬 수 확인
-- ============================================================

SELECT
  status,
  COUNT(*) AS `fan_count`
FROM subscription_history
GROUP BY status
ORDER BY `fan_count` DESC;

-- ============================================================
-- 예제 8 · [6.3] 이탈 팬의 상세 정보 조회
-- ============================================================

SELECT
  f.fan_id,
  f.fan_name,
  f.membership_level,
  f.country,
  sh.start_date AS `가입일`,
  sh.end_date AS `이탈일`
FROM subscription_history sh
INNER JOIN fans f ON sh.fan_id=f.fan_id
WHERE sh.status='churned'
ORDER BY sh.end_date DESC
LIMIT 5;

-- ============================================================
-- 예제 9 · [6.3] 등급별 이탈자 수 집계
-- ============================================================

SELECT
  f.membership_level,
  COUNT(*) AS `churned_count`
FROM subscription_history sh
INNER JOIN fans f ON sh.fan_id=f.fan_id
WHERE sh.status='churned'
GROUP BY f.membership_level;

-- ============================================================
-- 예제 10 · [6.3] 이탈 팬의 구매 이력 확인
-- ============================================================

SELECT
  f.fan_id,
  f.fan_name,
  f.membership_level,
  COUNT(o.order_id) AS `order_count`,
  COALESCE(SUM(o.total_amount), 0) AS `total_spent`
FROM subscription_history sh
INNER JOIN fans f ON sh.fan_id=f.fan_id
LEFT JOIN orders o ON f.fan_id=o.fan_id
WHERE sh.status='churned'
GROUP BY f.fan_id, f.fan_name, f.membership_level
ORDER BY `total_spent` DESC;

-- ============================================================
-- 예제 11 · [6.3] 활성 팬과 이탈 팬 비교
-- ============================================================

SELECT
  sh.status,
  COUNT(DISTINCT f.fan_id) AS `fan_count`,
  COUNT(DISTINCT o.order_id) AS `total_orders`,
  ROUND(COUNT(DISTINCT o.order_id) * 1.0 / COUNT(DISTINCT f.fan_id), 1) AS `orders_per_fan`,
  COUNT(DISTINCT fa.activity_id) AS `total_activities`,
  ROUND(COUNT(DISTINCT fa.activity_id) * 1.0 / COUNT(DISTINCT f.fan_id), 1) AS `activities_per_fan`
FROM subscription_history sh
INNER JOIN fans f ON sh.fan_id=f.fan_id
LEFT JOIN orders o ON f.fan_id=o.fan_id
LEFT JOIN fan_activities fa ON f.fan_id=fa.fan_id
GROUP BY sh.status
ORDER BY `fan_count` DESC;

-- ============================================================
-- 예제 12 · [6.3] 이탈 위험 팬 조기 발견
-- ============================================================

SELECT
  f.fan_id,
  f.fan_name,
  f.email,
  f.membership_level,
  COUNT(DISTINCT o.order_id) AS `order_count`,
  COUNT(DISTINCT fa.activity_id) AS `activity_count`
FROM subscription_history sh
INNER JOIN fans f ON sh.fan_id=f.fan_id
LEFT JOIN orders o ON f.fan_id=o.fan_id
LEFT JOIN fan_activities fa ON f.fan_id=fa.fan_id
WHERE sh.status='active'
  AND f.membership_level='일반'
GROUP BY f.fan_id, f.fan_name, f.email, f.membership_level
HAVING COUNT(DISTINCT o.order_id) <= 1
  AND COUNT(DISTINCT fa.activity_id) <= 2
ORDER BY `order_count`, `activity_count`;

-- ============================================================
-- 예제 13 · [6.3] 경영진 보고용 요약 데이터
-- ============================================================

SELECT
  sh.status AS `구독 상태`,
  COUNT(DISTINCT f.fan_id) AS `팬 수`,
  COUNT(DISTINCT o.order_id) AS `총 주문 건수`,
  COALESCE(SUM(o.total_amount), 0) AS `총 매출`,
  ROUND(COALESCE(SUM(o.total_amount), 0) * 1.0 / COUNT(DISTINCT f.fan_id)) AS `인당 매출`
FROM subscription_history sh
INNER JOIN fans f ON sh.fan_id=f.fan_id
LEFT JOIN orders o ON f.fan_id=o.fan_id
GROUP BY sh.status
ORDER BY `팬 수` DESC;
