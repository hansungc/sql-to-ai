-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 3  포토카드 인기 순위와 시세 추적 - ORDER BY
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
-- 예제 1 · [3.1] ORDER BY 기본 문법
-- ============================================================

-- ▶ 실행해 보세요 — 대괄호는 자리를 표시한 것이라 그대로 실행하면 문법 에러가 납니다
SELECT [칼럼명]
FROM [테이블명]
WHERE [조건]
ORDER BY [정렬 칼럼]

-- ============================================================
-- 예제 2 · [3.1] 포토카드 거래 테이블 구조 확인
-- ============================================================

SELECT *
FROM photocard_trades
LIMIT 3;

-- ============================================================
-- 예제 3 · [3.1] 거래 가격 높은 순 정렬 (DESC)
-- ============================================================

SELECT trade_id, product_id, trade_price, trade_date
FROM photocard_trades
ORDER BY trade_price DESC
LIMIT 3;

-- ============================================================
-- 예제 4 · [3.1] 거래 가격 낮은 순 정렬 (ASC)
-- ============================================================

SELECT trade_id, product_id, trade_price, trade_date
FROM photocard_trades
ORDER BY trade_price ASC
LIMIT 3;

-- ============================================================
-- 예제 5 · [3.1] 최근 거래부터 보기 - 날짜 정렬
-- ============================================================

SELECT trade_id, trade_date, trade_price, product_id
FROM photocard_trades
ORDER BY trade_date DESC
LIMIT 3;

-- ============================================================
-- 예제 6 · [3.1] 상품명 가나다순으로 보기 - 문자열 정렬
-- ============================================================

SELECT product_id, product_name, price
FROM products
WHERE category='포토카드'
ORDER BY product_name
LIMIT 3;

-- ============================================================
-- 예제 7 · [3.1] 조건 필터링 후 정렬하기 - WHERE+ORDER BY
-- ============================================================

SELECT trade_id, trade_count, trade_price, trade_date
FROM photocard_trades
WHERE trade_date BETWEEN '2026-07-15' AND '2026-07-24'
ORDER BY trade_count DESC
LIMIT 5;

-- ============================================================
-- 예제 8 · [3.1] TOP N 조회하기 - ORDER BY+LIMIT
-- ============================================================

SELECT trade_id, trade_price, trade_date
FROM photocard_trades
WHERE trade_date BETWEEN '2026-07-15' AND '2026-07-24'
ORDER BY trade_price DESC
LIMIT 3;

-- ============================================================
-- 예제 9 · [3.2] 같은 상품 안에서 가격순으로 정렬 (1단계)
-- ============================================================

SELECT product_id, trade_price, trade_date
FROM photocard_trades
WHERE trade_date BETWEEN '2026-07-15' AND '2026-07-24'
ORDER BY product_id
LIMIT 5;

-- ============================================================
-- 예제 10 · [3.2] 계산 결과로 정렬하고 싶을 때
-- ============================================================

SELECT
  trade_id,
  trade_price,
  trade_count,
  trade_price * trade_count AS `trade_amount`
FROM photocard_trades
WHERE trade_date BETWEEN '2026-07-15' AND '2026-07-24'
LIMIT 3;

-- ============================================================
-- 예제 11 · [3.2] 상품별로 묶고 가격순 정렬하기
-- ============================================================

SELECT product_id, trade_price, trade_date
FROM photocard_trades
WHERE trade_date BETWEEN '2026-07-15' AND '2026-07-24'
ORDER BY product_id, trade_price DESC
LIMIT 3;

-- ============================================================
-- 예제 12 · [3.2] 칼럼별로 정렬 방향 다르게 지정하기
-- ============================================================

SELECT product_id, trade_price, trade_date
FROM photocard_trades
WHERE trade_date BETWEEN '2026-07-15' AND '2026-07-24'
ORDER BY product_id DESC, trade_price ASC
LIMIT 6;

-- ============================================================
-- 예제 13 · [3.2] ORDER BY에 계산식 넣기
-- ============================================================

SELECT
  trade_id,
  trade_price,
  trade_count,
  trade_price * trade_count AS `trade_amount`
FROM photocard_trades
WHERE trade_date BETWEEN '2026-07-15' AND '2026-07-24'
ORDER BY trade_price * trade_count DESC
LIMIT 3;

-- ============================================================
-- 예제 14 · [3.2] 별칭으로 정렬하기
-- ============================================================

SELECT
  trade_id,
  trade_price,
  trade_count,
  trade_price * trade_count AS `trade_amount`
FROM photocard_trades
WHERE trade_date BETWEEN '2026-07-15' AND '2026-07-24'
ORDER BY `trade_amount` DESC
LIMIT 3;

-- ============================================================
-- 예제 15 · [3.2] 칼럼 번호로 정렬하기
-- ============================================================

SELECT
  trade_id,
  trade_price,
  trade_count,
  trade_price * trade_count AS `trade_amount`
FROM photocard_trades
WHERE trade_date BETWEEN '2026-07-15' AND '2026-07-24'
ORDER BY 4 DESC
LIMIT 3;

-- ============================================================
-- 예제 16 · [3.3] 거래 데이터 전체 구조 확인
-- ============================================================

SELECT *
FROM photocard_trades
WHERE trade_date BETWEEN '2026-07-15' AND '2026-07-24'
LIMIT 3;

-- ============================================================
-- 예제 17 · [3.3] 최근 거래 내역 조회하기
-- ============================================================

SELECT trade_id, product_id, trade_date, trade_price, trade_count
FROM photocard_trades
WHERE trade_date BETWEEN '2026-07-15' AND '2026-07-24'
ORDER BY trade_date DESC, trade_id DESC
LIMIT 3;

-- ============================================================
-- 예제 18 · [3.3] 거래 단가 높은 순 TOP 3
-- ============================================================

SELECT trade_id, product_id, trade_date, trade_price, trade_count
FROM photocard_trades
WHERE trade_date BETWEEN '2026-07-15' AND '2026-07-24'
ORDER BY trade_price DESC
LIMIT 3;

-- ============================================================
-- 예제 19 · [3.3] 거래액 기준 TOP 3
-- ============================================================

SELECT
  trade_id,
  product_id,
  trade_date,
  trade_price,
  trade_count,
  trade_price * trade_count AS `trade_amount`
FROM photocard_trades
WHERE trade_date BETWEEN '2026-07-15' AND '2026-07-24'
ORDER BY `trade_amount` DESC
LIMIT 3;

-- ============================================================
-- 예제 20 · [3.3] 거래액 기준 TOP 20
-- ============================================================

SELECT
  trade_id AS `거래 번호`,
  product_id AS `상품 ID`,
  trade_date AS `거래일`,
  trade_price AS `거래 단가`,
  trade_count AS `거래 수량`,
  trade_price * trade_count AS `거래액`
FROM photocard_trades
WHERE trade_date BETWEEN '2026-07-15' AND '2026-07-24'
ORDER BY `거래액` DESC
LIMIT 20;
