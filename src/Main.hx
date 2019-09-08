package;

import flash.utils.ByteArray;
import haxe.Json;
import haxe.ds.StringMap;
import haxe.io.Input;
import haxe.io.Path;
import hscript.Interp;
import hscript.Parser;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.display.Sprite;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;
import haxe.io.Bytes;

/**
 * ...
 * @author Joe Williamson
 */

 //TODO
 // Create test project
 // Move processes into scripts
 // Create and load batch configs
class Main {
	
	static var processCount:Int = 0;
	
	
	static var colorMap:Map<UInt, UInt>;//TODO remove
	static var outlineMasks:StringMap<BitmapData>;//TODO remove
	
	static var config:Dynamic;
	static var configPath:String;
	static var configFolder:String;
	static var script:String;
	
	static var fileInReg:EReg;
	static var fileOut:String;
	
	static var interp:Interp;
	
	public static function main() {
		var args = Sys.args();
		
		Sys.println("Running batch pixel...");
		
		// Load config from command line args
		if (args.length == 0) {
			Sys.println("Please specify path to config json");
		} else {
			configPath = args[0];
			var configStr = "";
			try {
				configFolder = Path.directory(configPath);
				configStr = File.getContent(configPath);
			} catch (e:String) {
				Sys.println("Cannot read config file: " + configPath);
				Sys.exit(-1);
			}
			
			try {
				config = Json.parse(configStr);
			} catch (e:String) {
				Sys.println("Config is not valid JSON: " + configPath);
				Sys.exit(-1);
			}
			
			if (config.script == null) {
				Sys.println("Config does not specify script");
				Sys.exit(-1);
			}
		}
		
		Sys.println(config.paletteMap);
		
		// Load hscript from config
		var parser:Parser = new Parser();
		interp = new Interp();
		interp.variables.set("BitmapData", BitmapData);
		interp.variables.set("Math", Math);
		interp.variables.set("Map", Map);
		interp.variables.set("Std", Std);
		interp.variables.set("StringTools", StringTools);
		interp.variables.set("StringMap", StringMap);
		interp.variables.set("println", Sys.println);
		interp.variables.set("Reflect", Reflect);
		interp.variables.set("toUInt", function(x){var u:UInt = cast x; return u; });
		var ast = parser.parseString(File.getContent(config.script));
		
		interp.execute(ast);
		
		var process:BitmapData->Dynamic->BitmapData = interp.variables.get("process");
		
		// Call script init
		if (interp.variables.exists("init")) interp.variables.get("init")(config);
		
		fileInReg = new EReg("^" + config.fileIn + "$", "");
		fileOut = config.fileOut;
		
		// Call script process on files
		var folders:Array<Dynamic> = config.folders;
		Sys.println(folders);
		
		for (folder in folders) {
			processFolder(Reflect.field(folder, "in"), folder.out, process);
		}
		
		// Call script complete
		if (interp.variables.exists("complete")) interp.variables.get("complete")();
		
		// Exit
		Sys.println("Done (" + processCount + " files processed)");
		Sys.exit(-1);
		
	}
	
	static function outlines():Void {
		//Sys.println("Applying outlines");
		//
		//outlineMasks = new StringMap<BitmapData>();
		//var folder = "/output/";
		//
		//// Load the masks
		//var files = FileSystem.readDirectory(folder);
		//for (file in files) {
			//var fname:String = Path.withoutExtension(Path.withoutDirectory(file));
			//var animName:String = "";
			//if (fname.substr(0, 12) == "outlinemask_") {
				//animName = fname.substr(12, fname.length - 12);
				//outlineMasks.set(animName, BitmapData.fromFile(folder + file));
				//
				//trace("Added mask: " + animName + " -> " + file);
			//}
		//}
		//
		//// Process the folders
		//processFolder("../heads/", "../heads_outlines/", addOutline);
		
	}
	
