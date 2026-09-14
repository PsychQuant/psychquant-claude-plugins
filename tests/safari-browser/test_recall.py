import importlib.util
from pathlib import Path
import unittest
import sys

SCRIPT = Path(__file__).resolve().parents[2] / 'plugins/safari-browser/skills/safari-browser/scripts/recall.py'
spec = importlib.util.spec_from_file_location('recall', SCRIPT)
recall = importlib.util.module_from_spec(spec)
spec.loader.exec_module(recall)


class RecallTests(unittest.TestCase):
    def test_full_url_dedup_preserves_same_titles_and_source_clues(self):
        records = {
            'history': [
                {'url': 'https://x/a?q=1#one', 'title': 'Same', 'visit_time': '2026-08-02T00:00:00Z'},
                {'url': 'https://x/a?q=1#one', 'title': 'Older', 'visit_time': None},
                {'url': 'https://x/b', 'title': 'Same', 'visit_time': None},
                {'url': 'https://x/a?q=2#one', 'title': 'Same', 'visit_time': None}],
            'bookmarks': [{'url': 'https://x/a?q=1#one', 'title': 'Saved', 'folder': 'Research', 'reading_list': True}],
        }
        result = recall.summarize(records, {})
        self.assertEqual(result['total_candidates'], 3)
        a = next(c for c in result['candidates'] if c['url'] == 'https://x/a?q=1#one')
        self.assertEqual(a['sources'], ['history', 'bookmarks'])
        self.assertEqual(a['history_matches'], 2)
        self.assertTrue(a['reading_list'])
        self.assertEqual(a['folders'], ['Research'])
        self.assertEqual(a['titles'], ['Same', 'Older', 'Saved'])

    def test_dates_sort_by_instant_and_unknowns_last(self):
        records = {'history': [
            {'url': 'https://x/a', 'title': None, 'visit_time': '2026-08-01T12:00:00+09:00'},
            {'url': 'https://x/b', 'title': 'B', 'visit_time': '2026-08-01T04:00:00Z'},
            {'url': 'https://x/c', 'title': 'C', 'visit_time': None}]}
        result = recall.summarize(records, {})
        self.assertEqual([c['url'] for c in result['candidates']], ['https://x/b', 'https://x/a', 'https://x/c'])
        self.assertIsNone(result['candidates'][-1]['latest_recorded_at'])

    def test_download_without_source_url_remains_a_hint(self):
        result = recall.summarize({'downloads': [{'filename': 'paper.pdf', 'source_url': '', 'date': None}]}, {})
        self.assertEqual(result['total_candidates'], 0)
        self.assertEqual(result['download_hints'], [{'filename': 'paper.pdf', 'date': None}])

    def test_pagination_reports_total_and_next_offset_without_hiding_coverage(self):
        records = {'cloud-tabs': [{'url': f'https://x/{n}', 'title': 'T', 'device': 'Phone'} for n in range(3)]}
        coverage = {'history': {'at_limit': True}}
        result = recall.summarize(records, coverage, offset=1, page_size=1)
        self.assertEqual(result['total_candidates'], 3)
        self.assertEqual(len(result['candidates']), 1)
        self.assertEqual(result['next_offset'], 2)
        self.assertEqual(result['coverage'], coverage)

    def test_query_after_url_merge_keeps_aliases_and_excludes_unrelated_pages(self):
        records = {'bookmarks': [
            {'url': 'https://x/a', 'title': 'Agent guide', 'folder': 'Research', 'reading_list': False},
            {'url': 'https://x/a', 'title': 'Saved for later', 'folder': 'Reading List', 'reading_list': True},
            {'url': 'https://x/b', 'title': 'Unrelated', 'folder': '', 'reading_list': False}]}
        report = recall.summarize(records, {}, search='agent')
        self.assertEqual(report['total_candidates'], 1)
        self.assertTrue(report['candidates'][0]['reading_list'])
        self.assertEqual(report['candidates'][0]['titles'], ['Agent guide', 'Saved for later'])

    def test_reading_list_is_unknown_without_bookmark_evidence(self):
        report = recall.summarize({'history': [{'url': 'https://x/a', 'title': 'A', 'visit_time': None}]}, {})
        self.assertIsNone(report['candidates'][0]['reading_list'])

    def test_fragment_alone_distinguishes_candidates(self):
        report = recall.summarize({'history': [{'url': 'https://x/a#one'}, {'url': 'https://x/a#two'}]}, {})
        self.assertEqual(report['total_candidates'], 2)


    def test_device_and_filename_matching_without_history(self):
        report = recall.summarize({
            'cloud-tabs': [{'url': 'https://x/device', 'title': 'Other', 'device': 'Phone'}],
            'downloads': [{'source_url': 'https://x/file', 'filename': 'phone.pdf', 'date': None},
                          {'source_url': 'https://x/unrelated', 'filename': 'other.pdf', 'date': None}]
        }, {}, search='phone')
        self.assertEqual({c['url'] for c in report['candidates']}, {'https://x/device', 'https://x/file'})



