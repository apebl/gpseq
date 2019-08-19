test_sources = files(
	'AtomicTests.vala',
	'BlockingTests.vala',
	'FutureTests.vala',
	'IntSeqTests.vala',
	'NullableIntSeqTests.vala',
	'NullableStringSeqTests.vala',
	'ObjSeqTests.vala',
	'SeqTests.vala',
	'StringSeqTests.vala',
	'SubArrayTests.vala',
	'TestSuite.vala',
	'TestTaskEnv.vala',
	'TestUtils.vala',
	'TestUtilsTests.vala',
	'UtilsTests.vala',
	'test.vala'
)

test_deps = [
	gpseq_dep
]

gpseq_test = executable('gpseq-test', test_sources,
	dependencies: [dependencies, test_deps],
	vala_args: vala_args)
test('test', gpseq_test)
