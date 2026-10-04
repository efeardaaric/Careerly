"""Initial Careerly CV tables."""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0001_cv_pipeline"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("external_auth_id", sa.String(128), unique=True),
        sa.Column("email", sa.String(320)),
        sa.Column("first_name", sa.String(120)),
        sa.Column("display_name", sa.String(160)),
        sa.Column("career_stage", sa.String(40)),
        sa.Column("opportunity_type", sa.String(40)),
        sa.Column("target_fields", sa.JSON),
        sa.Column("cv_languages", sa.JSON),
        sa.Column("created_at", sa.DateTime(timezone=True)),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "cv_documents",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(128), index=True),
        sa.Column("original_file_name", sa.String(260), nullable=False),
        sa.Column("display_name", sa.String(260), nullable=False),
        sa.Column("mime_type", sa.String(120), nullable=False),
        sa.Column("file_size", sa.Integer, nullable=False),
        sa.Column("detected_language", sa.String(16), nullable=False),
        sa.Column("parse_status", sa.String(32), nullable=False),
        sa.Column("parser_confidence", sa.Float, nullable=False),
        sa.Column("parser_version", sa.String(32), nullable=False),
        sa.Column("structured_data", sa.JSON, nullable=False),
        sa.Column("latest_analysis_id", sa.String(36)),
        sa.Column("created_at", sa.DateTime(timezone=True)),
        sa.Column("updated_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "cv_analyses",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("cv_id", sa.String(36), sa.ForeignKey("cv_documents.id"), index=True),
        sa.Column("overall_score", sa.Integer, nullable=False),
        sa.Column("ats_score", sa.Integer, nullable=False),
        sa.Column("content_impact_score", sa.Integer, nullable=False),
        sa.Column("experience_score", sa.Integer, nullable=False),
        sa.Column("skills_score", sa.Integer, nullable=False),
        sa.Column("structure_score", sa.Integer, nullable=False),
        sa.Column("language_score", sa.Integer, nullable=False),
        sa.Column("basics_score", sa.Integer, nullable=False),
        sa.Column("parser_confidence", sa.Float, nullable=False),
        sa.Column("engine_version", sa.String(32), nullable=False),
        sa.Column("summary", sa.Text),
        sa.Column("payload", sa.JSON, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True)),
    )
    op.create_table(
        "cv_analysis_categories",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("analysis_id", sa.String(36), sa.ForeignKey("cv_analyses.id"), index=True),
        sa.Column("key", sa.String(64), nullable=False),
        sa.Column("title", sa.String(120), nullable=False),
        sa.Column("score", sa.Integer, nullable=False),
        sa.Column("weight", sa.Float, nullable=False),
        sa.Column("earned_points", sa.Float, nullable=False),
        sa.Column("possible_points", sa.Float, nullable=False),
        sa.Column("summary", sa.Text, nullable=False),
    )
    op.create_table(
        "analysis_findings",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("analysis_id", sa.String(36), sa.ForeignKey("cv_analyses.id"), index=True),
        sa.Column("category", sa.String(64), nullable=False),
        sa.Column("severity", sa.String(32), nullable=False),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("description", sa.Text, nullable=False),
        sa.Column("evidence", sa.Text, nullable=False),
        sa.Column("recommendation", sa.Text, nullable=False),
        sa.Column("source_section", sa.String(64)),
        sa.Column("can_auto_fix", sa.Integer, nullable=False),
        sa.Column("extra", sa.JSON),
    )


def downgrade() -> None:
    op.drop_table("analysis_findings")
    op.drop_table("cv_analysis_categories")
    op.drop_table("cv_analyses")
    op.drop_table("cv_documents")
    op.drop_table("users")
