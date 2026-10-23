#!/usr/bin/env python3
"""Profile one day's working time from local activity signals.

Usage: timeline.py YYYY-MM-DD [EXTRA_EVENTS_TSV]

Local signals: Claude Code prompts (interactive sessions only), git commits,
and macOS display on/off from `pmset -g log`. EXTRA_EVENTS_TSV adds events the
caller collected from APIs, one per line:
    START_ISO <TAB> END_ISO_OR_EMPTY <TAB> SOURCE <TAB> LABEL
A row with an END is an interval (a meeting); a row without one is a point event.
"""

import json
import re
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple

IDLE_GAP = timedelta(minutes=15)
LEAD_TIME = timedelta(minutes=5)
MIN_AWAY = timedelta(minutes=5)
MAX_MEETING = timedelta(hours=3)
DEFAULT_MEETING = timedelta(minutes=30)
REPO = Path.home() / "Documents/valkai/onyx"
PROJECTS = Path.home() / ".claude/projects"
TICKET_RE = re.compile(r"eng-(\d+)", re.IGNORECASE)
SKIP_PROMPT_RE = re.compile(r"^(<|Another Claude session|You are )")
MEETING_SOURCE = "meeting"


@dataclass
class Event:
    start: datetime
    end: Optional[datetime]
    source: str
    label: str


def parse_time(value: str) -> datetime:
    return datetime.fromisoformat(value.strip().replace("Z", "+00:00")).astimezone()


def ticket_label(*texts: str) -> Optional[str]:
    for text in texts:
        match = TICKET_RE.search(text or "")
        if match:
            return f"ENG-{match.group(1)}"
    return None


def claude_events(day: str) -> List[Event]:
    events: List[Event] = []
    day_start = datetime.strptime(day, "%Y-%m-%d").timestamp()
    for path in PROJECTS.rglob("*.jsonl"):
        if "subagents" in path.parts or path.stat().st_mtime < day_start:
            continue
        title, prompts, cwd, branch, interactive = "", [], "", "", True
        for line in path.open(errors="ignore"):
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            if entry.get("type") == "ai-title":
                title = entry.get("aiTitle", title)
            if entry.get("type") != "user" or "timestamp" not in entry:
                continue
            if entry.get("entrypoint") == "sdk-cli":
                interactive = False
                break
            content = entry.get("message", {}).get("content")
            if not isinstance(content, str) or entry.get("isMeta") or SKIP_PROMPT_RE.match(content):
                continue
            when = parse_time(entry["timestamp"])
            if when.strftime("%F") == day:
                prompts.append(when)
                cwd, branch = entry.get("cwd", cwd), entry.get("gitBranch", branch)
        if not interactive or not prompts:
            continue
        label = ticket_label(branch, cwd) or f"session: {title or 'untitled'}"
        events += [Event(t, None, "claude", label) for t in prompts]
    return events


def git_events(day: str, next_day: str) -> List[Event]:
    name = subprocess.run(["git", "-C", str(REPO), "config", "user.name"],
                          capture_output=True, text=True).stdout.strip()
    out = subprocess.run(
        ["git", "-C", str(REPO), "log", "--all", f"--author={name}",
         f"--since={day} 00:00", f"--until={next_day} 00:00", "--format=%aI%x09%s"],
        capture_output=True, text=True).stdout
    events = []
    for line in out.splitlines():
        when, _, subject = line.partition("\t")
        if parse_time(when).strftime("%F") == day:
            events.append(Event(parse_time(when), None, "git", ticket_label(subject) or "git commit"))
    return events


