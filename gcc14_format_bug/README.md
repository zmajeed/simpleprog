# Test case for GCC Bug 116755 for  C++ `format` and `print` functions

## Bug report
https://gcc.gnu.org/bugzilla/show_bug.cgi?id=116755

## Description

There are two print bugs for chrono duration values in gcc 14.0.1 on Ubuntu 24.04

```bash
g++ --version
g++ (Ubuntu 14-20240412-0ubuntu1) 14.0.1 20240412 (experimental) [master r14-9935-g67e1433a94f]
```

1. The min value of a chrono duration representation type gets an extra minus sign prepended by format and println - this occurs for all integer types

2. A duration<int8_t> value is printed as char

## Build and run

```bash
cmake -B build
make -C build
```


## Output

```bash
build/gcc14_format_bug
```

```
fmt println d1 "-9223372036854775808s"
fmt format d1 "-9223372036854775808s"

Issue 1: std println prints extra minus sign d1 "--9223372036854775808s"
Issue 1: std format prepends extra minus sign d1 "--9223372036854775808s"

fmt println duration<int8_t>(54) d2 "54s"

Issue 2: std println treats duration<int8_t>(54) as char '6' d2 "6s"
```

## Source


```c++
// gcc14_format_bug.cpp

#include <limits>
#include <chrono>
#include <iostream>
#include <print>

#include <fmt/format.h>
#include <fmt/chrono.h>

int main()
{
  auto d1 = std::chrono::duration<long>{std::numeric_limits<long>::min()};

  fmt::println("fmt println d1 \"{}\"", d1);
  std::cout << fmt::format("fmt format d1 \"{}\"", d1) << "\n";

  std::println("");

  std::println("Issue 1: std println prints extra minus sign d1 \"{}\"", d1);
  std::cout << std::format("Issue 1: std format prepends extra minus sign d1 \"{}\"", d1) << "\n";

  std::println("");

  auto d2 = std::chrono::duration<int8_t>{54};

  fmt::println("fmt println duration<int8_t>(54) d2 \"{}\"", d2);

  std::println("");

  std::println("Issue 2: std println treats duration<int8_t>(54) as char '6' d2 \"{}\"", d2);
}
```

