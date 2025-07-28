"""Markdown linter and fixer with support for common style issues."""

from dataclasses import dataclass, field
from enum import Enum, auto
from pathlib import Path
from typing import Callable, Dict, List, Optional, Pattern, Set, Tuple, Union

__version__ = "0.1.0"
