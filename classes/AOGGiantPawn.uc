/**
* An enormous AOG Pawn supporting scale replication, "giant attacks", etc.
*/

class AOGGiantPawn extends AOCPawn;

var repnotify float GiantScale;
var CylinderComponent Bubble;

//PitchMultiplier = 1.0 for GiantScale = 1.0
//PitchMultiplier = MinPitchMultiplier for GiantScale = PitchMultiplierStartGiantScale
//PitchMultiplier = MaxPitchMultiplier for GiantScale = PitchMultiplierEndGiantScale
//scale linearly, two different slopes (before 1.0, and after 1.0)

var float MaxPitchMultiplier;
var float MinPitchMultiplier;
var float PitchMultiplierStartGiantScale;
var float PitchMultiplierEndGiantScale;
var float PitchMultiplier;

//At "small giant" size, collision cylinders stop colliding with actors
var float SmallGiantThreshold;

//At "major giant" size, giant attacks are enabled, arrows become ballista bolt, pebble shots become catapult shots, etc.
var float MajorGiantThreshold;

//If I'm this much bigger than someone else, crush them when I step on them
var float CrushDifferenceThreshold;

//You CANNOT parry attacks from people this much larger OR smaller than you
var float ParryImpossibilityThreshold;
//You CANNOT flinch people this much larger than you
var float FlinchImpossibilityThreshold;

var float GiantDamageScaleMultiplier;

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
	local float SafetyPushHeight;
	local float OldScale;
	
	OldScale = GiantScale;
	GiantScale = NewScale;
	
	//Taking a shortcut here by hardcoding the default scales/widths/heights of the components. Not good practice, but good enough for the tutorial.
	Mesh.SetScale(1.5 * GiantScale);
	OwnerMesh.SetScale(1.5 * GiantScale);
	
	//Push the pawn up a bit before rescaling to avoid clipping into the ground
	if(Role == ROLE_AUTHORITY || IsLocallyControlled())
	{
		SafetyPushHeight = FMax(0, GiantScale * 65 - GetCollisionHeight());
		SetLocation(Location + Vect(0,0,1)*SafetyPushHeight);
	}
	
	//Scale collision and enemy-collision ("bubble") cylinders
	CylinderComponent.SetCylinderSize(GiantScale * 36, GiantScale * 65);
	
	//Going to gradually scale down the bubble so it's totally uninvolved with large giants
	Bubble.SetCylinderSize(GiantScale * Max(36, 39 - 2 * Max(0, GiantScale - 1)), GiantScale * 65);
	
	if(Role == ROLE_AUTHORITY || IsLocallyControlled())
	{
		MoveSmooth(Vect(0,0,1) * SafetyPushHeight);
	}
	
	//Scale the voice pitch too!
	if(GiantScale < 1.0f)
	{
		PitchMultiplier = Lerp((GiantScale - PitchMultiplierStartGiantScale)/(1.0 - PitchMultiplierStartGiantScale), 1.0, MaxPitchMultiplier);
	}
	else
	{
		PitchMultiplier = Lerp((PitchMultiplierEndGiantScale - GiantScale)/(PitchMultiplierEndGiantScale - 1.0), 1.0, MinPitchMultiplier);
	}
	
	PitchMultiplier = FClamp(PitchMultiplier, MinPitchMultiplier, MaxPitchMultiplier);

	//VOSoundComp.PitchMultiplier = PitchMultiplier;
	FallingSoundComp.PitchMultiplier = PitchMultiplier;
	
	ForceUpdateComponents();
	
	if(NewScale >= SmallGiantThreshold && OldScale < SmallGiantThreshold)
	{
		ActivateSmallGiantMode();
	}
	
	if(NewScale >= MajorGiantThreshold && OldScale < MajorGiantThreshold)
	{
		ActiveMajorGiantMode();
	}
}

simulated function ActivateSmallGiantMode()
{
	CylinderComponent.SetActorCollision(true, false);
	Bubble.SetActorCollision(true, false);
	DisableWorldHit();
}

