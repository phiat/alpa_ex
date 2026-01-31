# Contributing

## Development Setup

```bash
git clone git@github.com:phiat/alpa_ex.git
cd alpa_ex
mix deps.get
mix test
```

## Quality Gates

Before submitting a PR, ensure:

```bash
mix compile --warnings-as-errors  # No warnings
mix format --check-formatted      # Code formatting
mix test                          # All tests pass
mix credo                         # Static analysis
mix dialyzer                      # Type checking
```

## Running Integration Tests

Integration tests hit the paper API and require credentials:

```bash
export APCA_API_KEY_ID="your-paper-key"
export APCA_API_SECRET_KEY="your-paper-secret"
mix test --include live
```

## Issue Workflow

1. Check [existing issues](https://github.com/phiat/alpa_ex/issues)
2. Create an issue describing the change
3. Fork and create a branch
4. Make changes with tests
5. Open a PR referencing the issue

## Code Style

- Follow existing patterns in the codebase
- Use `@doc`, `@spec`, and `@moduledoc` for all public functions
- Use TypedStruct for new models
- Return `{:ok, result} | {:error, %Alpa.Error{}}` from API functions
- URI-encode user-provided symbols in URL paths
