{
  Provides various utility functions useful in scripts.
}
Unit UrbanCMCUtility;

// Copies the VMAD record of from the source to the target element
Function CopyVMADRecord(e: IInterface; plugin: IInterface; sourceRecordID: Integer): Integer;
Var
  sourceRecord: IInterface;
Begin
  sourceRecord := RecordByFormID(plugin, sourceRecordID, False);
  If Not Assigned(sourceRecord) Then
  Begin
    AddMessage('Can''t locate source record ' + source + ' in ' + GetFileName(plugin));
    Result := 1;
    Exit;
  End;

  Add(e, 'VMAD', True);
  If ElementExists(e, 'VMAD') Then
  Begin
    ElementAssign(ElementByPath(e, 'VMAD'), LowInteger, ElementByPath(sourceRecord, 'VMAD'), False);
  End;
End;

// Sets/Unsets the specified flag on an element
Procedure SetFlag(e: IInterface; flagName: string; flagValue: boolean);
Var
  i: Integer;
  flags: TStringList;
  oldValue, newValue: Cardinal;
Begin
  flags := TStringList.Create;
  flags.Text := FlagValues(e);
  oldValue := GetNativeValue(e);
  For i := 0 To pred(flags.Count) Do
  Begin
    If SameText(flags[i], flagName) Then
    Begin
      If flagValue Then
      Begin
        newValue := oldValue Or (1 shl i);
      End Else
      Begin
        newValue := oldValue And Not (1 shl i);
      End;

      If oldValue <> newValue Then SetNativeValue(e, newValue);
      Break;
    End;
  End;
  flags.Free;
End;

End.