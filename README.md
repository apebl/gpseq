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

```vala
using Gpseq;

void main () {
    Channel<string> chan = Channel.bounded<string>(0);
    run( () => chan.send("ping").ok() );
    print("%s\n", chan.recv().value);
}

// output:
// ping
```

## Features

- Work-stealing task scheduling with managed blocking
- Functional programming for data processing with parallel execution support (Seq)
- Unbuffered, buffered, and unbounded MPMC channels
- Fork-join parallelism
- Parallel sorting
- Futures and promises
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
