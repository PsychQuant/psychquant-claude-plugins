"""Behavior tests for plugins/safari-browser/hooks/check-cli.sh (PsychQuant/safari-browser#280).

The hook runs at every session start and says whether the installed CLI is older than
the source checkout. It is run here as a real process against a throwaway HOME holding a
fake `~/bin/safari-browser` and a real, tiny git repository standing in for the checkout.
Network tools are shimmed so a call to any of them is a recorded failure: the hook is
offline by design and never installs anything.

macOS only (the hook uses BSD `stat -f` and `date -r`, as it always has).
"""
import os
import stat
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HOOK = ROOT / 'plugins/safari-browser/hooks/check-cli.sh'

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


def git(repo, *args, date=None):
    env = {**os.environ, **GIT_ENV}
    if date is not None:
        env['GIT_AUTHOR_DATE'] = env['GIT_COMMITTER_DATE'] = f'{date} +0000'
    result = subprocess.run(['git', '-C', str(repo), *args], check=True,
                            capture_output=True, text=True, env=env)
    return result.stdout.strip()


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
        self.network_log = self.root / 'network.log'
        self.shims = self.root / 'shims'
        self.shims.mkdir()
        for tool in ('curl', 'wget', 'gh'):
            self.write_executable(self.shims / tool,
                                  f'#!/bin/sh\necho "{tool} $*" >> "{self.network_log}"\nexit 1\n')

    @staticmethod
    def write_executable(path, text):
        path.write_text(text)
        path.chmod(path.stat().st_mode | stat.S_IXUSR)

    # --- the fake CLI ------------------------------------------------------------
    def install(self, behavior, age_days=None):
        """behavior: a version string, 'unsupported' (an old binary), or 'hang'."""
        if behavior == 'unsupported':
            answer = 'echo "Error: Unknown option \'--version\'" >&2; exit 64'
        elif behavior == 'hang':
            answer = 'exec sleep 60'
        else:
            answer = f"printf '%s\\n' '{behavior}'"
        self.write_executable(self.binary, f'#!/bin/sh\ncase "$1" in\n  --version) {answer} ;;\nesac\nexit 0\n')
        if age_days is not None:
            stamp = T0 + age_days * DAY
            os.utime(self.binary, (stamp, stamp))

    # --- the fake checkout ---------------------------------------------------------
    def make_checkout(self, history):
        """history: kinds in order, 'code' (touches Sources/) or 'docs'. Commit i is
        dated T0 + i days. The first commit is tagged v1.0.0. Returns the full hashes."""
        self.checkout.mkdir(exist_ok=True)
        git(self.checkout, 'init', '-q', '.')
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

    # --- running the hook -----------------------------------------------------------
    def run_hook(self):
        env = {'HOME': str(self.home), 'PATH': f'{self.shims}:{os.environ["PATH"]}',
               'LANG': 'C', **GIT_ENV}
        started = time.monotonic()
        result = subprocess.run([str(HOOK)], env=env, capture_output=True, text=True, timeout=30)
        self.elapsed = time.monotonic() - started
        self.assertEqual(result.returncode, 0, 'the hook must never fail a session start')
        return result.stdout

    def network_calls(self):
        return self.network_log.read_text() if self.network_log.exists() else ''


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
        # git can read `<tag>-<n>-g<hash>` itself, but only when it has the tag
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

    def test_the_stale_message_keeps_the_install_hint(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install(f'v1.0.0-0-g{hashes[0][:7]}')
        self.assertIn('make install-signed', self.run_hook())


class WhenTheBuildCannotBeComparedItSaysSoInsteadOfGuessing(CheckCliTestCase):
    def test_commit_not_in_the_checkout_is_not_called_stale_even_if_the_file_looks_old(self):
        self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install('v1.0.0-9-gdeadbee', age_days=-30)  # file time alone would say "older than source"
        out = self.run_hook()
        self.assertIn('not in', out)
        self.assertNotIn('⬆️', out)
        self.assertNotIn('older than its source', out)

    def test_commit_outside_the_checkouts_current_history_is_not_called_stale(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        git(self.checkout, 'checkout', '-q', hashes[0])
        git(self.checkout, 'checkout', '-q', '-b', 'side')
        (self.checkout / 'Sources/a.swift').write_text('side\n')
        git(self.checkout, '-c', 'commit.gpgsign=false', 'commit', '-q', '-am', 'side work', date=T0 + 9 * DAY)
        side = git(self.checkout, 'rev-parse', 'HEAD')
        git(self.checkout, 'checkout', '-q', hashes[4])  # detached on the main line again
        self.install(f'v1.0.0-1-g{side[:7]}')
        out = self.run_hook()
        self.assertIn('not in the history', out)
        self.assertNotIn('⬆️', out)

    def test_a_version_that_is_not_plain_text_is_ignored_and_never_reaches_git(self):
        self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install('--output=/tmp/pwned-by-check-cli')
        out = self.run_hook()
        self.assertNotIn('pwned-by-check-cli', out)
        self.assertFalse(Path('/tmp/pwned-by-check-cli').exists())


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

    def test_a_binary_that_hangs_on_the_flag_cannot_hang_the_session(self):
        self.stale_install('hang')
        out = self.run_hook()
        self.assertLess(self.elapsed, 10, 'the hook waited for a hung binary')
        self.assertIn('older than its source', out)


class Offline(CheckCliTestCase):
    def test_nothing_is_downloaded_or_looked_up_online(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install(f'v1.0.0-0-g{hashes[0][:7]}')
        self.run_hook()
        self.assertEqual(self.network_calls(), '')

    def test_the_installed_binary_is_never_replaced(self):
        hashes = self.make_checkout(CODE_DOCS_CODE_DOCS_CODE)
        self.install(f'v1.0.0-0-g{hashes[0][:7]}')
        before = self.binary.read_bytes()
        self.run_hook()
        self.assertEqual(self.binary.read_bytes(), before)


if __name__ == '__main__':
    unittest.main()
