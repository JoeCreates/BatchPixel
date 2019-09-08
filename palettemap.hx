function init(config) {
	paletteMap = new StringMap();
	for (key in Reflect.fields(config.paletteMap)) {
		paletteMap.set(key.toUpperCase(), Reflect.field(config.paletteMap, key).toUpperCase());
	}
    trace(paletteMap);
}

function process(bmp) {	
	var bmpOut = bmp.clone();
	
	for (j in 0...bmp.height) {
		for (i in 0...bmp.width) {
			var pixel = bmp.getPixel32(i, j);
			if (paletteMap.exists(StringTools.hex(pixel, 8))) {
				bmpOut.setPixel32(i, j, Std.parseInt("0x" + paletteMap.get(StringTools.hex(pixel, 8))));
			}
		}
	}
	
	return bmpOut;
}

function complete() {
	
}