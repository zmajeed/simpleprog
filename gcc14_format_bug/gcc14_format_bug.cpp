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

