#!/bin/bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export ROOT

python3 - <<'PY'
import errno
import os
from pathlib import Path
import pty
import select
import subprocess
import tempfile
import time

root = Path(os.environ['ROOT'])
package = root / 'pkgbuilds/omashiri-settings'
with tempfile.TemporaryDirectory() as directory:
    scratch = Path(directory)
    banner = scratch / 'banner'
    banner.write_text('#!/bin/bash\necho MOTD-CALLED\n')
    banner.chmod(0o755)
    hook = scratch / 'hook'
    hook.write_text((package / 'omashiri-motd.sh').read_text().replace('/usr/bin/omashiri-motd', str(banner)))
    env = dict(os.environ, HOME=directory, TERM='xterm')
    for name in ['TMUX', 'SSH_ORIGINAL_COMMAND', 'OMARCHY_BBS_SESSION', 'OMASHIRI_MOTD_SHOWN']:
        env.pop(name, None)
    command = f'. {hook}; . {hook}'

    def login(extra=None):
        pid, fd = pty.fork()
        if pid == 0:
            os.execve('/bin/bash', ['bash', '--noprofile', '--norc', '--login', '-i', '-c', command], env | (extra or {}))
        output = b''
        deadline = time.monotonic() + 5
        try:
            while True:
                if not select.select([fd], [], [], max(0, deadline - time.monotonic()))[0]:
                    os.kill(pid, 9)
                    raise AssertionError('login hook timed out')
                try:
                    chunk = os.read(fd, 4096)
                except OSError as error:
                    if error.errno == errno.EIO:
                        break
                    raise
                if not chunk:
                    break
                output += chunk
        finally:
            os.close(fd)
            os.waitpid(pid, 0)
        return output

    assert login().count(b'MOTD-CALLED') == 1, 'interactive login prints once'
    for extra in [{'TMUX': 'session'}, {'SSH_ORIGINAL_COMMAND': 'rsync --server'}, {'OMARCHY_BBS_SESSION': '1'}, {'OMASHIRI_MOTD_SHOWN': '1'}]:
        assert b'MOTD-CALLED' not in login(extra), extra
    (scratch / '.hushlogin').touch()
    assert b'MOTD-CALLED' not in login(), 'hushlogin suppresses banner'
    result = subprocess.run(['bash', '-c', command], env=env, capture_output=True, check=True)
    assert not result.stdout, 'noninteractive commands remain silent'
    stub = scratch / 'systemctl'
    stub.write_text('#!/bin/bash\nexit 1\n')
    stub.chmod(0o755)
    result = subprocess.run(['bash', str(package / 'omashiri-motd')], env=env | {'NO_COLOR': '1', 'PATH': f'{scratch}:' + env['PATH']}, capture_output=True, timeout=15, check=True)
    assert b'the AI server distro' in result.stdout
    assert b'\x1b' not in result.stdout, 'NO_COLOR/plain output has no escapes'
    assert b'unavailable' in result.stdout, 'failed service queries never report all green'
print('PASS: MOTD login guards, deduplication, plain rendering and unavailable service status')
PY
