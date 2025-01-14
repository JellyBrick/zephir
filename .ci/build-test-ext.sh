#!/usr/bin/env bash
#
# This file is part of the Zephir.
#
# (c) Zephir Team <team@zephir-lang.com>
#
# For the full copyright and license information, please view
# the LICENSE file that was distributed with this source code.

# -e  Exit immediately if a command exits with a non-zero status.
# -u  Treat unset variables as an error when substituting.
set -eu

# This allows the configuration of the executable path as follows:
#   ZEPHIR_BIN=zephir.phar .ci/build-test-ext.sh
#   ZEPHIR_BIN=./zephir .ci/build-test-ext.sh
: "${ZEPHIR_BIN:=zephir}"

# Some defaults
: "${REPORT_COVERAGE:=0}"
: "${CFLAGS:=}"
: "${CXXFLAGS:=}"
: "${LDFLAGS:=}"

$ZEPHIR_BIN clean 2>&1 || exit 1
$ZEPHIR_BIN fullclean 2>&1 || exit 1

# TODO: Export ZFLAGS and process by Config class
ZFLAGS=""
# ZFLAGS="${ZFLAGS} -Wnonexistent-function -Wnonexistent-class -Wunused-variable -Wnonexistent-constant"
# ZFLAGS="${ZFLAGS} -Wunreachable-code -Wnot-supported-magic-constant -Wnon-valid-decrement"

$ZEPHIR_BIN generate ${ZFLAGS} 2>&1 || exit 1
$ZEPHIR_BIN stubs ${ZFLAGS} 2>&1 || exit 1
$ZEPHIR_BIN api ${ZFLAGS} 2>&1 || exit 1

cd ext || exit 1

phpize

if [ "$REPORT_COVERAGE" -eq 1 ]
then
  CFLAGS=${CFLAGS//-O[0-9s]/}
  CXXFLAGS=${CXXFLAGS//-O[0-9s]/}
  LDFLAGS=${LDFLAGS//--coverage/}

  LDFLAGS="${LDFLAGS} --coverage"
  CFLAGS="${CFLAGS} -O0 -ggdb -fprofile-arcs -ftest-coverage"
  CXXFLAGS="${CXXFLAGS} -O0 -ggdb -fprofile-arcs -ftest-coverage"
fi

if [ -n "$CFLAGS" ] && [ -n "$LDFLAGS" ]
then
  ./configure --enable-test CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
else
  ./configure --enable-test
fi

make -j"$(getconf _NPROCESSORS_ONLN)" #2> ./compile-errors.log
exitcode=$?

test "$exitcode" = 0 || {
  test -f ./compile-errors.log && cat ./compile-errors.log
}

exit $exitcode
