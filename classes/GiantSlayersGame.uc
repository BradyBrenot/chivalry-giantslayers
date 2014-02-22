class GiantSlayersGame extends AOCFFA;

var float ScaleFactorPerKill;
 
static event class<GameInfo> SetGameType(string MapName, string Options, string Portal)
{
	//returns this object's own class, so this class is setting itself to be the game type used
	return default.class;
}

function ScoreKill(Controller Killer, Controller Other)
{
	local GiantSlayersPawn GSP;
	
	super.ScoreKill(Killer, Other);
	
	GSP = GiantSlayersPawn(Killer.Pawn);
	
	if(GSP != none)
	{
		GSP.SetGiantScale(GSP.GiantScale * ScaleFactorPerKill);
	}
}

defaultproperties
{
	//This is the name that shows in the server browser for this mod:
	ModDisplayString="Giant Slayers"
	
	//We won't leave these in here, but for now they'll let us see if the mod is actually loaded...
	SpawnWaveInterval=1
	MinimumRespawnTime=0
	
	//Use our new, custom pawn class
	DefaultPawnClass=class'GiantSlayersPawn'
	
	//Scale up 15% for every kill
	ScaleFactorPerKill = 1.15
}
