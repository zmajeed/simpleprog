// smallbinaries_slide_103.cpp

#include <array>

using namespace std;

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

