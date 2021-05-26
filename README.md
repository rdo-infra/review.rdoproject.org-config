# Test dependency management

To achieve reproducible test results on both development and CI environments,
we do lock/pin all test dependencies inside `test-requirements.txt`. This is
used as a pip **constraints** file inside various tox environments so
it will only force pip to directly pick specific versions instead of trying
to resolve them at runtime.

The file is automatically updated when you run `tox -e deps`, an action
that we will do whenever we find a need for a dependency bump. The real
source files for dependencies are `test-requirements.in` and this is the
place where we define compatibility ranges.

Many applications are using the same approach for locking their entire set
of dependencies, not only the test ones. Still for our particular use-case,
we get most benefits from doing this only for test ones.

There is no `tox-deps` zuul job because it does not make sense to run it on CI.
With 20+ test dependencies on average we have at least one dependency updated
each day. We don't really need to run bleeding edge and be the first line of
defense for all these libraries. Still, whenever we want we can update them
with a single command, making testing much easier.

These test constraints files are not shared across repositories for good
reasons, they are specific to each repo and affect testing of a single
repository. If we would attempt to centralize them we will create a case
were they are almost impossible to update, due to the huge amount of testing
needed. There is nothing wrong using outdated **test** dependencies, especially
when is so easy to control their upgrades.

References:

* [pip-tools](https://pypi.org/project/pip-tools/) which provides pip-compile
