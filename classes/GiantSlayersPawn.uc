class GiantSlayersPawn extends AOCPawn;

var repnotify float GiantScale;
var CylinderComponent Bubble;

replication
{
	if ( bNetDirty )
		GiantScale;
}

/** Do something when a repnotify variable is replicated. */
simulated event ReplicatedEvent(name VarName)
{
	super.ReplicatedEvent(VarName);
	if (VarName == 'GiantScale')
	{
		SetGiantScale(GiantScale);
	}
}

simulated function SetCharacterAppearanceFromInfo(class<AOCCharacterInfo> Info)
{
	Super.SetCharacterAppearanceFromInfo(Info);
	SetGiantScale(GiantScale);
}

simulated function SetGiantScale(float NewScale)
{
	if(Role == ROLE_Authority)
	{
		//This code is only executed on the server
		Health *= (NewScale / GiantScale);
		HealthMax *= (NewScale / GiantScale);
	}

	GiantScale = NewScale;
	
	//Taking a shortcut here by hardcoding the default scales/widths/heights of the components. Not good practice, but good enough for the tutorial.
	Mesh.SetScale(1.5 * GiantScale);
	OwnerMesh.SetScale(1.5 * GiantScale);
	Bubble.SetCylinderSize(NewScale * 39, NewScale * 65);
	CylinderComponent.SetCylinderSize(NewScale * 36, NewScale * 65);
	
	ForceUpdateComponents();
}

defaultproperties
{
	//start out mini!
	GiantScale = 0.6
	Bubble = OuterCylinder
}