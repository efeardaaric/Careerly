from contextlib import contextmanager

from sqlalchemy.dialects.postgresql import insert as postgres_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.orm import Session

from app.db.session import get_session_factory, init_db


@contextmanager
def billing_session(session: Session | None = None):
    if session is not None:
        yield session
        return
    init_db()
    with get_session_factory().begin() as owned_session:
        yield owned_session


def insert_for(session: Session, model):
    if session.get_bind().dialect.name == "postgresql":
        return postgres_insert(model)
    return sqlite_insert(model)
