# Agent Instructions

## Prerequisites

Install Lua 5.1 and LuaRocks:

```bash
apt-get update && apt-get install -y lua5.1 luarocks
```

Install the busted testing framework:

```bash
luarocks install busted
```

## Running Tests

Run the tests from the repository root:

```bash
busted tests/TakeItOff_spec.lua
```

**Important:** Always run the tests after making code changes to ensure nothing is broken.
