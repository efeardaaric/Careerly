"""Persist subscriptions and metered usage."""

import sqlalchemy as sa
from alembic import op

revision = "0002_billing_persistence"
down_revision = "0001_cv_pipeline"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "usage_counters",
        sa.Column("user_id", sa.String(128), primary_key=True),
        sa.Column("feature_id", sa.String(64), primary_key=True),
        sa.Column("period", sa.String(32), primary_key=True),
        sa.Column("count", sa.Integer, nullable=False),
    )
    op.create_table(
        "usage_requests",
        sa.Column("user_id", sa.String(128), primary_key=True),
        sa.Column("request_id", sa.String(200), primary_key=True),
        sa.Column("feature_id", sa.String(64), nullable=False),
        sa.Column("period", sa.String(32), nullable=False),
    )
    op.create_table(
        "user_subscriptions",
        sa.Column("user_id", sa.String(128), primary_key=True),
        sa.Column("tier", sa.String(32), nullable=False),
        sa.Column("status", sa.String(32), nullable=False),
        sa.Column("product_id", sa.String(120)),
        sa.Column("expires_at", sa.String(64)),
    )


def downgrade() -> None:
    op.drop_table("user_subscriptions")
    op.drop_table("usage_requests")
    op.drop_table("usage_counters")
