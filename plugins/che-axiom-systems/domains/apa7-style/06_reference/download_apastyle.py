#!/usr/bin/env python3
"""
Download APA Style website from Wayback Machine
"""

import requests
import time
import os
import re
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urljoin, urlparse

# Wayback Machine base URL
WAYBACK_BASE = "https://web.archive.org/web/20250104183002/"
APA_BASE = "https://apastyle.apa.org/"

# Output directory
OUTPUT_DIR = Path(__file__).parent / "apastyle_mirror"

# All URLs to download (extracted from the Style and Grammar Guidelines page)
URLS = [
    # Main pages
    "",
    "style-grammar-guidelines",
    "about-apa-style",
    "jars",
    "instructional-aids",
    "beginners",

    # Paper Format
    "style-grammar-guidelines/paper-format",
    "style-grammar-guidelines/paper-format/accessibility",
    "style-grammar-guidelines/paper-format/font",
    "style-grammar-guidelines/paper-format/headings",
    "style-grammar-guidelines/paper-format/line-spacing",
    "style-grammar-guidelines/paper-format/margins",
    "style-grammar-guidelines/paper-format/order-pages",
    "style-grammar-guidelines/paper-format/page-header",
    "style-grammar-guidelines/paper-format/paragraph-format",
    "style-grammar-guidelines/paper-format/sample-papers",
    "style-grammar-guidelines/paper-format/title-page",

    # In-Text Citations
    "style-grammar-guidelines/citations",
    "style-grammar-guidelines/citations/appropriate-citation",
    "style-grammar-guidelines/citations/basic-principles",
    "style-grammar-guidelines/citations/classroom-intranet-sources",
    "style-grammar-guidelines/citations/paraphrasing",
    "style-grammar-guidelines/citations/personal-communications",
    "style-grammar-guidelines/citations/plagiarism",
    "style-grammar-guidelines/citations/quotations",
    "style-grammar-guidelines/citations/quoting-participants",
    "style-grammar-guidelines/citations/secondary-sources",

    # Mechanics of Style
    "style-grammar-guidelines/mechanics-style",
    "style-grammar-guidelines/abbreviations",
    "style-grammar-guidelines/capitalization",
    "style-grammar-guidelines/italics-quotations",
    "style-grammar-guidelines/lists",
    "style-grammar-guidelines/numbers",
    "style-grammar-guidelines/punctuation",
    "style-grammar-guidelines/spelling-hyphenation",

    # Bias-Free Language
    "style-grammar-guidelines/bias-free-language",
    "style-grammar-guidelines/bias-free-language/age",
    "style-grammar-guidelines/bias-free-language/disability",
    "style-grammar-guidelines/bias-free-language/gender",
    "style-grammar-guidelines/bias-free-language/general-principles",
    "style-grammar-guidelines/bias-free-language/historical-context",
    "style-grammar-guidelines/bias-free-language/intersectionality",
    "style-grammar-guidelines/bias-free-language/research-participation",
    "style-grammar-guidelines/bias-free-language/racial-ethnic-minorities",
    "style-grammar-guidelines/bias-free-language/sexual-orientation",
    "style-grammar-guidelines/bias-free-language/socioeconomic-status",

    # Tables and Figures
    "style-grammar-guidelines/tables-figures",
    "style-grammar-guidelines/tables-figures/colors",
    "style-grammar-guidelines/tables-figures/figures",
    "style-grammar-guidelines/tables-figures/sample-figures",
    "style-grammar-guidelines/tables-figures/sample-tables",
    "style-grammar-guidelines/tables-figures/tables",

    # References
    "style-grammar-guidelines/references",
    "style-grammar-guidelines/references/archival",
    "style-grammar-guidelines/references/basic-principles",
    "style-grammar-guidelines/references/database-information",
    "style-grammar-guidelines/references/dois-urls",
    "style-grammar-guidelines/references/elements-list-entry",
    "style-grammar-guidelines/references/missing-information",
    "style-grammar-guidelines/references/examples",
    "style-grammar-guidelines/references/meta-analysis-references",
    "style-grammar-guidelines/references/lists-vs-bibliographies",
    "style-grammar-guidelines/references/works-included",

    # Reference Examples (detailed)
    "style-grammar-guidelines/references/examples/journal-article-references",
    "style-grammar-guidelines/references/examples/magazine-article-references",
    "style-grammar-guidelines/references/examples/newspaper-article-references",
    "style-grammar-guidelines/references/examples/blog-post-references",
    "style-grammar-guidelines/references/examples/uptodate-article-references",
    "style-grammar-guidelines/references/examples/book-references",
    "style-grammar-guidelines/references/examples/diagnostic-manual-references",
    "style-grammar-guidelines/references/examples/childrens-book-references",
    "style-grammar-guidelines/references/examples/classroom-course-references",
    "style-grammar-guidelines/references/examples/religious-work-references",
    "style-grammar-guidelines/references/examples/edited-book-chapter-references",
    "style-grammar-guidelines/references/examples/dictionary-entry-references",
    "style-grammar-guidelines/references/examples/wikipedia-references",
    "style-grammar-guidelines/references/examples/report-government-agency-references",
    "style-grammar-guidelines/references/examples/report-individual-authors-references",
    "style-grammar-guidelines/references/examples/brochure-references",
    "style-grammar-guidelines/references/examples/ethics-code-references",
    "style-grammar-guidelines/references/examples/fact-sheet-references",
    "style-grammar-guidelines/references/examples/iso-standard-references",
    "style-grammar-guidelines/references/examples/press-release-references",
    "style-grammar-guidelines/references/examples/white-paper-references",
    "style-grammar-guidelines/references/examples/conference-presentation-references",
    "style-grammar-guidelines/references/examples/conference-proceeding-references",
    "style-grammar-guidelines/references/examples/published-dissertation-references",
    "style-grammar-guidelines/references/examples/unpublished-dissertation-references",
    "style-grammar-guidelines/references/examples/eric-database-references",
    "style-grammar-guidelines/references/examples/preprint-article-references",
    "style-grammar-guidelines/references/examples/data-set-references",
    "style-grammar-guidelines/references/examples/toolbox-references",
    "style-grammar-guidelines/references/examples/artwork-references",
    "style-grammar-guidelines/references/examples/clip-art-references",
    "style-grammar-guidelines/references/examples/film-television-references",
    "style-grammar-guidelines/references/examples/musical-score-references",
    "style-grammar-guidelines/references/examples/online-course-references",
    "style-grammar-guidelines/references/examples/podcast-references",
    "style-grammar-guidelines/references/examples/powerpoint-references",
    "style-grammar-guidelines/references/examples/radio-broadcast-references",
    "style-grammar-guidelines/references/examples/ted-talk-references",
    "style-grammar-guidelines/references/examples/transcript-audiovisual-work-references",
    "style-grammar-guidelines/references/examples/youtube-references",
    "style-grammar-guidelines/references/examples/facebook-references",
    "style-grammar-guidelines/references/examples/instagram-references",
    "style-grammar-guidelines/references/examples/linkedin-references",
    "style-grammar-guidelines/references/examples/online-forum-references",
    "style-grammar-guidelines/references/examples/tiktok-references",
    "style-grammar-guidelines/references/examples/x-references",
    "style-grammar-guidelines/references/examples/webpage-website-references",
    "style-grammar-guidelines/references/examples/clinical-practice-references",
    "style-grammar-guidelines/references/examples/open-educational-resource-references",
    "style-grammar-guidelines/references/examples/whole-website-references",

    # Grammar
    "style-grammar-guidelines/grammar",
    "style-grammar-guidelines/grammar/active-passive-voice",
    "style-grammar-guidelines/grammar/anthropomorphism",
    "style-grammar-guidelines/grammar/first-person-pronouns",
    "style-grammar-guidelines/grammar/logical-comparisons",
    "style-grammar-guidelines/grammar/plural-nouns",
    "style-grammar-guidelines/grammar/possessive-adjectives",
    "style-grammar-guidelines/grammar/possessive-nouns",
    "style-grammar-guidelines/grammar/singular-they",
    "style-grammar-guidelines/grammar/verb-tense",

    # Publication Process
    "style-grammar-guidelines/research-publication",
    "style-grammar-guidelines/research-publication/dissertation-thesis",
    "style-grammar-guidelines/research-publication/correction-notices",
    "style-grammar-guidelines/research-publication/cover-letters",
    "style-grammar-guidelines/research-publication/open-science",
    "style-grammar-guidelines/research-publication/response-reviewers",

    # Instructional Aids
    "instructional-aids/handouts-guides",
    "instructional-aids/tutorials-webinars",
]


