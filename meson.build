project('gpseq', 'vala', 'c',
	version: '0.1.0-alpha',
	license: 'LGPL3',
	meson_version: '>=0.49.0')

project_desc = 'A GObject utility library providing parallel data processing'

version_ary = meson.project_version().split('.')
api_version = '@0@.@1@'.format(version_ary[0], version_ary[1])

libname = 'gpseq-@0@'.format(api_version)
Libname = 'Gpseq-@0@'.format(api_version)

message('gpseq version: ' + meson.project_version())
message('api version: ' + api_version)

cc = meson.get_compiler('c')

m_dep = cc.find_library('m', required: false)
glib_reqs = '2.36'
glib_dep = dependency('glib-2.0', version: '>=' + glib_reqs)
gobject_reqs = '2.36'
gobject_dep = dependency('gobject-2.0', version: '>=' + gobject_reqs)
gee_reqs = '0.18'
gee_dep = dependency('gee-0.8', version: '>=' + gee_reqs)

dependencies = [
	m_dep,
	glib_dep,
	gobject_dep,
	gee_dep
]

pkg_requires = [
	'glib-2.0 >= ' + glib_reqs,
	'gobject-2.0 >= ' + gobject_reqs,
	'gee-0.8 >= ' + gee_reqs
]

vala_args = [
	'--target-glib=' + glib_reqs,
	'--enable-experimental',
	'--verbose'
]

subdir('src')
subdir('tests')
if get_option('build_benchmark')
	subdir('benchmark')
endif

if get_option('build_doc').length() > 0
	valadoc = find_program('valadoc')
	doc_cmd_base = [valadoc,
		'--package-name=' + libname,
		'--package-version=' + meson.project_version(),
		'--target-glib=' + glib_reqs,
		'--force',
		'--pkg=glib-2.0',
		'--pkg=gobject-2.0',
		'--pkg=gee-0.8',
		'--directory=@OUTPUT@',
		'@INPUT@'
	]

	if get_option('build_doc').contains('valadoc')
		valadoc_cmd = [doc_cmd_base, '--doclet=html']
		custom_target('valadoc', command: valadoc_cmd,
			input: sources,
			output: 'valadoc',
			depends: gpseq_lib,
			install: true,
			install_dir: get_option('datadir') / 'doc' / libname)
	endif

	if get_option('build_doc').contains('gtkdoc')
		gtkdoc_cmd = [doc_cmd_base,
			'--doclet=gtkdoc',
			'--doclet-arg=' + (meson.current_build_dir() / 'src' / (meson.project_name() + '.h'))
		]
		custom_target('gtkdoc', command: gtkdoc_cmd,
			input: sources,
			output: 'gtkdoc',
			depends: gpseq_lib,
			install: true,
			install_dir: get_option('datadir') / 'doc' / libname)
	endif
endif
