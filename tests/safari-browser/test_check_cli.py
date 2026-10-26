"""Behavior tests for plugins/safari-browser/hooks/check-cli.sh (PsychQuant/safari-browser#280).

The hook runs at every session start and says whether the installed CLI is older than
the source checkout. It is run here as a real process against a throwaway HOME holding a
fake `~/bin/safari-browser` and a real, tiny git repository standing in for the checkout.
`curl`, `wget` and `gh` on PATH are shims that record any call as a failure (the hook is
offline by design and never installs anything), and `git` is a shim that records every
argument list before running the real git, so a test can say what reached git.

macOS only (the hook uses BSD `stat -f` and `date -r`, as it always has).
"""
import os
import shutil
import stat
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HOOK = ROOT / 'plugins/safari-browser/hooks/check-cli.sh'
REAL_GIT = shutil.which('git')

DAY = 86400
T0 = 1767225600  # 2026-01-01T00:00:00Z

GIT_ENV = {
    'GIT_CONFIG_GLOBAL': os.devnull,
    'GIT_CONFIG_SYSTEM': os.devnull,
    'GIT_AUTHOR_NAME': 't',
    'GIT_AUTHOR_EMAIL': 't@example.com',
    'GIT_COMMITTER_NAME': 't',
    'GIT_COMMITTER_EMAIL': 't@example.com',
}
# A caller's git environment (a hook exports these) would send the fixture's commits
# into another repository.
LEAKY_GIT_VARS = ('GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_COMMON_DIR',
                  'GIT_OBJECT_DIRECTORY', 'GIT_NAMESPACE')


def git(repo, *args, date=None):
    env = {k: v for k, v in os.environ.items() if k not in LEAKY_GIT_VARS}
    env.update(GIT_ENV)
    if date is not None:
        env['GIT_AUTHOR_DATE'] = env['GIT_COMMITTER_DATE'] = f'{date} +0000'
    result = subprocess.run([REAL_GIT, '-C', str(repo), *args], check=True,
                            capture_output=True, text=True, env=env)
    return result.stdout.strip()


def alive(pid):
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


