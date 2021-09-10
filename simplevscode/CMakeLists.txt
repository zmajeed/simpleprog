# simplevscode/CMakeLists.txt

cmake_minimum_required(VERSION 3.20)

project(simplevscode)

add_executable(simplevscode simplevscode.cpp)

target_compile_features(simplevscode PRIVATE cxx_std_20)
target_compile_options(simplevscode PRIVATE -Wall -Wextra -Werror -g -O0)