class CollectionTests(unittest.TestCase):
    def run_helper(self, failure='', malformed='', warning='', bad_schema='', extra=()):
        import json
        import os
        import subprocess
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            binary = root / 'safari-browser'
            binary.write_text('''#!/usr/bin/env python3
import json,os,sys
source=sys.argv[1]
with open(os.environ['CALL_LOG'],'a') as f:f.write(source+'\\n')
if source==os.environ.get('FAIL_SOURCE'):
 print('Error: fixture read failed',file=sys.stderr);raise SystemExit(23)
if source==os.environ.get('BAD_SOURCE'):
 print('{');raise SystemExit(0)
if source==os.environ.get('BAD_SCHEMA'):
 print(json.dumps([{'old_url':'missing url field'}]));raise SystemExit(0)
if source==os.environ.get('WARN_SOURCE'):
 print('notice before warning\\n⚠ BLOCKING DIALOG in window id 42: fixture',file=sys.stderr)
rows = ([{'url':'https://x/a','title':'A','visit_time':None}]*2 if source=='history'
 else [{'url':'https://x/b','title':'B','folder':'','reading_list':False}])
print(json.dumps(rows))
''')
            binary.chmod(0o755)
            log = root / 'calls'
            env = dict(os.environ, PATH=str(root)+os.pathsep+os.environ['PATH'], CALL_LOG=str(log),
                       FAIL_SOURCE=failure, BAD_SOURCE=malformed, WARN_SOURCE=warning, BAD_SCHEMA=bad_schema)
            result = subprocess.run([sys.executable, str(SCRIPT), '--sources', 'history', 'bookmarks', '--limit', '2', *extra],
                                    capture_output=True, text=True, env=env)
            return result, log.read_text().splitlines() if log.exists() else []

    def test_collection_marks_cap_and_checks_both_sources(self):
        import json
        result, calls = self.run_helper()
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads(result.stdout)
        self.assertTrue(report['coverage']['history']['at_limit'])
        self.assertEqual(calls, ['history', 'bookmarks'])
        self.assertEqual(report['total_candidates'], 2)

    def test_nonzero_stops_without_partial_report(self):
        result, calls = self.run_helper(failure='history')
        self.assertEqual(result.returncode, 23)
        self.assertEqual(result.stdout, '')
        self.assertEqual(calls, ['history'])
        self.assertIn('fixture read failed', result.stderr)

    def test_bad_json_stops_without_false_empty_success(self):
        result, calls = self.run_helper(malformed='history')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, '')
        self.assertEqual(calls, ['history'])

    def test_warning_after_first_line_stops_even_with_exit_zero(self):
        result, calls = self.run_helper(warning='history')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, '')
        self.assertEqual(calls, ['history'])
        self.assertIn('notice before warning', result.stderr)
        self.assertIn('BLOCKING DIALOG', result.stderr)

    def test_invalid_row_schema_stops_before_querying_next_source(self):
        result, calls = self.run_helper(bad_schema='history')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, '')
        self.assertEqual(calls, ['history'])

    def test_empty_since_is_rejected_before_querying(self):
        result, calls = self.run_helper(extra=('--since', ''))
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, [])
        self.assertEqual(result.stdout, '')

    def test_timeout_preserves_partial_stderr_and_stops(self):
        import argparse
        import contextlib
        import io
        import subprocess
        from unittest.mock import patch
        args = argparse.Namespace(sources=['history', 'bookmarks'], limit=2, search='', since=None)
        stream = io.StringIO()
        failure = subprocess.TimeoutExpired(['safari-browser'], 60, stderr=b'first diagnostic\nmore detail\n')
        with patch.object(recall.subprocess, 'run', side_effect=failure) as run, contextlib.redirect_stderr(stream):
            with self.assertRaises(recall.RecallError) as raised:
                recall.collect(args)
        self.assertEqual(raised.exception.code, 124)
        self.assertEqual(run.call_count, 1)
        self.assertEqual(stream.getvalue(), 'first diagnostic\nmore detail\n')

    def test_all_sources_use_real_encoder_shapes_and_old_bookmarks_json(self):
        import json
        import os
        import subprocess
        import tempfile
        fixture = Path(__file__).parent / 'fixtures/cli-local-data.json'
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            binary = root / 'safari-browser'
            binary.write_text("""#!/usr/bin/env python3
import json,os,sys
source=sys.argv[1]
with open(os.environ['CALL_LOG'],'a') as f:f.write(source+'\\n')
if source=='bookmarks' and any(a.startswith('--search') for a in sys.argv[2:]):
 print('Unknown option --search',file=sys.stderr);raise SystemExit(64)
with open(os.environ['FIXTURE']) as f:rows=json.load(f)[source]
print(json.dumps(rows))
""")
            binary.chmod(0o755)
            env = dict(os.environ, PATH=str(root)+os.pathsep+os.environ['PATH'],
                       CALL_LOG=str(root/'calls'), FIXTURE=str(fixture))
            result = subprocess.run([sys.executable, str(SCRIPT), '--search', 'agent', '--limit', '2'],
                                    capture_output=True, text=True, env=env)
            self.assertEqual(result.returncode, 0, result.stderr)
            report = json.loads(result.stdout)
            self.assertEqual((root/'calls').read_text().splitlines(), ['history', 'bookmarks', 'cloud-tabs', 'downloads'])
            self.assertTrue(result.stdout.isascii())
            a = next(c for c in report['candidates'] if c['url'].startswith('https://example.invalid/guide'))
            self.assertEqual(a['sources'], ['history', 'bookmarks', 'cloud-tabs', 'downloads'])
            self.assertTrue(a['reading_list'])
            self.assertIn('Saved overview', a['titles'])
            self.assertIn('Agent Ω notes', a['titles'])
            self.assertEqual(report['download_hints'][0]['filename'], 'agent-attachment.pdf')
            self.assertTrue(report['coverage']['downloads']['at_limit'])


if __name__ == '__main__':
    unittest.main()
