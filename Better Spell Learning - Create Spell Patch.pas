{
  Creates a patch plugin that makes spell mods compatible with Better Spell Learning.

  This script is load-order dependent, so any edits to spells will be included in the patch.

  Apply to either a specific mod, so only spell tomes from that mod will be processed,
  or to your whole load order to create a patch file for all spells that exist.

  The description of patched spell tomes will likely contain placeholders like <dur> and <mag>,
  which you may want to remove yourself while editing the description to still make sense.
}
Unit UrbanCMCCreateBSLPatch;

Uses 'UrbanCMC/Utility Functions', 'UrbanCMC/Script Property Helper';

Const
  // Text to add as content to each spell book that is converted
  sBookDescription = '</font> [pagebreak] <p align="left"><font size="20">[The tome contains countless diagrams and magical runes. Study them and learn how to cast this spell yourself.]</font>';

  sBetterSpellLearning = 'Better Spell Learning.esp';
  sBetterSpellLearningScript = 'SpellTomeReadScript';

Var
  BuildForLoadOrder: Boolean;
  BslPlugin, PatchPlugin: IInterface;
  PatchedTomeCount, VMADSourceSpellTomeID: Integer;

// Called before processing
Function Initialize: Integer;
Var
  i: Integer;
  plugin: IInterface;

Begin
  // Change BfLO to use winning override records
  BuildForLoadOrder := True;
  PatchedTomeCount := 0;

  // Ensure the BSL plugin is available
  For i := 0 To pred(FileCount) Do
  Begin
    plugin := FileByIndex(i);
    If SameText(GetFileName(plugin), sBetterSpellLearning) Then
    Begin
      BslPlugin := plugin;
    End;
  End;

  If Not Assigned(BslPlugin) Then
  Begin
    MessageDlg(Format('Unable to find %s.', [sBetterSpellLearning]), mtConfirmation, [mbOk], 0);
    Result := 1;
    Exit;
  End;

  PatchPlugin := AddNewFile();

  // Add all enabled plugins as master to be safe when referencing spells, etc. (Skip last plugin, which is the one we just created)
  For i := 0 To pred(FileCount - 1) Do
  Begin
    plugin := FileByIndex(i);
    AddMasterIfMissing(PatchPlugin, GetFileName(plugin));
  End;

  // Get ID of a spell tome with the required script/properties we can copy from
  VMADSourceSpellTomeID := FileFormIDToLoadOrderFormID(BslPlugin, '0009CD51');

  Add(PatchPlugin, 'BOOK', True);
End;

// called for every record selected in xEdit
Function Process(e: IInterface): Integer;
Var
  spellReference: IInterface;
  i: Integer;

Begin
  If Signature(e) <> 'BOOK' Then Exit;

  If (Not IsWinningOverride(e)) And (BuildForLoadOrder) Then e := WinningOverride(e);
  If Not IsConvertableSpellTome(e) Then Exit;

  // Copy override of target tome into patch plugin
  e := wbCopyElementToFile(e, PatchPlugin, False, True);

  CopyVMADRecord(e, BslPlugin, VMADSourceSpellTomeID);
  spellReference := ModifySpellTomeData(e);

  SetScriptProperties(e, spellReference);
  PatchedTomeCount := PatchedTomeCount + 1;
End;

// Called after processing
Function Finalize : Integer;
Begin
  SortMasters(PatchPlugin);
  CleanMasters(PatchPlugin);

  AddMessage(Format('Patched %d spell tomes to support Better Spell Learning', [PatchedTomeCount]));
End;

// ========== HELPER FUNCTIONS ==========

// Clears the DATA fields of the spell tome that are no longer required; Returns a reference to the spell the tome is teaching
Function ModifySpellTomeData(e: IInterface): IInterface;
Var
  i: Integer;
  description: String;
  spellEffects: IInterface;
  spellEffect: IInterface;

Begin
  Result := LinksTo(ElementByPath(e, 'DATA\Spell'));

  // The tome will no longer directly teach a spell
  SetElementNativeValues(e, 'DATA\Spell', -1);
  SetFlag(ElementByPath(e, 'DATA\Flags'), 'Teaches Spell', False);

  // Update book text to include standard BSL text
  SetElementEditValues(e, 'DESC', GetElementEditValues(e, 'DESC') + sBookDescription);

  // Update CNAM - Description to contain spell description, because it isn't retrieved automatically since we removed the link to a spell
  description := '';
  spellEffects := ElementByName(Result, 'Effects');
  For i := 0 To pred(ElementCount(spellEffects)) Do
  Begin
    spellEffect := LinksTo(ElementByName(ElementByIndex(spellEffects, i), 'EFID - Base Effect'));
    description := description + GetElementEditValues(spellEffect, 'DNAM');
  End;

  SetElementEditValues(e, 'CNAM', description);
End;

// Checks whether the specified element is a book that will teach a spell
Function IsConvertableSpellTome(e: IInterface): Boolean;
Begin
  // Also check for attached script called 'SpellTomeReadScript'
  Result := GetElementEditValues(e, 'DATA\Flags\Teaches Spell') = '1' And Not Assigned(GetScript(e, sBetterSpellLearningScript));
End;

// Sets the properties on the tome's script to values matching the specified spell
Procedure SetScriptProperties(e: IInterface; spellReference: IInterface);
Var
  script: IInterface;
  firstEffect: IInterface;

Begin
  script := GetScript(e, sBetterSpellLearningScript);

  firstEffect := LinksTo(ElementByPath(spellReference, 'Effects\[0]\EFID - Base Effect'));

  SetIntPropertyOnScript(script, 'difficulty', GetElementNativeValues(firstEffect, 'Magic Effect Data\DATA\Minimum Skill Level'));
  SetStringPropertyOnScript(script, 'School', uppercase(GetElementEditValues(firstEffect, 'Magic Effect Data\DATA\Magic Skill')));
  SetStringPropertyOnScript(script, 'LearnSpell', GetElementEditValues(spellReference, 'FULL'));

  SetFormPropertyOnScript(script, 'SpellLearned', GetLoadOrderFormID(spellReference));
  SetFormPropertyOnScript(script, 'ThisBook', GetLoadOrderFormID(e));
End;

End.