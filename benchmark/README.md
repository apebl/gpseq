# Benchmark

Build and run benchmark:

```sh
cd <project-root>
meson _build --buildtype=release -Dbenchmark=true
ninja -C _build
cd benchmark
../_build/benchmark/gpseq-benchmark
```

And show a result graph:

```sh
gnuplot *.gp # Creates *.png files
```
