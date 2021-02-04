## Writing tests

See also the [Bash style guide](https://github.com/github/backup-utils/tree/master/STYLEGUIDE.md)

---
##### All tests should use `set -e` and call `setup` before making any assertions

Like this:

```bash
begin_test "echo works"
(
  set -e
  setup

  echo passing | grep passing
)
end_test
```

---
##### Resist the urge to disable `set -e`

If you want to assert failure, please resist the urge to disable `set -e` and
instead use negation with `!`:

```bash
begin_test "netcat is not from bsd"
(
  set -e
  setup

  ! nc -h 2>&1 | grep bsd
)
end_test
```
