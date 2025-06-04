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
import openfl.geom.Rectangle;
import openfl.display.StageScaleMode;

/**
 * ...
 * @author Toby Davis
 */
class Main extends Sprite 
{
	
	var cacheTime:Int; // Stored at the end of each frame
	var deltaTime:Int; // Current delta time
	var pause:Int = 0; // Update loop pause length (multiplied by 1000)
	var storyPos:Int = 0;
	
	// Variables for updating the text list
	var linesToPush:Array<String>;
	var linesPushed:Int = 0;
	
	var running:Bool = true; // Is application running?
	var cont:Bool = true;
	var userQuit:Bool = false; // Did user agree to the game?
	var gameComplete:Bool = false; // Has the game been completed?
	var gameLost:Bool = false;
	var waitingForInput:Bool = false;
	
	var keys:Array<Bool>; // Store the value of keys pressed
	var allowInput:Bool = false; // Is input allowed?
	
	// Sprite containers for various elements
	var graphicSprite:Sprite;
	var listSprite:Sprite;
	var inputSprite:Sprite;
	
	// Font format
	var terminalFormat:TextFormat;
	var inputFormat:TextFormat;
	
	// List text variables
	var listTextField:TextField;
	var textList:Array<String>;
	
	// Input text variable
	var inputTextField:TextField;
	
	//
	// Initialization
	//
	public function new() 
	{
		super();
		
		// Crop visible content
		this.scrollRect = new Rectangle(0, 0, 800, 480);
		
		// Story graphics container sprite
		graphicSprite = new Sprite();
		graphicSprite.graphics.beginFill(0x0094FF);
		graphicSprite.graphics.drawRect(0, 0, 800, 192);
		graphicSprite.graphics.endFill();
		graphicSprite.y = 0;
		graphicSprite.scrollRect = new Rectangle(0, 0, 800, 192);
		addChild(graphicSprite);
		
		// Set up terminal text format
		#if html5
		terminalFormat = new TextFormat("Perfect DOS VGA 437", 16, 0xFFFFFF); // HTML5 weirdness
		#end
		#if cpp
		terminalFormat = new TextFormat("Perfect DOS VGA 437", 20, 0xFFFFFF);
		#end
		#if (!html5 && !cpp)
		terminalFormat = new TextFormat("Perfect DOS VGA 437", 18, 0xFFFFFF);
		#end
		// Set up input text format
		inputFormat = new TextFormat("Perfect DOS VGA 437", 24, 0xFFFFFF);
		
		// Text list container sprite
		listSprite = new Sprite();
		listSprite.graphics.beginFill(0xFFFFFF);
		listSprite.graphics.drawRect(0, 0, 800, 256);
		listSprite.graphics.endFill();
		listSprite.graphics.beginFill(0x000000);
		listSprite.graphics.drawRect(0+2, 0+2, 800-4, 256-4);
		listSprite.graphics.endFill();
		listSprite.y = 192;
		listSprite.scrollRect = new Rectangle(0, 0, 800, 256);
		
		listTextField = new TextField();
		listTextField.defaultTextFormat = terminalFormat;
		listTextField.selectable = false;
		listTextField.text = "";
		listTextField.width = 800;
		listTextField.height = 256;
		listTextField.x = listTextField.y = 4;
		
		listSprite.addChild(listTextField);
		addChild(listSprite);
		
		// Text input container sprite
		inputSprite = new Sprite();
		inputSprite.graphics.beginFill(0xFFFFFF);
		inputSprite.graphics.drawRect(0, 0, 800, 32);
		inputSprite.graphics.endFill();
		inputSprite.graphics.beginFill(0x000000);
		inputSprite.graphics.drawRect(0+2, 0, 800-4, 32-2);
		inputSprite.graphics.endFill();
		inputSprite.y = 448;
		
		inputTextField = new TextField();
		inputTextField.defaultTextFormat = inputFormat;
		inputTextField.selectable = false;
		inputTextField.text = "";
		inputTextField.width = 800;
		inputTextField.height = 256;
		inputTextField.x = listTextField.y = 4;
		
		inputSprite.addChild(inputTextField);
		addChild(inputSprite);
		
		
		// Set up main loop
		cacheTime = Lib.getTimer();
		stage.addEventListener(Event.ENTER_FRAME, everyFrame);
		
		// Set up keyboard input
		keys = [];
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyUp);
		
		// Set up resizing
		stage.addEventListener(Event.RESIZE, onResize);
		
		textList = [];
		linesToPush = [];
		
