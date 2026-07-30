# Contributing

Thanks for your interest in MoonLogfmt Lens.

## Development Requirements

Install the latest stable MoonBit toolchain and clone the repository:

```bash
git clone https://github.com/sqhyyy/moonlogfmt-lens.git
cd moonlogfmt-lens
```

## Local Verification

Before submitting a change, run:

```bash
moon fmt
moon check
moon build
moon test
moon package --list
```

All checks should pass before the change is committed.

## Contribution Guidelines

- Keep changes focused and easy to review.
- Add tests when introducing new behavior or fixing a bug.
- Preserve deterministic behavior across MoonBit targets.
- Do not include sensitive log values in tests, examples, or reports.
- Update the documentation when public APIs or command-line behavior change.

## Commit Messages

Use concise commit messages that describe the purpose of the change, for example:

```
docs: improve contribution guide
test: add duplicate-key audit coverage
fix: handle escaped quoted values
```
