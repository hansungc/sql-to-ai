-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 17  '17개 테이블, 3개만 남기기' - 메타데이터 활용부터 심화 질문 도출
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
-- 예제 1 · [17.1] FK 정보 직접 조회(MySQL)
-- ============================================================

SELECT
   TABLE_NAME AS `테이블명`,
   COLUMN_NAME AS `칼럼명`,
   REFERENCED_TABLE_NAME AS `참조테이블`,
   REFERENCED_COLUMN_NAME AS `참조칼럼`
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
-- 교재 원문: WHERE TABLE_SCHEMA=DATABASE()  -- 교재 원문: 'test'(db-fiddle 기준) (db-fiddle 환경 기준)
WHERE TABLE_SCHEMA=DATABASE()
 AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;

-- ============================================================
-- 예제 2 · [17.1] 각 테이블의 PK 칼럼 조회(1단계)
-- ============================================================

SELECT TABLE_NAME AS `테이블명`,
COLUMN_NAME AS `PK 칼럼명`
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA=DATABASE()  -- 교재 원문: 'test'(db-fiddle 기준)
 AND CONSTRAINT_NAME='PRIMARY'
ORDER BY TABLE_NAME;

-- ============================================================
-- 예제 3 · [17.1] 특정 PK 칼럼명이 다른 테이블에 존재하는지 확인(2단계)
-- ============================================================

SELECT TABLE_NAME AS `테이블명`, COLUMN_NAME AS `칼럼명`
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA=DATABASE()  -- 교재 원문: 'test'(db-fiddle 기준)
 AND COLUMN_NAME='fan_id'
ORDER BY TABLE_NAME;

-- ============================================================
-- 예제 4 · [17.1] 실제 참조 관계 검증(3단계)
-- ============================================================

SELECT COUNT(*)
FROM streaming s
WHERE NOT EXISTS(SELECT 1 FROM fans f WHERE f.fan_id=s.fan_id);

-- ============================================================
-- 예제 5 · [17.1] 전체 테이블 메타데이터 추출(MySQL)
-- ============================================================

-- ※ 테이블 설명(TABLE_COMMENT)은 COLUMNS 뷰가 아니라 TABLES 뷰에 있습니다.
--    두 뷰를 조인해서 '테이블 설명 + 칼럼 목록'을 한 번에 만듭니다.
--
--    교재 원문 (참고용 - 아래 동작 버전을 실행하세요)
--    SELECT
--        TABLE_NAME AS `테이블명`,
--        TABLE_COMMENT AS `테이블 설명`,
--        GROUP_CONCAT(
--            CONCAT(COLUMN_NAME, '(', COLUMN_COMMENT, ')')
--        ) AS `주요 칼럼`
--    FROM INFORMATION_SCHEMA.COLUMNS
--    WHERE TABLE_SCHEMA='harmony'
--    GROUP BY TABLE_NAME, TABLE_COMMENT;

SELECT
   c.TABLE_NAME AS `테이블명`,
   t.TABLE_COMMENT AS `테이블 설명`,
   GROUP_CONCAT(
      CONCAT(c.COLUMN_NAME, '(', c.COLUMN_COMMENT, ')')
      ORDER BY c.ORDINAL_POSITION      -- ※ 정렬을 지정하지 않으면 MySQL 버전마다 순서가 달라집니다
   ) AS `주요 칼럼`
FROM INFORMATION_SCHEMA.COLUMNS c
JOIN INFORMATION_SCHEMA.TABLES t
  ON c.TABLE_SCHEMA=t.TABLE_SCHEMA AND c.TABLE_NAME=t.TABLE_NAME
WHERE c.TABLE_SCHEMA=DATABASE()
GROUP BY c.TABLE_NAME, t.TABLE_COMMENT;

-- ============================================================
-- 예제 6 · [17.1] 팬 도메인 테이블만 추출(MySQL)
-- ============================================================

