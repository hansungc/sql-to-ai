-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 18  "이 쿼리, 더 좋게 만들 수 있을까?" - Query Refactoring
--
-- 이 파일은 교재의 '실습 재료'입니다. 쿼리를 왜 그렇게 쓰는지, 결과를 어떻게 읽고
-- 무엇을 판단하는지는 교재 본문에 있습니다. 예제 제목의 절 번호가 교재의 절 번호와
-- 같으니, 막히는 곳이 있으면 해당 절을 펼쳐 보세요.
--
-- 실행 전제: harmony_db에 harmony_v1.sql(HARMONY 데이터셋) 적재
--
-- 읽는 법
--   -- ======  구분선     이 줄부터 새 예제입니다
--   ▼ 프롬프트            /* 와 */ 사이가 AI에 입력할 내용입니다. 그대로 복사해 쓰세요
--   ▼ AI가 만든 SQL       그 프롬프트로 AI가 만들어 준 쿼리입니다
--   주석 없는 SQL           그대로 실행하면 됩니다
--   ▶ 실행해 보세요       실행해도 됩니다. 무엇을 보게 될지 같은 줄에 적어 두었습니다
--   -- ※                   실습 안내 주석입니다. 입력하지도, 실행하지도 않습니다
-- ============================================

-- ============================================================
-- 예제 1 · [18.1 - 스프레드시트에서 가져온 원본] 가독성 개선 전 원본 쿼리
-- ============================================================

SELECT p.product_name, COUNT(*), SUM(o.quantity), SUM(o.total_amount), CASE WHEN SUM(o.total_amount) >=500000 THEN 'HIGH' WHEN SUM(o.total_amount) >=100000 THEN 'MID' ELSE 'LOW' END FROM orders o, products p WHERE o.product_id=p.product_id AND o.order_date >='2026-07-01' AND o.order_date <'2026-08-01' GROUP BY p.product_id, p.product_name ORDER BY 4 DESC;

-- ============================================================
-- 예제 2 · [18.1 - Q7 분석] AI 응답: 가독성 개선된 쿼리
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[현재 쿼리]
SELECT p.product_name, COUNT(*), SUM(o.quantity), SUM(o.total_amount), CASE WHEN SUM(o.total_
amount) >=500000 THEN 'HIGH' WHEN SUM(o.total_amount) >=100000 THEN 'MID' ELSE 'LOW' END FROM orders
o, products p WHERE o.product_id=p.product_id AND o.order_date >='2026-07-01' AND o.order_date
<'2026-08-01' GROUP BY p.product_id, p.product_name ORDER BY 4 DESC;

[개선 요청]
이 쿼리의 가독성을 개선해 줘.
- 별칭: 의미를 알 수 있게
- 구조: 한눈에 파악되게 들여쓰기
- 주석: 조건의 의도 설명
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
-- Q7. 7월 전체 굿즈 매출 분석
-- 매출 등급: 50만 이상(상), 10만 이상(중), 그 외(하)

SELECT
  products.product_name       AS `상품명`,
  COUNT(*)                    AS `주문 건수`,
  SUM(orders.quantity)        AS `판매 수량`,
  SUM(orders.total_amount)    AS `매출액`,
  CASE
    WHEN SUM(orders.total_amount) >=500000 THEN '상'
    WHEN SUM(orders.total_amount) >=100000 THEN '중'
    ELSE '하'
  END                         AS `매출 등급`
FROM orders
INNER JOIN products
    ON orders.product_id=products.product_id
WHERE orders.order_date >='2026-07-01'              -- 7월 시작
    AND orders.order_date <'2026-08-01'             -- 8월 제외
GROUP BY products.product_id, products.product_name
ORDER BY `매출액` DESC;

-- ============================================================
-- 예제 3 · [18.1 - 코딩 컨벤션 적용] 팀 코딩 컨벤션 적용 후 쿼리
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[현재 쿼리]
select
    products.product_name AS `상품명`,
    count(*) AS `주문 건수`,
        sum(orders.quantity) AS `판매 수량`,
    sum(orders.total_amount) AS `매출액`,
    case when sum(orders.total_amount) >=500000 then '상'
         when sum(orders.total_amount) >=100000 then '중'
         else '하' end AS `매출 등급`
from
    orders
join
    products on orders.product_id=products.product_id
where
    orders.order_date >='2026-07-01'
    and orders.order_date <'2026-08-01'
group by
    products.product_id, products.product_name
order by
    매출액 desc;

