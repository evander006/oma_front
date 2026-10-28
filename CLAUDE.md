# CLAUDE.md

## Проект

Два клиента приложения «ОМА. Дом», цель — визуально один в один с официальным приложением ОМА:
- `lib/` — Flutter (тема в `lib/theme/`, общие виджеты в `lib/widgets/`, экраны в `lib/features/`).
- `android_companion/` — нативный Kotlin, UI собирается в коде. Все цвета и базовые стили — `Style.kt`.

Правила для дизайн-задач:
- Меняй только стили и разметку. Логику, API, навигацию и стейт не трогай без запроса.
- Цвета, шрифты, радиусы и отступы бери из темы (`lib/theme/`, `Style.kt`), не хардкодь.
- Задача про один элемент (например, кнопку) — правь только его файл. Нужен ещё файл — сначала спроси.
- `.tmp_oma_be/` — копия бэкенда, не редактировать.

## Общие правила

Взято из [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) (MIT).

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.
- Remove imports/variables/functions that YOUR changes made unused; leave pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

- Turn tasks into verifiable goals ("Fix the bug" → "reproduce it, then make it pass").
- For multi-step tasks, state a brief plan with a check for each step.
