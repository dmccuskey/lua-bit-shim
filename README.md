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
- Signed 32-bit results from both, as in LuaBitOp, so plain-Lua tests match Solar2D
- Fails at load with `Bit module not found` and each module's error when neither loads
- Pure Lua 5.1; MIT licensed

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
print( bit.bnot( 0 ), bit.__source )
```

Run it:

```sh
lua main.lua
```

```text
48	255	240
16	16
abcd
-1	lib.bit.numberlua
```

If it shows `module 'bit' not found`, run it from the folder that holds `lua-bit-shim/`.

To update, pull the repository again (`git -C lua-bit-shim pull`).

## What It Loads

The shim tries each module in the `BITOP_LIBS` list at the top of `bit.lua` and returns the first one that loads:

1. `plugin.bit`: Solar2D's plugin, written in C, with LuaBitOp's API: `tobit`, `tohex`, `bnot`, `band`, `bor`, `bxor`, `lshift`, `rshift`, `arshift`, `rol`, `ror`, `bswap`.
2. `lib.bit.numberlua`: the pure-Lua fallback. The shim uses its `bit` sub-table, written to match LuaBitOp: the same functions, signed results (`bit.bnot( 0 )` is `-1`, `bit.lshift( 1, 31 )` is `-2147483648`), and `band`, `bor` and `bxor` take any number of arguments. It's several times slower than the plugin: in a loop over large data, a call per byte adds up, so use lookup tables there.

The shim returns a copy of the module's functions, so the module's own table stays unchanged, with two fields added:

- `__version`: the shim's version, `0.2.0`
- `__source`: the name of the module it loaded, `plugin.bit` or `lib.bit.numberlua`

When neither loads, the error lists why each one failed.

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

Without it, the shim uses the fallback, which gives the same results, but slower.

The DMC Solar2D libraries load the shim as `lib.dmc_lua.bit`: their `dmc_corona/lib/dmc_lua/` folder carries a copy of it, as part of [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library). dmc-websockets uses it to build, parse and mask frames.

## Known Issues

- **LuaBitOp itself isn't tried.** In plain Lua (or LuaJIT), an installed LuaBitOp (`luarocks install luabitop`) is also named `bit`, so the shim can't load it by that name and uses the slower fallback. When the shim's folder comes first on `package.path`, it also hides LuaBitOp from other code. ([#1](https://github.com/dmccuskey/lua-bit-shim/issues/1))

## Development

Only `dmc_lua/bit.lua` is written here (and its tests); `dmc_lua/lib/bit/numberlua.lua` is numberlua 0.3.1, copied unchanged. [DMC-Lua-Library](https://github.com/dmccuskey/DMC-Lua-Library) copies both into its `dmc_lua/` with its Snakemake build (the `Snakefile` here registers them), and the DMC Solar2D libraries copy them from there into `dmc_corona/lib/dmc_lua/`.

The tests are in `spec/bit_spec.lua`, for [busted](https://lunarmodules.github.io/busted/) under Lua 5.1. They load the fallback, and a stand-in for `plugin.bit`. From the repository's root folder:

```sh
busted spec
```

## License

lua-bit-shim is released under the [MIT License](LICENSE). numberlua is (c) 2008-2011 David Manura, under the MIT License (the terms are in the file).
