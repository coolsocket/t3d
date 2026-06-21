"""ModelName value object.

Invariant INV-006: value must match ^[a-z0-9._-]+$ and be non-empty.
"""

import re
from dataclasses import dataclass

_MODEL_NAME_RE = re.compile(r"^[a-z0-9._-]+$")


@dataclass(frozen=True)
class ModelName:
    value: str

    def __post_init__(self) -> None:
        if not self.value:
            raise ValueError("ModelName must not be empty")
        if not _MODEL_NAME_RE.match(self.value):
            raise ValueError(
                f"ModelName must match pattern [a-z0-9._-]+, got {self.value!r}"
            )
