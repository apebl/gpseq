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
		.wait(); // Gpseq.Future.wait() throws Error
}

// (possibly unordered) output:
// DOG
// CAT
// PIG
```

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
	Seq.of_list<int>(list).foreach(g => print("%d ", g));
}

// output:
// 0 2 4 6 8
```

```vala
Seq.iterate<int>(0, i => i < 100, i => ++i)
	.parallel()
	.foreach(i => {
		if (i == 42) {
			throw new OptionalError.NOT_PRESENT("%d? Oops!", i);
		}
	}).wait();
// uncaught error: 42? Oops!
```

See [valadoc](https://gitlab.com/kosmospredanie/gpseq/-/jobs/artifacts/master/file/valadoc/index.html?job=build)
and [gtkdoc](https://gitlab.com/kosmospredanie/gpseq/-/jobs/artifacts/master/file/gtkdoc/html/index.html?job=build).

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
