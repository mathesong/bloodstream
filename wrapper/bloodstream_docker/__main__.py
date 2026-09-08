"""Module entry point for ``python -m bloodstream_docker``."""

from .cli import main


if __name__ == "__main__":
    raise SystemExit(main())
