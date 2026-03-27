#!/usr/bin/env python3
"""
Split APA7manual.md into chapter files
"""

from pathlib import Path

# Define chapter boundaries (line numbers are 1-indexed)
CHAPTERS = [
    (1, 175, "00_front_matter.md", "Front Matter (Tables, Figures, Editorial Staff, Acknowledgments)"),
    (176, 332, "00_introduction.md", "Introduction"),
    (333, 712, "01_scholarly_writing.md", "Chapter 1: Scholarly Writing and Publishing Principles"),
    (713, 1243, "02_paper_format.md", "Chapter 2: Paper Elements and Format"),
    (1244, 2265, "03_jars.md", "Chapter 3: Journal Article Reporting Standards"),
    (2266, 2704, "04_writing_style.md", "Chapter 4: Writing Style and Grammar"),
    (2705, 2933, "05_bias_free_language.md", "Chapter 5: Bias-Free Language Guidelines"),
    (2934, 4448, "06_mechanics.md", "Chapter 6: Mechanics of Style"),
    (4449, 5570, "07_tables_figures.md", "Chapter 7: Tables and Figures"),
    (5571, 6169, "08_in_text_citations.md", "Chapter 8: Works Credited in the Text"),
    (6170, 6874, "09_reference_list.md", "Chapter 9: Reference List"),
    (6875, 8351, "10_reference_examples.md", "Chapter 10: Reference Examples"),
    (8352, 8880, "11_legal_references.md", "Chapter 11: Legal References"),
    (8881, 9317, "12_publication_process.md", "Chapter 12: Publication Process"),
    (9318, 9397, "13_credits.md", "Credits for Adapted Tables, Figures, and Papers"),
    (9398, 9519, "14_references.md", "References"),
    (9520, 99999, "15_index.md", "Index"),
]

def main():
    base_dir = Path(__file__).parent
    source_file = base_dir / "APA7manual.md"
    output_dir = base_dir / "APA7manual"

    # Read source file
    with open(source_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    total_lines = len(lines)
    print(f"Source file: {total_lines} lines")

    # Create output directory
    output_dir.mkdir(exist_ok=True)

    # Split into chapters
    for start, end, filename, title in CHAPTERS:
        # Adjust for 0-indexed list
        start_idx = start - 1
        end_idx = min(end, total_lines)

        chapter_lines = lines[start_idx:end_idx]

        # Fix image paths (relative to parent directory)
        chapter_content = ''.join(chapter_lines)
        chapter_content = chapter_content.replace('](apa7_images/', '](../apa7_images/')

        # Add header comment
        header = f"<!-- {title} -->\n<!-- Lines {start}-{end_idx} from APA7manual.md -->\n\n"

        output_path = output_dir / filename
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(header + chapter_content)

        print(f"  {filename}: {len(chapter_lines)} lines ({start}-{end_idx})")

    # Create README index
    readme_content = """# APA 7th Edition Publication Manual

Split version of APA7manual.md for easier reading.

## Chapters

| File | Content | Lines |
|------|---------|-------|
"""
    for start, end, filename, title in CHAPTERS:
        end_actual = min(end, total_lines)
        line_count = end_actual - start + 1
        readme_content += f"| [{filename}]({filename}) | {title} | {line_count} |\n"

    readme_content += """
## Notes

- Each file is < 2000 lines for easy reading
- Image paths point to `../apa7_images/`
- For full-text search, use `../APA7manual.md`

## Source

Generated from `APA7manual.md` using `split_manual.py`
"""

    with open(output_dir / "README.md", 'w', encoding='utf-8') as f:
        f.write(readme_content)

    print(f"\nCreated README.md")
    print(f"Done! Files saved to {output_dir}")

if __name__ == '__main__':
    main()
