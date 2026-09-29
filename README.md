# lua-bit-shim

Load a bitwise-operations module under one name, so the same Lua code runs in Solar2D and in plain Lua.

Lua 5.1 has no bitwise operators. Solar2D (formerly Corona SDK) offers them in its `plugin.bit` plugin, a build of [LuaBitOp](https://bitop.luajit.org/). lua-bit-shim is a module named `bit` that loads `plugin.bit` when it's there, and otherwise falls back to [numberlua](https://github.com/davidm/lua-bit-numberlua), a pure-Lua implementation that it carries with it. Code that needs `band()` or `bxor()` then works in a Solar2D app and in tests under plain Lua, for example in [lua-corovel](https://github.com/dmccuskey/lua-corovel):

```lua
local bit = require 'bit'  -- plugin.bit, or the pure-Lua fallback

print( bit.bxor( 0xFF, 0x0F ) )  --> 240
```

## Features

- One name, `bit`, for Solar2D's `plugin.bit` and a pure-Lua fallback
- Needs nothing installed: numberlua (MIT, by David Manura) comes with it
- Fails at load with `Bit module not found` when neither loads
- Pure Lua 5.1; MIT licensed

The two modules don't give the same results for every value: see [Known Issues](#known-issues).

## Quick Start

The following steps will get you up and running in about 5 minutes with Lua 5.1 on macOS or Linux. You will load the shim and run a few bitwise operations with the pure-Lua fallback.

Prerequisites: Lua 5.1 (`lua -v` shows `Lua 5.1.x`) and git.

### 1. Get the Code

In an empty folder:

```sh
git clone https://github.com/dmccuskey/lua-bit-shim.git
```

The module is in `lua-bit-shim/dmc_lua/`: `bit.lua` is the shim, `lib/bit/numberlua.lua` the fallback. Keep the two together: the shim loads the fallback as `lib.bit.numberlua`, relative to the folder that holds `bit.lua`.

### 2. Use It

Create `main.lua` in the same folder:

```lua
package.path = './lua-bit-shim/dmc_lua/?.lua;' .. package.path
local bit = require 'bit'

print( bit.band( 0xF0, 0x3C ), bit.bor( 0xF0, 0x0F ), bit.bxor( 0xFF, 0x0F ) )
print( bit.lshift( 1, 4 ), bit.rshift( 256, 4 ) )
print( bit.tohex( 0xABCD, 4 ) )
```

Run it:

```sh
lua main.lua
```

```text
48	255	240
16	16
abcd
```

If it shows `module 'bit' not found`, run it from the folder that holds `lua-bit-shim/`.

To update, pull the repository again (`git -C lua-bit-shim pull`).

## What It Loads

The shim tries each module in the `BITOP_LIBS` list at the top of `bit.lua` and returns the first one that loads:

1. `plugin.bit`: Solar2D's plugin, written in C, with LuaBitOp's API: `tobit`, `tohex`, `bnot`, `band`, `bor`, `bxor`, `lshift`, `rshift`, `arshift`, `rol`, `ror`, `bswap`.
2. `lib.bit.numberlua`: the pure-Lua fallback, with the same function names (plus `extract`, `replace` and `btest` from Lua 5.2's `bit32`). Its `band`, `bor` and `bxor` take two arguments and ignore any more (`bit.band( 0xFF, 0x0F, 0x03 )` is `15`, not `3`). It's several times slower than the plugin: in a loop over large data, a call per byte adds up, so use lookup tables there.

The module you get keeps its own API; the shim adds nothing to it.

## In Solar2D

To get the faster plugin, add it to your app's `build.settings`:

```lua
settings =
{
	plugins =
	{
		["plugin.bit"] = { publisherId = "com.coronalabs" },
	},
}
```

Without it, the shim uses the fallback, which works the same (see [Known Issues](#known-issues)) but slower.

The DMC Solar2D libraries load the shim as `lib.dmc_lua.bit`: their `dmc_corona/lib/dmc_lua/` folder carries a copy of it, as part of [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library). dmc-websockets uses it to build, parse and mask frames.

## Known Issues

- **The fallback's results are unsigned, the plugin's signed.** LuaBitOp returns signed 32-bit numbers and numberlua's top-level functions non-negative ones, so any result with the top bit set differs: `bit.bnot( 0 )` is `-1` with the plugin and `4294967295` with the fallback, `bit.lshift( 1, 31 )` is `-2147483648` and `2147483648`. Results below `0x80000000` are the same. Code tested only under plain Lua can break in Solar2D. numberlua has a sub-table, `bit`, that matches LuaBitOp, but the shim returns the top level.
- **LuaBitOp itself isn't tried.** In plain Lua (or LuaJIT), an installed LuaBitOp (`luarocks install luabitop`) is also named `bit`, so the shim can't load it by that name and uses the slower fallback. When the shim's folder comes first on `package.path`, it also hides LuaBitOp from other code.
- **`Bit module not found` hides the real error.** When the fallback fails to load (moved away from `bit.lua`, say), the shim reports only that nothing was found. Run `require 'lib.bit.numberlua'` directly to see why.
- The version, `0.1.0`, is only in the file: the module returned is the bit module itself.
- No tests.

## Development

Only `dmc_lua/bit.lua` is written here; `dmc_lua/lib/bit/numberlua.lua` is numberlua 0.3.1, copied unchanged. [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library) copies both into its `dmc_lua/` with its Snakemake build (the `Snakefile` here registers them), and the DMC Solar2D libraries copy them from there into `dmc_corona/lib/dmc_lua/`.

## License

lua-bit-shim is released under the [MIT License](LICENSE). numberlua is (c) 2008-2011 David Manura, under the MIT License (the terms are in the file).
