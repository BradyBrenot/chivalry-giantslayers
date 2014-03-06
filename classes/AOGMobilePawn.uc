/**
* An AOG pawn with high mobility, suitable for killing AOGGiantPawns
*/

class AOGMobilePawn extends AOCPawn;

var vector HitWallHitNormal;
var actor HitWallActor;
var bool bLanded;
var bool TestA;
var bool TestB;
var float fElasticityCoeffecient;
var float fDragCoeffecient;

enum EGrapplers
{
	GRAPPLER_LEFT,
	GRAPPLER_RIGHT
};

var Actor GrapplePoints[EGrapplers];
var float GrappleRopeLength[EGrapplers];
var byte bGrappleReeling[EGrapplers];
var float fReelPerSecond;
var float fMaxOverReel;
var float fReelVelocityBoost;
var float fReelMaxVelocity;
var float fBreakingVelocity;

simulated function TakeFallingDamage()
{
	//NO!
}

simulated event Landed(vector HitNormal, actor FloorActor)
{
	super.Landed(HitNormal, FloorActor);
	SetPhysics(PHYS_Walking);
	bLanded = false;
}

event HitWall( vector HitNormal, actor Wall, PrimitiveComponent WallComp )
{
	super.HitWall(HitNormal, Wall, WallComp);
	HitWallHitNormal = HitNormal;
	HitWallActor= Wall;
}