class HTMLToMarkdown(HTMLParser):
    """Simple HTML to Markdown converter"""

    def __init__(self):
        super().__init__()
        self.output = []
        self.in_main = False
        self.in_nav = False
        self.in_footer = False
        self.tag_stack = []
        self.list_level = 0

    def handle_starttag(self, tag, attrs):
        attrs_dict = dict(attrs)

        if tag == 'main':
            self.in_main = True
        elif tag == 'nav':
            self.in_nav = True
        elif tag == 'footer':
            self.in_footer = True

        if not self.in_main or self.in_nav:
            return

        self.tag_stack.append(tag)

        if tag == 'h1':
            self.output.append('\n# ')
        elif tag == 'h2':
            self.output.append('\n## ')
        elif tag == 'h3':
            self.output.append('\n### ')
        elif tag == 'h4':
            self.output.append('\n#### ')
        elif tag == 'p':
            self.output.append('\n\n')
        elif tag == 'ul' or tag == 'ol':
            self.list_level += 1
        elif tag == 'li':
            self.output.append('\n' + '  ' * (self.list_level - 1) + '- ')
        elif tag == 'a':
            href = attrs_dict.get('href', '')
            if href and not href.startswith('#') and not href.startswith('javascript'):
                self.output.append('[')
        elif tag == 'strong' or tag == 'b':
            self.output.append('**')
        elif tag == 'em' or tag == 'i':
            self.output.append('*')
        elif tag == 'code':
            self.output.append('`')
        elif tag == 'br':
            self.output.append('\n')

    def handle_endtag(self, tag):
        if tag == 'main':
            self.in_main = False
        elif tag == 'nav':
            self.in_nav = False
        elif tag == 'footer':
            self.in_footer = False

        if not self.in_main or self.in_nav:
            return

        if self.tag_stack and self.tag_stack[-1] == tag:
            self.tag_stack.pop()

        if tag in ('h1', 'h2', 'h3', 'h4'):
            self.output.append('\n')
        elif tag == 'ul' or tag == 'ol':
            self.list_level = max(0, self.list_level - 1)
        elif tag == 'a':
            # Note: we'd need to track the href to output it here
            pass
        elif tag == 'strong' or tag == 'b':
            self.output.append('**')
        elif tag == 'em' or tag == 'i':
            self.output.append('*')
        elif tag == 'code':
            self.output.append('`')

    def handle_data(self, data):
        if not self.in_main or self.in_nav or self.in_footer:
            return
        self.output.append(data.strip())

    def get_markdown(self):
        return ''.join(self.output)


