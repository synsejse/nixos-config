#!/usr/bin/env python3
"""Check the actual daemon setter against successful and failed file writes.

Pass the path to dbus_services/dbus_methods/mamba.py in the patched daemon.
No daemon, D-Bus service or hardware is started.
"""
import ast
from pathlib import Path
import sys
from types import SimpleNamespace
from unittest.mock import Mock, mock_open

tree = ast.parse(Path(sys.argv[1]).read_text())
function = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == 'set_poll_rate')
function.decorator_list = []
module = ast.Module(body=[function], type_ignores=[])


def exercise(failure=None):
    opener = mock_open()
    if failure == 'open':
        opener.side_effect = OSError('open failed')
    elif failure == 'write':
        opener.return_value.write.side_effect = OSError('write failed')
    elif failure == 'close':
        opener.return_value.__exit__.side_effect = OSError('close failed')
    namespace = {'open': opener}
    exec(compile(module, '<actual daemon setter>', 'exec'), namespace)
    device = SimpleNamespace(logger=Mock(), POLL_RATES=[125,500,1000,2000,4000,8000],
                             poll_rate=1000, get_driver_path=lambda name: '/sys/test/' + name)
    try:
        namespace['set_poll_rate'](device, 8000)
    except OSError:
        assert failure is not None
    else:
        assert failure is None
    assert device.poll_rate == (1000 if failure else 8000), (failure, device.poll_rate)
    opener.assert_called_once_with('/sys/test/poll_rate', 'w')
    if failure is None:
        opener.return_value.write.assert_called_once_with('8000')
    opener.reset_mock()
    try:
        namespace['set_poll_rate'](device, 999)
    except RuntimeError:
        pass
    else:
        raise AssertionError('Unsupported rate was accepted')
    opener.assert_not_called()


for failure in [None, 'open', 'write', 'close']:
    exercise(failure)
print('PASS: polling cache changes only after a successful, closed sysfs write')