def screen_periods(day: str) -> Tuple[Optional[List[Tuple[datetime, datetime]]], List[Tuple[datetime, datetime]]]:
    """Return (screen-on periods, screen-off periods of at least MIN_AWAY) on DAY from the macOS power log.

    Screen-on periods are None when the log does not reach back to the start of DAY.
    """
    out = subprocess.run(["pmset", "-g", "log"], capture_output=True, text=True).stdout
    day_start = datetime.strptime(day, "%Y-%m-%d").astimezone()
    day_end = min(day_start + timedelta(days=1), datetime.now().astimezone())
    on_periods, away = [], []
    on_at: Optional[datetime] = None
    off_at: Optional[datetime] = None
    lines = [line for line in out.splitlines() if "Display is turned" in line]
    if not lines or lines[0][:10] >= day:
        return None, []
    for line in lines:
        when = datetime.strptime(line[:25], "%Y-%m-%d %H:%M:%S %z").astimezone()
        turned_on = "turned on" in line
        if when < day_start:
            on_at, off_at = (day_start, None) if turned_on else (None, day_start)
            continue
        if when >= day_end:
            break
        if turned_on and on_at is None:
            on_at = when
            if off_at and when - off_at >= MIN_AWAY:
                away.append((off_at, when))
            off_at = None
        elif not turned_on and on_at is not None:
            on_periods.append((on_at, when))
            on_at, off_at = None, when
    if on_at is not None:
        on_periods.append((on_at, day_end))
    return on_periods, away


def extra_events(path: str) -> List[Event]:
    events = []
    for line in Path(path).read_text().splitlines():
        parts = line.split("\t")
        if len(parts) < 4 or not parts[0].strip():
            continue
        start = parse_time(parts[0])
        end = parse_time(parts[1]) if parts[1].strip() else None
        if parts[2] == MEETING_SOURCE:
            if end is None or not (start < end <= start + MAX_MEETING):
                end = start + DEFAULT_MEETING
        events.append(Event(start, end, parts[2].strip(), parts[3].strip()))
    return events


