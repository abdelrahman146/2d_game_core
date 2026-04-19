# Testing And VS Code Setup

Yes, you can run Godot validation and automated tests from VS Code.

There are two separate things to think about:

## 1. Project validation

This is the easiest thing to run today.

It means launching Godot in headless mode to make sure the project loads without parser or startup errors.

This repo now includes a VS Code task for that:

- `Godot: Validate Project`

That task runs:

```sh
/opt/homebrew/bin/godot --headless --editor --path ${workspaceFolder} --quit
```

Use it from VS Code:

1. Open the Command Palette.
2. Run `Tasks: Run Task`.
3. Choose `Godot: Validate Project`.

This is not a real test suite. It is a fast smoke check.

## 2. Automated tests

For actual tests in Godot, you usually need one of these approaches:

### Option A: GUT

GUT is the most common Godot testing framework.

Good fit when you want:

- unit tests for GDScript logic
- integration tests for scenes and resources
- test folders and assertions similar to normal xUnit workflows

This is the option I recommend for this repo once we add real tests.

### Option B: custom test runner scene or script

This is lighter weight, but you have to build your own conventions.

Good fit when you only want a very small number of focused checks and do not want a dependency yet.

## Recommended setup for this repo

This repo now uses the following GUT structure:

- `addons/gut/` for the framework itself
- `tests/helpers/` for shared test-only helpers that should not be discovered as tests
- `tests/unit/` for fast runtime-free tests
- `tests/integration/` for scene/resource behavior tests

The committed GUT config is:

- [/.gutconfig.json](/Users/abdel/Workspace/Games/2DGameCore/.gutconfig.json)

That config currently tells GUT to:

- look under `res://tests`
- include subdirectories
- use the `test_` prefix convention
- exit automatically when the run completes

## What is already covered by tests

The first GUT tests currently cover:

- service setup order
- service teardown order
- late service registration and replacement behavior
- entity runtime creation from definition + components
- reverse-order entity component teardown
- interaction tag matching
- screen router creation, persistent-screen reuse, and non-persistent screen cleanup
- `GCGameCore` bootstrap, shutdown, and router reset behavior

Typical examples to test in this repo first:

- service registration and setup order
- service teardown order
- screen definition lookup and routing behavior
- persistent vs non-persistent screen behavior
- entity runtime initialization from definition + components
- interaction tag validation

## VS Code task for GUT

This repo now includes a real task:

- `Godot: Run GUT Tests`

It runs this command:

```sh
/opt/homebrew/bin/godot --headless --path ${workspaceFolder} -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
```

The explicit `-gexit` keeps the CLI run deterministic from VS Code tasks even if editor-side defaults change.

## Can tests run directly inside VS Code?

Yes, in a few ways:

- through `Tasks: Run Task`
- through the integrated terminal
- through debug/launch configurations for the Godot project

What VS Code does not give you automatically is a Godot-native test explorer unless you add a framework or extension that provides it.

## What is already configured in this repo

- [launch.json](/Users/abdel/Workspace/Games/2DGameCore/.vscode/launch.json): launches the Godot project for debugging.
- [tasks.json](/Users/abdel/Workspace/Games/2DGameCore/.vscode/tasks.json): runs headless validation, a headless project task, and the GUT suite.
- [/.gutconfig.json](/Users/abdel/Workspace/Games/2DGameCore/.gutconfig.json): shared GUT CLI configuration for the repo.
- [testing.md](/Users/abdel/Workspace/Games/2DGameCore/addons/game_core/docs/testing.md): explains how to evolve this into a real automated test setup.
- [tests/unit/core/test_service_registry.gd](/Users/abdel/Workspace/Games/2DGameCore/tests/unit/core/test_service_registry.gd): service lifecycle tests.
- [tests/unit/entities/test_entity_definition.gd](/Users/abdel/Workspace/Games/2DGameCore/tests/unit/entities/test_entity_definition.gd): entity definition/runtime tests.
- [tests/unit/interactions/test_interaction.gd](/Users/abdel/Workspace/Games/2DGameCore/tests/unit/interactions/test_interaction.gd): interaction tag-matching tests.
- [tests/unit/screens/test_screen_router.gd](/Users/abdel/Workspace/Games/2DGameCore/tests/unit/screens/test_screen_router.gd): screen router tests.
- [tests/integration/test_game_core.gd](/Users/abdel/Workspace/Games/2DGameCore/tests/integration/test_game_core.gd): bootstrap and shutdown integration tests for `GCGameCore`.
- [tests/integration/README.md](/Users/abdel/Workspace/Games/2DGameCore/tests/integration/README.md): guidance for future higher-level GUT tests.

## Naming rule for helpers

GUT discovers test scripts using the configured `test_` prefix under `res://tests`.

That means helper scripts should not be named like tests.

Good:

- `tests/helpers/screen_helper.gd`

Bad:

- `tests/helpers/test_screen.gd`

If a helper uses the `test_` prefix, GUT will try to execute it as a test script and pollute the output with warnings.

## Recommendation

Right now, use VS Code for:

- project validation
- debugging the running game
- running the committed GUT suite during development

## How to run tests now

1. Open the Command Palette.
2. Run `Tasks: Run Task`.
3. Choose `Godot: Run GUT Tests`.

You can also run the same command directly in the integrated terminal.

At the moment, the committed suite has 15 passing tests and 79 assertions.
