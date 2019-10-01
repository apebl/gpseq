# Contributing

## Commit Message Guidelines

Each commit message should be structured as follows:

```
<type>[(optional scope)]: <subject>

[optional body]
```

The first line is the header that should not be longer than 50 characters. And
you must wrap the body at 72 characters. The body can have multiple paragraphs.

The body can have the text `BREAKING CHANGE:` at the beginning of a line to
introduce a breaking API/ABI change. A BREAKING CHANGE can be part of commits
of any type.

The commit of which header or body have `#<issue-number>` is linked to the
issues. You can also close issues automatically using issue closing pattern --
`(Fixes|Closes|Resolves|Implements) #<issue-number>` in the body.

### Subject

Begin with a capital letter, use the imperative mood, and do not end with
a period.

Good:
- Add feature

Bad:
- add feature
- Add feature.
- Added feature
- Adds feature
- Adding feature
- Feature added

### Scope

There are no scopes at this time.

### Type

Must be one of the following:

- feat: A new feature
- fix: A bug fix
- refactor: Refactoring production code
- perf: A code change that improves performance
- docs: Documentation only changes
- style: Changes that do not affect the meaning of the code (white-space,
formatting, etc.)
- deps: Updating dependencies
- revert: Reverting a previous commit
- build: Changes that affect the build system
- ci: Changes to CI configuration
- test: Adding missing tests or correcting existing tests
- release: Changes to release new version (version string changes, etc.)
- chore: Other changes with no production code change
