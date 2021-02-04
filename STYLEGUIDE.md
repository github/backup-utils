## Bash Style Guide

If you've not done much Bash development before you may find these debugging tips useful: http://wiki.bash-hackers.org/scripting/debuggingtips.

---
##### Scripts must start with `#!/usr/bin/env bash`

---
##### Use `set -e`

If the return value of a command can be ignored, suffix it with `|| true`:

```bash
set -e
command_that_might_fail || true
command_that_should_not_fail
```

Note that ignoring an exit status with `|| true` is not a good practice though. Generally speaking, it's better to handle the error.

---
##### Avoid manually checking exit status with `$?`

Rely on `set -e` instead:

```bash
cmd
if [ $? -eq 0 ]; then
  echo worked
fi
```

should be written as:

```bash
set -e
if cmd; then
  echo worked
fi
```

---
##### Include a usage, description and optional examples

Use this format:

```bash
#!/usr/bin/env bash
#/ Usage: ghe-this-is-my-script [options] <required_arg>
#/
#/ This is a brief description of the script's purpose.
#/
#/ OPTIONS:
#/   -h | --help                      Show this message.
#/   -l | --longopt <required_arg>    An option.
#/   -c <required_arg>                Another option.
#/
#/ EXAMPLES: (optional section but nice to have when not trivial)
#/
#/    This will do foo and bar:
#/      $ ghe-this-is-my-script --longopt foobar -c 2
#/
set -e
```

If there are no options or required arguments, the `OPTIONS` section can be ignored.

---
##### Customer-facing scripts must accept both -h and --help arguments

They should also print the usage information and exit 2.

For example:

```bash
#!/usr/bin/env bash
#/ Usage: ghe-this-is-my-script [options] <required_arg>
#/
#/ This is a brief description of the script's purpose.
set -e

if [ "$1" = "--help" -o "$1" = "-h" ]; then
  grep '^#/' <"$0" | cut -c 4-
  exit 2
fi

```

---
##### Avoid Bash arrays

Main issues:

* Portability
* Important bugs in Bash versions < 4.3

---
##### Use `test` or `[` whenever possible

```bash
test -f /etc/passwd
test -f /etc/passwd -a -f /etc/group
if [ "string" = "string" ]; then
  true
fi
```

---
##### Scripts may use `[[` for advanced bash features

```bash
if [[ "$(hostname)" = *.iad.github.net ]]; then
  true
fi
```

---
##### Scripts may use Bash for loops

Preferred:

```bash
for i in $(seq 0 9); do
done
```

or:

```bash
for ((n=0; n<10; n++)); do
done
```

---
##### Use `$[x+y*z]` for mathematical expressions

```bash
local n=1
let n++
n=$[n+1] # preferred
n=$[$n+1]
n=$((n+1))
n=$(($n+1))
```

---
##### Use variables sparingly

Short paths and other constants should be repeated liberally throughout code since they
can be search/replaced easily if they ever change.

```bash
DATA_DB_PATH=/data/user/db
mkdir -p $DATA_DB_PATH
rsync $DATA_DB_PATH remote:$DATA_DB_PATH
```

versus the much more readable:

```bash
mkdir -p /data/user/db
rsync /data/user/db remote:/data/user/db
```

---
##### Use lowercase and uppercase variable names

Use lowercase variables for locals and internal veriables, and uppercase for variables inherited or exported via the environment

```bash
#!/usr/bin/env bash
#/ Usage: [DEBUG=0] process_repo <nwo>
nwo=$1
[ -n $DEBUG ] && echo "** processing $nwo" >&2

export GIT_DIR=/data/repos/$nwo.git
git rev-list
```

---
##### Use `${var}` for interpolation only when required

```bash
greeting=hello
echo $greeting
echo ${greeting}world
```

---
##### Use functions sparingly, opting for small/simple/sequential scripts instead whenever possible

When defining functions, use the following style:

```bash
my_function() {
  local arg1=$1
  [ -n $arg1 ] || return
  ...
}
```

---
##### Use `<<heredocs` when dealing with multi-line strings

- `<<eof` and `<< eof` will allow interpolation
- `<<"eof"` and `<<'eof'` will disallow interpolation
- `<<-eof` and `<<-"eof"` will strip off leading tabs first

```bash
cat <<"eof" | ssh $remote -- bash
  foo=bar
  echo $foo # interpolated on remote side after ssh
eof
```

```bash
bar=baz
cat <<eof | ssh $remote -- bash
  echo $bar > /etc/foo # interpolated before ssh
  chmod 0600 /etc/foo
eof
```

---
##### Quote variables that could reasonably have a space now or in the future

```bash
if [ ! -z "$packages" ]; then
  true
fi
```

---
##### Use two space indentation

---
##### Scripts should not produce errors or warnings when checked with ShellCheck

Use inline comments to disable specific tests, and explain why the test has been disabled.

```bash
hexToAscii() {
  # shellcheck disable=SC2059 # $1 needs to be interpreted as a formatted string
  printf "\x$1"
}
```

### Testing

See [the style guide](https://github.com/github/backup-utils/blob/master/test/STYLEGUIDE.md)
