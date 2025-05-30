; install.msi
;
; Installer for Meridian 59 client
;--------------------------------

!addplugindir ".\plugins"
!include FontReg.nsh
!include FontName.nsh
!include WinMessages.nsh
!include UAC.nsh

!define SOURCEDIR "..\run\webclient"

; First is default
LoadLanguageFile "${NSISDIR}\Contrib\Language files\English.nlf"
LoadLanguageFile "${NSISDIR}\Contrib\Language files\German.nlf"

; The name of the installer
Name "Meridian 59"

; The file to write
OutFile "meridian59-installer.exe"

; The default installation directory
InstallDir "$PROGRAMFILES\Meridian 59"

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\Meridian 59" "Install_Dir"

; Compress to the max
SetCompressor /SOLID LZMA

; We run an outer script with user permission, and an inner one with admin.  See
; http://nsis.sourceforge.net/UAC_plug-in
RequestExecutionLevel user

Function .OnInit
 
UAC_Elevate:
    !insertmacro UAC_RunElevated
    StrCmp 1223 $0 UAC_ElevationAborted ; UAC dialog aborted by user?
    StrCmp 0 $0 0 UAC_Err ; Error?
    StrCmp 1 $1 0 UAC_Success ;Are we the real deal or just the wrapper?
    Quit
 
UAC_Err:
    MessageBox mb_iconstop "Unable to elevate, error $0"
    Abort
 
UAC_ElevationAborted:
    # elevation was aborted, run as normal?
    MessageBox mb_iconstop "This installer requires admin access, aborting!"
    Abort
 
UAC_Success:
    StrCmp 1 $3 +4 ;Admin?
    StrCmp 3 $1 0 UAC_ElevationAborted ;Try again?
    MessageBox mb_iconstop "This installer requires admin access, try again"
    goto UAC_Elevate 
 
FunctionEnd


Function .OnInstFailed
;    UAC::Unload ;Must call unload!
FunctionEnd
 
Function .OnInstSuccess
;    UAC::Unload ;Must call unload!
FunctionEnd
;--------------------------------

; Pages

Page license
Page components
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

LicenseData "license.rtf"

;--------------------------------

Function InstallWithUserPrivilege
  ; These files go to the local data directory, not Program Files
  SetOutPath "$LOCALAPPDATA\Meridian 59\resource"
  File ${SOURCEDIR}\resource\*.*
  SetOutPath "$LOCALAPPDATA\Meridian 59\mail"
  File "${SOURCEDIR}\mail\*.*"
  SetOutPath "$LOCALAPPDATA\Meridian 59"
  File "${SOURCEDIR}\meridian.ini"

  ; Create download directory now; creating it on demand seems to fail
  ; under some UAC conditions.
  CreateDirectory "$LOCALAPPDATA\Meridian 59\download"
FunctionEnd

Function InstallDesktopShortcut
  ; This inherits the run directory from $OUTDIR, which is set to the local data dir
  ; by InstallWithUserPrivilege

  ; Set to run in data directory
  SetOutPath "$LOCALAPPDATA\Meridian 59"
  CreateShortCut "$DESKTOP\Meridian 59.lnk" "$INSTDIR\meridian.exe" "" "$INSTDIR\meridian.exe" 0
FunctionEnd

Function InstallMenuShortcuts
  CreateDirectory "$SMPROGRAMS\Meridian 59"
  CreateShortCut "$SMPROGRAMS\Meridian 59\Uninstall Meridian 59.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0

  ; Set to run in data directory
  SetOutPath "$LOCALAPPDATA\Meridian 59"

  CreateShortCut "$SMPROGRAMS\Meridian 59\Meridian 59.lnk" "$INSTDIR\meridian.exe" "" "$INSTDIR\meridian.exe" 0
FunctionEnd

