"""TDD tests for Money value object.

Each test corresponds to one INV-NNN in ../../INVARIANTS.md.
"""

from decimal import Decimal

import pytest

from contexts._shared_kernel.money import Money


def test_amount_non_negative() -> None:
    """INV-001: Money.amount must be ≥ 0."""
    with pytest.raises(ValueError, match="non-negative"):
        Money(Decimal("-1"), "USD")


def test_money_is_immutable() -> None:
    """INV-002: Money is frozen (immutable)."""
    m = Money(Decimal("10"), "USD")
    with pytest.raises((AttributeError, TypeError)):
        m.amount = Decimal("20")  # type: ignore[misc]


def test_addition_requires_same_currency() -> None:
    """INV-003: addition only allowed within same currency."""
    usd = Money(Decimal("10"), "USD")
    eur = Money(Decimal("10"), "EUR")
    with pytest.raises(ValueError, match="currency"):
        _ = usd + eur


def test_equality_by_value() -> None:
    """INV-004: two Money are equal iff amount and currency are equal."""
    a = Money(Decimal("10.50"), "USD")
    b = Money(Decimal("10.50"), "USD")
    c = Money(Decimal("10.50"), "EUR")
    assert a == b
    assert a != c


def test_addition_same_currency_returns_sum() -> None:
    """Adding two same-currency Money returns their sum."""
    a = Money(Decimal("3"), "USD")
    b = Money(Decimal("4"), "USD")
    assert a + b == Money(Decimal("7"), "USD")