[요청]
팀 코딩 컨벤션에 맞게 정리해 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
-- Q7. 7월 전체 굿즈 매출 분석
-- 매출 등급: 50만 이상(상), 10만 이상(중), 그 외(하)

SELECT p.product_name           AS `상품명`
  , COUNT(*)                    AS `주문 건수`
  , SUM(o.quantity)             AS `판매 수량`
  , SUM(o.total_amount)         AS `매출액`
  , CASE
      WHEN SUM(o.total_amount) >=500000 THEN '상'
      WHEN SUM(o.total_amount) >=100000 THEN '중'
      ELSE '하'
    END                         AS `매출 등급`
FROM orders o
INNER JOIN products p ON o.product_id=p.product_id
WHERE o.order_date >='2026-07-01'                  -- 7월 시작
  AND o.order_date <'2026-08-01'                    -- 8월 제외
GROUP BY p.product_id, p.product_name
ORDER BY `매출액` DESC;

-- ============================================================
-- 예제 4 · [18.2 - 서브쿼리 버전] 평균 이상 상품 - 서브쿼리 사용
-- ============================================================

-- ※ 지면(393쪽)의 결과 표에는 설명을 위해 '기준_평균 매출' 칼럼(834,714)이 함께 있지만,
--    이 쿼리는 상품명과 매출액 두 칼럼만 조회합니다. 기준 평균을 직접 구하면
--    834714.2857이며, 지면은 소수점을 절사해 인쇄했습니다.

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
위 스키마를 참고해서 SQL을 작성해 줘.:
7월 전체 굿즈 중에서 상품별 평균 매출보다 높은 상품만 보여 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT products.product_name, SUM(orders.total_amount) AS `매출액`
FROM orders
JOIN products ON orders.product_id=products.product_id
WHERE orders.order_date >='2026-07-01'
  AND orders.order_date <'2026-08-01'
GROUP BY products.product_id, products.product_name
HAVING SUM(orders.total_amount) >(
   SELECT AVG(`product_total`) FROM(
      SELECT SUM(o2.total_amount) AS `product_total`
      FROM orders o2
      JOIN products p2 ON o2.product_id=p2.product_id
      WHERE o2.order_date >='2026-07-01'
       AND o2.order_date <'2026-08-01'
      GROUP BY p2.product_id
   ) AS `sub`
);

-- ============================================================
-- 예제 5 · [18.2 - CTE 변환 요청 프롬프트] CTE 변환 요청 프롬프트의 쿼리
-- ============================================================

SELECT products.product_name, SUM(orders.total_amount) AS `매출액`
FROM orders
JOIN products ON orders.product_id=products.product_id
WHERE orders.order_date >='2026-07-01'
 AND orders.order_date <'2026-08-01'
GROUP BY products.product_id, products.product_name
HAVING SUM(orders.total_amount) >(
  SELECT AVG(`product_total`) FROM(
    SELECT SUM(o2.total_amount) AS `product_total`
    FROM orders o2
    JOIN products p2 ON o2.product_id=p2.product_id
    WHERE o2.order_date >='2026-07-01'
     AND o2.order_date <'2026-08-01'
    GROUP BY p2.product_id
  ) AS `sub`
);

-- ============================================================
-- 예제 6 · [18.2] CTE 변환 요청 템플릿
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[현재 쿼리]
(쿼리 붙여 넣기)

[개선 요청]
이 쿼리를 CTE로 변환해 줘.
- 중첩된 서브쿼리를 단계별로 분리
- 반복되는 조건은 한 곳에서만 정의
- 각 CTE에 의미 있는 이름 붙이기

[지침 참조]
지침 파일에 등록된 스키마 정보와 팀 코딩 컨벤션을 적용해 줘.

[추가 요청](필요시)
(교재의 표에서 상황에 맞는 요청 선택)
*/

-- ============================================================
-- 예제 7 · [18.2 - CTE 버전] AI 응답: CTE로 변환된 쿼리
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[현재 쿼리]
SELECT products.product_name, SUM(orders.total_amount) AS `매출액`
FROM orders
JOIN products ON orders.product_id=products.product_id
WHERE orders.order_date >='2026-07-01'
  AND orders.order_date <'2026-08-01'
GROUP BY products.product_id, products.product_name
HAVING SUM(orders.total_amount) >(
   SELECT AVG(`product_total`) FROM(
       SELECT SUM(o2.total_amount) AS `product_total`
       FROM orders o2
       JOIN products p2 ON o2.product_id=p2.product_id
       WHERE o2.order_date >='2026-07-01'
         AND o2.order_date <'2026-08-01'
       GROUP BY p2.product_id
   ) AS `sub`
);

