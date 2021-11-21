// *************************************************************************** }
//
// Delphi MVC Framework
//
// Copyright (c) 2010-2021 Daniele Teti and the DMVCFramework Team
//
// https://github.com/danieleteti/delphimvcframework
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ***************************************************************************

unit MVCFramework.SQLGenerators.Sqlite;

interface

uses
  System.Rtti,
  System.Generics.Collections,
  MVCFramework.ActiveRecord,
  MVCFramework.Commons,
  MVCFramework.RQL.Parser;

type
  TMVCSQLGeneratorSQLite = class(TMVCSQLGenerator)
  protected
    function GetCompilerClass: TRQLCompilerClass; override;
  public
    function CreateInsertSQL(const TableName: string; const Map: TFieldsMap;
      const PKFieldName: string; const PKOptions: TMVCActiveRecordFieldOptions): string; override;
    function HasSequences: Boolean; override;
  end;

implementation

uses
  System.SysUtils,
  MVCFramework.RQL.AST2SQLite;

function TMVCSQLGeneratorSQLite.CreateInsertSQL(const TableName: string; const Map: TFieldsMap;
  const PKFieldName: string; const PKOptions: TMVCActiveRecordFieldOptions): string;
var
  lKeyValue: TPair<TRttiField, TFieldInfo>;
  lSB: TStringBuilder;
  lPKInInsert: Boolean;
  lFieldName: String;
begin
  lPKInInsert := (not PKFieldName.IsEmpty) and
    (not(TMVCActiveRecordFieldOption.foAutoGenerated in PKOptions));
  lPKInInsert := lPKInInsert and (not(TMVCActiveRecordFieldOption.foReadOnly in PKOptions));
  lSB := TStringBuilder.Create;
  try
    lSB.Append('INSERT INTO ' + GetTableNameForSQL(TableName) + ' (');
    if lPKInInsert then
    begin
      lSB.Append(GetFieldNameForSQL(PKFieldName) + ',');
    end;

    {partition}
    for lFieldName in fPartitionInfo.FieldNames do
    begin
      lSB.Append(GetFieldNameForSQL(lFieldName) + ',');
    end;
    {end-partition}

    for lKeyValue in Map do
    begin
      if lKeyValue.Value.Writeable then
      begin
        lSB.Append(GetFieldNameForSQL(lKeyValue.Value.FieldName) + ',');
      end;
    end;
    lSB.Remove(lSB.Length - 1, 1);
    lSB.Append(') values (');
    if lPKInInsert then
    begin
      lSB.Append(':' + GetParamNameForSQL(PKFieldName) + ',');
    end;

    {partition}
    for lFieldName in fPartitionInfo.FieldNames do
    begin
      lSB.Append(':' + GetParamNameForSQL(lFieldName) + ',');
    end;
    {end-partition}

    for lKeyValue in Map do
    begin
      if lKeyValue.Value.Writeable then
      begin
        lSB.Append(':' + GetParamNameForSQL(lKeyValue.Value.FieldName) + ',');
      end;
    end;
    lSB.Remove(lSB.Length - 1, 1);
    lSB.Append(')');

    if TMVCActiveRecordFieldOption.foAutoGenerated in PKOptions then
    begin
      lSB.Append(' ; SELECT last_insert_rowid() as ' + GetFieldNameForSQL(PKFieldName) + ';');
    end;
    Result := lSB.ToString;
  finally
    lSB.Free;
  end;
end;

function TMVCSQLGeneratorSQLite.GetCompilerClass: TRQLCompilerClass;
begin
  Result := TRQLSQLiteCompiler;
end;

function TMVCSQLGeneratorSQLite.HasSequences: Boolean;
begin
  Result := False;
end;

initialization

TMVCSQLGeneratorRegistry.Instance.RegisterSQLGenerator('sqlite', TMVCSQLGeneratorSQLite);

finalization

TMVCSQLGeneratorRegistry.Instance.UnRegisterSQLGenerator('sqlite');

end.
