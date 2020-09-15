#!/usr/bin/env python3

import fileinput
import json
import re

current_run = None

for line in fileinput.input():
    m = re.match('experiments.py::test_([^[]*)\[([^-]*)-([^-]*)(-([^-]*)-([^-]*))?\]', line)
    if m:
        assert current_run is None
        query, cluster_size, input_size, run_num = m.group(1, 2, 3, 5)

        run_num = int(run_num) or 1
        query = query.replace('_', '-').replace('count', 'count-star')

        current_run = {
            'system': 'snowflake',
            'platform': 'cluster',
            'input_size': input_size,
            'query': query,
            'run_num': run_num,
        }

        continue

    m = re.match('.*Time: ([0-9.]+)s, query id: ([-0-9a-f]+)', line)
    if m:
        running_time, query_id = m.group(1, 2)

        if current_run is not None:
            current_run['running_time'] = float(running_time)
            current_run['query_id'] = query_id

        continue

    if line.startswith('PASSED'):
        current_run['exit_code'] = 0
        print(json.dumps(current_run))
        current_run = None
