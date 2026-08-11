# Agent Instructions

## Prerequisites

Install Lua 5.1 and the busted testing framework:

```bash
apt-get update && apt-get install -y lua5.1 lua-busted
```

Install busted from the distro archive rather than with `luarocks install busted`.
LuaRocks resolves busted's `lua-term` dependency to a GitHub tarball, which fails in
sandboxed environments where GitHub archive hosts are unreachable.

## Running Tests

Run the tests from the repository root:

```bash
busted tests/TakeItOff_spec.lua
```

**Important:** Always run the tests after making code changes to ensure nothing is broken.
