#!/bin/bash

set -e

EXIT_CODE=0

run_gpgv() {
    set +e
    "$@" gpgv --verbose --status-fd 3 \
	--keyring /usr/share/keyrings/cybint-archive-keyring.gpg \
	debian/tests/signed-data.txt \
	>$AUTOPKGTEST_TMP/stdout \
	2>$AUTOPKGTEST_TMP/stderr \
	3>$AUTOPKGTEST_TMP/status
    GPGV_EXIT_CODE=$?
    set -e
    if [ "$GPGV_EXIT_CODE" != "0" ]; then
	echo "ERROR: gpgv failed unexpectedly"
	echo "-- STDOUT --":
	cat $AUTOPKGTEST_TMP/stdout
	echo "-- STDERR --"
	cat $AUTOPKGTEST_TMP/stderr
	echo "-- STATUS-FD --"
	cat $AUTOPKGTEST_TMP/status
	EXIT_CODE=1
    fi
}

ensure_expired() {
    if ! grep -qE "\[GNUPG:\] EXPKEYSIG [A-F0-9]+ CYBINT (CYBINT Linux) <coder@cybint-linux.com>" $AUTOPKGTEST_TMP/status;
    then
	echo "ERROR: signature key was not detected as expired"
	EXIT_CODE=1
    fi
}
ensure_non_expired() {
    if ! grep -qE "\[GNUPG:\] GOODSIG [A-F0-9]+ CYBINT (CYBINT Linux) <coder@cybint-linux.com>" $AUTOPKGTEST_TMP/status;
    then
	echo "ERROR: signature key was not detected as good"
	EXIT_CODE=1
    fi
}

echo "1 - Checking signature at current time"
run_gpgv
ensure_non_expired

echo ""
echo "2 - Ensure we have at least one year before key expires by checking it one year in the future"
run_gpgv faketime +1year
ensure_non_expired

echo ""
echo "3 - Ensure the key eventually expires by checking signature 5 years in the future"
run_gpgv faketime +5years
ensure_expired

exit $EXIT_CODE