-- ※ 예제 5와 같은 이유로 TABLES 뷰를 조인합니다.
--
--    교재 원문 (참고용 - 아래 동작 버전을 실행하세요)
--    SELECT
--        TABLE_NAME AS `테이블명`,
--        TABLE_COMMENT AS `테이블 설명`,
--        GROUP_CONCAT(COLUMN_NAME) AS `주요 칼럼`
--    FROM INFORMATION_SCHEMA.COLUMNS
--    WHERE TABLE_SCHEMA='test'
--      AND TABLE_NAME IN('fans', 'fan_activities', 'subscription_history', 'sns_reactions')
--    GROUP BY TABLE_NAME, TABLE_COMMENT;

SELECT
   c.TABLE_NAME AS `테이블명`,
   t.TABLE_COMMENT AS `테이블 설명`,
   GROUP_CONCAT(c.COLUMN_NAME ORDER BY c.ORDINAL_POSITION) AS `주요 칼럼`  -- ※ 정렬 지정(버전 간 순서 고정)
FROM INFORMATION_SCHEMA.COLUMNS c
JOIN INFORMATION_SCHEMA.TABLES t
  ON c.TABLE_SCHEMA=t.TABLE_SCHEMA AND c.TABLE_NAME=t.TABLE_NAME
WHERE c.TABLE_SCHEMA=DATABASE()
 AND c.TABLE_NAME IN('fans', 'fan_activities', 'subscription_history', 'sns_reactions')
GROUP BY c.TABLE_NAME, t.TABLE_COMMENT;

-- ============================================================
-- 예제 7 · [17.2] 샘플 행 조회
-- ============================================================

SELECT * FROM fan_activities WHERE artist_id=3 LIMIT 5;

-- ============================================================
-- 예제 8 · [17.2] 고유값 추출
-- ============================================================

SELECT DISTINCT activity_type
FROM fan_activities;

-- ============================================================
-- 예제 9 · [17.2] fan_activities 테이블 스키마
-- ============================================================

-- ▶ 실행해 보세요 — 이미 있는 테이블이라 "already exists" 에러가 납니다. 스키마를 참고용으로 다시 보여 준 것입니다
CREATE TABLE fan_activities(
   activity_id INT PRIMARY KEY COMMENT '활동 ID',
   fan_id INT COMMENT '팬 ID',
   activity_type VARCHAR(50) COMMENT '활동 유형',
   activity_datetime DATETIME COMMENT '활동 일시',
   artist_id INT COMMENT '아티스트 ID',
   FOREIGN KEY(fan_id) REFERENCES fans(fan_id),
   FOREIGN KEY(artist_id) REFERENCES artists(artist_id)
);

-- ============================================================
-- 예제 10 · [17.2] 활동 유형별 비중 분석
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
CREATE TABLE fan_activities(
   activity_id INT PRIMARY KEY COMMENT '활동 ID',
   fan_id INT COMMENT '팬 ID',
   activity_type VARCHAR(50) COMMENT '활동 유형', -- login, stream, purchase, comment, like, share
   activity_datetime DATETIME COMMENT '활동 일시',
   artist_id INT COMMENT '아티스트 ID',
   FOREIGN KEY(fan_id) REFERENCES fans(fan_id),
   FOREIGN KEY(artist_id) REFERENCES artists(artist_id)
);

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.:
Phoenix(artist_id=3) 관련 활동 유형별 건수를 조회해 줘.
건수 내림차순으로 정렬해 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT activity_type,
   COUNT(*) AS `activity_count`
FROM fan_activities
WHERE artist_id=3
GROUP BY activity_type
ORDER BY `activity_count` DESC;

-- ============================================================
-- 예제 11 · [17.2] 활동 유형별 비중 분석 검증
-- ============================================================

SELECT COUNT(*)
FROM fan_activities
WHERE artist_id=3;

-- ============================================================
-- 예제 12 · [17.2] 스키마 상세 확인 - SHOW CREATE TABLE
-- ============================================================

SHOW CREATE TABLE fan_activities;
-- ============================================================
-- 예제 13 · [17.3] fans 테이블 스키마
-- ============================================================

