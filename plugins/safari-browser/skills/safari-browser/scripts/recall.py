#!/usr/bin/env python3
"""Read-only, in-memory candidate organization; never opens a candidate URL."""
import argparse
import datetime as dt
import json
import re
import subprocess
import sys

SOURCES = ('history', 'bookmarks', 'cloud-tabs', 'downloads')


class RecallError(Exception):
    def __init__(self, message, code=1):
        super().__init__(message)
        self.code = code if code > 0 else 128 - code


def text(row, key, source, required=False):
    value = row.get(key)
    if value is None and not required:
        return None
    if not isinstance(value, str):
        raise RecallError(f'{source}: invalid {key} in CLI JSON')
    return value


def instant(value, source):
    if value is None:
        return None
    try:
        date = dt.datetime.fromisoformat(value.replace('Z', '+00:00'))
        if date.tzinfo is None:
            raise ValueError('missing timezone')
        return date.timestamp()
    except (ValueError, OverflowError, OSError):
        raise RecallError(f'{source}: invalid timestamp in CLI JSON') from None


def validate_row(source, row):
    if not isinstance(row, dict):
        raise RecallError(f'{source}: expected JSON objects')
    url = text(row, 'source_url' if source == 'downloads' else 'url', source, required=True)
    title = text(row, 'title', source)
    date = text(row, 'visit_time' if source == 'history' else 'date', source) if source in ('history', 'downloads') else None
    timestamp = instant(date, source)
    filename = text(row, 'filename', source, required=True) if source == 'downloads' else None
    folder = text(row, 'folder', source, required=True) if source == 'bookmarks' else None
    device = text(row, 'device', source, required=True) if source == 'cloud-tabs' else None
    if source == 'bookmarks' and not isinstance(row.get('reading_list'), bool):
        raise RecallError('bookmarks: invalid reading_list in CLI JSON')
    if source != 'downloads' and not url:
        raise RecallError(f'{source}: empty URL in CLI JSON')
    return url, title, date, timestamp, filename, folder, device


def summarize(records, coverage, offset=0, page_size=200, search=""):
    candidates = {}
    hints = []
    for source, rows in records.items():
        if source not in SOURCES or not isinstance(rows, list):
            raise RecallError('invalid source result shape')
        for row in rows:
            url, title, date, timestamp, filename, folder, device = validate_row(source, row)
            # Validate every row before filtering so schema drift cannot look
            # like a successful empty search.
            fields = [url, title, filename, device] if source in ('downloads', 'cloud-tabs') else [url, title]
            if source in ('downloads', 'cloud-tabs') and search and not any(search.lower() in (value or '').lower() for value in fields):
                continue
            if source == 'downloads' and not url:
                hints.append({'filename': filename, 'date': date})
                continue
            item = candidates.setdefault(url, {
                'url': url, 'titles': [], 'sources': [], 'latest_recorded_at': None,
                'history_matches': 0, 'reading_list': False, 'folders': [], 'devices': [],
                'filenames': [], '_instant': None})
            if source not in item['sources']:
                item['sources'].append(source)
            if title and title not in item['titles']:
                item['titles'].append(title)
            if timestamp is not None and (item['_instant'] is None or timestamp > item['_instant']):
                item['_instant'] = timestamp
                item['latest_recorded_at'] = date
            if source == 'history':
                item['history_matches'] += 1  # Retrieved matching rows, not lifetime visits.
            elif source == 'bookmarks':
                item['reading_list'] |= row['reading_list']
                if folder not in item['folders']:
                    item['folders'].append(folder)
            elif source == 'cloud-tabs':
                if device not in item['devices']:
                    item['devices'].append(device)
            elif filename not in item['filenames']:
                item['filenames'].append(filename)
    ordered = sorted(candidates.values(), key=lambda item: (
        item['_instant'] is None, -(item['_instant'] or 0),
        (item['titles'][0] if item['titles'] else item['url']).lower(), item['url']))
    for item in ordered:
        del item['_instant']
    end = offset + page_size
    return {'total_candidates': len(ordered), 'offset': offset,
            'next_offset': end if end < len(ordered) else None,
            'candidates': ordered[offset:end], 'download_hints': hints,
            'coverage': coverage, 'snapshot_note': 'Each invocation queries the sources again; URLs, not indices, identify candidates.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--search', default='')
    parser.add_argument('--since', help='History only: YYYY-MM-DD')
    parser.add_argument('--limit', type=int, default=500, help='History/download rows per source')
    parser.add_argument('--sources', nargs='+', choices=SOURCES, default=list(SOURCES))
    parser.add_argument('--offset', type=int, default=0)
    parser.add_argument('--page-size', type=int, default=200)
    args = parser.parse_args()
    if args.limit <= 0 or args.offset < 0 or args.page_size <= 0:
        parser.error('limit/page-size must be positive; offset must be nonnegative')
    if args.since is not None:
        try:
            if not re.fullmatch(r'[0-9]{4}-[0-9]{2}-[0-9]{2}', args.since):
                raise ValueError('invalid date shape')
            dt.date.fromisoformat(args.since)
        except ValueError:
            parser.error('--since must be a real YYYY-MM-DD date')
        if 'history' not in args.sources:
            parser.error('--since applies only to history; include history in --sources')
    if len(set(args.sources)) != len(args.sources):
        parser.error('sources must not repeat')
    # Collection is defined below; no partial report is printed on an error.
    try:
        records, coverage = collect(args)
        print(json.dumps(summarize(records, coverage, args.offset, args.page_size, args.search), ensure_ascii=True, indent=2))
    except (RecallError, OSError, UnicodeError) as error:
        print(f'Recall stopped: {error}', file=sys.stderr)
        return error.code if isinstance(error, RecallError) else 1
    return 0


def collect(args):
    records, coverage = {}, {}
    for source in args.sources:
        command = ['safari-browser', source, '--json']
        limited = source in ('history', 'downloads')
        if limited:
            command += ['--limit', str(args.limit)]
        if args.search and source in ('history', 'bookmarks'):
            command += ['--search=' + args.search]
        if args.since and source == 'history':
            command += ['--since', args.since]
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=60, check=False)
        except subprocess.TimeoutExpired as timeout:
            if timeout.stderr:
                partial = timeout.stderr.decode('utf-8', errors='replace') if isinstance(timeout.stderr, bytes) else timeout.stderr
                sys.stderr.write(partial)
            raise RecallError(f'{source} timed out; no candidate report was produced', 124) from None
        # Keep the first line AND the full diagnostics; never merge stderr
        # into parseable JSON and never use a truncating live head/tail pipe.
        lines = result.stderr.splitlines()
        first = lines[0] if lines else None
        if result.stderr:
            sys.stderr.write(result.stderr)
        if result.returncode:
            raise RecallError(f'{source} exited {result.returncode}; collection stopped', result.returncode)
        if any(line.startswith('⚠ BLOCKING DIALOG') for line in lines):
            raise RecallError(f'{source} returned a blocking-dialog warning; inspect it before any next action')
        try:
            payload = json.loads(result.stdout)
        except json.JSONDecodeError:
            raise RecallError(f'{source} did not return valid JSON; check the installed CLI version') from None
        if not isinstance(payload, list):
            raise RecallError(f'{source}: expected a JSON array')
        for row in payload:
            validate_row(source, row)
        records[source] = payload
        coverage[source] = {'returned_rows': len(payload), 'limit': args.limit if limited else None,
                            'at_limit': limited and len(payload) >= args.limit,
                            'first_stderr_line': first, 'has_diagnostics': bool(lines)}
    return records, coverage


if __name__ == '__main__':
    raise SystemExit(main())
