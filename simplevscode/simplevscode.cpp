// simplevscode.cpp

#include <stdlib.h>
#include <stdio.h>

#include <string>
#include <vector>
#include <thread>

#include "amap/amap.h"
#include "aset/aset.h"

using namespace std;
using namespace simplevscode;

int main(void)
{

// simple objects to test for gdb pretty print
  char aCString[100] = "a C string";
  string aCPlusPlusString = "a C++ string";
  int anArray[100] = {1, 3, 5, 7};
  vector aVector = {13, 17, 19, 21};

// functions in other source files to step into
  map aMap = getAMap();
  set aSet = getASet();

  printf("c string: \"%s\"\n", aCString);
  printf("cplusplus string: \"%s\"\n", aCPlusPlusString.c_str());
  printf("array: [%d]\n", anArray[0]);
  printf("vector: [%d]\n", aVector[0]);
  printf("set: {%d}\n", *aSet.begin());
  printf("map: (%u, \"%s\")\n", aMap.begin()->first, aMap.begin()->second.c_str());

// slow loop to test gdb interrupt with pkill -stop simplevscode
  for(int i = 0; i < 100; ++i) {
    printf("%d\n", i);
    this_thread::sleep_for(1s);
  }
  puts("");

// test interactive io
  for(char quit = 'n'; quit != 'q';) {
    printf("q to quit: ");
    scanf("%c", &quit);
  }

  return 0;
}
