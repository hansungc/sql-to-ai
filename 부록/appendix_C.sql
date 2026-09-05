-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- 부록 C  날짜 함수 활용 - DATE, EXTRACT, 날짜 연산
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
-- 예제 1 · [현재 날짜와 시간 확인하기] NOW() 함수와 DATE() 함수
-- ============================================================

SELECT
  NOW() AS `현재 시간`,
  DATE(NOW()) AS `오늘 날짜`;

-- ============================================================
-- 예제 2 · [특정 날짜 거래만 조회하기] WHERE절로 특정 날짜만 조회
-- ============================================================

SELECT trade_id, trade_date, trade_price, product_id
FROM photocard_trades
WHERE trade_date='2026-07-22'
ORDER BY trade_price DESC
LIMIT 3;

-- ============================================================
-- 예제 3 · [날짜에서 연/월/일 각각 추출하기] EXTRACT 함수로 날짜 분리
-- ============================================================

SELECT
  trade_date,
  EXTRACT(YEAR FROM trade_date) AS `연도`,
  EXTRACT(MONTH FROM trade_date) AS `월`,
  EXTRACT(DAY FROM trade_date) AS `일`
FROM photocard_trades
WHERE trade_date BETWEEN '2026-07-15' AND '2026-07-24'
LIMIT 3;

-- ============================================================
-- 예제 4 · [MySQL의 간편 날짜 함수] YEAR/MONTH/DAY 함수 비교
-- ============================================================

-- ▶ 실행해 보세요 — 비교용으로 잘라 둔 불완전한 문장이라 문법 에러가 납니다
EXTRACT 사용(표준 SQL)
SELECT EXTRACT(YEAR FROM trade_date) AS `연도`

-- MySQL 전용 함수(더 짧음)
-- SELECT YEAR(trade_date) AS `연도`

-- ============================================================
-- 예제 5 · [날짜 더하기와 빼기] DATE_ADD와 DATE_SUB 함수
-- ============================================================

SELECT
  '2026-07-25' AS `기준일`,
  DATE_SUB('2026-07-25', INTERVAL 7 DAY) AS `일주일 전`,
  DATE_ADD('2026-07-25', INTERVAL 7 DAY) AS `일주일 후`;

-- ============================================================
-- 예제 6 · [최근 7일간 거래 조회하기] DATE_SUB로 기간 범위 지정
-- ============================================================

SELECT trade_id, trade_date, trade_price, product_id
FROM photocard_trades
WHERE trade_date >=DATE_SUB('2026-07-25', INTERVAL 7 DAY)
AND trade_date <='2026-07-25'
ORDER BY trade_date DESC
LIMIT 3;

-- ============================================================
-- 예제 7 · [CURDATE()를 사용한 동적 조회] 현재 날짜 기준 자동 갱신
-- ============================================================

SELECT trade_id, trade_date, trade_price, product_id
FROM photocard_trades
WHERE trade_date >=DATE_SUB(CURDATE(), INTERVAL 7 DAY)
AND trade_date <=CURDATE()
ORDER BY trade_date DESC
LIMIT 3;

-- ============================================================
-- 예제 8 · [두 날짜 사이 일수 계산하기] DATEDIFF 함수 활용
-- ============================================================

SELECT
  trade_id,
  trade_date,
  DATEDIFF(trade_date, '2026-07-22') AS `발매 후 경과일`,
  trade_price
FROM photocard_trades
WHERE trade_date >='2026-07-22'
ORDER BY trade_date
LIMIT 3;