def download_page(url_path: str) -> str | None:
    """Download a page from Wayback Machine"""
    full_url = WAYBACK_BASE + APA_BASE + url_path

    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        }
        response = requests.get(full_url, headers=headers, timeout=30)
        if response.status_code == 200:
            return response.text
        else:
            print(f"  Error {response.status_code}: {url_path}")
            return None
    except Exception as e:
        print(f"  Exception: {url_path} - {e}")
        return None


def html_to_simple_text(html: str) -> str:
    """Extract text content from HTML, focusing on main content"""
    # Remove script and style tags
    html = re.sub(r'<script[^>]*>.*?</script>', '', html, flags=re.DOTALL | re.IGNORECASE)
    html = re.sub(r'<style[^>]*>.*?</style>', '', html, flags=re.DOTALL | re.IGNORECASE)

    # Extract main content if possible
    main_match = re.search(r'<main[^>]*>(.*?)</main>', html, re.DOTALL | re.IGNORECASE)
    if main_match:
        html = main_match.group(1)

    # Convert headers
    html = re.sub(r'<h1[^>]*>(.*?)</h1>', r'\n# \1\n', html, flags=re.DOTALL | re.IGNORECASE)
    html = re.sub(r'<h2[^>]*>(.*?)</h2>', r'\n## \1\n', html, flags=re.DOTALL | re.IGNORECASE)
    html = re.sub(r'<h3[^>]*>(.*?)</h3>', r'\n### \1\n', html, flags=re.DOTALL | re.IGNORECASE)
    html = re.sub(r'<h4[^>]*>(.*?)</h4>', r'\n#### \1\n', html, flags=re.DOTALL | re.IGNORECASE)

    # Convert lists
    html = re.sub(r'<li[^>]*>', '\n- ', html, flags=re.IGNORECASE)

    # Convert paragraphs
    html = re.sub(r'<p[^>]*>', '\n\n', html, flags=re.IGNORECASE)
    html = re.sub(r'</p>', '', html, flags=re.IGNORECASE)

    # Convert line breaks
    html = re.sub(r'<br\s*/?>', '\n', html, flags=re.IGNORECASE)

    # Convert emphasis
    html = re.sub(r'<(strong|b)[^>]*>(.*?)</\1>', r'**\2**', html, flags=re.DOTALL | re.IGNORECASE)
    html = re.sub(r'<(em|i)[^>]*>(.*?)</\1>', r'*\2*', html, flags=re.DOTALL | re.IGNORECASE)

    # Remove remaining tags
    html = re.sub(r'<[^>]+>', '', html)

    # Clean up whitespace
    html = re.sub(r'\n{3,}', '\n\n', html)
    html = re.sub(r' +', ' ', html)

    # Decode HTML entities
    html = html.replace('&amp;', '&')
    html = html.replace('&lt;', '<')
    html = html.replace('&gt;', '>')
    html = html.replace('&quot;', '"')
    html = html.replace('&#39;', "'")
    html = html.replace('&nbsp;', ' ')

    return html.strip()


