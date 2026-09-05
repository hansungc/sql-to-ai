-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 16  "팀장님이 던진 숙제, 어디서부터 시작하지?" - 요구사항 및 문제 정의
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
--   -- ※                   실습 안내 주석입니다. 입력하지도, 실행하지도 않습니다
-- ============================================

-- ============================================================
-- 예제 1 · [16.1] 분석 질문 도출 요청
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[역할]
K-POP 엔터테인먼트 회사의 데이터 분석가

[상황]
팀장님께 "아티스트 콘서트 D-7 성과"를 보고해야 함.
분석 기간: 최근 한 달(7월)

[요청]
다음 관점에서 분석해야 할 핵심 질문들을 제안해 줘.:
- 스트리밍 성과
- 팬 활동
- 굿즈 매출 현황
*/

-- ============================================================
-- 예제 2 · [16.2] 질문 난이도 판단 요청
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[난이도 판단 요청]
다음 분석 질문들의 난이도를 단순/보통/복잡 중 하나로 분류해 줘.
각 질문에 대해 난이도, 예상 사용 구문, 판단 이유를 함께 알려 줘.
하나의 질문에 여러 난이도의 구문이 섞이면, 가장 높은 난이도를 적용해 줘.

[분류 기준]
- 단순(논리 단계 1):
  . 단일 테이블 조회
  . 필터 조건(WHERE) 1~2개
  . 단일 집계 함수(COUNT, SUM, AVG, MAX, MIN)
  . 정렬 및 행 제한(ORDER BY, LIMIT)
  . DISTINCT를 활용한 중복 제거
- 보통(논리 단계 2):
  . 2~3개 테이블 JOIN(INNER JOIN, LEFT JOIN)
  . GROUP BY+집계 함수 조합
  . HAVING 절을 통한 집계 후 필터링
  . CASE WHEN을 활용한 조건부 분류
  . 날짜 함수를 활용한 기간 필터링(DATE_FORMAT, BETWEEN, EXTRACT)
  . 집합 연산(UNION, UNION ALL, EXCEPT)
  . 단순 서브쿼리(WHERE IN(SELECT ...))
- 복잡(논리 단계 3 이상):
  . 상관 서브쿼리(EXISTS, 외부 참조)
  . 인라인 뷰(FROM 절 서브쿼리)
  . 윈도우 함수(ROW_NUMBER, RANK, LAG, SUM OVER)
  . CTE(WITH 절)를 활용한 다단계 처리
*/

-- ============================================================
-- 예제 3 · [16.3 Q1] Q1. Phoenix 7월 총 스트리밍 수
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
CREATE TABLE albums(
   album_id INT PRIMARY KEY,
   album_name VARCHAR(200),
   artist_id INT
);

CREATE TABLE tracks(
   track_id INT PRIMARY KEY,
   track_name VARCHAR(200),
   album_id INT,
   FOREIGN KEY(album_id) REFERENCES albums(album_id)
);

CREATE TABLE streaming(
   stream_id INT PRIMARY KEY,
   track_id INT,
   stream_date DATE,
   play_count INT,
   platform VARCHAR(50),
   FOREIGN KEY(track_id) REFERENCES tracks(track_id)
);

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: Phoenix(artist_id=3)의 7월 총 스트리밍 수 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT SUM(s.play_count) AS `total_streams`
FROM streaming s
JOIN tracks t ON s.track_id=t.track_id
JOIN albums a ON t.album_id=a.album_id
WHERE a.artist_id=3
  AND s.stream_date BETWEEN '2026-07-01' AND '2026-07-31';

-- ============================================================
-- 예제 4 · [16.3 Q2] Q2. Phoenix 7월 플랫폼별 스트리밍 비중
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
(Q1과 동일)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: Phoenix(artist_id=3)의 7월 플랫폼별 스트리밍 수
- 플랫폼명, 재생 수 출력
- 재생 수 내림차순 정렬
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT s.platform,
    SUM(s.play_count) AS `total_plays`
FROM streaming s
JOIN tracks t ON s.track_id=t.track_id
JOIN albums a ON t.album_id=a.album_id
WHERE a.artist_id=3
  AND s.stream_date BETWEEN '2026-07-01' AND '2026-07-31'
