# gpseq

[![pipeline status](https://gitlab.com/kosmospredanie/gpseq/badges/master/pipeline.svg?style=flat-square)](https://gitlab.com/kosmospredanie/gpseq/commits/master)
[![coverage report](https://gitlab.com/kosmospredanie/gpseq/badges/master/coverage.svg?style=flat-square)](https://gitlab.com/kosmospredanie/gpseq/-/jobs/artifacts/master/file/coverage/index.html?job=test)

Gpseq is a parallelism library for Vala and GObject.

```vala
using Gpseq;

void main () {
    string[] array = {"dog", "cat", "pig", "boar", "bear"};
    Seq.of_array<string>(array)
        .parallel()
        .filter(g => g.length == 3)
        .map<string>(g => g.up())
        .foreach(g => print("%s\n", g))
        .wait();
}

// (possibly unordered) output:
// DOG
// CAT
// PIG
```

## Features

- [*Work-stealing*](https://en.wikipedia.org/wiki/Work_stealing) and *managed
blocking* task scheduling: Similar behavior to Go scheduler
- Functional programming for data processing with parallel execution support:
An equivalent to Java's
[streams](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/stream/Stream.html)
- [Fork-join](https://en.wikipedia.org/wiki/Fork–join_model) parallelism
- Parallel sorting
- [Futures and promises](https://en.wikipedia.org/wiki/Futures_and_promises)
- 64-bit atomic operations
- Overflow safe arithmetic functions for signed integers
- ...

## Documentation

Read [wiki](https://gitlab.com/kosmospredanie/gpseq/wikis),
[valadoc](https://gitlab.com/kosmospredanie/gpseq/-/jobs/artifacts/master/file/valadoc/index.html?job=build),
and [gtkdoc (C API)](https://gitlab.com/kosmospredanie/gpseq/-/jobs/artifacts/master/file/gtkdoc/html/index.html?job=build).

There is a developer's guide in the wiki.

## Install

See the [installation guide](INSTALL.md).

## License

Gpseq is released under the [LGPL 3.0 license](COPYING).

### Libgee

Gpseq uses a modified version of timsort.vala of libgee.
See [TimSort.vala](src/TimSort.vala) and [COPYING-libgee](COPYING-libgee).
