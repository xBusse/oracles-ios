// Link's walk speed setting: the speeds it picks are ones the game's speed table has, and it only
// applies while the player is steering Link (not to the walk in through a cave or a scripted walk).
#include "game/game.h"
#include "game/features.h"
#include <stdio.h>
#include <stdlib.h>

static int fails;
#define CHECK_EQ(a, b) do { int a_ = (a), b_ = (b); if (a_ != b_) { fails++; printf("FAIL %s:%d: %s == %s (got %d, want %d)\n", __FILE__, __LINE__, #a, #b, a_, b_); } } while (0)

static void scaling(void) {
  // 4 quarters (or less): every speed exactly as the ROM gives it
  for (int q = 0; q <= 4; q += 4)
    for (int s = 0; s < 256; s++) CHECK_EQ(features_scale_speed(q, (uint8_t)s), s);
  // SPEED_100 (0x28), Link's walk: 1.25x .. 2x land exactly on SPEED_120 .. SPEED_200
  const int want[] = {0x28, 0x32, 0x3c, 0x46, 0x50};
  for (int q = 4; q <= 8; q++) CHECK_EQ(features_scale_speed(q, 0x28), want[q - 4]);
  // every result is a table speed: a multiple of 5, never above SPEED_300, never slower
  for (int q = 5; q <= 8; q++) {
    for (int s = 5; s <= 0x78; s += 5) {
      int r = features_scale_speed(q, (uint8_t)s);
      if (r % 5 || r > 0x78 || r < s) { fails++; printf("FAIL q=%d speed %#x -> %#x\n", q, s, r); }
    }
    CHECK_EQ(features_scale_speed(q, 0), 0);            // standing still stays still
    CHECK_EQ(features_scale_speed(q, 0x78), 0x78);      // already the fastest
  }
}

static void only_while_steering(bool seasons) {
  GB *gb = calloc(1, sizeof *gb);
  game_seasons = seasons;
  features.walk_speed = 8;                              // 2x
  W8(w1Link_state) = 0x01;                              // normal
  W8(wGameKeysPressed) = 0x40;                          // up held
  W8(wDisabledObjects) = 0;
  CHECK_EQ(features_link_speed(gb, 0x28), 0x50);        // steering: doubled
  W8(wGameKeysPressed) = 0x01;                          // A only, no direction
  CHECK_EQ(features_link_speed(gb, 0x28), 0x28);
  W8(wGameKeysPressed) = 0x40;
  W8(w1Link_state) = 0x0b;                              // forced movement
  CHECK_EQ(features_link_speed(gb, 0x28), 0x28);
  W8(w1Link_state) = 0x0a;                              // warping in through a cave or door
  CHECK_EQ(features_link_speed(gb, 0x28), 0x28);
  W8(w1Link_state) = 0x01;
  W8(wDisabledObjects) = 0x01;                          // a cutscene froze things
  CHECK_EQ(features_link_speed(gb, 0x28), 0x28);
  W8(wDisabledObjects) = 0;
  features.walk_speed = 4;                              // setting off
  CHECK_EQ(features_link_speed(gb, 0x28), 0x28);
  features.walk_speed = 0;
  free(gb);
}

int main(void) {
  scaling();
  only_while_steering(false);
  only_while_steering(true);
  printf(fails ? "%d FAILED\n" : "features ok\n", fails);
  return fails != 0;
}
