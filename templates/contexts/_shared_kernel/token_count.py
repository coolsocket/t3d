"""TokenCount value object.

Invariant INV-005: value must be non-negative.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class TokenCount:
    value: int

    def __post_init__(self) -> None:
        if self.value < 0:
            raise ValueError(f"TokenCount must be non-negative, got {self.value}")

    def __add__(self, other: "TokenCount") -> "TokenCount":
        return TokenCount(self.value + other.value)
