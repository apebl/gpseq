benchmark_sources = files(
	'benchmark-fmf.vala',
	'benchmark-sort.vala',
	'benchmark.vala',
	'benchmarks.vala',
	'utils.vala'
)

benchmark_deps = [
	gpseq_dep,
	dependency('gio-2.0', version: '>=2.36')
]

executable('gpseq-benchmark', benchmark_sources,
	dependencies: [dependencies, benchmark_deps],
	vala_args: vala_args)
