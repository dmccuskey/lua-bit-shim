--[[
Testing for bit (the shim)
--]]

package.path = './dmc_lua/?.lua;' .. package.path



--====================================================================--
--== Testing Setup
--====================================================================--


-- load the shim again, with the given stand-ins in package.preload
local function loadShim( preload )
	local saved = {}
	for name, loader in pairs( preload or {} ) do
		saved[name] = package.preload[name]
		package.preload[name] = loader
		package.loaded[name] = nil
	end
	package.loaded['bit'] = nil

	local ok, result = pcall( require, 'bit' )

	for name in pairs( preload or {} ) do
		package.preload[name] = saved[name]
		package.loaded[name] = nil
	end
	package.loaded['bit'] = nil

	return ok, result
end



--====================================================================--
--== Test: Fallback
--====================================================================--


describe( "the pure-Lua fallback", function()

	local bit

	before_each( function()
		local ok
		ok, bit = loadShim()
		assert.is_true( ok, bit )
	end)

	it( "is loaded when plugin.bit is missing", function()
		assert.are.equal( 'lib.bit.numberlua', bit.__source )
	end)

	it( "has the version", function()
		assert.are.equal( '0.2.0', bit.__version )
	end)

	it( "has LuaBitOp's functions", function()
		for _, name in ipairs{ 'tobit', 'tohex', 'bnot', 'band', 'bor', 'bxor',
			'lshift', 'rshift', 'arshift', 'rol', 'ror', 'bswap' }
		do
			assert.are.equal( 'function', type( bit[name] ), name )
		end
	end)

	it( "gives the README's results", function()
		assert.are.equal( 48, bit.band( 0xF0, 0x3C ) )
		assert.are.equal( 255, bit.bor( 0xF0, 0x0F ) )
		assert.are.equal( 240, bit.bxor( 0xFF, 0x0F ) )
		assert.are.equal( 16, bit.lshift( 1, 4 ) )
		assert.are.equal( 16, bit.rshift( 256, 4 ) )
		assert.are.equal( 'abcd', bit.tohex( 0xABCD, 4 ) )
	end)

	it( "gives signed results, like LuaBitOp", function()
		assert.are.equal( -1, bit.bnot( 0 ) )
		assert.are.equal( -2147483648, bit.lshift( 1, 31 ) )
		assert.are.equal( -1, bit.tobit( 0xFFFFFFFF ) )
		assert.are.equal( -16, bit.arshift( -256, 4 ) )
		assert.are.equal( 0x0FFFFFF0, bit.rshift( -256, 4 ) )
	end)

	it( "takes more than two arguments in band, bor, bxor", function()
		assert.are.equal( 3, bit.band( 0xFF, 0x0F, 0x03 ) )
		assert.are.equal( 7, bit.bor( 1, 2, 4 ) )
		assert.are.equal( 0, bit.bxor( 1, 2, 3 ) )
	end)

	it( "doesn't change numberlua's own table", function()
		local numberlua = require 'lib.bit.numberlua'
		assert.is_nil( numberlua.bit.__version )
	end)

end)



--====================================================================--
--== Test: Plugin
--====================================================================--


describe( "plugin.bit", function()

	it( "is loaded first when it's there, and not changed", function()
		local plugin = { band=function() return 'plugin' end }
		local ok, bit = loadShim{ ['plugin.bit']=function() return plugin end }
		assert.is_true( ok, bit )
		assert.are.equal( 'plugin.bit', bit.__source )
		assert.are.equal( 'plugin', bit.band( 1, 1 ) )
		assert.is_nil( plugin.__version )
	end)

end)



--====================================================================--
--== Test: Nothing Loads
--====================================================================--


describe( "when no module loads", function()

	it( "raises with each module's error", function()
		local ok, err = loadShim{
			['lib.bit.numberlua']=function() error( 'numberlua is broken' ) end
		}
		assert.is_false( ok )
		assert.is_truthy( err:find( 'Bit module not found', 1, true ) )
		assert.is_truthy( err:find( 'plugin.bit:', 1, true ) )
		assert.is_truthy( err:find( 'numberlua is broken', 1, true ) )
	end)

end)
