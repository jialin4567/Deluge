# Deluge Windows installer script
# Version 0.4 28-Apr-2009

# Copyright (C) 2009 by
#   Jesper Lund <mail@jesperlund.com>
#   Andrew Resch <andrewresch@gmail.com>
#   John Garland <johnnybg@gmail.com>

# Deluge is free software.
#
# You may redistribute it and/or modify it under the terms of the
# GNU General Public License, as published by the Free Software
# Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# Deluge is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with deluge.    If not, write to:
# 	The Free Software Foundation, Inc.,
# 	51 Franklin Street, Fifth Floor
# 	Boston, MA    02110-1301, USA.
#

# Set default compressor
SetCompressor lzma

###
### --- The PROGRAM_VERSION !define need to be updated with new Deluge versions ---
###

# Script version; displayed when running the installer
!define DELUGE_INSTALLER_VERSION "0.4"

# Deluge program information
!define PROGRAM_NAME "Deluge"
!define PROGRAM_VERSION "1.2.2"
!define PROGRAM_WEB_SITE "http://deluge-torrent.org"

# Python files generated with bbfreeze (without DLLs from GTK+ runtime)
!define DELUGE_PYTHON_BBFREEZE_OUTPUT_DIR "..\build-win32\deluge-bbfreeze-${PROGRAM_VERSION}"

# Installer for GTK+ 2.12 runtime; will be downloaded from deluge-torrent.org
!define DELUGE_GTK_DEPENDENCY "gtk2-runtime-2.16.6-2010-02-24-ash.exe"


# --- Interface settings ---

# Modern User Interface 2
!include MUI2.nsh

# Installer
!define MUI_ICON "deluge.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "installer-top.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP "installer-side.bmp"
!define MUI_COMPONENTSPAGE_SMALLDESC
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_ABORTWARNING

# Uninstaller
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"
!define MUI_HEADERIMAGE_UNBITMAP "installer-top.bmp"
!define MUI_WELCOMEFINISHPAGE_UNBITMAP "installer-side.bmp"
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

# --- Start of Modern User Interface ---

# Welcome page
!insertmacro MUI_PAGE_WELCOME

# License page
!insertmacro MUI_PAGE_LICENSE "..\LICENSE"

# Components page
!insertmacro MUI_PAGE_COMPONENTS

# Let the user select the installation directory
!insertmacro MUI_PAGE_DIRECTORY

# Run installation
!insertmacro MUI_PAGE_INSTFILES

# Display 'finished' page
!insertmacro MUI_PAGE_FINISH

# Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

# Language files
!insertmacro MUI_LANGUAGE "English"


# --- Functions ---

Function un.onUninstSuccess
  HideWindow
  MessageBox MB_ICONINFORMATION|MB_OK "$(^Name) was successfully removed from your computer."
FunctionEnd

Function un.onInit
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Do you want to completely remove $(^Name) and all of its components?" IDYES +2
  Abort
FunctionEnd


# --- Installation sections ---

# Compare versions
!include "WordFunc.nsh"

!define PROGRAM_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PROGRAM_NAME}"
!define PROGRAM_UNINST_ROOT_KEY "HKLM"

# Branding text
BrandingText "Deluge Windows Installer v${DELUGE_INSTALLER_VERSION}"

Name "${PROGRAM_NAME} ${PROGRAM_VERSION}"
OutFile "..\build-win32\deluge-${PROGRAM_VERSION}-win32-setup.exe"

# The Python bbfreeze files will be placed here
!define DELUGE_PYTHON_SUBDIR "$INSTDIR\Deluge-Python"

InstallDir "$PROGRAMFILES\Deluge"

ShowInstDetails show
ShowUnInstDetails show