def save_page(url_path: str, content: str):
    """Save page content as markdown"""
    # Create directory structure
    if url_path:
        file_path = OUTPUT_DIR / (url_path.replace('/', '_') + '.md')
    else:
        file_path = OUTPUT_DIR / 'index.md'

    file_path.parent.mkdir(parents=True, exist_ok=True)

    # Convert to markdown
    markdown = html_to_simple_text(content)

    # Add source URL header
    header = f"---\nsource: https://apastyle.apa.org/{url_path}\narchive: {WAYBACK_BASE}{APA_BASE}{url_path}\n---\n\n"

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(header + markdown)

    return file_path


def main():
    """Main download function"""
    print(f"Downloading {len(URLS)} pages from APA Style via Wayback Machine...")
    print(f"Output directory: {OUTPUT_DIR}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    success = 0
    failed = 0

    for i, url_path in enumerate(URLS):
        # Check if file already exists
        if url_path:
            file_path = OUTPUT_DIR / (url_path.replace('/', '_') + '.md')
        else:
            file_path = OUTPUT_DIR / 'index.md'

        if file_path.exists() and file_path.stat().st_size > 500:
            print(f"[{i+1}/{len(URLS)}] Skipping (exists): {url_path or 'index'}")
            success += 1
            continue

        print(f"[{i+1}/{len(URLS)}] Downloading: {url_path or 'index'}")

        html = download_page(url_path)

        if html:
            save_path = save_page(url_path, html)
            print(f"  Saved: {save_path.name}")
            success += 1
        else:
            failed += 1

        # Be nice to the server - longer delay to avoid rate limiting
        time.sleep(3)

    print(f"\nDone! Success: {success}, Failed: {failed}")
    print(f"Files saved to: {OUTPUT_DIR}")


if __name__ == '__main__':
    main()