class CheckCliTestCase(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.home = self.root / 'home'
        self.binary = self.home / 'bin/safari-browser'
        self.checkout = self.home / 'Developer/safari-browser'
        self.binary.parent.mkdir(parents=True)
        self.checkout.parent.mkdir(parents=True)
        self.tmpdir = self.root / 'tmp'
        self.tmpdir.mkdir()
        self.network_log = self.root / 'network.log'
        self.git_log = self.root / 'git.log'
        self.shims = self.root / 'shims'
        self.shims.mkdir()
        for tool in ('curl', 'wget', 'gh'):
            self.write_executable(self.shims / tool,
                                  f'#!/bin/sh\necho "{tool} $*" >> "{self.network_log}"\nexit 1\n')
        self.write_executable(self.shims / 'git',
                              f'#!/bin/sh\nfor a in "$@"; do printf \'%s\\n\' "$a"; done >> "{self.git_log}"\n'
                              f'exec "{REAL_GIT}" "$@"\n')

    @staticmethod
    def write_executable(path, text):
        path.write_text(text)
        path.chmod(path.stat().st_mode | stat.S_IXUSR)

    # --- the fake CLI ------------------------------------------------------------
    def install(self, behavior, age_days=None):
        """behavior: a version string, 'unsupported' (an old binary), 'hang',
        'ignore-term' (hangs and ignores SIGTERM), or 'grandchild' (hangs and leaves a
        child process of its own)."""
        pidfile = self.root / 'probe.pid'
        if behavior == 'unsupported':
            answer = 'echo "Error: Unknown option \'--version\'" >&2; exit 64'
        elif behavior == 'hang':
            answer = 'exec sleep 60'
        elif behavior == 'hang-pid':
            answer = f"echo $$ > '{pidfile}'; exec sleep 60"
        elif behavior == 'ignore-term':
            answer = f"trap '' TERM; echo $$ > '{pidfile}'; exec sleep 60"
        elif behavior == 'grandchild':
            answer = f"sleep 61 & echo $! > '{pidfile}'; sleep 62"
        else:
            answer = f"printf '%s\\n' '{behavior}'"
        self.install_script(answer, age_days)

    def install_script(self, answer, age_days=None):
        self.write_executable(self.binary, f'#!/bin/sh\ncase "$1" in\n  --version) {answer} ;;\nesac\nexit 0\n')
        if age_days is not None:
            stamp = T0 + age_days * DAY
            os.utime(self.binary, (stamp, stamp))

    def probe_pid(self):
        return int((self.root / 'probe.pid').read_text().strip())

    # --- the fake checkout ---------------------------------------------------------
    def make_checkout(self, history):
        """history: kinds in order, 'code' (touches Sources/) or 'docs'. Commit i is
        dated T0 + i days. The first commit is tagged v1.0.0. Returns the full hashes."""
        self.checkout.mkdir(exist_ok=True)
        git(self.checkout, 'init', '-q', '-b', 'main', '.')
        hashes = []
        for i, kind in enumerate(history):
            path = self.checkout / ('Sources/a.swift' if kind == 'code' else 'docs/readme.md')
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(f'{i}\n')
            git(self.checkout, 'add', '-A')
            git(self.checkout, '-c', 'commit.gpgsign=false', 'commit', '-q', '-m', f'{kind} {i}', date=T0 + i * DAY)
            hashes.append(git(self.checkout, 'rev-parse', 'HEAD'))
            if i == 0:
                git(self.checkout, 'tag', 'v1.0.0')
        return hashes

    def side_commit(self, base, day):
        """A code commit on a branch `side` off `base`, dated T0 + day; back on main afterwards."""
        git(self.checkout, 'checkout', '-q', '-b', 'side', base)
        (self.checkout / 'Sources/a.swift').write_text('side\n')
        git(self.checkout, '-c', 'commit.gpgsign=false', 'commit', '-q', '-am', 'side work', date=T0 + day * DAY)
        side = git(self.checkout, 'rev-parse', 'HEAD')
        git(self.checkout, 'checkout', '-q', 'main')
        return side

    # --- running the hook -----------------------------------------------------------
    def run_hook(self):
        env = {'HOME': str(self.home), 'PATH': f'{self.shims}:{os.environ["PATH"]}',
               'LANG': 'C', 'TMPDIR': str(self.tmpdir), **GIT_ENV}
        started = time.monotonic()
        try:
            result = subprocess.run([str(HOOK)], env=env, capture_output=True, text=True, timeout=30)
        except subprocess.TimeoutExpired:
            self.fail('the hook did not finish within 30 s: a session start would hang')
        self.elapsed = time.monotonic() - started
        self.stderr = result.stderr
        self.assertEqual(result.returncode, 0, 'the hook must never fail a session start')
        return result.stdout

    def network_calls(self):
        return self.network_log.read_text() if self.network_log.exists() else ''

    def git_args(self):
        return self.git_log.read_text().splitlines() if self.git_log.exists() else []


CODE_DOCS_CODE_DOCS_CODE = ['code', 'docs', 'code', 'docs', 'code']


class NotInstalled(CheckCliTestCase):
    def test_says_so_and_still_exits_zero(self):
        out = self.run_hook()
        self.assertIn('not found at', out)
        self.assertIn('make install-signed', out)


class FreshnessFromTheBuildCommit(CheckCliTestCase):
    """The binary says which commit it was built from; compare that with the checkout."""

    def test_first_line_shows_the_version(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install(f'v1.0.0-4-g{hashes[4][:7]}')
        first = self.run_hook().splitlines()[0]
        self.assertIn(str(self.binary), first)
        self.assertIn(f'v1.0.0-4-g{hashes[4][:7]}', first)

    def test_built_from_the_current_commit_is_silent(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install(f'v1.0.0-4-g{hashes[4][:7]}')
        self.assertNotIn('⬆️', self.run_hook())

    def test_counts_only_commits_that_touch_compiled_code(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)  # after commit 0: code, docs, code, docs, code
        self.install(f'v1.0.0-0-g{hashes[0][:7]}')
        out = self.run_hook()
        self.assertIn('⬆️', out)
        self.assertIn('2 commits touching the compiled code', out)  # not 4

    def test_a_single_commit_is_not_pluralised(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install(f'v1.0.0-2-g{hashes[2][:7]}')
        self.assertIn('1 commit touching the compiled code', self.run_hook())

    def test_commits_after_the_build_that_only_touch_docs_do_not_warn(self):
        hashes = self.make_checkout(['code', 'docs', 'docs'])
        self.install(f'v1.0.0-0-g{hashes[0][:7]}')
        self.assertNotIn('⬆️', self.run_hook())

    def test_a_release_built_exactly_on_its_tag_is_resolved_through_the_tag(self):
        self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install('v1.0.0')
        out = self.run_hook()
        self.assertIn('2 commits touching the compiled code', out)

    def test_a_dirty_suffix_is_shown_and_does_not_break_the_lookup(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install(f'v1.0.0-4-g{hashes[4][:7]}-dirty')
        out = self.run_hook()
        self.assertIn('-dirty', out.splitlines()[0])
        self.assertNotIn('⬆️', out)

    def test_the_hash_alone_decides_when_the_tag_is_unknown_to_the_checkout(self):
        # git resolves `<anything>-<n>-g<hash>` by the hash; the tag name and the count
        # are not consulted, so a tag the checkout lacks does not matter
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install(f'v0.9.0-3-g{hashes[0][:7]}')
        self.assertIn('2 commits touching the compiled code', self.run_hook())

    def test_the_hash_alone_decides_with_a_dirty_suffix_too(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install(f'v0.9.0-3-g{hashes[0][:7]}-dirty')
        self.assertIn('2 commits touching the compiled code', self.run_hook())

    def test_a_build_exactly_on_a_tag_with_uncommitted_changes_still_resolves(self):
        self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install('v1.0.0-dirty')
        out = self.run_hook()
        self.assertIn('v1.0.0-dirty', out.splitlines()[0])
        self.assertIn('2 commits touching the compiled code', out)

    def test_a_bare_commit_hash_is_understood(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install(hashes[2][:7])
        self.assertIn('1 commit touching the compiled code', self.run_hook())

    def test_a_bare_commit_hash_with_a_dirty_suffix_is_understood(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install(f'{hashes[2][:7]}-dirty')
        self.assertIn('1 commit touching the compiled code', self.run_hook())

    def test_a_dirty_build_is_not_told_as_fact_that_the_fixes_are_missing(self):
        # edit, `make install` (the binary says -dirty), then commit: the commits after
        # the build commit may well be in the binary already
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install(f'v1.0.0-2-g{hashes[2][:7]}-dirty')
        out = self.run_hook()
        self.assertIn('1 commit touching the compiled code', out)
        self.assertIn('uncommitted changes', out)
        self.assertNotIn('Fixes merged since the build are not in the installed binary', out)

    def test_the_stale_message_keeps_the_install_hint(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install(f'v1.0.0-0-g{hashes[0][:7]}')
        self.assertIn('make install-signed', self.run_hook())


class WhenTheCommitsCannotBeComparedFileTimesStillDecide(CheckCliTestCase):
    """A build commit the checkout cannot place is said so, and the file-time signal the
    hook used before #280 still decides: a build from a branch that was squash-merged,
    rebased or amended can never become an ancestor of HEAD, and must still be warned
    about once code has landed after it."""

    def test_a_build_from_a_squash_merged_branch_still_warns(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)          # main: code on days 0, 2, 4
        side = self.side_commit(hashes[0], day=1)                       # built from here on day 1
        self.install(f'v1.0.0-1-g{side[:7]}', age_days=1)
        out = self.run_hook()
        self.assertIn('not in the history', out)
        self.assertIn('⬆️', out)
        self.assertIn('older than its source', out)

    def test_a_build_commit_gone_from_the_checkout_still_warns(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        side = self.side_commit(hashes[0], day=1)
        git(self.checkout, 'branch', '-q', '-D', 'side')
        git(self.checkout, 'reflog', 'expire', '--expire=now', '--all')
        git(self.checkout, 'gc', '-q', '--prune=now')
        self.install(f'v1.0.0-1-g{side[:7]}', age_days=1)
        out = self.run_hook()
        self.assertIn('not in', out)
        self.assertIn('⬆️', out)
        self.assertIn('older than its source', out)

    def test_an_unknown_commit_with_a_new_file_is_not_called_stale(self):
        self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install('v1.0.0-9-gdeadbee')                               # file is from today
        out = self.run_hook()
        self.assertIn('not in', out)
        self.assertNotIn('⬆️', out)

    def test_another_branch_with_a_new_file_is_not_called_stale(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        side = self.side_commit(hashes[0], day=9)
        git(self.checkout, 'checkout', '-q', hashes[4])                 # detached on the main line
        self.install(f'v1.0.0-1-g{side[:7]}')
        out = self.run_hook()
        self.assertIn('not in the history', out)
        self.assertNotIn('⬆️', out)

    def test_a_build_newer_than_the_checkout_says_the_checkout_is_behind(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        git(self.checkout, 'checkout', '-q', hashes[2])                 # the checkout is behind the build
        self.install(f'v1.0.0-4-g{hashes[4][:7]}')
        out = self.run_hook()
        self.assertIn('newer than', out)
        self.assertNotIn('another branch', out)
        self.assertNotIn('⬆️', out)


class UntrustedVersionOutput(CheckCliTestCase):
    """Whatever `--version` prints is shown to the user and partly passed to git."""

    def test_option_shaped_output_is_ignored_and_never_reaches_git(self):
        self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install('--output=/tmp/pwned-by-check-cli')
        out = self.run_hook()
        self.assertNotIn('pwned-by-check-cli', out)
        self.assertFalse(any('pwned-by-check-cli' in a for a in self.git_args()))

    def test_ref_syntax_in_a_version_never_reaches_git(self):
        self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        for weird in ('v1.0.0@{1}', 'v1.0.0^', 'v1.0.0~1', 'v1.0.0:Sources'):
            with self.subTest(version=weird):
                self.git_log.unlink(missing_ok=True)
                self.install(weird)
                out = self.run_hook()
                self.assertNotIn(weird, out)
                self.assertFalse(any(weird in a for a in self.git_args()), self.git_args())

    def test_a_short_hex_string_is_not_taken_for_a_commit(self):
        self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install('abc12')                                           # 5 hex digits: not a describe hash
        out = self.run_hook()
        self.assertNotIn('built from abc12', out)
        self.assertFalse(any(a.startswith('abc12') for a in self.git_args()))

    def test_only_the_first_line_is_read(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install_script(f"printf 'v1.0.0-0-g{hashes[0][:7]}\\nGARBAGE\\n'")
        out = self.run_hook()
        self.assertNotIn('GARBAGE', out)
        self.assertIn('2 commits touching the compiled code', out)

    def test_a_version_printed_before_a_failure_is_not_trusted(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install_script(f"printf 'v1.0.0-0-g{hashes[0][:7]}\\n'; exit 3", age_days=1)
        out = self.run_hook()
        self.assertNotIn(hashes[0][:7], out)
        self.assertIn('older than its source', out)                     # the file-time signal decided

    def test_a_huge_first_line_is_cheap_and_not_shown(self):
        self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install('v1' + 'a' * 200000, age_days=1)
        out = self.run_hook()
        self.assertLess(self.elapsed, 3, 'a long version line made the hook slow')
        self.assertLess(len(out), 2000)
        self.assertIn('older than its source', out)


class BoundedVersionProbe(CheckCliTestCase):
    """`--version` runs at every session start, so it must cost seconds at most, leave
    no process and no temp file behind, and print nothing on stderr."""

    def stale_install(self, behavior):
        self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)  # last code commit is day 4
        self.install(behavior, age_days=1)             # binary is from day 1

    def test_a_binary_that_hangs_falls_back_within_the_bound(self):
        self.stale_install('hang')
        out = self.run_hook()
        self.assertLess(self.elapsed, 5, 'the hook waited for a hung binary')
        self.assertIn('older than its source', out)

    def test_a_binary_that_ignores_sigterm_is_still_bounded_and_killed(self):
        self.stale_install('ignore-term')
        out = self.run_hook()
        self.assertLess(self.elapsed, 5, 'the hook waited for a binary that ignores SIGTERM')
        self.assertIn('older than its source', out)
        pid = self.probe_pid()
        time.sleep(0.3)
        self.assertFalse(alive(pid), 'the version probe outlived the hook')

    def test_a_child_of_the_probe_is_killed_too(self):
        self.stale_install('grandchild')
        self.run_hook()
        pid = self.probe_pid()
        time.sleep(0.3)
        self.assertFalse(alive(pid), "the probe's own child outlived the hook")

    def test_a_hook_interrupted_during_the_probe_leaves_nothing_behind(self):
        # what a session-start timeout does: TERM to the hook's process group while the
        # probe is still running
        import signal
        self.stale_install('hang-pid')
        env = {'HOME': str(self.home), 'PATH': f'{self.shims}:{os.environ["PATH"]}',
               'LANG': 'C', 'TMPDIR': str(self.tmpdir), **GIT_ENV}
        hook = subprocess.Popen([str(HOOK)], env=env, stdout=subprocess.DEVNULL,
                                stderr=subprocess.DEVNULL, start_new_session=True)
        pidfile = self.root / 'probe.pid'
        for _ in range(50):
            if pidfile.exists() and pidfile.read_text().strip():
                break
            time.sleep(0.1)
        self.assertTrue(pidfile.exists(), 'the probe never started')
        os.killpg(hook.pid, signal.SIGTERM)
        hook.wait(timeout=10)
        time.sleep(0.5)
        self.assertFalse(alive(self.probe_pid()), 'the probe outlived an interrupted hook')
        self.assertEqual(list(self.tmpdir.iterdir()), [])

    def test_no_temp_file_is_left_behind_and_stderr_stays_quiet(self):
        for behavior in ('unsupported', 'hang', 'grandchild'):
            with self.subTest(behavior=behavior):
                if not self.checkout.exists():
                    self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
                self.install(behavior, age_days=1)
                self.run_hook()
                self.assertEqual(list(self.tmpdir.iterdir()), [])
                self.assertEqual(self.stderr, '')


class FallbackToFileTimes(CheckCliTestCase):
    """Binaries from before --version (#278), or built without git, keep the old signal."""

    def stale_install(self, behavior):
        self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)  # last code commit is day 4
        self.install(behavior, age_days=1)             # binary is from day 1

    def test_unknown_version_uses_file_times(self):
        self.stale_install('unknown')
        out = self.run_hook()
        self.assertIn('⬆️', out)
        self.assertIn('older than its source', out)

    def test_a_binary_that_rejects_the_flag_uses_file_times(self):
        self.stale_install('unsupported')
        out = self.run_hook()
        self.assertIn('⬆️', out)
        self.assertIn('older than its source', out)

    def test_a_binary_newer_than_the_source_is_silent(self):
        self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install('unsupported', age_days=30)
        self.assertNotIn('⬆️', self.run_hook())


class Offline(CheckCliTestCase):
    def test_nothing_is_downloaded_or_looked_up_online(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install(f'v1.0.0-0-g{hashes[0][:7]}')
        self.run_hook()
        self.assertEqual(self.network_calls(), '')

    def test_the_installed_binary_is_never_replaced(self):
        # both verdict paths: behind by commits, and older by file time
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        for behavior, age in ((f'v1.0.0-0-g{hashes[0][:7]}', None), ('unsupported', 1)):
            with self.subTest(behavior=behavior):
                self.install(behavior, age_days=age)
                before = self.binary.read_bytes()
                out = self.run_hook()
                self.assertIn('⬆️', out)                                    # the stale path ran
                self.assertEqual(self.binary.read_bytes(), before)


if __name__ == '__main__':
    unittest.main()
