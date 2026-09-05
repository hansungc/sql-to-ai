-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 7  "우리가 업계 평균보다 나은가?" - 서브쿼리
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
-- 예제 1 · [7.1] HAVING의 한계 (오류 예제)
-- ============================================================

-- ▶ 실행해 보세요 — 에러는 안 나지만 결과가 0행입니다.
--   HAVING은 GROUP BY로 묶인 그룹 안에서만 집계하므로, 여기서 AVG(stock_quantity)는
--   '전체 평균'이 아니라 '그 그룹의 평균'(=자기 자신)이 됩니다. 전체 평균과 비교하려면
--   서브쿼리가 필요합니다. 그 방법은 아래 [7.1] 예제들에서 이어집니다.
SELECT product_name, stock_quantity
FROM products
GROUP BY product_name, stock_quantity
HAVING stock_quantity < AVG(stock_quantity);

-- ============================================================
-- 예제 2 · [7.1] 서브쿼리 기본 구조 - 문법 형태
-- ============================================================

-- ▶ 실행해 보세요 — 대괄호는 자리를 표시한 것이라 그대로 실행하면 문법 에러가 납니다
SELECT column_name
FROM table_name
WHERE column_name operator(SELECT column_name FROM table_name);

-- ============================================================
-- 예제 3 · [7.1] WHERE 절 서브쿼리 - 평균과 비교하기
-- ============================================================

SELECT product_name, stock_quantity
FROM products
WHERE stock_quantity < (SELECT AVG(stock_quantity) FROM products);

-- ============================================================
-- 예제 4 · [7.1] 앨범 가격과 평균 비교하기
-- ============================================================

SELECT
  album_name AS `앨범명`,
  price AS `가격`
FROM albums
WHERE price > (SELECT AVG(price) FROM albums)
ORDER BY price DESC
LIMIT 3;

-- ============================================================
-- 예제 5 · [7.1] MAX와 비교하기
-- ============================================================

SELECT
  artist_name AS `아티스트명`,
  debut_date AS `데뷔일`,
  genre AS `장르`
FROM artists
WHERE debut_date = (SELECT MAX(debut_date) FROM artists);

-- ============================================================
-- 예제 6 · [7.1] JOIN으로 특정 그룹의 평균 구하기
-- ============================================================

SELECT
  al.album_name AS `앨범명`,
  al.price AS `가격`,
  ar.genre AS `장르`
FROM albums al
JOIN artists ar ON al.artist_id = ar.artist_id
WHERE al.price > (
  SELECT AVG(al2.price)
  FROM albums al2
  JOIN artists ar2 ON al2.artist_id = ar2.artist_id
  WHERE ar2.genre = 'K-POP'
)
ORDER BY al.price DESC
LIMIT 3;

-- ============================================================
-- 예제 7 · [7.1] 인라인 뷰 - FROM 절 서브쿼리
-- ============================================================

SELECT
  artist_id AS `아티스트 ID`,
  `album_count` AS `앨범 수`
FROM(
  SELECT artist_id, COUNT(*) AS `album_count`
  FROM albums
  GROUP BY artist_id
) AS `album_stats`
WHERE `album_count` >= 2
LIMIT 3;

-- ============================================================
-- 예제 8 · [7.1] 스칼라 서브쿼리 - SELECT 절 서브쿼리
-- ============================================================

SELECT
  album_name AS `앨범명`,
  price AS `가격`,
  (SELECT COUNT(*) FROM albums) AS `전체 앨범 수`,
  (SELECT MAX(price) FROM albums) AS `최고가`
FROM albums
ORDER BY price DESC
LIMIT 3;

-- ============================================================
-- 예제 9 · [7.1] 여러 값 반환 오류 - 서브쿼리가 두 행 이상 반환
-- ============================================================

