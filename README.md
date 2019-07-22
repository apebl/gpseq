# gpseq

[![pipeline status](https://gitlab.com/kosmospredanie/gpseq/badges/master/pipeline.svg?style=flat-square)](https://gitlab.com/kosmospredanie/gpseq/commits/master)
[![coverage report](https://gitlab.com/kosmospredanie/gpseq/badges/master/coverage.svg?style=flat-square)](https://gitlab.com/kosmospredanie/gpseq/-/jobs/artifacts/master/file/coverage/index.html?job=test)

Gpseq is a GObject utility library providing parallel data processing.

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

Read [wiki](https://gitlab.com/kosmospredanie/gpseq/wikis),
[snippets](https://gitlab.com/kosmospredanie/gpseq/snippets),
[valadoc](https://gitlab.com/kosmospredanie/gpseq/-/jobs/artifacts/master/file/valadoc/index.html?job=build),
and [gtkdoc (C API)](https://gitlab.com/kosmospredanie/gpseq/-/jobs/artifacts/master/file/gtkdoc/html/index.html?job=build).

## Features

- Work-stealing task scheduling
- Fork-join parallelism
- Functional programming for data processing with parallel execution support --
like Java's streams or C#'s LINQ
- Parallel sorting
- 64-bit atomic operations
- Futures and promises
- Optional objects
- Overflow safe arithmetic functions for signed integers
- ...

## Examples

### iterate, collectors, and sequential operations

```vala
using Gpseq;
using Gpseq.Collectors;

void main () {
	var list = Seq.iterate<int>(0, i => i < 100, i => ++i)
		.parallel()
		.filter(i => i%2 == 0)
		.limit(5)
		.collect( to_list<int>() )
		.value; // Gpseq.Future.value

	// Sequential (non-parallel) operations do not have to wait()
	Seq.of_list<int>(list).foreach(g => print("%d ", g));
}

// output:
// 0 2 4 6 8
```

### Error handling

```vala
try {
	Seq.iterate<int>(0, i => i < 100, i => ++i)
		.parallel()
		.foreach(i => {
			if (i == 42) {
				throw new OptionalError.NOT_PRESENT("%d? Oops!", i);
			}
		}).wait(); // Gpseq.Future.wait() throws Error
} catch (Error err) {
	error(err.message);
}

// ERROR: 42? Oops!
```

### Parallel array sorting

```vala
var arr = new GenericArray<int>();
Seq.iterate<int>(9999, i => i >= 0, i => --i).foreach(i => arr.add(i));
Seq.of_generic_array<int>(arr)
	.limit(5)
	.foreach(g => print("%d ", g))
	.and_then(g => print("\n"));
// 9999 9998 9997 9996 9995

parallel_sort<int>(arr.data).wait();
Seq.of_generic_array<int>(arr)
	.limit(5)
	.foreach(g => print("%d ", g))
	.and_then(g => print("\n"));
// 0 1 2 3 4
```

### Work-stealing task scheduling

```vala
using Gpseq;

void main () {
	Future<string> future = task<string>(() => "What's up?");
	print("%s\n", future.value); // What's up?
}
```

```vala
using Gpseq;

void main () {
	int sum = 0;
	Future<void*> future = Future.of<void*>(null);

	for (int i = 0; i < 100; i++) {
		var f = task<void*>(() => {
			AtomicInt.inc(ref sum);
			return null;
		});
		future = future.flat_map(val => f);
	}

	future.wait();
	print("%d\n", sum); // 100
}
```

## License

Gpseq is free software: you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your
option) any later version.

Gpseq is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
License for more details.

You should have received a copy of the GNU Lesser General Public License
along with Gpseq.  If not, see <http://www.gnu.org/licenses/>.

### Libgee

Gpseq uses a modified version of timsort.vala of libgee.
See [TimSort.vala](src/TimSort.vala) and [COPYING-libgee](COPYING-libgee).
