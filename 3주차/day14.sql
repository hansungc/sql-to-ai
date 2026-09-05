-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 14  "테이블이 17개인데 뭘 골라야 하죠?" - Schema Linking, Prompt Chaining
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
-- ============================================

-- ============================================================
-- 예제 1 · [14.1] 17개 전체 테이블 전달 - 지시하지 않은 JOIN 포함
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
HARMONY 데이터베이스 17개 테이블:
artists, members, albums, tracks, streaming, fans, orders, products,
daily_charts, concerts, fansign_events, fansign_participants,
fan_activities, photocard_trades, subscription_history, industry_benchmarks, sns_reactions

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: 2026년 7월 매출 TOP 5 상품을 조회해 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT p.product_name, a.artist_name, SUM(o.total_amount) AS `total_sales`
FROM products p
JOIN orders o ON p.product_id=o.product_id
JOIN artists a ON p.artist_id=a.artist_id
WHERE o.order_date>='2026-07-01' AND o.order_date<'2026-08-01'
GROUP BY p.product_name, a.artist_name
ORDER BY `total_sales` DESC
LIMIT 5;

-- ============================================================
-- 예제 2 · [14.1] 필요한 테이블만 선별 - 정확한 SQL
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
CREATE TABLE orders(
   order_id INT PRIMARY KEY,
   product_id INT,
   order_date DATE,
   total_amount INT
);

CREATE TABLE products(
   product_id INT PRIMARY KEY,
   product_name VARCHAR(200)
);

[연결 관계]
orders.product_id→products.product_id

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: 2026년 7월 매출 TOP 5 상품을 조회해 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT p.product_name, SUM(o.total_amount) AS `total_sales`
FROM orders o
JOIN products p ON o.product_id=p.product_id
WHERE o.order_date>='2026-07-01' AND o.order_date<'2026-08-01'
GROUP BY p.product_id, p.product_name
ORDER BY `total_sales` DESC
LIMIT 5;

-- ============================================================
-- 예제 3 · [14.2] SHOW CREATE TABLE로 albums 스키마 확인
-- ============================================================

SHOW CREATE TABLE albums;

-- ============================================================
-- 예제 4 · [14.2] CREATE TABLE albums 결과
-- ============================================================

