package states;

import backend.Section.SwagSection;
import backend.Song.SwagSong;
import shaders.WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import shaders.BuildingShaders.BuildingShader;
import shaders.BuildingShaders;
import shaders.ColorSwap;
import ui.PreferencesMenu;

using StringTools;

#if discord_rpc
import backend.Discord.DiscordClient;
#end

class PlayState extends backend.MusicBeatState
{
	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var deathCounter:Int = 0;
	public static var practiceMode:Bool = false;

	var halloweenLevel:Bool = false;

	private var vocals:FlxSound;
	private var vocalsFinished:Bool = false;

	private var dad:objects.Character;
	private var gf:objects.Character;
	private var boyfriend:objects.Boyfriend;

	private var notes:FlxTypedGroup<objects.Note>;
	private var unspawnNotes:Array<objects.Note> = [];

	private var strumLine:FlxSprite;

	private var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	private var strumLineNotes:FlxTypedGroup<FlxSprite>;
	private var playerStrums:FlxTypedGroup<FlxSprite>;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	private var iconP1:objects.HealthIcon;
	private var iconP2:objects.HealthIcon;
	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	public static var seenCutscene:Bool = false;

	var halloweenBG:FlxSprite;
	var isHalloween:Bool = false;

	var phillyCityLights:FlxTypedGroup<FlxSprite>;
	var phillyTrain:FlxSprite;
	var trainSound:FlxSound;

	var foregroundSprites:FlxTypedGroup<stages.objects.BGSprite>;

	var limo:FlxSprite;
	var grpLimoDancers:FlxTypedGroup<stages.objects.BackgroundDancer>;
	var fastCar:FlxSprite;

	var upperBoppers:FlxSprite;
	var bottomBoppers:FlxSprite;
	var santa:FlxSprite;

	var bgGirls:stages.objects.BackgroundGirls;
	var wiggleShit:shaders.WiggleEffect = new shaders.WiggleEffect();

	var tankmanRun:FlxTypedGroup<stages.objects.TankmenBG>;
	var gfCutsceneLayer:FlxGroup;
	var bfTankCutsceneLayer:FlxGroup;
	var tankWatchtower:stages.objects.BGSprite;
	var tankGround:stages.objects.BGSprite;

	var talking:Bool = true;
	var songScore:Int = 0;
	var songMisses:Int = 0;
	var scoreTxt:FlxText;

	var grpNoteSplashes:FlxTypedGroup<objects.NoteSplash>;

	public static var campaignScore:Int = 0;

	var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	var inCutscene:Bool = false;

	#if discord_rpc
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var songLength:Float = 0;
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	var camPos:FlxPoint;
	var lightFadeShader:BuildingShaders;