[개선 요청]
이 쿼리를 CTE로 변환해 줘.
- 중첩된 서브쿼리를 단계별로 분리
- 반복되는 조건은 한 곳에서만 정의
- 각 CTE에 의미 있는 이름 붙이기

[지침 참조]
지침 파일에 등록된 스키마 정보와 팀 코딩 컨벤션을 적용해 줘.

[추가 요청]
각 단계마다 주석으로 설명을 달아 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
-- 7월 굿즈: 평균 이상 매출 상품 조회
-- CTE를 사용해 단계별로 분리

-- 1단계: 7월 주문 데이터 추출(조건 1회만 정의)
WITH july_orders AS(
   SELECT p.product_id
     , p.product_name
     , o.total_amount
   FROM orders o
   INNER JOIN products p ON o.product_id=p.product_id
   WHERE o.order_date >='2026-07-01'                 -- 7월 시작
    AND o.order_date <'2026-08-01'                   -- 8월 제외
),

-- 2단계: 상품별 매출 집계
product_sales AS(
   SELECT product_id
     , product_name
     , SUM(total_amount) AS `매출액`
   FROM july_orders
   GROUP BY product_id, product_name
),

-- 3단계: 평균 매출 계산
avg_benchmark AS(
   SELECT AVG(`매출액`) AS `평균 매출`
   FROM product_sales
)

-- 최종: 평균 이상 상품만 출력
SELECT product_name AS `상품명`
   , `매출액`
   , (SELECT `평균 매출` FROM avg_benchmark) AS `기준_평균 매출`
FROM product_sales
WHERE `매출액` >(SELECT `평균 매출` FROM avg_benchmark)
ORDER BY `매출액` DESC;

-- ============================================================
-- 예제 8 · [18.2] VIEW 생성 요청 템플릿
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[현재 쿼리]
(쿼리 붙여 넣기)

[개선 요청]
이 쿼리를 VIEW로 만들어서 재사용할 수 있게 해 줘.

[지침 참조]
지침 파일에 등록된 스키마 정보와 팀 코딩 컨벤션을 적용해 줘.

[추가 요청](필요시)
(교재의 표에서 상황에 맞는 요청 선택)
*/

-- ============================================================
-- 예제 9 · [18.2 - VIEW 생성] Phoenix 일별 매출 VIEW 생성
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[현재 쿼리]
SELECT orders.order_date, products.product_name,
       COUNT(*), SUM(orders.quantity), SUM(orders.total_amount)
FROM orders
JOIN products ON orders.product_id=products.product_id
WHERE products.artist_id=3
GROUP BY orders.order_date, products.product_id, products.product_name;

[개선 요청]
이 쿼리를 VIEW로 만들어서 재사용할 수 있게 해 줘.

[지침 참조]
지침 파일에 등록된 스키마 정보와 팀 코딩 컨벤션을 적용해 줘.

[추가 요청]
날짜 필터는 VIEW 밖에서 적용할 수 있게 해 줘.
칼럼에 한글 별칭을 달아 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
-- Phoenix 일별 매출 VIEW(한 번만 실행)
-- 날짜 필터 없이 전체 기간을 집계해 두고, 조회 시 기간을 지정
-- ※ 아래 DROP은 교재에 없는 줄입니다. 이 파일을 두 번 이상 실행해도
--   'phoenix_daily_sales already exists' 오류가 나지 않도록 넣었습니다.
DROP VIEW IF EXISTS phoenix_daily_sales;
CREATE VIEW phoenix_daily_sales AS
SELECT o.order_date            AS `주문일`
   , p.product_id
   , p.product_name            AS `상품명`
   , COUNT(*)                  AS `주문 건수`
   , SUM(o.quantity)           AS `판매 수량`
   , SUM(o.total_amount)       AS `매출액`
FROM orders o
INNER JOIN products p ON o.product_id=p.product_id
WHERE p.artist_id=3                                  -- Phoenix 고정
GROUP BY o.order_date, p.product_id, p.product_name;

-- ============================================================
-- 예제 10 · [18.2 - VIEW 조회 1] 7월 리포트: VIEW로 간단하게 조회
-- ============================================================

-- 7월 리포트
SELECT `상품명`, SUM(`매출액`) AS `총 매출`
FROM phoenix_daily_sales
WHERE `주문일` >='2026-07-01'
  AND `주문일` <'2026-08-01'
