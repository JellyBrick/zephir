#!/bin/sh
#
# This file is part of the Zephir.
#
# (c) Zephir Team <team@zephir-lang.com>
#
# For the full copyright and license information, please view
# the LICENSE file that was distributed with this source code.

if [ "$(command -v valgrind 2>/dev/null)" = "" ]; then
  (>&2 echo "Valgring does not exist. Can not check for memory leaks.")
  (>&2 echo "Aborting.")
  exit 1
fi

# Correctly show the stack frames for extensions compiled as shared libraries
export ZEND_DONT_UNLOAD_MODULES=1

# Disable Zend memory manager before running PHP with valgrind
export USE_ZEND_ALLOC=0

# Do not stop testing on failures
export PHPUNIT_DONT_EXIT=1

valgrind \
  --read-var-info=yes \
  --error-exitcode=1 \
  --fullpath-after= \
  --track-origins=yes \
  --leak-check=full \
  --num-callers=20 \
  --run-libc-freeres=no \
  "$(phpenv which php)" \
    -d "extension=ext/modules/test.so" \
      "unit-tests/phpunit" \
      --no-coverage \
      --testsuite "Extension Test Suite"