GROUP BY s.platform
ORDER BY `total_plays` DESC;

-- ============================================================
-- 예제 5 · [16.3 Q3] Q3. Phoenix 7월 곡별 스트리밍 TOP 3
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
(Q1과 동일)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: Phoenix(artist_id=3)의 7월 곡별 스트리밍 TOP 3
- `곡명`, 재생 수 출력
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT t.track_name,
    SUM(s.play_count) AS `total_plays`
FROM streaming s
JOIN tracks t ON s.track_id=t.track_id
JOIN albums a ON t.album_id=a.album_id
WHERE a.artist_id=3
  AND s.stream_date BETWEEN '2026-07-01' AND '2026-07-31'
GROUP BY t.track_id, t.track_name
ORDER BY `total_plays` DESC
LIMIT 3;

-- ============================================================
-- 예제 6 · [16.3 Q4(첫번째시도)] Q4. 핵심 팬 찾기 (첫 번째 시도)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
CREATE TABLE albums(
   album_id INT PRIMARY KEY,
   artist_id INT
);

CREATE TABLE tracks(
   track_id INT PRIMARY KEY,
   track_name VARCHAR(200),
   album_id INT,
   FOREIGN KEY(album_id) REFERENCES albums(album_id)
);

CREATE TABLE fans(
   fan_id INT PRIMARY KEY,
   fan_name VARCHAR(100)
);

CREATE TABLE streaming(
   stream_id INT PRIMARY KEY,
   fan_id INT,
   track_id INT,
   play_count INT,
   stream_date DATE,
   FOREIGN KEY(fan_id) REFERENCES fans(fan_id),
   FOREIGN KEY(track_id) REFERENCES tracks(track_id)
);

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.:
Phoenix(artist_id=3) 곡 중 평균 스트리밍 이상인 곡을 재생한 팬 목록,
기간: 2026년 7월
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT DISTINCT f.fan_id, f.fan_name
FROM fans f
JOIN streaming s ON f.fan_id=s.fan_id
JOIN tracks t ON s.track_id=t.track_id
JOIN albums a ON t.album_id=a.album_id
WHERE a.artist_id=3
  AND s.stream_date BETWEEN '2026-07-01' AND '2026-07-31'
  AND t.track_id IN(
    SELECT track_id
    FROM(
      SELECT t2.track_id, SUM(s2.play_count) AS `track_total`
      FROM streaming s2
      JOIN tracks t2 ON s2.track_id=t2.track_id
      JOIN albums a2 ON t2.album_id=a2.album_id
      WHERE a2.artist_id=3
        AND s2.stream_date BETWEEN '2026-07-01' AND '2026-07-31'
      GROUP BY t2.track_id
    ) track_stats
    WHERE track_total >= (
      SELECT AVG(track_total)
      FROM(
        SELECT SUM(s3.play_count) AS `track_total`
        FROM streaming s3
        JOIN tracks t3 ON s3.track_id=t3.track_id
        JOIN albums a3 ON t3.album_id=a3.album_id
        WHERE a3.artist_id=3
          AND s3.stream_date BETWEEN '2026-07-01' AND '2026-07-31'
        GROUP BY t3.track_id
      ) avg_calc
    )
  );

-- ============================================================
-- 예제 7 · [16.3 Q4-1단계] Q4. 1단계: 곡별 총 재생 수
-- ============================================================

-- ※ 결과는 곡명과 재생 수(Rising 130 · Phoenix Fire 120)로 대조하세요.
--    track_id 번호 자체는 데이터셋 판번에 따라 달라집니다(현재 데이터셋에서는 34 · 40).

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
CREATE TABLE albums(
   album_id INT PRIMARY KEY,
   artist_id INT
);

CREATE TABLE tracks(
   track_id INT PRIMARY KEY,
   track_name VARCHAR(200),
   album_id INT,
   FOREIGN KEY(album_id) REFERENCES albums(album_id)
);

CREATE TABLE fans(
   fan_id INT PRIMARY KEY,
   fan_name VARCHAR(100)
);

CREATE TABLE streaming(
   stream_id INT PRIMARY KEY,
   fan_id INT,
   track_id INT,
   play_count INT,
   stream_date DATE,
   FOREIGN KEY(fan_id) REFERENCES fans(fan_id),
   FOREIGN KEY(track_id) REFERENCES tracks(track_id)
);

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.:
Phoenix(artist_id=3) 곡 중 평균 스트리밍 이상인 곡을 재생한 팬 목록,
기간: 2026년 7월

