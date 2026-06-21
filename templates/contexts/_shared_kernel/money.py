"""Money value object.

Invariants (see ./INVARIANTS.md):
  INV-001 amount >= 0
  INV-002 frozen / immutable
  INV-003 addition only same currency
  INV-004 equality by value
"""

from dataclasses import dataclass
from decimal import Decimal


@dataclass(frozen=True)
class Money:
    amount: Decimal
    currency: str

    def __post_init__(self) -> None:
        if self.amount < 0:
            raise ValueError(f"Money amount must be non-negative, got {self.amount}")

    def __add__(self, other: "Money") -> "Money":
        if self.currency != other.currency:
            raise ValueError(
                f"Cannot add different currency: {self.currency} vs {other.currency}"
            )
        return Money(self.amount + other.amount, self.currency)