; The stuff to install
Section "Meridian 59 (required)"

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR

  ; Put executable files there
  File "${SOURCEDIR}\archive.dll"
  File "${SOURCEDIR}\club.exe"
  File "${SOURCEDIR}\heidelb1.ttf"
  File "${SOURCEDIR}\license.rtf"
  File "${SOURCEDIR}\meridian.exe"
  File "${SOURCEDIR}\mss32.dll"
  File "${SOURCEDIR}\mss32midi.dll"
  File "${SOURCEDIR}\mssmp3.asi"
  File "${SOURCEDIR}\waveplay.dll"
  File "${SOURCEDIR}\zlib1.dll"

  File "${SOURCEDIR}\BsSndRpt.exe"
  File "${SOURCEDIR}\BugSplat.dll"
  File "${SOURCEDIR}\BugSplatRc.dll"

  ; Install font
  StrCpy $FONT_DIR $FONTS
  !insertmacro InstallTTFFont "${SOURCEDIR}\heidelb1.ttf"
  SendMessage ${HWND_BROADCAST} ${WM_FONTCHANGE} 0 0 /TIMEOUT=5000

  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\Meridian59 "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Meridian 59" "DisplayName" "Meridian 59"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Meridian 59" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Meridian 59" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Meridian 59" "NoRepair" 1
  WriteUninstaller "uninstall.exe"

  ; Install resources at user level
  !insertmacro UAC_AsUser_Call function InstallWithUserPrivilege ${UAC_SYNCREGISTERS}|${UAC_SYNCINSTDIR}
SectionEnd

; Optional section (can be disabled by the user)
Section "Desktop Shortcut"
  ; Shortcut must be installed as current user
  !insertmacro UAC_AsUser_Call function InstallDesktopShortcut ${UAC_SYNCREGISTERS}|${UAC_SYNCINSTDIR}
SectionEnd

; Optional section
Section "Start Menu Shortcuts"
  ; Shortcut must be installed as current user
  !insertmacro UAC_AsUser_Call function InstallMenuShortcuts ${UAC_SYNCREGISTERS}|${UAC_SYNCINSTDIR}
SectionEnd

;--------------------------------

; Uninstaller

Function un.OnInit
UAC_Elevate:
    !insertmacro UAC_RunElevated
    StrCmp 1223 $0 UAC_ElevationAborted ; UAC dialog aborted by user?
    StrCmp 0 $0 0 UAC_Err ; Error?
    StrCmp 1 $1 0 UAC_Success ;Are we the real deal or just the wrapper?
    Quit
 
UAC_Err:
    MessageBox mb_iconstop "Unable to elevate, error $0"
    Abort
 
UAC_ElevationAborted:
    # elevation was aborted, run as normal?
    MessageBox mb_iconstop "This installer requires admin access, aborting!"
    Abort
 
UAC_Success:
    StrCmp 1 $3 +4 ;Admin?
    StrCmp 3 $1 0 UAC_ElevationAborted ;Try again?
    MessageBox mb_iconstop "This installer requires admin access, try again"
    goto UAC_Elevate 
 
FunctionEnd

Function un.OnUnInstFailed
;    UAC::Unload ;Must call unload!
FunctionEnd
 
Function un.OnUnInstSuccess
;    UAC::Unload ;Must call unload!
FunctionEnd

Section "Uninstall"
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Meridian 59"
  DeleteRegKey HKLM "SOFTWARE\Meridian 59"

  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\Meridian 59\Meridian 59.lnk"
  Delete "$SMPROGRAMS\Meridian 59\Uninstall Meridian 59.lnk"
  Delete "$DESKTOP\Meridian 59.lnk"

  ; Remove font

  ;  StrCpy $FONT_DIR $INSTDIR
  ;  !insertmacro RemoveTTFFont "$INSTDIR\heidelb1.ttf"

  ; Remove directories used
  RMDir "$SMPROGRAMS\Meridian 59"
  RMDir /r "$INSTDIR"
  RMDir /r "$LOCALAPPDATA\Meridian 59"

SectionEnd
