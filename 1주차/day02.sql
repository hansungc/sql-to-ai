-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 2  슈퍼팬 타깃 마케팅 대상 추출 - WHERE
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
-- 예제 1 · [2.1] WHERE 기본: 등호(=)로 특정 값 찾기
-- ============================================================

SELECT stream_id, fan_id, track_id, platform, stream_date
FROM streaming
WHERE platform='Melon'
LIMIT 3;

-- ============================================================
-- 예제 2 · [2.1] 부등호(>)로 특정 값보다 큰 데이터 찾기
-- ============================================================

SELECT stream_id, fan_id, track_id, play_count, platform
FROM streaming
WHERE play_count > 15
LIMIT 3;

-- ============================================================
-- 예제 3 · [2.1] 같지 않음(!=)으로 특정 값 제외하기
-- ============================================================

SELECT stream_id, fan_id, platform, play_count
FROM streaming
WHERE platform != 'Spotify'
LIMIT 3;

-- ============================================================
-- 예제 4 · [2.1] AND와 OR로 복잡한 조건 묶기
-- ============================================================

SELECT fan_id, fan_name, membership_level, country
FROM fans
WHERE (membership_level='VIP' AND country='대한민국')
  OR (membership_level='일반' AND country != '대한민국')
LIMIT 3;

-- ============================================================
-- 예제 5 · [2.2] OR을 반복해서 써야 하는 불편함
-- ============================================================

SELECT product_id, product_name, artist_id
FROM products
WHERE artist_id=1
  OR artist_id=2
  OR artist_id=3
  OR artist_id=6
  OR artist_id=7
LIMIT 3;

-- ============================================================
-- 예제 6 · [2.2] 범위를 표현하는 게 번거로움
-- ============================================================

SELECT product_id, product_name, price
FROM products
WHERE price >= 20000 AND price <= 50000
LIMIT 3;

-- ============================================================
-- 예제 7 · [2.2] 부분 일치를 검색할 수 없는 한계
-- ============================================================

SELECT track_id, track_name
FROM tracks
WHERE track_name='Night'
LIMIT 3;

-- ============================================================
-- 예제 8 · [2.2] IN으로 여러 값을 한 번에 (문자열)
-- ============================================================

SELECT artist_id, artist_name, member_count
FROM artists
WHERE artist_name IN('StarLight', 'Luna Eclipse', 'Phoenix')
LIMIT 3;

-- ============================================================
-- 예제 9 · [2.2] IN으로 여러 값을 한 번에 (숫자)
-- ============================================================

SELECT stream_id, fan_id, track_id, platform
FROM streaming
WHERE track_id IN(1, 7, 22)
LIMIT 3;

-- ============================================================
-- 예제 10 · [2.2] BETWEEN으로 범위를 간단하게
-- ============================================================

SELECT product_id, product_name, price
FROM products
WHERE price BETWEEN 20000 AND 50000
LIMIT 3;

-- ============================================================
-- 예제 11 · [2.2] BETWEEN으로 날짜 범위로 검색하기
-- ============================================================

SELECT order_id, fan_id, order_date, total_amount
FROM orders
WHERE order_date BETWEEN '2025-07-15' AND '2025-07-22'
LIMIT 3;

-- ============================================================
-- 예제 12 · [2.2] LIKE와 와일드카드로 부분 일치 검색
-- ============================================================

SELECT artist_id, artist_name, artist_type
FROM artists
WHERE artist_name LIKE '%Star%';

-- ============================================================
-- 예제 13 · [2.2] IS NULL로 빈 값 찾기
-- ============================================================

SELECT fan_id, fan_name, email
FROM fans
WHERE email IS NULL
LIMIT 3;

-- ============================================================
-- 예제 14 · [2.2] IS NOT NULL로 빈 값 제외하기
-- ============================================================

SELECT fan_id, fan_name, email, country
FROM fans
WHERE email IS NOT NULL
  AND country='대한민국'
LIMIT 3;

-- ============================================================
-- 예제 15 · [2.2] 여러 조건으로 대상자 추출하기
-- ============================================================

SELECT fan_id, fan_name, membership_level, join_date, email
FROM fans
WHERE membership_level IN('VIP', '프리미엄')
  AND join_date BETWEEN '2024-01-01' AND '2026-07-22'
  AND email IS NOT NULL
LIMIT 3;

-- ============================================================
-- 예제 16 · [2.3] 5개 채널 이상 활동자 정보 가져오기 - IN 활용
-- ============================================================

SELECT fan_id, fan_name, membership_level, country
FROM fans
WHERE fan_id IN(1, 4, 7, 8, 11, 13);

-- ============================================================
-- 예제 17 · [2.3] 등급+가입일 조건 추가 - IN과 BETWEEN 조합
-- ============================================================

SELECT fan_id, fan_name, membership_level, join_date
FROM fans
WHERE fan_id IN(1, 4, 7, 8, 11, 13)
  AND membership_level IN('VIP', '프리미엄')
  AND join_date BETWEEN '2024-01-01' AND '2026-07-22';

-- ============================================================
-- 예제 18 · [2.3] 이메일 등록+국내 거주 조건 추가 - IS NOT NULL 활용
-- ============================================================

SELECT fan_id, fan_name, email, membership_level
FROM fans
WHERE fan_id IN(1, 4, 7, 8, 11, 13)
  AND membership_level IN('VIP', '프리미엄')
  AND join_date BETWEEN '2024-01-01' AND '2026-07-22'
  AND email IS NOT NULL
  AND country='대한민국';

-- ============================================================
-- 예제 19 · [2.3] 최종 슈퍼팬 리스트 추출
-- ============================================================

-- 슈퍼팬 타깃 리스트 추출 조건
-- 1. 채널 활동: 5개 이상 플랫폼에서 활동(선배가 미리 파악한 fan_id: 1, 4, 7, 8, 11, 13번)
-- 2. 멤버십 등급: VIP 또는 프리미엄
-- 3. 가입 시기: 2024년 1월 이후 가입
-- 4. 이메일: 등록 완료
-- 5. 거주 지역: 국내

SELECT
  fan_id AS `팬 ID`,
  fan_name AS `이름`,
  email AS `이메일`,
  membership_level AS `멤버십`,
  join_date AS `가입일`,
  country AS `국가`
FROM fans
WHERE fan_id IN(1, 4, 7, 8, 11, 13)
  AND membership_level IN('VIP', '프리미엄')
  AND join_date BETWEEN '2024-01-01' AND '2026-07-22'
  AND email IS NOT NULL
  AND country='대한민국';

-- ============================================================
-- 예제 20 · [OR 논리 연산자 단순 예제]
-- ============================================================

SELECT stream_id, fan_id, platform, play_count
FROM streaming
WHERE platform='Melon' OR platform='Genie'
LIMIT 3;

-- ============================================================
-- 예제 21 · [AND 논리 연산자 단순 예제]
-- ============================================================

SELECT stream_id, fan_id, play_count, platform
FROM streaming
WHERE platform='Melon' AND play_count >10
LIMIT 3;