simulated function ActiveMajorGiantMode()
{

}

simulated function WeaponAttachmentChanged()
{
	super.WeaponAttachmentChanged();
	
	if(GiantScale >= SmallGiantThreshold)
	{
		DisableWorldHit();
	}
}

simulated function DisableWorldHit()
{
	local int i;
	for(i = 0; i < AOCWeaponAttachment(CurrentWeaponAttachment).AttackTypeInfo.Length; ++i)
	{
		AOCWeaponAttachment(CurrentWeaponAttachment).AttackTypeInfo[i].iWorldHitLenience=90000;
	}
}

simulated function TestScaleSoundA(float Scale)
{
	PitchMultiplier = Scale;
}

simulated function TestScaleSoundB(float Scale)
{
	//
}

/* ************************************************************************
 * Voice pitch scaling... not pretty
 **************************************************************************/
simulated function PlayZMenuVO(int index)
{
	local SoundCue voSound;

	if (WorldInfo.NetMode == NM_DedicatedServer)
		return;
		
	if (!VOSoundComp.IsPlaying() && Physics != PHYS_Falling && !bIsBurning)
	{	
		if (AOCCTFPlayerController(Controller) == none || index != 4)
		{
			class<AOCPawnSoundGroup>(SoundGroupClass).static.getAOCZMenuVO(self, index, voSound);
		}  
		else if (AOCCTFPlayerController(Controller) != none && index == 4)
		{
			class<AOCPawnSoundGroup>(SoundGroupClass).static.GetCTFDynVO(self, voSound);
		}


		voSound.PitchMultiplier = PitchMultiplier;
		VOSoundComp.SoundCue = voSound;
		VOSoundComp.Play();

		if (Role < ROLE_Authority || WorldInfo.NetMode == NM_STANDALONE)
		{
			s_PlayVO(voSound);
		}
	}
	else
	{
		PlaySound(GenericCantDoSound, true);
		AOCGame(WorldInfo.Game).LocalizedPrivateMessage(PlayerController(Controller), 12);
	}
}

simulated function PlayXMenuVO(int index)
{
	local SoundCue voSound;

	if (WorldInfo.NetMode == NM_DedicatedServer)
		return;
		
	if (!VOSoundComp.IsPlaying() && Physics != PHYS_Falling && !bIsBurning)
	{	
		class<AOCPawnSoundGroup>(SoundGroupClass).static.getAOCXMenuVO(self, index, voSound);
		
		voSound.PitchMultiplier = PitchMultiplier;
		VOSoundComp.SoundCue = voSound;
		VOSoundComp.Play();

		if (Role < ROLE_Authority || WorldInfo.NetMode == NM_STANDALONE)
		{
			s_PlayVO(voSound);
		}
	}
	else
	{
		PlaySound(GenericCantDoSound, true);
		AOCGame(WorldInfo.Game).LocalizedPrivateMessage(PlayerController(Controller), 12);
	}
}

reliable server function s_PlayVO(SoundCue voSound)
{
	voSound.PitchMultiplier = PitchMultiplier;
	
	if(voSound == PawnCharacter.default.MobileBattleCry)
	{
		OnActionSucceeded(EACT_Battlecry);
	}
	
	VOSoundComp.SoundCue = voSound;
	replicatedSoundToStop.soundToStop = VOSoundComp.SoundCue.Name;
	replicatedSoundToStop.soundOwnerNetTag = PlayerReplicationInfo.PlayerID;
	PlaySound(voSound, false, false, true);
}