	override public function create()
	{
		backend.Paths.clearUnusedMemory();
		backend.Paths.clearStoredMemory();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.sound.cache(backend.Paths.inst(PlayState.SONG.song));
		FlxG.sound.cache(backend.Paths.voices(PlayState.SONG.song));

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new backend.SwagCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = backend.Song.loadFromJson('tutorial');

		backend.Conductor.mapBPMChanges(SONG);
		backend.Conductor.changeBPM(SONG.bpm);

		foregroundSprites = new FlxTypedGroup<stages.objects.BGSprite>();

		switch (backend.Paths.formatToSongPath(SONG.song))
		{
			case 'tutorial':
				dialogue = ["Hey you're pretty cute.", 'Use the arrow keys to keep up \nwith me singing.'];
			case 'bopeebo':
				dialogue = [
					'HEY!',
					"You think you can just sing\nwith my daughter like that?",
					"If you want to date her...",
					"You're going to have to go \nthrough ME first!"
				];
			case 'fresh':
				dialogue = ["Not too shabby boy.", ""];
			case 'dadbattle':
				dialogue = [
					"gah you think you're hot stuff?",
					"If you can beat me here...",
					"Only then I will even CONSIDER letting you\ndate my daughter!"
				];
			case 'senpai':
				dialogue = backend.CoolUtil.coolTextFile(backend.Paths.txt('senpai/senpaiDialogue'));
			case 'roses':
				dialogue = backend.CoolUtil.coolTextFile(backend.Paths.txt('roses/rosesDialogue'));
			case 'thorns':
				dialogue = backend.CoolUtil.coolTextFile(backend.Paths.txt('thorns/thornsDialogue'));
		}

		#if discord_rpc
		initDiscord();
		#end

		switch (backend.Paths.formatToSongPath(SONG.song))
		{
			case 'spookeez' | 'monster' | 'south':
				curStage = "spooky";
				halloweenLevel = true;

				var hallowTex = backend.Paths.getSparrowAtlas('halloween_bg');

				halloweenBG = new FlxSprite(-200, -100);
				halloweenBG.frames = hallowTex;
				halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
				halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
				halloweenBG.animation.play('idle');
				halloweenBG.antialiasing = true;
				add(halloweenBG);

				isHalloween = true;
			case 'pico' | 'blammed' | 'philly':
				curStage = 'philly';

				var bg:FlxSprite = new FlxSprite(-100).loadGraphic(backend.Paths.image('philly/sky'));
				bg.scrollFactor.set(0.1, 0.1);
				add(bg);

				var city:FlxSprite = new FlxSprite(-10).loadGraphic(backend.Paths.image('philly/city'));
				city.scrollFactor.set(0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				lightFadeShader = new BuildingShaders();
				phillyCityLights = new FlxTypedGroup<FlxSprite>();

				add(phillyCityLights);

				for (i in 0...5)
				{
					var light:FlxSprite = new FlxSprite(city.x).loadGraphic(backend.Paths.image('philly/win' + i));
					light.scrollFactor.set(0.3, 0.3);
					light.visible = false;
					light.setGraphicSize(Std.int(light.width * 0.85));
					light.updateHitbox();
					light.antialiasing = true;
					light.shader = lightFadeShader.shader;
					phillyCityLights.add(light);
				}

				var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(backend.Paths.image('philly/behindTrain'));
				add(streetBehind);

				phillyTrain = new FlxSprite(2000, 360).loadGraphic(backend.Paths.image('philly/train'));
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(backend.Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				// var cityLights:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.win0.png);

				var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic(backend.Paths.image('philly/street'));
				add(street);
			case "milf" | 'satin-panties' | 'high':
				curStage = 'limo';
				defaultCamZoom = 0.90;

				var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic(backend.Paths.image('limo/limoSunset'));
				skyBG.scrollFactor.set(0.1, 0.1);
				add(skyBG);

				var bgLimo:FlxSprite = new FlxSprite(-200, 480);
				bgLimo.frames = backend.Paths.getSparrowAtlas('limo/bgLimo');
				bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
				bgLimo.animation.play('drive');
				bgLimo.scrollFactor.set(0.4, 0.4);
				add(bgLimo);

				grpLimoDancers = new FlxTypedGroup<stages.objects.BackgroundDancer>();
				add(grpLimoDancers);

				for (i in 0...5)
				{
					var dancer:stages.objects.BackgroundDancer = new stages.objects.BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
					dancer.scrollFactor.set(0.4, 0.4);
					grpLimoDancers.add(dancer);
				}

				var overlayShit:FlxSprite = new FlxSprite(-500, -600).loadGraphic(backend.Paths.image('limo/limoOverlay'));
				overlayShit.alpha = 0.5;
				// add(overlayShit);
				// var shaderBullshit = new BlendModeEffect(new shaders.OverlayShader(), FlxColor.RED);
				// FlxG.camera.setFilters([new ShaderFilter(cast shaderBullshit.shader)]);
				// overlayShit.shader = shaderBullshit;

				limo = new FlxSprite(-120, 550);
				limo.frames = backend.Paths.getSparrowAtlas('limo/limoDrive');
				limo.animation.addByPrefix('drive', "Limo stage", 24);
				limo.animation.play('drive');
				limo.antialiasing = true;

				fastCar = new FlxSprite(-300, 160).loadGraphic(backend.Paths.image('limo/fastCarLol'));
			// add(limo);
			case "cocoa" | 'eggnog':
				curStage = 'mall';

				defaultCamZoom = 0.80;

				var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic(backend.Paths.image('christmas/bgWalls'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.2, 0.2);
				bg.active = false;
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				upperBoppers = new FlxSprite(-240, -90);
				upperBoppers.frames = backend.Paths.getSparrowAtlas('christmas/upperBop');
				upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
				upperBoppers.antialiasing = true;
				upperBoppers.scrollFactor.set(0.33, 0.33);
				upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
				upperBoppers.updateHitbox();
				add(upperBoppers);

				var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic(backend.Paths.image('christmas/bgEscalator'));
				bgEscalator.antialiasing = true;
				bgEscalator.scrollFactor.set(0.3, 0.3);
				bgEscalator.active = false;
				bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
				bgEscalator.updateHitbox();
				add(bgEscalator);

				var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic(backend.Paths.image('christmas/christmasTree'));
				tree.antialiasing = true;
				tree.scrollFactor.set(0.40, 0.40);
				add(tree);

				bottomBoppers = new FlxSprite(-300, 140);
				bottomBoppers.frames = backend.Paths.getSparrowAtlas('christmas/bottomBop');
				bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
				bottomBoppers.antialiasing = true;
				bottomBoppers.scrollFactor.set(0.9, 0.9);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic(backend.Paths.image('christmas/fgSnow'));
				fgSnow.active = false;
				fgSnow.antialiasing = true;
				add(fgSnow);

				santa = new FlxSprite(-840, 150);
				santa.frames = backend.Paths.getSparrowAtlas('christmas/santa');
				santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
				santa.antialiasing = true;
				add(santa);
			case 'winter-horrorland':
				curStage = 'mallEvil';
				var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic(backend.Paths.image('christmas/evilBG'));
				bg.antialiasing = true;
				bg.scrollFactor.set(0.2, 0.2);
				bg.active = false;
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic(backend.Paths.image('christmas/evilTree'));
				evilTree.antialiasing = true;
				evilTree.scrollFactor.set(0.2, 0.2);
				add(evilTree);

				var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic(backend.Paths.image("christmas/evilSnow"));
				evilSnow.antialiasing = true;
				add(evilSnow);
			case 'senpai' | 'roses':
				curStage = 'school';

				// defaultCamZoom = 0.9;

				var bgSky = new FlxSprite().loadGraphic(backend.Paths.image('weeb/weebSky'));
				bgSky.scrollFactor.set(0.1, 0.1);
				add(bgSky);

				var repositionShit = -200;

				var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(backend.Paths.image('weeb/weebSchool'));
				bgSchool.scrollFactor.set(0.6, 0.90);
				add(bgSchool);

				var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(backend.Paths.image('weeb/weebStreet'));
				bgStreet.scrollFactor.set(0.95, 0.95);
				add(bgStreet);

				var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(backend.Paths.image('weeb/weebTreesBack'));
				fgTrees.scrollFactor.set(0.9, 0.9);
				add(fgTrees);

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				var treetex = backend.Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.frames = treetex;
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);

				var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
				treeLeaves.frames = backend.Paths.getSparrowAtlas('weeb/petals');
				treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
				treeLeaves.animation.play('leaves');
				treeLeaves.scrollFactor.set(0.85, 0.85);
				add(treeLeaves);

				var widShit = Std.int(bgSky.width * 6);

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));
				fgTrees.setGraphicSize(Std.int(widShit * 0.8));
				treeLeaves.setGraphicSize(widShit);

				fgTrees.updateHitbox();
				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();
				treeLeaves.updateHitbox();

				bgGirls = new stages.objects.BackgroundGirls(-100, 190);
				bgGirls.scrollFactor.set(0.9, 0.9);

				if (backend.Paths.formatToSongPath(SONG.song) == 'roses')
				{
					bgGirls.getScared();
				}

				bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
				bgGirls.updateHitbox();
				add(bgGirls);
			case 'thorns':
				curStage = 'schoolEvil';

				var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
				var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);

				var posX = 400;
				var posY = 200;

				var bg:FlxSprite = new FlxSprite(posX, posY);
				bg.frames = backend.Paths.getSparrowAtlas('weeb/animatedEvilSchool');
				bg.animation.addByPrefix('idle', 'background 2', 24);
				bg.animation.play('idle');
				bg.scrollFactor.set(0.8, 0.9);
				bg.scale.set(6, 6);
				add(bg);

			/* 
				var bg:FlxSprite = new FlxSprite(posX, posY).loadGraphic(backend.Paths.image('weeb/evilSchoolBG'));
				bg.scale.set(6, 6);
				// bg.setGraphicSize(Std.int(bg.width * 6));
				// bg.updateHitbox();
				add(bg);

				var fg:FlxSprite = new FlxSprite(posX, posY).loadGraphic(backend.Paths.image('weeb/evilSchoolFG'));
				fg.scale.set(6, 6);
				// fg.setGraphicSize(Std.int(fg.width * 6));
				// fg.updateHitbox();
				add(fg);

				wiggleShit.effectType = WiggleEffectType.DREAMY;
				wiggleShit.waveAmplitude = 0.01;
				wiggleShit.waveFrequency = 60;
				wiggleShit.waveSpeed = 0.8;
			 */

			// bg.shader = wiggleShit.shader;
			// fg.shader = wiggleShit.shader;

			/* 
				var waveSprite = new FlxEffectSprite(bg, [waveEffectBG]);
				var waveSpriteFG = new FlxEffectSprite(fg, [waveEffectFG]);

				// Using scale since setGraphicSize() doesnt work???
				waveSprite.scale.set(6, 6);
				waveSpriteFG.scale.set(6, 6);
				waveSprite.setPosition(posX, posY);
				waveSpriteFG.setPosition(posX, posY);

				waveSprite.scrollFactor.set(0.7, 0.8);
				waveSpriteFG.scrollFactor.set(0.9, 0.8);

				// waveSprite.setGraphicSize(Std.int(waveSprite.width * 6));
				// waveSprite.updateHitbox();
				// waveSpriteFG.setGraphicSize(Std.int(fg.width * 6));
				// waveSpriteFG.updateHitbox();

				add(waveSprite);
				add(waveSpriteFG);
			 */

			case 'guns' | 'stress' | 'ugh':
				defaultCamZoom = 0.90;
				curStage = 'tank';

				var bg:stages.objects.BGSprite = new stages.objects.BGSprite('tankSky', -400, -400, 0, 0);
				add(bg);

				var tankSky:stages.objects.BGSprite = new stages.objects.BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
				tankSky.active = true;
				tankSky.velocity.x = FlxG.random.float(5, 15);
				add(tankSky);

				var tankMountains:stages.objects.BGSprite = new stages.objects.BGSprite('tankMountains', -300, -20, 0.2, 0.2);
				tankMountains.setGraphicSize(Std.int(tankMountains.width * 1.2));
				tankMountains.updateHitbox();
				add(tankMountains);

				var tankBuildings:stages.objects.BGSprite = new stages.objects.BGSprite('tankBuildings', -200, 0, 0.30, 0.30);
				tankBuildings.setGraphicSize(Std.int(tankBuildings.width * 1.1));
				tankBuildings.updateHitbox();
				add(tankBuildings);

				var tankRuins:stages.objects.BGSprite = new stages.objects.BGSprite('tankRuins', -200, 0, 0.35, 0.35);
				tankRuins.setGraphicSize(Std.int(tankRuins.width * 1.1));
				tankRuins.updateHitbox();
				add(tankRuins);

				var smokeLeft:stages.objects.BGSprite = new stages.objects.BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
				add(smokeLeft);

				var smokeRight:stages.objects.BGSprite = new stages.objects.BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
				add(smokeRight);

				// tankGround.

				tankWatchtower = new stages.objects.BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
				add(tankWatchtower);

				tankGround = new stages.objects.BGSprite('tankRolling', 300, 300, 0.5, 0.5, ['BG tank w lighting'], true);
				add(tankGround);
				// tankGround.active = false;

				tankmanRun = new FlxTypedGroup<stages.objects.TankmenBG>();
				add(tankmanRun);

				var tankGround:stages.objects.BGSprite = new stages.objects.BGSprite('tankGround', -420, -150);
				tankGround.setGraphicSize(Std.int(tankGround.width * 1.15));
				tankGround.updateHitbox();
				add(tankGround);

				moveTank();

				// smokeLeft.screenCenter();

				var fgTank0:stages.objects.BGSprite = new stages.objects.BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']);
				foregroundSprites.add(fgTank0);

				var fgTank1:stages.objects.BGSprite = new stages.objects.BGSprite('tank1', -300, 750, 2, 0.2, ['fg']);
				foregroundSprites.add(fgTank1);

				// just called 'foreground' just cuz small inconsistency no bbiggei
				var fgTank2:stages.objects.BGSprite = new stages.objects.BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']);
				foregroundSprites.add(fgTank2);

				var fgTank4:stages.objects.BGSprite = new stages.objects.BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']);
				foregroundSprites.add(fgTank4);

				var fgTank5:stages.objects.BGSprite = new stages.objects.BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']);
				foregroundSprites.add(fgTank5);

				var fgTank3:stages.objects.BGSprite = new stages.objects.BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']);
				foregroundSprites.add(fgTank3);

			default:
				defaultCamZoom = 0.9;
				curStage = 'stage';

				var bg:stages.objects.BGSprite = new stages.objects.BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(backend.Paths.image('stagefront'));
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				stageFront.antialiasing = true;
				stageFront.scrollFactor.set(0.9, 0.9);
				stageFront.active = false;
				add(stageFront);

				var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(backend.Paths.image('stagecurtains'));
				stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
				stageCurtains.updateHitbox();
				stageCurtains.antialiasing = true;
				stageCurtains.scrollFactor.set(1.3, 1.3);
				stageCurtains.active = false;

				add(stageCurtains);
		}

