# Building gpseq

## Build requirements

Required:

- valac >= 0.39.6
- meson >= 0.49
- ninja (or other meson backend to use)

Optional:

- g-ir-compiler and *.gir of the dependencies (optional; to build typelib)
- valadoc (optional; to build documentation)
- gtk-doc-tools (optional; to build gtkdoc)

### Dependencies

- glib-2.0 >= 2.36
- gobject-2.0 >= 2.36
- gee-0.8 >= 0.18

## Build

```sh
cd gpseq
meson _build --buildtype=release
ninja -C _build
```

In order to build documentations, add the `-Ddocs` option.

- Build valadoc: `-Ddocs=valadoc`
- Build gtkdoc: `-Ddocs=gtkdoc`
- Build both: `-Ddocs=valadoc,gtkdoc`

### Test

After meson build:

```sh
meson test -C _build -t 100 --print-errorlogs --verbose
```

### Install

Run (sudo) `ninja -C _build install` after meson build.

To uninstall: (sudo) `ninja -C _build uninstall`

You can specify the installation prefix by adding a `--prefix` option to meson
build:

```sh
meson _build --buildtype=release --prefix=/usr
sudo ninja -C _build install
```

### Build options

See [meson_options.txt](meson_options.txt).
