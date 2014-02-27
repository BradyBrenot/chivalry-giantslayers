/**
* A grapple attachment point (end point for the grappler)
*/

class AOGGrappleAttachment extends KActorSpawnable;

var AOGMobilePawn PawnOwner;

DefaultProperties
{
	bEdShouldSnap=TRUE
	bCollideActors=true
	bBlockActors=true
	bWorldGeometry=true
	bCollideWorld=false
	bStatic=false
	bRouteBeginPlayEvenIfStatic=true
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=true
	bScriptInitialized=false

	bNoDelete=false
	
	NetUpdateFrequency = 1.0f //it doesn't move or do much of anything!

	Begin Object Name=StaticMeshComponent0
		StaticMesh=StaticMesh'WP_shld_Pavise.SM_pavise_shield_a'
		Rotation=(Pitch=0,Yaw=16384,Roll=-16384)
		Scale=1.5f
		RBChannel=RBCC_NOTHING
		RBCollideWithChannels=(Pawn=FALSE,DeadPawn=FALSE)
		BlockActors=true
		BlockNonZeroExtent=true
		BlockZeroExtent=true
	End Object
	CollisionComponent=StaticMeshComponent0
	StaticMeshComponent=StaticMeshComponent0
	Components.add(StaticMeshComponent0)
}