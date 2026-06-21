"""TDD tests for ModelName value object."""

import pytest

from contexts._shared_kernel.model_name import ModelName


def test_format_validation() -> None:
    """INV-006: must match ^[a-z0-9._-]+$ and be non-empty."""
    # valid
    ModelName("claude-opus-4-8")
    ModelName("gpt-4.1-mini")
    ModelName("haiku")

    # invalid: empty
    with pytest.raises(ValueError, match="empty"):
        ModelName("")
    # invalid: uppercase
    with pytest.raises(ValueError, match="pattern"):
        ModelName("Claude")
    # invalid: spaces
    with pytest.raises(ValueError, match="pattern"):
        ModelName("claude opus")
    # invalid: special chars
    with pytest.raises(ValueError, match="pattern"):
        ModelName("claude/opus")
