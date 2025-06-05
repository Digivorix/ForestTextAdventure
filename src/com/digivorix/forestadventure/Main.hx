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
	var pause:Float = 0; // Update loop pause length (multiplied by 1000)
	var storyPos:Int = 0; // Current story position (used in update loop and input checks)
	
	// Variables for updating the text list
	var linesToPush:Array<String>;
	var linesPushed:Int = 0;
	
	var running:Bool = true; // Is application running?
	var cont:Bool = true; // Continue with story in the update loop?
	var userQuit:Bool = false; // Did user agree to the game?
	var gameComplete:Bool = false; // Has the game been completed?
	var gameLost:Bool = false; // Has the game been lost?
	var waitingForInput:Bool = false; // Is the game waiting for the user's input?
	
	var keys:Array<Bool>; // Store the value of keys pressed
	var allowInput:Bool = false; // Is input allowed?
	
	// Sprite containers for various elements
	var graphicSprite:Sprite; // Contains the story graphics
	var listSprite:Sprite; // Contains the text list (aka the terminal readout)
	var inputSprite:Sprite; // Contains the input text box
	
	// Font format
	var terminalFormat:TextFormat;
	var inputFormat:TextFormat;
	
	// List text variables
	var listTextField:TextField;
	var textList:Array<String>; // List of text that is looped through and displayed in the listTextField
	
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
		terminalFormat = new TextFormat("Perfect DOS VGA 437", 16, 0xFFFFFF);
		
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
	
	// Restart the game
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
		
		// Restart from loss or completion
		if (checkKey(Keyboard.R) && (gameLost || gameComplete) && !userQuit){
			restart(4);
		}
		
		// Submit or subtract from input box content
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
			allowInput = false;
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
					"<SYSTEM> Hello", 
					"", 
					"<SYSTEM> I am GEOS"
					];
					storyPos++;
				case 2:
					resetPushedLines();
					linesToPush = ["", "<SYSTEM> Would you like to play a game? (Y | N)"];
					//allowInput = true;
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
					//allowInput = true;
					waitingForInput = true;
				case 5:
					resetPushedLines();
					linesToPush = [
					"",
					"You then come to a pool of lava.",
					"Do swim across or take a boat? (SWIM | BOAT)"
					];
					//allowInput = true;
					waitingForInput = true;
				case 6:
					resetPushedLines();
					linesToPush = [
					"",
					"Later you find an apple and a banana, you are hungry.",
					"Which one do you eat? (APPLE | BANANA)"
					];
					//allowInput = true;
					waitingForInput = true;
				case 7:
					resetPushedLines();
					linesToPush = [
					"",
					"You come to a clearing and see a iron sword with a jeweled hilt.",
					"You also see a pack of dynamite.",
					"Which do you choose? (SWORD | DYNAMITE)"
					];
					//allowInput = true;
					waitingForInput = true;
				case 8:
					resetPushedLines();
					linesToPush = [
					"",
					"You find a electric fence blocking your path.",
					"Do you blow it up with a stick of dynamite?", "Or run as fast as you can at it?",
					"(DYNAMITE | RUN)"
					];
					//allowInput = true;
					waitingForInput = true;
				case 9:
					resetPushedLines();
					linesToPush = [
					"",
					"You come to another clearing and see a book and a strange looking device.",
					"Do you pick up the book or the device? (BOOK | DEVICE)"
					];
					//allowInput = true;
					waitingForInput = true;
				case 10:
					resetPushedLines();
					linesToPush = [
					"",
					"You find a nuke and its detonator and a brick after entering the castle.",
					"Which one do you take, the nuke or brick? (NUKE | BRICK)"
					];
					//allowInput = true;
					waitingForInput = true;
				case 11:
					resetPushedLines();
					linesToPush = [
					"",
					"You have found a dragon upstairs! You only get one shot!",
					"Do you use the nuke or all of the sticks of dynamite? (NUKE | DYNAMITE)"
					];
					//allowInput = true;
					waitingForInput = true;
				
			}
			cont = false;
		}
		else{ // For after a new prompt is pushed to the display
			if(linesPushed < linesToPush.length){ //Will add the new lines to the display before anything else
				progressStory(0.5);
				//wait(2);
			}
			else if(waitingForInput){
				// Waiting
				if (!allowInput)
					allowInput = true;
			}
			else if(!(linesPushed < linesToPush.length) && !waitingForInput && !userQuit && !gameLost && !gameComplete){
				// Resume if there are no lines waiting for a push, no pause for a user input, and the game has not ended in any way
				cont = true;
			}
		}
	}
	
	// Check if key is pressed with its code
	private function checkKey(code:Int):Bool{
		if(keys[code]){
			return true;
		}
		return false;
	}
	
	// Reset the pushed line variables
	private function resetPushedLines():Void{
		linesToPush = [];
		linesPushed = 0;
	}
	
	// Progress the story by pushing the new lines to the display
	private function progressStory(delay:Float = 0):Void{
		//trace("Progress story");
		var newLine:String = linesToPush[linesPushed];
		
		if(newLine != null){
			printList(newLine);
		}
		linesPushed++;
		
		wait(delay); // Set pause for next loop
	}
	
	// Decide what will happen based on the user's input
	private function processInput():Void{
		var input:String = inputTextField.text;
		inputTextField.text = "";
		
		switch(storyPos){
			case 2: // Confirm start
				if (input == "Y"){
					resetPushedLines();
					linesToPush = ["", "<SYSTEM> Great, I like games."];
					storyPos++;
					waitingForInput = false;
				}
				else if (input == "N"){
					resetPushedLines();
					trace("User has quit game");
					#if (!flash && !html5)
					// Native
					linesToPush = ["", "<SYSTEM> Not now? Okay", "", "<SYSTEM> Goodbye"];
					userQuit = true;
					#else
					// Flash and Web
					linesToPush = ["", "<SYSTEM> Not now? Okay", "", "<SYSTEM> Goodbye", "", "Press R to Restart"];
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
			case 8: // Fence
				if (input == "DYNAMITE"){
					resetPushedLines();
					linesToPush = ["", "You don't know how to use dynamite properly yet!", "You blew yourself up!", "Your score is 4", "", "Press R to Restart"];
					gameLost = true;
				}
				else if (input == "RUN"){
					resetPushedLines();
					linesToPush = ["", "The fence was a hologram!", "It was too expensive to get a real one,", "so a hologram was put in place to scare away intruders.", "You cross through it safely.", "You continue to follow the dirt road."];
					storyPos++;
					waitingForInput = false;
				}
				else{
					resetPushedLines();
					linesToPush = ["", "<INVALID INPUT>"];
					waitingForInput = false;
				}
			case 9: // Strange device and book
				if (input == "DEVICE"){
					resetPushedLines();
					linesToPush = ["", "The device was a black hole generator and you turned it on!", "Well, there goes the Earth, see ya!", "Your score is 5", "", "Press R to Restart"];
					gameLost = true;
				}
				else if (input == "BOOK"){
					resetPushedLines();
					linesToPush = ["", "You read the book! You now know how to use dynamite.", "You're lucky you didn't try to use it before or you could have blown yourself up!", "You see a castle up ahead and decide to go and enter it"];
					storyPos++;
					waitingForInput = false;
				}
				else{
					resetPushedLines();
					linesToPush = ["", "<INVALID INPUT>"];
					waitingForInput = false;
				}
			case 10: // Nuke and brick
				if (input == "BRICK"){
					resetPushedLines();
					linesToPush = ["", "The brick was part of a crucial support system!", "You're now buried under a pile of rubble! You're also dead.", "Your score is 6", "", "Press R to Restart"];
					gameLost = true;
				}
				else if (input == "NUKE"){
					resetPushedLines();
					linesToPush = ["", "Hey, you didn't blow up! You now have a nuke and its detonator!", "You continue upstairs to where you just heard a loud ROAR!"];
					storyPos++;
					waitingForInput = false;
				}
				else{
					resetPushedLines();
					linesToPush = ["", "<INVALID INPUT>"];
					waitingForInput = false;
				}
			case 11: // Dragon
				if (input == "NUKE"){
					resetPushedLines();
					linesToPush = ["", "You blew up the dragon, but also yourself, the castle, and the surrounding area!", "Good job hero.", "Your score is 7/8. You were so close!", "", "Press R to Restart", "ESC to Quit"];
					gameLost = true;
				}
				else if (input == "DYNAMITE"){
					resetPushedLines();
					linesToPush = ["", "You blew up the dragon and lived!", "You return to your town a hero and live you life to a nice old age.", "Your score is 8/8. YOU WIN!", "", "Press R to Restart", "ESC to Quit"];
					storyPos++;
					waitingForInput = false;
					gameComplete = true;
				}
				else{
					resetPushedLines();
					linesToPush = ["", "<INVALID INPUT>"];
					waitingForInput = false;
				}
		}
	}
	
	//Add a new line of text to display
	private function printList(text:String, delay:Int = 0):Void{
		textList.push(text);
		updateList();
	}
	
	// Update the displayed text list
	private function updateList(delay:Int = 0):Void{
		var maxLines:Int = 12;
		
		#if (!html5)
		maxLines = 15;
		#else
		maxLines = 12; // Less lines to account for HTML5 text weirdness
		#end
		
		var newText:String = "";
		
		var lines:Int = 0;
		var startPos:Int = 0;
		
		if(textList.length <= maxLines){
			startPos = 0;
		}
		else{
			startPos = textList.length - maxLines;
		}
		
		while(startPos < textList.length){
			newText += textList[startPos] + "\n";
			
			startPos++;
		}
		
		listTextField.text = newText;
		
	}
	
	// Pause the next update loop execution for the specified time (in seconds)
	private function wait(length:Float):Void{
		//pause = length * 1000;
		pause = 0.25 * 1000;
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
	
	private function onResize(event:Event):Void { // For native platforms
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
