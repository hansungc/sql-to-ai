-- 이전 3칼럼 eval_cases를 Day 25 v2 구조로 확장합니다.
-- 기존 case_name, request, expected_hash와 행은 삭제하지 않습니다.

DELIMITER //

DROP PROCEDURE IF EXISTS upgrade_eval_cases_v2//
CREATE PROCEDURE upgrade_eval_cases_v2()
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = DATABASE() AND table_name = 'eval_cases'
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'eval_cases가 없습니다. Day 25의 CREATE TABLE부터 실행하세요.';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'eval_cases' AND column_name = 'canonical_sql') THEN
    ALTER TABLE eval_cases ADD COLUMN canonical_sql TEXT NULL AFTER request;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'eval_cases' AND column_name = 'expected_result') THEN
    ALTER TABLE eval_cases ADD COLUMN expected_result JSON NULL AFTER canonical_sql;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'eval_cases' AND column_name = 'hash_algorithm') THEN
    ALTER TABLE eval_cases ADD COLUMN hash_algorithm VARCHAR(10) NULL AFTER expected_result;
  END IF;
  -- SHA-256 대안(64자)을 저장할 수 있도록 CHAR(32)이면 넓힙니다.
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'eval_cases'
      AND column_name = 'expected_hash' AND CHARACTER_MAXIMUM_LENGTH < 64
  ) THEN
    ALTER TABLE eval_cases MODIFY expected_hash VARCHAR(64);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'eval_cases' AND column_name = 'expected_row_count') THEN
    ALTER TABLE eval_cases ADD COLUMN expected_row_count INT UNSIGNED NULL AFTER expected_hash;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'eval_cases' AND column_name = 'dataset_version') THEN
    ALTER TABLE eval_cases ADD COLUMN dataset_version VARCHAR(50) NULL AFTER expected_row_count;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'eval_cases' AND column_name = 'serialization_version') THEN
    ALTER TABLE eval_cases ADD COLUMN serialization_version VARCHAR(50) NULL AFTER dataset_version;
  END IF;

  -- 책의 Universe 예제로 만든 기존 행만, 알려진 기준값으로 보완합니다.
  UPDATE eval_cases
  SET canonical_sql = COALESCE(
        canonical_sql,
        'SELECT s.stream_date, SUM(s.play_count) AS daily_streams FROM streaming s JOIN tracks t ON s.track_id = t.track_id WHERE t.track_name = ''Universe'' AND s.stream_date >= ''2026-07-01'' AND s.stream_date < ''2026-08-01'' GROUP BY s.stream_date ORDER BY s.stream_date'
      ),
      expected_result = COALESCE(
        expected_result,
        JSON_ARRAY(
          JSON_OBJECT('stream_date', '2026-07-22', 'daily_streams', 212),
          JSON_OBJECT('stream_date', '2026-07-23', 'daily_streams', 233),
          JSON_OBJECT('stream_date', '2026-07-24', 'daily_streams', 256),
          JSON_OBJECT('stream_date', '2026-07-25', 'daily_streams', 232)
        )
      ),
      hash_algorithm = COALESCE(
        hash_algorithm,
        CASE CHAR_LENGTH(expected_hash) WHEN 32 THEN 'MD5' WHEN 64 THEN 'SHA256' END
      ),
      expected_row_count = COALESCE(expected_row_count, 4),
      dataset_version = COALESCE(dataset_version, 'harmony_v1'),
      serialization_version = COALESCE(
        serialization_version, 'date-colon-integer-comma-v1'
      )
  WHERE case_name IN ('universe-daily-streams', 'universe-daily-streams-sha256');
END//

CALL upgrade_eval_cases_v2()//
DROP PROCEDURE upgrade_eval_cases_v2//

DELIMITER ;

SHOW COLUMNS FROM eval_cases;

-- 아래 결과가 남으면 해당 case의 SQL·정답 행·직렬화 규칙을 사람이 보완해야 합니다.
SELECT case_name
FROM eval_cases
WHERE canonical_sql IS NULL
   OR expected_result IS NULL
   OR hash_algorithm IS NULL
   OR expected_row_count IS NULL
   OR dataset_version IS NULL
   OR serialization_version IS NULL;