simulated function PlayBattleCrySound()
{
	local SoundCue voSound;

	if (!bIsBurning && !VOSoundComp.IsPlaying())
	{
		if(PawnInfo.myFamily.default.FamilyFaction == EFAC_AGATHA)
		{
			voSound = class<AOCPawnSoundGroup>(SoundGroupClass).default.BattleCrySoundAgatha;
		}
		else
		{
			voSound = class<AOCPawnSoundGroup>(SoundGroupClass).default.BattleCrySoundMason;
		}

		voSound.PitchMultiplier = PitchMultiplier;
		VOSoundComp.SoundCue = voSound;
		VOSoundComp.Play();
		
		if (Role < ROLE_Authority || WorldInfo.NetMode == NM_STANDALONE)
			s_PlayVO(voSound);
	}
}

//Crush smaller pawns
singular event BaseChange()
{
	local AOCObjective_Pushable Pushable;
	local DynamicSMActor Dyn;
	local AOCStaticMeshActor_PaviseShield PaviseBase;
	
	//Check for unallowed pushables
	Pushable = AOCObjective_Pushable(Base);

	if (AOGMobilePawn(Base) != None 
		|| (AOGGiantPawn(Base) != None && AOGGiantPawn(Base).GiantScale <= GiantScale / CrushDifferenceThreshold))
	{
		Pawn(Base).CrushedBy(self);
	}
	else if(GiantScale >= SmallGiantThreshold && Pushable != None && !Pushable.bPawnCanBaseOn)
	{
		//Do nothing; giants are allowed to stand on pushables because it's A) Hilarous B) Maybe hard to avoid
		return;
	}
	else
	{
		//singular event, so we need to reproduce AOCPawn's functionality here
		// Pawns can only set base to non-pawns, or pawns which specifically allow it.
		// Otherwise we do some damage and jump off.
		if (Pawn(Base) != None && (DrivenVehicle == None || !DrivenVehicle.IsBasedOn(Base)))
		{
			if( !Pawn(Base).CanBeBaseForPawn(Self) )
			{
				Pawn(Base).CrushedBy(self);
				JumpOffPawn();
			}
		}

		// If it's a KActor, see if we can stand on it.
		Dyn = DynamicSMActor(Base);
		if( Dyn != None && !Dyn.CanBasePawn(self) )

		{
			JumpOffPawn();
		}
		
		//Check for unallowed pushables
		Pushable = AOCObjective_Pushable(Base);
		if( Pushable != None && !Pushable.bPawnCanBaseOn )
		{
			JumpOffPawn();
		}	
		
		PaviseBase = AOCStaticMeshActor_PaviseShield(Base);
		if(PaviseBase != none)
		{
			SetPhysics(PHYS_Falling);
			if(Role == ROLE_AUTHORITY)
			{
				PaviseBase.Collapse();	
			}	
		}
	}
}

function CrushedBy(Pawn OtherPawn)
{
	if(AOGGiantPawn(OtherPawn).GiantScale >= CrushDifferenceThreshold * GiantScale)
	{
		TakeDamage(900000, OtherPawn.Controller, Location, vect(0.0f, 0.0f, 0.0f), class'AOCDmgType_Fists');
	}
}

//Scale knockback and damage
event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo myHitInfo, optional Actor DamageCauser)
{
	local float GiantDamageScale;
	local AOGGiantPawn EnemyPawn;
	
	EnemyPawn = AOGGiantPawn(DamageCauser);
	if(EnemyPawn == none)
	{
		EnemyPawn = AOGGiantPawn(InstigatedBy.Pawn);
	}
	
	if(EnemyPawn != none)
	{
		GiantDamageScale = EnemyPawn.GiantScale / GiantScale;
		GiantDamageScale = (1 - GiantDamageScaleMultiplier) + GiantDamageScaleMultiplier*GiantDamageScale;
		Momentum *= GiantDamageScale;
		Damage *= GiantDamageScale;
	}
	
	AOCPlayerController(InstigatedBy).ClientDisplayConsoleMessage("GiantDamageScale"@GiantDamageScale);
	
	super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, myHitInfo, DamageCauser);
}

//-----------------------------------------------------------------------
//-----------------------------------------------------------------------
//----- Override AttackOtherPawn just so we can adjust flinch logic -----
//-----------------------------------------------------------------------
//-----------------------------------------------------------------------

