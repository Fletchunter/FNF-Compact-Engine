package ui;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import ui.AtlasText.AtlasFont;
import ui.TextMenuList.TextMenuItem;

class PreferencesMenu extends ui.OptionsState.Page
{
	public static var preferences:Map<String, Dynamic> = new Map();

	private var pref:String = null;
	public var value:Dynamic = null;

	var items:TextMenuList;

	var checkboxes:Array<CheckboxThingie> = [];
	var menuCamera:FlxCamera;
	var camFollow:FlxObject;

	var save:FlxSave;

	public function new()
	{
		super();

		menuCamera = new SwagCamera();
		FlxG.cameras.add(menuCamera, false);
		menuCamera.bgColor = 0x0;
		camera = menuCamera;

		add(items = new TextMenuList());

		createPrefItem('naughtyness', 'censorNaughty', true);
		createPrefItem('downscroll', 'downScroll', false);
		createPrefItem('flashing menu', 'flashingMenu', true);
		createPrefItem('Camera Zooming on Beat', 'cameraZoom', true);
		createPrefItem('FPS Counter', 'fpsCounter', true);
		createPrefItem('Auto Pause', 'autoPause', false);

		camFollow = new FlxObject(FlxG.width / 2, 0, 140, 70);
		if (items != null)
			camFollow.y = items.selectedItem.y;

		menuCamera.follow(camFollow, null, 0.06);
		var margin = 160;
		menuCamera.deadzone.set(0, margin, menuCamera.width, 40);
		menuCamera.minScrollY = 0;

		items.onChange.add(function(selected)
		{
			camFollow.y = selected.y;
		});

	}

	/*public static function getPref(pref:String):Dynamic {
		return PlayerPrefs.getPref(pref);
	}
	
	public static function setPref(pref:String, value:Dynamic):Void {
		PlayerPrefs.setPref(pref, value);
	}*/

	public static function getPref(pref:String):Dynamic {
        return Reflect.getProperty(PlayerPrefs, pref);
        trace(pref);
    }
    
    public static function setPref(pref:String, value:Dynamic):Void {
        Reflect.setProperty(PlayerPrefs, pref, value);
        trace(pref);
    }
	

	
	/*
	public static function initPrefs():Void // its pointless because the prefs should be saved from json file
	{
		preferenceCheck('censorNaughty', true);
		preferenceCheck('downscroll', false);
		preferenceCheck('flashingMenu', true);
		preferenceCheck('cameraZoom', true);
		preferenceCheck('fpsCounter', true);
		preferenceCheck('autoPause', false);
		
	
		
		#if muted
		setPref('master-volume', 0);
		FlxG.sound.muted = true;
		#end
		

		FlxG.autoPause = PlayerPrefs.autoPause;
	}
	*/
	

	private function createPrefItem(prefName:String, prefString:String, prefValue:Dynamic):Void
	{
		items.createItem(120, (120 * items.length) + 30, prefName, AtlasFont.Bold, function()
		{
			preferenceCheck(prefString, prefValue);

			switch (Type.typeof(prefValue).getName())
			{
				case 'TBool':
					prefToggle(prefString);

				default:
					trace('swag');
			}
		});

		switch (Type.typeof(prefValue).getName())
		{
			case 'TBool':
				createCheckbox(prefString);

			default:
				trace('swag');
		}

		trace(Type.typeof(prefValue).getName());
	}

	function createCheckbox(prefString:String)
	{
		var checkbox:CheckboxThingie = new CheckboxThingie(0, 120 * (items.length - 1), getPref(prefString));
		checkboxes.push(checkbox);
		add(checkbox);
	}

	/**
	 * Assumes that the preference has already been checked/set?
	 */
	private function prefToggle(prefName:String):Void {
		var daSwap:Bool = getPref(prefName);
		daSwap = !daSwap;
		setPref(prefName, daSwap);
		checkboxes[items.selectedIndex].daValue = daSwap;
		trace('toggled? ' + daSwap);
	
		if (PlayerPrefs.fpsCounter) {
			    FlxG.stage.addChild(Main.fpsCounter);
			} else {
				FlxG.stage.removeChild(Main.fpsCounter);
			}
			
			FlxG.autoPause = PlayerPrefs.autoPause;
	
		PlayerPrefs.saveSettings(); // Save all preferences to JSON
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// menuCamera.followLerp = CoolUtil.camLerpShit(0.05);

		items.forEach(function(daItem:TextMenuItem)
		{
			if (items.selectedItem == daItem)
				daItem.x = 150;
			else
				daItem.x = 120;
		});
	}

	public static function preferenceCheck(prefString:String, prefValue:Dynamic):Void
	{
		if (getPref(prefString) == null)
		{
			setPref(prefString, prefValue);
			trace(prefString + ' = ' + prefValue);
		}
		else
		{
			trace('found preference: ' + getPref(prefString));
		}
	}
}

class CheckboxThingie extends FlxSprite
{
	public var daValue(default, set):Bool;

	public function new(x:Float, y:Float, daValue:Bool = false)
	{
		super(x, y);

		frames = Paths.getSparrowAtlas('checkboxThingie');
		animation.addByPrefix('static', 'Check Box unselected', 24, false);
		animation.addByPrefix('checked', 'Check Box selecting animation', 24, false);

		antialiasing = true;

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();

		this.daValue = daValue;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		switch (animation.curAnim.name)
		{
			case 'static':
				offset.set();
			case 'checked':
				offset.set(17, 70);
		}
	}

	function set_daValue(value:Bool):Bool
	{
		if (value)
			animation.play('checked', true);
		else
			animation.play('static');

		return value;
	}
}
