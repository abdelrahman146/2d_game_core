# Integration Tests

Put higher-level GUT tests here when a test needs real scene/resource orchestration rather than isolated runtime objects.

This folder now includes `test_game_core.gd` as the first real integration-level lifecycle check.

Guidelines:

- Test files should use the `test_*.gd` naming convention.
- Helper files should not use the `test_` prefix, or GUT will try to execute them as test scripts.
- Keep unit-style logic tests under `tests/unit/` and shared helpers under `tests/helpers/`.
