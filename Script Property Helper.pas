{
  Helper script that makes modifying script properties easier.

  Original code: DavidJCobb @ https://github.com/DavidJCobb/xedit-tesv-scripts/

  PROPERTY TYPE VALUES:
    1 - Object (any forms or aliases)
    2 - String
    3 - Int32
    4 - Float
    5 - Bool
    11 - Array of Object
    12 - Array of String
    13 - Array of Int32
    14 - Array of Float
    15 - Array of Bool
}
Unit UrbanCMCScriptHelper;

Const
  TypeObject = 1;
  TypeString = 2;
  TypeInt = 3;
  TypeFloat = 4;
  TypeBool = 5;

// Searches for and returns a script attached to a form
Function GetScript(form: IInterface; name: String): IInterface;
Var
  i: Integer;
  currentScript: IInterface;
  scripts: IInterface;
  scriptName: String;
  VMAD: IInterface;

Begin
  scripts := ElementByPath(form, 'VMAD\Scripts');
  If Not Assigned(scripts) Then Exit;

  For i := 0 To pred(ElementCount(scripts)) Do
  Begin
    currentScript := ElementByIndex(scripts, i);
    If SameText(Name(currentScript), name) Then
    Begin
     Result := currentScript;
     Exit;
    End;
  End;
End;

// Returns or creates a property on a script. Sets the wasCreated variable to True if the property had to be created
Function GetOrMakePropertyOnScript(script: IInterface; propertyName: String; propertyType: Integer; Var wasCreated : Boolean) : IInterface;
Var
  i: Integer;
  currentProperty: IInterface;
  properties: IInterface;

Begin
  properties := ElementByName(script, 'Properties');
  Result := GetPropertyFromScript(script, propertyName);
  If Assigned(Result) Then Exit;

  // Create the property if it does not exist.
  // The immediate child nodes (propertyName and friends) will be created and managed by TES5Edit, more-or-less automatically;
  // we'll just have to set their values.
  wasCreated := True;
  currentProperty := ElementAssign(properties, HighInteger, nil, False);
  SetElementEditValues(currentProperty, 'propertyName', propertyName);
  SetElementNativeValues(currentProperty, 'Type', propertyType);
  SetElementNativeValues(currentProperty, 'Flags', 1); // "Edited"
  Result := currentProperty;
End;

// Returns the matching property node in the given script.
Function GetPropertyFromScript(script: IInterface; propertyName: String) : IInterface;
Var
  i: Integer;
  currentProperty: IInterface;
  properties: IInterface;
  propertyValue: String;

Begin
  properties := ElementByName(script, 'Properties');
  For i := 0 To pred(ElementCount(properties)) Do
  Begin
    currentProperty := ElementByIndex(properties, i);
    If SameText(Name(currentProperty), 'Property') Then
    Begin
      propertyValue := GetElementEditValues(currentProperty, 'propertyName');
      If propertyValue = propertyName Then
      Begin
        Result := currentProperty;
        Exit;
      End;
    End;
  End;
End;

// Sets the value of a boolean property
Procedure SetBoolPropertyOnScript(script: IInterface; propertyName: String; propertyValue: Boolean);
Var
  targetProperty: IInterface;
  wasCreated: Boolean; // Unused

Begin
  targetProperty := GetOrMakePropertyOnScript(script, propertyName, TypeBool, wasCreated);
  SetElementNativeValues(targetProperty, 'Flags', 1); // "Edited"
  SetElementNativeValues(targetProperty, 'Bool', propertyValue);
End;

// Sets the value of an integer property
Procedure SetIntPropertyOnScript(script: IInterface; propertyName: String; propertyValue: Integer);
Var
  targetProperty: IInterface;
  wasCreated: Boolean; // Unused

Begin
  targetProperty := GetOrMakePropertyOnScript(script, propertyName, TypeInt, wasCreated);
  SetElementNativeValues(targetProperty, 'Flags', 1); // "Edited"
  SetElementNativeValues(targetProperty, 'Int32', propertyValue);
End;

// Sets the value of a float property
Procedure SetFloatPropertyOnScript(script: IInterface; propertyName: String; propertyValue: Float);
Var
  targetProperty: IInterface;
  wasCreated: Boolean; // Unused

Begin
  targetProperty := GetOrMakePropertyOnScript(script, propertyName, TypeFloat, wasCreated);
  SetElementNativeValues(targetProperty, 'Flags', 1); // "Edited"
  SetElementNativeValues(targetProperty, 'Float', propertyValue);
End;

// Sets the value of a form property
Procedure SetFormPropertyOnScript(script: IInterface; propertyName: String; propertyValue: Integer);
Var
  targetProperty: IInterface;
  wasCreated: Boolean; // Unused

Begin
  targetProperty := GetOrMakePropertyOnScript(script, propertyName, TypeString, wasCreated);
  SetElementNativeValues(targetProperty, 'Flags', 1); // "Edited"
  SetElementNativeValues(targetProperty, 'Value\Object Union\Object v2\FormID', propertyValue);
  SetElementNativeValues(targetProperty, 'Value\Object Union\Object v2\Alias', -1);
End;

// Sets the value of a string property
Procedure SetStringPropertyOnScript(script: IInterface; propertyName: String; propertyValue: String);
Var
  targetProperty: IInterface;
  wasCreated: Boolean; // Unused

Begin
  targetProperty := GetOrMakePropertyOnScript(script, propertyName, TypeString, wasCreated);
  SetElementNativeValues(targetProperty, 'Flags', 1); // "Edited"
  SetElementNativeValues(targetProperty, 'String', propertyValue);
End;

End.