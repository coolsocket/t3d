"""TDD tests for Timestamp value object."""

from datetime import datetime, timedelta, timezone

import pytest

from contexts._shared_kernel.timestamp import Timestamp


def test_timestamp_is_utc() -> None:
    """INV-007: Timestamp must be UTC."""
    naive = datetime(2026, 1, 1, 12, 0, 0)
    with pytest.raises(ValueError, match="timezone-aware"):
        Timestamp(naive)

    nyc = timezone(timedelta(hours=-5))
    with pytest.raises(ValueError, match="UTC"):
        Timestamp(datetime(2026, 1, 1, 12, 0, 0, tzinfo=nyc))


def test_from_iso_with_offset() -> None:
    ts = Timestamp.from_iso("2026-01-01T12:00:00+00:00")
    assert ts.value.year == 2026
    offset = ts.value.utcoffset()
    assert offset is not None and offset.total_seconds() == 0


def test_from_iso_naive_treated_as_utc() -> None:
    ts = Timestamp.from_iso("2026-01-01T12:00:00")
    offset = ts.value.utcoffset()
    assert offset is not None and offset.total_seconds() == 0


def test_now_returns_utc() -> None:
    ts = Timestamp.now()
    offset = ts.value.utcoffset()
    assert offset is not None and offset.total_seconds() == 0


def test_timestamp_equality_by_value() -> None:
    a = Timestamp.from_iso("2026-01-01T12:00:00+00:00")
    b = Timestamp.from_iso("2026-01-01T12:00:00+00:00")
    assert a == b
