program PrintMend;

{$APPTYPE CONSOLE}
{$OPTIMIZATION OFF}
{$DEFINE _DEBUG}

uses

  Windows,
  Messages,
  SysUtils,
  Classes,
  PrnCmd in 'PrnCmd.pas',     //机器指令生成单元
  PrtCtrl in 'PrtCtrl.pas',   //打印输出控制单元
  MemMap in 'MemMap.pas',     //
  PMConst in 'PMConst.pas',
  MemBuf in 'MemBuf.pas',
  PMRCU in 'PMRCU.pas',   //机器指令读取分析单元
  PMTypedef in 'PMTypedef.pas',
  VarPointer in 'VarPointer.pas', //变形指针单元
  PMMCU in 'PMMCU.pas',//机器指令修补单元
  Mender in 'Mender.pas'; //管理单元



begin



end.

