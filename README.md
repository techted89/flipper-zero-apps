# Flipper Zero Apps

This repository is a workspace for building Flipper Zero external applications (.fap) using the official Flipper Zero firmware as the dependency source and build system.

## What this repo includes

- A dependency on the official Flipper Zero firmware repo
- A ready-to-use app folder for external apps
- Bootstrapping steps for setting up the toolchain and build environment

## Quick start

```bash
git clone --recurse-submodules https://github.com/techted89/flipper-zero-apps.git
cd flipper-zero-apps
bash ./scripts/bootstrap-flipper.sh
cd firmware
./fbt
```

## Dependency source

The build environment is based on the official Flipper Zero firmware repository:

- https://github.com/flipperdevices/flipperzero-firmware
- Branch: `dev`

This repo uses it as a submodule at `./firmware` so you get the same headers, toolchain logic, and app build conventions used by the upstream project.

## Project structure

```text
flipper-zero-apps/
├── firmware/                  # official Flipper Zero firmware repo (submodule)
├── applications_user/         # external app source tree for .fap builds
│   └── example_hello/
│       ├── application.fam
│       └── hello_app.c
├── scripts/
│   └── bootstrap-flipper.sh
├── .gitmodules
├── README.md
└── .gitignore
```

## Build your app

After the environment is ready:

```bash
cd firmware
./fbt fap_{app_id}
```

For the sample app included here, the app ID is `example_hello`, so the command is:

```bash
cd firmware
./fbt fap_example_hello
```

The resulting `.fap` file will be generated in the build output directory used by the official firmware build system.

## Notes

- The official firmware repo is the canonical dependency for building FAPs.
- Keep external app code inside `applications_user/` when you want it to be picked up by the official build system.
- Add your own package/families to `application.fam` files when creating additional apps.
