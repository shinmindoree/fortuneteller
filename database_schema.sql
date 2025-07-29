-- 사주플래너 Supabase 데이터베이스 스키마
-- 생성일: 2024-12-25

-- 1. 사용자 테이블 확장 (기본 auth.users 테이블에 추가 정보)
CREATE TABLE public.user_profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    display_name TEXT,
    birth_date DATE,
    birth_time TIME,
    gender TEXT CHECK (gender IN ('남성', '여성')),
    is_lunar_calendar BOOLEAN DEFAULT false,
    timezone TEXT DEFAULT 'Asia/Seoul',
    notification_enabled BOOLEAN DEFAULT true,
    fcm_token TEXT, -- Firebase Cloud Messaging 토큰
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 사주 분석 결과 테이블
CREATE TABLE public.saju_analyses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    birth_date DATE NOT NULL,
    birth_time TIME,
    gender TEXT NOT NULL,
    is_lunar_calendar BOOLEAN DEFAULT false,
    
    -- 사주 8자 데이터
    year_cheongan INTEGER NOT NULL, -- 천간 인덱스 (0-9)
    year_jiji INTEGER NOT NULL,     -- 지지 인덱스 (0-11)
    month_cheongan INTEGER NOT NULL,
    month_jiji INTEGER NOT NULL,
    day_cheongan INTEGER NOT NULL,
    day_jiji INTEGER NOT NULL,
    hour_cheongan INTEGER NOT NULL,
    hour_jiji INTEGER NOT NULL,
    
    -- AI 분석 결과
    personality TEXT,
    wealth_fortune TEXT,
    career_fortune TEXT,
    health_fortune TEXT,
    love_fortune TEXT,
    caution_period TEXT,
    summary TEXT,
    
    -- 메타데이터
    is_current BOOLEAN DEFAULT false, -- 현재 활성 분석
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 길일 추천 테이블
CREATE TABLE public.good_days (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    analysis_id UUID REFERENCES public.saju_analyses(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    date_value DATE NOT NULL,
    purpose TEXT NOT NULL,
    reason TEXT NOT NULL,
    event_type TEXT DEFAULT 'general',
    
    -- 알림 설정
    is_reminder_set BOOLEAN DEFAULT false,
    reminder_date TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 운세 기록 테이블
CREATE TABLE public.fortune_readings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- 운세 기본 정보
    fortune_type TEXT NOT NULL CHECK (fortune_type IN ('daily', 'weekly', 'monthly')),
    date_value DATE NOT NULL, -- 운세 날짜 (일일: 해당일, 주간: 월요일, 월간: 1일)
    title TEXT NOT NULL,
    summary TEXT NOT NULL,
    description TEXT NOT NULL,
    
    -- 운세 점수
    wealth_score INTEGER CHECK (wealth_score >= 0 AND wealth_score <= 100),
    health_score INTEGER CHECK (health_score >= 0 AND health_score <= 100),
    love_score INTEGER CHECK (love_score >= 0 AND love_score <= 100),
    career_score INTEGER CHECK (career_score >= 0 AND career_score <= 100),
    general_score INTEGER CHECK (general_score >= 0 AND general_score <= 100),
    
    -- 운세 상세 정보
    lucky_items TEXT[], -- 배열로 저장
    recommendations TEXT[],
    warnings TEXT[],
    
    -- 사용자 상호작용
    is_favorite BOOLEAN DEFAULT false,
    view_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 캘린더 이벤트 테이블
CREATE TABLE public.calendar_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    good_day_id UUID REFERENCES public.good_days(id) ON DELETE SET NULL,
    
    title TEXT NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    event_type TEXT DEFAULT 'general',
    
    -- 알림 설정
    is_reminder_set BOOLEAN DEFAULT false,
    reminder_date TIMESTAMP WITH TIME ZONE,
    
    -- 메타데이터
    is_synced_locally BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. 데이터 동기화 로그 테이블
CREATE TABLE public.sync_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('create', 'update', 'delete')),
    
    -- 동기화 상태
    sync_status TEXT DEFAULT 'pending' CHECK (sync_status IN ('pending', 'success', 'failed')),
    error_message TEXT,
    
    -- 충돌 해결
    conflict_resolution TEXT CHECK (conflict_resolution IN ('local_wins', 'remote_wins', 'merged')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- 인덱스 생성
CREATE INDEX idx_user_profiles_user_id ON public.user_profiles(id);
CREATE INDEX idx_saju_analyses_user_id ON public.saju_analyses(user_id);
CREATE INDEX idx_saju_analyses_current ON public.saju_analyses(user_id, is_current);
CREATE INDEX idx_good_days_user_id ON public.good_days(user_id);
CREATE INDEX idx_good_days_date ON public.good_days(date_value);
CREATE INDEX idx_fortune_readings_user_id ON public.fortune_readings(user_id);
CREATE INDEX idx_fortune_readings_type_date ON public.fortune_readings(user_id, fortune_type, date_value);
CREATE INDEX idx_calendar_events_user_id ON public.calendar_events(user_id);
CREATE INDEX idx_calendar_events_date ON public.calendar_events(event_date);
CREATE INDEX idx_sync_logs_user_id ON public.sync_logs(user_id);
CREATE INDEX idx_sync_logs_status ON public.sync_logs(sync_status);

-- RLS (Row Level Security) 정책 설정
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saju_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.good_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fortune_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_logs ENABLE ROW LEVEL SECURITY;

-- 사용자 프로필 정책
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 사주 분석 정책
CREATE POLICY "Users can manage own saju analyses" ON public.saju_analyses
    FOR ALL USING (auth.uid() = user_id);

-- 길일 정책
CREATE POLICY "Users can manage own good days" ON public.good_days
    FOR ALL USING (auth.uid() = user_id);

-- 운세 정책
CREATE POLICY "Users can manage own fortune readings" ON public.fortune_readings
    FOR ALL USING (auth.uid() = user_id);

-- 캘린더 이벤트 정책
CREATE POLICY "Users can manage own calendar events" ON public.calendar_events
    FOR ALL USING (auth.uid() = user_id);

-- 동기화 로그 정책
CREATE POLICY "Users can manage own sync logs" ON public.sync_logs
    FOR ALL USING (auth.uid() = user_id);

-- 트리거 함수: updated_at 자동 업데이트
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 트리거 적용
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_saju_analyses_updated_at BEFORE UPDATE ON public.saju_analyses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_good_days_updated_at BEFORE UPDATE ON public.good_days FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_fortune_readings_updated_at BEFORE UPDATE ON public.fortune_readings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_calendar_events_updated_at BEFORE UPDATE ON public.calendar_events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 샘플 데이터 삽입용 함수 (개발/테스트용)
CREATE OR REPLACE FUNCTION create_sample_data(sample_user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- 사용자 프로필 생성
    INSERT INTO public.user_profiles (id, display_name, birth_date, gender, is_lunar_calendar)
    VALUES (sample_user_id, '테스트 사용자', '1990-01-01', '남성', false)
    ON CONFLICT (id) DO NOTHING;
    
    -- 샘플 사주 분석 생성
    INSERT INTO public.saju_analyses (
        user_id, name, birth_date, gender, is_lunar_calendar,
        year_cheongan, year_jiji, month_cheongan, month_jiji,
        day_cheongan, day_jiji, hour_cheongan, hour_jiji,
        personality, summary, is_current
    ) VALUES (
        sample_user_id, '테스트 사용자', '1990-01-01', '남성', false,
        6, 5, 8, 11, 2, 3, 4, 7,
        '성실하고 책임감이 강한 성격입니다.', '전체적으로 안정된 운세를 보이고 있습니다.', true
    ) ON CONFLICT DO NOTHING;
END;
$$ language 'plpgsql';

-- 데이터베이스 초기화 완료
COMMENT ON SCHEMA public IS '사주플래너 메인 스키마';
COMMENT ON TABLE public.user_profiles IS '사용자 프로필 확장 정보';
COMMENT ON TABLE public.saju_analyses IS '사주 분석 결과 저장';
COMMENT ON TABLE public.good_days IS 'AI 추천 길일 데이터';
COMMENT ON TABLE public.fortune_readings IS '일일/주간/월간 운세 기록';
COMMENT ON TABLE public.calendar_events IS '캘린더 이벤트 및 일정';
COMMENT ON TABLE public.sync_logs IS '로컬-클라우드 동기화 로그'; 