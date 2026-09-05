-- ============================================
-- 5주차 환경 셋업
-- HARMONY 데이터셋과 query_history 실행 기록
-- (교재 436~437쪽)
-- ============================================
-- 전제: HARMONY 데이터셋이 harmony_db에 적재되어 있어야 합니다.
--       같은 내용의 파일이 두 이름으로 들어 있으니 둘 중 하나만 적재하세요.
--         - 0주차/harmony_v1.sql                    (본편 적재용)
--         - 5주차/harmony-analysis/harmony_v1.sql   (도커가 사용)

-- 1) query_history 테이블 생성
--    AI가 실행한 쿼리를 기록하는 실행 기록용 테이블 (Day 24, 25에서 사용)
--
--    ※ 교재 436쪽은 6칼럼(query_id, category, description, sql_query,
--      created_datetime, verified)입니다. 여기에는 Day 24의 record-query.sh가
--      "누가·어떤 도구로·성공했는지"까지 남길 수 있도록 7칼럼을 더했습니다.
--        session_id, tool_use_id, executor, agent_name, tool_name,
--        execution_status, error_message
--      교재의 6칼럼만으로도 Day 24·25 실습은 진행됩니다. 그 경우 record-query.sh에서
--      추가 칼럼을 넣는 부분을 빼면 됩니다.
--
--    부록 N 또는 이전 5주차 테이블이 이미 있으면 데이터를 지우지 말고
--    query_history_upgrade_v2.sql을 관리자 계정으로 먼저 실행합니다.
CREATE TABLE IF NOT EXISTS query_history(
   query_id INT PRIMARY KEY AUTO_INCREMENT,
   session_id VARCHAR(100),
   tool_use_id VARCHAR(100),
   executor VARCHAR(100),
   agent_name VARCHAR(100),
   tool_name VARCHAR(150),
   category VARCHAR(50),
   description VARCHAR(200),
   sql_query TEXT,
   execution_status VARCHAR(20) NOT NULL DEFAULT 'success',
   error_message TEXT,
   created_datetime DATETIME DEFAULT CURRENT_TIMESTAMP,
   verified BOOLEAN DEFAULT FALSE
);

-- 2) 데이터 준비 확인 - 주요 테이블 8개 행 수 검증
--    기대 결과: artists 15 / fans 111 / tracks 104 / streaming 375
--              orders 234 / subscription_history 100 / fan_activities 140
--              query_history 0
SELECT 'artists' AS table_name, COUNT(*) AS row_count FROM artists
UNION ALL SELECT 'fans', COUNT(*) FROM fans
UNION ALL SELECT 'tracks', COUNT(*) FROM tracks
UNION ALL SELECT 'streaming', COUNT(*) FROM streaming
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'subscription_history', COUNT(*) FROM subscription_history
UNION ALL SELECT 'fan_activities', COUNT(*) FROM fan_activities
UNION ALL SELECT 'query_history', COUNT(*) FROM query_history;
