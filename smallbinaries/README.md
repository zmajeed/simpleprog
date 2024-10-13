# Notes on How To Keep C++ Binaries Small, C++ on Sea 2024

## Summary

Slides 103-104 from the talk at https://youtu.be/XfU2ZODl6EU?t=4525 at 1:15:25 mark show the impact of virtual functions on executable size

A small class is compiled with and without virtual functions. Exectuable size is shown to increase from 16 KB without virtual functions to 281 KB with just a virtual destructor. Additional virtual functions increase binary size by tiny amounts


We see similar effects in our test with GCC-14 on Ubuntu 24.04. In fact our executables blow up from 16 KB to 498 KB.

I don't know why our executables with virtual functions have an extra 217 KB compared to the executables from the talk. I believe the speaker ran his tests on Mac while our results are on Linux. For some reason adding virtual functions caused the .data section to grow and the .bss section to shrink on Linux.


## Slides from the talk

## Slide 103

```c++
class VirtualExperiment {
public:
  VirtualExperiment() = default;
  VirtualExperiment(int a, int b, int c) : m_a(a), m_b(b), m_c(c) {}
  /* virtual */ ~VirtualExperiment() = default;
  /* virtual */ int getA() const { return m_a; }
  /* virtual */ int getB() const { return m_b; }
  /* virtual */ int getC() const { return m_c; }
private:
  int m_a = 0;
  int m_b = 0;
  int m_c = 0;
};

```

## Slide 104

|   Version         | Binary size |
|-------------------|-------------|
| no virtual        |    16,879   |
| only virtual dtor |   281,505   |
| one virtual       |   281,553   |
| two virtuals      |   281,601   |
| three virtuals    |   281,649   |


## Our test version

## C++ source

The file `smallbinaries_virtual.cpp` has the code

```c++
class VirtualExperiment {
public:
  VirtualExperiment() = default;
  VirtualExperiment(int a, int b, int c) : m_a(a), m_b(b), m_c(c) {}

#ifdef NO_VIRTUAL
  ~VirtualExperiment() = default;
  int getA() const { return m_a; }
  int getB() const { return m_b; }
  int getC() const { return m_c; }
#elif VIRTUAL_DESTRUCTOR
  virtual ~VirtualExperiment() = default;
  int getA() const { return m_a; }
  int getB() const { return m_b; }
  int getC() const { return m_c; }
#elif ONE_VIRTUAL
  virtual ~VirtualExperiment() = default;
  virtual int getA() const { return m_a; }
  int getB() const { return m_b; }
  int getC() const { return m_c; }
#elif TWO_VIRTUALS
  virtual ~VirtualExperiment() = default;
  virtual int getA() const { return m_a; }
  virtual int getB() const { return m_b; }
  int getC() const { return m_c; }
#elif THREE_VIRTUALS
  virtual ~VirtualExperiment() = default;
  virtual int getA() const { return m_a; }
  virtual int getB() const { return m_b; }
  virtual int getC() const { return m_c; }
#endif

private:
  int m_a = 0;
  int m_b = 0;
  int m_c = 0;
};

array<VirtualExperiment, 10'000> a{};

int main() {}
```

## Build

The following commands build five executables for the different compile macros

```
cmake -B build -S .
make -C build
```

The gcc-14 command is

```
g++ -std=c++23 -Wall -Werror -Wextra -Os
```

## Check sizes

```
ls -l build/test*

 15872 test_1_no_virtual
498416 test_2_virtual_destructor
498472 test_3_one_virtual
498528 test_4_two_virtuals
498584 test_5_three_virtuals

```

```
size build/test*
  text    data     bss     dec   filename
  1217     544  120032  121793   test_1_no_virtual
241932  240696       8  482636   test_2_virtual_destructor
241992  240704       8  482704   test_3_one_virtual
242052  240712       8  482772   test_4_two_virtuals
242112  240720       8  482840   test_5_three_virtuals

```

