/**
* The generic AOG Player Controller
*
* The primary 'problem' with AOG is going to be the asymmetric gameplay.
* I'm going to need one PC to cover both 'giant' and 'mobile' gameplay.
* That's this class right here.
* At least I can keep things in separate states.
*/

class AOGPlayerController extends AOCPlayerController
	dependson(AOGMobilePawn);

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
		//if(Pawn.Physics == PHYS_Falling && !AOGMobilePawn(Pawn).bLanded)
		//{
		//	Pawn.SetPhysics(PHYS_Custom);
		//}
		super.ProcessMove(DeltaTime, NewAccel, DoubleClickMove, DeltaRot);
	}
}

simulated function rotator CalcAim()
{
	local Vector RealStartLoc;
	local rotator Aim;

	AOCPawn(Pawn).OwnerMesh.GetSocketWorldLocationAndRotation(AOCPawn(Pawn).CameraSocket, RealStartLoc, Aim);

	if (!AOCPawn(Pawn).IsFirstPerson())
	{
		Aim = CalcThirdPersonAim(RealStartLoc, Aim);
	}

	return Aim;
}

simulated function rotator CalcThirdPersonAim(vector RealStartLoc, rotator Aim)
{
	local Vector CameraLoc;
	local Rotator CameraAim;
	local float CameraFOV;
	local Vector TargetLoc;
	local Vector HitLoc;
	local Vector HitNormal;

	// ray trace along the camera sight to find target location
	AOCPawn(Pawn).CalcThirdPersonCam(1.0f, CameraLoc, CameraAim, CameraFOV);

	CameraLoc = CameraLoc + (Vect(1,0,0) >> CameraAim) * 130.0f;
	TargetLoc = CameraLoc + (Vect(1,0,0) >> CameraAim) * 10000.0f;

	if( Trace(HitLoc, HitNormal, TargetLoc, CameraLoc, true) != None )
	{
		// Adjust slightly for close objects
		if (VSize(HitLoc - RealStartLoc) < 200.0f)
		{
			HitLoc = HitLoc + Normal(HitLoc - CameraLoc) * 50.0f;
		}

		TargetLoc = HitLoc;
	}

	return Rotator(TargetLoc - RealStartLoc);
}

//Input overrides that only make sense with default, QWERTY inputs! YAY!
exec function PerformFeint(optional bool bMeleeOnly = false)
{
	FireGrapplerForwardOrRelease(GRAPPLER_LEFT);
}

exec function Use()
{
	FireGrapplerForwardOrRelease(GRAPPLER_RIGHT);
}

simulated function FireGrapplerForwardOrRelease(EGrapplers Grappler)
{
	if(AOGMobilePawn(Pawn).IsGrapplerActive(Grappler))
	{
		AOGMobilePawn(Pawn).ReleaseGrappler(Grappler);
	}
	else
	{
		FireGrapplerForward(Grappler);
	}
}

simulated function FireGrapplerForward(EGrapplers Grappler)
{
	AOGMobilePawn(Pawn).FireGrappler(Grappler, CalcAim());
}

exec function DoParry()
{
	AOGMobilePawn(Pawn).StartReeling(GRAPPLER_LEFT);
	AOGMobilePawn(Pawn).StartReeling(GRAPPLER_RIGHT);
	ClientDisplayConsoleMessage("REELING");
}

exec function LowerShield()
{
	AOGMobilePawn(Pawn).StopReeling(GRAPPLER_LEFT);
	AOGMobilePawn(Pawn).StopReeling(GRAPPLER_RIGHT);
	ClientDisplayConsoleMessage("STOP REELING");
}

//We might still want "Use", but we definitely don't need "Shove" for anything, so substitute
exec function DoShove()
{
	Super.Use();
}

exec function StopShove()
{
	Super.EndUseAction();
}

exec function AOG_SetOR(float set)
{
	AOGMobilePawn(Pawn).fMaxOverReel = set;
}
exec function AOG_SetGR(float set)
{
	AOGMobilePawn(Pawn).fElasticityCoeffecient = set;
}
exec function AOG_SetRPS(float set)
{
	AOGMobilePawn(Pawn).fReelPerSecond = set;
}

defaultproperties
{
}