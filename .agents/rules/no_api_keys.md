# Rule: Zero Plaintext API Keys & Secrets in Repository

## Directive
Under NO circumstances may any API keys, access tokens, secret credentials, private keys, or passwords be written to files tracked by git, nor hardcoded as default fallback values in configuration files (such as `codemagic.yaml`, workflow files, `.env` files, or Dart sources).

## Strict Requirements
1. **No Plaintext Fallbacks**:
   - In YAML or workflow files, NEVER use syntax like `${VAR:-plaintext_secret}` that embeds a fallback secret.
   - Use only the environment variable name provided by secure secret vaults or CI/CD groups (e.g. `groups: [selah_secrets]` in Codemagic).
2. **Dart Code Constants**:
   - Always load sensitive keys via `String.fromEnvironment('KEY_NAME', defaultValue: 'REDACTED')`.
   - Never embed actual tokens in source code or unit test mocks.
3. **Ignored Files**:
   - Ensure files containing credentials (e.g., `google-services.json`, `GoogleService-Info.plist`, `.env*`, `*.keystore`, `*.jks`) are strictly included in `.gitignore`.
4. **Pre-Commit Verification**:
   - Before executing `git commit`, inspect `git diff --staged` to verify no secret or credential was introduced.