def minutes(start: datetime, end: datetime) -> List[datetime]:
    first = start.replace(second=0, microsecond=0)
    return [first + timedelta(minutes=i) for i in range(int((end - first).total_seconds() // 60))]


def label_spans(events: List[Event], away: List[Tuple[datetime, datetime]],
                lead: timedelta) -> Dict[str, List[Tuple[datetime, datetime]]]:
    """Group each label's point events into spans; a gap over IDLE_GAP or a screen-off period ends a span."""
    by_label: Dict[str, List[datetime]] = defaultdict(list)
    spans: Dict[str, List[Tuple[datetime, datetime]]] = defaultdict(list)
    for event in events:
        if event.end:
            spans[event.label].append((event.start, event.end))
        else:
            by_label[event.label].append(event.start)
    for label, times in by_label.items():
        times.sort()
        start = prev = times[0]
        for t in times[1:]:
            broken = any(prev <= a_start and a_end <= t for a_start, a_end in away)
            if t - prev > IDLE_GAP or broken:
                spans[label].append((start - lead, prev))
                start = t
            prev = t
        spans[label].append((start - lead, prev))
    return spans


def minute_owners(events: List[Event], away: List[Tuple[datetime, datetime]],
                  lead: timedelta) -> Dict[datetime, List[str]]:
    owners: Dict[datetime, List[str]] = defaultdict(list)
    for label, spans in label_spans(events, away, lead).items():
        for start, end in spans:
            for minute in minutes(start, end):
                if label not in owners[minute]:
                    owners[minute].append(label)
    return owners


def label_totals(owners: Dict[datetime, List[str]], meetings: set) -> Dict[str, float]:
    """Split each minute evenly between its labels; a meeting takes the whole minute."""
    totals: Dict[str, float] = defaultdict(float)
    for labels in owners.values():
        share = [label for label in labels if label in meetings] or labels
        for label in share:
            totals[label] += 1 / len(share)
    return totals


def fmt_hours(count: float) -> str:
    return f"{count / 60:.1f}h"


def fmt_span(start: datetime, end: datetime) -> str:
    length = int((end - start).total_seconds() // 60)
    return f"{start:%H:%M}–{end:%H:%M} ({length // 60}h{length % 60:02d})"


def main() -> None:
    day = sys.argv[1]
    next_day = (datetime.strptime(day, "%Y-%m-%d") + timedelta(days=1)).strftime("%F")
    events = claude_events(day)
    events += git_events(day, next_day)
    if len(sys.argv) > 2:
        events += extra_events(sys.argv[2])
    screen_on, away = screen_periods(day)
    meetings = {e.label for e in events if e.source == MEETING_SOURCE}

    on_minutes = {m for start, end in screen_on or [] for m in minutes(start, end)}
    slack_lead = {m for e in events if e.source == "slack" for m in minutes(e.start - LEAD_TIME, e.start)}
    floor = minute_owners(events, away, timedelta(0))
    loose = minute_owners(events, away, LEAD_TIME)
    ceiling = loose if screen_on is None else {
        m: labels for m, labels in loose.items() if m in floor or m in on_minutes or m in slack_lead}
    floor_totals, ceiling_totals = label_totals(floor, meetings), label_totals(ceiling, meetings)

    active = sorted(ceiling)
    blocks: List[Tuple[datetime, datetime, set]] = []
    for minute in active:
        if blocks and minute - blocks[-1][1] <= timedelta(minutes=1):
            blocks[-1] = (blocks[-1][0], minute + timedelta(minutes=1), blocks[-1][2] | set(ceiling[minute]))
        else:
            blocks.append((minute, minute + timedelta(minutes=1), set(ceiling[minute])))

    print(f"# Timeline {day}\n")
    if not active:
        print("No activity found.")
        return
    longest = max(blocks, key=lambda b: b[1] - b[0])
    meeting_minutes = sum(1 for labels in ceiling.values() if any(l in meetings for l in labels))
    away_minutes = sum((e - s).total_seconds() / 60 for s, e in away if active[0] <= s <= active[-1])
    lead_m, gap_m, away_m = (int(x.total_seconds() // 60) for x in (LEAD_TIME, IDLE_GAP, MIN_AWAY))
    print("## Summary")
    print(f"- day: {active[0]:%H:%M}–{blocks[-1][1]:%H:%M}")
    print(f"- active floor (no lead): {fmt_hours(len(floor))}")
    print(f"- active ceiling ({lead_m}m lead, screen-on or Slack only): {fmt_hours(len(ceiling))}")
    print(f"- active midpoint: {fmt_hours((len(floor) + len(ceiling)) / 2)}")
    print(f"- active unadjusted ({lead_m}m lead everywhere): {fmt_hours(len(loose))}")
    if screen_on is None:
        print("- screen on: no data (power log does not reach this day); ceiling not screen-adjusted")
    elif screen_on:
        print(f"- screen on: {fmt_hours(len(on_minutes))} in {len(screen_on)} stretches, "
              f"{screen_on[0][0]:%H:%M}–{screen_on[-1][1]:%H:%M}")
    print(f"- screen off ≥{away_m}m: {len(away)} times, {fmt_hours(away_minutes)}")
    print(f"- meetings: {fmt_hours(meeting_minutes)} · longest block: {fmt_span(longest[0], longest[1])}")
    print(f"- rules: {gap_m}m idle gap, overlapping work split evenly, meetings take priority\n")
    print("## By work item (floor / ceiling; shares can shift either way)")
    for label, count in sorted(ceiling_totals.items(), key=lambda kv: -kv[1]):
        if count >= 1:
            print(f"- {label}: {fmt_hours(floor_totals.get(label, 0))} / {fmt_hours(count)}")
    print("\n## Blocks (ceiling)")
    for start, end, labels in blocks:
        print(f"- {fmt_span(start, end)}: {', '.join(sorted(labels))}")
    print("\n## Events")
    print("time\tend\tsource\tlabel")
    for event in sorted(events, key=lambda e: e.start):
        end = f"{event.end:%H:%M}" if event.end else ""
        print(f"{event.start:%H:%M:%S}\t{end}\t{event.source}\t{event.label}")
    for start, end in screen_on or []:
        print(f"{start:%H:%M:%S}\t{end:%H:%M}\tscreen-on\tat laptop")


if __name__ == "__main__":
    main()