GROUP BY `상품명`
ORDER BY `총 매출` DESC;

-- ============================================================
-- 예제 11 · [18.2 - VIEW 조회 2] 다음 달: 날짜만 바꿔 반복 조회
-- ============================================================

-- 다음 달은 날짜만 바꾸면 됨
SELECT `상품명`, SUM(`매출액`) AS `총 매출`
FROM phoenix_daily_sales
WHERE `주문일` >='2026-08-01'
  AND `주문일` <'2026-09-01'
GROUP BY `상품명`
ORDER BY `총 매출` DESC;

-- ============================================================
-- 예제 12 · [18.2] Phoenix 일별 매출 VIEW 만들기 - 프롬프트의 [현재 쿼리]
-- ============================================================

SELECT orders.order_date, products.product_name,
   COUNT(*), SUM(orders.quantity), SUM(orders.total_amount)
FROM orders
JOIN products ON orders.product_id=products.product_id
WHERE products.artist_id=3
GROUP BY orders.order_date, products.product_id, products.product_name;
-- ============================================================
-- 예제 13 · [18.3 - 쿼리 1] 쿼리 1: Phoenix 7월 총 매출
-- ============================================================

SELECT SUM(o.total_amount) AS `총 매출`
FROM orders o
INNER JOIN products p ON o.product_id=p.product_id
WHERE p.artist_id=3                                -- Phoenix
  AND o.order_date >='2026-07-01'
  AND o.order_date <'2026-08-01';

-- ============================================================
-- 예제 14 · [18.3 - 쿼리 2] 쿼리 2: 팬 등급별 매출
-- ============================================================

SELECT f.membership_level       AS `등급`
   , SUM(o.total_amount)        AS `등급 매출`
FROM orders o
INNER JOIN products p ON o.product_id=p.product_id
INNER JOIN fans f ON o.fan_id=f.fan_id
WHERE p.artist_id=3                                -- Phoenix
  AND o.order_date >='2026-07-01'
  AND o.order_date <'2026-08-01'                   -- 7월
GROUP BY f.membership_level;
-- 결과: 프리미엄 372,000/VIP 348,000

-- ============================================================
-- 예제 15 · [18.3 - 쿼리 3] 쿼리 3: 팬 등급별 인기 상품
-- ============================================================

SELECT f.membership_level       AS `등급`
  , p.product_name              AS `상품명`
  , COUNT(*)                    AS `주문 건수`
FROM orders o
INNER JOIN products p ON o.product_id=p.product_id
INNER JOIN fans f ON o.fan_id=f.fan_id
WHERE p.artist_id=3                                -- Phoenix
  AND o.order_date >='2026-07-01'
  AND o.order_date <'2026-07-31'                   -- 실수!
GROUP BY f.membership_level, p.product_name;

-- ============================================================
-- 예제 16 · [18.3] 쿼리 통합 요청 템플릿
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[현재 상황]
여러 쿼리를 따로 실행하고 엑셀에서 결과를 조합하고 있어요.
- 쿼리 1: (첫 번째 분석 설명)
- 쿼리 2: (두 번째 분석 설명)
- 쿼리 3: (세 번째 분석 설명)

[개선 요청]
이 분석들을 하나의 쿼리로 합쳐 줘.
- 날짜 조건은 한 곳에서만 정의
- 모든 계산을 SQL에서 완료

[지침 참조]
지침 파일에 등록된 스키마 정보와 팀 코딩 컨벤션을 적용해 줘.

[추가 요청](필요시)
(교재의 표에서 상황에 맞는 요청 선택)
*/

-- ============================================================
-- 예제 17 · [18.3 - 통합 쿼리] AI 응답: 3개 분석을 하나의 쿼리로 통합
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[현재 상황]
여러 쿼리를 따로 실행하고 엑셀에서 결과를 조합하고 있어요.
- 쿼리 1: Phoenix 7월 총 매출(위 [18.3 - 쿼리 1] 쿼리 추가)
- 쿼리 2: 팬 등급별 매출(위 [18.3 - 쿼리 2] 쿼리 추가)
- 쿼리 3: 팬 등급별 인기 상품(위 [18.3 - 쿼리 3] 쿼리 추가)

[개선 요청]
이 분석들을 하나의 쿼리로 합쳐 줘.
- 날짜 조건은 한 곳에서만 정의
- 모든 계산을 SQL에서 완료

[지침 참조]
지침 파일에 등록된 스키마 정보와 팀 코딩 컨벤션을 적용해 줘.

