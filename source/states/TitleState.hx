package states;

import backend.Highscore;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.FlxAssets;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import lime.ui.Window;
import openfl.Assets;
import openfl.display.Sprite;
import openfl.events.AsyncErrorEvent;
import openfl.events.AsyncErrorEvent;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.NetStatusEvent;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import shaders.BuildingShaders.BuildingShader;
import shaders.BuildingShaders;
import shaders.ColorSwap;
import ui.PreferencesMenu;

using StringTools;

#if discord_rpc
import backend.Discord.DiscordClient;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
import sys.io.FileInput;
import sys.io.FileOutput;
import sys.io.Process;
import sys.thread.Thread;
#end

class TitleState extends backend.MusicBeatState
{
	public static var initialized:Bool = false;
	var startedIntro:Bool;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:objects.Alphabet;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;

	var curWacky:Array<String> = [];
	var wackyImage:FlxSprite;
	var lastBeat:Int = 0;
	var swagShader:ColorSwap;
	var alphaShader:BuildingShaders;
	var thingie:FlxSprite;

	var video:Video;
	var netStream:NetStream;
	private var overlay:Sprite;

	override public function create():Void
	{
		#if polymod
		polymod.Polymod.init({modRoot: "mods", dirs: ['introMod'], framework: OPENFL});
		// FlxG.bitmap.clearCache();
		#end

		startedIntro = false;

		FlxG.game.focusLostFramerate = 60;

		swagShader = new ColorSwap();
		alphaShader = new BuildingShaders();

		FlxG.sound.muteKeys = [ZERO];

		curWacky = FlxG.random.getObject(getIntroTextShit());

		// DEBUG BULLSHIT

		FlxG.autoPause = backend.PlayerPrefs.autoPause;

		super.create();

		FlxG.save.bind('funkin', 'ninjamuffin99');

		backend.PlayerPrefs.initPrefs();
		// PreferencesMenu.initPrefs();
		backend.PlayerSettings.init();

		var filePath:String = "preferences/preferences.json";

		#if sys
        if (!FileSystem.exists(filePath)) {
            FileSystem.createDirectory("preferences");
            var file:FileOutput = File.write(filePath);

            file.writeString("{}");
            file.close();

			backend.PlayerPrefs.saveSettings();
			trace('pref data is empty! setting the default variable from file');
        }
		#end

		/*if (isNotepadRunning()) { // this is stupid, do not open this unless you want to?
            writeToFile("usingNotepadHuh.txt", "What are you writing or reading at?");
        } else {
			var text:String = "Oh, nevermind. It sounds like you didn't use Notepad. I shouldn't assume too much, sorry.\nBut I know exactly why you shouldn't assume too much.\n\n";
			var reasons:Array<String> = [
				"It can lead to misunderstandings.",
				"You might miss important details.",
				"Assumptions can cause conflicts.",
				"It's always better to verify facts.",
				"Assuming limits your understanding."
			];
			
			var randomIndex:Int = Math.floor(Math.random() * reasons.length);
			var randomReason:String = reasons[randomIndex];
			var reasonNumber:Int = randomIndex + 1;
			
			text += 'Reason ${reasonNumber}: ${randomReason}';
			
			writeToFile("usingNotepadHuh.txt", text);
			
			
        }*/

		/*if (!sys.FileSystem.exists("preferences")) {
			sys.FileSystem.createDirectory("preferences");
			sys.io.File.writeString("preferences/preferences.json", '{}');
		}

		if (!sys.FileSystem.exists("preferences/preferences.json")) {
            backend.PlayerPrefs.saveSettings();
			trace('pref file didnt exist! creating the file');
        }*/

		backend.Highscore.load();

		#if newgrounds
		NGio.init();
		#end
			
		if (FlxG.save.data.weekUnlocked != null)
		{
			// FIX LATER!!!
			// WEEK UNLOCK PROGRESSION!!
			// states.StoryMenuState.weekUnlocked = FlxG.save.data.weekUnlocked;

			if (states.StoryMenuState.weekUnlocked.length < 4)
				states.StoryMenuState.weekUnlocked.insert(0, true);

			// QUICK PATCH OOPS!
			if (!states.StoryMenuState.weekUnlocked[0])
				states.StoryMenuState.weekUnlocked[0] = true;
		}

		if (FlxG.save.data.seenVideo != null)
		{
			VideoState.seenVideo = FlxG.save.data.seenVideo;
		}

		#if FREEPLAY
		FlxG.switchState(new states.FreeplayState());
		#elseif ANIMATE
		FlxG.switchState(new states.debug.CutsceneAnimTestState());
		#elseif CHARTING
		FlxG.switchState(new states.debug.ChartingState());
		/* 
			#elseif web


			if (!initialized)
			{

				video = new Video();
				FlxG.stage.addChild(video);

				var netConnection = new NetConnection();
				netConnection.connect(null);

				netStream = new NetStream(netConnection);
				netStream.client = {onMetaData: client_onMetaData};
				netStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, netStream_onAsyncError);
				netConnection.addEve0ntListener(NetStatusEvent.NET_STATUS, netConnection_onNetStatus);
				// netStream.addEventListener(NetStatusEvent.NET_STATUS) // netStream.play(backend.Paths.file('music/kickstarterTrailer.mp4'));

				overlay = new Sprite();
				overlay.graphics.beginFill(0, 0.5);
				overlay.graphics.drawRect(0, 0, 1280, 720);
				overlay.addEventListener(MouseEvent.MOUSE_DOWN, overlay_onMouseDown);

				overlay.buttonMode = true;
				// FlxG.stage.addChild(overlay);

			}
		 */

		// netConnection.addEventListener(MouseEvent.MOUSE_DOWN, overlay_onMouseDown);
		#else
		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			startIntro();
		});
		#end

		#if discord_rpc
		DiscordClient.initialize();

		Application.current.onExit.add(function(exitCode)
		{
			DiscordClient.shutdown();
		});
		#end
	}

	/*private function isNotepadRunning():Bool {  // this is stupid, do not open this unless you want to?
		var process = new Process('tasklist');
		var readableList:String = process.stdout.readAll().toString().toLowerCase();
		process.close();
	
		var programList:Array<String> = ["notepad.exe"];
	
		for (i in 0...programList.length) {
			if (readableList.indexOf(programList[i]) != -1) {
				return true;
			}
		}
	
		return false;
	}*/

	private function writeToFile(filePath:String, content:String):Void {
		#if sys
		var file:FileOutput = File.write(filePath);
		file.writeString(content);
		file.close();
		#end
	}

	private function client_onMetaData(metaData:Dynamic)
	{
		video.attachNetStream(netStream);

		video.width = video.videoWidth;
		video.height = video.videoHeight;
		// video.
	}

	private function netStream_onAsyncError(event:AsyncErrorEvent):Void
	{
		trace("Error loading video");
	}

	private function netConnection_onNetStatus(event:NetStatusEvent):Void
	{
		if (event.info.code == 'NetStream.Play.Complete')
		{
			// netStream.dispose();
			// FlxG.stage.removeChild(video);

			startIntro();
		}

		trace(event.toString());
	}

	private function overlay_onMouseDown(event:MouseEvent):Void
	{
		netStream.soundTransform.volume = 0.2;
		netStream.soundTransform.pan = -1;
		// netStream.play(backend.Paths.file('music/kickstarterTrailer.mp4'));

		FlxG.stage.removeChild(overlay);
	}
	var logoBl:FlxSprite;

	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;

	function startIntro()
	{
		if (!initialized)
		{
			var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			diamond.persist = true;
			diamond.destroyOnNoUse = false;

			FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
				new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
			FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
				{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
		}

		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(backend.Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		}

		backend.Conductor.changeBPM(102);
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		// bg.antialiasing = true;
		// bg.setGraphicSize(Std.int(bg.width * 0.6));
		// bg.updateHitbox();

		add(bg);

		logoBl = new FlxSprite(-150, -100);
		logoBl.frames = backend.Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = true;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.animation.play('bump');

		logoBl.updateHitbox();

		logoBl.shader = swagShader.shader;
		// logoBl.shader = alphaShader.shader;

		// trace();
		// logoBl.screenCenter();
		// logoBl.color = FlxColor.BLACK;

		gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		gfDance.frames = backend.Paths.getSparrowAtlas('gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.antialiasing = true;
		add(gfDance);

		gfDance.shader = swagShader.shader;

		add(logoBl);

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = backend.Paths.getSparrowAtlas('titleEnter');
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = true;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		// titleText.screenCenter(X);
		add(titleText);

		var logo:FlxSprite = new FlxSprite().loadGraphic(backend.Paths.image('logo'));
		logo.screenCenter();
		logo.antialiasing = true;
		// add(logo);

		// FlxTween.tween(logoBl, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
		// FlxTween.tween(logo, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		// var atlasBullShit:FlxSprite = new FlxSprite();
		// atlasBullShit.frames = CoolUtil.fromAnimate(backend.Paths.image('money'), backend.Paths.file('images/money.json'));
		// credGroup.add(atlasBullShit);

		credTextShit = new objects.Alphabet(0, 0, "ninjamuffin99\nPhantomArcade\nkawaisprite\nevilsk8er", true);
		credTextShit.screenCenter();

		// credTextShit.alignment = CENTER;

		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(backend.Paths.image('newgrounds_logo'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = true;

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		FlxG.mouse.visible = false;

		if (initialized)
			skipIntro();
		else
			initialized = true;

		/**
		if (FlxG.sound.music != null)
		FlxG.sound.music.onComplete = function() FlxG.switchState(new VideoState());
		*/

		startedIntro = true;
		// credGroup.add(credTextShit);
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(backend.Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;

	override function update(elapsed:Float)
	{
		#if debug
		if (FlxG.keys.justPressed.EIGHT)
			FlxG.switchState(new states.debug.CutsceneAnimTestState());
		#end

		/* 
			if (FlxG.keys.justPressed.R)
			{
				#if polymod
				polymod.Polymod.init({modRoot: "mods", dirs: ['introMod']});
				trace('reinitialized');
				#end
			}

		 */

		if (FlxG.sound.music != null)
			backend.Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

		if (FlxG.keys.justPressed.F)
			FlxG.fullscreen = !FlxG.fullscreen;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
				pressedEnter = true;
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}

		if (pressedEnter && !transitioning && skippedIntro)
		{
			if (FlxG.sound.music != null)
				FlxG.sound.music.onComplete = null;
			// netStream.play(backend.Paths.file('music/kickstarterTrailer.mp4'));;

			// If it's Friday according to da clock

			titleText.animation.play('press');

			FlxG.camera.flash(FlxColor.WHITE, 1);
			FlxG.sound.play(backend.Paths.sound('confirmMenu'), 0.7);

			transitioning = true;
			// FlxG.sound.music.stop();

			#if newgrounds
			if (!OutdatedSubState.leftState)
			{
				NGio.checkVersion(function(version)
				{
					// Check if version is outdated

					var localVersion:String = "v" + Application.current.meta.get('version');
					var onlineVersion = version.split(" ")[0].trim();

					if (version.trim() != onlineVersion)
					{
						trace('OLD VERSION!');
						// FlxG.switchState(new OutdatedSubState());
					}
					else
					{
						 //FlxG.switchState(new states.MainMenuState());
					}

					// REDO FOR ITCH/FINAL SHIT
					FlxG.switchState(new states.MainMenuState());
				});
			}
			#else
			new FlxTimer().start(1.25, function(tmr:FlxTimer)
			{
				FlxG.switchState(new states.MainMenuState());
			});
			#end
			// FlxG.sound.play(backend.Paths.music('titleShoot'), 0.7);
		}

		if (pressedEnter && !skippedIntro && initialized)
			skipIntro();
		/* 
			#if web
			if (!initialized && controls.ACCEPT)
			{
				// netStream.dispose();
				// FlxG.stage.removeChild(video);

				startIntro();
				skipIntro();
			}
			#end
		 */

		// if (FlxG.keys.justPressed.SPACE)
		// swagShader.hasOutline = !swagShader.hasOutline;

		if (controls.UI_LEFT)
			swagShader.update(-elapsed * 0.1);

		if (controls.UI_RIGHT)
			swagShader.update(elapsed * 0.1);

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>)
	{
		for (i in 0...textArray.length)
		{
			var money:objects.Alphabet = new objects.Alphabet(0, 0, textArray[i], true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 200;
			credGroup.add(money);
			textGroup.add(money);
		}
	}

	function addMoreText(text:String)
	{
		var coolText:objects.Alphabet = new objects.Alphabet(0, 0, text, true, false);
		coolText.screenCenter(X);
		coolText.y += (textGroup.length * 60) + 200;
		credGroup.add(coolText);
		textGroup.add(coolText);
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	var isRainbow:Bool = false;

	override function beatHit()
	{
		super.beatHit();

		if (!startedIntro)
			return ;

		if (skippedIntro)
		{
			logoBl.animation.play('bump', true);

			danceLeft = !danceLeft;

			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}
		else
		{
			FlxG.log.add(curBeat);
			// if the user is draggin the window some beats will
			// be missed so this is just to compensate
			if (curBeat > lastBeat)
			{
				for (i in lastBeat...curBeat)
				{
					switch (i + 1)
					{
						case 1:
							createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
						// credTextShit.visible = true;
						case 3:
							addMoreText('present');
						// credTextShit.text += '\npresent...';
						// credTextShit.addText();
						case 4:
							deleteCoolText();
						// credTextShit.visible = false;
						// credTextShit.text = 'In association \nwith';
						// credTextShit.screenCenter();
						case 5:
							createCoolText(['Not association', 'with']);
						case 7:
							addMoreText('newgrounds');
							ngSpr.visible = true;
						// credTextShit.text += '\nNewgrounds';
						case 8:
							deleteCoolText();
							ngSpr.visible = false;
						// credTextShit.visible = false;

						// credTextShit.text = 'Shoutouts Tom Fulp';
						// credTextShit.screenCenter();
						case 9:
							createCoolText([curWacky[0]]);
						// credTextShit.visible = true;
						case 11:
							addMoreText(curWacky[1]);
						// credTextShit.text += '\nlmao';
						case 12:
							deleteCoolText();
						// credTextShit.visible = false;
						// credTextShit.text = "Friday";
						// credTextShit.screenCenter();
						case 13:
							addMoreText('Friday');
						// credTextShit.visible = true;
						case 14:
							addMoreText('Night');
						// credTextShit.text += '\nNight';
						case 15:
							addMoreText('Funkin'); // credTextShit.text += '\nFunkin';

						case 16:
							skipIntro();
					}
				}
			}
			lastBeat = curBeat;
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			remove(ngSpr);

			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(credGroup);
			skippedIntro = true;
		}
	}
}
