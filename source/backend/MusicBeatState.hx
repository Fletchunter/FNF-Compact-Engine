package backend;

import backend.Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;

class MusicBeatState extends FlxUIState
{
	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var controls(get, never):backend.Controls;

	inline function get_controls():backend.Controls
		return PlayerSettings.player1.controls;

	override function create()
	{
		if (transIn != null)
			// trace('reg ' + transIn.region);

		super.create();
	}

	override function update(elapsed:Float)
	{
		// everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep >= 0)
			stepHit();

		super.update(elapsed);
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...backend.Conductor.bpmChangeMap.length)
		{
			if (backend.Conductor.songPosition >= backend.Conductor.bpmChangeMap[i].songTime)
				lastChange = backend.Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((backend.Conductor.songPosition - lastChange.songTime) / backend.Conductor.stepCrochet);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// do literally nothing dumbass
	}
}
