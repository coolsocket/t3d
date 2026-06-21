"""Timestamp value object — UTC only.

Invariant INV-007: timezone must be UTC.
"""

from dataclasses import dataclass
from datetime import UTC, datetime


@dataclass(frozen=True)
class Timestamp:
    value: datetime

    def __post_init__(self) -> None:
        if self.value.tzinfo is None:
            raise ValueError("Timestamp must be timezone-aware (UTC)")
        offset = self.value.utcoffset()
        if offset is None or offset.total_seconds() != 0:
            raise ValueError(f"Timestamp must be UTC, got offset {offset}")

    @classmethod
    def from_iso(cls, iso_string: str) -> "Timestamp":
        dt = datetime.fromisoformat(iso_string)
        if dt.tzinfo is None:
            # naive ISO strings are treated as UTC for ergonomics
            dt = dt.replace(tzinfo=UTC)
        return cls(dt.astimezone(UTC))

    @classmethod
    def now(cls) -> "Timestamp":
        return cls(datetime.now(UTC))
