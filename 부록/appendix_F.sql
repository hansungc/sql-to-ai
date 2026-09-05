-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- 부록 F  인덱스 - JOIN을 빠르게 만드는 비밀
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
--   -- ※                   실습 안내 주석입니다. 입력하지도, 실행하지도 않습니다
-- ============================================

-- ※ streaming.fan_id에는 외래 키(FOREIGN KEY ... REFERENCES fans)가 걸려 있습니다.
--    MySQL은 외래 키를 만들 때 인덱스(이름: fan_id)를 함께 만들어 주므로(149쪽 본문 참고),
--    F.2로 인덱스를 만들기 '전'에도 streaming은 이미 인덱스를 타고 있습니다.
--    그래서 F.1과 F.3의 실행 계획이 거의 같게 보이는 것이 정상입니다.
--    (결과의 type=ALL 행은 streaming이 아니라 먼저 읽는 fans 테이블입니다.)
--    '인덱스가 없을 때 풀스캔이 난다'를 눈으로 확인하려면 마지막 예제 5를 실행하세요.

-- ============================================================
-- 예제 1 · [F.1] 인덱스 사용 여부 확인
-- ============================================================

EXPLAIN
SELECT f.fan_name, s.stream_id
FROM fans f
INNER JOIN streaming s ON f.fan_id=s.fan_id;

-- ============================================================
-- 예제 2 · [F.2] streaming 테이블에 인덱스 생성
-- ============================================================

-- ※ 두 번 실행하면 "Duplicate key name" 오류가 납니다. 다시 실행하려면 먼저 지우세요.
--    DROP INDEX idx_streaming_fan_id ON streaming;
--    (외래 키가 쓰는 자동 인덱스 fan_id는 지울 수 없습니다 - 정상입니다.)
CREATE INDEX idx_streaming_fan_id ON streaming(fan_id);

-- ============================================================
-- 예제 3 · [F.3] 인덱스 추가 후 실행 계획 재확인
-- ============================================================

EXPLAIN
SELECT f.fan_name, s.stream_id
FROM fans f
INNER JOIN streaming s ON f.fan_id=s.fan_id;

-- ============================================================
-- 예제 4 · [F.4] orders 테이블에 인덱스 생성
-- ============================================================

-- ▶ 실행해 보세요 — 데이터셋에 이미 있는 인덱스라 "Duplicate key name" 에러가 납니다
CREATE INDEX idx_orders_fan_id ON orders(fan_id);

-- ============================================================
-- 예제 5 · [F.2 보충] 인덱스 전/후 실행 계획 직접 비교
-- ============================================================

-- ▶ 실행해 보세요 — 교재에 없는 보충 예제입니다.
--   외래 키가 없는 복사본을 만들어 'type=ALL → type=ref' 변화를 직접 확인합니다.
DROP TABLE IF EXISTS streaming_noidx;
CREATE TABLE streaming_noidx AS SELECT * FROM streaming;

-- ① 인덱스 없음 → type=ALL, key=NULL, rows=375
EXPLAIN
SELECT * FROM streaming_noidx WHERE fan_id=1;

CREATE INDEX idx_noidx_fan_id ON streaming_noidx(fan_id);

-- ② 인덱스 있음 → type=ref, key=idx_noidx_fan_id, rows가 크게 줄어듦
EXPLAIN
SELECT * FROM streaming_noidx WHERE fan_id=1;

-- 확인이 끝나면 정리합니다.
DROP TABLE streaming_noidx;
