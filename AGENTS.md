# PostgreSQL Development

## Cursor Cloud specific instructions

This is the PostgreSQL 19devel source tree — a large C codebase with two build systems (Meson and legacy Autoconf/Make). **Meson is the preferred build system.**

### Build (Meson)

```bash
# First-time configure (from repo root):
meson setup build -Dcassert=true -Dtap_tests=enabled -Dprefix=/usr/local/pgsql

# Rebuild after code changes:
ninja -C build

# Install binaries:
sudo ninja -C build install
```

After install, binaries are at `/usr/local/pgsql/bin/`. Add to PATH:

```bash
export PATH=/usr/local/pgsql/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/pgsql/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
```

### Testing

```bash
# Core regression tests (239 subtests, ~14s):
meson test -C build --suite setup --suite regress -t 5

# Isolation tests (125 subtests, ~27s):
meson test -C build --suite setup --suite isolation -t 5

# All tests (slow — includes TAP tests for every module):
meson test -C build -t 10

# Run a specific test suite:
meson test -C build --suite setup --suite <suite_name> -t 5
```

The `--suite setup` must always be included — it handles `tmp_install` and `initdb_cache` needed by other test suites.

### Running a local server

```bash
initdb -D /tmp/pgdata
pg_ctl -D /tmp/pgdata -l /tmp/pgdata/logfile start
createdb mydb
psql -d mydb
# Stop: pg_ctl -D /tmp/pgdata stop
```

### Gotchas

- The compiler is **Clang 18** (not GCC) in this environment. Meson auto-detects it.
- `libperl` for PL/Perl is not linkable in this environment (missing `libperl-dev`); PL/Perl is disabled. PL/Python and PL/Tcl are also disabled (missing dev packages). This is expected and does not affect core PostgreSQL development.
- Meson `setup` is only needed once; `ninja -C build` is sufficient for incremental rebuilds after code changes.
- If you change `meson.build` files or `meson_options.txt`, Meson/Ninja will automatically re-configure on the next `ninja -C build`.
- The build directory is `/workspace/build/`. Do not commit it.
