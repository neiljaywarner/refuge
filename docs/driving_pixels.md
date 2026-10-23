# 📱 Real Device Driving & Hardware Automation Guide

> [!NOTE]
> This guide has been elevated and modernized in [**`docs/real_device_driving_and_automation.md`**](real_device_driving_and_automation.md).
> Maestro is **fully installed and operational** via the **Maestro MCP Server** (`ServerName: 'maestro'`) and CLI (`maestro`), serving as our #1 priority for zero-prompt physical device screenshots and declarative UI driving.

## Quick Reference Summary

- **Authoritative Guide**: See [**`docs/real_device_driving_and_automation.md`**](real_device_driving_and_automation.md)
- **Maestro MCP Tools**: `take_screenshot`, `inspect_screen`, `run`, `list_devices`, `open_maestro_viewer`
- **Maestro Web Viewer**: Live screen stream at `http://127.0.0.1:9999/`
- **Connected Fleet**:
  - Google Pixel 9a (`56091JEBF14039`)
  - Google Pixel 8 (`58221JEBF20835`)
  - Android Emulator (`emulator-5554`)
- **Patrol MCP & `patrol_finders`**: Native automation and sub-2s BDD widget tests.
- **Single-Command Turnkey Hardware Regression**:
  ```bash
  ./tool/run_physical_glass_regression.sh
  ```
