-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 12  "빨간 에러 메시지, AI가 해결해 줍니다." - 구문 및 의미 오류 검증
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
--   ✕ 실행하지 마세요       일부러 주석 처리한 SQL입니다. 사유는 같은 줄에 적어 두었습니다
--   ▶ 실행해 보세요       실행해도 됩니다. 무엇을 보게 될지 같은 줄에 적어 두었습니다
--   -- ※                   실습 안내 주석입니다. 입력하지도, 실행하지도 않습니다
-- ============================================

-- ============================================================
-- 예제 1 · [12.1] 키워드 오타: SELEC → SELECT
-- ============================================================

-- ▶ 실행해 보세요 — SELEC 오타 때문에 문법 에러가 납니다. 메시지가 어디를 가리키는지 확인해 보세요
SELEC fan_name, join_date
FROM fans
WHERE membership_level='VIP';

-- ============================================================
-- 예제 2 · [12.1] 키워드 오타: 수정된 쿼리
-- ============================================================

SELECT fan_name, join_date
FROM fans
WHERE membership_level='VIP'
ORDER BY join_date DESC
LIMIT 3;

-- ============================================================
-- 예제 3 · [12.1] 쉼표 누락: 칼럼 구분자
-- ============================================================

-- ▶ 실행해 보세요 — 결과의 칼럼이 'join_date' 하나뿐인 것을 확인하세요.
--   쉼표가 빠지면 MySQL은 join_date를 fan_name의 별칭(AS 생략형)으로 해석합니다.
--   즉 팬 이름이 'join_date'라는 이름으로 나올 뿐, 가입일은 조회되지 않았습니다.
--   쉼표 누락은 이렇게 에러 없이 지나가는 경우와 문법 오류가 나는 경우로 갈립니다.
--   칼럼을 하나 더 붙여 보면 이번에는 1064 오류를 볼 수 있습니다.
--     SELECT fan_name join_date membership_level FROM fans;
--   에러가 나면 오히려 다행이고, 나지 않을 때가 더 위험합니다(→ Day 13).
SELECT fan_name join_date
FROM fans;

-- ============================================================
-- 예제 4 · [12.1] 쉼표 누락: 수정된 쿼리
-- ============================================================

SELECT fan_name, join_date
FROM fans
LIMIT 3;

-- ============================================================
-- 예제 5 · [12.1] 키워드 순서 오류: SELECT, FROM, WHERE
-- ============================================================

-- ▶ 실행해 보세요 — 칼럼 사이 쉼표가 빠져 문법 에러가 납니다
SELECT fan_name
WHERE membership_level='VIP'
FROM fans;

-- ============================================================
-- 예제 6 · [12.1] 키워드 순서 오류: 수정된 쿼리
-- ============================================================

SELECT fan_name
FROM fans
WHERE membership_level='VIP'
LIMIT 3;

-- ============================================================
-- 예제 7 · [12.1] SHOW TABLES로 테이블 확인
-- ============================================================

SHOW TABLES;

-- ============================================================
-- 예제 8 · [12.1] 존재하지 않는 테이블: fan 대신 fans
-- ============================================================

-- ▶ 실행해 보세요 — 테이블 이름이 fan이라 \"Table 'harmony_db.fan' doesn't exist\" 에러가 납니다
SELECT COUNT(*) AS `new_fans`
FROM fan
WHERE signup_date>='2026-07-01';

-- ============================================================
-- 예제 9 · [12.1] DESCRIBE로 칼럼 확인
-- ============================================================

DESCRIBE fans;

-- ============================================================
-- 예제 10 · [12.1] 존재하지 않는 칼럼: signup_date 대신 join_date
-- ============================================================

-- ▶ 실행해 보세요 — signup_date라는 칼럼이 없어 "Unknown column" 에러가 납니다
SELECT COUNT(*) AS `new_fans`
FROM fans
WHERE signup_date>='2026-07-01';

-- ============================================================
-- 예제 11 · [12.1] 칼럼명 수정: join_date 사용
-- ============================================================

SELECT COUNT(*) AS `new_fans`
FROM fans
WHERE join_date>='2026-07-01';

-- ============================================================
-- 예제 12 · [12.1] 데이터 타입 불일치: 숫자 칼럼에 문자열
-- ============================================================

-- ▶ 실행해 보세요 — price에 문자열을 넣어 "Data truncated for column 'price'" 에러가 납니다
INSERT INTO products(product_id, product_name, category, price, stock_quantity)
VALUES(101, 'StarLight 한정판 포토북', '포토북', '35000원', 500);

-- ============================================================
-- 예제 13 · [12.1] DESCRIBE로 칼럼 타입 확인
-- ============================================================

DESCRIBE products;

-- ============================================================
-- 예제 14 · [12.1] 데이터 타입 수정: 숫자만 입력
-- ============================================================

