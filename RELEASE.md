# Releasing

## Vendoring Python 3

cloud.gov maintains a BOSH release for vendoring Python 3 into other BOSH releases:

<https://github.com/cloud-gov/cg-python3-boshrelease>

## Adding blobs for wheels of Python dependencies

Some of the jobs in this release, such as `curator`, are directly invoked from
a Python package. To prevent BOSH from having to `pip install` to get dependencies
for Python packages and produce deterministic builds, the Python wheel files (`*.whl`)
are vendored and included as blobs in this release.

To add or update the Python wheels for dependencies as blobs, use the included
script:

```shell
./scripts/add_python_wheel_blobs <package_name>
```

## Building BOSH releases

See <https://github.com/cloud-gov/internal-docs/blob/main/runbooks/building-bosh-releases.md>
