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


def code_blocks(markdown):
    """Fenced blocks of any info string, paired line by line (a fence opens and closes
    with the same backtick run), so an unrelated block cannot shift the pairing."""
    blocks, current, fence = [], None, None
    for line in markdown.splitlines():
        match = re.match(r'^(`{3,})', line)
        if current is None and match:
            current, fence = [], match.group(1)
        elif current is not None and line.startswith(fence) and line.strip() == fence:
            blocks.append('\n'.join(current))
            current = None
        elif current is not None:
            current.append(line)
    return blocks


TYPED_TEXT = re.compile(
    r'keystroke\s+(?!"[^"\n]"\s+using\b)(?!(?:return|tab|space)\b)', re.I)


def types_text(code):
    """True when the code sends text with `keystroke`: a string longer than one key, or
    a variable. A single key with modifiers (Cmd+V) and the return/tab/space constants
    are shortcuts, not typed text."""
    return bool(TYPED_TEXT.search(code))


class TypedTextDetectorTests(unittest.TestCase):
    def test_typing_a_path_is_flagged_in_any_fence(self):
        for fence in ('bash', 'sh', 'osascript', 'applescript', ''):
            doc = f'```{fence}\nkeystroke "/Users/me/x.pdf"\n```\n'
            self.assertTrue(any(types_text(b) for b in code_blocks(doc)), fence)

    def test_typing_a_variable_is_flagged(self):
        self.assertTrue(types_text('keystroke destPath'))

    def test_paste_and_return_shortcuts_are_not_typed_text(self):
        self.assertFalse(types_text('keystroke "v" using command down\nkeystroke "g" using {command down, shift down}\nkeystroke return'))

    def test_an_unrelated_block_does_not_shift_the_pairing(self):
        doc = '```json\n{"a": 1}\n```\nprose that says instead of keystroke\n```bash\necho ok\n```\n'
        self.assertEqual(code_blocks(doc), ['{"a": 1}', 'echo ok'])


class SavingFilesGuidanceTests(unittest.TestCase):
    """safari-browser#315: an agent that could not find a command for saving the
    PDF a tab showed scripted Save As and typed the destination with `keystroke`; a
    non-ASCII input source rewrote the path and the file landed in an unrelated
    folder, silently."""

    SECTION = 'Saving What the Page Shows'
    DIALOG = 'Never Type a Path into a File Dialog'

    @classmethod
    def setUpClass(cls):
        source = (PLUGIN / 'skills/safari-browser/SKILL.md').read_text()
        cls.front, cls.body = source.split('---', 2)[1:]
        folded = re.search(r'^description: >-\n((?:  .*\n)+)', cls.front, re.M).group(1)
        cls.description = ' '.join(folded.split())

    def section(self, title):
        match = re.search(r'^(#{2,3}) ' + re.escape(title) + r'.*?$(.*?)(?=^#{2,3} |\Z)',
                          self.body, re.M | re.S)
        self.assertIsNotNone(match, f'missing section: {title}')
        return match.group(2)

    def assertMentions(self, text, *needles):
        for needle in needles:
            self.assertIn(needle.lower(), text.lower())

    def test_description_ties_the_save_triggers_to_a_safari_tab(self):
        self.assertMentions(self.description, 'pdf-cache', 'save-image', 'save the PDF this Safari tab shows')
        self.assertLessEqual(len(self.description), 1024)   # Agent Skills description limit

    def test_pdf_cache_and_its_three_selection_forms_are_documented(self):
        self.assertMentions(self.section(self.SECTION), 'pdf-cache list', 'pdf-cache get', '--url', '--key',
                            '--source webkit-pdfs --file', 'pdf-cache list --source webkit-pdfs',
                            'exactly one', 'Full Disk Access')

    def test_minimum_versions_and_the_help_text_are_named(self):
        text = self.section(self.SECTION)
        self.assertMentions(text, 'v2.7.0', 'v2.6.0', 'safari-browser pdf-cache get --help')
        self.assertNotIn('top-level help', self.body)   # the #335 report was a test error
        self.assertNotIn('#335', self.body)

    def test_a_tab_flag_matches_only_a_tab_whose_url_is_the_pdf(self):
        self.assertMentions(self.section(self.SECTION), "own URL is the PDF", 'byte for byte', 'PDF.js')

    def test_no_match_has_a_next_step(self):
        self.assertMentions(self.section(self.SECTION), 'When nothing matches', 'no-store', 'hand the save to the user')

    def test_a_workflow_that_reserves_saving_for_the_user_wins(self):
        self.assertMentions(self.section(self.SECTION), 'workflow skill', 'the user saves the file')

    def test_save_image_request_referer_and_overwrite_are_stated(self):
        self.assertMentions(self.section(self.SECTION), 'save-image', '--element', '--with-cookies', 'no request',
                            'inline SVG', "full URL", 'safari-browser#336', 'overwrites')

    def test_pdf_export_is_told_apart_from_saving_the_original(self):
        self.assertMentions(self.section(self.SECTION), 'pdf --allow-hid', 'original bytes')
        self.assertMentions(self.section('Screenshot, PDF & Upload'), 'pdf-cache get')

    def test_file_dialog_rule_forbids_typed_text_and_injection(self):
        self.assertMentions(self.section(self.DIALOG), 'keystroke', 'input source', 'file name',
                            'on run argv', 'never interpolate', 'Go to Folder', 'on error')

    def test_file_dialog_rule_treats_the_clipboard_as_visible(self):
        self.assertMentions(self.section(self.DIALOG), 'clipboard history', 'restore', 'best effort')

    def test_success_check_compares_with_the_state_before_the_dialog(self):
        self.assertMentions(self.section(self.DIALOG), 'modification time', 'new or changed', 'received the file')

    def test_no_example_types_text_with_keystroke(self):
        for block in code_blocks(self.body):
            self.assertFalse(types_text(block), block)

    def test_the_stale_axdefault_description_is_gone(self):
        self.assertNotIn('AXDefault', self.body)

    def test_limitations_name_both_outcomes_of_a_named_profile_tab(self):
        self.assertMentions(self.section('Limitations'), 'pdf-cache', 'default profile', 'safari-browser#243',
                            'copy of the same URL', 'reported as success')


if __name__ == '__main__':
    unittest.main()
