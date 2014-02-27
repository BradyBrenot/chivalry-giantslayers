/**
* A grapple projectile, which tells its parent when it's hit something
*/

class AOGGrappleProj extends UTProjectile;

var AOGMobilePawn PawnOwner;
/** StaticMesh */
var StaticMeshComponent Mesh;

simulated function Explode(vector HitLocation, vector HitNormal)
{
	LogAlwaysInternal("ProcessTouch");
	SpawnExplosionEffects(HitLocation, HitNormal);
	PawnOwner.OnGrappleProjAttached(self);
	super.Explode(HitLocation, HitNormal);
}

simulated function Destroyed()
{
	PawnOwner.OnGrappleProjDestroyed(self);
	super.Destroyed();
}

defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
		bCastDynamicShadow=false
		CastShadow=false
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		MaxDrawDistance=4000
		bUseAsOccluder=FALSE
		bAcceptsDynamicDecals=FALSE
		CollideActors=false
		BlockActors=false
		AlwaysCheckCollision=false
		StaticMesh=StaticMesh'WP_DL1_sling.Stone'
		Scale=1.0
	End Object
	Mesh=StaticMeshComponent0
	Components.add(StaticMeshComponent0)
}