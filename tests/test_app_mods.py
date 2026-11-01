"""The Mods entry is shown and opens from touch navigation, then backs out cleanly."""
import os
import subprocess
import sys
import tempfile
with tempfile.TemporaryDirectory() as cache:
    r = subprocess.run([sys.argv[1], "--cache", cache], env=dict(os.environ,
        SDL_VIDEO_DRIVER="dummy", SDL_AUDIO_DRIVER="dummy",
        ORACLES_TEST_KEYS="10:Right,20:Down,30:Up,40:^Setting.21,50:Z,60:Z,70:Z"),
        capture_output=True, text=True, timeout=20)
    assert r.returncode == 0, r.stderr
    assert "test tap: no Setting.21" not in r.stderr, r.stderr
print("app mods: entry is shown")
