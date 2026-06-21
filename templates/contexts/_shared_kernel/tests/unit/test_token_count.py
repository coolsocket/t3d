"""TDD tests for TokenCount value object."""

import pytest

from contexts._shared_kernel.token_count import TokenCount


def test_token_count_non_negative() -> None:
    """INV-005: TokenCount must be ≥ 0."""
    with pytest.raises(ValueError, match="non-negative"):
        TokenCount(-1)


def test_token_count_zero_allowed() -> None:
    assert TokenCount(0).value == 0


def test_token_count_addition() -> None:
    assert TokenCount(3) + TokenCount(4) == TokenCount(7)


def test_token_count_is_immutable() -> None:
    tc = TokenCount(5)
    with pytest.raises((AttributeError, TypeError)):
        tc.value = 10  # type: ignore[misc]