# Install main application
Section "Deluge Bittorrent Client" Section1
  SectionIn RO

  Rmdir /r "${DELUGE_PYTHON_SUBDIR}"
  SetOutPath "${DELUGE_PYTHON_SUBDIR}"
  File /r "${DELUGE_PYTHON_BBFREEZE_OUTPUT_DIR}\*.*"

  # Clean up previous confusion between Deluge.ico and deluge.ico (seems to matter on Vista registry settings?)
  Delete "$INSTDIR\Deluge.ico"

  SetOverwrite ifnewer
  SetOutPath $INSTDIR
  File "..\LICENSE"
  File "StartX.exe"
  File "deluge.ico"

  # Create deluge.cmd file
  fileOpen $0 "$INSTDIR\deluge.cmd" w
  fileWrite $0 '@ECHO OFF$\r$\n'
  fileWrite $0 'SET DELUGEFOLDER="$INSTDIR"$\r$\n'
  fileWrite $0 'SET STARTX_APP="$INSTDIR\StartX.exe"$\r$\n'
  fileWrite $0 '$\r$\n'
  fileWrite $0 'IF ""%1"" == """" ( $\r$\n'
  fileWrite $0 '  %STARTX_APP% /B /D%DELUGEFOLDER% "$INSTDIR\Deluge-Python\deluge.exe"$\r$\n'
  fileWrite $0 ') ELSE ( $\r$\n'
  fileWrite $0 '  %STARTX_APP% /B /D%DELUGEFOLDER% "$INSTDIR\Deluge-Python\deluge.exe "%1" "%2" "%3" "%4""$\r$\n'
  fileWrite $0 ')$\r$\n'
  fileClose $0

  # Create deluged.cmd file
  fileOpen $0 "$INSTDIR\deluged.cmd" w
  fileWrite $0 '@ECHO OFF$\r$\n'
  fileWrite $0 'SET DELUGEFOLDER="$INSTDIR"$\r$\n'
  fileWrite $0 '"$INSTDIR\StartX.exe" /B /D%DELUGEFOLDER% "$INSTDIR\Deluge-Python\deluged.exe "%1" "%2" "%3" "%4""$\r$\n'
  fileClose $0

  # Create deluge-webui.cmd file
  fileOpen $0 "$INSTDIR\deluge-webui.cmd" w
  fileWrite $0 '@ECHO OFF$\r$\n'
  fileWrite $0 'SET DELUGEFOLDER="$INSTDIR"$\r$\n'
  fileWrite $0 '"$INSTDIR\StartX.exe" /B /D%DELUGEFOLDER% "$INSTDIR\Deluge-Python\deluge.exe --ui web"$\r$\n'
  fileWrite $0 "ECHO Deluge WebUI started and is running at http://localhost:8112 by default$\r$\n"
  fileWrite $0 "ECHO NOTE: The Deluge WebUI process can only be stopped in the Windows Task Manager$\r$\n"
  fileWrite $0 "ECHO.$\r$\n"
  fileWrite $0 PAUSE
  fileClose $0
SectionEnd

Section -StartMenu_Desktop_Links
  WriteIniStr "$INSTDIR\homepage.url" "InternetShortcut" "URL" "${PROGRAM_WEB_SITE}"

  CreateDirectory "$SMPROGRAMS\Deluge"
  CreateShortCut "$SMPROGRAMS\Deluge\Deluge.lnk" "$INSTDIR\deluge.cmd" "" "$INSTDIR\deluge.ico"
  CreateShortCut "$SMPROGRAMS\Deluge\Deluge daemon.lnk" "$INSTDIR\deluged.cmd" "" "$INSTDIR\deluge.ico"
  CreateShortCut "$SMPROGRAMS\Deluge\Deluge webUI.lnk" "$INSTDIR\deluge-webui.cmd" "" "$INSTDIR\deluge.ico"
  CreateShortCut "$SMPROGRAMS\Deluge\Project homepage.lnk" "$INSTDIR\Homepage.url"
  CreateShortCut "$SMPROGRAMS\Deluge\Uninstall Deluge.lnk" "$INSTDIR\Deluge-uninst.exe"
  CreateShortCut "$DESKTOP\Deluge.lnk" "$INSTDIR\deluge.cmd" "" "$INSTDIR\deluge.ico"
SectionEnd

Section -Uninstaller
  WriteUninstaller "$INSTDIR\Deluge-uninst.exe"
  WriteRegStr ${PROGRAM_UNINST_ROOT_KEY} "${PROGRAM_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PROGRAM_UNINST_ROOT_KEY} "${PROGRAM_UNINST_KEY}" "UninstallString" "$INSTDIR\Deluge-uninst.exe"
  WriteRegStr ${PROGRAM_UNINST_ROOT_KEY} "${PROGRAM_UNINST_KEY}" "DisplayIcon" "$INSTDIR\deluge.ico"
SectionEnd

# Create file association for .torrent
Section "Create .torrent file association for Deluge" Section2
  # Set up file association for .torrent files
  DeleteRegKey HKCR ".torrent"
  WriteRegStr HKCR ".torrent" "" "Deluge"
  WriteRegStr HKCR ".torrent" "Content Type" "application/x-bittorrent"

  DeleteRegKey HKCR "Deluge"
  WriteRegStr HKCR "Deluge" "" "Deluge"
  WriteRegStr HKCR "Deluge\Content Type" "" "application/x-bittorrent"
  WriteRegStr HKCR "Deluge\DefaultIcon" "" '"$INSTDIR\deluge.ico"'
  WriteRegStr HKCR "Deluge\shell" "" "open"
  WriteRegStr HKCR "Deluge\shell\open\command" "" '"$INSTDIR\deluge.cmd" "%1"'
