#ifndef SIMPLEVSCODE_AMAP_H
#define SIMPLEVSCODE_AMAP_H
// simplevscode/amap.h

#include <map>

namespace simplevscode {
using namespace std;

auto getAMap = [] {
  return map{pair{0u, "zero"s}, {1u, "one"s}};
};

}

#endif
