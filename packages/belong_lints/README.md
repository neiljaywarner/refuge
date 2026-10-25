# belong_lints

Analyzer plugin for Belong-specific rules (`no_print_use_app_logger`, `prefer_use_text_editing_controller`, etc.).

## Deferred rules

- **Dot shorthands** ([#610](https://github.com/neiljaywarner/refuge/issues/610)): No custom lint yet. Use `dart analyze` and code review; adopt `const .all(...)` / `.circular(...)` where context types are clear.
- **Primary constructors** ([#609](https://github.com/neiljaywarner/refuge/issues/609)): Documented in `docs/wiki/CI-CD-FAQ.md`; optional lint later if the plugin API stays stable on our SDK pin.