[단계별 접근]
1단계: Phoenix 곡별 총 스트리밍 수 계산
2단계: Phoenix 곡들의 평균 스트리밍 수 계산
3단계: 평균 이상인 곡 식별
4단계: 해당 곡을 재생한 팬 추출
각 단계별 중간 결과를 확인할 수 있는 개별 쿼리와
최종 통합 쿼리를 모두 작성해 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT t.track_id, t.track_name, SUM(s.play_count) AS `track_total`
FROM streaming s
JOIN tracks t ON s.track_id=t.track_id
JOIN albums a ON t.album_id=a.album_id
WHERE a.artist_id=3
  AND s.stream_date BETWEEN '2026-07-01' AND '2026-07-31'
GROUP BY t.track_id, t.track_name;

-- ============================================================
-- 예제 8 · [16.3 Q4-2단계] Q4. 2단계: 곡별 총 재생 수의 평균
-- ============================================================

SELECT AVG(`track_total`) AS `avg_track_streams`
FROM(
  SELECT SUM(s.play_count) AS `track_total`
  FROM streaming s
  JOIN tracks t ON s.track_id=t.track_id
  JOIN albums a ON t.album_id=a.album_id
  WHERE a.artist_id=3
    AND s.stream_date BETWEEN '2026-07-01' AND '2026-07-31'
  GROUP BY t.track_id
) track_stats;

-- ============================================================
-- 예제 9 · [16.3 Q4-3단계] Q4. 3단계: 평균 이상인 곡 식별
-- ============================================================

SELECT track_id, track_name, `track_total`
FROM(
  SELECT t.track_id, t.track_name, SUM(s.play_count) AS `track_total`
  FROM streaming s
  JOIN tracks t ON s.track_id=t.track_id
  JOIN albums a ON t.album_id=a.album_id
  WHERE a.artist_id=3
    AND s.stream_date BETWEEN '2026-07-01' AND '2026-07-31'
  GROUP BY t.track_id, t.track_name
) track_stats
WHERE `track_total` >= (
  SELECT AVG(`track_total`)
  FROM(
    SELECT SUM(s2.play_count) AS `track_total`
    FROM streaming s2
    JOIN tracks t2 ON s2.track_id=t2.track_id
    JOIN albums a2 ON t2.album_id=a2.album_id
    WHERE a2.artist_id=3
      AND s2.stream_date BETWEEN '2026-07-01' AND '2026-07-31'
    GROUP BY t2.track_id
  ) avg_calc
);

-- ============================================================
-- 예제 10 · [16.3 Q4-4단계] Q4. 4단계: 평균 이상 곡을 재생한 팬 (최종)
-- ============================================================

SELECT DISTINCT f.fan_id, f.fan_name
FROM fans f
JOIN streaming s ON f.fan_id=s.fan_id
JOIN tracks t ON s.track_id=t.track_id
JOIN albums a ON t.album_id=a.album_id
WHERE a.artist_id=3
  AND s.stream_date BETWEEN '2026-07-01' AND '2026-07-31'
  AND t.track_id IN(
    SELECT track_id
    FROM(
      SELECT t2.track_id, SUM(s2.play_count) AS `track_total`
      FROM streaming s2
      JOIN tracks t2 ON s2.track_id=t2.track_id
      JOIN albums a2 ON t2.album_id=a2.album_id
      WHERE a2.artist_id=3
        AND s2.stream_date BETWEEN '2026-07-01' AND '2026-07-31'
      GROUP BY t2.track_id
    ) track_stats
    WHERE `track_total` >= (
      SELECT AVG(`track_total`)
      FROM(
        SELECT SUM(s3.play_count) AS `track_total`
        FROM streaming s3
        JOIN tracks t3 ON s3.track_id=t3.track_id
        JOIN albums a3 ON t3.album_id=a3.album_id
        WHERE a3.artist_id=3
          AND s3.stream_date BETWEEN '2026-07-01' AND '2026-07-31'
        GROUP BY t3.track_id
      ) avg_calc
    )
  );