//PHYS_Custom for a Mobile Pawn -> "Grappling" physics
// this is going to start as little more than PHYS_Falling implemented from script land... then, just wait
simulated event PerformCustomPhysics(FLOAT deltaTime, INT Iterations)
{
	local float TickAirControl;
	local Vector TestWalk;
	local Vector ColLocation;

	local float remainingTime;
	local float timeTick;
	local Vector OldLocation;
	local vector OldVelocity;

	local TraceHitInfo Hit;
	local Actor HitActor;
	local Vector HitLocation, HitNormal;

	local Actor FloorActor;
	local Vector FloorHitLocation, FloorHitNormal;

	local Vector ReelAccel;
	local Vector InputVelocity;

	local Vector TangentialVelocity;
	local Vector NonTangentialVelocity;
	
	local Vector GAcc;

	//local Vector CentripedalAcc;

	local int i;

	Acceleration.Z = 0;

	remainingTime = deltaTime;
	timeTick = 0.1;
	OldLocation = Location;

	while( (remainingTime > 0) && (Iterations < 8) )
	{
		Iterations++;

		if( remainingTime > 0.05 )
		{
			timeTick = FMin(0.05, remainingTime * 0.5);
		}
		else 
		{
			timeTick = remainingTime;
		}

		ReelAccel = Vect(0,0,0);

		remainingTime -= timeTick;
		OldLocation = Location;

		OldVelocity = Velocity;

		GAcc = Vect(0,0,1)*GetGravityZ();

		//Question #1: Am I walking? If so, maybe do some jazz for that
		FloorActor = Trace(FloorHitLocation, FloorHitNormal, Location + Vect(0,0,-1)*MaxStepHeight, Location, true, Vect(0,0,1) * GetCollisionHeight() + Vect(1,1,0)*2*GetCollisionRadius(), Hit);

		if(FloorActor != none && FloorHitNormal.Z >= WalkableFloorZ && VSize(OldVelocity) <= GroundSpeed)
		{
			//We're on walkable ground! FRICTION and WALKING come into play now...
			InputVelocity = Normal(Acceleration - Acceleration*(Acceleration dot FloorHitNormal)) * AccelRate * timeTick;
			if(VSize(OldVelocity + InputVelocity) < GroundSpeed)
			{
				OldVelocity = InputVelocity + OldVelocity;
			}
			else
			{
				OldVelocity = GroundSpeed * Normal(Acceleration);
			}

			//First figure out walking; we'll do out the rest later

			//NonTangentialVelocity = FloorHitNormal * (Velocity dot FloorHitNormal);
			//TangentialVelocity = Velocity - NonTangentialVelocity;	
		}
		else //air control
		{
			OldVelocity = OldVelocity + Acceleration * timeTick;
		}

		//Reeling
		for(i = 0; i < GRAPPLER_MAX; ++i)
		{
			if(AOGGrappleAttachment(GrapplePoints[i]) != none && bool(bGrappleReeling[i]))
			{
				DrawDebugLine(Location + 10 * fReelVelocityBoost*Normal(AOGGrappleAttachment(GrapplePoints[i]).Location - Location) , Location, 255, 2, 255, false);

				if((Velocity dot Normal(AOGGrappleAttachment(GrapplePoints[i]).Location - Location)) < fReelMaxVelocity)
				{
					ReelAccel += fReelVelocityBoost*Normal(AOGGrappleAttachment(GrapplePoints[i]).Location - Location);
				}
				
				GAcc = Vect(0,0,0);
			}
		}

		Velocity = OldVelocity + (ReelAccel + GAcc) * timeTick;	
		Velocity -= fDragCoeffecient * VSizeSq(Velocity) * timeTick * Normal(Velocity);

		for(i = 0; i < GRAPPLER_MAX; ++i)
		{
			if(AOGGrappleAttachment(GrapplePoints[i]) != none && VSize(AOGGrappleAttachment(GrapplePoints[i]).Location - Location) >= GrappleRopeLength[i] - 30)
			{
				//CENTRIPEDE
				NonTangentialVelocity = Normal(AOGGrappleAttachment(GrapplePoints[i]).Location - Location) * (Velocity dot Normal(AOGGrappleAttachment(GrapplePoints[i]).Location - Location));
				TangentialVelocity = Velocity - NonTangentialVelocity;	

				if(VSize(AOGGrappleAttachment(GrapplePoints[i]).Location - Location) >= GrappleRopeLength[i])
				{
					//cancel (@TODO - a portion of?) non-tangential velocity iff it's going _away_ from grapple point; going towards is fine
					//also, this is a kind of stupid way of calculating this isn't it?

					if( VSize(AOGGrappleAttachment(GrapplePoints[i]).Location - Location) < VSize(AOGGrappleAttachment(GrapplePoints[i]).Location - (Location + NonTangentialVelocity*timeTick)))
					{
						if(VSize(NonTangentialVelocity) < fBreakingVelocity)
						{
							Velocity = TangentialVelocity;
						}
						else
						{
							AOGPlayerController(Controller).ClientDisplayConsoleMessage("Broken: VSize(NonTangentialVelocity)"@VSize(NonTangentialVelocity));
							AOGGrappleAttachment(GrapplePoints[i]).Destroy();
							GrapplePoints[i] = none;
							continue;
						}
					}

					//1: Centripedal Force on the movement tangential to the sphere
					Velocity += timeTick * Normal(AOGGrappleAttachment(GrapplePoints[i]).Location - Location) * VSize(((TangentialVelocity * TangentialVelocity) / VSize(AOGGrappleAttachment(GrapplePoints[i]).Location - Location)));

					//Improve?: take NonTangentialVelocity; figure out if any of it would make us move past the rope's length. If so, cap out that amount? I don't know.
				}
			}
		}

		//Springyness of the rope
		for(i = 0; i < GRAPPLER_MAX; ++i)
		{
			if(AOGGrappleAttachment(GrapplePoints[i]) != none && VSize(AOGGrappleAttachment(GrapplePoints[i]).Location - Location) > GrappleRopeLength[i])
			{
				Velocity += timeTick * Normal(AOGGrappleAttachment(GrapplePoints[i]).Location - Location) * fElasticityCoeffecient * ( VSize(AOGGrappleAttachment(GrapplePoints[i]).Location - Location) - GrappleRopeLength[i]);
			}
		}

		HitWallActor = Trace(HitLocation, HitNormal, Location + Velocity*TimeTick, Location, true, Vect(0,0,1) * GetCollisionHeight() + Vect(1,1,0)*2*GetCollisionRadius(), Hit);
		HitWallHitNormal = HitNormal;

		if(HitWallActor != none)
		{
			//We hit...... something
			//Velocity = Velocity - HitNormal * (Velocity dot HitNormal);	
		}

		MoveSmooth(Velocity * TimeTick);

		if(FloorActor != none && VSize(Location - OldLocation)/TimeTick < VSize(OldLocation * Velocity * TimeTick - OldLocation)/1.1)
		{
			//we definitely didn't make it
			//let's try to 'cheat' by trying to 'step over' whatever is in front of us
			//note: this approach only _kind of_ works

			//to do this: move back to original location
			SetLocation(OldLocation);

			//move up by StepHeight
			Move(Vect(0,0,1) * MaxStepHeight);

			//try moving again
			Move(Velocity * TimeTick);

			//To the floor!
			MoveSmooth(Vect(0,0,-1) * MaxStepHeight);

			//FloorActor = Trace(FloorHitLocation, FloorHitNormal, Location + Vect(0,0,-1)*MaxStepHeight, Location, true, Vect(0,0,1) * GetCollisionHeight() + Vect(1,1,0)*2*GetCollisionRadius(), Hit);
			//if(FloorActor == none || FloorHitNormal.Z < WalkableFloorZ)
			//{
			//	//BAD
			//	SetLocation(OldLocation);
			//	MoveSmooth(Velocity * TimeTick);
			//}
		}

		for(i = 0; i < GRAPPLER_MAX; ++i)
		{
			if(AOGGrappleAttachment(GrapplePoints[i]) != none && bool(bGrappleReeling[i]))
			{
				GrappleRopeLength[i] = FMin(GrappleRopeLength[i],VSize(AOGGrappleAttachment(GrapplePoints[i]).Location - Location));
			}
		}



		if(VSize(HitWallHitNormal) != 0)
		{


			//landed on walkable ground
			if (HitWallHitNormal.Z >= WalkableFloorZ)
			{ 
				bLanded = true;
				//SetPhysics(PHYS_Falling);
				//return;
			}
		}

		//correct velocity, e.g. when level geometry affected the fall
		Velocity = (Location - OldLocation)/timeTick; //actual average velocity

		if( VSizeSq(Velocity) > Square(GetTerminalVelocity()))
		{
			Velocity = Normal(Velocity);
			Velocity *= GetTerminalVelocity();
		}
	}
}

