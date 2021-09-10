# simplevscode
A simple C++ program with cmakefile and VSCode launch.json config for cygwin gdb

See nice views in VSCode of standard C++ objects like vector, map, string and set

Also step into and set breakpoints in different files

Pause button in VSCode does not work - workaround is to send SIGSTOP from cygwin

```bash
$ pkill -stop simplevscode
```

`pkill` and other proc tools are in `procps-ng` cygwin package

Tested with VSCode 1.60
