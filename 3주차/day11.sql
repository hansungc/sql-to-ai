-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 11  "긴급 데이터 요청, AI에게 맡겨 봅시다." - Zero-Shot & Few-Shot
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
--   ✕ 실행하지 마세요       일부러 주석 처리한 SQL입니다. 사유는 같은 줄에 적어 두었습니다
--   -- ※                   실습 안내 주석입니다. 입력하지도, 실행하지도 않습니다
-- ============================================

-- ============================================================
-- 예제 1 · [11.1] Zero-Shot: 스키마 정보 없이 질문
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
2026년 7월에 발매된 앨범 목록 보여 줘
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT * FROM albums
WHERE release_date BETWEEN '2026-07-01' AND '2026-07-31';

-- ============================================================
-- 예제 2 · [11.1] Zero-Shot: 스키마 정보 없이 질문 (오류 예제)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
SQL 쿼리로 작성해 줘.: 2026년 7월에 발매된 앨범의 이름과 발매일 조회
*/

-- ▼ AI가 만든 SQL  ✕ 실행하지 마세요 — 교재가 의도적으로 보여주는 '오류 예제'라 그대로 실행하면 에러가 납니다
-- SELECT title, published_date
-- FROM album
-- WHERE published_date BETWEEN '2026-07-01' AND '2026-07-31';

-- ============================================================
-- 예제 3 · [11.1] Zero-Shot: 스키마 정보 함께 전달
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: albums(album_id, album_name, release_date)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: 2026년 7월에 발매된 앨범의 이름과 발매일 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT album_name, release_date
FROM albums
WHERE release_date >= '2026-07-01'
  AND release_date < '2026-08-01';

-- ============================================================
-- 예제 4 · [11.1] GROUP BY 자동 생성
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: streaming(platform, play_count)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: 플랫폼별 `총 재생 횟수` 집계
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT platform,
   SUM(play_count) AS `total_plays`
FROM streaming
GROUP BY platform;

-- ============================================================
-- 예제 5 · [11.1] Few-Shot: YEAR() 함수 패턴 학습
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: artists(artist_id, artist_name, debut_date)

[패턴 예시]
Q: 2022년에 데뷔한 아티스트는?
A: SELECT artist_name FROM artists WHERE YEAR(debut_date)=2022;

[요청]
Q: 2024년에 데뷔한 아티스트는?
A:
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT artist_name
FROM artists
WHERE YEAR(debut_date) = 2024;

-- ============================================================
-- 예제 6 · [11.2] CREATE TABLE로 정확하게 전달 (단일 테이블)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
CREATE TABLE artists(
   artist_id INT PRIMARY KEY,
   artist_name VARCHAR(100),
   artist_type VARCHAR(20),                 -- 'GROUP' 또는 'SOLO'
   debut_date DATE,
   genre VARCHAR(50)                        -- 'K-POP', 'Ballad', 'Hip-Hop' 등
);

[요청]
위 스키마를 참고해서 SQL을 작성해 줘.: K-POP 장르의 그룹 중 2023년 이후 데뷔한 목록 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT artist_name, debut_date
FROM artists
WHERE genre = 'K-POP'
  AND artist_type = 'GROUP'
  AND debut_date >= '2023-01-01';

-- ============================================================
-- 예제 7 · [11.2] 테이블 관계 알려주기 (FOREIGN KEY 활용)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
CREATE TABLE tracks(
   track_id INT PRIMARY KEY,
   track_name VARCHAR(200),
   album_id INT,
   FOREIGN KEY(album_id) REFERENCES albums(album_id)
);

CREATE TABLE albums(
   album_id INT PRIMARY KEY,
   album_name VARCHAR(200),
   artist_id INT,
   FOREIGN KEY(artist_id) REFERENCES artists(artist_id)
);

CREATE TABLE artists(
   artist_id INT PRIMARY KEY,
   artist_name VARCHAR(100)
);

[요청]
위 스키마를 참고해서 SQL을 작성해 줘.: Celestial의 모든 트랙 이름 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT t.track_name
FROM tracks t
JOIN albums al ON t.album_id = al.album_id
JOIN artists a ON al.artist_id = a.artist_id
WHERE a.artist_name = 'Celestial';

-- ============================================================
-- 예제 8 · [11.2] 설명문으로 빠르게 전달
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: fans(fan_id, fan_name, membership_level, country)
- membership_level 값: 'VIP', '프리미엄', '일반'

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: 한국 VIP 팬 수 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT COUNT(*) AS `vip_count`
FROM fans
WHERE membership_level = 'VIP'
  AND country = '대한민국';

-- ============================================================
-- 예제 9 · [11.2] 샘플 데이터로 정확도 높이기
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: fans(fan_id, fan_name, membership_level)

[샘플 데이터]
| fan_id | fan_name | membership_level |
|--------|----------|------------------|
| 1      | 김민지   | VIP              |
| 4      | 정수아   | 프리미엄         |
| 5      | 최동현   | 일반             |

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: 프리미엄 등급 팬 목록 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT fan_id, fan_name
FROM fans
WHERE membership_level = '프리미엄';

