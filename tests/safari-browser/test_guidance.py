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
        self.assertEqual(plugin['version'], '2.10.0')
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
    """Fenced blocks of any info string, paired line by line. A fence may be indented
    (under a list item) and use backticks or tildes; it closes on a line holding only a
    run of the same character at least as long. An unclosed block runs to the end."""
    blocks, current, fence = [], None, None
    for line in markdown.splitlines():
        stripped = line.strip()
        if current is None:
            match = re.match(r'^(`{3,}|~{3,})', stripped)
            if match:
                current, fence = [], match.group(1)
        elif stripped and set(stripped) == {fence[0]} and len(stripped) >= len(fence):
            blocks.append('\n'.join(current))
            current = None
        else:
            current.append(line)
    if current is not None:
        blocks.append('\n'.join(current))
    return blocks


TYPED_TEXT = re.compile(
    r'keystroke\s+(?!"[^"\n]"\s+using\b)(?!(?:return|tab|space)\b(?!\s*&))', re.I)


def types_text(code):
    """True when the code sends text with `keystroke`: a string longer than one key, a
    variable, or a key constant joined to more text. A single key with modifiers (Cmd+V)
    and a bare return/tab/space are shortcuts, not typed text."""
    return bool(TYPED_TEXT.search(code))


class TypedTextDetectorTests(unittest.TestCase):
    def test_typing_a_path_is_flagged_in_any_fence(self):
        for opening in ('```bash', '```sh', '```osascript', '```applescript', '```', '~~~applescript'):
            doc = f'{opening}\nkeystroke "/Users/me/x.pdf"\n{opening[:3]}\n'
            self.assertTrue(any(types_text(b) for b in code_blocks(doc)), opening)

    def test_an_indented_or_unclosed_fence_is_still_read(self):
        indented = '1. step\n\n   ```applescript\n   keystroke "/Users/me/x.pdf"\n   ```\n'
        unclosed = 'text\n```applescript\nkeystroke "/Users/me/x.pdf"\n'
        for doc in (indented, unclosed):
            self.assertTrue(any(types_text(b) for b in code_blocks(doc)), doc)

    def test_typing_a_variable_or_a_joined_string_is_flagged(self):
        self.assertTrue(types_text('keystroke destPath'))
        self.assertTrue(types_text('keystroke return & destPath'))

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

    SECTION = 'Saving What the Page Shows (pdf-cache, save-pdf, save-image)'
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
        self.assertMentions(self.description, 'pdf-cache', 'save-image', 'save the PDF this Safari tab shows',
                            '存 Safari 分頁上的 PDF')
        self.assertLessEqual(len(self.description), 1024)   # Agent Skills description limit

    def test_the_usage_rule_of_the_issue_is_stated(self):
        self.assertMentions(self.section(self.SECTION), 'before any dialog', 'behind a login', 'original bytes')

    def test_pdf_cache_and_its_three_selection_forms_are_documented(self):
        self.assertMentions(self.section(self.SECTION), 'pdf-cache list', 'pdf-cache get', '--url', '--key',
                            '--source webkit-pdfs --file', 'pdf-cache list --source webkit-pdfs',
                            'exactly one', 'Full Disk Access')

    def test_minimum_versions_and_the_help_text_are_named(self):
        self.assertMentions(self.section(self.SECTION), 'v2.7.0', 'v2.6.0', 'safari-browser pdf-cache get --help')

    def test_a_tab_flag_matches_only_a_tab_whose_url_is_the_pdf(self):
        self.assertMentions(self.section(self.SECTION), "own URL is the PDF", 'byte for byte', 'PDF.js')

    def test_no_match_hands_the_save_to_the_user_instead_of_picking(self):
        # Round 3: a row picked from the listing, or a WebKitPDFs file, is not tied to the
        # tab; a wrong PDF is copied and reported as success (it happened on 2026-11-02).
        self.assertMentions(self.section(self.SECTION), 'When nothing matches', 'no-store', 'byte ranges',
                            'hand the save to the user', 'do not pick', 'wrong PDF')

    def test_key_and_file_forms_are_for_what_the_user_identified(self):
        self.assertMentions(self.section(self.SECTION), 'the user identified', 'first-page title', '50 rows')

    def test_no_example_tells_the_agent_to_pick(self):
        # Round 4: the prose forbade picking while an example comment still said "pick it from the listing".
        for block in code_blocks(self.section(self.SECTION)):
            for line in block.splitlines():
                self.assertNotRegex(line.lower(), r'#.*\bpick\b', line)
        self.assertIn('<file the user identified>', self.section(self.SECTION))

    def test_save_pdf_comes_before_handing_the_save_over(self):
        text = self.section(self.SECTION)
        self.assertIn('use `save-pdf` with the same tab flag', text)
        self.assertIn('v2.8.0', text)
        self.assertIn('compare `pages`', text)
        self.assertIn('Content-Security-Policy', text)

    def test_several_matches_are_the_users_choice(self):
        text = self.section(self.SECTION)
        self.assertIn('the user says which one', text)
        self.assertNotIn('one of their keys', text)

    def test_cli_hints_do_not_override_the_no_picking_rule(self):
        self.assertMentions(self.section(self.SECTION), 'hint', 'does not change this')

    def test_duplicate_webkitpdfs_names_are_a_dead_end(self):
        self.assertMentions(self.section(self.SECTION), 'same name', 'safari-browser#337')

    def test_the_listing_is_a_viewing_record_and_untrusted_text(self):
        self.assertMentions(self.section(self.SECTION), 'viewing record', 'as data')

    def test_page_derived_values_are_single_quoted_in_examples(self):
        text = self.section(self.SECTION)
        self.assertMentions(text, 'single quotes', '$(')
        for block in code_blocks(text):
            self.assertIsNone(re.search(r'--(?:file|url)\s+"', block), block)

    def test_destination_names_from_a_page_stay_in_the_chosen_folder(self):
        self.assertMentions(self.section(self.SECTION), 'one path component', 'folder the user chose')

    def test_a_workflow_that_reserves_saving_for_the_user_wins(self):
        self.assertMentions(self.section(self.SECTION), 'workflow skill', 'the user saves the file')

    def test_save_image_request_referer_overwrite_and_failures_are_stated(self):
        self.assertMentions(self.section(self.SECTION), 'save-image', '--element', '--with-cookies', 'no request',
                            'inline SVG', 'full URL', 'safari-browser#336', 'overwrites', 'blob:',
                            'do not retry without', 'should not reach another site', 'extension',
                            'behind a login needs `--with-cookies`', 'does not check what came back',
                            'file --mime-type')

    def test_force_is_named_as_irreversible(self):
        self.assertMentions(self.section(self.SECTION), '--force', 'irreversibl')

    def test_pdf_export_is_told_apart_from_saving_the_original(self):
        self.assertMentions(self.section(self.SECTION), 'pdf --allow-hid', 'Export as PDF')
        self.assertMentions(self.section('Screenshot, PDF & Upload'), 'pdf-cache get', 'v2.6.0 and earlier')
        self.assertNotIn('locale-independent', self.body)   # main said this; #107 made it false

    def test_file_dialog_rule_keeps_the_discipline_of_the_issue(self):
        self.assertMentions(self.section(self.DIALOG), 'keystroke', 'input source', 'paste', 'clipboard',
                            'check that the file')

    def test_file_dialog_defaults_to_the_user_and_names_the_cli_guards(self):
        self.assertMentions(self.section(self.DIALOG), 'hand the save to the user', 'actively interfering',
                            'frontmost', 'Replace', 'run their own', 'escape the path')
        # upload and pdf interpolate the path after escaping it; the skill must not say otherwise.
        self.assertNotIn('never interpolate', self.section(self.DIALOG))

    def test_file_dialog_keeps_the_confirmed_clarity_items(self):
        # Clarity Surface row 3, confirmed by the maintainer: restore, and say it is best effort.
        self.assertMentions(self.section(self.DIALOG), 'restore', 'best effort', 'new or changed',
                            'received the file')

    def test_local_data_statements_include_pdf_cache(self):
        text = self.section('Local Safari Data')
        self.assertMentions(text, 'pdf-cache', "Safari's container", 'tab flag')
        self.assertNotIn('These four (and', text)
        self.assertIn('pdf-cache', re.search(r'^- \*\*Local-data commands require Full Disk Access\*\*.*$',
                                             self.body, re.M).group(0))

    def test_no_example_types_text_with_keystroke(self):
        for block in code_blocks(self.body):
            self.assertFalse(types_text(block), block)

    def test_limitations_name_both_outcomes_of_a_named_profile_tab(self):
        self.assertMentions(self.section('Limitations'), 'pdf-cache', 'default profile', 'safari-browser#243',
                            'copy of the same URL', 'reported as success', 'loaded into its cache',
                            'private window')


if __name__ == '__main__':
    unittest.main()