SectionEnd


# Create magnet uri association
Section "Create magnet uri link association for Deluge" Section3
    DeleteRegKey HKCR "magnet"
    WriteRegStr HKCR "magnet" "" "URL:magnet protocol"
    WriteRegStr HKCR "magnet" "URL Protocol" ""

    WriteRegStr HKCR "magnet\shell\open\command" "" '"$INSTDIR\deluge.cmd" "%1"'
SectionEnd

# Install GTK+ 2.16
Section "GTK+ 2.16 runtime" Section4
  GTK_install_start:
  MessageBox MB_OK "You will now download and run the installer for the GTK+ 2.16 runtime. \
    You must be connected to the internet before you press the OK button. \
    The GTK+ runtime can be installed in any location, \
    because the GTK+ installer adds the location to the global PATH variable. \
    Please note that the GTK+ 2.16 runtime is not removed by the Deluge uninstaller. \
    You must use the GTK+ 2.16 uninstaller if you want to remove it together with Deluge."

  # Download GTK+ installer to TEMP dir
  NSISdl::download http://download.deluge-torrent.org/windows/deps/${DELUGE_GTK_DEPENDENCY} "$TEMP\${DELUGE_GTK_DEPENDENCY}"

  # Get return value (success, cancel, or string describing the network error)
  Pop $2
  StrCmp $2 "success" 0 GTK_download_error

  ExecWait '"$TEMP\${DELUGE_GTK_DEPENDENCY}" /compatdlls=yes'
  Goto GTK_install_exit

  GTK_download_error:
  MessageBox MB_ICONEXCLAMATION|MB_OK "Download of GTK+ 2.16 installer failed (return code: $2). \
      You must install the GTK+ 2.16 runtime manually, or Deluge will fail to run on your system."

  GTK_install_exit:
SectionEnd

LangString DESC_Section1 ${LANG_ENGLISH} "Install Deluge Bittorrent client."
LangString DESC_Section2 ${LANG_ENGLISH} "Select this option unless you have another torrent client which you want to use for opening .torrent files."
LangString DESC_Section3 ${LANG_ENGLISH} "Select this option to have Deluge handle magnet links."
LangString DESC_Section4 ${LANG_ENGLISH} "Download and install the GTK+ 2.16 runtime. \
  This is skipped automatically if GTK+ is already installed."

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${Section1} $(DESC_Section1)
  !insertmacro MUI_DESCRIPTION_TEXT ${Section2} $(DESC_Section2)
  !insertmacro MUI_DESCRIPTION_TEXT ${Section3} $(DESC_Section3)
  !insertmacro MUI_DESCRIPTION_TEXT ${Section4} $(DESC_Section4)
!insertmacro MUI_FUNCTION_DESCRIPTION_END


# --- Uninstallation section(s) ---

Section Uninstall
  Rmdir /r "${DELUGE_PYTHON_SUBDIR}"

  Delete "$INSTDIR\Deluge-uninst.exe"
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\deluge.cmd"
  Delete "$INSTDIR\deluged.cmd"
  Delete "$INSTDIR\deluge-webui.cmd"
  Delete "$INSTDIR\StartX.exe"
  Delete "$INSTDIR\Homepage.url"
  Delete "$INSTDIR\deluge.ico"

  Delete "$SMPROGRAMS\Deluge\Deluge.lnk"
  Delete "$SMPROGRAMS\Deluge\Deluge daemon.lnk"
  Delete "$SMPROGRAMS\Deluge\Deluge webUI.lnk"
  Delete "$SMPROGRAMS\Deluge\Uninstall Deluge.lnk"
  Delete "$SMPROGRAMS\Deluge\Project homepage.lnk"
  Delete "$DESKTOP\Deluge.lnk"

  RmDir "$SMPROGRAMS\Deluge"
  RmDir "$INSTDIR"

  DeleteRegKey ${PROGRAM_UNINST_ROOT_KEY} "${PROGRAM_UNINST_KEY}"

  # Only delete the .torrent association if Deluge owns it
  ReadRegStr $1 HKCR ".torrent" ""
  StrCmp $1 "Deluge" 0 DELUGE_skip_delete

  # Delete the key since it is owned by Deluge; afterwards there is no .torrent association
  DeleteRegKey HKCR ".torrent"

  DELUGE_skip_delete:
  # This key is only used by Deluge, so we should always delete it
  DeleteRegKey HKCR "Deluge"
SectionEnd
