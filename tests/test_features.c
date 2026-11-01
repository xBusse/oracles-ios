// Link's walk speed setting: the speeds it picks are ones the game's speed table has.
#include "game/features.h"
#include <stdio.h>

static int fails;
#define CHECK_EQ(a, b) do { int a_ = (a), b_ = (b); if (a_ != b_) { fails++; printf("FAIL %s:%d: %s == %s (got %d, want %d)\n", __FILE__, __LINE__, #a, #b, a_, b_); } } while (0)

int main(void) {
  // off (0 or 4): every speed exactly as the ROM gives it
  for (int q = 0; q <= 4; q += 4) {
    features.walk_speed = (uint8_t)q;
    for (int s = 0; s < 256; s++) CHECK_EQ(features_link_speed((uint8_t)s), s);
  }
  // SPEED_100 (0x28), Link's walk: 1.25x .. 2x land exactly on SPEED_120 .. SPEED_200
  const int want[] = {0x28, 0x32, 0x3c, 0x46, 0x50};
  for (int q = 4; q <= 8; q++) { features.walk_speed = (uint8_t)q; CHECK_EQ(features_link_speed(0x28), want[q - 4]); }
  // every result is a table speed: a multiple of 5, never above SPEED_300, never slower
  for (int q = 5; q <= 8; q++) {
    features.walk_speed = (uint8_t)q;
    for (int s = 5; s <= 0x78; s += 5) {
      int r = features_link_speed((uint8_t)s);
      if (r % 5 || r > 0x78 || r < s) { fails++; printf("FAIL q=%d speed %#x -> %#x\n", q, s, r); }
    }
    CHECK_EQ(features_link_speed(0), 0);                // standing still stays still
    CHECK_EQ(features_link_speed(0x78), 0x78);          // already the fastest
  }
  features.walk_speed = 0;
  printf(fails ? "%d FAILED\n" : "features ok\n", fails);
  return fails != 0;
}