-- ※ 아래 DELETE는 교재에 없는 줄입니다. 이 파일을 두 번 이상 실행해도
--   'Duplicate entry 101' 오류가 나지 않도록 먼저 지우고 넣습니다.
DELETE FROM products WHERE product_id = 101;
INSERT INTO products(product_id, product_name, category, price, stock_quantity)
VALUES(101, 'StarLight 한정판 포토북', '포토북', 35000, 500);

-- ============================================================
-- 예제 15 · [12.2] MySQL, PostgreSQL, Snowflake, BigQuery - LIMIT 사용
-- ============================================================

SELECT * FROM fans LIMIT 10;

-- ============================================================
-- 예제 16 · [12.2] SQL Server - TOP 사용
-- ============================================================

-- ▶ 실행해 보세요 — 다른 DBMS(PostgreSQL·Oracle·SQL Server) 문법이라 MySQL에서는 문법 에러가 납니다
SELECT TOP 10 * FROM fans;

-- ============================================================
-- 예제 17 · [12.2] Oracle - FETCH FIRST ROWS ONLY 사용
-- ============================================================

-- ▶ 실행해 보세요 — 다른 DBMS(PostgreSQL·Oracle·SQL Server) 문법이라 MySQL에서는 문법 에러가 납니다
SELECT * FROM fans FETCH FIRST 10 ROWS ONLY;

-- ============================================================
-- 예제 18 · [12.2] MySQL, PostgreSQL - 버전 확인
-- ============================================================

-- ※ 지면은 9.5.0으로 인쇄돼 있으나, 각자 설치한 버전이 그대로 나옵니다.
SELECT VERSION();

-- ============================================================
-- 예제 19 · [12.2] Oracle - 버전 확인
-- ============================================================

-- ▶ 실행해 보세요 — 다른 DBMS(PostgreSQL·Oracle·SQL Server) 문법이라 MySQL에서는 문법 에러가 납니다
SELECT BANNER FROM V$VERSION WHERE ROWNUM=1;

-- ============================================================
-- 예제 20 · [12.2] SQL Server - 버전 확인
-- ============================================================

SELECT @@VERSION;

-- ============================================================
-- 예제 21 · [12.2] Snowflake - 버전 확인
-- ============================================================

-- ▶ 실행해 보세요 — 다른 DBMS(PostgreSQL·Oracle·SQL Server) 문법이라 MySQL에서는 문법 에러가 납니다
SELECT CURRENT_VERSION();

-- ============================================================
-- 예제 22 · [12.2] VIP 팬 목록 조회 (DBMS 정보 미포함)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: fans(fan_id, fan_name, membership_level)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: VIP 팬 목록을 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT fan_id, fan_name
FROM fans
WHERE membership_level='VIP';

-- ============================================================
-- 예제 23 · [12.2] VIP 팬 목록 조회 (DBMS 정보 포함)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: fans(fan_id, fan_name, membership_level)
- membership_level: 'VIP', '프리미엄', '일반'

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: VIP 팬 목록을 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT fan_id, fan_name
FROM fans
WHERE membership_level='VIP';

-- ============================================================
-- 예제 24 · [12.2] 한 번에 복잡하게 요청하면?
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: fans(fan_id, fan_name, join_date, membership_level)
- membership_level: 'VIP', '프리미엄', '일반'
테이블: orders(order_id, fan_id, product_id, quantity, total_amount)

[요청]
7월에 가입한 VIP 팬 중에서 구매 기록이 있는 팬의 이름과 총 구매 금액을 구매 금액 순으로 보여 줘.
*/

-- ============================================================
-- 예제 25 · [12.2] 2026년 7월 가입 VIP 팬 목록
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: fans(fan_id, fan_name, join_date, membership_level)
- membership_level: 'VIP', '프리미엄', '일반'

[요청]
2026년 7월에 가입한 VIP 팬 목록 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT fan_id, fan_name
FROM fans
WHERE membership_level='VIP'
  AND join_date BETWEEN '2026-07-01' AND '2026-07-31';

-- ============================================================
-- 예제 26 · [12.2] 2026년 7월 가입 VIP 팬별 구매 분석
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: fans(fan_id, fan_name, join_date, membership_level)
- membership_level: 'VIP', '프리미엄', '일반'
테이블: orders(order_id, fan_id, product_id, quantity, total_amount)

[요청]
2026년 7월에 가입한 VIP 팬별 구매 횟수와 총 구매 금액을 구매 금액 내림차순으로 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT f.fan_id, f.fan_name,
   COUNT(o.order_id) AS `order_count`,
   SUM(o.total_amount) AS `total_spent`
FROM fans f
JOIN orders o ON f.fan_id=o.fan_id
WHERE f.membership_level='VIP'
  AND f.join_date BETWEEN '2026-07-01' AND '2026-07-31'
GROUP BY f.fan_id, f.fan_name
ORDER BY `total_spent` DESC;