		var gfVersion:String = 'gf';

		switch (curStage)
		{
			case 'limo':
				gfVersion = 'gf-car';
			case 'mall' | 'mallEvil':
				gfVersion = 'gf-christmas';
			case 'school' | 'schoolEvil':
				gfVersion = 'gf-pixel';
			case 'tank':
				gfVersion = 'gf-tankmen';
		}

		if (backend.Paths.formatToSongPath(SONG.song) == 'stress')
			gfVersion = 'pico-speaker';

		gf = new objects.Character(400, 130, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		switch (gfVersion)
		{
			case 'pico-speaker':
				gf.x -= 50;
				gf.y -= 200;

				var tempTankman:stages.objects.TankmenBG = new stages.objects.TankmenBG(20, 500, true);
				tempTankman.strumTime = 10;
				tempTankman.resetShit(20, 600, true);
				tankmanRun.add(tempTankman);

				for (i in 0...stages.objects.TankmenBG.animationNotes.length)
				{
					if (FlxG.random.bool(16))
					{
						var tankman:stages.objects.TankmenBG = tankmanRun.recycle(stages.objects.TankmenBG);
						// new stages.objects.TankmenBG(500, 200 + FlxG.random.int(50, 100), stages.objects.TankmenBG.animationNotes[i][1] < 2);
						tankman.strumTime = stages.objects.TankmenBG.animationNotes[i][0];
						tankman.resetShit(500, 200 + FlxG.random.int(50, 100), stages.objects.TankmenBG.animationNotes[i][1] < 2);
						tankmanRun.add(tankman);
					}
				}
		}

		dad = new objects.Character(100, 100, SONG.player2);

		camPos = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		switch (SONG.player2)
		{
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode)
				{
					camPos.x += 600;
					tweenCamIn();
				}
			case "spooky":
				dad.y += 200;
			case "monster":
				dad.y += 100;
			case 'monster-christmas':
				dad.y += 130;
			case 'dad':
				camPos.x += 400;
			case 'pico':
				camPos.x += 600;
				dad.y += 300;
			case 'parents-christmas':
				dad.x -= 500;
			case 'senpai' | 'senpai-angry':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'spirit':
				dad.x -= 150;
				dad.y += 100;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'tankman':
				dad.y += 180;
		}

		boyfriend = new objects.Boyfriend(770, 450, SONG.player1);

		// REPOSITIONING PER STAGE
		switch (curStage)
		{
			case 'limo':
				boyfriend.y -= 220;
				boyfriend.x += 260;

				resetFastCar();
				add(fastCar);
			case 'mall':
				boyfriend.x += 200;
			case 'mallEvil':
				boyfriend.x += 320;
				dad.y -= 80;
			case 'school':
				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
			case 'schoolEvil':
				// trailArea.scrollFactor.set();

				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
				// evilTrail.changeValuesEnabled(false, false, false, false);
				// evilTrail.changeGraphic()
				add(evilTrail);
				// evilTrail.scrollFactor.set(1.1, 1.1);

				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
			case "tank":
				gf.y += 10;
				gf.x -= 30;
				boyfriend.x += 40;
				boyfriend.y += 0;
				dad.y += 60;
				dad.x -= 80;

				if (gfVersion != 'pico-speaker')
				{
					gf.x -= 170;
					gf.y -= 75;
				}
		}

		add(gf);

		gfCutsceneLayer = new FlxGroup();
		add(gfCutsceneLayer);

		bfTankCutsceneLayer = new FlxGroup();
		add(bfTankCutsceneLayer);

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		add(dad);
		add(boyfriend);

		add(foregroundSprites);

		var doof:cutscenes.DialogueBox = new cutscenes.DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;