	//static function addOutline(file:String):BitmapData {
		////var bitmap:BitmapData = BitmapData.fromFile(file);
		////var newBitmap:BitmapData = bitmap.clone();
		////
		////var r:EReg = ~/\S*_([a-zA-Z\d]+).png$/;
		////if (r.match(file)) {
			////var animName:String = r.matched(1);
			////if (!outlineMasks.exists(animName)) return null;
			////
			////var w = bitmap.width;
			////var h = bitmap.height;
			////for (y in 0...h) {
				////for (x in 0...w) {
					////// If current pixel is transparent
					////if (bitmap.getPixel32(x, y) & 0xff000000 == 0) {
						////// Look at neighbouring pixels
						////for (ij in [{i:0,j:-1}, {i:-1,j:0}, {i:1,j:0}, {i:0,j:1}]) {
							////var i = x + ij.i;
							////var j = y + ij.j;
							////
							////// If neighbour within image bounds
							////// And neighbour not transparent
							////// And current pixel not masked out
							////// Set current pixel to outline
							////if (i >= 0 && i < w && j >= 0 && j < h
								////&& ((bitmap.getPixel32(i, j) & 0xff000000) != 0)
								////&& (outlineMasks.get(animName).getPixel32(x, y) & 0xff000000 == 0))
							////{
								////newBitmap.setPixel32(x, y, 0xff000000);//TODO outline color customisation
								////break;
							////}
						////}
					////}
				////}
			////}
			////
			////replaceCount++;
			////
			////bitmap.dispose();
			////
			////return newBitmap;
		////}
		////
		////return null;
	//}
	//
	//static function paletteSwap():Void {
		////colorMap = new Map<UInt, UInt>();
		////
		////// Yellow sleeves
		////colorMap.set(0xffd163, 0xf0eeee);
		////colorMap.set(0xbc6d3b, 0x9c879c);
		////
		////// Red to yellow
		////colorMap.set(0xff4747, 0xffc845);
		////colorMap.set(0x8b263a, 0xbc6d34);
		////colorMap.set(0xcc2837, 0xde9b3c);//<-Extra tos midtone
		////colorMap.set(0x5b1c36, 0x68402a);
		////
		////colorMap.set(0x591e43, 0xbc6d34);
		////colorMap.set(0x8b2650, 0xffc845);
		////
		////processFolder("../tng_red/", "../tng_yellow/", replaceColors);
		////processFolder("../voy_red/", "../voy_yellow/", replaceColors);
		////processFolder("../tos_red/", "../tos_yellow/", replaceColors);
		////processFolder("../ent_red/", "../ent_yellow/", replaceColors);
		////processFolder("../ds9_red/", "../ds9_yellow/", replaceColors);
		////
		////// Red to blue tng tos
		////colorMap = new Map<UInt, UInt>();
		////colorMap.set(0xff4747, 0x319de4);
		////colorMap.set(0x8b263a, 0x494aa5);
		////colorMap.set(0xcc2837, 0x43d72c4);//<-Extra tos midtone
		////colorMap.set(0x5b1c36, 0x311f69);
		////
		////processFolder("../tng_red/", "../tng_blue/", replaceColors);
		////processFolder("../tos_red/", "../tos_blue/", replaceColors);
		////
		////// Red to blue voy ds9 ent
		////colorMap = new Map<UInt, UInt>();
		////colorMap.set(0xff4747, 0x35b0a0);
		////colorMap.set(0x8b263a, 0x2f617b);
		////colorMap.set(0xcc2837, 0x31888d);//<-Extra tos midtone
		////colorMap.set(0x5b1c36, 0x223952);
		////
		////colorMap.set(0x591e43, 0x2f617b);
		////colorMap.set(0x8b2650, 0x35b0a0);
		////
		////processFolder("../voy_red/", "../voy_blue/", replaceColors);
		////processFolder("../ds9_red/", "../ds9_blue/", replaceColors);
		////processFolder("../ent_red/", "../ent_blue/", replaceColors);
		//
	//}
	
	static function processFolder(folder:String, newFolder:String, process:BitmapData->Dynamic->BitmapData):Void {
		var copiedFolder:Bool = false;
		var files = FileSystem.readDirectory(folder);
		Sys.println("Processing folder: " + folder + " (" + files.length + " files)");
		
		for (file in files) {
			var filePath = folder + "/" + file;
			
			if (FileSystem.isDirectory(filePath)) {
				// Recursively go through subdirectories
				processFolder(filePath, newFolder + "/" + file, process);
				
			} else if (fileInReg.match(file)) {
				
				var newFile = newFolder + "/" + fileInReg.replace(file, fileOut);
				
				if (!copiedFolder) {
					try {
						FileSystem.createDirectory(newFolder);
					} catch (e:String) {
						Sys.println("Cannot create directory: " + newFolder);
						Sys.exit(-1);
					}
					copiedFolder = true;
				}
				var bmp = process(BitmapData.fromFile(filePath), config);
				if (bmp != null) {
					saveBitmap(bmp, newFile);
					bmp.dispose();
					processCount++;
				}
			}
		}
	}
	
	static function saveBitmap(image:BitmapData, file:String):Void {
		Sys.println("Saving " + file);
		var byteArray:ByteArray = image.encode(image.rect, new PNGEncoderOptions());
		byteArray.position = 0;
		var bytes:Bytes = Bytes.alloc(byteArray.length);
		while (byteArray.bytesAvailable > 0) {
			var position = byteArray.position;
			bytes.set(position, byteArray.readByte());
		}
		var fo:FileOutput = sys.io.File.write(file, true);
		fo.write(bytes);
		fo.close();
	}

}
