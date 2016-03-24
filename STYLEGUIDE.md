# Bash styleguide

If you've not done much Bash development before you may find these debugging tips useful: http://wiki.bash-hackers.org/scripting/debuggingtips

1. Scripts must start with `#!/usr/bin/env bash`.

1. Scripts must use `set -e`.
   if the return value of a command can be ignored, suffix it with `|| true`

  ``` bash
  set -e
  command_that_might_fail || true
  command_that_should_not_fail
  ```
  
  Note that ignoring an exit status with `|| true` is genrally not a good practice
  though. Generally speaking it's better to handle the error.

1. Scripts should not check exit status via `$?` manually. rely on `set -e` instead:

  ``` bash
  cmd
  if [ $? -eq 0 ]; then
    echo worked
  fi
  ```

  should be written as:

  ``` bash
  set -e
  if cmd; then
    echo worked
  fi
  ```

1. Scripts must include a usage, description and optional examples in this format:

  ```bash
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
  ```

  If there are no options or required arguments, that can be ignored.

1. Customer-facing scripts must accept both `-h` and `--help` arguments and print the usage information with an `exit 2` status code.

1. Scripts should not use Bash arrays.

1. Scripts should use `test` or `[` whenever possible:

  ``` bash
  test -f /etc/passwd
  test -f /etc/passwd -a -f /etc/group
  if [ "string" = "string" ]; then
    true
  fi
  ```

1. Scripts may use `[[` for advanced bash features

  ``` bash
  if [[ "$(hostname)" = *.iad.github.net ]]; then
    true
  fi
  ```

1. Scripts may use bash for loops

  ``` bash
  for ((n=0; n<10; n++)); do
  done
  ```

  or

  ```bash
  for i in $(seq 0 9); do
  done
  ```

1. Scripts should use `$[x+y*z]` for mathematical expressions

  ``` bash
  local n=1
  let n++
  n=$[n+1] # preferred
  n=$[$n+1]
  n=$((n+1))
  n=$(($n+1))
  ```

1. Scripts should use variables sparingly.
   Short paths and other constants should be repeated liberally throughout
   code since they can be search/replaced easily if they ever change.

  ``` bash
  DATA_DB_PATH=/data/user/db
  mkdir -p $DATA_DB_PATH
  rsync $DATA_DB_PATH remote:$DATA_DB_PATH
  ```

  vs the much more readable:

  ``` bash
  mkdir -p /data/user/db
  rsync /data/user/db remote:/data/user/db
  ```

1. Scripts should use lowercase variables for locals,
   and uppercase for variables inherited or exported via the environment:

  ``` bash
  #!/bin/bash
  #/ Usage: [DEBUG=0] process_repo <nwo>
  nwo=$1
  [ -n $DEBUG ] && echo "** processing $nwo" >&2

  export GIT_DIR=/data/repos/$nwo.git
  git rev-list
  ```

1. Scripts should use `${var}` for interpolation only when required:

  ``` bash
  greeting=hello
  echo $greeting
  echo ${greeting}world
  ```

1. Scripts should use functions sparingly, opting for small/simple/sequential
   scripts instead whenever possible when defining functions, use the following style:

  ``` bash
  my_function() {
    local arg1=$1
    [ -n $arg1 ] || return
    ...
  }
  ```

1. Scripts should use `<<heredocs` when dealing with multi-line strings:

  - `<<eof` and `<< eof` will allow interpolation
  - `<<"eof"` and `<<'eof'` will disallow interpolation
  - `<<-eof` and `<<-"eof"` will strip off leading tabs first

  ``` bash
  cat <<"eof" | ssh $remote -- bash
    foo=bar
    echo $foo # interpolated on remote side after ssh
eof
  ```

  ``` bash
  bar=baz
  cat <<eof | ssh $remote -- bash
    echo $bar > /etc/foo # interpolated before ssh
    chmod 0600 /etc/foo
eof
  ```

1. Scripts should quote variables that could reasonably have a space now or in
   the future:

  ``` bash
  if [ ! -z "$packages" ]; then
    true
  fi
  ```

## Writing tests

1. All tests should use `set -e` before making any assertions:

  ```bash
  begin_test "echo works"
  (
    set -e
  
    echo passing | grep passing
  )
  end_test
  ```

1. If you want to assert failure, please resist the urge to disable `set -e` and
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