[추가 요청]
전체 대비 비중(%)까지 한 번에 계산해 줘.
각 등급에서 가장 많이 팔린 상품 1개씩만 보여 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
-- Phoenix 팬 등급별 구매 패턴 통합 분석
-- 총 매출+등급별 매출·비중+인기 상품을 한 번에 조회

-- 1단계: 기초 데이터(3개 테이블 JOIN, 날짜 조건은 여기서 1번만)
WITH phoenix_july_orders AS(
   SELECT o.order_id
     , o.fan_id
     , o.total_amount
     , p.product_name
     , f.membership_level
   FROM orders o
   INNER JOIN products p ON o.product_id=p.product_id
   INNER JOIN fans f ON o.fan_id=f.fan_id
   WHERE p.artist_id=3                               -- Phoenix
    AND o.order_date >='2026-07-01'                  -- 7월 시작
    AND o.order_date <'2026-08-01'                   -- 8월 제외
),

-- 2단계: 전체 매출(결과: 1행)
total_sales AS(
   SELECT SUM(total_amount) AS `전체 매출`
   FROM phoenix_july_orders
),

-- 3단계: 등급별 집계
grade_sales AS(
   SELECT membership_level
     , COUNT(DISTINCT fan_id)   AS `구매자 수`
     , SUM(total_amount)        AS `등급 매출`
   FROM phoenix_july_orders
   GROUP BY membership_level
),

-- 4단계: 등급별 1위 상품(ROW_NUMBER로 순위)
grade_top_product AS(
   SELECT membership_level
     , product_name
     , ROW_NUMBER() OVER(
          PARTITION BY membership_level
          ORDER BY COUNT(*) DESC
       ) AS `ranking`
   FROM phoenix_july_orders
   GROUP BY membership_level, product_name
)

-- 최종: CROSS JOIN으로 전체 매출 붙이고, LEFT JOIN으로 1위 상품 연결
SELECT grade_sales.membership_level       AS `등급`
   , grade_sales.`구매자 수`
   , grade_sales.`등급 매출`
   , ROUND(grade_sales.`등급 매출` * 100.0
       /total_sales.`전체 매출`, 1)           AS `비중`
   , grade_top_product.product_name       AS `인기 상품`
FROM grade_sales
CROSS JOIN total_sales                            -- 1행짜리 테이블 붙이기
LEFT JOIN grade_top_product
   ON grade_sales.membership_level=grade_top_product.membership_level
    AND grade_top_product.`ranking`=1                 -- 1위만
ORDER BY grade_sales.`등급 매출` DESC;

-- ============================================================
-- 예제 18 · [18.3] CTE 단계별 확인 요령
-- ============================================================

-- ▶ 실행해 보세요 — 대괄호는 자리를 표시한 것이라 그대로 실행하면 문법 에러가 납니다
WITH july_orders AS(
  SELECT ...
)
SELECT * FROM july_orders;                     -- 1단계만 확인

-- ============================================================
-- 예제 19 · [18.3 - CTE 단계별 실행] 1단계만 확인: 기초 데이터 검증
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
위 쿼리에서 이해가 안 되는 부분이 있어:
1. CROSS JOIN total_sales가 하는 역할이 뭐야?
2. ROW_NUMBER() OVER(PARTITION BY ...)는 어떻게 동작해?
각각 이 쿼리에서 어떤 역할을 하는지 설명해 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
-- 1단계만 확인: 기초 데이터가 제대로 추출됐는지
WITH phoenix_july_orders AS(
   SELECT o.order_id, o.fan_id, o.total_amount,
      p.product_name, f.membership_level
   FROM orders o
   INNER JOIN products p ON o.product_id=p.product_id
   INNER JOIN fans f ON o.fan_id=f.fan_id
   WHERE p.artist_id=3
    AND o.order_date >='2026-07-01'
    AND o.order_date <'2026-08-01'
)
SELECT * FROM phoenix_july_orders;

-- ============================================================
-- 예제 20 · [18.3 - CTE 2단계 확인] 2단계만 확인: 전체 매출 검증
-- ============================================================

-- ▶ 실행해 보세요 — 앞 단계의 CTE 없이는 실행되지 않아 에러가 납니다. 이어 붙여 쓰는 조각입니다
2단계만 확인: 전체 매출이 720,000인지
(1단계 CTE를 복사한 후 아래만 추가)
...
SELECT SUM(total_amount) AS `전체 매출` FROM phoenix_july_orders;

