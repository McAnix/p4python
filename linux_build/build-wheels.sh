#!/bin/bash
set -e -x

export PATH=$PATH:/work/p4-bin/bin.linux26x86_64/

# Extract the p4api and set the P4API path var
mkdir -p /work/p4-api
tar xvfz /work/p4-bin/bin.linux26x86_64/p4api-glibc2.3-openssl1.1.1.tgz -C /work/p4-api
P4API=`echo /work/p4-api/p4api-20*`

cd /work/p4-python
mkdir repair

# Compile wheels
for VERSION in $1; do
	PYBIN="/opt/python/$(ls /opt/python/ | grep $VERSION | grep -v 27mu)/bin"

	## Make tgz
	"${PYBIN}/python" setup.py build_ext --apidir $P4API --ssl /openssl/lib sdist --formats=gztar --keep-temp

	## Make object files for installer
	"${PYBIN}/python" setup.py build --apidir $P4API --ssl /openssl/lib
	"${PYBIN}/python" setup.py install_egg_info --install-dir build

	## Test the build
	"${PYBIN}/python" p4test.py

	## Build the installer
	"${PYBIN}/python" setup.py build_ext --apidir $P4API --ssl /openssl/lib bdist_wheel

	## Repair wheel with new ABI tag manylinux2010_x86_64
	auditwheel repair dist/p4python-*-linux_x86_64.whl --plat manylinux2010_x86_64 -w repair

	rm -rf build p4python.egg-info dist
done
