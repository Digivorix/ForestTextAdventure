package com.digivorix.forestadventure;

import openfl.display.Sprite;
import openfl.Lib;
import openfl.text.Font;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.AntiAliasType;
import openfl.events.Event;
import openfl.ui.Keyboard;
import openfl.events.KeyboardEvent;

/**
 * ...
 * @author Toby Davis
 */
class Main extends Sprite 
{
	
	private var cacheTime:Int; // Stored at the end of each frame
	private var deltaTime:Int; // Current delta time
	
	private var running:Bool = true; // Is application running?
	
	private var keys:Array<Bool>; // Store the value of keys pressed
	
	//
	// Initialization
	//
	public function new() 
	{
		super();
		
		// Assets:
		// openfl.Assets.getBitmapData("img/assetname.jpg");
		
		var format = new TextFormat ("Perfect DOS VGA 437", 24, 0xFFFFFF);
		var textField = new TextField ();
		
		textField.defaultTextFormat = format;
		textField.embedFonts = true;
		textField.selectable = false;
		
		textField.x = 0;
		textField.y = 0;
		textField.width = 200;
		
		textField.text = "Hello World";
		
		addChild (textField);
		
		/*sprite = new Sprite ();
		sprite.graphics.beginFill (0x24AFC4);
		sprite.graphics.drawRect (0, 0, 100, 100);
		sprite.y = 50;*/
		
		// Set up main loop
		cacheTime = Lib.getTimer();
		stage.addEventListener(Event.ENTER_FRAME, everyFrame);
		
		// Set up keyboard input
		keys = [];
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyUp);
	}
	
	//
	// Game loop
	//
	private function update():Void {
		
		// Purge inputs
		var k:Int = 0;
		while(k < keys.length){
			if(keys[k] == true){
				//trace("Resetting: " + k);
				keys[k] = false;
			}
			k++;
		}
		
		// Terminate application at end of loop if no longer running
		if(!running){
			applicationEnd();
		}
	}
	
	// Final actions before application ends
	private function applicationEnd():Void {
		#if (!flash && !html5)
		Sys.exit(0); // Close native application
		#end
	}

	//
	// Event Handlers
	// 
	private function everyFrame(event:Event):Void {
		var currentTime = Lib.getTimer();
		deltaTime = currentTime - cacheTime; // Update delta time
		update(); // Run game loop
		
		cacheTime = currentTime; // Update the cached time
		
	}
	
	private function onKeyDown(event:KeyboardEvent):Void {
		trace("Key down: " + event.toString());
		keys[event.keyCode] = true;
	}
	private function onKeyUp(event:KeyboardEvent):Void {
		
	}

}
