# lua-bit-shim

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "lua-bit-shim"
	include: "../DMC-Lua-Library/snakemake/Snakefile"

module_config = {
	"name": "lua-bit-shim",
	"module": {
		"dir": "dmc_lua",
		"files": [
			"bit.lua",
			"lib/bit/numberlua.lua"
		],
		"requires": [
		]
	},
	"tests": {
		"dir": "spec",
		"files": [
			"bit_spec.lua"
		],
		"requires": [
		]
	}
}

register( "lua-bit-shim", module_config )


