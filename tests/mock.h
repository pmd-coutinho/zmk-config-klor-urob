/* Shared helpers for the simulation tests. The mock matrix is 1 row x 44
 * columns with no transform, so column N == key position N and the KLOR key
 * labels (LT4, LM1, RH0, ...) from zmk-helpers can be used directly. */
#include <dt-bindings/zmk/kscan_mock.h>

#define DOWN(pos, ms) ZMK_MOCK_PRESS(0, pos, ms)
#define UP(pos, ms)   ZMK_MOCK_RELEASE(0, pos, ms)
/* A clean, isolated tap: short press, then a long idle gap. */
#define TAP(pos)      DOWN(pos, 40) UP(pos, 300)
