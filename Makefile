# KLOR ZMK config — Docker-based local build.
#
# Quick start:
#   make init      # one-time: set up the west workspace + fetch ZMK/modules
#   make build     # build both halves -> firmware/klor_left.uf2, klor_right.uf2
#   make flash-left / flash-right   # copy a .uf2 onto a half in bootloader mode
#
# Everything runs inside the official ZMK build container; nothing is installed
# on the host except Docker.
#
# Layout: this repo is both the user config (config/) and a ZMK keyboard module
# (zephyr/module.yml + boards/shields/klor/). The west workspace (zmk/, zephyr/,
# modules/, build/) lives in the gitignored .zmk/ so it doesn't collide with the
# module's zephyr/ directory.

# Fully-qualified so it resolves under both docker and podman.
IMAGE   ?= docker.io/zmkfirmware/zmk-dev-arm:stable
# Container engine: prefer docker, fall back to podman (override with ENGINE=...).
ENGINE  ?= $(shell command -v docker 2>/dev/null || command -v podman 2>/dev/null || echo docker)
# nice!nano v2 in Zephyr's hardware-model-v2 layout: board "nice_nano",
# default revision 2.0.0, "zmk" variant.
BOARD   ?= nice_nano//zmk
WORKDIR := /workspace
WS      := $(WORKDIR)/.zmk

# keymap-drawer (layer SVG): runs in a small Python image, version pinned.
DRAW_IMAGE ?= docker.io/library/python:3.12-slim
KD_VERSION ?= 0.23.0

# ":z" relabels the bind mount for SELinux (needed on Fedora-based hosts with
# podman; harmless elsewhere). The repo is mounted at $(WORKDIR); config/ is
# additionally mounted at $(WS)/config, because `west init -l` needs the manifest
# repo inside the workspace.
REPO_MOUNT := -v "$(CURDIR)":$(WORKDIR):z
MOUNT      := $(REPO_MOUNT) -v "$(CURDIR)/config":$(WS)/config:z -w $(WS)
# Non-interactive container invocation (used for builds in scripts/CI).
DOCKER    := $(ENGINE) run --rm $(MOUNT) $(IMAGE)
# Interactive (TTY) invocation, for `make shell`.
DOCKER_IT := $(ENGINE) run --rm -it $(MOUNT) $(IMAGE)

# Each `docker run --rm` is a fresh container, so the Zephyr CMake package
# registration (written by `west zephyr-export` into the container's home dir)
# does not persist. The build recipes run `west zephyr-export` in the same
# invocation as `west build` (see below).
WEST_BUILD = west build -p -s zmk/app -b $(BOARD)
CMAKE_ARGS = -DZMK_CONFIG=$(WORKDIR)/config -DZMK_EXTRA_MODULES=$(WORKDIR)
# ZMK Studio on the central (left) half only; `make build STUDIO=n` to disable.
STUDIO ?= y
ifeq ($(STUDIO),y)
STUDIO_ARGS  = -S studio-rpc-usb-uart
STUDIO_CMAKE = -DCONFIG_ZMK_STUDIO=y
endif

.PHONY: help init update build build-left build-right test draw clean pristine shell flash-left flash-right

help:
	@echo "Targets:"
	@echo "  init         set up west workspace and fetch ZMK + modules (run once)"
	@echo "  update       re-fetch/update west dependencies"
	@echo "  build        build both halves into firmware/"
	@echo "  build-left   build the left half only"
	@echo "  build-right  build the right half only"
	@echo "  test         run keymap simulation tests (tests/; T=<case> for one)"
	@echo "  draw         render the keymap to draw/klor.svg (needs 'make init' first)"
	@echo "  clean        remove build artifacts and firmware/*.uf2"
	@echo "  pristine     clean + remove the fetched west workspace (.zmk/)"
	@echo "  shell        open an interactive shell in the build container"

# Mount point for the nested config/ bind mount.
.zmk/config:
	@mkdir -p $@

init: .zmk/config
	$(DOCKER) bash -lc "west init -l config && west update && west zephyr-export"

update: .zmk/config
	$(DOCKER) west update

build: build-left build-right

build-left: .zmk/config
	@mkdir -p firmware
	$(DOCKER) bash -lc 'west zephyr-export && $(WEST_BUILD) -d build/left $(STUDIO_ARGS) -- -DSHIELD=klor_left $(CMAKE_ARGS) $(STUDIO_CMAKE)'
	cp .zmk/build/left/zephyr/zmk.uf2  firmware/klor_left.uf2
	@echo "==> firmware/klor_left.uf2"

build-right: .zmk/config
	@mkdir -p firmware
	$(DOCKER) bash -lc 'west zephyr-export && $(WEST_BUILD) -d build/right -- -DSHIELD=klor_right $(CMAKE_ARGS)'
	cp .zmk/build/right/zephyr/zmk.uf2 firmware/klor_right.uf2
	@echo "==> firmware/klor_right.uf2"

# Keymap simulation tests: replay key presses through the real keymap on ZMK's
# native_sim board and diff the HID output (see tests/run.sh). `make test T=combos`
# runs one case; ACCEPT=1 rewrites the expected logs (review the diff first!).
test: .zmk/config
	$(ENGINE) run --rm $(MOUNT) -e ACCEPT=$(ACCEPT) $(IMAGE) /workspace/tests/run.sh $(T)

# Render layer diagrams. Needs the west workspace (`make init`) because
# keymap-drawer's preprocessor resolves the zmk-helpers macros via .zmk/modules/.
draw:
	@mkdir -p draw
	$(ENGINE) run --rm $(REPO_MOUNT) -w $(WORKDIR) $(DRAW_IMAGE) bash -lc 'pip install --quiet --root-user-action=ignore keymap-drawer==$(KD_VERSION) && keymap -c draw/config.yaml parse -z config/klor.keymap -o draw/klor.yaml && keymap -c draw/config.yaml draw draw/klor.yaml -o draw/klor.svg'
	@echo "==> draw/klor.svg"

clean:
	rm -rf .zmk/build firmware/*.uf2

pristine: clean
	rm -rf .zmk

shell: .zmk/config
	$(DOCKER_IT) bash

# Flash helpers: put the half into bootloader (double-tap reset) so it mounts as
# a USB drive, then run these. Adjust the mount path for your system.
# NOTE: distinct from MOUNT above (the container bind-mount flags) — reusing that
# name made the flash targets expand the podman args instead of this path.
NICENANO ?= /run/media/$(USER)/NICENANO
flash-left:
	cp firmware/klor_left.uf2  "$(NICENANO)/"
flash-right:
	cp firmware/klor_right.uf2 "$(NICENANO)/"