		backend.Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);

		if (backend.PlayerPrefs.downScroll)
			strumLine.y = FlxG.height - 150; // 150 just random ass number lol

		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		// fake notesplash cache type deal so that it loads in the graphic?

		grpNoteSplashes = new FlxTypedGroup<objects.NoteSplash>();

		var noteSplash:objects.NoteSplash = new objects.NoteSplash(100, 100, 0);
		grpNoteSplashes.add(noteSplash);
		noteSplash.alpha = 0.1;

		add(grpNoteSplashes);

		playerStrums = new FlxTypedGroup<FlxSprite>();

		generateSong();

		// add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(backend.Paths.image('healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		if ((backend.PlayerPrefs.downScroll))
			healthBarBG.y = FlxG.height * 0.1;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		// healthBar
		add(healthBar);

		scoreTxt = new FlxText(healthBarBG.x + healthBarBG.width - 190, healthBarBG.y + 30, 0, "", 20);
		scoreTxt.setFormat(backend.Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		add(scoreTxt);

		iconP1 = new objects.HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new objects.HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		grpNoteSplashes.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		if (isStoryMode && !seenCutscene)
		{
			seenCutscene = true;

			switch (curSong.toLowerCase())
			{
				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play(backend.Paths.sound('Lights_Turn_On'));
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
								}
							});
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					schoolIntro(doof);
				/*case 'ugh': // ima deal with these later
					ughIntro();
				case 'stress':
					stressIntro();
				case 'guns':
					gunsIntro();*/

				default:
					startCountdown();
			}
		}
		else
		{
			switch (curSong.toLowerCase())
			{
				// REMOVE THIS LATER
				// case 'ugh':
				// 	ughIntro();
				// case 'stress':
				// 	stressIntro();
				// case 'guns':
				// 	gunsIntro();

				default:
					startCountdown();
			}
		} 

		if(backend.PlayerPrefs.censorNaughty) health = 0.000000001;

		super.create();
	}

	function ughIntro()
	{
		inCutscene = true;

		var blackShit:FlxSprite = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		blackShit.scrollFactor.set();
		add(blackShit);

		var vid:backend.FlxVideo = new backend.FlxVideo('music/ughCutscene.mp4');
		vid.finishCallback = function()
		{
			remove(blackShit);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (backend.Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});
			startCountdown();
			cameraMovement();
		};

		FlxG.camera.zoom = defaultCamZoom * 1.2;

		camFollow.x += 100;
		camFollow.y += 100;

		/* 
			FlxG.sound.playMusic(backend.Paths.music('DISTORTO'), 0);
			FlxG.sound.music.fadeIn(5, 0, 0.5);

			dad.visible = false;
			var tankCutscene:TankCutscene = new TankCutscene(-20, 320);
			tankCutscene.frames = backend.Paths.getSparrowAtlas('cutsceneStuff/tankTalkSong1');
			tankCutscene.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
			tankCutscene.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
			tankCutscene.animation.play('wellWell');
			tankCutscene.antialiasing = true;
			gfCutsceneLayer.add(tankCutscene);

			camHUD.visible = false;

			FlxG.camera.zoom *= 1.2;
			camFollow.y += 100;

			tankCutscene.startSyncAudio = FlxG.sound.load(backend.Paths.sound('wellWellWell'));

			new FlxTimer().start(3, function(tmr:FlxTimer)
			{
				camFollow.x += 800;
				camFollow.y += 100;
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 0.27, {ease: FlxEase.quadInOut});

				new FlxTimer().start(1.5, function(bep:FlxTimer)
				{
					boyfriend.playAnim('singUP');
					// play sound
					FlxG.sound.play(backend.Paths.sound('bfBeep'), function()
					{
						boyfriend.playAnim('idle');
					});
				});

				new FlxTimer().start(3, function(swaggy:FlxTimer)
				{
					camFollow.x -= 800;
					camFollow.y -= 100;
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 0.5, {ease: FlxEase.quadInOut});
					tankCutscene.animation.play('killYou');
					FlxG.sound.play(backend.Paths.sound('killYou'));
					new FlxTimer().start(6.1, function(swagasdga:FlxTimer)
					{
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (backend.Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});

						FlxG.sound.music.fadeOut((backend.Conductor.crochet / 1000) * 5, 0);

						new FlxTimer().start((backend.Conductor.crochet / 1000) * 5, function(money:FlxTimer)
						{
							dad.visible = true;
							gfCutsceneLayer.remove(tankCutscene);
						});

						cameraMovement();

						startCountdown();
						camHUD.visible = true;
					});
				});
		});*/
	}

	function gunsIntro()
	{
		inCutscene = true;

		var blackShit:FlxSprite = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		blackShit.scrollFactor.set();
		add(blackShit);

		var vid:backend.FlxVideo = new backend.FlxVideo('music/gunsCutscene.mp4');
		vid.finishCallback = function()
		{
			remove(blackShit);

			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (backend.Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});
			startCountdown();
			cameraMovement();
		};

		/* camFollow.setPosition(camPos.x, camPos.y);

			camHUD.visible = false;

			FlxG.sound.playMusic(backend.Paths.music('DISTORTO'), 0);
			FlxG.sound.music.fadeIn(5, 0, 0.5);

			camFollow.y += 100;

			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.3}, 4, {ease: FlxEase.quadInOut});

			dad.visible = false;
			var tankCutscene:TankCutscene = new TankCutscene(20, 320);
			tankCutscene.frames = backend.Paths.getSparrowAtlas('cutsceneStuff/tankTalkSong2');
			tankCutscene.animation.addByPrefix('tankyguy', 'TANK TALK 2', 24, false);
			tankCutscene.animation.play('tankyguy');
			tankCutscene.antialiasing = true;
			gfCutsceneLayer.add(tankCutscene); // add();

			tankCutscene.startSyncAudio = FlxG.sound.load(backend.Paths.sound('tankSong2'));

			new FlxTimer().start(4.1, function(ugly:FlxTimer)
			{
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.4}, 0.4, {ease: FlxEase.quadOut});
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.3}, 0.7, {ease: FlxEase.quadInOut, startDelay: 0.45});

				gf.playAnim('sad');
			});

			new FlxTimer().start(11, function(tmr:FlxTimer)
			{
				FlxG.sound.music.fadeOut((backend.Conductor.crochet / 1000) * 5, 0);

				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (backend.Conductor.crochet * 5) / 1000, {ease: FlxEase.quartIn});
				startCountdown();
				new FlxTimer().start((backend.Conductor.crochet * 25) / 1000, function(daTim:FlxTimer)
				{
					dad.visible = true;
					gfCutsceneLayer.remove(tankCutscene);
				});

				camHUD.visible = true;
		});*/
	}

	/**
	 * [
	 * 	[0, function(){blah;}],
	 * 	[4.6, function(){blah;}],
	 * 	[25.1, function(){blah;}],
	 * 	[30.7, function(){blah;}]
	 * ]
	 * SOMETHING LIKE THIS
	 */
	// var cutsceneFunctions:Array<Dynamic> = [];

	function stressIntro()
	{
		inCutscene = true;

		var blackShit:FlxSprite = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		blackShit.scrollFactor.set();
		add(blackShit);

		var vid:backend.FlxVideo = new backend.FlxVideo('music/stressCutscene.mp4');
		vid.finishCallback = function()
		{
			remove(blackShit);

			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (backend.Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});
			startCountdown();
			cameraMovement();
		};

		/* camHUD.visible = false;

			// for story mode shit
			camFollow.setPosition(camPos.x, camPos.y);

			var dummyLoaderShit:FlxGroup = new FlxGroup();

			add(dummyLoaderShit);

			for (i in 0...7)
			{
				var dummyLoader:FlxSprite = new FlxSprite();
				dummyLoader.loadGraphic(backend.Paths.image('cutsceneStuff/gfHoldup-' + i));
				dummyLoaderShit.add(dummyLoader);
				dummyLoader.alpha = 0.01;
				dummyLoader.y = FlxG.height - 20;
				// dummyLoader.drawFrame(true);
			}

			dad.visible = false;

			// gf.y += 300;
			gf.alpha = 0.01;

			var gfTankmen:FlxSprite = new FlxSprite(210, 70);
			gfTankmen.frames = backend.Paths.getSparrowAtlas('characters/gfTankmen');
			gfTankmen.animation.addByPrefix('loop', 'GF Dancing at Gunpoint', 24, true);
			gfTankmen.animation.play('loop');
			gfTankmen.antialiasing = true;
			gfCutsceneLayer.add(gfTankmen);

			var tankCutscene:TankCutscene = new TankCutscene(-70, 320);
			tankCutscene.frames = backend.Paths.getSparrowAtlas('cutsceneStuff/tankTalkSong3-pt1');
			tankCutscene.animation.addByPrefix('tankyguy', 'TANK TALK 3 P1 UNCUT', 24, false);
			// tankCutscene.animation.addByPrefix('weed', 'sexAmbig', 24, false);
			tankCutscene.animation.play('tankyguy');

			tankCutscene.antialiasing = true;
			bfTankCutsceneLayer.add(tankCutscene); // add();

			var alsoTankCutscene:FlxSprite = new FlxSprite(20, 320);
			alsoTankCutscene.frames = backend.Paths.getSparrowAtlas('cutsceneStuff/tankTalkSong3-pt2');
			alsoTankCutscene.animation.addByPrefix('swagTank', 'TANK TALK 3 P2 UNCUT', 24, false);
			alsoTankCutscene.antialiasing = true;

			bfTankCutsceneLayer.add(alsoTankCutscene);

			alsoTankCutscene.y = FlxG.height + 100;

			camFollow.setPosition(gf.x + 350, gf.y + 560);
			FlxG.camera.focusOn(camFollow.getPosition());

			boyfriend.visible = false;

			var fakeBF:Character = new Character(boyfriend.x, boyfriend.y, 'bf', true);
			bfTankCutsceneLayer.add(fakeBF);

			// var atlasCutscene:Animation
			// var animAssets:AssetManager = new AssetManager();

			// var url = 'images/gfDemon';

			// // animAssets.enqueueSingle(backend.Paths.file(url + "/spritemap1.png"));
			// // animAssets.enqueueSingle(backend.Paths.file(url + "/spritemap1.json"));
			// // animAssets.enqueueSingle(backend.Paths.file(url + "/Animation.json"));

			// animAssets.loadQueue(function(asssss:AssetManager)
			// {
			// 	var daAnim:Animation = asssss.createAnimation('GF Turnin Demon W Effect');
			// 	FlxG.addChildBelowMouse(daAnim);
			// });

			var bfCatchGf:FlxSprite = new FlxSprite(boyfriend.x - 10, boyfriend.y - 90);
			bfCatchGf.frames = backend.Paths.getSparrowAtlas('cutsceneStuff/bfCatchesGF');
			bfCatchGf.animation.addByPrefix('catch', 'BF catches GF', 24, false);
			bfCatchGf.antialiasing = true;
			add(bfCatchGf);
			bfCatchGf.visible = false;

			if (PreferencesMenu.getPref('censor-naughty'))
				tankCutscene.startSyncAudio = FlxG.sound.play(backend.Paths.sound('stressCutscene'));
			else
			{
				tankCutscene.startSyncAudio = FlxG.sound.play(backend.Paths.sound('song3censor'));
				// cutsceneSound.loadEmbedded(backend.Paths.sound('song3censor'));

				var censor:FlxSprite = new FlxSprite();
				censor.frames = backend.Paths.getSparrowAtlas('cutsceneStuff/censor');
				censor.animation.addByPrefix('censor', 'mouth censor', 24);
				censor.animation.play('censor');
				add(censor);
				censor.visible = false;
				//

				new FlxTimer().start(4.6, function(censorTimer:FlxTimer)
				{
					censor.visible = true;
					censor.setPosition(dad.x + 160, dad.y + 180);

					new FlxTimer().start(0.2, function(endThing:FlxTimer)
					{
						censor.visible = false;
					});
				});

				new FlxTimer().start(25.1, function(censorTimer:FlxTimer)
				{
					censor.visible = true;
					censor.setPosition(dad.x + 120, dad.y + 170);

					new FlxTimer().start(0.9, function(endThing:FlxTimer)
					{
						censor.visible = false;
					});
				});

				new FlxTimer().start(30.7, function(censorTimer:FlxTimer)
				{
					censor.visible = true;
					censor.setPosition(dad.x + 210, dad.y + 190);

					new FlxTimer().start(0.4, function(endThing:FlxTimer)
					{
						censor.visible = false;
					});
				});

				new FlxTimer().start(33.8, function(censorTimer:FlxTimer)
				{
					censor.visible = true;
					censor.setPosition(dad.x + 180, dad.y + 170);

					new FlxTimer().start(0.6, function(endThing:FlxTimer)
					{
						censor.visible = false;
					});
				});
			}

			// new FlxTimer().start(0.01, function(tmr) cutsceneSound.play()); // cutsceneSound.play();
			// cutsceneSound.play();
			// tankCutscene.startSyncAudio = cutsceneSound;
			// tankCutscene.animation.curAnim.curFrame

			FlxG.camera.zoom = defaultCamZoom * 1.15;

			camFollow.x -= 200;

			// cutsceneSound.onComplete = startCountdown;

			// Cunt 1
			new FlxTimer().start(31.5, function(cunt:FlxTimer)
			{
				camFollow.x += 400;
				camFollow.y += 150;
				FlxG.camera.zoom = defaultCamZoom * 1.4;
				FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.1}, 0.5, {ease: FlxEase.elasticOut});
				FlxG.camera.focusOn(camFollow.getPosition());
				boyfriend.playAnim('singUPmiss');
				boyfriend.animation.finishCallback = function(animFinish:String)
				{
					camFollow.x -= 400;
					camFollow.y -= 150;
					FlxG.camera.zoom /= 1.4;
					FlxG.camera.focusOn(camFollow.getPosition());

					boyfriend.animation.finishCallback = null;
				};
			});

			new FlxTimer().start(15.1, function(tmr:FlxTimer)
			{
				camFollow.y -= 170;
				camFollow.x += 200;
				FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom * 1.3}, 2.1, {
					ease: FlxEase.quadInOut
				});

				new FlxTimer().start(2.2, function(swagTimer:FlxTimer)
				{
					// FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.7, {ease: FlxEase.elasticOut});
					FlxG.camera.zoom = 0.8;
					// camFollow.y -= 100;
					boyfriend.visible = false;
					bfCatchGf.visible = true;
					bfCatchGf.animation.play('catch');

					bfTankCutsceneLayer.remove(fakeBF);

					bfCatchGf.animation.finishCallback = function(anim:String)
					{
						bfCatchGf.visible = false;
						boyfriend.visible = true;
					};

					new FlxTimer().start(3, function(weedShitBaby:FlxTimer)
					{
						camFollow.y += 180;
						camFollow.x -= 80;
					});

					new FlxTimer().start(2.3, function(gayLol:FlxTimer)
					{
						bfTankCutsceneLayer.remove(tankCutscene);
						alsoTankCutscene.y = 320;
						alsoTankCutscene.animation.play('swagTank');
						// tankCutscene.animation.play('weed');
					});
				});

				gf.visible = false;
				var cutsceneShit:states.debug.CutsceneCharacter = new states.debug.CutsceneCharacter(210, 70, 'gfHoldup');
				gfCutsceneLayer.add(cutsceneShit);
				gfCutsceneLayer.remove(gfTankmen);

				cutsceneShit.onFinish = function()
				{
					gf.alpha = 1;
					gf.visible = true;
				};

				// add(cutsceneShit);
				new FlxTimer().start(20, function(alsoTmr:FlxTimer)
				{
					dad.visible = true;
					bfTankCutsceneLayer.remove(alsoTankCutscene);
					startCountdown();
					remove(dummyLoaderShit);
					dummyLoaderShit.destroy();
					dummyLoaderShit = null;

					gfCutsceneLayer.remove(cutsceneShit);
				});
		});*/
	}

	function initDiscord():Void
	{
		#if discord_rpc
		storyDifficultyText = difficultyString();
		iconRPC = SONG.player2;

		// To avoid having duplicate images in Discord assets
		switch (iconRPC)
		{
			case 'senpai-angry':
				iconRPC = 'senpai';
			case 'monster-christmas':
				iconRPC = 'monster';
			case 'mom-car':
				iconRPC = 'mom';
		}

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		detailsText = isStoryMode ? "Story Mode: Week " + storyWeek : "Freeplay";
		detailsPausedText = "Paused - " + detailsText;

		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		#end
	}

	function schoolIntro(?dialogueBox:cutscenes.DialogueBox):Void
	{
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = backend.Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * daPixelZoom));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += senpaiEvil.width / 5;

		camFollow.setPosition(camPos.x, camPos.y);

		if (backend.Paths.formatToSongPath(SONG.song) == 'roses' || backend.Paths.formatToSongPath(SONG.song) == 'thorns')
		{
			remove(black);

			if (backend.Paths.formatToSongPath(SONG.song) == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
			else
				FlxG.sound.play(backend.Paths.sound('ANGRY'));
			// moved senpai angry noise in here to clean up cutscene switch case lol
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
				tmr.reset(0.3);
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (backend.Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
								swagTimer.reset();
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(backend.Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
						add(dialogueBox);
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer = new FlxTimer();
	var perfectMode:Bool = false;

	function startCountdown():Void
	{
		inCutscene = false;
		camHUD.visible = true;

		generateStaticArrows(0);
		generateStaticArrows(1);

		talking = false;
		startedCountdown = true;
		backend.Conductor.songPosition = 0;
		backend.Conductor.songPosition -= backend.Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer.start(backend.Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			// this just based on beatHit stuff but compact
			if (swagCounter % gfSpeed == 0)
				gf.dance();
			if (swagCounter % 2 == 0)
			{
				if (!boyfriend.animation.curAnim.name.startsWith("sing"))
					boyfriend.playAnim('idle');
				if (!dad.animation.curAnim.name.startsWith("sing"))
					dad.dance();
			}
			else if (dad.curCharacter == 'spooky' && !dad.animation.curAnim.name.startsWith("sing"))
				dad.dance();
			if (generatedMusic)
				notes.sort(sortNotes, FlxSort.DESCENDING);

			var introSprPaths:Array<String> = ["ready", "set", "go"];
			var altSuffix:String = "";

			if (curStage.startsWith("school"))
			{
				altSuffix = '-pixel';
				introSprPaths = ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel'];
			}

			var introSndPaths:Array<String> = ["intro3" + altSuffix, "intro2" + altSuffix,
				"intro1" + altSuffix, "introGo" + altSuffix];

			if (swagCounter > 0)
				readySetGo(introSprPaths[swagCounter - 1]);
			FlxG.sound.play(backend.Paths.sound(introSndPaths[swagCounter]), 0.6);

			/* switch (swagCounter)
			{
				case 0:
					
				case 1:
					
				case 2:
					
				case 3:
					
			} */

			swagCounter += 1;
		}, 4);
	}

	function readySetGo(path:String):Void
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(backend.Paths.image(path));
		spr.scrollFactor.set();

		if (curStage.startsWith('school'))
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.updateHitbox();
		spr.screenCenter();
		add(spr);
		FlxTween.tween(spr, {y: spr.y += 100, alpha: 0}, backend.Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				spr.destroy();
			}
		});
	}

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;

		if (!paused)
			FlxG.sound.playMusic(backend.Paths.inst(SONG.song), 1, false);
		FlxG.sound.music.onComplete = endSong;
		vocals.play();

		#if discord_rpc
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength);
		#end
	}

	private function generateSong():Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		backend.Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(backend.Paths.voices(SONG.song));
		else
			vocals = new FlxSound();

		vocals.onComplete = function()
		{
			vocalsFinished = true;
		};
		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<objects.Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;

				var oldNote:objects.Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:objects.Note = new objects.Note(daStrumTime, daNoteData, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.altNote = songNotes[3];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / backend.Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:objects.Note = new objects.Note(daStrumTime + (backend.Conductor.stepCrochet * susNote) + backend.Conductor.stepCrochet, daNoteData, oldNote, true);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
						sustainNote.x += FlxG.width / 2; // general offset
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2; // general offset
			}
		}

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	// Now you are probably wondering why I made 2 of these very similar functions
	// sortByShit(), and sortNotes(). sortNotes is meant to be used by both sortByShit(), and the notes FlxGroup
	// sortByShit() is meant to be used only by the unspawnNotes array.
	// and the array sorting function doesnt need that order variable thingie
	// this is good enough for now lololol HERE IS COMMENT FOR THIS SORTA DUMB DECISION LOL
	function sortByShit(Obj1:objects.Note, Obj2:objects.Note):Int
	{
		return sortNotes(FlxSort.ASCENDING, Obj1, Obj2);
	}

	function sortNotes(order:Int = FlxSort.ASCENDING, Obj1:objects.Note, Obj2:objects.Note)
	{
		return FlxSort.byValues(order, Obj1.strumTime, Obj2.strumTime);
	}

	// ^ These two sorts also look cute together ^

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);
			var colorswap:ColorSwap = new ColorSwap();
			babyArrow.shader = colorswap.shader;
			colorswap.update(objects.Note.arrowColors[i]);

			switch (curStage)
			{
				case 'school' | 'schoolEvil':
					babyArrow.loadGraphic(backend.Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);
					babyArrow.animation.add('green', [6]);
					babyArrow.animation.add('red', [7]);
					babyArrow.animation.add('blue', [5]);
					babyArrow.animation.add('purplel', [4]);

					babyArrow.setGraphicSize(Std.int(babyArrow.width * daPixelZoom));
					babyArrow.updateHitbox();
					babyArrow.antialiasing = false;

					switch (Math.abs(i))
					{
						case 0:
							babyArrow.x += objects.Note.swagWidth * 0;
							babyArrow.animation.add('static', [0]);
							babyArrow.animation.add('pressed', [4, 8], 12, false);
							babyArrow.animation.add('confirm', [12, 16], 24, false);
						case 1:
							babyArrow.x += objects.Note.swagWidth * 1;
							babyArrow.animation.add('static', [1]);
							babyArrow.animation.add('pressed', [5, 9], 12, false);
							babyArrow.animation.add('confirm', [13, 17], 24, false);
						case 2:
							babyArrow.x += objects.Note.swagWidth * 2;
							babyArrow.animation.add('static', [2]);
							babyArrow.animation.add('pressed', [6, 10], 12, false);
							babyArrow.animation.add('confirm', [14, 18], 12, false);
						case 3:
							babyArrow.x += objects.Note.swagWidth * 3;
							babyArrow.animation.add('static', [3]);
							babyArrow.animation.add('pressed', [7, 11], 12, false);
							babyArrow.animation.add('confirm', [15, 19], 24, false);
					}

				default:
					babyArrow.frames = backend.Paths.getSparrowAtlas('NOTE_assets');
					babyArrow.animation.addByPrefix('green', 'arrowUP');
					babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
					babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
					babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

					babyArrow.antialiasing = true;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

					switch (Math.abs(i))
					{
						case 0:
							babyArrow.x += objects.Note.swagWidth * 0;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 1');
							babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
						case 1:
							babyArrow.x += objects.Note.swagWidth * 1;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 2');
							babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
						case 2:
							babyArrow.x += objects.Note.swagWidth * 2;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 4');
							babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
						case 3:
							babyArrow.x += objects.Note.swagWidth * 3;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 3');
							babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
					}
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			if (player == 1)
				playerStrums.add(babyArrow);

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (backend.Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals();

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;

			#if discord_rpc
			if (startTimer.finished)
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength - backend.Conductor.songPosition);
			else
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		super.closeSubState();
	}

	#if discord_rpc
	override public function onFocus():Void
	{
		if (health > 0 && !paused && FlxG.autoPause)
		{
			if (backend.Conductor.songPosition > 0.0)
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength - backend.Conductor.songPosition);
			else
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		}

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		if (health > 0 && !paused && FlxG.autoPause)
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);

		super.onFocusLost();
	}
	#end

	function resyncVocals():Void
	{
		if (_exiting)
			return;

		vocals.pause();
		FlxG.sound.music.play();
		backend.Conductor.songPosition = FlxG.sound.music.time + backend.Conductor.offset;

		if (vocalsFinished)
			return;

		vocals.time = backend.Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		// makes the lerp non-dependant on the framerate
		// FlxG.camera.followLerp = backend.CoolUtil.camLerpShit(0.04);

		#if !debug
		perfectMode = false;
		#end

		// do this BEFORE super.update() so songPosition is accurate
		if (startingSong)
		{
			if (startedCountdown)
			{
				backend.Conductor.songPosition += FlxG.elapsed * 1000;
				if (backend.Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			backend.Conductor.songPosition = FlxG.sound.music.time + backend.Conductor.offset; // 20 is THE MILLISECONDS??
			// backend.Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (backend.Conductor.lastSongPos != backend.Conductor.songPosition)
				{
					songTime = (songTime + backend.Conductor.songPosition) / 2;
					backend.Conductor.lastSongPos = backend.Conductor.songPosition;
					// backend.Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}
			// backend.Conductor.lastSongPos = FlxG.sound.music.time;
		}

		switch (curStage)
		{
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}

				lightFadeShader.update((backend.Conductor.crochet / 1000) * FlxG.elapsed * 1.5);
			// phillyCityLights.members[curLight].alpha -= (backend.Conductor.crochet / 1000) * FlxG.elapsed;

			case 'tank':
				moveTank();
		}

		super.update(elapsed);

		scoreTxt.text = "Score: " + songScore + " | " + "Misses: " + songMisses + " | " + "Health: " + Math.round(health * 50.0) + "%";

		if (controls.PAUSE && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			// 1 / 1000 chance for Gitaroo Man easter egg
			if (FlxG.random.bool(0.1))
			{
				// gitaroo man easter egg
				FlxG.switchState(new states.GitarooPause());
			}
			else
			{
				var boyfriendPos = boyfriend.getScreenPosition();
				var pauseSubState = new substates.PauseSubState(boyfriendPos.x, boyfriendPos.y);
				openSubState(pauseSubState);
				pauseSubState.camera = camHUD;
				boyfriendPos.put();
			}

			#if discord_rpc
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new states.debug.ChartingState());

			#if discord_rpc
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}

		if (FlxG.keys.justPressed.NINE)
			iconP1.swapOldIcon();

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.85)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.85)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		/* if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new Charting()); */

		if (FlxG.keys.justPressed.ONE)
			endSong();
		if (FlxG.keys.justPressed.EIGHT)
		{
			/* 	 8 for opponent char
			   SHIFT+8 for player char
				 CTRL+SHIFT+8 for gf   */
			if (FlxG.keys.pressed.SHIFT)
				if (FlxG.keys.pressed.CONTROL)
					FlxG.switchState(new states.debug.AnimationDebug(gf.curCharacter));
				else 
					FlxG.switchState(new states.debug.AnimationDebug(SONG.player1));
			else
				FlxG.switchState(new states.debug.AnimationDebug(SONG.player2));
		}

		/*if (FlxG.keys.justPressed.PAGEUP)
			changeSection(1);
		if (FlxG.keys.justPressed.PAGEDOWN)
			changeSection(-1);*/

		if (generatedMusic && SONG.notes[Std.int(curStep / 16)] != null)
		{
			cameraRightSide = SONG.notes[Std.int(curStep / 16)].mustHitSection;

			cameraMovement();
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (curSong == 'Fresh')
		{
			switch (curBeat)
			{
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
				case 163:
					// FlxG.sound.music.stop();
					// FlxG.switchState(new states.TitleState());
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (curBeat)
			{
				case 128, 129, 130:
					vocals.volume = 0;
					// FlxG.sound.music.stop();
					// FlxG.switchState(new PlayState());
			}
		}
		// better streaming of shit

		if (!inCutscene && !_exiting)
		{
			// RESET = Quick Game Over Screen
			if (controls.RESET)
			{
				health = 0;
				trace("RESET = True");
			}

			#if CAN_CHEAT // brandon's a pussy
			if (controls.CHEAT)
			{
				health += 1;
				trace("User is cheating!");
			}
			#end

			if (health <= 0 && !practiceMode)
			{
				// boyfriend.stunned = true;

				persistentUpdate = false;
				persistentDraw = false;
				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				// unloadAssets();

				deathCounter += 1;

				openSubState(new substates.GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				// FlxG.switchState(new states.GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if discord_rpc
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
				#end
			}
		}

		while (unspawnNotes[0] != null && unspawnNotes[0].strumTime - backend.Conductor.songPosition < 1800 / SONG.speed)
		{
			var dunceNote:objects.Note = unspawnNotes[0];
			notes.add(dunceNote);

			var index:Int = unspawnNotes.indexOf(dunceNote);
			unspawnNotes.shift();
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:objects.Note)
			{
				if (((backend.PlayerPrefs.downScroll) && daNote.y < -daNote.height)
					|| (!(backend.PlayerPrefs.downScroll) && daNote.y > FlxG.height))
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				var strumLineMid = strumLine.y + objects.Note.swagWidth / 2;

				if ((backend.PlayerPrefs.downScroll))
				{
					daNote.y = (strumLine.y + (backend.Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));

					if (daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith("end") && daNote.prevNote != null)
							daNote.y += daNote.prevNote.height;
						else
							daNote.y += daNote.height / 2;

						if ((!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
							&& daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= strumLineMid)
						{
							// clipRect is applied to graphic itself so use frame Heights
							var swagRect:FlxRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);

							swagRect.height = (strumLineMid - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;
							daNote.clipRect = swagRect;
						}
					}
				}
				else
				{
					daNote.y = (strumLine.y - (backend.Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));

					if (daNote.isSustainNote
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
						&& daNote.y + daNote.offset.y * daNote.scale.y <= strumLineMid)
					{
						var swagRect:FlxRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);

						swagRect.y = (strumLineMid - daNote.y) / daNote.scale.y;
						swagRect.height -= swagRect.y;
						daNote.clipRect = swagRect;
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit) // opponent stuff
				{
					opponentNoteHit(daNote);
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * SONG.speed));

				// removing this so whether the note misses or not is entirely up to Note class
				// var noteMissPresses:Bool = daNote.y < -daNote.height;

				// if ((backend.PlayerPrefs.downScroll))
					// noteMissPresses = daNote.y > FlxG.height;

				if (daNote.isSustainNote && daNote.wasGoodHit)
				{
					if ((!(backend.PlayerPrefs.downScroll) && daNote.y < -daNote.height)
						|| ((backend.PlayerPrefs.downScroll) && daNote.y > FlxG.height))
					{
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}
				else if (daNote.tooLate || daNote.wasGoodHit)
				{
					if (daNote.tooLate)
					{
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		if (!inCutscene)
			keyShit();
	}

	function killCombo():Void
	{
		if (combo > 5 && gf.animOffsets.exists('sad'))
			gf.playAnim('sad');
		if (combo != 0)
		{
			combo = 0;
			displayCombo();
		}
	}

	#if debug
	function changeSection(sec:Int):Void
	{
		FlxG.sound.music.pause();

		var daBPM:Float = SONG.bpm;
		var daPos:Float = 0;
		for (i in 0...(Std.int(curStep / 16 + sec)))
		{
			if (SONG.notes[i].changeBPM)
			{
				daBPM = SONG.notes[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		backend.Conductor.songPosition = FlxG.sound.music.time = daPos;
		updateCurStep();
		resyncVocals();
	}
	#end

	function endSong():Void
	{
		seenCutscene = false;
		deathCounter = 0;
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;

		if (SONG.validScore)
		{
			backend.Highscore.saveScore(SONG.song, songScore, storyDifficulty);
		}

		if (isStoryMode)
		{
			campaignScore += songScore;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic(backend.Paths.music('freakyMenu'));

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				switch (PlayState.storyWeek)
				{
					case 7:
						FlxG.switchState(new VideoState());
					default:
						FlxG.switchState(new states.StoryMenuState());
				}

				// if ()
				states.StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, states.StoryMenuState.weekUnlocked.length - 1))] = true;

				if (SONG.validScore)
				{
					backend.Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
				}

				FlxG.save.data.weekUnlocked = states.StoryMenuState.weekUnlocked;
				FlxG.save.flush();
			}
			else
			{
				var difficulty:String = backend.CoolUtil.getDifficultyFilePath();

				trace('LOADING NEXT SONG');
				trace(backend.Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				FlxG.sound.music.stop();
				vocals.stop();

				if (backend.Paths.formatToSongPath(SONG.song) == 'eggnog')
				{
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;
					inCutscene = true;

					FlxG.sound.play(backend.Paths.sound('Lights_Shut_off'), function()
					{
						// no camFollow so it centers on horror tree
						SONG = backend.Song.loadFromJson(storyPlaylist[0].toLowerCase() + difficulty, storyPlaylist[0]);
						states.LoadingState.loadAndSwitchState(new PlayState());
					});
				}
				else
				{
					prevCamFollow = camFollow;

					SONG = backend.Song.loadFromJson(storyPlaylist[0].toLowerCase() + difficulty, storyPlaylist[0]);
					states.LoadingState.loadAndSwitchState(new PlayState());
				}
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			// unloadAssets();
			FlxG.switchState(new states.FreeplayState());
		}
	}

	// gives score and pops up rating
	private function popUpScore(strumtime:Float, daNote:objects.Note):Void
	{
		var noteDiff:Float = Math.abs(strumtime - backend.Conductor.songPosition);
		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 375;

		var daRating:String = "sick";

		var isSick:Bool = true;

		if (noteDiff > backend.Conductor.safeZoneOffset * 0.9)
		{
			daRating = 'shit';
			score = 50;
			isSick = false; // shitty copypaste on this literally just because im lazy and tired lol!
			health -= 0.07;
		}
		else if (noteDiff > backend.Conductor.safeZoneOffset * 0.75)
		{
			daRating = 'bad';
			score = 100;
			isSick = false;
			health -= 0.05;
		}
		else if (noteDiff > backend.Conductor.safeZoneOffset * 0.3)
		{
			daRating = 'good';
			score = 200;
			isSick = false;
			health += 0.02;
		}

		if (isSick)
		{
			var noteSplash:objects.NoteSplash = grpNoteSplashes.recycle(objects.NoteSplash);
			noteSplash.setupNoteSplash(daNote.x, daNote.y, daNote.noteData);
			// new objects.NoteSplash(daNote.x, daNote.y, daNote.noteData);
			grpNoteSplashes.add(noteSplash);

			health += 0.04;
		}

		// Only add the score if you're not on practice mode
		if (!practiceMode)
			songScore += score;

		// ludum dare rating system
		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var ratingPath:String = daRating;

		if (curStage.startsWith('school'))
			ratingPath = "weeb/pixelUI/" + ratingPath + "-pixel";

		rating.loadGraphic(backend.Paths.image(ratingPath));
		rating.x = FlxG.width * 0.55 - 40;
		// make sure rating is visible lol!
		if (rating.x < FlxG.camera.scroll.x)
			rating.x = FlxG.camera.scroll.x;
		else if (rating.x > FlxG.camera.scroll.x + FlxG.camera.width - rating.width)
			rating.x = FlxG.camera.scroll.x + FlxG.camera.width - rating.width;

		rating.y = FlxG.camera.scroll.y + FlxG.camera.height * 0.4 - 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		add(rating);

		if (curStage.startsWith('school'))
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = true;
		}
		rating.updateHitbox();

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				rating.destroy();
			},
			startDelay: backend.Conductor.crochet * 0.001
		});
		if (combo >= 10 || combo == 0)
			displayCombo();
	}

	function displayCombo():Void
	{
		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (curStage.startsWith('school'))
		{
			pixelShitPart1 = 'weeb/pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(backend.Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.y = FlxG.camera.scroll.y + FlxG.camera.height * 0.4 + 80;
		comboSpr.x = FlxG.width * 0.55;
		// make sure combo is visible lol!
		// 194 fits 4 combo digits
		if (comboSpr.x < FlxG.camera.scroll.x + 194)
			comboSpr.x = FlxG.camera.scroll.x + 194;
		else if (comboSpr.x > FlxG.camera.scroll.x + FlxG.camera.width - comboSpr.width)
			comboSpr.x = FlxG.camera.scroll.x + FlxG.camera.width - comboSpr.width;

		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.velocity.x += FlxG.random.int(1, 10);

		add(comboSpr);

		if (curStage.startsWith('school'))
		{
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
		}
		else
		{
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = true;
		}
		comboSpr.updateHitbox();

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				comboSpr.destroy();
			},
			startDelay: backend.Conductor.crochet * 0.001
		});

		var seperatedScore:Array<Int> = [];
		var tempCombo:Int = combo;

		while (tempCombo != 0)
		{
			seperatedScore.push(tempCombo % 10);
			tempCombo = Std.int(tempCombo / 10);
		}
		while (seperatedScore.length < 3)
			seperatedScore.push(0);

		// seperatedScore.reverse();

		var daLoop:Int = 1;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(backend.Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.y = comboSpr.y;

			if (curStage.startsWith('school'))
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			else
			{
				numScore.antialiasing = true;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			numScore.updateHitbox();

			numScore.x = comboSpr.x - (43 * daLoop); //- 90;
			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: backend.Conductor.crochet * 0.002
			});

			daLoop++;
		}
	}

	var cameraRightSide:Bool = false;

	function cameraMovement()
	{
		if (camFollow.x != dad.getMidpoint().x + 150 && !cameraRightSide)
		{
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);

			switch (dad.curCharacter)
			{
				case 'mom':
					camFollow.y = dad.getMidpoint().y;
				case 'senpai' | 'senpai-angry':
					camFollow.y = dad.getMidpoint().y - 430;
					camFollow.x = dad.getMidpoint().x - 100;
			}

			if (dad.curCharacter == 'mom')
				vocals.volume = 1;

			if (backend.Paths.formatToSongPath(SONG.song) == 'tutorial')
				tweenCamIn();
		}

		if (cameraRightSide && camFollow.x != boyfriend.getMidpoint().x - 100)
		{
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			switch (curStage)
			{
				case 'limo':
					camFollow.x = boyfriend.getMidpoint().x - 300;
				case 'mall':
					camFollow.y = boyfriend.getMidpoint().y - 200;
				case 'school' | 'schoolEvil':
					camFollow.x = boyfriend.getMidpoint().x - 200;
					camFollow.y = boyfriend.getMidpoint().y - 200;
			}

			if (backend.Paths.formatToSongPath(SONG.song) == 'tutorial')
				FlxTween.tween(FlxG.camera, {zoom: 1}, (backend.Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
		}
	}

	private function keyShit():Void
	{
		// control arrays, order L D R U
		var holdArray:Array<Bool> = [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
		var pressArray:Array<Bool> = [
			controls.NOTE_LEFT_P,
			controls.NOTE_DOWN_P,
			controls.NOTE_UP_P,
			controls.NOTE_RIGHT_P
		];
		var releaseArray:Array<Bool> = [
			controls.NOTE_LEFT_R,
			controls.NOTE_DOWN_R,
			controls.NOTE_UP_R,
			controls.NOTE_RIGHT_R
		];

		// HOLDS, check for sustain notes
		if (holdArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
		{
			notes.forEachAlive(function(daNote:objects.Note)
			{
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.noteData])
					goodNoteHit(daNote);
			});
		}

		// PRESSES, check for note hits
		if (pressArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
		{
			boyfriend.holdTimer = 0;

			var possibleNotes:Array<objects.Note> = []; // notes that can be hit
			var directionList:Array<Int> = []; // directions that can be hit
			var dumbNotes:Array<objects.Note> = []; // notes to kill later

			notes.forEachAlive(function(daNote:objects.Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					if (directionList.contains(daNote.noteData))
					{
						for (coolNote in possibleNotes)
						{
							if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
							{ // if it's the same note twice at < 10ms distance, just delete it
								// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
								dumbNotes.push(daNote);
								break;
							}
							else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
							{ // if daNote is earlier than existing note (coolNote), replace
								possibleNotes.remove(coolNote);
								possibleNotes.push(daNote);
								break;
							}
						}
					}
					else
					{
						possibleNotes.push(daNote);
						directionList.push(daNote.noteData);
					}
				}
			});

			for (note in dumbNotes)
			{
				FlxG.log.add("killing dumb ass note at " + note.strumTime);
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}

			possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

			if (perfectMode)
				goodNoteHit(possibleNotes[0]);
			else if (possibleNotes.length > 0)
			{
				for (shit in 0...pressArray.length)
				{ // if a direction is hit that shouldn't be
					if (pressArray[shit] && !directionList.contains(shit))
						noteMissPresses(shit);
				}
				for (coolNote in possibleNotes)
				{
					if (pressArray[coolNote.noteData])
						goodNoteHit(coolNote);
				}
			}
			else
			{
				for (shit in 0...pressArray.length)
					if (pressArray[shit])
						noteMissPresses(shit);
			}
		}

		if (boyfriend.holdTimer > backend.Conductor.stepCrochet * 4 * 0.001 && !holdArray.contains(true))
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.playAnim('idle');
			}
		}

		playerStrums.forEach(function(spr:FlxSprite)
		{
			if (pressArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				spr.animation.play('pressed');
			if (!holdArray[spr.ID])
				spr.animation.play('static');

			if (spr.animation.curAnim.name == 'confirm' && !curStage.startsWith('school'))
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();
		});
	}

	function noteMiss(note:objects.Note):Void
	{
		health -= 0.1;
		killCombo();

		songMisses++;

		if (!practiceMode)
			songScore -= 10;

		vocals.volume = 0;
		FlxG.sound.play(backend.Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		boyfriend.playAnim(singAnimations[Std.int(Math.abs(note.noteData))] + 'miss', true);
	}

	
	function noteMissPresses(direction:Int = 1):Void
	{
		health -= 0.1;
		killCombo();

		songMisses++;

		if (!practiceMode)
			songScore -= 10;

		vocals.volume = 0;
		FlxG.sound.play(backend.Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
	} 

	function goodNoteHit(note:objects.Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note.strumTime, note);
			}

			boyfriend.playAnim(singAnimations[Std.int(Math.abs(note.noteData))], true);

			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.animation.play('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function opponentNoteHit(note:objects.Note):Void
	{
		if (SONG.song != 'Tutorial')
			camZooming = true;

			var altAnim:String = "";

			var dadSingAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

			if (SONG.notes[Math.floor(curStep / 16)] != null)
			{
					if (SONG.notes[Math.floor(curStep / 16)].altAnim)
					    altAnim = '-alt';
			}

			if (note.altNote)
				altAnim = '-alt';

			dad.playAnim(dadSingAnimations[Std.int(Math.abs(note.noteData))] + altAnim, true);

			dad.holdTimer = 0;

			if (SONG.needsVoices)
				vocals.volume = 1;

			note.kill();
			notes.remove(note, true);
			note.destroy();
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive()
	{
		FlxG.sound.play(backend.Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
		});
	}

	function moveTank():Void
	{
		if (!inCutscene)
		{
			var daAngleOffset:Float = 1;
			tankAngle += FlxG.elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;

			tankGround.x = tankX + Math.cos(FlxAngle.asRadians((tankAngle * daAngleOffset) + 180)) * 1500;
			tankGround.y = 1300 + Math.sin(FlxAngle.asRadians((tankAngle * daAngleOffset) + 180)) * 1100;
		}
	}

	var tankResetShit:Bool = false;
	var tankMoving:Bool = false;
	var tankAngle:Float = FlxG.random.int(-90, 45);
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankX:Float = 400;

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		gf.playAnim('hairFall');
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(backend.Paths.soundRandom('thunder_', 1, 2));
		halloweenBG.animation.play('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		boyfriend.playAnim('scared', true);
		gf.playAnim('scared', true);
	}

	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (backend.Conductor.songPosition - backend.Conductor.offset)) > 20
			|| (SONG.needsVoices && Math.abs(vocals.time - (backend.Conductor.songPosition - backend.Conductor.offset)) > 20))
		{
			resyncVocals();
		}

		if (dad.curCharacter == 'spooky' && curStep % 4 == 2)
		{
			// dad.dance();
		}
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(sortNotes, FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				backend.Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			// else
			// backend.Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);
		wiggleShit.update(backend.Conductor.crochet);

		// HARDCODING FOR MILF ZOOMS!

		if (PreferencesMenu.getPref('camera-zoom'))
		{
			if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
			}

			if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
			}
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (curBeat % gfSpeed == 0)
			gf.dance();

		if (curBeat % 2 == 0)
		{
			if (!boyfriend.animation.curAnim.name.startsWith("sing"))
				boyfriend.playAnim('idle');
			if (!dad.animation.curAnim.name.startsWith("sing"))
				dad.dance();
		}
		else if (dad.curCharacter == 'spooky')
		{
			if (!dad.animation.curAnim.name.startsWith("sing"))
				dad.dance();
		}

		if (curBeat % 8 == 7 && curSong == 'Bopeebo')
		{
			boyfriend.playAnim('hey', true);
		}

		if (curBeat % 16 == 15 && SONG.song == 'Tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48)
		{
			boyfriend.playAnim('hey', true);
			dad.playAnim('cheer', true);
		}

		foregroundSprites.forEach(function(spr:stages.objects.BGSprite)
		{
			spr.dance();
		});

		// boppin friends
		switch (curStage)
		{
			case 'school':
				bgGirls.dance();

			case 'mall':
				upperBoppers.animation.play('bop', true);
				bottomBoppers.animation.play('bop', true);
				santa.animation.play('idle', true);

			case 'limo':
				grpLimoDancers.forEach(function(dancer:stages.objects.BackgroundDancer)
				{
					dancer.dance();
				});

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					lightFadeShader.reset();

					phillyCityLights.forEach(function(light:FlxSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1);

					phillyCityLights.members[curLight].visible = true;
					// phillyCityLights.members[curLight].alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
			case 'tank':
				tankWatchtower.dance();
		}

		if (isHalloween && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
	}

	var curLight:Int = 0;
}
