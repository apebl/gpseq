# Building gpseq

## Build requirements

- valac
- meson >= 0.49
- ninja (or other meson backend to use)
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

### Build documentations

After build:

```sh
meson --reconfigure _build -Dbuild_doc=valadoc,gtkdoc
ninja -C _build
```

- Build valadoc: `-Dbuild_doc=valadoc`
- Build gtkdoc: `-Dbuild_doc=gtkdoc`
- Build both: `-Dbuild_doc=valadoc,gtkdoc`

### Test

After meson build:

```sh
meson test -C _build -t 20 --print-errorlogs --verbose
```

### Install

Run `ninja install -C _build` after meson build.

To uninstall: `ninja uninstall -C _build`

### Build options

See meson_options.txt.
