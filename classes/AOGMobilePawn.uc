/**
* An AOG pawn with high mobility, suitable for killing AOGGiantPawns
*/

class AOGMobilePawn extends AOCPawn;

var vector HitWallHitNormal;
var actor HitWallActor;
var bool bLanded;
var bool TestA;
var bool TestB;

enum EGrapplers
{
	GRAPPLER_LEFT,
	GRAPPLER_RIGHT
};

var Actor GrapplePoints[EGrapplers];
var float GrappleRopeLength[EGrapplers];

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

	local int i;

	// test for slope to avoid using air control to climb walls
	TickAirControl = AirControl;
	Acceleration.Z = 0;
	if( TickAirControl > 0.05 )
	{
		TestWalk = ( TickAirControl * AccelRate * Normal(Acceleration) + Velocity ) * deltaTime;
		TestWalk.Z = 0;
		if(VSize(TestWalk) != 0)
		{
			ColLocation = Location + CollisionComponent.Translation;
			HitActor = Trace(HitLocation, HitNormal, ColLocation + TestWalk, ColLocation, false,,Hit);

			if( HitActor != none )
			{
				TickAirControl = 0;
			}
		}
	}

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

		//k * (d - pd)
		for(i = 0; i < GRAPPLER_MAX; ++i)
		{
			if(AOGGrappleAttachment(GrapplePoints[i]) != none && VSize(AOGGrappleAttachment(GrapplePoints[i]).Location - Location) > GrappleRopeLength[i])
			{
				Acceleration += Normal(AOGGrappleAttachment(GrapplePoints[i]).Location - Location) * 200 * ( VSize(AOGGrappleAttachment(GrapplePoints[i]).Location - Location) - GrappleRopeLength[i]);
			}
		}

		remainingTime -= timeTick;
		OldLocation = Location;

		OldVelocity = Velocity;
		Velocity = OldVelocity + (Acceleration + Vect(0,0,1)*GetGravityZ()) * timeTick;

		HitWallActor = none;

		MoveSmooth(Velocity * TimeTick);

		//event HitWall may be called while in MoveSmooth if we hit something
		if(HitWallActor != none)
		{
			//landed on walkable ground
			if (HitWallHitNormal.Z >= WalkableFloorZ)
			{ 
				bLanded = true;
				SetPhysics(PHYS_Falling);
				return;
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
	if(super.DoJump(bUpdating))
	{
		SetPhysics(PHYS_Custom);
		return true;
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
}