-- ============================================================
-- 예제 27 · [12.2] DBMS 미지정 시 AI 응답 - MySQL 문법
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: fans(fan_id, fan_name, membership_level, join_date)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: 최근 가입한 팬 10명 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
-- MySQL에서는 정상 실행되지만, SQL Server에서 실행하면
-- "Error: Incorrect syntax near 'LIMIT'." 에러가 발생하는 예제입니다.
SELECT fan_id, fan_name, join_date
FROM fans
ORDER BY join_date DESC
LIMIT 10;

-- ============================================================
-- 예제 28 · [12.3] 아티스트별 총 상품 매출 조회 (GROUP BY 누락)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: products(product_id, product_name, artist_id, category, price, stock_quantity)
테이블: orders(order_id, fan_id, product_id, order_date, quantity, total_amount)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: 아티스트별 총 상품 매출 조회
*/

-- ▼ AI가 만든 SQL  ✕ 실행하지 마세요 — 교재가 의도적으로 보여주는 '오류 예제'라 그대로 실행하면 에러가 납니다
-- SELECT p.artist_id,
--    SUM(o.total_amount) AS `total_revenue`
-- FROM products p
-- JOIN orders o ON p.product_id=o.product_id;

-- ============================================================
-- 예제 29 · [12.3] 아티스트별 총 상품 매출 조회 (수정된 쿼리)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[원래 질문]
아티스트별 총 상품 매출을 조회하려고 했어.

[작성한 SQL]
SELECT p.artist_id, SUM(o.total_amount) AS `total_revenue`
FROM products p
JOIN orders o ON p.product_id=o.product_id;

[에러 메시지]
Query Error: In aggregated query without GROUP BY,
expression #1 of SELECT list contains nonaggregated column 'test.p.artist_id';
this is incompatible with sql_mode=only_full_group_by

[실제 테이블 스키마]
- products: product_id, product_name, artist_id, category, price, stock_quantity
- orders: order_id, fan_id, product_id, order_date, quantity, total_amount
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT p.artist_id,
   SUM(o.total_amount) AS `total_revenue`
FROM products p
JOIN orders o ON p.product_id=o.product_id
GROUP BY p.artist_id
ORDER BY `total_revenue` DESC;

-- ============================================================
-- 예제 30 · [12.3] 전체 평균 주문 금액보다 높은 아티스트 (서브쿼리 오류)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: products(product_id, product_name, artist_id, category, price, stock_quantity)
테이블: orders(order_id, fan_id, product_id, order_date, quantity, total_amount)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.:
전체 평균 주문 금액보다 평균 주문 금액이 높은 아티스트 목록 조회
*/

-- ▼ AI가 만든 SQL  ✕ 실행하지 마세요 — 교재가 의도적으로 보여주는 '오류 예제'라 그대로 실행하면 에러가 납니다
-- SELECT p.artist_id
-- FROM products p
-- JOIN orders o ON p.product_id=o.product_id
-- GROUP BY p.artist_id
-- HAVING SUM(o.total_amount) >(
--    SELECT SUM(total_amount)
--    FROM orders
--    GROUP BY product_id
-- );

-- ============================================================
-- 예제 31 · [12.3] 전체 평균 주문 금액보다 높은 아티스트 (수정된 쿼리)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[원래 질문]
전체 평균 주문 금액보다 평균 주문 금액이 높은 아티스트 목록을 조회하려고 했어.

[작성한 SQL]
SELECT p.artist_id
FROM products p
JOIN orders o ON p.product_id=o.product_id
GROUP BY p.artist_id
HAVING SUM(o.total_amount) >(
   SELECT SUM(total_amount)
   FROM orders
   GROUP BY product_id
);

[에러 메시지]
Query Error: Subquery returns more than 1 row

[실제 테이블 스키마]
- products: product_id, product_name, artist_id, category, price, stock_quantity
- orders: order_id, fan_id, product_id, order_date, quantity, total_amount
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT p.artist_id,
   AVG(o.total_amount) AS `avg_revenue`
FROM products p
JOIN orders o ON p.product_id=o.product_id
GROUP BY p.artist_id
HAVING AVG(o.total_amount) >(
  SELECT AVG(total_amount) FROM orders
)
ORDER BY `avg_revenue` DESC;

-- ============================================================
-- 예제 32 · [SQL Server 최근 가입 팬 10명]
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[환경 정보]
DBMS: SQL Server 2025

[스키마 정보]
테이블: fans(fan_id, fan_name, membership_level, join_date)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: 최근 가입한 팬 10명 조회
*/

-- ▼ AI가 만든 SQL  ✕ 실행하지 마세요 — SQL Server의 문법이라 MySQL에서는 실행하지 않습니다
-- SELECT TOP 10 fan_id, fan_name, join_date
-- FROM fans
-- ORDER BY join_date DESC;
