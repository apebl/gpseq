# Building gpseq

## Build requirements

- valac
- meson >= 0.49
- ninja (or other meson backend to use)
- g-ir-compiler and *.gir of the dependencies (optional; to build typelib)
- valadoc (optional; to build documentation)
- gtk-doc-tools (optional; to build gtkdoc)

### Dependencies

- glib-2.0 >= 2.36
- gobject-2.0 >= 2.36
- gee-0.8 >= 0.18

## Build

```sh
cd <project-root>
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
meson test -C _build -t 20 --print-errorlogs --verbose
```

### Install

Run `ninja install -C _build` after meson build.

To uninstall: `ninja uninstall -C _build`

You can specify the installation prefix by adding a `--prefix` option to meson
build:

```sh
meson _build --buildtype=release --prefix=/usr
ninja install -C _build
```

### Build options

See meson_options.txt.