-- ▶ 실행해 보세요 — 서브쿼리가 두 행 이상을 돌려줘 "Subquery returns more than 1 row" 에러가 납니다
SELECT album_name
FROM albums
WHERE artist_id = (
  SELECT artist_id FROM artists WHERE genre = 'K-POP'
);

-- ============================================================
-- 예제 10 · [7.1] 존재 여부 확인을 LEFT JOIN으로 대체하기
-- ============================================================

SELECT f.fan_id, f.fan_name
FROM fans f
LEFT JOIN orders o ON f.fan_id = o.fan_id
WHERE o.order_id IS NULL;

-- ============================================================
-- 예제 11 · [7.2] IN 연산자 - 여러 값과 비교하기
-- ============================================================

SELECT
  al.album_name AS `앨범명`,
  ar.artist_name AS `아티스트`,
  ar.genre AS `장르`,
  al.release_date AS `발매일`
FROM albums al
JOIN artists ar ON al.artist_id = ar.artist_id
WHERE al.artist_id IN(
  SELECT artist_id
  FROM artists
  WHERE genre = 'K-POP'
)
ORDER BY al.release_date DESC
LIMIT 3;

-- ============================================================
-- 예제 12 · [7.2] NOT IN 연산자 - 제외하기
-- ============================================================

SELECT
  al.album_name AS `앨범명`,
  ar.artist_name AS `아티스트`,
  ar.genre AS `장르`
FROM albums al
JOIN artists ar ON al.artist_id = ar.artist_id
WHERE al.artist_id NOT IN(
  SELECT artist_id FROM artists WHERE genre = 'K-POP'
)
LIMIT 3;

-- ============================================================
-- 예제 13 · [7.2] ALL 연산자 - 모든 값과 비교하기
-- ============================================================

SELECT al.album_name AS `앨범명`, al.price AS `가격`, ar.genre AS `장르`
FROM albums al
JOIN artists ar ON al.artist_id = ar.artist_id
WHERE al.price > ALL(
  SELECT al2.price
  FROM albums al2
  JOIN artists ar2 ON al2.artist_id = ar2.artist_id
  WHERE ar2.genre = 'Ballad'
)
ORDER BY al.price DESC
LIMIT 3;

-- ============================================================
-- 예제 14 · [7.2] NOT EXISTS - 존재하지 않음 확인하기
-- ============================================================

SELECT
  fan_name AS `팬명`,
  email AS `이메일`,
  join_date AS `가입일`
FROM fans f
WHERE NOT EXISTS(
  SELECT 1 FROM orders o WHERE o.fan_id = f.fan_id
)
LIMIT 3;

-- ============================================================
-- 예제 15 · [7.2] 상관 서브쿼리 - 아티스트별 멤버 수
-- ============================================================

SELECT
  ar.artist_name AS `아티스트`,
  ar.debut_date AS `데뷔일`,
  (SELECT COUNT(*)
   FROM members m
   WHERE m.artist_id = ar.artist_id) AS `멤버 수`
FROM artists ar
WHERE ar.artist_type = 'GROUP'
LIMIT 3;

-- ============================================================
-- 예제 16 · [7.3] 업계 평균 기준선 파악하기
-- ============================================================

SELECT
  metric_name AS `지표명`,
  benchmark_value AS `업계 평균`
FROM industry_benchmarks
WHERE category = 'K-POP'
ORDER BY metric_name
LIMIT 3;

-- ============================================================
-- 예제 17 · [7.3] 스칼라 서브쿼리로 기준선과 비교하기
-- ============================================================

SELECT
  a.artist_name AS `아티스트명`,
  ROUND(AVG(c.total_seats), 0) AS `우리 관객 수`,
  CAST((SELECT benchmark_value
  FROM industry_benchmarks
  WHERE metric_name = 'avg_concert_attendance'
    AND category = 'K-POP') AS SIGNED) AS `업계 평균`
