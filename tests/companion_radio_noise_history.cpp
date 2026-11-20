#include <assert.h>
#include <stdint.h>
#include "RadioNoiseHistory.h"

int main() {
  RadioNoiseHistory history;
  assert(history.shouldSample(0));
  history.sample(-114, 0);
  history.sample(-114, -114);
  assert(!history.shouldSample(199));
  assert(history.shouldSample(200));
  history.sample(-90, -113);
  assert(history.latest() == 0);
  assert(history.shouldSample(10000));
  auto first = history.latest();
  const auto* entry = history.get(first);
  assert(entry && entry->valid == 2 && entry->elevated == 1);
  assert(entry->floor == -114 && entry->peak == -90);
  assert(history.ageMs(first, 10200) == 200);
  assert(history.shouldSample(32000));
  assert(history.get(history.latest())->valid == 0);
  assert(history.ageMs(first, 32000) == 22000);

  history.reset(50000);
  assert(!history.get(first));
  assert(history.shouldSample(50000));
  history.sample(-104, -114);
  for (uint32_t i = 1; i <= 361; ++i) {
    assert(history.shouldSample(50000 + i * RadioNoiseHistory::WindowMs));
  }
  assert(history.latest() - history.oldest() + 1 == RadioNoiseHistory::Capacity);
  assert(history.get(history.oldest())->valid == 0);
  assert(!history.get(history.oldest() - 1));

  history.reset(UINT32_MAX - 5000);
  assert(history.shouldSample(UINT32_MAX - 5000));
  history.sample(-103, -114);
  assert(history.shouldSample(5000));
  assert(history.get(history.latest())->elevated == 1);
  assert(history.ageMs(history.latest(), 5000) == 1);
  assert(history.shouldSample(8000000));
  assert(history.latest() - history.oldest() + 1 == RadioNoiseHistory::Capacity);
  assert(history.get(history.oldest())->valid == 0);
}
