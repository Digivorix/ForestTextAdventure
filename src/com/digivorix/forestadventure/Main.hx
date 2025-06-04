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
		
		// Set up primary text format
		terminalFormat = new TextFormat("Perfect DOS VGA 437", 20, 0xFFFFFF);
		
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
		inputTextField.defaultTextFormat = terminalFormat;
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
		
		textList = [];
		linesToPush = [];
		
		#if flash
		stage.scaleMode = StageScaleMode.EXACT_FIT;
		#end
	}
	
	private function restart():Void{
		trace("Restart game");
		pause = 0;
		storyPos = 4; // Skip all the introductory stuff
		
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
			restart(); //For Flash and HTML5
			#end
		}
		// Restart from loss
		if (checkKey(Keyboard.R) && gameLost && !userQuit){
			restart();
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
			else if(!(linesPushed < linesToPush.length) && !waitingForInput && !userQuit && !gameLost){
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
		trace("Progress story");
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
			case 2:
				if (input == "Y"){
					resetPushedLines();
					linesToPush = ["", "Great, I like games."];
					//wait(2);
					storyPos++;
					waitingForInput = false;
				}
				else if (input == "N"){
					resetPushedLines();
					trace("User has quit game");
					#if (!flash && !html5)
					// Native
					linesToPush = ["", "Not now? Okay", "", "Goodbye"];
					userQuit = true;
					#else
					// Flash and Web
					linesToPush = ["", "Not now? Okay", "", "Goodbye", "", "Press R to Restart"];
					gameLost = true;
					#end
				}
				else{
					resetPushedLines();
					linesToPush = ["", "<INVALID INPUT>"];
					waitingForInput = false;
				}
			case 4:
				if (input == "LEFT"){
					resetPushedLines();
					linesToPush = ["", "You chose wrong! You fell into a pit of spikes and died!", "Your score is 0", "", "Press R to Restart"];
					//wait(2);
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
