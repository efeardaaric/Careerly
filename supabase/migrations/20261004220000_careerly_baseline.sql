BEGIN;

CREATE TABLE alembic_version (
    version_num VARCHAR(32) NOT NULL,
    CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num)
);


CREATE TABLE users (
    id VARCHAR(36) NOT NULL,
    external_auth_id VARCHAR(128),
    email VARCHAR(320),
    first_name VARCHAR(120),
    display_name VARCHAR(160),
    career_stage VARCHAR(40),
    opportunity_type VARCHAR(40),
    target_fields JSON,
    cv_languages JSON,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (id),
    UNIQUE (external_auth_id)
);

CREATE TABLE cv_documents (
    id VARCHAR(36) NOT NULL,
    user_id VARCHAR(128),
    original_file_name VARCHAR(260) NOT NULL,
    display_name VARCHAR(260) NOT NULL,
    mime_type VARCHAR(120) NOT NULL,
    file_size INTEGER NOT NULL,
    detected_language VARCHAR(16) NOT NULL,
    parse_status VARCHAR(32) NOT NULL,
    parser_confidence FLOAT NOT NULL,
    parser_version VARCHAR(32) NOT NULL,
    structured_data JSON NOT NULL,
    latest_analysis_id VARCHAR(36),
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (id)
);

CREATE INDEX ix_cv_documents_user_id ON cv_documents (user_id);

CREATE TABLE cv_analyses (
    id VARCHAR(36) NOT NULL,
    cv_id VARCHAR(36),
    overall_score INTEGER NOT NULL,
    ats_score INTEGER NOT NULL,
    content_impact_score INTEGER NOT NULL,
    experience_score INTEGER NOT NULL,
    skills_score INTEGER NOT NULL,
    structure_score INTEGER NOT NULL,
    language_score INTEGER NOT NULL,
    basics_score INTEGER NOT NULL,
    parser_confidence FLOAT NOT NULL,
    engine_version VARCHAR(32) NOT NULL,
    summary TEXT,
    payload JSON NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (id),
    FOREIGN KEY(cv_id) REFERENCES cv_documents (id)
);

CREATE INDEX ix_cv_analyses_cv_id ON cv_analyses (cv_id);

CREATE TABLE cv_analysis_categories (
    id VARCHAR(36) NOT NULL,
    analysis_id VARCHAR(36),
    key VARCHAR(64) NOT NULL,
    title VARCHAR(120) NOT NULL,
    score INTEGER NOT NULL,
    weight FLOAT NOT NULL,
    earned_points FLOAT NOT NULL,
    possible_points FLOAT NOT NULL,
    summary TEXT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY(analysis_id) REFERENCES cv_analyses (id)
);

CREATE INDEX ix_cv_analysis_categories_analysis_id ON cv_analysis_categories (analysis_id);

CREATE TABLE analysis_findings (
    id VARCHAR(36) NOT NULL,
    analysis_id VARCHAR(36),
    category VARCHAR(64) NOT NULL,
    severity VARCHAR(32) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    evidence TEXT NOT NULL,
    recommendation TEXT NOT NULL,
    source_section VARCHAR(64),
    can_auto_fix INTEGER NOT NULL,
    extra JSON,
    PRIMARY KEY (id),
    FOREIGN KEY(analysis_id) REFERENCES cv_analyses (id)
);

CREATE INDEX ix_analysis_findings_analysis_id ON analysis_findings (analysis_id);

INSERT INTO alembic_version (version_num) VALUES ('0001_cv_pipeline') RETURNING alembic_version.version_num;


CREATE TABLE usage_counters (
    user_id VARCHAR(128) NOT NULL,
    feature_id VARCHAR(64) NOT NULL,
    period VARCHAR(32) NOT NULL,
    count INTEGER NOT NULL,
    PRIMARY KEY (user_id, feature_id, period)
);

CREATE TABLE usage_requests (
    user_id VARCHAR(128) NOT NULL,
    request_id VARCHAR(200) NOT NULL,
    feature_id VARCHAR(64) NOT NULL,
    period VARCHAR(32) NOT NULL,
    PRIMARY KEY (user_id, request_id)
);

CREATE TABLE user_subscriptions (
    user_id VARCHAR(128) NOT NULL,
    tier VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL,
    product_id VARCHAR(120),
    expires_at VARCHAR(64),
    PRIMARY KEY (user_id)
);

UPDATE alembic_version SET version_num='0002_billing_persistence' WHERE alembic_version.version_num = '0001_cv_pipeline';

ALTER TABLE public.alembic_version ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.alembic_version FROM anon, authenticated;

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.users FROM anon, authenticated;

ALTER TABLE public.cv_documents ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.cv_documents FROM anon, authenticated;

ALTER TABLE public.cv_analyses ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.cv_analyses FROM anon, authenticated;

ALTER TABLE public.cv_analysis_categories ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.cv_analysis_categories FROM anon, authenticated;

ALTER TABLE public.analysis_findings ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.analysis_findings FROM anon, authenticated;

ALTER TABLE public.usage_counters ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.usage_counters FROM anon, authenticated;

ALTER TABLE public.usage_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.usage_requests FROM anon, authenticated;

ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.user_subscriptions FROM anon, authenticated;

COMMIT;
