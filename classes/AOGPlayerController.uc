/**
* The generic AOG Player Controller
*
* The primary 'problem' with AOG is going to be the asymmetric gameplay.
* I'm going to need one PC to cover both 'giant' and 'mobile' gameplay.
* That's this class right here.
* At least I can keep things in separate states.
*/

class AOGPlayerController extends AOCPlayerController;

var array<float> SizeMessageThresholds;

//Welcome users to the game
reliable client function ShowDefaultGameHeader()
{
	if (AOCGRI(Worldinfo.GRI) == none)
	{
		SetTimer(0.1f, false, 'ShowDefaultGameHeader');
		return;
	}

	super.ShowDefaultGameHeader();
	
	//Localize() will find the "Welcome" key in the "ChatMessages" section of "GiantSlayers.XXX" where XXX is replaced with the user's language's name (English is "INT")
	//ReceiveChatMessage("",Localize("ChatMessages", "ChatWelcomeOther", "GiantSlayers"),EFAC_ALL,false,false,,false);
	//Localization is broken at the moment...
	ReceiveChatMessage("","Welcome to Age of Giants",EFAC_ALL,false,false,,false);

	SetTimer(3.0f, false, 'ShowGiantSlayersHeader');
}

simulated function ShowGiantSlayersHeader()
{
	//ReceiveLocalizedHeaderText(Localize("ChatMessages", "Welcome", "GiantSlayers"),5.0f);
	//Localization is broken at the moment...
	ReceiveLocalizedHeaderText("Welcome to Age of Giants!",5.0f);
}

// Override so we can go into the grapple-happy state if necessary
function EnterStartState()
{
	local name NewState;

	if ( Pawn.PhysicsVolume.bWaterVolume )
	{
		if ( Pawn.HeadVolume.bWaterVolume )
		{
			Pawn.BreathTime = Pawn.UnderWaterTime;
		}
		NewState = Pawn.WaterMovementState;
	}
	else
	{
		if(AOGMobilePawn(Pawn) != none)
		{
			NewState = 'PlayerGrappling';
		}
		else
		{
			NewState = Pawn.LandMovementState;
		}
	}

	if (GetStateName() == NewState)
	{
		BeginState(NewState);
	}
	else
	{
		GotoState(NewState);
	}
}

// Player movement.
// Standard 'mobile' player movement, a combination of PlayerWalking and "something else"
state PlayerGrappling extends PlayerWalking
{
	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		super.ProcessMove(DeltaTime, NewAccel, DoubleClickMove, DeltaRot);
	}
}

defaultproperties
{
}