-- ✕ 실행하지 마세요 — SHOW CREATE TABLE의 실행 결과 예시입니다
-- CREATE TABLE 'albums'(
--   'album_id' int NOT NULL COMMENT '앨범 ID',
--   'album_name' varchar(200) NOT NULL COMMENT '앨범명',
--   'artist_id' int DEFAULT NULL COMMENT '아티스트 ID',
--   'release_date' date DEFAULT NULL COMMENT '발매일',
--   'album_type' varchar(50) DEFAULT NULL COMMENT '앨범 유형(정규/미니/싱글)',
--   'total_tracks' int DEFAULT NULL COMMENT '총트랙수',
--   'price' int DEFAULT NULL COMMENT '가격',
--   PRIMARY KEY(`album_id`),
--   CONSTRAINT 'albums_ibfk_1' FOREIGN KEY(`artist_id`) REFERENCES 'artists'(`artist_id`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='앨범 정보-발매된 앨범의 기본 정보 및 가격';

-- ============================================================
-- 예제 5 · [14.2] SHOW CREATE TABLE로 artists·tracks·streaming 스키마 확인
-- ============================================================

SHOW CREATE TABLE artists;
SHOW CREATE TABLE tracks;
SHOW CREATE TABLE streaming;

-- ============================================================
-- 예제 6 · [14.2] 프롬프트용 스키마 정보
-- ============================================================

-- ▶ 실행해 보세요 — 이미 있는 테이블이라 "already exists" 에러가 납니다. 스키마를 참고용으로 다시 보여 준 것입니다
CREATE TABLE artists(
   artist_id INT PRIMARY KEY COMMENT '아티스트 ID',
   artist_name VARCHAR(100) COMMENT '아티스트명',
   artist_type VARCHAR(20) COMMENT '아티스트 유형(GROUP/SOLO)',
   debut_date DATE COMMENT '데뷔일'
) COMMENT='아티스트 기본 정보';

-- CREATE TABLE albums(
--    album_id INT PRIMARY KEY COMMENT '앨범 ID',
--    album_name VARCHAR(200) COMMENT '앨범명',
--    artist_id INT COMMENT '아티스트 ID',
--    release_date DATE COMMENT '발매일',
--    FOREIGN KEY(artist_id) REFERENCES artists(artist_id)
-- ) COMMENT='앨범 정보';

-- CREATE TABLE tracks(
--    track_id INT PRIMARY KEY COMMENT '트랙 ID',
--    track_name VARCHAR(200) COMMENT '트랙명',
--    album_id INT COMMENT '앨범 ID',
--    duration INT COMMENT '재생 시간(초)',
--    FOREIGN KEY(album_id) REFERENCES albums(album_id)
-- ) COMMENT='트랙(곡) 정보';

-- CREATE TABLE streaming(
--    stream_id INT PRIMARY KEY COMMENT '스트림 ID',
--    track_id INT COMMENT '트랙 ID',
--    stream_date DATE COMMENT '재생일',
--    stream_datetime DATETIME COMMENT '재생 일시',
--    play_count INT COMMENT '재생 횟수',
--    platform VARCHAR(50) COMMENT '플랫폼',
--    FOREIGN KEY(track_id) REFERENCES tracks(track_id)
-- ) COMMENT='스트리밍 로그';

-- ============================================================
-- 예제 7 · [14.3] 테이블 목록 조회 - INFORMATION_SCHEMA
-- ============================================================

SELECT TABLE_NAME, TABLE_COMMENT
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA='harmony_db'
 AND TABLE_TYPE='BASE TABLE'
ORDER BY TABLE_NAME;

-- ============================================================
-- 예제 8 · [14.3] SHOW CREATE TABLE - 2단계 전 실행
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[HARMONY 데이터베이스 테이블 목록]
1. artists - 아티스트 기본 정보
2. members - 아티스트 멤버 정보
3. albums - 앨범 정보
4. tracks - 트랙(곡) 정보
5. streaming - 스트리밍 로그
6. fans - 팬 정보
7. orders - 상품 주문 내역
8. products - 굿즈 상품 정보
9. daily_charts - 일간 차트 순위
10. concerts - 콘서트 정보
11. fansign_events - 팬사인회 이벤트
12. fansign_participants - 팬사인회 참가자
13. fan_activities - 팬 활동 로그
14. photocard_trades - 포토카드 거래
15. subscription_history - 구독 이력
16. industry_benchmarks - 업계 벤치마크
17. sns_reactions - SNS 반응

[분석 목표]
Celestial 그룹의 스트리밍 트렌드 분석
- 어떤 곡이 인기 있는지
- 일별 스트리밍 추이

[요청]
위 분석에 필요한 테이블만 선택하고, 테이블 간 연결 경로를 알려 주세요.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SHOW CREATE TABLE artists;
SHOW CREATE TABLE albums;
SHOW CREATE TABLE tracks;
SHOW CREATE TABLE streaming;

-- ============================================================
-- 예제 9 · [14.3] 곡별 스트리밍 순위 - 2단계 AI 응답
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
CREATE TABLE artists(
   artist_id INT PRIMARY KEY COMMENT '아티스트 ID',
   artist_name VARCHAR(100) COMMENT '아티스트명',
   artist_type VARCHAR(20) COMMENT '아티스트 유형(GROUP/SOLO)',
   debut_date DATE COMMENT '데뷔일'
) COMMENT='아티스트 기본 정보';

CREATE TABLE albums(
   album_id INT PRIMARY KEY COMMENT '앨범 ID',
   album_name VARCHAR(200) COMMENT '앨범명',
   artist_id INT COMMENT '아티스트 ID',
   release_date DATE COMMENT '발매일',
   FOREIGN KEY(artist_id) REFERENCES artists(artist_id)
) COMMENT='앨범 정보';

CREATE TABLE tracks(
   track_id INT PRIMARY KEY COMMENT '트랙 ID',
   track_name VARCHAR(200) COMMENT '트랙명',
   album_id INT COMMENT '앨범 ID',
   duration INT COMMENT '재생 시간(초)',
   FOREIGN KEY(album_id) REFERENCES albums(album_id)
) COMMENT='트랙(곡) 정보';

CREATE TABLE streaming(
   stream_id INT PRIMARY KEY COMMENT '스트림 ID',
   track_id INT COMMENT '트랙 ID',
   stream_date DATE COMMENT '재생일',
   stream_datetime DATETIME COMMENT '재생 일시',
   play_count INT COMMENT '재생 횟수',
   platform VARCHAR(50) COMMENT '플랫폼',
   FOREIGN KEY(track_id) REFERENCES tracks(track_id)
) COMMENT='스트리밍 로그';

[연결 경로]
artists→albums(artist_id)
albums→tracks(album_id)
tracks→streaming(track_id)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.:
Celestial 그룹의 곡별 총 스트리밍 횟수를 조회해 줘.
인기 순으로 정렬하고 상위 5곡만 보여 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT
  t.track_name AS `곡명`,
  a.album_name AS `앨범명`,
  SUM(s.play_count) AS `총 재생 횟수`
FROM artists ar
JOIN albums a ON ar.artist_id=a.artist_id
JOIN tracks t ON a.album_id=t.album_id
JOIN streaming s ON t.track_id=s.track_id
WHERE ar.artist_name='Celestial'
GROUP BY t.track_id, t.track_name, a.album_name
ORDER BY `총 재생 횟수` DESC
LIMIT 5;

-- ============================================================
-- 예제 10 · [14.3] 일별 스트리밍 추이 - 추가 분석 AI 응답
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[이전 결과]
Celestial 곡별 총 스트리밍 순위(상위 4곡):
1. Universe - 933회
2. Sky High - 371회
3. Midnight Fantasy - 95회
4. Starlight Dreams - 72회

[스키마 정보]
--- 2단계와 동일한 스키마를 그대로 붙여 넣습니다 ---

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.:
Celestial의 'Universe' 곡에 대해 2026년 7월의 일별 스트리밍 횟수를 조회해 줘.
날짜별로 정렬해서 추이를 볼 수 있게 해 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT
  s.stream_date AS `날짜`,
  SUM(s.play_count) AS `일별 재생 횟수`
FROM artists ar
JOIN albums a ON ar.artist_id=a.artist_id
JOIN tracks t ON a.album_id=t.album_id
JOIN streaming s ON t.track_id=s.track_id
WHERE ar.artist_name='Celestial'
  AND t.track_name='Universe'
  AND s.stream_date>='2026-07-01'
  AND s.stream_date<'2026-08-01'
GROUP BY s.stream_date
ORDER BY `날짜`;
