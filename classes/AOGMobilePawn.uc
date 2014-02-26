/**
* An AOG pawn with high mobility, suitable for killing AOGGiantPawns
*/

class AOGMobilePawn extends AOCPawn;

simulated function TakeFallingDamage()
{
	//NO!
}

simulated event Landed(vector HitNormal, actor FloorActor)
{
	super.Landed(HitNormal, FloorActor);
}

defaultproperties
{
}