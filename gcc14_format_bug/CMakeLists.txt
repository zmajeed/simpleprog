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

target_compile_options(gcc14_format_bug PRIVATE -std=c++23 -Wall -Werror -Wextra)
target_compile_options(gcc14_format_bug PRIVATE $<$<CONFIG:debug>: -O0 -ggdb3 -gdwarf-5>)
target_compile_options(gcc14_format_bug PRIVATE $<$<CONFIG:release>: -Og>)

target_link_libraries(gcc14_format_bug fmt)

if(MINGW)
# gcc-14 print library needs -lstdc++exp on Windows
  target_link_libraries(gcc14_format_bug stdc++exp)
endif()
