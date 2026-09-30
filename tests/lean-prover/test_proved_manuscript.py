"""Tests for plugins/lean-prover/scripts/proved_manuscript.py on the fixture project.

Run from the repository root:  python3 -m unittest discover -s tests/lean-prover -v
Every test copies the fixture to a temporary directory, so tests can change the graph freely.
"""
import contextlib
import importlib.util
import io
import json
import os
import shutil
import subprocess
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
FIXTURE = os.path.join(HERE, "fixtures", "proj")
SCRIPT = os.path.join(HERE, "..", "..", "plugins", "lean-prover", "scripts", "proved_manuscript.py")

TEX = "PROVED_MANUSCRIPT.tex"
FRONTIER = "FRONTIER.md"


def load_module():
    spec = importlib.util.spec_from_file_location("proved_manuscript", SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


class Case(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.proj = os.path.join(self.tmp, "proj")
        shutil.copytree(FIXTURE, self.proj)
        self.out = os.path.join(self.tmp, "out")
        self.mod = load_module()

    def tearDown(self):
        shutil.rmtree(self.tmp)

    # helpers ------------------------------------------------------------
    def graph_path(self):
        return os.path.join(self.proj, "graph.json")

    def edit_graph(self, fn):
        with open(self.graph_path(), encoding="utf-8") as f:
            g = json.load(f)
        fn(g)
        with open(self.graph_path(), "w", encoding="utf-8") as f:
            json.dump(g, f)

    def run_main(self, *extra):
        argv = ["--graph", self.graph_path(), "--cards", os.path.join(self.proj, "cards"),
                "--manuscript", os.path.join(self.proj, "manuscript", "main.tex"),
                "--out", self.out, *extra]
        err = io.StringIO()
        with contextlib.redirect_stderr(err), contextlib.redirect_stdout(io.StringIO()):
            code = self.mod.main(argv)
        return code, err.getvalue()

    def read(self, name):
        with open(os.path.join(self.out, name), encoding="utf-8") as f:
            return f.read()

    def set_status(self, node_id, status):
        def fn(g):
            for n in g["nodes"]:
                if n["id"] == node_id:
                    n["status"] = status
        self.edit_graph(fn)


class GateAndInclusion(Case):
    def test_text_graph_is_refused(self):
        self.edit_graph(lambda g: g.update(check="text"))
        code, err = self.run_main()
        self.assertEqual(code, 2)
        self.assertIn("card-graph --lean", err)
        self.assertFalse(os.path.exists(os.path.join(self.out, TEX)))
        self.assertFalse(os.path.exists(os.path.join(self.out, FRONTIER)))

    def test_open_and_unformalized_cards_are_absent(self):
        self.assertEqual(self.run_main()[0], 0)
        doc = self.read(TEX)
        self.assertIn("STATEMENTA", doc)
        for absent in ("NATURALB", "NATURALC", "STATEMENTB", "theorem B", "theorem C"):
            self.assertNotIn(absent, doc)

    def test_newly_proved_card_is_added_and_nothing_else_changes(self):
        self.run_main()
        first = self.read(TEX)
        self.set_status("tB", "proved")
        self.edit_graph(lambda g: g["edges"].append(
            {"conclusion": "tB", "premises": ["d1"], "proof_module": "Lib.Proofs.B"}))
        self.run_main()
        second = self.read(TEX)
        self.assertIn("STATEMENTB", second)
        self.assertNotIn("STATEMENTB", first)
        for kept in ("STATEMENTA", "STATEMENTG", "NATURALF"):
            self.assertIn(kept, second)

    def test_proved_card_with_unproved_premise_is_held_back(self):
        self.run_main()
        doc, report = self.read(TEX), self.read(FRONTIER)
        self.assertNotIn("STATEMENTE", doc)
        self.assertNotIn("NATURALD2", doc)          # a definition only the held-back card uses
        held = report.split("Proved but held back")[1]
        self.assertIn("theorem E", held)
        self.assertIn("theorem B", held)             # the blocking premise is named


class TransitiveClosure(Case):
    def test_a_theorem_resting_on_a_held_back_theorem_is_held_back_too(self):
        def fn(g):
            g["nodes"].append({"id": "tY", "lean_name": "Lib.Y", "shape": "theorem", "status": "proved", "title": "theorem Y"})
            g["edges"].append({"conclusion": "tY", "premises": ["tE"], "proof_module": "Lib.Proofs.Y"})
        self.edit_graph(fn)
        with open(os.path.join(self.proj, "cards", "tY.yaml"), "w", encoding="utf-8") as f:
            f.write('theorem:\nid: tY\ntitle: "theorem Y"\nnatural: "NATURALY prose."\n'
                    'expressions:\n  manuscript:\n    block: "thm:y"\n')
        self.run_main()
        self.assertNotIn("NATURALY", self.read(TEX))
        held = self.read(FRONTIER).split("Proved but held back")[1]
        self.assertIn("theorem Y", held)
        self.assertIn("theorem E", held)          # it waits for E, which is itself held back


class ManuscriptReading(Case):
    def test_commands_in_comments_are_ignored(self):
        code, err = self.run_main()
        self.assertEqual(code, 0, err)                      # the commented \\input of a missing file is not read
        doc = self.read(TEX)
        self.assertIn("STATEMENTA2 continues after it", doc)   # a commented \\begin{proof} does not cut the statement
        self.assertNotIn("statement from card text; the manuscript environment was not found", doc.split("theorem F")[0])

    def test_a_preamble_supplied_through_input_is_flattened(self):
        ms = os.path.join(self.proj, "manuscript")
        with open(os.path.join(ms, "preamble.tex"), "w", encoding="utf-8") as f:
            f.write("\\documentclass{article}\n\\usepackage{amsmath,amsthm}\n\\newtheorem{theorem}{Theorem}\n"
                    "\\newtheorem{lemma}{Lemma}\n\\newcommand{\\one}{\\mathbf1}\n\\newcommand{\\fromPreamble}{X}\n")
        with open(os.path.join(ms, "main2.tex"), "w", encoding="utf-8") as f:
            f.write("\\input{preamble}\n\\begin{document}\n\\input{sec1}\n\\end{document}\n")
        argv = ["--graph", self.graph_path(), "--cards", os.path.join(self.proj, "cards"),
                "--manuscript", os.path.join(ms, "main2.tex"), "--out", self.out]
        with contextlib.redirect_stderr(io.StringIO()), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(self.mod.main(argv), 0)
        doc = self.read(TEX)
        self.assertNotIn("\\input{preamble}", doc)
        self.assertIn("\\newcommand{\\fromPreamble}{X}", doc)

    def test_a_missing_input_file_is_an_error(self):
        with open(os.path.join(self.proj, "manuscript", "main.tex"), "a", encoding="utf-8") as f:
            pass
        path = os.path.join(self.proj, "manuscript", "main.tex")
        text = open(path, encoding="utf-8").read().replace("\\input{sec1}", "\\input{sec1}\n\\input{absent}")
        open(path, "w", encoding="utf-8").write(text)
        code, err = self.run_main()
        self.assertEqual(code, 1)
        self.assertIn("absent", err)


class GraphValidation(Case):
    def test_a_premise_that_is_not_a_graph_node_is_an_error(self):
        self.edit_graph(lambda g: g["edges"].append(
            {"conclusion": "tZ", "premises": ["ghost"], "proof_module": "Lib.Proofs.Z0"}))
        code, err = self.run_main()
        self.assertEqual(code, 1)
        self.assertIn("ghost", err)


class OrderAndSource(Case):
    def test_premise_theorem_precedes_its_dependent(self):
        self.run_main()
        doc = self.read(TEX)
        # in the manuscript G comes before A; G depends on A, so A must come first
        self.assertLess(doc.index("STATEMENTA"), doc.index("STATEMENTG"))

    def test_ties_follow_the_manuscript_order_not_the_card_id(self):
        self.run_main()
        doc = self.read(TEX)
        # A and Z are both free of dependencies; Z is earlier in the manuscript but its id sorts later
        self.assertLess(doc.index("STATEMENTZ"), doc.index("STATEMENTA"))

    def test_a_proof_nested_inside_the_environment_is_cut(self):
        self.run_main()
        doc = self.read(TEX)
        self.assertIn("STATEMENTZ holds", doc)
        self.assertNotIn("PROOFTEXTZ", doc)

    def test_label_found_gives_the_environment_without_the_proof(self):
        self.run_main()
        doc = self.read(TEX)
        self.assertIn("\\begin{lemma}\\label{thm:a}", doc)
        self.assertIn("STATEMENTA holds.", doc)
        self.assertNotIn("PROOFTEXT", doc)

    def test_label_missing_falls_back_to_the_card_text_and_says_so(self):
        self.run_main()
        doc = self.read(TEX)
        self.assertIn("NATURALF prose for F", doc)
        self.assertIn("statement from card text", doc)

    def test_symbols_that_text_fonts_lack_are_set_in_math_mode(self):
        self.run_main()
        doc = self.read(TEX)
        self.assertIn("$\\mathbf{1}$", doc)
        self.assertIn("$\\succeq$", doc)
        for glyph in ("\U0001D7D9", "\u2ab0", "\u211d", "\u2084", "\u1d40", "\u2075"):
            self.assertNotIn(glyph, doc)
        self.assertIn("$\\mathbf{R}$", doc)
        self.assertIn("$_{4}$", doc)
        self.assertIn("$^{5}$", doc)
        for glyph in ("\u00b9", "\u00b2", "\u00b3", "\U0001D53D"):
            self.assertNotIn(glyph, doc)
        self.assertIn("$\\mathbf{F}$", doc)

    @unittest.skipUnless(shutil.which("xelatex") and shutil.which("pdftotext"), "xelatex or pdftotext not installed")
    def test_the_document_compiles_and_outside_references_print_their_label(self):
        self.run_main()
        for _ in range(2):
            r = subprocess.run(["xelatex", "-interaction=nonstopmode", "-halt-on-error", TEX],
                               cwd=self.out, capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, r.stdout[-1500:])
        log = open(os.path.join(self.out, TEX.replace(".tex", ".log")), encoding="utf-8", errors="replace").read()
        self.assertNotIn("undefined references", log)
        text = subprocess.run(["pdftotext", os.path.join(self.out, TEX.replace(".tex", ".pdf")), "-"],
                              capture_output=True, text=True).stdout
        self.assertIn("thm:outside", text)
        self.assertNotIn("??", text)
        self.assertNotIn("*thm:a", text)         # the starred form of \\ref is not broken

    def test_a_definition_entry_shows_its_provenance_too(self):
        self.run_main()
        doc = self.read(TEX)
        self.assertIn("Lean: \\texttt{Lib.H}; card: \\texttt{d1}; manuscript label: \\texttt{sec:defs}", doc)

    def test_shared_definition_appears_once(self):
        self.run_main()
        self.assertEqual(self.read(TEX).count("NATURALD1"), 1)

    def test_provenance_line(self):
        self.run_main()
        doc = self.read(TEX)
        for token in ("Lib.A", "tA", "thm:a"):
            self.assertIn(token, doc)


class FrontierAndReproducibility(Case):
    def test_two_frontier_layers_are_separate(self):
        self.run_main()
        report = self.read(FRONTIER)
        stated = report.split("Stated in Lean, not yet proved")[1].split("##")[0]
        unstated = report.split("Not yet stated in Lean")[1].split("##")[0]
        self.assertIn("theorem B", stated)
        self.assertNotIn("theorem C", stated)
        self.assertIn("theorem C", unstated)
        self.assertNotIn("theorem B", unstated)

    def test_header_has_counts_and_links_the_report(self):
        self.run_main()
        doc = self.read(TEX)
        self.assertIn("5 of 7 theorem cards are proved in Lean; 4 of them appear here", doc)   # E is held back
        self.assertIn("\\href{run:%s}" % FRONTIER, doc)   # a real link, not just the file name

    def test_report_says_the_frontier_over_reports_when_a_card_has_no_proof_module(self):
        self.run_main()
        self.assertIn("over-reports", self.read(FRONTIER))

    def test_output_is_identical_across_runs(self):
        self.run_main()
        a = (self.read(TEX), self.read(FRONTIER))
        self.run_main()
        self.assertEqual(a, (self.read(TEX), self.read(FRONTIER)))

    def test_stale_output_is_detected_by_check_mode(self):
        self.run_main()
        self.assertEqual(self.run_main("--check")[0], 0)
        self.set_status("tB", "proved")
        self.edit_graph(lambda g: g["edges"].append(
            {"conclusion": "tB", "premises": ["d1"], "proof_module": "Lib.Proofs.B"}))
        code, err = self.run_main("--check")
        self.assertEqual(code, 1)
        self.assertIn(TEX, err)


class Failures(Case):
    def test_card_missing_on_disk_is_an_error(self):
        os.remove(os.path.join(self.proj, "cards", "tA.yaml"))
        code, err = self.run_main()
        self.assertEqual(code, 1)
        self.assertIn("tA", err)

    def test_dependency_cycle_is_an_error(self):
        self.edit_graph(lambda g: g["edges"].append(
            {"conclusion": "tA", "premises": ["tG"], "proof_module": "Lib.Proofs.A2"}))
        # tA now has two proof modules, one of which needs tG, which needs tA
        self.edit_graph(lambda g: g["edges"].__setitem__(0, {"conclusion": "tA", "premises": ["tG"],
                                                             "proof_module": "Lib.Proofs.A"}))
        code, err = self.run_main()
        self.assertEqual(code, 1)
        self.assertIn("cycle", err)


if __name__ == "__main__":
    unittest.main()
