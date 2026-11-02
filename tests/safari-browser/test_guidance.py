import contextlib
import io
import json
from pathlib import Path
import re
import subprocess
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
PLUGIN = ROOT / 'plugins/safari-browser'


class CommandExampleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        prose = (PLUGIN / 'skills/safari-browser/references/command-results.md').read_text()
        code = re.search(r'```python\n(.*?)\n```', prose, re.S).group(1)
        cls.namespace = {}
        exec(compile(code, 'command-results.md', 'exec'), cls.namespace)

    def run_sequence(self, code, stderr):
        calls = []
        def fake(args, **kwargs):
            calls.append(args)
            return subprocess.CompletedProcess(args, code, '{"ok":true}\n', stderr)
        stream = io.StringIO()
        with patch('subprocess.run', side_effect=fake), contextlib.redirect_stderr(stream):
            try:
                for args in [('get', 'title'), ('click', '@e1')]:
                    self.namespace['checked'](*args)
            except BaseException as error:
                return calls, error, stream.getvalue()
        return calls, None, stream.getvalue()

    def test_nonzero_preserves_status_and_stops_next_action(self):
        calls, error, stderr = self.run_sequence(23, 'read failed\nmore detail\n')
        self.assertEqual(len(calls), 1)
        self.assertIsInstance(error, SystemExit)
        self.assertEqual(error.code, 23)
        self.assertEqual(stderr, 'read failed\nmore detail\n')

    def test_exit_zero_warning_after_notice_stops_next_action(self):
        calls, error, stderr = self.run_sequence(0, 'notice\n⚠ BLOCKING DIALOG in window id 42: test\n')
        self.assertEqual(len(calls), 1)
        self.assertIsInstance(error, RuntimeError)
        self.assertTrue(stderr.startswith('notice\n'))
        self.assertIn('BLOCKING DIALOG', stderr)

    def test_signal_status_is_preserved(self):
        calls, error, _ = self.run_sequence(-15, '')
        self.assertEqual(len(calls), 1)
        self.assertEqual(error.code, 143)

    def test_success_keeps_json_separate_from_diagnostics(self):
        namespace = self.namespace
        with patch('subprocess.run', return_value=subprocess.CompletedProcess([], 0, '[1]\n', 'note\nmore\n')):
            with contextlib.redirect_stderr(io.StringIO()) as stderr:
                output, first = namespace['checked']('history', '--json')
        self.assertEqual(json.loads(output), [1])
        self.assertEqual(first, 'note')
        self.assertEqual(stderr.getvalue(), 'note\nmore\n')


class PackagingTests(unittest.TestCase):
    def test_new_skill_matches_authoritative_playbook_contract(self):
        path = PLUGIN / 'skills/safari-google-fill/SKILL.md'
        source = path.read_text()
        front, body = source.split('---', 2)[1:]
        self.assertEqual(re.findall(r'^(\w[\w-]*):', front, re.M), ['name', 'description', 'allowed-tools'])
        self.assertIn('name: ' + path.parent.name, front)
        description = re.search(r'^description: (.*)$', front, re.M).group(1)
        self.assertLessEqual(len(description), 200)
        self.assertIn('Safari', description)
        self.assertIn('Google Forms', description)
        self.assertIn('Bash(safari-browser:*)', front)
        self.assertIn('Bash(safari-browser *)', front)
        self.assertEqual(re.findall(r'^## (.*)$', body, re.M),
                         ['When to use', 'Preconditions', 'Steps', 'Error handling', 'Verification', 'Gotchas'])
        for section in re.split(r'^## .*$', body, flags=re.M)[1:]:
            self.assertTrue(section.strip())

    def test_plugin_and_marketplace_versions_and_descriptions_match(self):
        plugin = json.loads((PLUGIN / 'plugin.json').read_text())
        market = json.loads((ROOT / '.claude-plugin/marketplace.json').read_text())
        entry = next(p for p in market['plugins'] if p['name'] == 'safari-browser')
        self.assertEqual(plugin['version'], '2.9.2')
        self.assertEqual(entry['version'], plugin['version'])
        self.assertEqual(entry['description'], plugin['description'])
        self.assertTrue((ROOT / entry['source']).is_dir())

    def test_main_skill_does_not_expand_automatic_tool_grants(self):
        front = (PLUGIN / 'skills/safari-browser/SKILL.md').read_text().split('---', 2)[1]
        permissions = re.findall(r'^  - (Bash\(.*\))$', front, re.M)
        self.assertEqual(permissions, ['Bash(safari-browser:*)', 'Bash(safari-browser *)'])

    def test_reference_links_resolve(self):
        skill = PLUGIN / 'skills/safari-browser/SKILL.md'
        for link in re.findall(r'\]\((references/[^)]+)\)', skill.read_text()):
            self.assertTrue((skill.parent / link).is_file(), link)


class SavingFilesGuidanceTests(unittest.TestCase):
    """safari-browser#315: an agent that could not find a command for saving the
    PDF a tab showed scripted Save As with `keystroke`; a non-ASCII input source
    rewrote the path and the file landed in an unrelated folder, silently."""

    SECTION = 'Saving What the Page Shows'

    @classmethod
    def setUpClass(cls):
        source = (PLUGIN / 'skills/safari-browser/SKILL.md').read_text()
        cls.front, cls.body = source.split('---', 2)[1:]
        cls.description = re.search(r'^description: >-\n((?:  .*\n)+)', cls.front, re.M).group(1)

    def section(self, title):
        match = re.search(r'^(#{2,3}) ' + re.escape(title) + r'.*?$(.*?)(?=^#{2,3} |\Z)',
                          self.body, re.M | re.S)
        self.assertIsNotNone(match, f'missing section: {title}')
        return match.group(2)

    def test_description_surfaces_the_skill_when_saving_a_shown_file(self):
        for word in ('pdf-cache', 'save-image', 'save this PDF'):
            self.assertIn(word, self.description)

    def test_pdf_cache_and_its_three_selection_forms_are_documented(self):
        text = self.section(self.SECTION)
        for needle in ('pdf-cache list', 'pdf-cache get', '--url', '--key',
                       '--source webkit-pdfs --file', 'exactly one', 'Full Disk Access'):
            self.assertIn(needle, text)

    def test_save_image_and_whether_each_command_sends_a_request(self):
        text = self.section(self.SECTION)
        for needle in ('save-image', '--element', '--with-cookies', 'no request', 'sends its own request'):
            self.assertIn(needle.lower(), text.lower())

    def test_pdf_export_is_told_apart_from_saving_the_original(self):
        text = self.section(self.SECTION)
        self.assertIn('pdf --allow-hid', text)
        self.assertIn('original bytes', text)

    def test_file_dialog_paths_are_pasted_and_the_clipboard_restored(self):
        text = self.section('Never Type a Path into a File Dialog')
        for needle in ('keystroke', 'input source', 'clipboard', 'restore', 'check that the file exists'):
            self.assertIn(needle, text)

    def test_no_example_types_a_path_with_keystroke(self):
        for block in re.findall(r'```(?:bash|applescript)?\n(.*?)```', self.body, re.S):
            self.assertNotIn('keystroke', block)

    def test_limitations_name_the_default_profile_cache(self):
        text = self.section('Limitations')
        self.assertIn('pdf-cache', text)
        self.assertIn('default profile', text)
        self.assertIn('safari-browser#243', text)


if __name__ == '__main__':
    unittest.main()