/** Only called using a melee weapon. This is what happens when we go to attack another pawn.
 *  Happens on the server.
 */
reliable server function AttackOtherPawn(HitInfo Info, string DamageString, optional bool bCheckParryOnly = false, optional bool bBoxParrySuccess, optional bool bHitShield = false, optional SwingTypeImpactSound LastHit = ESWINGSOUND_Slash, optional bool bQuickKick = false)
{
	local bool bParry;
	local float ActualDamage;
	local bool bSameTeam;
	local bool bFlinch;
	local IAOCAIListener AIList;
	local int i;
	local float Resistance;
	local float GenericDamage;
	local float HitForceMag;
	local PlayerReplicationInfo PRI;
	local bool bOnFire;
	local bool bPassiveBlock;
	local AOCWeaponAttachment HitActorWeaponAttachment;
	local class<AOCWeapon> UsedWeapon;
	
	local bool bCannotFlinchDueToScale;

	if (PlayerReplicationInfo == none)
		PRI = Info.PRI;
	else
		PRI = PlayerReplicationInfo;

	if (!PerformAttackSSSC(Info) && WorldInfo.NetMode != NM_Standalone)
	{
		LogAlwaysInternal("SSSC Failure Notice By:"@PRI.PlayerName);
		LogAlwaysInternal( self@"performed an illegal move directed at"@Info.HitActor$".");
		LogAlwaysInternal("Attack Information:");
		LogAlwaysInternal("My Location:"@Location$"; Hit Location"@Info.HitLocation);
		LogAlwaysInternal("Attack Type:"@Info.AttackType@Info.DamageType);
		LogAlwaysInternal("Hit Damage:"@Info.HitDamage);
		LogAlwaysInternal("Hit Component:"@Info.HitComp);
		LogAlwaysInternal("Hit Bone:"@Info.BoneName);
		LogAlwaysInternal("Current Weapon State:"@Weapon.GetStateName());
		return;
	}

	if (Info.UsedWeapon == 0)
	{
		UsedWeapon = PrimaryWeapon;
	}
	else if (Info.UsedWeapon == 1)
	{
		UsedWeapon = SecondaryWeapon;
	}
	else
	{
		UsedWeapon = TertiaryWeapon;
	}

	HitActorWeaponAttachment = AOCWeaponAttachment(Info.HitActor.CurrentWeaponAttachment);

	bSameTeam = IsOnSameTeam(self, Info.HitActor);

	bParry = false;
	bFlinch = false;
	
	bCannotFlinchDueToScale = AOGMobilePawn(Info.HitActor) != none 
		|| AOGGiantPawn(Info.HitActor).GiantScale/GiantScale >= FlinchImpossibilityThreshold;

	//if(AOCPlayerController(Info.HitActor.Controller).bBoxParrySystem)
	//{
		bParry = bBoxParrySuccess && (Info.HitActor.StateVariables.bIsParrying || Info.HitActor.StateVariables.bIsActiveShielding) && class<AOCDmgType_Generic>(Info.DamageType) == none 
			&& Info.DamageType != class'AOCDmgType_SiegeWeapon';

		// Check if fists...fists can only blocks fists
		if (AOCWeapon_Fists(Info.HitActor.Weapon) != none && class<AOCDmgType_Fists>(Info.DamageType) == none)
			bParry = false;
		
		//@GS: cannot parry someone too small or too large
		if (AOGMobilePawn(Info.HitActor) != none
		 || AOGGiantPawn(Info.HitActor).GiantScale/GiantScale >= ParryImpossibilityThreshold || GiantScale / AOGGiantPawn(Info.HitActor).GiantScale >= ParryImpossibilityThreshold)
		{
			bParry = false;
		}

		if(bParry)
		{
			DetectSuccessfulParry(Info, i, bCheckParryOnly, 0);
		}
	//}
	//else
	//{
	//	// check if the other pawn is parrying or active shielding
	//	if (!Info.HitActor.bPlayedDeath && (Info.HitActor.StateVariables.bIsParrying || Info.HitActor.StateVariables.bIsActiveShielding) && class<AOCDmgType_Generic>(Info.DamageType) != none)
	//	{
	//		bParry = ParryDetectionBonusAngles(Info, bCheckParryOnly);
	//	}
	//}

	if (Info.DamageType.default.bIsProjectile)
		AOCPRI(PlayerReplicationInfo).NumHits += 1;
	
	bPassiveBlock = false;
	if ( bHitShield && Info.DamageType.default.bIsProjectile)
	{
		// Check for passive shield block
		bParry = true;
		Info.HitDamage = 0.0f;
		bPassiveBlock = !Info.HitActor.StateVariables.bIsActiveShielding;
	}

	if (bCheckParryOnly)
		return;
	LogAlwaysInternal("SUCCESSFUL ATTACK OTHER PAWN HERE");
	// Play hit sound
	AOCWeaponAttachment(CurrentWeaponAttachment).LastSwingType = LastHit;
	if(!bParry)
	{
		Info.HitActor.OnActionFailed(EACT_Block);
		Info.HitSound = AOCWeaponAttachment(CurrentWeaponAttachment).PlayHitPawnSound(Info.HitActor);
	}
	else        
		Info.HitSound = AOCWeaponAttachment(CurrentWeaponAttachment).PlayHitPawnSound(Info.HitActor, true);
	
	if (AOCMeleeWeapon(Info.Instigator.Weapon) != none)
	{
		AOCMeleeWeapon(Info.Instigator.Weapon).bHitPawn = true;
	}

	// Less damage for quick kick
	if (bQuickKick)
	{
		Info.HitDamage = 3;
	}

	ActualDamage = Info.HitDamage;
	GenericDamage = Info.HitDamage * Info.DamageType.default.DamageType[EDMG_Generic];
	ActualDamage -= GenericDamage; //Generic damage is unaffected by resistances etc.

	//Backstab damage for melee damage
	if (!CheckOtherPawnFacingMe(Info.HitActor) && !Info.DamageType.default.bIsProjectile)
		ActualDamage *= PawnFamily.default.fBackstabModifier;

	// Vanguard Aggression
	ActualDamage *= PawnFamily.default.fComboAggressionBonus ** Info.HitCombo;
	
	// make the other pawn take damage, the push back should be handled here too
	//Damage = HitDamage * LocationModifier * Resistances
	if (Info.UsedWeapon == 0 && AOCWeapon_Crossbow(Weapon) != none && Info.DamageType.default.bIsProjectile)
	{
		ActualDamage *= Info.HitActor.PawnFamily.default.CrossbowLocationModifiers[GetBoneLocation(Info.BoneName)];
	}
	else
	{
		ActualDamage *= (Info.DamageType.default.bIsProjectile ? Info.HitActor.PawnFamily.default.ProjectileLocationModifiers[GetBoneLocation(Info.BoneName)] : 
			Info.HitActor.PawnFamily.default.LocationModifiers[GetBoneLocation(Info.BoneName)]);
	}
		                                                           
	Resistance = 0;
	
	for( i = 0; i < ArrayCount(Info.DamageType.default.DamageType); i++)
	{
		Resistance += Info.DamageType.default.DamageType[i] * Info.HitActor.PawnFamily.default.DamageResistances[i];
	}
	
	ActualDamage *= Resistance;

	if (PawnFamily.default.FamilyFaction == Info.HitActor.PawnFamily.default.FamilyFaction)
		ActualDamage *= AOCGame(WorldInfo.Game).fTeamDamagePercent;
		
	ActualDamage += GenericDamage;
		
	//Damage calculations should be done now; round it to nearest whole number
	ActualDamage = float(Round(ActualDamage));

	LogAlwaysInternal("ATTACK OTHER PAWN"@ActualDamage);
	// Successful parry but stamina got too low!
	
	if(!bCannotFlinchDueToScale)
	{
		if (bParry && !bPassiveBlock && Info.HitActor.Stamina <= 0)
		{
			bFlinch = true;
			AOCWeapon(Info.HitActor.Weapon).ActivateFlinch(true, Info.HitActor.GetHitDirection(Location), true, true, AOCWeapon(Weapon).bTwoHander); 
		}
		// if the other pawn is currently attacking, we just conducted a counter-attack
		if (Info.AttackType == Attack_Shove && !bParry && !Info.HitActor.StateVariables.bIsSprintAttack)
		{
			// kick should activate flinch and take away 10 stamina
			if (!bSameTeam)
			{
				bFlinch = true;
				AOCWeapon(Info.HitActor.Weapon).ActivateFlinch(true, Info.HitActor.GetHitDirection(Location),true, Info.HitActor.StateVariables.bIsActiveShielding && !bQuickKick, false);
			}
			Info.HitActor.ConsumeStamina(10);
			if (Info.HitActor.StateVariables.bIsActiveShielding && Info.HitActor.Stamina <= 0)
			{
				Info.HitActor.ConsumeStamina(-30.f);
			}
		}
		else if (Info.AttackType == Attack_Sprint && !bSameTeam)
		{
			bFlinch = true;
			AOCWeapon(Info.HitActor.Weapon).ActivateFlinch(true, Info.HitActor.GetHitDirection(Location), true, false, AOCWeapon(Weapon).bTwoHander); // sprint attack should daze
		}
		else if ((Info.HitActor.StateVariables.bIsParrying || Info.HitActor.StateVariables.bIsActiveShielding) && !bSameTeam && !bParry)
		{
			bFlinch = true;
			AOCWeapon(Info.HitActor.Weapon).ActivateFlinch(true, Info.HitActor.GetHitDirection(Location), class<AOCDmgType_Generic>(Info.DamageType) != none
				, class<AOCDmgType_Generic>(Info.DamageType) != none, AOCWeapon(Weapon).bTwoHander);
		}
		else if ((ActualDamage >= 80.0f || Info.HitActor.StateVariables.bIsSprinting || Info.HitActor.Weapon.IsInState('Deflect') ||
			Info.HitActor.Weapon.IsInState('Feint') || (Info.HitActor.Weapon.IsInState('Windup') && AOCRangeWeapon(Info.HitActor.Weapon) == none) || Info.HitActor.Weapon.IsInState('Active') || Info.HitActor.Weapon.IsInState('Flinch')
			|| Info.HitActor.Weapon.IsInState('Transition') || Info.HitActor.StateVariables.bIsManualJumpDodge || (Info.HitActor.Weapon.IsInState('Recovery') && AOCWeapon(Info.HitActor.Weapon).GetFlinchAnimLength(true) >= WeaponAnimationTimeLeft()) ) 
			&& !bParry && !bSameTeam &&	!Info.HitActor.StateVariables.bIsSprintAttack)
		{
			AOCWeapon(Info.HitActor.Weapon).ActivateFlinch(true, Info.HitActor.GetHitDirection(Location), false, false, AOCWeapon(Weapon).bTwoHander);
		}
		else if (AOCWeapon_JavelinThrow(Info.HitActor.Weapon) != none && Info.HitActor.Weapon.IsInState('WeaponEquipping'))
		{
			AOCWeapon(Info.HitActor.Weapon).ActivateFlinch(true, Info.HitActor.GetHitDirection(Location), false, false, AOCWeapon(Weapon).bTwoHander);
		}
		else if (!bParry && !bSameTeam) // cause the other pawn to play the hit animation
		{
			AOCWeapon(Info.HitActor.Weapon).ActivateHitAnim(Info.HitActor.GetHitDirection(Location, false, true), bSameTeam);
		}
	}

	// GOD MODE - TODO: REMOVE
	if (Info.HitActor.bInfiniteHealth)
		ActualDamage = 0.0f;

	if (ActualDamage > 0.0f)
	{
		Info.HitActor.SetHitDebuff();
		LastAttackedBy = Info.Instigator;
		PauseHealthRegeneration();
		Info.HitActor.PauseHealthRegeneration();
		Info.HitActor.DisableSprint(true);	
		Info.HitActor.StartSprintRecovery();

		// play a PING sound if we hit a player when shooting
		if (Info.DamageType.default.bIsProjectile)
			PlayRangedHitSound();

		// Play sounds for everyone
		if (Info.HitActor.Health - ActualDamage > 0.0f)
			Info.HitActor.PlayHitSounds(ActualDamage, bFlinch);
		
		//PlayPitcherHitSound(ActualDamage, Info.HitActor.Location);
		if (AOCPlayerController(Controller) != none)
			AOCPlayerController(Controller).PC_SuccessfulHit();

		// Add to assist list if not in it already
		if (Info.HitActor.ContributingDamagers.Find(AOCPRI(PlayerReplicationInfo)) == INDEX_NONE && !bSameTeam)
			Info.HitActor.ContributingDamagers.AddItem(AOCPRI(PlayerReplicationInfo));

		Info.HitActor.LastPawnToHurtYou = Controller;

		//do not set the timer to clear the last pawn to attack value on a duel map...we want players to receive the kill even if the other player
		//  commits suicide by receiving falling damage or trap damage
		if( AOCDuel(WorldInfo.Game) == none || CDWDuel(WorldInfo.Game) == none )
			Info.HitActor.SetTimer(10.f, false, 'ClearLastPawnToAttack');

		if (Info.DamageType.default.bIsProjectile)
		{
			Info.HitActor.StruckByProjectile(self, UsedWeapon);
		}
	}

	
	// Notify Pawn that we hit
	if (AOCMeleeWeapon(Weapon) != none && Info.HitActor.Health - ActualDamage > 0.0f && Info.AttackType != Attack_Shove && Info.AttackType != Attack_Sprint && !bParry)
		AOCMeleeWeapon(Weapon).NotifyHitPawn();

	// pass attack info to be replicated to the clients
	Info.bParry = bParry;
	Info.DamageString = DamageString;
	if (Info.BoneName == 'b_Neck' && !Info.DamageType.default.bIsProjectile && Info.DamageType.default.bCanDecap && Info.AttackType != Attack_Stab)
		Info.DamageString $= "3";
	else if ((Info.BoneName == 'b_Neck' || Info.BoneName == 'b_Head') && Info.DamageType.default.bIsProjectile)
	{
		Info.DamageString $= "4";

		if ( AOCPlayerController(Controller) != none)
			AOCPlayerController(Controller).NotifyAchievementHeadshot();
	}
	else if ((Info.BoneName == 'b_spine_A' || Info.BoneName == 'b_spine_B' || Info.BoneName == 'b_spine_C' || Info.BoneName == 'b_spine_D') && Info.DamageType.default.bIsProjectile)
	{
		if ( AOCPlayerController(Controller) != none)
			AOCPlayerController(Controller).NotifyCupidProgress();
	}
	Info.HitActor.ReplicatedHitInfo = Info;
	Info.HitDamage = ActualDamage;

	Info.HitForce *= int(PawnState != ESTATE_PUSH && PawnState != ESTATE_BATTERING);
	//LogAlwaysInternal("DAMAGE FORCE:"@Info.HitForce);
	Info.HitForce *= int(!bFlinch);
	HitForceMag = VSize( Info.HitForce );
	Info.HitForce.Z = 0.f;
	Info.HitForce = Normal(Info.HitForce) * HitForceMag;

	// Stat Tracking For Damage
	// TODO: Also sort by weapon
	if (PRI != none)
	{
		if (!bSameTeam)
		{
			AOCPRI(PRI).EnemyDamageDealt += ActualDamage;
		}
		else
		{
			if (Info.HitActor.PawnInfo.myFamily.default.ClassReference != ECLASS_Peasant)
			{
				AOCPRI(PRI).TeamDamageDealt += ActualDamage;
				AOCPlayerController(Controller).TeamDamageDealt += ActualDamage;
			}
		}
		
		AOCPRI(PRI).bForceNetUpdate = TRUE;
	}

	if (Info.HitActor.PlayerReplicationInfo != none)
	{
		AOCPRI(Info.HitActor.PlayerReplicationInfo).DamageTaken += ActualDamage;
		AOCPRI(Info.HitActor.PlayerReplicationInfo).bForceNetUpdate = TRUE;
	}

	LogAlwaysInternal("ATTACK OTHER PAWN"@Controller@CurrentSiegeWeapon.Controller);
	bOnFire = Info.HitActor.bIsBurning;
	
	Info.HitActor.TakeDamage(ActualDamage, Controller != none ? Controller : CurrentSiegeWeapon.Controller, Info.HitLocation, Info.HitForce, Info.DamageType);

	if ((Info.HitActor == none || Info.HitActor.Health <= 0) && WorldInfo.NetMode == NM_DedicatedServer)
	{
		// Make sure this wasn't a team kill
		if (AOCPlayerController(Controller).StatWrapper != none
			&& !bSameTeam
			&& Info.UsedWeapon < 2)
		{
			AOCPlayerController(Controller).StatWrapper.IncrementKillStats(
				Info.UsedWeapon == 0 ? PrimaryWeapon : SecondaryWeapon, 
				PawnFamily,
				Info.HitActor.PawnFamily,
				class<AOCWeapon>(HitActorWeaponAttachment.WeaponClass)
			);
		}

		// Do another check for a headshot here
		if (Info.BoneName == 'b_Neck' && !Info.DamageType.default.bIsProjectile && Info.DamageType.default.bCanDecap && Info.AttackType != Attack_Stab)
		{
			// Award rotiserie chef achievement on client
			if (AOCPlayerController(Controller) != none && bOnFire)
			{
				AOCPlayerController(Controller).UnlockRotisserieChef();
			}

			// Notify decap
			AOCPlayerController(Controller).NotifyAchievementDecap();
		}

		// Check if fists
		if (class<AOCDmgType_Fists>(Info.DamageType) != none)
		{
			if (AOCPlayerController(Controller) != none)
			{
				AOCPlayerController(Controller).NotifyFistofFuryProgress();
			}
		}

		Info.HitActor.ReplicatedHitInfo.bWasKilled = true;
	}

	foreach AICombatInterests(AIList)
	{
		AIList.NotifyPawnPerformSuccessfulAttack(self);
	}
	
	foreach Info.HitActor.AICombatInterests(AIList)
	{
		if (!bParry)
			AIList.NotifyPawnReceiveHit(Info.HitActor,self);
		else
			AIList.NotifyPawnSuccessBlock(Info.HitActor, self);
	}

	// manually do the replication if we're on the standalone
	if (WorldInfo.NetMode == NM_Standalone)
	{
		Info.HitActor.HandlePawnGetHit();
	}
}






defaultproperties
{
	//start out mini!
	GiantScale = 0.6
	Bubble = OuterCylinder
	
	MaxPitchMultiplier = 1.5;
	MinPitchMultiplier = 0.4;
	PitchMultiplierStartGiantScale = 0.6;
	PitchMultiplierEndGiantScale = 10;
	PitchMultiplier = 1.0;
	
	WaterMovementState=PlayerWalking
	
	SmallGiantThreshold=1.4
	MajorGiantThreshold=2.0
	
	CrushDifferenceThreshold = 3.0
	
	//You CANNOT parry attacks from people this much larger OR smaller than you
	ParryImpossibilityThreshold = 3.0
	
	//You CANNOT flinch people this much larger than you
	FlinchImpossibilityThreshold = 3.0
	
	GiantDamageScaleMultiplier = 0.5
}