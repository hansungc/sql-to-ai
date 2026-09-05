-- 기존 query_history의 행을 지우지 않고 Day 24·25용 v2 구조로 올립니다.
-- MySQL 8.4 관리자 계정으로 harmony_db에서 한 번 실행하세요.

DELIMITER //

DROP PROCEDURE IF EXISTS upgrade_query_history_v2//
CREATE PROCEDURE upgrade_query_history_v2()
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = DATABASE() AND table_name = 'query_history'
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'query_history가 없습니다. query_history_setup.sql을 먼저 실행하세요.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'query_history'
      AND column_name = 'created_at'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'query_history'
      AND column_name = 'created_datetime'
  ) THEN
    ALTER TABLE query_history
      CHANGE COLUMN created_at created_datetime DATETIME DEFAULT CURRENT_TIMESTAMP;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'query_history' AND column_name = 'session_id') THEN
    ALTER TABLE query_history ADD COLUMN session_id VARCHAR(100) AFTER query_id;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'query_history' AND column_name = 'tool_use_id') THEN
    ALTER TABLE query_history ADD COLUMN tool_use_id VARCHAR(100) AFTER session_id;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'query_history' AND column_name = 'executor') THEN
    ALTER TABLE query_history ADD COLUMN executor VARCHAR(100) AFTER tool_use_id;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'query_history' AND column_name = 'agent_name') THEN
    ALTER TABLE query_history ADD COLUMN agent_name VARCHAR(100) AFTER executor;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'query_history' AND column_name = 'tool_name') THEN
    ALTER TABLE query_history ADD COLUMN tool_name VARCHAR(150) AFTER agent_name;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'query_history' AND column_name = 'execution_status') THEN
    ALTER TABLE query_history ADD COLUMN execution_status VARCHAR(20) NOT NULL DEFAULT 'success' AFTER sql_query;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'query_history' AND column_name = 'error_message') THEN
    ALTER TABLE query_history ADD COLUMN error_message TEXT AFTER execution_status;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'query_history' AND column_name = 'created_datetime') THEN
    ALTER TABLE query_history ADD COLUMN created_datetime DATETIME DEFAULT CURRENT_TIMESTAMP AFTER error_message;
  END IF;
END//

CALL upgrade_query_history_v2()//
DROP PROCEDURE upgrade_query_history_v2//

DELIMITER ;

SHOW COLUMNS FROM query_history;
