# gcc14_format_bug/CMakeLists.txt

cmake_minimum_required(VERSION 3.28)

project(gcc14_format_bug)

include(FetchContent)

FetchContent_Declare(
  fmt
  GIT_REPOSITORY https://github.com/fmtlib/fmt
  GIT_TAG master
  GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(fmt)

add_executable(gcc14_format_bug gcc14_format_bug.cpp)

target_compile_options(gcc14_format_bug PRIVATE -Wall -Werror -Wextra -O0 -ggdb3 -gdwarf-5 -std=c++23)

target_link_libraries(gcc14_format_bug fmt)

