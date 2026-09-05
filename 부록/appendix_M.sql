-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- 부록 M  DBMS별 스키마 정보 추출 방법
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
--   ✕ 실행하지 마세요       일부러 주석 처리한 SQL입니다. 사유는 같은 줄에 적어 두었습니다
--   -- ※                   실습 안내 주석입니다. 입력하지도, 실행하지도 않습니다
-- ============================================

-- ============================================================
-- 예제 1 · [M.1] MySQL 테이블 DDL 추출
-- ============================================================

SHOW CREATE TABLE orders;

-- ============================================================
-- 예제 2 · [M.2] PostgreSQL INFORMATION_SCHEMA 칼럼 정보 조회
-- ============================================================

SELECT column_name, data_type, is_nullable, column_default
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_schema='public' AND table_name='orders'
ORDER BY ordinal_position;

-- ============================================================
-- 예제 3 · [M.3] PostgreSQL pg_description 카탈로그 조회
-- ============================================================

-- ▶ 실행해 보세요 — 다른 DBMS(PostgreSQL·Oracle·SQL Server) 문법이라 MySQL에서는 문법 에러가 납니다
SELECT col.column_name, pgd.description AS comment
FROM INFORMATION_SCHEMA.COLUMNS col
LEFT JOIN pg_description pgd
 ON pgd.objsubid=col.ordinal_position
 AND pgd.objoid=(
   SELECT oid FROM pg_class
   WHERE relname='orders'
     AND relnamespace=(
       SELECT oid FROM pg_namespace WHERE nspname='public'
     )
 )
WHERE col.table_schema='public'
  AND col.table_name='orders'
ORDER BY col.ordinal_position;

-- ============================================================
-- 예제 4 · [M.4] PostgreSQL pg_dump으로 테이블 DDL 추출 [shell]
-- ============================================================

-- ✕ 실행하지 마세요 — SQL이 아니라 터미널에서 실행하는 명령이라 여기서는 실행하지 않습니다
-- pg_dump --schema-only --table=orders 데이터베이스명

-- ============================================================
-- 예제 5 · [M.5] Oracle DBMS_METADATA.GET_DDL 함수
-- ============================================================

-- ▶ 실행해 보세요 — 다른 DBMS(PostgreSQL·Oracle·SQL Server) 문법이라 MySQL에서는 문법 에러가 납니다
SELECT DBMS_METADATA.GET_DDL('TABLE', 'ORDERS', 'HR')
FROM DUAL;

-- ============================================================
-- 예제 6 · [M.6] SQL Server sp_help 시스템 프로시저
-- ============================================================

-- ▶ 실행해 보세요 — 다른 DBMS(PostgreSQL·Oracle·SQL Server) 문법이라 MySQL에서는 문법 에러가 납니다
EXEC sp_help 'dbo.orders';

-- ============================================================
-- 예제 7 · [M.7] Snowflake GET_DDL 함수 (기본 사용)
-- ============================================================

-- ▶ 실행해 보세요 — 다른 DBMS(PostgreSQL·Oracle·SQL Server) 문법이라 MySQL에서는 문법 에러가 납니다
SELECT GET_DDL('TABLE', 'ORDERS');

-- ============================================================
-- 예제 8 · [M.8] Snowflake GET_DDL 함수 (스키마 명시)
-- ============================================================

-- ▶ 실행해 보세요 — 다른 DBMS(PostgreSQL·Oracle·SQL Server) 문법이라 MySQL에서는 문법 에러가 납니다
SELECT GET_DDL('TABLE', 'MY_SCHEMA.ORDERS');

-- ============================================================
-- 예제 9 · [M.9] Snowflake GET_DDL 함수 (데이터베이스명 포함)
-- ============================================================

-- ▶ 실행해 보세요 — 다른 DBMS(PostgreSQL·Oracle·SQL Server) 문법이라 MySQL에서는 문법 에러가 납니다
SELECT GET_DDL('TABLE', 'MY_DATABASE.MY_SCHEMA.ORDERS');

-- ============================================================
-- 예제 10 · [M.10] INFORMATION_SCHEMA.TABLES 조회 (MySQL)
-- ============================================================

SELECT TABLE_NAME, TABLE_COMMENT
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA='데이터베이스명';

-- ============================================================
-- 예제 11 · [M.11] INFORMATION_SCHEMA.COLUMNS 조회 (MySQL)
-- ============================================================

-- ※ COLUMN_COMMENT가 지면은 '주문 ID'(공백 있음), 데이터셋의 실제 값은 '주문ID'입니다.
--    지면 표기와 데이터 값의 차이라 정상입니다.

SELECT COLUMN_NAME, DATA_TYPE, COLUMN_KEY, COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='데이터베이스명'
  AND TABLE_NAME='orders'
ORDER BY ORDINAL_POSITION;

-- ============================================================
-- 예제 12 · [M.12] INFORMATION_SCHEMA.KEY_COLUMN_USAGE 외래키 관계 조회 (MySQL)
-- ============================================================

SELECT TABLE_NAME, COLUMN_NAME,
    REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA='데이터베이스명'
  AND TABLE_NAME='orders'
  AND REFERENCED_TABLE_NAME IS NOT NULL;

-- ============================================================
-- 예제 13 · [부록 M] psql 백슬래시 명령어 - PostgreSQL [shell]
-- ============================================================

-- ✕ 실행하지 마세요 — SQL이 아니라 터미널에서 실행하는 명령이라 여기서는 실행하지 않습니다
-- \d+ orders

-- ============================================================
-- 예제 14 · [부록 M] COMMENT 조회 - PostgreSQL pg_description
-- ============================================================

-- ▶ 실행해 보세요 — PostgreSQL 문법이라 MySQL에서는 에러가 납니다
SELECT col.column_name, pgd.description AS `comment`
FROM INFORMATION_SCHEMA.COLUMNS col
LEFT JOIN pg_description pgd
 ON pgd.objsubid=col.ordinal_position
 AND pgd.objoid=(
   SELECT oid FROM pg_class
   WHERE relname='orders'
     AND relnamespace=(
       SELECT oid FROM pg_namespace WHERE nspname='public'
     )
 )
WHERE col.table_schema='public'
 AND col.table_name='orders'
ORDER BY col.ordinal_position;
