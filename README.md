# aws-cli-config-d

Split your `~/.aws/config` into separate files per AWS organization.

## The problem

When working with multiple AWS organizations using SSO, `~/.aws/config` becomes a long, hard-to-navigate file mixing profiles from unrelated clients. The AWS CLI doesn't support `include` directives or a `config.d/` pattern natively.

## How it works

Instead of maintaining a single `~/.aws/config`, you keep per-organization files in `~/.aws/config.d/`:

```
~/.aws/config.d/
  00-defaults     # default profile, shared settings
  acme-corp       # all Acme Corp profiles + SSO session
  globex-inc      # all Globex Inc profiles + SSO session
```

A fish shell hook runs at the start of each session and checks if any file in `config.d/` is newer than `~/.aws/config`. If so, it concatenates them all into `~/.aws/config` and prints a message:

```
aws: rebuilt ~/.aws/config from config.d/
```

If nothing changed, it does nothing.

## Setup

### Automatic

```fish
./install.fish
```

This will:
1. Create `~/.aws/config.d/` with example files
2. Add the auto-rebuild hook to your `~/.config/fish/config.fish`
3. Build `~/.aws/config` from the parts

### Manual

1. Create `~/.aws/config.d/` and move your profiles into per-organization files:

```bash
mkdir -p ~/.aws/config.d
```

2. Add the contents of `config.fish.snippet` to the top of your `~/.config/fish/config.fish`.

3. Rebuild the config:

```bash
cat ~/.aws/config.d/* > ~/.aws/config
```

## Usage

### Adding a new organization

Create a new file in `~/.aws/config.d/` with the organization's profiles:

```ini
# ~/.aws/config.d/my-new-client
[profile my-new-client-dev]
sso_session=my-new-client
sso_account_id=123456789012
sso_role_name=DeveloperAccess
region=eu-west-1

[sso-session my-new-client]
sso_start_url=https://my-new-client.awsapps.com/start/
sso_region=eu-west-1
sso_registration_scopes=sso:account:access
```

The next time you open a fish shell, the config will be rebuilt automatically.

### Ordering

Files are concatenated in lexicographic order. Use numeric prefixes to control ordering (e.g., `00-defaults` runs first).

### Forcing a rebuild

Touch any file in the directory:

```bash
touch ~/.aws/config.d/00-defaults
```

Then open a new shell session.

## Adapting for other shells

The fish-specific hook is in `config.fish.snippet`. The equivalent for bash/zsh in your `.bashrc` or `.zshrc`:

```bash
if [ -d ~/.aws/config.d ]; then
  if [ ! -f ~/.aws/config ] || [ -n "$(find ~/.aws/config.d -newer ~/.aws/config -print -quit 2>/dev/null)" ]; then
    cat ~/.aws/config.d/* > ~/.aws/config
    echo "aws: rebuilt ~/.aws/config from config.d/"
  fi
fi
```

## Limitations

- The AWS CLI does not support `config.d/` natively. This is a workaround that concatenates files.
- Editing `~/.aws/config` directly (e.g., via `aws configure sso`) will be overwritten on the next rebuild. Edit the source files in `config.d/` instead.
- `~/.aws/credentials` is not managed by this tool. You could apply the same pattern with a `credentials.d/` directory if needed.