-- ▶ 실행해 보세요 — 이미 있는 테이블이라 "already exists" 에러가 납니다. 스키마를 참고용으로 다시 보여 준 것입니다
CREATE TABLE fans(
   fan_id INT PRIMARY KEY COMMENT '팬 ID',
   fan_name VARCHAR(100) COMMENT '팬명',
   email VARCHAR(200) COMMENT '이메일',
   join_date DATE COMMENT '가입일',
   membership_level VARCHAR(50) COMMENT '멤버십 등급',
   favorite_artist_id INT COMMENT '최애 아티스트 ID',
   country VARCHAR(50) COMMENT '국가',
   FOREIGN KEY(favorite_artist_id) REFERENCES artists(artist_id)
);

-- ============================================================
-- 예제 14 · [17.3] subscription_history 테이블 스키마
-- ============================================================

-- ▶ 실행해 보세요 — 이미 있는 테이블이라 "already exists" 에러가 납니다. 스키마를 참고용으로 다시 보여 준 것입니다
CREATE TABLE subscription_history(
   subscription_id INT PRIMARY KEY COMMENT '구독 ID',
   fan_id INT COMMENT '팬 ID',
   status VARCHAR(20) COMMENT '구독 상태',
   start_date DATE COMMENT '시작일',
   end_date DATE COMMENT '종료일',
   monthly_fee INT COMMENT '월 구독료',
   FOREIGN KEY(fan_id) REFERENCES fans(fan_id)
);

-- ============================================================
-- 예제 15 · [17.3] 구독 상태별 인원수 조회
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
CREATE TABLE fans(
   fan_id INT PRIMARY KEY COMMENT '팬 ID',
   fan_name VARCHAR(100) COMMENT '팬명',
   email VARCHAR(200) COMMENT '이메일',
   join_date DATE COMMENT '가입일',
   membership_level VARCHAR(50) COMMENT '멤버십 등급',
   favorite_artist_id INT COMMENT '최애 아티스트 ID',
   country VARCHAR(50) COMMENT '국가',
   FOREIGN KEY(favorite_artist_id) REFERENCES artists(artist_id)
);

CREATE TABLE subscription_history(
   subscription_id INT PRIMARY KEY COMMENT '구독 ID',
   fan_id INT COMMENT '팬 ID',
   status VARCHAR(20) COMMENT '구독 상태',   -- active, churned, reactivated
   start_date DATE COMMENT '시작일',
   end_date DATE COMMENT '종료일',
   monthly_fee INT COMMENT '월 구독료',
   FOREIGN KEY(fan_id) REFERENCES fans(fan_id)
);

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.:
Phoenix(favorite_artist_id=3) 팬의 구독 상태별 인원수를 조회해 줘.
- 한 팬이 구독 이력을 여러 개 가질 수 있으므로 중복 제거해 줘.
- 인원수 내림차순으로 정렬해 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT sh.status,
   COUNT(DISTINCT f.fan_id) AS `fan_count`
FROM fans f
JOIN subscription_history sh ON f.fan_id=sh.fan_id
WHERE f.favorite_artist_id=3
GROUP BY sh.status
ORDER BY `fan_count` DESC;

-- ============================================================
-- 예제 16 · [17.3] 이탈 팬 상세 정보 조회
-- ============================================================

SELECT f.fan_id,
   f.fan_name,
   sh.end_date AS `churned_date`
FROM fans f
JOIN subscription_history sh ON f.fan_id=sh.fan_id
WHERE f.favorite_artist_id=3
 AND sh.status='churned'
ORDER BY sh.end_date DESC;

-- ============================================================
-- 예제 17 · [17.3] Phoenix 팬 총 인원 검증
-- ============================================================

SELECT COUNT(*)
FROM fans
WHERE favorite_artist_id=3;

-- ============================================================
-- 예제 18 · [17.3] subscription_history에 기록된 팬 검증
-- ============================================================

SELECT COUNT(DISTINCT f.fan_id)
FROM fans f
JOIN subscription_history sh
 ON f.fan_id=sh.fan_id
WHERE f.favorite_artist_id=3;