-- ============================================================
-- 예제 10 · [11.3] 테이블 구조 확인: MySQL DESCRIBE
-- ============================================================

DESCRIBE daily_charts;

-- ============================================================
-- 예제 11 · [11.3] 테이블 구조 확인: PostgreSQL
-- ============================================================

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'daily_charts';

-- ============================================================
-- 예제 12 · [11.3] 테이블 구조 확인: Oracle
-- ============================================================

-- ▶ 실행해 보세요 — 다른 DBMS(PostgreSQL·Oracle·SQL Server) 문법이라 MySQL에서는 문법 에러가 납니다
SELECT column_name, data_type, data_length FROM ALL_TAB_COLUMNS
WHERE table_name = 'DAILY_CHARTS';

-- ============================================================
-- 예제 13 · [11.3] 테이블 구조 확인: SQL Server (INFORMATION_SCHEMA)
-- ============================================================

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'daily_charts';

-- ============================================================
-- 예제 14 · [11.3] 테이블 구조 확인: SQL Server (SP_HELP)
-- ============================================================

-- ▶ 실행해 보세요 — 다른 DBMS(PostgreSQL·Oracle·SQL Server) 문법이라 MySQL에서는 문법 에러가 납니다
SP_HELP 'daily_charts';

-- ============================================================
-- 예제 15 · [11.3] 테이블 구조 확인: Snowflake
-- ============================================================

-- ▶ 실행해 보세요 — 다른 DBMS(PostgreSQL·Oracle·SQL Server) 문법이라 MySQL에서는 문법 에러가 납니다
※ MySQL에서 이 구문은 오류가 나지 않는 대신 전혀 다른 뜻이 됩니다.
   DESCRIBE는 EXPLAIN의 동의어라서 'TABLE daily_charts' 문장의 실행 계획이 출력됩니다.
   (MySQL 9부터는 그 실행 계획마저 TREE 형식으로 바뀌어 더 낯설게 보입니다.)
   테이블 구조를 보려면 위의 DESCRIBE daily_charts; 를 사용하세요.
DESCRIBE TABLE daily_charts;

-- ============================================================
-- 예제 16 · [11.3] 테이블 구조 확인: BigQuery
-- ============================================================

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'daily_charts';

-- ============================================================
-- 예제 17 · [11.3] 설명문 방식으로 빠르게 시작 (결과: track_id만 출력)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: daily_charts(track_id, chart_date, chart_rank, daily_streams)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: 2026년 7월 24일 차트 TOP 5의 순위와 스트리밍 수 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT chart_rank,
   track_id,
   daily_streams
FROM daily_charts
WHERE chart_date = '2026-07-24'
  AND chart_rank <= 5
ORDER BY chart_rank;

-- ============================================================
-- 예제 18 · [11.3] SHOW CREATE TABLE로 스키마 확인
-- ============================================================

SHOW CREATE TABLE daily_charts;

-- ============================================================
-- 예제 19 · [11.3] CREATE TABLE 방식으로 정확도 높이기
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
CREATE TABLE daily_charts(
   track_id INT,
   chart_date DATE,
   chart_rank INT,
   daily_streams INT,
   FOREIGN KEY(track_id) REFERENCES tracks(track_id)
);

CREATE TABLE tracks(
   track_id INT PRIMARY KEY,
   track_name VARCHAR(200),
   album_id INT,
   FOREIGN KEY(album_id) REFERENCES albums(album_id)
);

CREATE TABLE albums(
   album_id INT PRIMARY KEY,
   artist_id INT,
   FOREIGN KEY(artist_id) REFERENCES artists(artist_id)
);

CREATE TABLE artists(
   artist_id INT PRIMARY KEY,
   artist_name VARCHAR(100)
);

[요청]
위 스키마를 참고해서 SQL을 작성해 줘.: 2026년 7월 24일 차트 TOP 5의 순위, 아티스트, 곡명, 스트리밍 수 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT
  dc.chart_rank AS `순위`,
  ar.artist_name AS `아티스트`,
  t.track_name AS `곡명`,
  dc.daily_streams AS `스트리밍 수`
FROM daily_charts dc
JOIN tracks t ON dc.track_id = t.track_id
JOIN albums al ON t.album_id = al.album_id
JOIN artists ar ON al.artist_id = ar.artist_id
WHERE dc.chart_date = '2026-07-24'
  AND dc.chart_rank <= 5
ORDER BY dc.chart_rank;

-- ============================================================
-- 예제 20 · [11.3] 결과 검증: 곡 정보 확인
-- ============================================================

SELECT track_id, track_name
FROM tracks
WHERE track_id = 93;

-- ============================================================
-- 예제 21 · [11.3] 결과 검증: 스트리밍 수 확인
-- ============================================================

SELECT daily_streams
FROM daily_charts
WHERE track_id = 93
  AND chart_date = '2026-07-24';

-- ============================================================
-- 예제 22 · [프롬프팅 기본 구조] 스키마 정보와 요청 분리하기
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: 테이블명(칼럼1, 칼럼2, ...)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: [구체적인 분석 요청]
*/
