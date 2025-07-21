# AutoPR Integration for HomeLab Testing

This directory contains AutoPR actions and workflows for automating the testing of the Azure HomeLab environment.

## Actions

### run-homelab-tests

This action runs the HomeLab tests using PowerShell and returns the results.

#### Inputs

- `test_type` (string): Type of tests to run. Options: `Unit`, `Integration`, `Workflow`, `All`. Default: `All`.
- `coverage` (boolean): Whether to generate code coverage. Default: `false`.
- `generate_report` (boolean): Whether to generate an HTML report. Default: `true`.
- `test_path` (string, optional): Specific test path to run.

#### Outputs

- `success` (boolean): Whether the tests passed.
- `total_tests` (number): Total number of tests run.
- `passed_tests` (number): Number of tests that passed.
- `failed_tests` (number): Number of tests that failed.
- `skipped_tests` (number): Number of tests that were skipped.
- `pass_rate` (number): Percentage of tests that passed.
- `test_results` (string): Full test results output.
- `report_path` (string, optional): Path to the HTML report if generated.

## Workflows

### test_homelab.yaml

This workflow runs the HomeLab tests and comments on the PR with the results.

#### Triggers

- Pull request: opened, synchronize
- Manual workflow dispatch

#### Inputs

- `test_type` (string): Type of tests to run. Options: `Unit`, `Integration`, `Workflow`, `All`. Default: `All`.

## Usage

To use these actions and workflows, you need to have AutoPR installed and configured in your repository.

### Running Tests Manually

```yaml
name: Run HomeLab Tests
on:
  workflow_dispatch:
    inputs:
      test_type:
        description: Type of tests to run
        required: true
        default: All
        type: choice
        options:
          - All
          - Unit
          - Integration
          - Workflow

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      - name: Install AutoPR
        run: pip install autopr
      - name: Run Tests
        run: autopr run test_homelab --input test_type=${{ github.event.inputs.test_type }}
```

## Development

To develop and test these actions locally:

1. Install AutoPR: `pip install autopr`
2. Run the action manually:

```python
import asyncio
from autopr.tests.utils import run_action_manually
from autopr.actions.run_homelab_tests import RunHomelabTests, Inputs

asyncio.run(
    run_action_manually(
        action=RunHomelabTests,
        inputs=Inputs(
            test_type="Unit",
            coverage=True,
            generate_report=True
        ),
    )
)
```

3. Run the tests: `pytest autopr/tests/test_run_homelab_tests.py`