function bool DoJump( bool bUpdating )
{
	local TraceHitInfo Hit;
	local Actor FloorActor;
	local Vector FloorHitLocation, FloorHitNormal;

	local Vector JumpV;

	if (StateVariables.bCanJump)
	{
		if(bJumpCapable && !bIsCrouching && !(StateVariables.bIsAttacking && AOCWeapon(Weapon).CurrentFireMode == Attack_Shove) && PawnState != ESTATE_FROZEN)
		{
			FloorActor = Trace(FloorHitLocation, FloorHitNormal, Location + Vect(0,0,-1)*MaxStepHeight, Location, true, Vect(0,0,1) * GetCollisionHeight() + Vect(1,1,0)*2*GetCollisionRadius(), Hit);
			
			if ( FloorActor != none )
				JumpV += Default.JumpZ * FloorHitNormal;
			else
				return false;

			if (Base != None && !Base.bWorldGeometry && Base.Velocity.Z > 0.f)
			{
				JumpV += Normal(JumpV) * (Normal(JumpV) dot Base.Velocity);
			}

			ConsumeStamina(7);
			Velocity += JumpV;

			// update state
			StateVariables.bIsManualJumpDodge = true;
			StateVariables.bCanCrouch = false;

			return true;
		}
	}

	return false;
}

function bool PerformLunge(vector Dir, vector Cross, bool bManualFlag, bool bCombo)
{
	return true;
}

simulated function AOCSetCharacterClassFromInfo(class<AOCFamilyInfo> Info)
{
	super.AOCSetCharacterClassFromInfo(Info);
	JumpZ = 800;
}

function FireGrappler(EGrapplers Grappler, Rotator FireRot)
{
	local AOGGrappleProj SpawnedProjectile;
	local Vector RealStartLoc;
	local rotator RealRot;

	OwnerMesh.GetSocketWorldLocationAndRotation(CameraSocket, RealStartLoc, RealRot);

	if(IsGrapplerActive(Grappler))
	{
		ReleaseGrappler(Grappler);
	}

	SpawnedProjectile = Spawn(class'AOGGrappleProj',,, RealStartLoc, FireRot);
	if ( SpawnedProjectile != None )
	{
		SpawnedProjectile.Init(Vector(FireRot));
		GrapplePoints[Grappler] = SpawnedProjectile;
		SpawnedProjectile.PawnOwner = self;
	}
}

function bool IsGrapplerActive(EGrapplers Grappler)
{
	return GrapplePoints[Grappler] != none;
}

function ReleaseGrappler(EGrapplers Grappler)
{
	GrapplePoints[Grappler].Destroy();
	GrapplePoints[Grappler] = none;
}

function StartReeling(EGrapplers Grappler)
{
	bGrappleReeling[Grappler] = byte(true);
}

function StopReeling(EGrapplers Grappler)
{
	bGrappleReeling[Grappler] = byte(false);
}

function OnGrappleProjAttached(AOGGrappleProj GrappleProj)
{
	local AOGGrappleAttachment SpawnedAttachment;
	local int i;
	local EGrapplers FoundGrappler;

	FoundGrappler = GRAPPLER_MAX;

	LogAlwaysInternal("Not yet found grappler:"@FoundGrappler);

	for(i = 0; i < GRAPPLER_MAX; ++i)
	{
		if(GrapplePoints[i] == GrappleProj)
		{
			FoundGrappler = EGrapplers(i);
			break;
		}
	}

	LogAlwaysInternal("Found grappler:"@FoundGrappler);

	if(FoundGrappler != GRAPPLER_MAX)
	{
		SpawnedAttachment = Spawn(class'AOGGrappleAttachment',,, GrappleProj.Location, GrappleProj.Rotation);
		LogAlwaysInternal("Spawned grappler:"@SpawnedAttachment@GrappleProj.Location);
		GrapplePoints[FoundGrappler] = SpawnedAttachment;
		GrappleRopeLength[FoundGrappler] = VSize(Location - SpawnedAttachment.Location);
	}
}

function OnGrappleProjDestroyed(AOGGrappleProj GrappleProj)
{

}

defaultproperties
{
	fElasticityCoeffecient=1.5
	fReelPerSecond=400
	fMaxOverReel=10
	fReelVelocityBoost=600
	fReelMaxVelocity=8800
	fDragCoeffecient=0.0003
	fBreakingVelocity=6000
}