		#if flash
		stage.scaleMode = StageScaleMode.EXACT_FIT;
		#end
	}
	
	private function restart(pos:Int):Void{
		//trace("Restart game");
		pause = 0;
		storyPos = pos; // Start from specified story position
		
		linesToPush = [];
		linesPushed = 0;
		
		running = true;
		cont = true;
		userQuit = false;
		gameComplete = false;
		gameLost = false;
		waitingForInput = false;
		
		keys = [];
		allowInput = false;
		
		listTextField.text = "";
		textList = [];
		
		inputTextField.text = "";
	}
	
	//
	// Game loop
	//
	private function update():Void {
		// Quit behavior
		if (!(linesPushed < linesToPush.length) && !gameLost && userQuit){
			#if (!flash && !html5)
			running = false;
			#else
			restart(0); //For Flash and HTML5
			#end
		}
		
		// Force quit
		if (checkKey(Keyboard.ESCAPE)){
			#if (!flash && !html5)
			running = false;
			#else
			restart(0); //For Flash and HTML5
			#end
		}
		
		// Restart from loss
		if (checkKey(Keyboard.R) && gameLost && !userQuit){
			restart(4);
		}
		
		if (allowInput){
			if(checkKey(Keyboard.BACKSPACE)){
				inputTextField.text = inputTextField.text.substring(0, inputTextField.length-1);
			}
			if (checkKey(Keyboard.ENTER)){
				allowInput = false;
				processInput();
			}
		}
		
		if(cont && !waitingForInput){ // Are we allowed to continue and not waiting for user input?
			switch(storyPos){
				case 0:
					wait(1);
					storyPos++;
				case 1:
					resetPushedLines();
					linesToPush = [
					"Starting", 
					"...",
					"Initializing Gaming Electronic Operating System Version 1.0",
					"Copyright (c) 2017-2025 Toby Davis",
					"", 
					"Hello", 
					"", 
					"I am GEOS"
					];
					storyPos++;
				case 2:
					resetPushedLines();
					linesToPush = ["", "Would you like to play a game? (Y | N)"];
					allowInput = true;
					waitingForInput = true;
				case 3:
					resetPushedLines();
					linesToPush = [
					"The game will start in", 
					"5",
					"4",
					"3",
					"2", 
					"1"
					];
					storyPos++;
				case 4:
					resetPushedLines();
					linesToPush = [
					"",
					"You start out on a dirt road in a forest with a fork in it.",
					"Do you go left or right? (LEFT | RIGHT)"
					];
					allowInput = true;
					waitingForInput = true;
				case 5:
					resetPushedLines();
					linesToPush = [
					"",
					"You then come to a pool of lava.",
					"Do swim across or take a boat? (SWIM | BOAT)"
					];
					allowInput = true;
					waitingForInput = true;
				case 6:
					resetPushedLines();
					linesToPush = [
					"",
					"Later you find an apple and a banana, you are hungry.",
					"Which one do you eat? (APPLE | BANANA)"
					];
					allowInput = true;
					waitingForInput = true;
				case 7:
					resetPushedLines();
					linesToPush = [
					"",
					"You come to a clearing and see a iron sword with a jeweled hilt.",
					"You also see a pack of dynamite.",
					"Which do you choose? (SWORD | DYNAMITE)"
					];
					allowInput = true;
					waitingForInput = true;
			}
			cont = false;
		}
		else{
			if(linesPushed < linesToPush.length){
				progressStory(1);
				//wait(2);
			}
			else if(waitingForInput){
				// Waiting
			}
			else if(!(linesPushed < linesToPush.length) && !waitingForInput && !userQuit && !gameLost && !gameComplete){
				// Resume if there are no lines waiting for a push, no pause for a user input, and the user has not quit the game
				cont = true;
			}
			//checkCurrentPosState(); ???
		}
	}
	
	// Check if key is pressed with its code
	private function checkKey(code:Int):Bool{
		if(keys[code]){
			return true;
		}
		return false;
	}
	
	private function resetPushedLines():Void{
		linesToPush = [];
		linesPushed = 0;
	}
	
	private function progressStory(delay:Int = 0):Void{
		//trace("Progress story");
		var newLine:String = linesToPush[linesPushed];
		
		if(newLine != null){
			printList(newLine);
		}
		linesPushed++;
		
		wait(delay); // Set pause for next loop
	}
	
	private function processInput():Void{
		var input:String = inputTextField.text;
		inputTextField.text = "";
		
		switch(storyPos){
			case 2: // Confirm start
				if (input == "Y"){
					resetPushedLines();
					linesToPush = ["", "Great, I like games."];
					storyPos++;
					waitingForInput = false;
				}
				else if (input == "N"){
					resetPushedLines();
					trace("User has quit game");
					#if (!flash && !html5)
					// Native
					linesToPush = ["", "Not now? Okay", "", "Goodbye2"];
					userQuit = true;
					#else
					// Flash and Web
					linesToPush = ["", "Not now? Okay", "", "Goodbye3", "", "Press R to Restart"];
					gameLost = true;
					#end
				}
				else{
					resetPushedLines();
					linesToPush = ["", "<INVALID INPUT>"];
					waitingForInput = false;
				}
			case 4: // Fork in the road
				if (input == "LEFT"){
					resetPushedLines();
					linesToPush = ["", "You chose wrong! You fell into a pit of spikes and died!", "Your score is 0", "", "Press R to Restart"];
					gameLost = true;
				}
				else if (input == "RIGHT"){
					resetPushedLines();
					linesToPush = ["", "You are right! You go along your merry way."];
					storyPos++;
					waitingForInput = false;
				}
				else{
					resetPushedLines();
					linesToPush = ["", "<INVALID INPUT>"];
					waitingForInput = false;
				}
			case 5: // Lava
				if (input == "BOAT"){
					resetPushedLines();
					linesToPush = ["", "The boat was rigged to explode! You blew up.", "Your score is 1", "", "Press R to Restart"];
					gameLost = true;
				}
				else if (input == "SWIM"){
					resetPushedLines();
					linesToPush = ["", "You chose right! The lava was fake, it was a prank by your friend!", "It was actually water, you were able to swim across safely."];
					storyPos++;
					waitingForInput = false;
				}
				else{
					resetPushedLines();
					linesToPush = ["", "<INVALID INPUT>"];
					waitingForInput = false;
				}
			case 6: // Apple or banana
				if (input == "APPLE"){
					resetPushedLines();
					linesToPush = ["", "The apple was poisoned by a bandit who was hiding in the bushes!", "You are now dead and poor.", "Your score is 2", "", "Press R to Restart"];
					gameLost = true;
				}
				else if (input == "BANANA"){
					resetPushedLines();
					linesToPush = ["", "You chose right! With your hunger satisfied, you move on."];
					storyPos++;
					waitingForInput = false;
				}
				else{
					resetPushedLines();
					linesToPush = ["", "<INVALID INPUT>"];
					waitingForInput = false;
				}
			case 7: // Sword
				if (input == "SWORD"){
					resetPushedLines();
					linesToPush = ["", "The sword was electrified!", "You are now nice and crispy, and also dead.", "Your score is 3", "", "Press R to Restart"];
					gameLost = true;
				}
				else if (input == "DYNAMITE"){
					resetPushedLines();
					linesToPush = ["", "You chose right!", "You now have a pack of dynamite to use against a foe.", "You continue on your path."];
					storyPos++;
					waitingForInput = false;
				}
				else{
					resetPushedLines();
					linesToPush = ["", "<INVALID INPUT>"];
					waitingForInput = false;
				}
		}
	}
	
	private function isValid():Bool{
		return false;
	}
	
	private function printList(text:String, delay:Int = 0):Void{
		textList.push(text);
		updateList();
	}
	
	// Update the displayed text list
	private function updateList(delay:Int = 0):Void{
		var newText:String = "";
		
		var lines:Int = 0;
		var startPos:Int = 0;
		
		if(textList.length <= 12){
			startPos = 0;
		}
		else{
			startPos = textList.length - 12;
		}
		
		while(startPos < textList.length){
			newText += textList[startPos] + "\n";
			
			startPos++;
		}
		
		listTextField.text = newText;
		
	}
	
	// Pause the next update loop execution for the specified time (in seconds)
	private function wait(length:Int):Void{
		//pause = length * 1000;
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
		
		if(pause == 0){
			update(); // Run game loop
		}
		else if (pause > 0){
			if(pause - (1 * deltaTime) < 0){
				pause = 0;
			}
			else{
				pause = pause - (1 * deltaTime);
			}
			//trace(pause);
		}
		else if(pause < 0){
			pause = 0;
			
		}
		
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
		
		cacheTime = currentTime; // Update the cached time
	}
	
	private function onResize(event:Event):Void {
		#if (!flash && !html5)
		var multX:Float = stage.stageWidth / 800; 
		var multY:Float = stage.stageHeight / 480;
		
		this.scaleX = multX;
		this.scaleY = multY;
		
		this.scrollRect = new Rectangle (0, 0, 800 * this.scaleX, 480 * this.scaleY);
		#end
	}
	
	private function onKeyDown(event:KeyboardEvent):Void {
		//trace("Key down: " + event.toString());
		keys[event.keyCode] = true;
		
		// Add to input string if the key is A-Z and input is allowed
		if((event.keyCode >= 65 && event.keyCode <= 90) && allowInput){
			if(inputTextField != null && inputTextField.length < 15){
				inputTextField.text += String.fromCharCode(event.keyCode).toUpperCase();
			}
		}
	}
	private function onKeyUp(event:KeyboardEvent):Void {
		
	}

}
