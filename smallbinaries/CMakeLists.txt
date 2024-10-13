# smallbinaries/CMakeLists.txt

cmake_minimum_required(VERSION 3.28)

project(smallbinaries)

add_compile_options(-std=c++23;-Wall;-Werror;-Wextra)
add_compile_options("$<$<CONFIG:debug>:-O0;-ggdb3>")
add_compile_options("$<$<CONFIG:release>:-Os>")
add_compile_options("$<$<NOT:$<BOOL:${CONFIG}>>:-Os>")

add_executable(test_1_no_virtual smallbinaries_virtual.cpp)
target_compile_definitions(test_1_no_virtual PRIVATE NO_VIRTUAL)

add_executable(test_2_virtual_destructor smallbinaries_virtual.cpp)
target_compile_definitions(test_2_virtual_destructor PRIVATE VIRTUAL_DESTRUCTOR)

add_executable(test_3_one_virtual smallbinaries_virtual.cpp)
target_compile_definitions(test_3_one_virtual PRIVATE ONE_VIRTUAL)

add_executable(test_4_two_virtuals smallbinaries_virtual.cpp)
target_compile_definitions(test_4_two_virtuals PRIVATE TWO_VIRTUALS)

add_executable(test_5_three_virtuals smallbinaries_virtual.cpp)
target_compile_definitions(test_5_three_virtuals PRIVATE THREE_VIRTUALS)

