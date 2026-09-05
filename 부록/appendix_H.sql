-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- 부록 H  VIEW, 임시 테이블, 재귀 CTE - 더 넓은 활용
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
-- 예제 1 · [VIEW 생성] DROP VIEW 선행 정리
-- ============================================================

-- 같은 이름의 View가 이미 있으면 먼저 삭제
DROP VIEW IF EXISTS artist_album_summary;

-- ============================================================
-- 예제 2 · [VIEW 생성] VIEW 생성
-- ============================================================

-- View 생성
CREATE VIEW artist_album_summary AS
SELECT
   a.artist_id,
   a.artist_name AS `아티스트명`,
   COUNT(al.album_id) AS `앨범 수`,
   SUM(al.total_tracks) AS `총 트랙 수`,
   MAX(al.release_date) AS `최신 발매일`
FROM artists a
LEFT JOIN albums al ON a.artist_id=al.artist_id
GROUP BY a.artist_id, a.artist_name;

-- ============================================================
-- 예제 3 · [VIEW 생성] VIEW 조회
-- ============================================================

-- View 조회(MySQL 전용: LIMIT)
SELECT * FROM artist_album_summary
ORDER BY artist_id
LIMIT 3;

-- ============================================================
-- 예제 4 · [VIEW 삭제] VIEW 삭제
-- ============================================================

DROP VIEW IF EXISTS artist_album_summary;

-- ============================================================
-- 예제 5 · [부록 H] VIEW 생성 및 조회
-- ============================================================

DROP VIEW IF EXISTS artist_album_summary;

CREATE VIEW artist_album_summary AS
SELECT
  a.artist_id,
  a.artist_name AS `아티스트명`,
  COUNT(al.album_id) AS `앨범 수`,
  SUM(al.total_tracks) AS `총 트랙 수`,
  MAX(al.release_date) AS `최신 발매일`
FROM artists a
LEFT JOIN albums al ON a.artist_id=al.artist_id
GROUP BY a.artist_id, a.artist_name;

SELECT * FROM artist_album_summary
ORDER BY artist_id
LIMIT 3;

-- ============================================================
-- 예제 6 · [임시 테이블 만들기] 임시 테이블 만들기
-- ============================================================

CREATE TEMPORARY TABLE temp_july_sales AS
SELECT
  COUNT(DISTINCT order_id) AS `주문 수`,
  COUNT(DISTINCT fan_id) AS `구매 팬 수`,
  SUM(total_amount) AS `총 매출`
FROM orders
WHERE order_date >= '2026-07-22' AND order_date < '2026-08-01';

-- ============================================================
-- 예제 7 · [임시 테이블 만들기] 임시 테이블 조회
-- ============================================================

SELECT * FROM temp_july_sales;

-- ============================================================
-- 예제 8 · [연속 날짜 생성하기] 재귀 CTE로 연속 날짜 생성
-- ============================================================

WITH RECURSIVE date_range AS(
  SELECT DATE('2026-07-22') AS `the_date`
  UNION ALL
  SELECT DATE_ADD(`the_date`, INTERVAL 1 DAY)
  FROM date_range
  WHERE `the_date` < '2026-07-26'
)
SELECT the_date AS `날짜` FROM date_range;
