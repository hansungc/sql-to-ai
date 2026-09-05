-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- 부록 N  RAG 기초 - 과거 쿼리 이력으로 AI 성능 높이기
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

-- ⚠ 주의: 5주차의 query_history와 이름은 같지만 칼럼이 다릅니다.
--    특히 '도커로_MySQL_준비하기.md'로 환경을 만들었다면 컨테이너 첫 실행 때
--    5주차용 query_history가 이미 만들어지므로, 아래 CREATE는 항상 실패합니다.
--    그때는 (2)번 방법(테이블 이름 바꿔 실습)을 권합니다.
--    부록 N : created_at DATE
--    5주차  : created_datetime DATETIME  (5주차/환경셋업/query_history_setup.sql)
--    한 DB에서 둘 다 실습하면 'Table already exists' 또는 'Unknown column' 오류가 납니다.
--    두 실습을 모두 진행한다면 아래 중 하나를 택하세요.
--      (1) 부록 N을 별도 DB에서 실습        : CREATE DATABASE appendix_db; USE appendix_db;
--      (2) 부록 N 테이블 이름을 바꿔 실습    : query_history -> query_history_appendix
--      (3) 앞서 만든 테이블을 지우고 다시 생성: DROP TABLE IF EXISTS query_history;

-- ============================================================
-- 예제 1 · [쿼리 이력 관리하기] 쿼리 이력 관리 테이블 생성
-- ============================================================

CREATE TABLE query_history(
   query_id INT PRIMARY KEY AUTO_INCREMENT,
   category VARCHAR(50),
   description VARCHAR(200),
   sql_query TEXT,
   created_at DATE,
   verified BOOLEAN DEFAULT FALSE
);

-- ============================================================
-- 예제 2 · [쿼리 이력 관리하기] 검증된 VIP 팬 구매 쿼리 저장
-- ============================================================

INSERT INTO query_history(category, description, sql_query, created_at, verified)
VALUES
('매출', 'VIP 등급 팬의 7월 총 구매 금액 조회',
 'SELECT SUM(o.total_amount) AS `vip_total`
  FROM orders o
  INNER JOIN fans f ON o.fan_id=f.fan_id
  WHERE f.membership_level=''VIP''
   AND o.order_date >= ''2026-07-01''
   AND o.order_date < ''2026-08-01'';',
 '2026-08-01',
 TRUE);

-- ============================================================
-- 예제 3 · [유사 쿼리 검색하기] 카테고리별 검증된 쿼리 조회
-- ============================================================

SELECT description, sql_query
FROM query_history
WHERE category='매출'
 AND verified=TRUE
ORDER BY created_at DESC
LIMIT 3;

-- ============================================================
-- 예제 4 · [패턴 예시] Few-Shot 프롬프트의 SQL 패턴
-- ============================================================

SELECT SUM(o.total_amount) AS `vip_total`
FROM orders o
INNER JOIN fans f ON o.fan_id=f.fan_id
WHERE f.membership_level='VIP'
 AND o.order_date >='2026-07-01'
 AND o.order_date <'2026-08-01';