FROM artists a
JOIN concerts c ON a.artist_id = c.artist_id
WHERE c.concert_date >= '2026-07-22'
  AND a.genre = 'K-POP'
GROUP BY a.artist_id, a.artist_name
ORDER BY `우리 관객 수` DESC
LIMIT 3;

-- ============================================================
-- 예제 18 · [7.3] HAVING과 서브쿼리 - 기준 이상만 거르기
-- ============================================================

SELECT
  a.artist_name AS `아티스트명`,
  a.genre AS `장르`,
  ROUND(AVG(c.total_seats), 0) AS `평균 관객 수`
FROM artists a
JOIN concerts c ON a.artist_id = c.artist_id
WHERE c.concert_date >= '2026-07-22'
GROUP BY a.artist_id, a.artist_name, a.genre
HAVING AVG(c.total_seats) > (
  SELECT benchmark_value
  FROM industry_benchmarks
  WHERE metric_name = 'avg_concert_attendance'
   AND category = 'K-POP')
ORDER BY `평균 관객 수` DESC;

-- ============================================================
-- 예제 19 · [7.3] IN 서브쿼리 - 2026년 앨범 발매 필터
-- ============================================================

SELECT
  a.artist_name AS `아티스트명`,
  a.genre AS `장르`,
  a.debut_date AS `데뷔일`,
  (SELECT COUNT(*) FROM albums al
   WHERE al.artist_id = a.artist_id
     AND al.release_date >= '2026-01-01') AS `2026 앨범 수`
FROM artists a
WHERE a.artist_id IN(
  SELECT artist_id
  FROM albums
  WHERE release_date >= '2026-01-01'
)
ORDER BY a.debut_date
LIMIT 3;

-- ============================================================
-- 예제 20 · [7.3] EXISTS 조건 여러 개 - 앨범과 콘서트 모두
-- ============================================================

SELECT
  a.artist_name AS `아티스트명`,
  a.genre AS `장르`,
  (SELECT COUNT(*) FROM albums al
   WHERE al.artist_id = a.artist_id
     AND al.release_date >= '2026-07-22') AS `앨범 수`,
  (SELECT COUNT(*) FROM concerts c
   WHERE c.artist_id = a.artist_id
     AND c.concert_date >= '2026-07-22') AS `콘서트 수`
FROM artists a
WHERE EXISTS(
  SELECT 1 FROM albums al
  WHERE al.artist_id = a.artist_id
   AND al.release_date >= '2026-07-22'
)
AND EXISTS(
  SELECT 1 FROM concerts c
  WHERE c.artist_id = a.artist_id
   AND c.concert_date >= '2026-07-22'
)
ORDER BY a.artist_name
LIMIT 3;

-- ============================================================
-- 예제 21 · [7.3] 종합 분석 대시보드 - 상관·스칼라 서브쿼리
-- ============================================================

SELECT
  a.artist_name AS `아티스트명`,
  a.genre AS `장르`,
  (SELECT COUNT(*) FROM albums al
   WHERE al.artist_id = a.artist_id
     AND al.release_date >= '2026-07-22') AS `신규 앨범`,
  (SELECT COUNT(*) FROM concerts c
   WHERE c.artist_id = a.artist_id
     AND c.concert_date >= '2026-07-22') AS `콘서트 수`,
  (SELECT ROUND(AVG(c.total_seats), 0) FROM concerts c
   WHERE c.artist_id = a.artist_id
     AND c.concert_date >= '2026-07-22') AS `평균 관객 수`,
  CAST((SELECT benchmark_value
  FROM industry_benchmarks
  WHERE metric_name = 'avg_concert_attendance'
    AND category = 'K-POP') AS SIGNED) AS `업계 평균`
FROM artists a
WHERE EXISTS(
  SELECT 1 FROM albums al
  WHERE al.artist_id = a.artist_id AND al.release_date >= '2026-07-22'
)
ORDER BY `평균 관객 수` DESC
LIMIT 5;
