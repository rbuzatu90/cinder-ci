#!/bin/bash

job_type=$1

cd /opt/stack/tempest

testr init

TEMPEST_DIR="/home/ubuntu/tempest"
EXCLUDED_TESTS="$TEMPEST_DIR/excluded_tests.txt"
RUN_TESTS_LIST="$TEMPEST_DIR/test_list.txt"
mkdir -p "$TEMPEST_DIR"

if [ $job_type = "iscsi" ]; then
    testr list-tests | grep volume | grep -v "tempest.api.volume.test_volumes_actions.VolumesV\|volume.admin.test_volume_types.VolumeTypes" > "$RUN_TESTS_LIST"
    res=$?
    if [ $res -ne 0 ]; then
        echo "failed to generate list of tests"
        exit $res
    fi
else
    testr list-tests | grep volume | grep -v "test_volume_boot_pattern\|volume.admin.test_volume_types.VolumeTypes" > "$RUN_TESTS_LIST"
    res=$?
    if [ $res -ne 0 ]; then
        echo "failed to generate list of tests"
        exit $res
    fi
fi

testr run --parallel --subunit  --load-list=$RUN_TESTS_LIST  > /home/ubuntu/tempest/subunit-output.log 2>&1
cat /home/ubuntu/tempest/subunit-output.log | subunit-trace -n -f > /home/ubuntu/tempest/tempest-output.log 2>&1
# testr exits with status 0. colorizer.py actually sets correct exit status
RET=$?
cd /home/ubuntu/tempest/
python /home/ubuntu/bin/subunit2html.py /home/ubuntu/tempest/subunit-output.log

exit $RET
