# Echo Product Specification

## Product idea

Echo is a flexible personal journal, memory archive, and life log. It should make capturing a thought or moment easy without turning reflection into a chore.

The guiding principle is:

> I write however I want. Echo quietly helps organize and preserve it.

Echo should feel personal, calm, warm, modern, private, Apple-native, and slightly editorial. It should not behave like a task manager, social network, habit tracker, or self-improvement game. Missing a day is neutral.

## Core concept

A **day** is a calendar-day container. An **entry** is something captured during that day. A day can contain one long entry or many small entries, and both patterns are first-class.

The first usable version focuses on text. Media, voice, imported events, richer highlights, and cross-app context are later extensions.

## Primary navigation

Echo has three primary areas:

1. **Today** — the fastest path to writing and reviewing the current day.
2. **Timeline** — chronological access to previous days and day details.
3. **Highlights** — a curated collection of meaningful moments.

Settings belongs in a toolbar or platform-appropriate settings surface, not a fourth primary tab.

## Today

Today presents the date, a low-friction way to write, and the day's entries in chronological order. It supports creating, opening, editing, deleting, and highlighting an entry. With no entries, it presents a calm empty state—not a warning or missed-day indicator.

Writing never requires a mood, tag, prompt, rating, category, or other metadata first.

## Timeline and day detail

Timeline groups previous entries by calendar day. Day Detail prioritizes readable chronological entries and later accommodates an organized journal, highlights, media, and Hub-provided context.

## Highlights

The MVP highlights entire entries. The eventual model should be able to reference passages, media, organized journals, or other Echo entities without invalidating the first version.

## Raw and assisted writing

The user's original text is immutable with respect to AI operations: cleanup, polish, and daily organization create separate output. Assisted text must never overwrite raw text.

AI is optional and should preserve meaning, personality, chronology, events, and emotions. It must not invent details or turn personal writing into corporate prose. A replaceable local mock is used before any real provider is introduced.

## MVP boundary

The MVP includes text entries, local persistence, Today, Timeline, Day Detail, entry highlights, a mock AI boundary, organized daily journals, tests, and documentation.

It excludes accounts, authentication, sync, a backend, real AI calls, Hub or Ambition integration, media capture, voice transcription, analytics, tags, location, gamification, notifications, widgets, watchOS, and public sharing.

## Current implementation boundary

Phase 1 adds the tested journal domain: entries, captured calendar-day identity, chronological grouping, independent highlight relationships, and repository contracts. It intentionally contains no SwiftData schema, concrete repository, AI service, sample personal data, or interactive journal workflow.
