XPStyle on
RequestExecutionLevel user
SetCompressor /SOLID lzma

!addincludedir "NSIS dirs\Include"
!addplugindir "NSIS dirs\Plugins"
!include nsDialogs.nsh
!include LogicLib.nsh
!include Sections.nsh
!include UAC.nsh
!include GameExplorer.nsh
!include WinVer.nsh
!include nsArray.nsh
!include Utils.nsh
!include WordFunc.nsh
!include textlog.nsh
!include x64.nsh
!include procfunc.nsh
!include KBInstall.nsh

Var GTA_DIR
Var Install_Dir
Var CreateSMShortcuts
Var CreateDesktopIcon
Var RegisterProtocol
Var AddToGameExplorer
Var ExeMD5
Var PatchInstalled
Var DEFAULT_INSTDIR
Var LAST_INSTDIR
Var CUSTOM_INSTDIR
Var WhichRadio
Var ShowLastUsed
Var PermissionsGroup

; Games explorer: With each new X.X, update this GUID and the file at MTA10\launch\NEU\GDFImp.gdf.xml
!define GUID "{DF780162-2450-4665-9BA2-EAB14ED640A3}"


!ifndef MAJOR_VER
    !define MAJOR_VER "1"
    !define MINOR_VER "4"
    !define MAINT_VER "0"
!endif
!define 0.0 "${MAJOR_VER}.${MINOR_VER}"
!define 0.0.0 "${MAJOR_VER}.${MINOR_VER}.${MAINT_VER}"

; ###########################################################################################################
!ifndef FILES_ROOT
    !define LIGHTBUILD    ; enable LIGHTBUILD for nightly
    !define FILES_ROOT "../../InstallFiles"
    !define SERVER_FILES_ROOT "${FILES_ROOT}/server"
    !define FILES_MODULE_SDK "${FILES_ROOT}/development/publicsdk"
    !define INSTALL_OUTPUT "mtasa-${0.0.0}-unstable-00000-0-000-nsis.exe"
    !define PRODUCT_VERSION "v${0.0.0}-unstable-00000-0-000"
    !define REVISION "0"
!endif
!ifndef LIGHTBUILD
    !define INCLUDE_DEVELOPMENT
    !define INCLUDE_EDITOR
!endif
!ifndef PRODUCT_VERSION
    !define PRODUCT_VERSION "v${0.0.0}"
!endif
!define EXPAND_DIALOG_X 134
!define EXPAND_DIALOG_Y 60
!define DIALOG_X 450
; ###########################################################################################################

;ReserveFile "${NSISDIR}\Plugins\InstallOptions.dll"
!ifdef REVISION
    !define REVISION_TAG "(r${REVISION})"
!else
    !define REVISION_TAG ""
!endif

!define PRODUCT_NAME "MTA:SA ${0.0}"
!define PRODUCT_NAME_NO_VER "MTA:SA"

!define PRODUCT_PUBLISHER "Multi Theft Auto"
!define PRODUCT_WEB_SITE "http://www.multitheftauto.com"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\Multi Theft Auto ${0.0}.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

; Set file version information
!ifndef VI_PRODUCT_VERSION
    !ifdef REVISION
        !define VI_PRODUCT_VERSION "${0.0.0}.${REVISION}"
    !else
        !define VI_PRODUCT_VERSION "${0.0.0}.0"
    !endif
    !define VI_PRODUCT_NAME "MTA San Andreas"
    !define VI_COMPANY_NAME "Multi Theft Auto"
    !define /date DATE_YEAR "%Y"
    !define VI_LEGAL_COPYRIGHT "(C) 2003 - ${DATE_YEAR} Multi Theft Auto"
    !ifndef LIGHTBUILD
        !define VI_FILE_DESCRIPTION "Multi Theft Auto Full Installer"
    !else
        !define VI_FILE_DESCRIPTION "Multi Theft Auto Nightly Installer"
    !endif
!endif
VIProductVersion "${VI_PRODUCT_VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "${VI_PRODUCT_NAME}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "${VI_COMPANY_NAME}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "${VI_LEGAL_COPYRIGHT}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "${VI_FILE_DESCRIPTION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${VI_PRODUCT_VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductVersion" "${VI_PRODUCT_VERSION}"

; MUI 1.67 compatible ------
!include "MUI.nsh"
!include "ReplaceSubStr.nsh"
!include "FileIfMD5.nsh"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON        "mta.ico"
!define MUI_UNICON      "mta.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "mta_install_header.bmp"
!define MUI_HEADERIMAGE_BITMAP_RTL "mta_install_header_rtl.bmp"

; Welcome page
!define MUI_WELCOMEPAGE_TITLE_3LINES
!define MUI_WELCOMEPAGE_TEXT        "$(WELCOME_TEXT)"
!define MUI_PAGE_CUSTOMFUNCTION_PRE "WelcomePreProc"
!define MUI_PAGE_CUSTOMFUNCTION_SHOW "WelcomeShowProc"
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE "WelcomeLeaveProc"
!insertmacro MUI_PAGE_WELCOME

; License page
!define MUI_PAGE_CUSTOMFUNCTION_SHOW "LicenseShowProc"
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE "LicenseLeaveProc"
!insertmacro MUI_PAGE_LICENSE                   "eula.txt"

Page custom CustomNetMessagePage CustomNetMessagePageLeave

; Components page
!define MUI_PAGE_CUSTOMFUNCTION_SHOW "ComponentsShowProc"
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE "ComponentsLeaveProc"
!insertmacro MUI_PAGE_COMPONENTS

; Game directory page
#!define MUI_PAGE_CUSTOMFUNCTION_SHOW "DirectoryShowProc"
#!define MUI_PAGE_CUSTOMFUNCTION_LEAVE "DirectoryLeaveProc"
#!define MUI_CUSTOMFUNCTION_ABORT "DirectoryAbort"
#!define MUI_DIRECTORYPAGE_VARIABLE             $INSTDIR
#!insertmacro MUI_PAGE_DIRECTORY
Page custom CustomDirectoryPage CustomDirectoryPageLeave

; Language Tools ----
;Note: Assumes NSIS Unicode edition compiler
!define MUI_LANGDLL_ALLLANGUAGES
!define MUI_LANGDLL_REGISTRY_ROOT "HKLM" 
!define MUI_LANGDLL_REGISTRY_KEY "SOFTWARE\Multi Theft Auto: San Andreas All\${0.0}" 
!define MUI_LANGDLL_REGISTRY_VALUENAME "Installer Language"
!insertmacro MUI_RESERVEFILE_LANGDLL ;Solid compression optimization for multilang

; INSERT OUR PAGES
!define MUI_PAGE_CUSTOMFUNCTION_PRE             SkipDirectoryPage
!define MUI_PAGE_HEADER_TEXT                    "$(HEADER_Text)"
!define MUI_PAGE_HEADER_SUBTEXT                 ""
!define MUI_DIRECTORYPAGE_TEXT_DESTINATION      "$(DIRECTORY_Text_Dest)"
!define MUI_DIRECTORYPAGE_TEXT_TOP              "$(DIRECTORY_Text_Top)"
!define MUI_DIRECTORYPAGE_VARIABLE              $GTA_DIR
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE           "GTADirectoryLeaveProc"
!insertmacro MUI_PAGE_DIRECTORY

; Instfiles page
!insertmacro MUI_PAGE_INSTFILES

; Finish page
!define MUI_FINISHPAGE_TITLE_3LINES
; Launch from installer with user privileges
!define MUI_FINISHPAGE_RUN                      ""
!define MUI_FINISHPAGE_RUN_FUNCTION             "LaunchLink"
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

; INSERT OUR LANGUAGE STRINGS -----
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Swedish"
LangString LANGUAGE_CODE ${LANG_Swedish} "sv"
LangString WELCOME_TEXT ${LANG_Swedish} "Den här guiden leder dig genom installationen eller uppdateringen av $(^Name) ${REVISION_TAG}\n\nDet är rekommenderat att du stänger alla andra program innan du startar installationsprogrammet.\n\n[Administratörsbehörighet kan begäras för Vista och upp]\n\nKlicka på Nästa för att fortsätta."
LangString HEADER_Text ${LANG_Swedish} "Grand Theft Auto: San Andreas plats"
LangString DIRECTORY_Text_Dest ${LANG_Swedish} "Grand Theft Auto: San Andreas mapp"
LangString DIRECTORY_Text_Top ${LANG_Swedish} "Vänligen välj din Grand Theft Auto: San Andreas mapp.$\n$\nDu MÅSTE ha Grand Theft Auto: San Andreas 1.0 installerat för att kunna använda MTA:SA, det stödjer inte några andra versioner.$\n$\nKlicka på Installera för att påbörja installationen."
LangString DESC_Section10 ${LANG_Swedish} "Skapa en grupp i startmenyn för installerade program"
LangString DESC_Section11 ${LANG_Swedish} "Skapa en skrivbordsgenväg till MTA:SA Klienten."
LangString DESC_Section12 ${LANG_Swedish} "Registrera mtasa:// protokollet för webbläsarklickbarhet."
LangString DESC_Section13 ${LANG_Swedish} "Lägg till i Windows Spelutforskaren (om sådan finns)."
LangString DESC_Section1 ${LANG_Swedish} "De centrala komponentera som krävs för att köra Multi Theft Auto."
LangString DESC_Section2 ${LANG_Swedish} "MTA:SA modifikationen, så att du kan spela online."
LangString DESC_SectionGroupServer ${LANG_Swedish} "Multi Theft Auto Servern. Detta ger dig möjlighet att vara värd för spel från din dator. Detta kräver en snabb internetuppkoppling."
LangString DESC_Section4 ${LANG_Swedish} "Multi Theft Auto servern. Detta är en nödvändig komponent."
LangString DESC_Section5 ${LANG_Swedish} "MTA:SA modifikationen till server."
LangString DESC_Section6 ${LANG_Swedish} "Detta är en uppsättning av nödvändiga resurser för din server."
LangString DESC_Section7 ${LANG_Swedish} "Detta är en valfri uppsättning spellägen och kartor för din server."
LangString DESC_Section8 ${LANG_Swedish} "MTA:SA 1.0 Kartskapare.  Detta kan användas för att skapa dina alldeles egna kartor för användning i spellägen för MTA."
LangString DESC_Section9 ${LANG_Swedish} "Detta är en SDK för att skapa binära moduler för MTA-servern. Installera bara om du har en god förståelse för C++!"
LangString DESC_SectionGroupDev ${LANG_Swedish} "Utvecklingskod och verktyg som hjälper dig i skapandet av mods för Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_Swedish} "Klienten är programmet du kör för att spela på en Multi Theft Auto server"
LangString INST_CLIENTSERVER ${LANG_Swedish} "Klient och Server"
LangString INST_SERVER ${LANG_Swedish} "Bara server"
LangString INST_STARTMENU_GROUP ${LANG_Swedish} "Startmenygrupp"
LangString INST_DESKTOP_ICON ${LANG_Swedish} "Skrivbordsikon"
LangString INST_PROTOCOL ${LANG_Swedish} "Registrera mtasa:// protokoll"
LangString INST_GAMES_EXPLORER ${LANG_Swedish} "Lägg till i Spelutforskaren"
LangString INST_SEC_CLIENT ${LANG_Swedish} "Spelklient"
LangString INST_SEC_SERVER ${LANG_Swedish} "Dedikerad server"
LangString INST_SEC_CORE ${LANG_Swedish} "Centrala komponenter"
LangString INST_SEC_GAME ${LANG_Swedish} "Spelmodul"
LangString INFO_INPLACE_UPGRADE ${LANG_Swedish} "Utför uppgradering..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Swedish} "Uppdaterar behörigheter. Detta kan ta några minuter..."
LangString MSGBOX_INVALID_GTASA ${LANG_Swedish} "En giltig Windows version av Grand Theft Auto: San Andreas hittades inte.$\r$\nMen installationen kommer att fortsätta.$\r$\nVar god installera om, om det blir problem senare."
LangString INST_SEC_CORE_RESOURCES ${LANG_Swedish} "Centrala resurser"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Swedish} "Valfria resurser"
LangString INST_SEC_EDITOR ${LANG_Swedish} "Redigerare"
LangString INST_SEC_DEVELOPER ${LANG_Swedish} "Utveckling"
LangString UNINST_SUCCESS ${LANG_Swedish} "$(^Name) har tagits bort från datorn."
LangString UNINST_FAIL ${LANG_Swedish} "Avinstallationen misslyckades!"
LangString UNINST_REQUEST ${LANG_Swedish} "Är du säker på att du vill ta bort $(^Name) och alla dess komponenter?"
LangString UNINST_DATA_REQUEST ${LANG_Swedish} "Vill du behålla dina datafiler (t.ex. resurser, skärmdumpar och serverkonfiguration)? Om du klickar på nej kommer alla resurser, konfigurationer eller skärmdumpar som du har skapat att förloras."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Swedish} "Kunde inte ladda ner patchfilen för din version av Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Swedish} "Kunde inte installera patchfilen för din version av Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_Swedish} "Detta installationsprogram kräver administratörsbehörighet, försök igen"
LangString UAC_RIGHTS_UN ${LANG_Swedish} "Denna avinstallerare kräver administratörsbehörighet, försök igen"
LangString UAC_RIGHTS3 ${LANG_Swedish} "Inloggningstjänsten körs inte, avbryter!"
LangString UAC_RIGHTS4 ${LANG_Swedish} "Kunde inte höja"
LangString INST_MTA_CONFLICT ${LANG_Swedish} "En annan huvudversion av MTA ($1) finns redan i den sökvägen.$\n$\nMTA är designat att installera huvudversioner i olika sökvägar.$\n Är du säker på att du vill skriva över MTA $1 i $INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Swedish} "Den valda sökvägen finns inte.$\n$\nVar god välj GTA:SA installationsmappen"
LangString INST_GTA_ERROR2 ${LANG_Swedish} "Kunde inte hitta GTA:SA installerat i $GTA_DIR $\n$\nÄr du säker på att du vill fortsätta ?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Swedish} "Välj Installationsmapp"
LangString INST_CHOOSE_LOC ${LANG_Swedish} "Välj mapp att installera ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Swedish} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} kommer att installeras i följande mapp.$\nFör att installera i en annan mapp, klicka på Bläddra och välj en annan mapp.$\n$\n Klicka på Nästa för att fortsätta."
LangString INST_CHOOSE_LOC3 ${LANG_Swedish} "Destinationsmapp"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Swedish} "Bläddra..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Swedish} "Standard"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Swedish} "Senast använd"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Swedish} "Anpassad"
LangString INST_CHOOSE_LOC4 ${LANG_Swedish} "Välj mapp att installera ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} i:"
LangString INST_LOC_OW ${LANG_Swedish} "Varning: En annan huvudversion av MTA ($1) finns redan i den sökvägen."
LangString INST_LOC_UPGRADE ${LANG_Swedish} "Installationstyp:  Uppgradera"
LangString GET_XPVISTA_PLEASE ${LANG_Swedish} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Swedish} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString DESC_DirectX ${LANG_Swedish} "Install or update DirectX (if required)."
LangString INST_DIRECTX ${LANG_Swedish} "Install DirectX"
LangString UNINST_REQUEST_NOTE ${LANG_Swedish} "Uninstalling before update?$\r$\nIt is not necessary to uninstall before installing a new version of MTA:SA$\r$\nRun the new installer to upgrade and preserve your settings."
LangString INST_GTA_CONFLICT ${LANG_Swedish} "MTA cannot be installed into the same directory as GTA:SA.$\n$\nDo you want to use the default install directory$\n$DEFAULT_INSTDIR ?"
LangString NETTEST_TITLE1 ${LANG_Swedish} "Online update"
LangString NETTEST_TITLE2 ${LANG_Swedish} "Checking for update information"
LangString NETTEST_STATUS1 ${LANG_Swedish} "Checking for installer update information..."
LangString NETTEST_STATUS2 ${LANG_Swedish} "Please ensure your firewall is not blocking"
!insertmacro MUI_LANGUAGE "Estonian"
LangString LANGUAGE_CODE ${LANG_Estonian} "et"
LangString WELCOME_TEXT ${LANG_Estonian} "See rakendus aitab sul läbida  $(^Name) ${REVISION_TAG} paigaldamise või uuendamise\n\nSoovitame enne alustamist sulgeda kõik teised rakendused.\n\n[Administraatori õigused võivad olla vajalikud kui kasutate Vistat või uuemat windowsi]\n\nVajutage Edasi kui soovite jätkata"
LangString HEADER_Text ${LANG_Estonian} "Grand Theft Auto: San Andrease asukoht"
LangString DIRECTORY_Text_Dest ${LANG_Estonian} "Grand Theft Auto: San Andrease kaust"
LangString DIRECTORY_Text_Top ${LANG_Estonian} "Palun vali oma Grand Theft Auto: San Andrease kaust.$\n$\nSul peab olema eelnevalt paigaldatud Grand Theft Auto: San Andreas 1.0, MTA:SA ei pruugi käivituda teiste versioonidega.$\n$\nVajuta Paigalda, et alustada paigaldamisega."
LangString DESC_Section10 ${LANG_Estonian} "Tee Start Menüü grupp paigaldatud rakendustele"
LangString DESC_Section11 ${LANG_Estonian} "Tee desktopi lühitee MTA:SA rakendusele."
LangString DESC_Section12 ${LANG_Estonian} "Registreeri mtasa:// protokoll brauserite jaoks."
LangString DESC_Section13 ${LANG_Estonian} "Lisa Windowsi Mängude hulka (kui on olemas)."
LangString DESC_Section1 ${LANG_Estonian} "Põhilised kompondendid, mida vaja Multi Theft Auto käivitamiseks."
LangString DESC_Section2 ${LANG_Estonian} "See on MTA:SA modifikatsioon, mis lubab sul mängida onlainis."
LangString DESC_SectionGroupServer ${LANG_Estonian} "Multi Theft Auto server. See lubab sul luua enda mänguserverit. Nõuab internetiühendust."
LangString DESC_Section4 ${LANG_Estonian} "Multi Theft Auto server. See on nõutud komponent."
LangString DESC_Section5 ${LANG_Estonian} "MTA:SA modifikatsioon serveri jaoks."
LangString DESC_Section6 ${LANG_Estonian} "See on kogum ressursse sinu mänguserveri jaoks."
LangString DESC_Section7 ${LANG_Estonian} "See on valikuline kogum mängutüüpe ja kaarte sinu mänguserveri jaoks."
LangString DESC_Section8 ${LANG_Estonian} "MTA:SA 1.0 Kaardi Loomise Rakendus. See aitab sul luua sinu enda kaarte, mida saab kasutada mängutüüpides."
LangString DESC_Section9 ${LANG_Estonian} "See on SDK, et luua mooduleid MTA serverile. Paigaldada ainult kui oskad hästi C++ keelt!"
LangString DESC_SectionGroupDev ${LANG_Estonian} "Arendamise kood ja tööriistad, mis aitavad luua modifikatsioone Multi Theft Auto jaoks"
LangString DESC_SectionGroupClient ${LANG_Estonian} "Klient on rakendus, millega saad mängida Multi Theft Auto serveris"
LangString INST_CLIENTSERVER ${LANG_Estonian} "Klient ja Server"
LangString INST_SERVER ${LANG_Estonian} "Ainult server"
LangString INST_STARTMENU_GROUP ${LANG_Estonian} "Start menüü grupp"
LangString INST_DESKTOP_ICON ${LANG_Estonian} "Desktopi ikoon"
LangString INST_PROTOCOL ${LANG_Estonian} "Registreeri mtasa:// protokoll"
LangString INST_GAMES_EXPLORER ${LANG_Estonian} "Lisa Games Exploreri"
LangString INST_SEC_CLIENT ${LANG_Estonian} "Mängu klient"
LangString INST_SEC_SERVER ${LANG_Estonian} "Virtuaalserver"
LangString INST_SEC_CORE ${LANG_Estonian} "Põhilised komponendid"
LangString INST_SEC_GAME ${LANG_Estonian} "Mängu moodul"
LangString INFO_INPLACE_UPGRADE ${LANG_Estonian} "Uuendan..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Estonian} "Uuendan õiguseid. See võib võtta paar minutit..."
LangString MSGBOX_INVALID_GTASA ${LANG_Estonian} "Nõutud Windowsi versiooni Grand Theft Auto: San Andreasest ei leitud.$\r$\nSiiski paigaldamine jätkub.$\r$\nPalun paigaldage uuesti kui rakendusega on hiljem probleeme."
LangString INST_SEC_CORE_RESOURCES ${LANG_Estonian} "Põhilised ressursid"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Estonian} "Valikulised ressursid"
LangString INST_SEC_EDITOR ${LANG_Estonian} "Redaktor"
LangString INST_SEC_DEVELOPER ${LANG_Estonian} "Arendus"
LangString UNINST_SUCCESS ${LANG_Estonian} "$(^Name) on edukalt teie arvutist eemaldatud."
LangString UNINST_FAIL ${LANG_Estonian} "Eemaldamine ebaõnnestus!"
LangString UNINST_REQUEST ${LANG_Estonian} "Kas oled kindel, et soovid eemaldada $(^Name) ja kõik selle komponendid?"
LangString UNINST_DATA_REQUEST ${LANG_Estonian} "Kas sooviksid jätta mõned failid nagu ressursid, pildid ja serveri seaded? Kui vajutate ei siis kõik ressursid, pildid ja serveri seaded kustutatakse ära."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Estonian} "Ei suuda alla laadida uuendus faili Grand Theft Auto: San Andrease jaoks"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Estonian} "Ei suuda paigaldada uuendust Grand Theft Auto: San Andrease jaoks"
LangString UAC_RIGHTS1 ${LANG_Estonian} "Paigaldamine nõuab administraatori õiguseid, proovige uuesti"
LangString UAC_RIGHTS_UN ${LANG_Estonian} "Eemaldamis rakendus vajab administraatori õiguseid, proovige uuesti"
LangString UAC_RIGHTS3 ${LANG_Estonian} "Sisselogimise teenus ei tööta, katkestan!"
LangString UAC_RIGHTS4 ${LANG_Estonian} "Ei suuda tõsta"
LangString INST_MTA_CONFLICT ${LANG_Estonian} "Erinev versioon MTA-st ($1) on juba paigaldatud valitud kausta.$\n$\nMTA eeldab, et erinevad versioonid paigaldatakse erinevatesse kaustadesse.$\nOled kindel, et tahad MTA $1 üle kirjutada asukohas $INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Estonian} "Valitud kaust ei eksisteeri.$\n$\nPalun vali GTA:SA paigaldamise kaust"
LangString INST_GTA_ERROR2 ${LANG_Estonian} "Ei suuda leida paigaldatud GTA:SA kaustast $GTA_DIR $\n$\nOled kindel, et tahad jätkata ?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Estonian} "Vali paigaldamise asukoht"
LangString INST_CHOOSE_LOC ${LANG_Estonian} "Vali kaust kuhu paigaldada ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Estonian} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} paigaldatakse järnevasse kausta.$\nPaigaldamiseks kuhugi mujale, vajuta Sirvi ja vali uus kaust$\n$\nVajuta Edasi et jätkata."
LangString INST_CHOOSE_LOC3 ${LANG_Estonian} "Soovitud kaust"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Estonian} "Sirvi..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Estonian} "Tavaline"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Estonian} "Viimati kasutatud"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Estonian} "Kohandatud"
LangString INST_CHOOSE_LOC4 ${LANG_Estonian} "Vali kaust kuhu installida ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}:"
LangString INST_LOC_OW ${LANG_Estonian} "Hoiatus: Muu versioon MTA-st ($1) on juba paigaldatud valitud kausta."
LangString INST_LOC_UPGRADE ${LANG_Estonian} "Paigaldamise tüüp: Uuendus"
LangString GET_XPVISTA_PLEASE ${LANG_Estonian} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Estonian} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString DESC_DirectX ${LANG_Estonian} "Install or update DirectX (if required)."
LangString INST_DIRECTX ${LANG_Estonian} "Install DirectX"
LangString UNINST_REQUEST_NOTE ${LANG_Estonian} "Uninstalling before update?$\r$\nIt is not necessary to uninstall before installing a new version of MTA:SA$\r$\nRun the new installer to upgrade and preserve your settings."
LangString INST_GTA_CONFLICT ${LANG_Estonian} "MTA cannot be installed into the same directory as GTA:SA.$\n$\nDo you want to use the default install directory$\n$DEFAULT_INSTDIR ?"
LangString NETTEST_TITLE1 ${LANG_Estonian} "Online update"
LangString NETTEST_TITLE2 ${LANG_Estonian} "Checking for update information"
LangString NETTEST_STATUS1 ${LANG_Estonian} "Checking for installer update information..."
LangString NETTEST_STATUS2 ${LANG_Estonian} "Please ensure your firewall is not blocking"
!insertmacro MUI_LANGUAGE "Turkish"
LangString LANGUAGE_CODE ${LANG_Turkish} "tr"
LangString GET_XPVISTA_PLEASE ${LANG_Turkish} "İndirmiş olduğunuz MTA:SA sürümü Windows XP veya Vista'yı desteklemiyor. Lütfen www.mtasa.com adresinden alternatif bir sürüm indiriniz."
LangString GET_MASTER_PLEASE ${LANG_Turkish} "MTA:SA'nın bu sürümü, Windows'un eski sürümleri için tasarlandı. Lütfen www.mtasa.com adresinden en son sürümü indiriniz."
LangString WELCOME_TEXT ${LANG_Turkish} "Bu sihirbaz kurulum ve güncelleştirme için size eşlik edecek. $(^Name) ${REVISION_TAG}\n\nKurulum başlamadan önce arka planda çalışan uygulamaları kapatmanız önerilir. Setup.\n\n[Admin access may be requested for Vista and up]\n\nDevam etmek için tıklayın."
LangString HEADER_Text ${LANG_Turkish} "Grand Theft Auto: San Andreas konumu"
LangString DIRECTORY_Text_Dest ${LANG_Turkish} "Grand Theft Auto: San Andreas klasörü"
LangString DIRECTORY_Text_Top ${LANG_Turkish} "Lütfen Grand Theft Auto: San Andreas folder.$\n oyununun kurulu olduğu yeri seçin.$\nGrand Theft Auto: San Andreas 1.0 yüklü olması gerekir. MTA:SA, diğer sürümleri desteklemez.$\n$\nKurulumu başlatmak için tıklayın."
LangString DESC_Section10 ${LANG_Turkish} "Yüklü uygulamalar için başlat menüsü grubu oluştur."
LangString DESC_Section11 ${LANG_Turkish} "MTA:SA masaüstü kısayolu oluştur."
LangString DESC_Section12 ${LANG_Turkish} "Tarayıcınızda tıklanabilir mtasa:// protokolü için kaydolun."
LangString DESC_Section13 ${LANG_Turkish} "Windows Games Tarayıcısına ekleyin. (Varsa)"
LangString DESC_DirectX ${LANG_Turkish} "DirectX'i yükle veya güncelle (eğer gerekliyse)."
LangString DESC_Section1 ${LANG_Turkish} "Temel bileşenler Multi Theft Auto çalıştırmak için gerekli."
LangString DESC_Section2 ${LANG_Turkish} "MTA : SA Değişiktir . Online oynamak için sizi bekliyor ."
LangString DESC_SectionGroupServer ${LANG_Turkish} "Multi Theft Auto Sunucusu. Bu bilgisayarınızdan oyunlar için ev sahipliği sağlar. Bu hızlı bir internet bağlantısı gerektirir."
LangString DESC_Section4 ${LANG_Turkish} "Multi Theft Auto sunucusu. Bu gerekli bir bileşenidir."
LangString DESC_Section5 ${LANG_Turkish} "MTA:SA bu sunucu için özelleştirilmiş."
LangString DESC_Section6 ${LANG_Turkish} "Bu sunucu için gerekli kaynakların listesi."
LangString DESC_Section7 ${LANG_Turkish} "Bu sunucu için oyun modları ve haritaların isteğe bağlı bir kümesidir."
LangString DESC_Section8 ${LANG_Turkish} "MTA:SA 1.0 Harita Editörü. Kendi haritalarınızı oluşturmak için kullanabilirsiniz."
LangString DESC_Section9 ${LANG_Turkish} "SDK, MTA sunucuları için ikili modül oluşturmada kullanılır. Sadece C++ dilini biliyorsanız kurun!"
LangString DESC_SectionGroupDev ${LANG_Turkish} "Geliştirici kodları ve araçlar Multi Theft Auto için mod oluşturmada yardımcı olur"
LangString DESC_SectionGroupClient ${LANG_Turkish} "İstemci bir Multi Theft Auto sunucusu üzerinde oynamak için çalışan bir programdır"
LangString INST_CLIENTSERVER ${LANG_Turkish} "İstemci ve Sunucu"
LangString INST_SERVER ${LANG_Turkish} "Sadece sunucu"
LangString INST_STARTMENU_GROUP ${LANG_Turkish} "Başlat menüsü"
LangString INST_DESKTOP_ICON ${LANG_Turkish} "Masaüstü simgesi"
LangString INST_PROTOCOL ${LANG_Turkish} "mtasa:// protokolüne kaydol"
LangString INST_GAMES_EXPLORER ${LANG_Turkish} "Oyun tarayıcısına ekle"
LangString INST_DIRECTX ${LANG_Turkish} "DirectX'i kur"
LangString INST_SEC_CLIENT ${LANG_Turkish} "Oyun istemcisi"
LangString INST_SEC_SERVER ${LANG_Turkish} "Özel sunucu"
LangString INST_SEC_CORE ${LANG_Turkish} "Çekirdek bileşenleri"
LangString INST_SEC_GAME ${LANG_Turkish} "Oyun Modülü"
LangString INFO_INPLACE_UPGRADE ${LANG_Turkish} "Yerinde yükseltme gerçekleştirme ..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Turkish} "Güncelleme Yapılıyor . Birkaç dakika alabilir ..."
LangString MSGBOX_INVALID_GTASA ${LANG_Turkish} "Grand Theft Auto : San Andreas ' ın gerekli versiyonuna ulaşılamadı.$\r$\nAncak kurulum devam edecektir.$\r$\nEğer sorunlar devam ederse terkar yükleyin."
LangString INST_SEC_CORE_RESOURCES ${LANG_Turkish} "Çekirdek Dosyaları"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Turkish} "Opyisonal Kanyaklar"
LangString INST_SEC_EDITOR ${LANG_Turkish} "Dünleyici"
LangString INST_SEC_DEVELOPER ${LANG_Turkish} "Geliştirme"
LangString UNINST_SUCCESS ${LANG_Turkish} "$(^Name) sizin bilgisayarınızdan sorunsuz bir şekilde silindi ."
LangString UNINST_FAIL ${LANG_Turkish} "Kaldırma hatası oluştu !"
LangString UNINST_REQUEST ${LANG_Turkish} "Tamamen $(^Name) bileşenlerini kaldırmak istiyormusunuz"
LangString UNINST_REQUEST_NOTE ${LANG_Turkish} "Güncellemeden önce kaldırılıyor ?$\r$\nYeni versiyonu yüklemek için MTA:SA'yı kaldırmanıza gerek yok.$\r$\nAyarlarınızı korumak ve güncellemek için yeni kurulum sihirbazını çalıştırın."
LangString UNINST_DATA_REQUEST ${LANG_Turkish} "Güncellemeden önce kaldırılıyor ?$\r$\nYeni versiyonu yüklemek için MTA:SA'yı kaldırmanıza gerek yok.$\r$\nAyarlarınızı korumak ve güncellemek için yeni kurulum sihirbazını çalıştırın."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Turkish} "Grand Theft Auto: San Andreas patch dosyası indirilemiyor "
LangString MSGBOX_PATCH_FAIL2 ${LANG_Turkish} "Grand Theft Auto: San Andreas versiyon paketin indirilemiyor"
LangString UAC_RIGHTS1 ${LANG_Turkish} "Bu kurcu admin ulaşımı gerektiriyor , tekrar deneyin"
LangString UAC_RIGHTS_UN ${LANG_Turkish} "Bu kurucu admin ulaşımı istiyor , tekrar deneyin"
LangString UAC_RIGHTS3 ${LANG_Turkish} "Oturum Açma hizmeti iptal, çalışmıyor!"
LangString UAC_RIGHTS4 ${LANG_Turkish} "Yükseltilemedi"
LangString INST_MTA_CONFLICT ${LANG_Turkish} "MTA ($1) farklı bir ana sürüm zaten yolda bulunmaktadır. $\n$\nMTA farklı yollar kurulacak büyük sürümleri için tasarlanmıştır. $\nEğer  $INSTDIR de MTA $1 üzerine yazmak istediğinizden emin misiniz?"
LangString INST_GTA_CONFLICT ${LANG_Turkish} "MTA, GTA:SA ile aynı dizine kurulamaz.$\n$\nVarsayılan dizine kurmak ister misiniz?$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Turkish} "Seçilmiş sözlük bulunamiyor.$\n$\nLütfen GTA:SA kurulum yerini seçiniz"
LangString INST_GTA_ERROR2 ${LANG_Turkish} "GTA:SA , $GTA_DIR da bulunamıyor $\n$\nDevam etmek istediğinize eminmisiniz"
LangString INST_CHOOSE_LOC_TOP ${LANG_Turkish} "Kurulum dilini seçiniz"
LangString INST_CHOOSE_LOC ${LANG_Turkish} "Lütfen ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION},kurulacak klorsörü seçiniz"
LangString INST_CHOOSE_LOC2 ${LANG_Turkish} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} kurulacaktır takip edilecek klosöre.$\nÖnemli bir klosore kurmak için Browseye basın ve başka bir klosör seçin$\n$\nDevam için Next'e basın"
LangString INST_CHOOSE_LOC3 ${LANG_Turkish} "Hedef Klosör"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Turkish} "Gözat..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Turkish} "Varolan"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Turkish} "Son kullanılmış"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Turkish} "Özel"
LangString INST_CHOOSE_LOC4 ${LANG_Turkish} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} dosyasını burada seçiniz :"
LangString INST_LOC_OW ${LANG_Turkish} "Uyarı : Önemli bir major sürümü zaten bu sürümde çıkar"
LangString INST_LOC_UPGRADE ${LANG_Turkish} "Kurulum tipi:~ ~ güncelleme"
LangString NETTEST_TITLE1 ${LANG_Turkish} "Çevrimiçi güncelleme"
LangString NETTEST_TITLE2 ${LANG_Turkish} "Güncelleme bilgileri kontrol ediliyor"
LangString NETTEST_STATUS1 ${LANG_Turkish} "Kurulum sihirbazı güncellemesi kontrol ediliyor..."
LangString NETTEST_STATUS2 ${LANG_Turkish} "Lütfen güvenlik duvarınızın engel olmadığına emin olun"
!insertmacro MUI_LANGUAGE "Romanian"
LangString LANGUAGE_CODE ${LANG_Romanian} "ro"
LangString WELCOME_TEXT ${LANG_Romanian} "Acest ghid te va ajuta la instalarea sau actualizarea $(^Name)${REVISION_TAG}\n\nEste recomandat să închizi celelalte aplicații înaintea începerii instalării.\n\n[Accesul de administrator poate fi necesar pentru Vista și versiunile ulterioare]\n\nApasă pe Următorul pentru a continua."
LangString HEADER_Text ${LANG_Romanian} "Locația Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_Romanian} "Dosarul Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Top ${LANG_Romanian} "Vă rugăm să selectați dosarul Grand Theft Auto: San Andreas.$\n$\nTREBUIE să aveți Grand Theft Auto: San Andreas 1.0 instalat pentru a folosi MTA:SA, acesta nesuportând altă versiune.$\n$\nClick pe Instalează pentru a începe."
LangString DESC_Section10 ${LANG_Romanian} "Creează un grup în Meniul Start pentru aplicațiile instalate."
LangString DESC_Section11 ${LANG_Romanian} "Creează o scurtătură pe Desktop pentru Clientul MTA:SA."
LangString DESC_Section12 ${LANG_Romanian} "Înregistrează protocolul mtasa:// pentru acces rapid din browser."
LangString DESC_Section13 ${LANG_Romanian} "Adaugă în Windows Games Explorer (dacă există)."
LangString DESC_Section1 ${LANG_Romanian} "Componentele principale, necesare pentru a rula Multi Theft Auto."
LangString DESC_Section2 ${LANG_Romanian} "Modificarea MTA:SA, ce permite jocul online."
LangString DESC_SectionGroupServer ${LANG_Romanian} "Serverul Multi Theft Auto. Acesta vă permite să găzduiți jocuri pe calculatorul dumneavoastră. Este necesară o conexiune rapidă la internet."
LangString DESC_Section4 ${LANG_Romanian} "Serverul Multi Theft Auto. Acesta este un component necesar."
LangString DESC_Section5 ${LANG_Romanian} "Modificarea MTA:SA pentru server."
LangString DESC_Section6 ${LANG_Romanian} "Acesta este un set de resurse necesare pentru serverul dumneavoastră."
LangString DESC_Section7 ${LANG_Romanian} "Acesta este un set opțional de modificări de joc și hărți pentru serverul dumneavoastră."
LangString DESC_Section8 ${LANG_Romanian} "Editorul de hărți MTA:SA 1.0. Acesta poate fi folosit pentru a vă crea propriile hărți pentru modurile de joc pentru MTA."
LangString DESC_Section9 ${LANG_Romanian} "Acesta este SDK-ul pentru crearea modulelor binare ale serverului MTA. Instalați numai dacă aveți un set de cunoștințe bun despre C++!"
LangString DESC_SectionGroupDev ${LANG_Romanian} "Cod și instrumente de dezvoltare ce ajută la crearea modificărilor pentru Multi Theft Auto."
LangString DESC_SectionGroupClient ${LANG_Romanian} "Clientul este programul pe care îl rulați pentru a juca pe un server Multi Theft Auto."
LangString INST_CLIENTSERVER ${LANG_Romanian} "Client și Server"
LangString INST_SERVER ${LANG_Romanian} "Doar server"
LangString INST_STARTMENU_GROUP ${LANG_Romanian} "Grup în Meniul Start"
LangString INST_DESKTOP_ICON ${LANG_Romanian} "Pictogramă pe Desktop"
LangString INST_PROTOCOL ${LANG_Romanian} "Înregistrează protocolul mtasa://"
LangString INST_GAMES_EXPLORER ${LANG_Romanian} "Adaugă în Games Explorer"
LangString INST_SEC_CLIENT ${LANG_Romanian} "Client de joc"
LangString INST_SEC_SERVER ${LANG_Romanian} "Server dedicat"
LangString INST_SEC_CORE ${LANG_Romanian} "Componente principale"
LangString INST_SEC_GAME ${LANG_Romanian} "Modul de joc"
LangString INFO_INPLACE_UPGRADE ${LANG_Romanian} "Se efectuează o actualizare pe loc..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Romanian} "Se actualizează permisiunile. Poate dura câteva minute..."
LangString MSGBOX_INVALID_GTASA ${LANG_Romanian} "O versiune validă a Grand Theft Auto: San Andreas pentru Windows nu a fost detectată.$\r$\nTotuși, instalarea va contiuna.$\r$\nVă rugăm să reinstalați dacă apar probleme mai târziu."
LangString INST_SEC_CORE_RESOURCES ${LANG_Romanian} "Resurse principale"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Romanian} "Resurse opționale"
LangString INST_SEC_EDITOR ${LANG_Romanian} "Editor"
LangString INST_SEC_DEVELOPER ${LANG_Romanian} "Dezvoltare"
LangString UNINST_SUCCESS ${LANG_Romanian} "$(^Name) a fost șters cu succes de pe calculatorul dumneavoastră."
LangString UNINST_FAIL ${LANG_Romanian} "Dezinstalarea a eșuat!"
LangString UNINST_REQUEST ${LANG_Romanian} "Sunteți sigur că doriți sa eliminați complet $(^Name) și toate componentele sale?"
LangString UNINST_DATA_REQUEST ${LANG_Romanian} "Doriți să vă păstrați datele (cum ar fi resursele, capturile de ecran și configurația serverului)? Dacă apăsați nu, orice resurse, configurații sau capturi de ecran create de dumneavoastră vor fi pierdute."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Romanian} "Nu s-a putut descărca fișierul patch pentru versiunea dumneavoastră de Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Romanian} "Nu s-a putut instala fișierul patch pentru versiunea dumneavoastră de Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_Romanian} "Acest program necesită acces de administrator, reîncercați"
LangString UAC_RIGHTS_UN ${LANG_Romanian} "Acest dezinstalator necesită acces de administrator, reîncercați"
LangString UAC_RIGHTS3 ${LANG_Romanian} "Serviciul Logon nu rulează, se anulează!"
LangString UAC_RIGHTS4 ${LANG_Romanian} "Nu s-a putut eleva"
LangString INST_MTA_CONFLICT ${LANG_Romanian} "O altă versiune majoră de MTA ($1) există deja în acel director.$\n$\nMTA este proiectat ca versiunile majore să fie instalate în dosare diferite.$\nSigur doriți să înlocuiți MTA $1 din $INSTDIR?"
LangString INST_GTA_ERROR1 ${LANG_Romanian} "Directorul selectat nu există.$\n$\nSelectați dosarul de instalare al GTA:SA"
LangString INST_GTA_ERROR2 ${LANG_Romanian} "Nu s-a găsit GTA:SA instalat în $GTA_DIR $\n$\nSunteți sigur că vreți să continuați?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Romanian} "Alegeți locația instalării"
LangString INST_CHOOSE_LOC ${LANG_Romanian} "Alegeți dosarul în care să instalați ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Romanian} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} va fi instalat în dosarul următor.$\nPentru a instala în alt dosar, apasă pe Răsfoiește și selectează alt dosar.$\n$\nApasă pe Următorul pentru a continua."
LangString INST_CHOOSE_LOC3 ${LANG_Romanian} "Dosarul destinație"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Romanian} "Răsfoiește..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Romanian} "Implicită"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Romanian} "Ultima folosită"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Romanian} "Diferită"
LangString INST_CHOOSE_LOC4 ${LANG_Romanian} "Selectați dosarul instalării ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}:"
LangString INST_LOC_OW ${LANG_Romanian} "Avertisment: O altă versiune majoră de MTA ($1) există deja în acel director."
LangString INST_LOC_UPGRADE ${LANG_Romanian} "Tip de instalare: Actualizare"
LangString GET_XPVISTA_PLEASE ${LANG_Romanian} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Romanian} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString DESC_DirectX ${LANG_Romanian} "Install or update DirectX (if required)."
LangString INST_DIRECTX ${LANG_Romanian} "Install DirectX"
LangString UNINST_REQUEST_NOTE ${LANG_Romanian} "Uninstalling before update?$\r$\nIt is not necessary to uninstall before installing a new version of MTA:SA$\r$\nRun the new installer to upgrade and preserve your settings."
LangString INST_GTA_CONFLICT ${LANG_Romanian} "MTA cannot be installed into the same directory as GTA:SA.$\n$\nDo you want to use the default install directory$\n$DEFAULT_INSTDIR ?"
LangString NETTEST_TITLE1 ${LANG_Romanian} "Online update"
LangString NETTEST_TITLE2 ${LANG_Romanian} "Checking for update information"
LangString NETTEST_STATUS1 ${LANG_Romanian} "Checking for installer update information..."
LangString NETTEST_STATUS2 ${LANG_Romanian} "Please ensure your firewall is not blocking"
!insertmacro MUI_LANGUAGE "Slovenian"
LangString LANGUAGE_CODE ${LANG_Slovenian} "sl"
LangString WELCOME_TEXT ${LANG_Slovenian} "Ta čarovnik vas bo vodil skozi nameščanje ali posodabljanje programa $(^Name) ${REVISION_TAG}\n\nPriporočeno je, da pred nameščanjem zaprete vse ostale aplikacije.\n\n[Možno je, da bo za operacijo potrebno dovoljenje dovoljenje administratorja v Windows Vista in novejših različicah operacijskega sistema Windows]\n\nKlikni naprej za nadaljevanje."
LangString HEADER_Text ${LANG_Slovenian} "Lokacija Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_Slovenian} "Grand Theft Auto: San Andreas mapa"
LangString DIRECTORY_Text_Top ${LANG_Slovenian} "Prosimo izberite mapo, kjer je nameščen Grand Theft Auto: San Andreas.$\n$\nNameščen mora biti Grand Theft Auto: San Andreas različica 1.0, MTA:SA ne podpira drugih različic.$\n$\nKliknite Namestitev za začetek nameščanja."
LangString DESC_Section10 ${LANG_Slovenian} "Ustvari skupino na Start meniju za nameščene aplikacije"
LangString DESC_Section11 ${LANG_Slovenian} "Ustvari namizno bližnjico za MTA:SA Klient."
LangString DESC_Section12 ${LANG_Slovenian} "Registrirajte mtasa:// protokol za klikanje po brskalniku."
LangString DESC_Section13 ${LANG_Slovenian} "Dodaj na Windows Games Explorer (če obstaja)."
LangString DESC_Section1 ${LANG_Slovenian} "Glavne komponente, ki so potrebne za zagon Multi Theft Auto."
LangString DESC_Section2 ${LANG_Slovenian} "MTA:SA modifikacija ti dovoljuje, da igraš preko interneta."
LangString DESC_SectionGroupServer ${LANG_Slovenian} "Multi Theft Auto Strežnik. To ti dovoljuje, da preko svojega računalnika gostuješ igre. Potrebna je hitra internetna povezava."
LangString DESC_Section4 ${LANG_Slovenian} "Multi Theft Auto strežnik. To je potrebna komponenta."
LangString DESC_Section5 ${LANG_Slovenian} "MTA:SA modifikacija za strežnik."
LangString DESC_Section6 ${LANG_Slovenian} "To je niz potrebnih virov za vaš strežnik."
LangString DESC_Section7 ${LANG_Slovenian} "To je neobvezen niz načinov igranja in map za vaš strežnik."
LangString DESC_Section8 ${LANG_Slovenian} "MTA:SA 1.0 Urejevalnik map. To se uporablja za ustvarjanje lastnih map za različne igralske načine v MTA."
LangString DESC_Section9 ${LANG_Slovenian} "To je SDK za ustvarjanje binarnih modulov za MTA strežnik. Namestite samo, če dobro razumete jezik C++!"
LangString DESC_SectionGroupDev ${LANG_Slovenian} "Razvojna koda in orodja ki pomagajo pri ustvarjanju modifikacij za Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_Slovenian} "Klient je program, ki ga zaženete za igranje na Multi Theft Auto strežnikih"
LangString INST_CLIENTSERVER ${LANG_Slovenian} "Klient in strežnik"
LangString INST_SERVER ${LANG_Slovenian} "Samo strežnik"
LangString INST_STARTMENU_GROUP ${LANG_Slovenian} "Skupina v start meniju"
LangString INST_DESKTOP_ICON ${LANG_Slovenian} "Namizna ikona"
LangString INST_PROTOCOL ${LANG_Slovenian} "Registriraj mtasa:// protokol"
LangString INST_GAMES_EXPLORER ${LANG_Slovenian} "Dodaj na Games Explorer"
LangString INST_SEC_CLIENT ${LANG_Slovenian} "Klient za igro"
LangString INST_SEC_SERVER ${LANG_Slovenian} "Posvečen strežnik"
LangString INST_SEC_CORE ${LANG_Slovenian} "Bistveni elementi"
LangString INST_SEC_GAME ${LANG_Slovenian} "Modul igre"
LangString INFO_INPLACE_UPGRADE ${LANG_Slovenian} "Opravljanje nadgradnje na mestu..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Slovenian} "Posodabljanje dovoljenj. To lahko traja nekaj minut..."
LangString MSGBOX_INVALID_GTASA ${LANG_Slovenian} "Veljavne Windows različice Grand Theft Auto: San Andreas ni bilo mogoče najti.$\r$\nNamestitev se bo nadaljevala.$\r$\nProsimo, da ponovno namestite program, če se pozneje pojavijo problemi."
LangString INST_SEC_CORE_RESOURCES ${LANG_Slovenian} "Ključni viri"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Slovenian} "Neobvezni viri"
LangString INST_SEC_EDITOR ${LANG_Slovenian} "Urejevalnik"
LangString INST_SEC_DEVELOPER ${LANG_Slovenian} "Razvoj"
LangString UNINST_SUCCESS ${LANG_Slovenian} "$(^Name) je bil uspešno odstranjen iz vašega računalnika."
LangString UNINST_FAIL ${LANG_Slovenian} "Med odstranitvijo je prišlo do napake!"
LangString UNINST_REQUEST ${LANG_Slovenian} "Ali ste prepričani, da želite popolnoma odstraniti $(^Name) in vse njegove komponente?"
LangString UNINST_DATA_REQUEST ${LANG_Slovenian} "Ali želite obdržati podatkovne datoteke (kot so viri, posnetki zaslona in konfiguracije strežnika)? Če kliknete ne, bodo vsi viri, konfiguracije ali posnetki zaslona ki ste jih ustvarili, izgubljeni."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Slovenian} "Ni mogoče naložiti popravka za vašo verzijo Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Slovenian} "Ni mogoče namestiti popravka za vašo verzijo Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_Slovenian} "Za nameščanje potrebujete dovoljenje administratorja, poskusite znova"
LangString UAC_RIGHTS_UN ${LANG_Slovenian} "Za odstranitev potrebujete dovoljenje administratorja, poskusite znova"
LangString UAC_RIGHTS3 ${LANG_Slovenian} "Prijavna storitev ne teče, prekinjam!"
LangString UAC_RIGHTS4 ${LANG_Slovenian} "Ni mogoče elevirati"
LangString INST_MTA_CONFLICT ${LANG_Slovenian} "Drugačna glavna različica programa MTA ($1) že obstaja na tej poti.$\n$\nGlavna različica MTA je narejena tako, da je nameščena na drugih poteh.$\nAli ste prepričani da želite prepisati MTA $1 v $INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Slovenian} "Izbrana pot ne obstaja.$\n$\nProsimo, izberite pot, kjer je nameščen GTA:SA"
LangString INST_GTA_ERROR2 ${LANG_Slovenian} "Ni bilo mogoče najti GTA:SA v $GTA_DIR $\n$\nAli ste prepričani da želite nadaljevati ?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Slovenian} "Izberite lokacijo namestitve"
LangString INST_CHOOSE_LOC ${LANG_Slovenian} "Izberite mapo kamor hočete namestiti ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Slovenian} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} bo nameščen v naslednjo mapo.$\nČe ga želite namestiti v drugo mapo, kliknite Išči in izberite drugo mapo.$\n$\nKliknite Naprej za nadaljevanje."
LangString INST_CHOOSE_LOC3 ${LANG_Slovenian} "Ciljna mapa"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Slovenian} "Išči..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Slovenian} "Privzeto"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Slovenian} "Nazadnje uporabljeno"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Slovenian} "Po meri"
LangString INST_CHOOSE_LOC4 ${LANG_Slovenian} "Izberite mapo kjer želite namestiti ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} :"
LangString INST_LOC_OW ${LANG_Slovenian} "Opozorilo: Na tej poti že obstaja glavna različica MTA ($1) ."
LangString INST_LOC_UPGRADE ${LANG_Slovenian} "Vrsta namestitve: Nadgradnja"
LangString GET_XPVISTA_PLEASE ${LANG_Slovenian} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Slovenian} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString DESC_DirectX ${LANG_Slovenian} "Install or update DirectX (if required)."
LangString INST_DIRECTX ${LANG_Slovenian} "Install DirectX"
LangString UNINST_REQUEST_NOTE ${LANG_Slovenian} "Uninstalling before update?$\r$\nIt is not necessary to uninstall before installing a new version of MTA:SA$\r$\nRun the new installer to upgrade and preserve your settings."
LangString INST_GTA_CONFLICT ${LANG_Slovenian} "MTA cannot be installed into the same directory as GTA:SA.$\n$\nDo you want to use the default install directory$\n$DEFAULT_INSTDIR ?"
LangString NETTEST_TITLE1 ${LANG_Slovenian} "Online update"
LangString NETTEST_TITLE2 ${LANG_Slovenian} "Checking for update information"
LangString NETTEST_STATUS1 ${LANG_Slovenian} "Checking for installer update information..."
LangString NETTEST_STATUS2 ${LANG_Slovenian} "Please ensure your firewall is not blocking"
!insertmacro MUI_LANGUAGE "Dutch"
LangString LANGUAGE_CODE ${LANG_Dutch} "nl"
LangString WELCOME_TEXT ${LANG_Dutch} "Deze wizard zal u begeleiden door de installatie of update van $(^Name) ${REVISION_TAG}\n\nHet is aanbevolen om alle andere applicaties te sluiten voordat u de Installatie start.\n\n[Administrator rechten kunnen worden opgevraagd voor Vista en nieuwer]\n\nKlik op Volgende om door te gaan."
LangString HEADER_Text ${LANG_Dutch} "Locatie van Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_Dutch} "Map met Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Top ${LANG_Dutch} "Selecteer het bestand waar Grand Theft Auto: San Andreas zich bevind.$\n$\n Je MOET Grand Theft Auto: San Andreas 1.0 geïnstalleerd hebben om MTA:SA te gebruiken, MTA:SA ondersteund geen andere versies.$\n$\n Klik op Installeer om met de installatie te beginnen."
LangString DESC_Section10 ${LANG_Dutch} "Maak een groep in het Start Menu aan voor de geïnstalleerde applicatie"
LangString DESC_Section11 ${LANG_Dutch} "Maak een snelkoppeling aan op het bureaublad voor MTA:SA."
LangString DESC_Section12 ${LANG_Dutch} "Registreer het mtasa:// protocol voor snelle toegang vanuit een webbrowser."
LangString DESC_Section13 ${LANG_Dutch} "Voeg toe aan de Windows Spellen verkenner (indien aanwezig)."
LangString DESC_Section1 ${LANG_Dutch} "De kern elementen die vereist zijn om Multi Theft Auto te kunnen spelen."
LangString DESC_Section2 ${LANG_Dutch} "De MTA:SA modificatie, laat je toe online te spelen."
LangString DESC_SectionGroupServer ${LANG_Dutch} "De Multi Theft Auto Server. Hiermee kan je spellen van op je computer aanbieden. Dit vereist een snelle internet verbinding."
LangString DESC_Section4 ${LANG_Dutch} "De Mulit Theft Auto server. Dit is een vereist onderdeel."
LangString DESC_Section5 ${LANG_Dutch} "De MTA:SA modificatie voor de server."
LangString DESC_Section6 ${LANG_Dutch} "Dit is een set van vereiste bronnen voor je server."
LangString DESC_Section7 ${LANG_Dutch} "Dit is een optionele set van spelmodi en werelden voor je server."
LangString DESC_Section8 ${LANG_Dutch} "De MTA:SA 1.0 Map Editor.  Dit kan gebruikt worden om je eigen wereld mee te bouwen voor gebruik in spelmodi in MTA."
LangString DESC_Section9 ${LANG_Dutch} "Met deze SDK kan je binaire modules bouwen voor de MTA server. Enkel te installeren indien je een goede kennis van C++ hebt!"
LangString DESC_SectionGroupDev ${LANG_Dutch} "Ontwikkel code en gereedschap om te helpen bij het bouwen van mods voor Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_Dutch} "De client is het programma dat je start om te spelen op een Multi Theft Auto server"
LangString INST_CLIENTSERVER ${LANG_Dutch} "Client en Server"
LangString INST_SERVER ${LANG_Dutch} "Enkel de server"
LangString INST_STARTMENU_GROUP ${LANG_Dutch} "Start menu groep"
LangString INST_DESKTOP_ICON ${LANG_Dutch} "Bureaublad icoon"
LangString INST_PROTOCOL ${LANG_Dutch} "Registreer mtasa:// protocol"
LangString INST_GAMES_EXPLORER ${LANG_Dutch} "Voeg toe aan de Spellen verkenner"
LangString INST_SEC_CLIENT ${LANG_Dutch} "Client"
LangString INST_SEC_SERVER ${LANG_Dutch} "Losstaande server"
LangString INST_SEC_CORE ${LANG_Dutch} "Essentiële onderdelen"
LangString INST_SEC_GAME ${LANG_Dutch} "Spel module"
LangString INFO_INPLACE_UPGRADE ${LANG_Dutch} "Vervangende upgrade aan het uitvoeren..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Dutch} "Aanpassen van bevoegdheden. Dit kan enkele minuten duren..."
LangString MSGBOX_INVALID_GTASA ${LANG_Dutch} "Een geldige Windows versie van Grand Theft Auto: San Andreas is niet gedetecteerd.$\r$\nMaar de installatie gaat door.$\r$\nAlstublieft opnieuw installeren als er enige problemen zijn later."
LangString INST_SEC_CORE_RESOURCES ${LANG_Dutch} "Hoofd Bronnen"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Dutch} "Optionele bronnen"
LangString INST_SEC_EDITOR ${LANG_Dutch} "Editor"
LangString INST_SEC_DEVELOPER ${LANG_Dutch} "Ontwikkeling"
LangString UNINST_SUCCESS ${LANG_Dutch} "$(^Name) was succesvol verwijderd van uw computer."
LangString UNINST_FAIL ${LANG_Dutch} "De-installatie heeft gefaald!"
LangString UNINST_REQUEST ${LANG_Dutch} "Ben je zeker dat je $(^Name) en alle bijhorende onderdelen volledig wenst te verwijderen?"
LangString UNINST_DATA_REQUEST ${LANG_Dutch} "Wil je de data files behouden (zoals resources, screenshots en server configuration)? Als je op nee klikt, alle resources, configuraties of screenshots die gemaakt zijn zullen worden verwijdert."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Dutch} "Niet mogelijk om het patch bestand voor deze versie van Grand Theft Auto: San Andreas te downloaden"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Dutch} "Niet mogelijk om het patch bestand voor deze versie van Grand Theft Auto: San Andreas te installeren"
LangString UAC_RIGHTS1 ${LANG_Dutch} "Deze installer heeft administrator rechten nodig, probeer opnieuw"
LangString UAC_RIGHTS_UN ${LANG_Dutch} "Deze uninstaller heeft administrator rechten nodig, probeer opnieuw"
LangString UAC_RIGHTS3 ${LANG_Dutch} "Aanmeld service is niet gestart, afbreken!"
LangString UAC_RIGHTS4 ${LANG_Dutch} "Verheffing niet mogelijk"
LangString INST_MTA_CONFLICT ${LANG_Dutch} "Een andere versie van MTA ($1) bestaat al in dat pad.$\n$\nMTA is onworpen om andere versies in verschillende paden te installeren.$\nWeet je zeker dat je MTA $1 op $INSTDIR wilt overschrijven ?"
LangString INST_GTA_ERROR1 ${LANG_Dutch} "Het geselecteerde bestand bestaat niet.$\n$\n Selecteer de GTA:SA Installatie map"
LangString INST_GTA_ERROR2 ${LANG_Dutch} "Kies map waar ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} geïnstalleerd in moet worden"
LangString INST_CHOOSE_LOC_TOP ${LANG_Dutch} "Selecteer Installatie Locatie"
LangString INST_CHOOSE_LOC ${LANG_Dutch} "Kies map waar ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} geïnstalleerd in moet worden"
LangString INST_CHOOSE_LOC2 ${LANG_Dutch} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} wordt in de volgende map geïnstalleerd.$\nOm dit in een andere map te installeren, klik Bladeren en selecteer een andere map.$\n$\nKlik op volgende om door te gaan."
LangString INST_CHOOSE_LOC3 ${LANG_Dutch} "Doelmap"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Dutch} "Bladeren..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Dutch} "Standaard locatie"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Dutch} "Laatst gebruikt"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Dutch} "Aangepast"
LangString INST_CHOOSE_LOC4 ${LANG_Dutch} "Selecteer de map om ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} in te installeren:"
LangString INST_LOC_OW ${LANG_Dutch} "Waarschuwing: Een andere grote versie van MTA ($1) bestaat al op die locatie."
LangString INST_LOC_UPGRADE ${LANG_Dutch} "Installatie type:  Bijwerken"
LangString GET_XPVISTA_PLEASE ${LANG_Dutch} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Dutch} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString DESC_DirectX ${LANG_Dutch} "Install or update DirectX (if required)."
LangString INST_DIRECTX ${LANG_Dutch} "Install DirectX"
LangString UNINST_REQUEST_NOTE ${LANG_Dutch} "Uninstalling before update?$\r$\nIt is not necessary to uninstall before installing a new version of MTA:SA$\r$\nRun the new installer to upgrade and preserve your settings."
LangString INST_GTA_CONFLICT ${LANG_Dutch} "MTA cannot be installed into the same directory as GTA:SA.$\n$\nDo you want to use the default install directory$\n$DEFAULT_INSTDIR ?"
LangString NETTEST_TITLE1 ${LANG_Dutch} "Online update"
LangString NETTEST_TITLE2 ${LANG_Dutch} "Checking for update information"
LangString NETTEST_STATUS1 ${LANG_Dutch} "Checking for installer update information..."
LangString NETTEST_STATUS2 ${LANG_Dutch} "Please ensure your firewall is not blocking"
!insertmacro MUI_LANGUAGE "Bulgarian"
LangString LANGUAGE_CODE ${LANG_Bulgarian} "bg"
LangString GET_XPVISTA_PLEASE ${LANG_Bulgarian} "Версията на MTA:SA, която сте изтеглили не поддържа Windows XP или Vista. Моля изтеглете алтернативна версия от www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Bulgarian} "Версията на MTA:SA е изработена за по-стари версии на Windows. Моля изтеглете най-новата версия от www.mtasa.com."
LangString WELCOME_TEXT ${LANG_Bulgarian} "Този помощник ще ви води през инсталацията или обновяване на $(^Name) ${REVISION_TAG}\n\nПрепоръчително е да затворите всички други приложения, преди да започнете инсталацията.\n\n[Администраторски достъп може да бъде поискан за Vista и нагоре]\n\nЦъкнете Продължи за да продължите."
LangString HEADER_Text ${LANG_Bulgarian} "Папката на Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_Bulgarian} "Папката на Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Top ${LANG_Bulgarian} "Моля изберете папката на Grand Theft Auto: San Andreas.$\n$\nВие ТРЯБВА да имате have Grand Theft Auto: San Andreas 1.0 инсталирана за да играете MTA:SA, защото тя не поддържа други версии.$\n$\nЦъкнете Инсталирай за да продължите."
LangString DESC_Section10 ${LANG_Bulgarian} "Създай Стар Меню група за инсталирани програми"
LangString DESC_Section11 ${LANG_Bulgarian} "Създай пряк път на работния плот за MTA:SA Клиента."
LangString DESC_Section12 ${LANG_Bulgarian} "Регистрирайте mtasa:// протокол за по-лесно свързване към сайтове."
LangString DESC_Section13 ${LANG_Bulgarian} "Добави към Windows Games Explorer (ако съществува)."
LangString DESC_DirectX ${LANG_Bulgarian} "Инсталирай или обнови DirectX (ако има нужда)."
LangString DESC_Section1 ${LANG_Bulgarian} "Основните компоненти, необходими за стартиране Multi Theft Auto."
LangString DESC_Section2 ${LANG_Bulgarian} "MTA: SA е модификация, която Ви позволява да играете онлайн."
LangString DESC_SectionGroupServer ${LANG_Bulgarian} "Multi Theft Auto сървър. Това Ви позволява да поддържате сървър от вашия компютър. Изисква се бърз интернет."
LangString DESC_Section4 ${LANG_Bulgarian} "Multi Theft Auto сървър. Това е задължителен компонент"
LangString DESC_Section5 ${LANG_Bulgarian} "MTA: SA модификация на сървъра."
LangString DESC_Section6 ${LANG_Bulgarian} "Това е набор от необходимите ресурси за вашия сървър."
LangString DESC_Section7 ${LANG_Bulgarian} "Това е допълнителен набор от видовете за игра и карти за вашия сървър."
LangString DESC_Section8 ${LANG_Bulgarian} "MTA: SA 1.0 Map Editor. Това може да се използва за създадаване на собствени карти за различните режими на игра в МТА."
LangString DESC_Section9 ${LANG_Bulgarian} "Това е SDK за създаване на двукомпонентни модули за сървър на МТА. Инсталирайте само ако имате добро разбиране на C++!"
LangString DESC_SectionGroupDev ${LANG_Bulgarian} "Разработен код и инструменти, които помагат при направата на модове за Multi Theft Auto."
LangString DESC_SectionGroupClient ${LANG_Bulgarian} "Клиентът е пограмата, която използвате за да играете в Multi Theft Auto сървър"
LangString INST_CLIENTSERVER ${LANG_Bulgarian} "Клиент и Сървър"
LangString INST_SERVER ${LANG_Bulgarian} "Само Сървър"
LangString INST_STARTMENU_GROUP ${LANG_Bulgarian} "Група в началното меню"
LangString INST_DESKTOP_ICON ${LANG_Bulgarian} "Икона на работния плот"
LangString INST_PROTOCOL ${LANG_Bulgarian} "Регистрирай mtasa:// протокол"
LangString INST_GAMES_EXPLORER ${LANG_Bulgarian} "Добави в Games Explorer"
LangString INST_DIRECTX ${LANG_Bulgarian} "Инсталирай DirectX"
LangString INST_SEC_CLIENT ${LANG_Bulgarian} "Игрален клиент"
LangString INST_SEC_SERVER ${LANG_Bulgarian} "Собствен сървър"
LangString INST_SEC_CORE ${LANG_Bulgarian} "Основни компоненти"
LangString INST_SEC_GAME ${LANG_Bulgarian} "Игрален модул"
LangString INFO_INPLACE_UPGRADE ${LANG_Bulgarian} "Изпълянване на надграждане..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Bulgarian} "Актуализиране на разрешения. Това може да отнеме няколко минути ..."
LangString MSGBOX_INVALID_GTASA ${LANG_Bulgarian} "Не е намерена валидна Windows версия на Grand Theft Auto: San Andreas.$\r$\nВъпреки това, инсталацията ще продължи.$\r$\nМоля, преинсталирайте ако съществуват проблеми в бъдеще."
LangString INST_SEC_CORE_RESOURCES ${LANG_Bulgarian} "Основни Ресурси"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Bulgarian} "Допълнителни Ресурси"
LangString INST_SEC_EDITOR ${LANG_Bulgarian} "Редактор"
LangString INST_SEC_DEVELOPER ${LANG_Bulgarian} "Разработка"
LangString UNINST_SUCCESS ${LANG_Bulgarian} "$(^Name) беше успешно премахнат от вашия компютър."
LangString UNINST_FAIL ${LANG_Bulgarian} "Грешка при деинсталиране!"
LangString UNINST_REQUEST ${LANG_Bulgarian} "Сигурни ли сте, че искате да премахнете $(^Name) и всички компоненти свързани с него?"
LangString UNINST_REQUEST_NOTE ${LANG_Bulgarian} "Деинсталиране преди актуализация?$\r$\nНе е необходимо да деинсталирате преди да инсталирате нова версия на MTA:SA$\r$\nСтартирайте новия инсталатор за да обновите и запазите настройките си."
LangString UNINST_DATA_REQUEST ${LANG_Bulgarian} "Бихте ли искали да запазите вашите файлове с данни (като ресурси, екранни снимки и сървъри)? Ако щракнете не, всички ресурси, конфигурации и снимки, които сте създали ще бъдат премахнати."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Bulgarian} "Проблем при свалянето на пач файл за вашата версия на Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Bulgarian} "Проблем при инсталирането на пач файла за вашата версия на Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_Bulgarian} "Този инсталатор изисква администраторски права, пробвайте пак."
LangString UAC_RIGHTS_UN ${LANG_Bulgarian} "Деинсталаторът изисква администраторски права, пробвайте пак."
LangString UAC_RIGHTS3 ${LANG_Bulgarian} "Вписващата услуга не работи, прекратяване!"
LangString UAC_RIGHTS4 ${LANG_Bulgarian} "Невъзможно издигане"
LangString INST_MTA_CONFLICT ${LANG_Bulgarian} "Друга версия на MTA:SA ($1) вече съществува в тази папка.$\n$\nМТА:SA е предназначена други версии да бъдат инсталирани в различни папки.$\nНаистина ли искате да презапишете MTA $1 в $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_Bulgarian} "MTA не може да бъде инсталирана в същата папка с GTA:SA.$\n$\nИскате ли да се използва инсталационната директория по подразбиране$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Bulgarian} "Избраната директория не съществува.$\n$\nМоля изберете папката, която съдържа GTA:SA"
LangString INST_GTA_ERROR2 ${LANG_Bulgarian} "Проблем с намирането на GTA: SA инсталиран в $GTA_DIR $\n$\nСигурни ли сте че искате да продължите?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Bulgarian} "Изберете място за инсталиране"
LangString INST_CHOOSE_LOC ${LANG_Bulgarian} "Изберете папката, в която да инсталирате ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Bulgarian} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} ще бъдат инсталирани в избраната папка.$\nЗа да инсталирате в друга папка, натиснете Търси и изберете друга папка.$\n$\nНатиснете Продължи за да продължите."
LangString INST_CHOOSE_LOC3 ${LANG_Bulgarian} "Целева Папка"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Bulgarian} "Преглед..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Bulgarian} "По подразбиране"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Bulgarian} "Последно използван/а"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Bulgarian} "Персонализиран"
LangString INST_CHOOSE_LOC4 ${LANG_Bulgarian} "Изберете папка, за инсталиране на ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} в:"
LangString INST_LOC_OW ${LANG_Bulgarian} "Внимание: Друга версия на MTA ($1) вече съществува в тази папка."
LangString INST_LOC_UPGRADE ${LANG_Bulgarian} "Начин на инсталация: Надграждане"
LangString NETTEST_TITLE1 ${LANG_Bulgarian} "Онлайн обновяване"
LangString NETTEST_TITLE2 ${LANG_Bulgarian} "Проверка на информация за обновление"
LangString NETTEST_STATUS1 ${LANG_Bulgarian} "Проверка на информация за обновления на инсталера..."
LangString NETTEST_STATUS2 ${LANG_Bulgarian} "Моля, проверете дали защитната стена не блокира"
!insertmacro MUI_LANGUAGE "Vietnamese"
LangString LANGUAGE_CODE ${LANG_Vietnamese} "vi"
LangString GET_XPVISTA_PLEASE ${LANG_Vietnamese} "Phiên bản MTA:SA này không hỗ trợ Windows XP và Vista. Truy cập vào trang www.mtasa.com hoặc mtasa.vn để tải về phiên bản phù hợp với máy tính của bạn."
LangString GET_MASTER_PLEASE ${LANG_Vietnamese} "Phiên bản MTA:SA này chỉ có thể chạy trên các phiên bản Windows cũ hơn. Vui lòng truy cập vào website www.mtasa.com hoặc mtasa.vn để tải về phiên bản mới nhất."
LangString WELCOME_TEXT ${LANG_Vietnamese} "Thuật sỹ này sẽ hướng dẫn bạn trong quá trình cài đặt hoặc cập nhật $(^Name) ${REVISION_TAG}\n\nBạn nên tắt tất cả các chương trình khác trước khi bắt đầu cài đặt.\n\n[Nếu bạn sử dụng Windows Vista hoặc mới hơn thì nên chạy trên quyền Admin]\n\nNhấn Next để tiếp tục."
LangString HEADER_Text ${LANG_Vietnamese} "Chọn nơi cài đặt Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_Vietnamese} "Thư mục đã cài Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Top ${LANG_Vietnamese} "Hãy chọn thư mục chứa game Grand Theft Auto: San Andreas.$\n$\nĐể có thể chơi được MTA:SA thì bạn PHẢI có game Grand Theft Auto: San Andreas phiên bản 1.0 sẵn trong máy tính, ngoài ra MTA:SA sẽ không hỗ trợ phiên bản khác.$\n$\nChọn $\"Install$\" để bắt đầu cài đặt."
LangString DESC_Section10 ${LANG_Vietnamese} "Tạo nhóm mục ở Start Menu cho các phần mềm đã được cài đặt"
LangString DESC_Section11 ${LANG_Vietnamese} "Tạo icon MTA:SA ngoài Desktop"
LangString DESC_Section12 ${LANG_Vietnamese} "Đăng ký giao thức kết nối mtasa:// để có thể sử dụng ở trình duyệt web."
LangString DESC_Section13 ${LANG_Vietnamese} "Thêm vào Windows Games Explorer (nếu có)."
LangString DESC_DirectX ${LANG_Vietnamese} "Cài đặt hoặc cập nhật DirectX (nếu cần thiết)."
LangString DESC_Section1 ${LANG_Vietnamese} "Các thành phần lõi cần thiết để chạy Multi Theft Auto."
LangString DESC_Section2 ${LANG_Vietnamese} "The MTA:SA modification, cho phép bạn chơi trực tuyến."
LangString DESC_SectionGroupServer ${LANG_Vietnamese} "The Multi Theft Auto Server. Cho phép bạn tự tạo server MTA:SA từ chính máy tính của bạn. Cần có đường truyền mạng nhanh."
LangString DESC_Section4 ${LANG_Vietnamese} "The Multi Theft Auto server. Đây là thành phần cần thiết."
LangString DESC_Section5 ${LANG_Vietnamese} "Phiên bản MTA:SA modification cho server"
LangString DESC_Section6 ${LANG_Vietnamese} "Đây là một bộ resources cần thiết cho server của bạn."
LangString DESC_Section7 ${LANG_Vietnamese} "Đây là một bộ tùy chọn chế độ (gamemodes) và bản đồ (maps) cho server của bạn."
LangString DESC_Section8 ${LANG_Vietnamese} "The MTA:SA 1.0 Map Editor.  Được sử dụng để bạn có thể tạo bản đồ tùy thích sử dụng trong các chế độ chơi cho MTA."
LangString DESC_Section9 ${LANG_Vietnamese} "Đây là bộ SDK dùng để tạo các mô-đun binary cho server MTA. Cài đặt nó nếu bạn có thể lập trình bằng C++!"
LangString DESC_SectionGroupDev ${LANG_Vietnamese} "Viết code và các công cụ hỗ trợ trong việc tạo ra các mods cho Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_Vietnamese} "Client là phần mềm giúp bạn kết nối đến server Multi Theft Auto"
LangString INST_CLIENTSERVER ${LANG_Vietnamese} "Client và Server"
LangString INST_SERVER ${LANG_Vietnamese} "Server"
LangString INST_STARTMENU_GROUP ${LANG_Vietnamese} "Nhóm mục Start menu"
LangString INST_DESKTOP_ICON ${LANG_Vietnamese} "Desktop icon"
LangString INST_PROTOCOL ${LANG_Vietnamese} "Đăng ký giao thức mtasa:// protocol"
LangString INST_GAMES_EXPLORER ${LANG_Vietnamese} "Thêm vào Games Explorer"
LangString INST_DIRECTX ${LANG_Vietnamese} "Cài đặt DirectX"
LangString INST_SEC_CLIENT ${LANG_Vietnamese} "Game client"
LangString INST_SEC_SERVER ${LANG_Vietnamese} "Dedicated server"
LangString INST_SEC_CORE ${LANG_Vietnamese} "Các thành phần lõi"
LangString INST_SEC_GAME ${LANG_Vietnamese} "Mô-đun game"
LangString INFO_INPLACE_UPGRADE ${LANG_Vietnamese} "Đang thực hiện nâng cấp..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Vietnamese} "Đang cập nhật quyền hạn. Có thể mất vài phút..."
LangString MSGBOX_INVALID_GTASA ${LANG_Vietnamese} "Không tìm thấy phên bản Windows phù hợp với Grand Theft Auto: San Andreas.$\r$\nQuá trình cài đặt vẫn sẽ tiếp tục.$\r$\nVui lòng cài đặt lại nếu bị lỗi trong quá trình cài đặt."
LangString INST_SEC_CORE_RESOURCES ${LANG_Vietnamese} "Core Resources"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Vietnamese} "Optional Resources"
LangString INST_SEC_EDITOR ${LANG_Vietnamese} "Editor"
LangString INST_SEC_DEVELOPER ${LANG_Vietnamese} "Development"
LangString UNINST_SUCCESS ${LANG_Vietnamese} "$(^Name) đã được xóa thành công khỏi máy tính của bạn."
LangString UNINST_FAIL ${LANG_Vietnamese} "Gỡ bỏ phần mềm thất bại!"
LangString UNINST_REQUEST ${LANG_Vietnamese} "Bạn có muốn xóa hoàn toàn $(^Name) và tất cả các thành phần khác của nó?"
LangString UNINST_REQUEST_NOTE ${LANG_Vietnamese} "Gỡ bỏ trước khi cập nhật?$\r$\nBạn không cần thiết phải gỡ bỏ MTA:SA cũ trước khi cài đặt phiên bản MTA:SA mới$\r$\nChạy file cài đặt để nâng cấp và sao lưu các tùy chọn của bạn."
LangString UNINST_DATA_REQUEST ${LANG_Vietnamese} "Bạn có muốn giữ lại dữ liệu của bạn (Chẳng hạn như resources, ảnh chụp màn hình trong game và các tùy chỉnh server)? Nếu bạn chọn không, thì resources, các tùy chỉnh hay ảnh chụp màn hình trong game mà bạn đang có sẽ bị xóa."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Vietnamese} "Không thể tải bản patch cho phiên bản Grand Theft Auto: San Andreas của bạn"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Vietnamese} "Không thể cài đặt bản patch cho phiên bản Grand Theft Auto: San Andreas của bạn"
LangString UAC_RIGHTS1 ${LANG_Vietnamese} "Trình cài đặt này cần quyền Administrator, vui lòng thử lại"
LangString UAC_RIGHTS_UN ${LANG_Vietnamese} "Trình gỡ bỏ này cần quyền Administrator, vui lòng thử lại"
LangString UAC_RIGHTS3 ${LANG_Vietnamese} "Login service không hoạt động, đang hủy lệnh!"
LangString UAC_RIGHTS4 ${LANG_Vietnamese} "Unable to elevate"
LangString INST_MTA_CONFLICT ${LANG_Vietnamese} "Một phiên bản khác của MTA ($1) đã được cài đặt tại mục đó rồi.$\n$\nMTA phiên bản chính được cài đặt ở đường dẫn khác.$\nBạn có muốn ghi đè MTA $1 vào mục $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_Vietnamese} "MTA không thể cài đặt trong cùng một thư mục với GTA:SA.$\n$\nBạn có muốn cài đặt vào mục mặt định$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Vietnamese} "Thư mục bạn vừa chọn không tồn tại.$\n$\nHãy chọn đường dẫn đến thư mục cài đặt GTA:SA"
LangString INST_GTA_ERROR2 ${LANG_Vietnamese} "Không tìm thấy GTA:SA tại mục $GTA_DIR $\n$\nBạn có muốn tiếp tục?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Vietnamese} "Chọn đường dẫn cài đặt"
LangString INST_CHOOSE_LOC ${LANG_Vietnamese} "Chọn thư mục để cài đặt ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Vietnamese} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} sẽ được cài đặt vào thư mục sau.$\nNếu bạn muốn cài đặt vào thư mục khác, click vào Tìm duyệt và chọn một thư mục mà bạn muốn.$\n$\n Nhấn Next để tiếp tục."
LangString INST_CHOOSE_LOC3 ${LANG_Vietnamese} "Thư cài đặt"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Vietnamese} "Tìm duyệt..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Vietnamese} "Mặc định"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Vietnamese} "Như cũ"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Vietnamese} "Tùy chọn"
LangString INST_CHOOSE_LOC4 ${LANG_Vietnamese} "Chọn thư mục để cài đặt ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} vào trong:"
LangString INST_LOC_OW ${LANG_Vietnamese} "Cảnh báo: Một phiên bản chính khác của MTA ($1) đã được cài đặt ở đường dẫn đó."
LangString INST_LOC_UPGRADE ${LANG_Vietnamese} "Loại cài đặt:  Nâng cấp"
LangString NETTEST_TITLE1 ${LANG_Vietnamese} "Cập nhật trực tuyến"
LangString NETTEST_TITLE2 ${LANG_Vietnamese} "Đang kiểm tra thông tin cập nhật"
LangString NETTEST_STATUS1 ${LANG_Vietnamese} "Đang kiểm tra thông tin cập nhật của trình cài đặt..."
LangString NETTEST_STATUS2 ${LANG_Vietnamese} "Chắc chắc rằng tường lửa (firewall) của máy bạn không chặn phần mềm này"
!insertmacro MUI_LANGUAGE "Hungarian"
LangString LANGUAGE_CODE ${LANG_Hungarian} "hu"
LangString WELCOME_TEXT ${LANG_Hungarian} "Ez a varázsló segítségedre lesz, hogy telepítsd vagy frissítsd a(z) $(^Name) ${REVISION_TAG}\n\nAjánlott, hogy zárj be minden más alkalmazást a telepítés indítása előtt.\n\n[Vista és annál újabb rendszereken rendszergazdai jogosultság szükséges.]\n\nKattints a Tovább gombra a folytatáshoz!"
LangString HEADER_Text ${LANG_Hungarian} "Grand Theft Auto: San Andreas főkönyvtára"
LangString DIRECTORY_Text_Dest ${LANG_Hungarian} "Grand Theft Auto: San Andreas mappája"
LangString DIRECTORY_Text_Top ${LANG_Hungarian} "Kérlek válaszd ki a Grand Theft Auto: San Andreas mappáját.$\n$\nAz MTA:SA kizárólag a Grand Theft Auto: San Andreas 1.0 verzióját támogatja.$\n$\nKattints a Telepítés gombra a telepítés megkezdéséhez."
LangString DESC_Section10 ${LANG_Hungarian} "Start Menü ikon létrehozása a telepített alkalmazásoknak."
LangString DESC_Section11 ${LANG_Hungarian} "Ikon létrehozása az asztalon az MTA:SA Kliensnek."
LangString DESC_Section12 ${LANG_Hungarian} "mtasa:// protokoll hozzáadása a böngésződhöz."
LangString DESC_Section13 ${LANG_Hungarian} "MTA:SA hozzáadása a Windows Játékböngészőhöz (ha elérhető)."
LangString DESC_Section1 ${LANG_Hungarian} "Az alapvető összetevők szükségesek a Multi Theft Auto futtatásához."
LangString DESC_Section2 ${LANG_Hungarian} "Az MTA:SA módosításai lehetővé teszik az online játékot."
LangString DESC_SectionGroupServer ${LANG_Hungarian} "A Multi Theft Auto Szerver lehetővé teszi, hogy szervert indíts a saját gépedről. Ehhez gyors internetkapcsolat szükséges."
LangString DESC_Section4 ${LANG_Hungarian} "Multi Theft Auto szerver. Ez egy szükséges összetevő."
LangString DESC_Section5 ${LANG_Hungarian} "Az MTA:SA módosításai a szerverhez."
LangString DESC_Section6 ${LANG_Hungarian} "Ez egy beállítás a szükséges erőforrásokhoz a szerveredhez."
LangString DESC_Section7 ${LANG_Hungarian} "Ez egy opcionális beállítás a játékmódokhoz és pályákhoz a szerveredhez."
LangString DESC_Section8 ${LANG_Hungarian} "MTA:SA 1.0 Pályakészítő. A saját pályáid megépítésére szolgál, melyeket különböző MTA-s játékmódokban használhatsz."
LangString DESC_Section9 ${LANG_Hungarian} "Ez egy SDK, amely létrehozza a bináris modulokat az MTA szerverhez. Csak akkor telepítsd, ha értesz is a C++-hoz!"
LangString DESC_SectionGroupDev ${LANG_Hungarian} "Fejlesztői kód és eszközök Multi Theft Auto módok létrehozásához"
LangString DESC_SectionGroupClient ${LANG_Hungarian} "A kliens egy program, amellyel játszhatsz Multi Theft Auto szervereken."
LangString INST_CLIENTSERVER ${LANG_Hungarian} "Kliens és Szerver"
LangString INST_SERVER ${LANG_Hungarian} "Csak szerver"
LangString INST_STARTMENU_GROUP ${LANG_Hungarian} "Start menü ikon"
LangString INST_DESKTOP_ICON ${LANG_Hungarian} "Asztali ikon"
LangString INST_PROTOCOL ${LANG_Hungarian} "mtasa:// protokoll regisztráció"
LangString INST_GAMES_EXPLORER ${LANG_Hungarian} "Hozzáadás a játéktallózóhoz"
LangString INST_DIRECTX ${LANG_Hungarian} "DirectX telepítés"
LangString INST_SEC_CLIENT ${LANG_Hungarian} "Játék kliens"
LangString INST_SEC_SERVER ${LANG_Hungarian} "Dedikált szerver"
LangString INST_SEC_CORE ${LANG_Hungarian} "Alapvető összetevők"
LangString INST_SEC_GAME ${LANG_Hungarian} "Játék modul"
LangString INFO_INPLACE_UPGRADE ${LANG_Hungarian} "A frissítés előkészítése..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Hungarian} "Engedélyek frissítése. Ez eltarthat néhány percig..."
LangString MSGBOX_INVALID_GTASA ${LANG_Hungarian} "Az eredeti Grand Theft Auto: San Andreas nem található.$\r$\nAzonban a telepítés folytatódik.$\r$\nTelepítsd újra, ha a későbbiekben probléma merül fel."
LangString INST_SEC_CORE_RESOURCES ${LANG_Hungarian} "Alapvető erőforrások"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Hungarian} "Opcionális erőforrások"
LangString INST_SEC_EDITOR ${LANG_Hungarian} "Szerkesztő"
LangString INST_SEC_DEVELOPER ${LANG_Hungarian} "Fejlesztés"
LangString UNINST_SUCCESS ${LANG_Hungarian} "$(^Name) sikeresen el lett távolítva a számítógépedről."
LangString UNINST_FAIL ${LANG_Hungarian} "Eltávolítás sikertelen!"
LangString UNINST_REQUEST ${LANG_Hungarian} "Biztosan el szeretné távolítani $(^Name) és az összes összetevőjét?"
LangString UNINST_REQUEST_NOTE ${LANG_Hungarian} "Eltávolítás a frissítés előtt?$\r$\nNem szükséges eltávolítani, az új MTA: SA verzió telepítése előtt$\r$\nFuttassa az új telepítőt a frissítéshez, és az megőrzi a beállításokat."
LangString UNINST_DATA_REQUEST ${LANG_Hungarian} "Megszeretnéd tartani az adataid, mint például erőforrások, képek és szerver beállítások? Minden adat elveszik, ha nem."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Hungarian} "A letöltése nem sikerült: Grand Theft Auto: San Andreas patch"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Hungarian} "A telepítése nem sikerült: Grand Theft Auto: San Andreas patch"
LangString UAC_RIGHTS1 ${LANG_Hungarian} "A telepítéshez rendszergazda jogosultság kell, próbáld újra."
LangString UAC_RIGHTS_UN ${LANG_Hungarian} "Az eltávolításhoz rendszergazda jogosultság kell, próbáld újra."
LangString UAC_RIGHTS3 ${LANG_Hungarian} "A bejelentkezési szolgáltatás nem fut, megszakítás!"
LangString UAC_RIGHTS4 ${LANG_Hungarian} "Sikertelen"
LangString INST_MTA_CONFLICT ${LANG_Hungarian} "Egy másik változata az MTA-nak ($1) elérhető ezen az úton.$\n$\nAz MTA szeretné telepíteni az újabb verziót egy másik telepítési úton.$\nBiztosan felül szeretné írni az MTA verzióját $1 at $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_Hungarian} "Az MTA-t nem lehet telepíteni ugyanabba a könyvtárba, mint a GTA: SA-t.$\n$\nSzeretnéd használni az alapértelmezett telepítési könyvtárat$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Hungarian} "A kiválasztott könyvtár nem létezik.$\n$\nKérlek válaszd ki a GTA:SA könyvtárát"
LangString INST_GTA_ERROR2 ${LANG_Hungarian} "Nem található a GTA:SA telepítve itt: $GTA_DIR $\n$\nBiztosan folytatod?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Hungarian} "Válaszd ki a telepítési helyet"
LangString INST_CHOOSE_LOC ${LANG_Hungarian} "Válaszd ki a mappát, ahova telepíteni fogod a(z): ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Hungarian} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} telepítve lesz a következő mappába.$\nHa máshova szeretnéd telepíteni, kattints az Egyéni fülre és a Tallózás gombra.$\n$\nKattints a Tovább gombra a folytatáshoz."
LangString INST_CHOOSE_LOC3 ${LANG_Hungarian} "Célmappa"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Hungarian} "Tallózás..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Hungarian} "Alapértelmezett"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Hungarian} "Utoljára használva"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Hungarian} "Egyéni"
LangString INST_CHOOSE_LOC4 ${LANG_Hungarian} "Válaszd ki a mappát, ahova telepíted ezt: ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_LOC_OW ${LANG_Hungarian} "Figyelem: Egy másik MTA verzió ($1) már létezik ezen az útvonalon."
LangString INST_LOC_UPGRADE ${LANG_Hungarian} "Telepítés típusa: Frissítés"
LangString NETTEST_TITLE1 ${LANG_Hungarian} "Online frissítés"
LangString NETTEST_TITLE2 ${LANG_Hungarian} "Frissítési információk ellenőrzése"
LangString NETTEST_STATUS1 ${LANG_Hungarian} "Telepítő frissítési információk ellenőrzése..."
LangString NETTEST_STATUS2 ${LANG_Hungarian} "Kérjük biztosítsd, hogy a tűzfal ne blokkoljon"
LangString GET_XPVISTA_PLEASE ${LANG_Hungarian} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Hungarian} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString DESC_DirectX ${LANG_Hungarian} "Install or update DirectX (if required)."
!insertmacro MUI_LANGUAGE "Macedonian"
LangString LANGUAGE_CODE ${LANG_Macedonian} "mk"
LangString GET_XPVISTA_PLEASE ${LANG_Macedonian} "Верзијата од MTA:SA што сте ја симнале не продржува Windows XP или Vista.   Ве молиме симнете друга верзија од www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Macedonian} "Верзијата од MTA:SA е дизајнирана за постари верзии од Windows.   Ве молиме симнете ја најновата верзија од www.mtasa.com."
LangString WELCOME_TEXT ${LANG_Macedonian} "Волшебникот ќе те води преку инсталацијата или упдате на $(^Name) ${REVISION_TAG}\n\nСе препорачувана дека сите други програми да бидаат затворени пред да се стартува Сетапот.\n\n[Пристап на админот може да се бара за Vista и подобри верзии]\n\nСтиснете Next за да продолжиш."
LangString HEADER_Text ${LANG_Macedonian} "Grand Theft Auto: San Andreas локација"
LangString DIRECTORY_Text_Dest ${LANG_Macedonian} "Grand Theft Auto: San Andreas фолдер"
LangString DIRECTORY_Text_Top ${LANG_Macedonian} "Ве молиме селектирајте го вашиот Grand Theft Auto: San Andreas фолдер.$\n$\nВие мора да ја имате Grand Theft Auto: San Andreas 1.0 верзијата инсталирано за да го користите MTA:SA, ниедна друга верзија не подржува.$\n$\nКликнете на Инсталирај за да започне инсталирањето."
LangString DESC_Section10 ${LANG_Macedonian} "Креирај Старт Мену група за инсталираните апликации."
LangString DESC_Section11 ${LANG_Macedonian} "Креирај Декстоп кратенка за MTA:SA Клиентот"
LangString DESC_Section12 ${LANG_Macedonian} "Регистрирај mtasa:// протокол за да може да се притисне на прелистувачот. "
LangString DESC_Section13 ${LANG_Macedonian} "Додај во прозорецот за пребарување на игри (доколку е претставен)"
LangString DESC_DirectX ${LANG_Macedonian} "Инсталирај или надгради го DirectX (доколку се бара)."
LangString DESC_Section1 ${LANG_Macedonian} "Основните компоненти се потребни за да може да се стартува Multi Theft Auto."
LangString DESC_Section2 ${LANG_Macedonian} "Модификацијата на MTA:SA, ти дозволува да играш онлајн."
LangString DESC_SectionGroupServer ${LANG_Macedonian} "Multi Theft Auto серверот ти овозможува да хостираш игра од твојот компјутер.За тоа ти треба брза интернет конекција."
LangString DESC_Section4 ${LANG_Macedonian} "Multi Theft Auto серверот е задолжителна компонента."
LangString DESC_Section5 ${LANG_Macedonian} "MTA:SA модификација за серверот."
LangString DESC_Section6 ${LANG_Macedonian} "Ова е сет од задолжителни ресурси за твојот сервер."
LangString DESC_Section7 ${LANG_Macedonian} "Ова е оптимален сет од модови за игри и мапи за твојот сервер."
LangString DESC_Section8 ${LANG_Macedonian} "Едиторот на мапа за MTA:SA 1.0. ~ ~ Ова може да се употреби за креирање на мапи во модовите на игри за MTA."
LangString DESC_Section9 ${LANG_Macedonian} "Ова е SDK за креирање на бинарни модели за MTA серверот. Инсталирај го само доколку имаш добри познавање на C++!"
LangString DESC_SectionGroupDev ${LANG_Macedonian} "Кодот за развој и алатки што помага во креирање на модови за Мulti Theft Auto."
LangString DESC_SectionGroupClient ${LANG_Macedonian} "Овој клиент е програмата што ја користиш за да можеш да играш на Multi Theft Auto серверите."
LangString INST_CLIENTSERVER ${LANG_Macedonian} "Клиент и Сервер"
LangString INST_SERVER ${LANG_Macedonian} "Само сервер"
LangString INST_STARTMENU_GROUP ${LANG_Macedonian} "Start menu група"
LangString INST_DESKTOP_ICON ${LANG_Macedonian} "Десктоп икона"
LangString INST_PROTOCOL ${LANG_Macedonian} "Регистрирај mtasa:// протокол"
LangString INST_GAMES_EXPLORER ${LANG_Macedonian} "Додај во истражувачот на игри"
LangString INST_DIRECTX ${LANG_Macedonian} "Инсталирање на DirectX"
LangString INST_SEC_CLIENT ${LANG_Macedonian} "Клиент за игра"
LangString INST_SEC_SERVER ${LANG_Macedonian} "Посветен сервер"
LangString INST_SEC_CORE ${LANG_Macedonian} "Основни компоненти"
LangString INST_SEC_GAME ${LANG_Macedonian} "Модел на игра "
LangString INFO_INPLACE_UPGRADE ${LANG_Macedonian} "Извршување на место надградба..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Macedonian} "Ажурирање на барање. Ова може да потрае неколку минути..."
LangString MSGBOX_INVALID_GTASA ${LANG_Macedonian} "Валидна верзија од Grand Theft Auto: San Andreas не беше детектирана.$\r$\nСепак инсталацијата ќе продолжи.$\r$/nВе молиме ре-инсталирајте доколку имате проблеми подоцна."
LangString INST_SEC_CORE_RESOURCES ${LANG_Macedonian} "Основни ресурси"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Macedonian} "Оптимални ресурси"
LangString INST_SEC_EDITOR ${LANG_Macedonian} "Уредник"
LangString INST_SEC_DEVELOPER ${LANG_Macedonian} "Развој"
LangString UNINST_SUCCESS ${LANG_Macedonian} "$(^Име) беше успешно отстрането од вашиот компјутер."
LangString UNINST_FAIL ${LANG_Macedonian} "Деинсталирањето е неуспешно!"
LangString UNINST_REQUEST ${LANG_Macedonian} "Дали сте сигурни дека сакате комплетно да го отстраните $(^Име) и сите други компоненти?"
LangString UNINST_REQUEST_NOTE ${LANG_Macedonian} "Деинсталирање пред надградување?$\r$\nНе е потребно да се деинсталира нова верзија од MTA:SA пред инсталирање$\r$\nВклучете ја новата инсталација за да надградете и вратете старите конфигурации."
LangString UNINST_DATA_REQUEST ${LANG_Macedonian} "Дали сакате да ги задржите вашите фајлови (како на пример ресурси, слики и конфигурации од серверот)? Доколку притиснете не, било каква ресурса, конфигурација или слика што сте ги креирале ќе биде изгубена."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Macedonian} "Печ фајлот  за вашата верзија од Grand Theft Auto: San Andreas не може да се симне"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Macedonian} "Печ фајлот за вашата верзија од Grand Theft Auto: San Andreas не може да се инсталира"
LangString UAC_RIGHTS1 ${LANG_Macedonian} "Инсталацијата бара пристап на админот, пробајте повторно "
LangString UAC_RIGHTS_UN ${LANG_Macedonian} "Деинсталацијата бара пристап до админот, пробајте повторно"
LangString UAC_RIGHTS3 ${LANG_Macedonian} "Сервисот за логирање не е во употреба, исклучување!"
LangString UAC_RIGHTS4 ${LANG_Macedonian} "Грешка во подигање"
LangString INST_MTA_CONFLICT ${LANG_Macedonian} "Поинаква поголема верзија од MTA ($1) веќе постои во таа локација.$\n$\nМТА е дизајнирана за поголеми верзии за да бидат инсталирана во ралзични локации.$\n~Дали сте сигурни дека сакате да ја пребришете MTA $1 во $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_Macedonian} "MTA не може да се инсталира во истата дирекција како GTA:SA.$\n$\nДали сакате да ја користите нормалната дирекција за инсталирање$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Macedonian} "Селектираниот фолдер не постои.$\n$\nВе молиме селектирајте го инсталациониот фолдер на GTA:SA"
LangString INST_GTA_ERROR2 ${LANG_Macedonian} "Не може да се најде инсталацијата на GTA:SA во $GTA_DIR $\n$\nДали сте сигурни дека сакате да продолжите ?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Macedonian} "Изберете место за инсталација"
LangString INST_CHOOSE_LOC ${LANG_Macedonian} "Изберете фолдер во кој ќе инсталирате ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Macedonian} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} ќе се инсталира во следниот фолдер.$\nЗа да инсталирате во различен фолдер кликнете Пребарување и селектирајте го другиот фолдер.$\n$\n~Кликнете Следно за да продолжите."
LangString INST_CHOOSE_LOC3 ${LANG_Macedonian} "Дестинација на фолдерот"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Macedonian} "Пребарување..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Macedonian} "Стандарно"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Macedonian} "Последно употребувано"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Macedonian} "Обично"
LangString INST_CHOOSE_LOC4 ${LANG_Macedonian} "Селектирајте го фолдерот за да инсталирате ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} во:"
LangString INST_LOC_OW ${LANG_Macedonian} "Предупредување: Поинаква поголема верзија од MTA ($1) веќе постои на тоа место."
LangString INST_LOC_UPGRADE ${LANG_Macedonian} "Вид на инсталација: ~ ~ Надградба"
LangString NETTEST_TITLE1 ${LANG_Macedonian} "Онлјан надградба"
LangString NETTEST_TITLE2 ${LANG_Macedonian} "Проверка на информација за надградба"
LangString NETTEST_STATUS1 ${LANG_Macedonian} "Проверка на информација за надградба на инсталацијата"
LangString NETTEST_STATUS2 ${LANG_Macedonian} "Ве молиме осигурајте се вашиот firewall да не блокира"
!insertmacro MUI_LANGUAGE "Lithuanian"
LangString LANGUAGE_CODE ${LANG_Lithuanian} "lt"
LangString GET_XPVISTA_PLEASE ${LANG_Lithuanian} "Ši MTA:SA versija, kurią atsisiuntėte, nepalaiko Windows XP ar Vista operacinės sitemos. Prašome atsisiųsti tinkamą versiją iš www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Lithuanian} "Ši MTA:SA versija yra skirta senesnėms Windows versijoms. Prašome atsisiųsti naujausią versiją iš www.mtasa.com."
LangString WELCOME_TEXT ${LANG_Lithuanian} "Šis įdiegimo gidas jums padės įdiegti ar atnaujinti $(^Name) ${REVISION_TAG}\n\nRekomenduojame išjungti visas kitas programas prieš pradedant Įdiegimą.\n\n[Administratoriaus teisės gali būti pareikalautos naudojantis Vista ir vėlesnėmis operacinėmis sistemomis]\n\nNorėdami tęsti, spauskite Toliau."
LangString HEADER_Text ${LANG_Lithuanian} "Grand Theft Auto: San Andreas įdiegimo vieta"
LangString DIRECTORY_Text_Dest ${LANG_Lithuanian} "Grand Theft Auto: San Andreas aplankas"
LangString DIRECTORY_Text_Top ${LANG_Lithuanian} "Pasirinkite Grand Theft Auto: San Andreas aplanką.$\n$\nJūs PRIVALOTE turėti Grand Theft Auto: Sand Andreas 1.0 įdiegtą, norėdami naudoti MTA:SA, kitos versijos nepalaikomos.$\n$\nSpauskite Įdiegti norėdami pradėti įdiegimą."
LangString DESC_Section10 ${LANG_Lithuanian} "Sukurti Pradžios Meniu grupę įdiegtoms programoms"
LangString DESC_Section11 ${LANG_Lithuanian} "Sukurti Darbalaukio Nuorodą MTA:SA Klientui."
LangString DESC_Section12 ${LANG_Lithuanian} "Leisti mtasa:// protokolo panaudojimą naršyklėse."
LangString DESC_Section13 ${LANG_Lithuanian} "Pridėti prie Windows Games Explorer (jei yra)."
LangString DESC_DirectX ${LANG_Lithuanian} "Įdiegti ar atnaujinti DirectX (jei reikalinga)."
LangString DESC_Section1 ${LANG_Lithuanian} "Pagrindiniai komponentai reikalingi, kad veiktų Multi Theft Auto."
LangString DESC_Section2 ${LANG_Lithuanian} "MTA:SA modifikacija, leidžianti jums žaisti internetu."
LangString DESC_SectionGroupServer ${LANG_Lithuanian} "Multi Theft Auto serveris. Naudodamiesi juo jūs galite sukurti savo žaidimo serverį. Reikalingas greitas interneto ryšys."
LangString DESC_Section4 ${LANG_Lithuanian} "Multi Theft Auto serveris. Šis komponentas yra privalomas."
LangString DESC_Section5 ${LANG_Lithuanian} "MTA:SA modifikacija serveriui."
LangString DESC_Section6 ${LANG_Lithuanian} "Tai yra reikalingų resursų rinkinys jūsų serveriui."
LangString DESC_Section7 ${LANG_Lithuanian} "Tai yra neprivalomas žaidimo režimų ir žemėlapių rinkinys jūsų serveriui."
LangString DESC_Section8 ${LANG_Lithuanian} "MTA:SA 1.0 Žemėlapių Redaktorius.  Gali būti panaudotas norint sukurti jūsų pačių trokštamus žemėlapius skirtus MTA žaidimo tipams."
LangString DESC_Section9 ${LANG_Lithuanian} "Tai yra SDK norint kurti dvejetainius modulius MTA serveriui. Įdiekite tik tuomet, jei turite gerą supratimą apie C++!"
LangString DESC_SectionGroupDev ${LANG_Lithuanian} "Vystymo kodas ir įrankiai, kurie padeda Multi Theft Auto modifikacijų kūrime"
LangString DESC_SectionGroupClient ${LANG_Lithuanian} "Klientas yra programa, kurią jūs naudojate žaisdami Multi Theft Auto serveryje"
LangString INST_CLIENTSERVER ${LANG_Lithuanian} "Klientas ir Serveris"
LangString INST_SERVER ${LANG_Lithuanian} "Tik serveris"
LangString INST_STARTMENU_GROUP ${LANG_Lithuanian} "Pradžios meniu grupė"
LangString INST_DESKTOP_ICON ${LANG_Lithuanian} "Darbalaukio piktograma"
LangString INST_PROTOCOL ${LANG_Lithuanian} "Registruoti mtasa:// protokolą"
LangString INST_GAMES_EXPLORER ${LANG_Lithuanian} "Pridėti prie Games Explorer"
LangString INST_DIRECTX ${LANG_Lithuanian} "Įdiegti DirectX"
LangString INST_SEC_CLIENT ${LANG_Lithuanian} "Žaidimo klientas"
LangString INST_SEC_SERVER ${LANG_Lithuanian} "Dedikuotas serveris"
LangString INST_SEC_CORE ${LANG_Lithuanian} "Pagrindiniai komponentai"
LangString INST_SEC_GAME ${LANG_Lithuanian} "Žaidimo modulis"
LangString INFO_INPLACE_UPGRADE ${LANG_Lithuanian} "Atliekamas vietos atnaujinimas..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Lithuanian} "Atnaujinami leidimai. Tai gali užtrukti kelias minutes..."
LangString MSGBOX_INVALID_GTASA ${LANG_Lithuanian} "Galiojanti Grand Theft Auto: San Andreas versija nerasta.$\r$\nTačiau diegimas tęsis.$\rJei kils problemų, prašome įdiegti iš naujo."
LangString INST_SEC_CORE_RESOURCES ${LANG_Lithuanian} "Pagrindiniai Resursai"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Lithuanian} "Nebūtini Resursai"
LangString INST_SEC_EDITOR ${LANG_Lithuanian} "Redaktorius"
LangString INST_SEC_DEVELOPER ${LANG_Lithuanian} "Plėtojimas"
LangString UNINST_SUCCESS ${LANG_Lithuanian} "$(^Name) buvo sėkmingai pašalintas iš jūsų kompiuterio."
LangString UNINST_FAIL ${LANG_Lithuanian} "Pašalinimas nepavyko!"
LangString UNINST_REQUEST ${LANG_Lithuanian} "Ar tikrai norite pašalinti $(^Name) ir visus jo komponentus?"
LangString UNINST_REQUEST_NOTE ${LANG_Lithuanian} "Pašalinama prieš atnaujinimą?$\r$\nNėra būtina pašalinti šios versijos prieš diegiant naują MTA:SA versiją$\r$\nPaleiskite atnaujinimo diegimą ir išsaugosite savo nustatymus."
LangString UNINST_DATA_REQUEST ${LANG_Lithuanian} "Ar norėtumėte palikti savo duomenų bylas (pavyzdžiui resursus, nuotraukas ir serverio konfigūraciją)? Jei paspausite ne, tai visi resursai, konfigūracijos ar nuotraukos kurias padarėte, bus pašalinti."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Lithuanian} "Nepavyko atsisiųsti papildomų klaidų ištaisymo paketo jūsų Grand Theft Auto: San Andreas versijai"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Lithuanian} "Nepavyko įdiegti papildomų klaidų ištaisymo paketo jūsų Grand Theft Auto: San Andreas versijai"
LangString UAC_RIGHTS1 ${LANG_Lithuanian} "Šis įdiegimo procesas reikalauja administratoriaus teisių, bandykite dar kartą"
LangString UAC_RIGHTS_UN ${LANG_Lithuanian} "Šis pašalinimas reikalauja administratoriaus teisių, bandykite dar kartą"
LangString UAC_RIGHTS3 ${LANG_Lithuanian} "Prisijungimo paslauga neveikia, nutraukiama!"
LangString UAC_RIGHTS4 ${LANG_Lithuanian} "Nepavyko iškelti"
LangString INST_MTA_CONFLICT ${LANG_Lithuanian} "Kita MTA ($1) pagrindinė versija jau egzistuoja pasirinktoje vietoje.$\n$\nMTA yra pritaikytas pagrindinėms versijoms įdiegti skirtingose vietose.$\n Ar jūs įsitikinę, jog norite perrašyti MTA $1 direktorijoje $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_Lithuanian} "MTA negali būti įdiegtas į tą pačią vietą kaip GTA:SA.$\n$\nAr norite naudoti įprastinę įdiegimo vietą$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Lithuanian} "Pasirinkta direktorija neegzistuoja.$\n$\nPrašome pasirinkti GTA:SA įdiegimo direktoriją"
LangString INST_GTA_ERROR2 ${LANG_Lithuanian} "Nepavyko rasti GTA:SA pasirinktoje direktorijoje $GTA_DIR $\n$\nAr tikrai norite tęsti ?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Lithuanian} "Pasirinkite Įdiegimo Vietą"
LangString INST_CHOOSE_LOC ${LANG_Lithuanian} "Pasirinkite aplanką, kuriame norėtumėte įdiegti ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Lithuanian} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} bus įdiegta šiame aplanke.$\nNorėdami įdiegti į kitą aplanką, paspauskite Naršyti ir pasirinkite kitą aplanką.$\n$\nNorėdami tęsti, spauskite Toliau."
LangString INST_CHOOSE_LOC3 ${LANG_Lithuanian} "Pasirinktas Aplankas įdiegimui"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Lithuanian} "Naršyti..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Lithuanian} "Numatytasis"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Lithuanian} "Paskutinį kartą naudota(s)"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Lithuanian} "Pasirinktinis"
LangString INST_CHOOSE_LOC4 ${LANG_Lithuanian} "Pasirinkite aplanką įdiegti ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}:"
LangString INST_LOC_OW ${LANG_Lithuanian} "Dėmesio: Kita pagrindinė MTA ($1) versija jau egzistuoja pasirinktoje vietoje."
LangString INST_LOC_UPGRADE ${LANG_Lithuanian} "Įdiegimo tipas: Atnaujinimas"
LangString NETTEST_TITLE1 ${LANG_Lithuanian} "Atnaujinimas tinklu"
LangString NETTEST_TITLE2 ${LANG_Lithuanian} "Tikrinama ar yra atnaujinimų"
LangString NETTEST_STATUS1 ${LANG_Lithuanian} "Tikrinama ar yra diegimo atnaujinimų..."
LangString NETTEST_STATUS2 ${LANG_Lithuanian} "Prašome įsitinkinti ar ugniasienė neblokuoja"
!insertmacro MUI_LANGUAGE "French"
LangString LANGUAGE_CODE ${LANG_French} "fr"
LangString WELCOME_TEXT ${LANG_French} "Cet assistant vous guidera dans l'installation ou la mise à jour de $(^Name) ${REVISION_TAG}\n\nIl est recommandé de fermer toutes les autres applications avant de commencer l'installation.\n\n[Un accès Administrateur pourrait être demandé.]\n\nCliquez sur Suivant pour continuer."
LangString HEADER_Text ${LANG_French} "Emplacement de Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_French} "Dossier de Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Top ${LANG_French} "Veuillez sélectionner le dossier de Grand Theft Auto: San Andreas.$\n$\nVous DEVEZ avoir Grand Theft Auto: San Andreas version 1.0 pour pouvoir utiliser MTA:SA, qui ne supporte aucune autre version.$\n$\nCliquez sur Installer pour commencer l'installation."
LangString DESC_Section10 ${LANG_French} "Créer un raccourci dans le menu Démarrer"
LangString DESC_Section11 ${LANG_French} "Créer un raccourci sur le Bureau pour le Client MTA:SA."
LangString DESC_Section12 ${LANG_French} "Enregistrer le protocole mtasa:// pour les navigateurs."
LangString DESC_Section13 ${LANG_French} "Ajouter à l'Explorateur de Jeux Windows (si présent)."
LangString DESC_Section1 ${LANG_French} "Les composants de base nécessaires pour lancer MTA:SA."
LangString DESC_Section2 ${LANG_French} "La modification MTA:SA, vous permettant de jouer en ligne."
LangString DESC_SectionGroupServer ${LANG_French} "Le Serveur Multi Theft Auto, vous permettant d'héberger des jeux à partir de votre ordinateur. Cela nécessite une connexion Internet rapide."
LangString DESC_Section4 ${LANG_French} "Le Serveur Multi Theft Auto. Ceci est un composant nécessaire."
LangString DESC_Section5 ${LANG_French} "La modification MTA:SA pour le Serveur."
LangString DESC_Section6 ${LANG_French} "Il s'agit d'un ensemble de ressources nécessaires pour votre serveur."
LangString DESC_Section7 ${LANG_French} "Il s'agit d'un ensemble facultatif de gamemodes et maps pour votre serveur."
LangString DESC_Section8 ${LANG_French} "L'Editeur de Map pour MTA:SA.  Il peut être utilisé pour créer vos propres maps pour ensuite les utiliser dans les gamemodes de MTA:SA."
LangString DESC_Section9 ${LANG_French} "Il s'agit du SDK pour créer des modules binaires pour le Serveur MTA:SA. Installez uniquement si vous avez une bonne connaissance du C++!"
LangString DESC_SectionGroupDev ${LANG_French} "Outils de développement, aidant à la création de mods pour MTA:SA"
LangString DESC_SectionGroupClient ${LANG_French} "Le client est le programme que vous exécutez pour jouer sur un serveur MTA:SA"
LangString INST_CLIENTSERVER ${LANG_French} "Client et Serveur"
LangString INST_SERVER ${LANG_French} "Serveur uniquement"
LangString INST_STARTMENU_GROUP ${LANG_French} "Raccourci dans le menu Démarrer"
LangString INST_DESKTOP_ICON ${LANG_French} "Raccourci sur le Bureau"
LangString INST_PROTOCOL ${LANG_French} "Enregistrer le protocole mtasa://"
LangString INST_GAMES_EXPLORER ${LANG_French} "Ajouter à l'Explorateur de Jeux"
LangString INST_SEC_CLIENT ${LANG_French} "Client"
LangString INST_SEC_SERVER ${LANG_French} "Serveur"
LangString INST_SEC_CORE ${LANG_French} "Composants de base"
LangString INST_SEC_GAME ${LANG_French} "Module du jeu"
LangString INFO_INPLACE_UPGRADE ${LANG_French} "Mise à niveau en cours..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_French} "Mise à jour des permissions. Ceci peut prendre quelques minutes..."
LangString MSGBOX_INVALID_GTASA ${LANG_French} "Aucune version valide de Grand Theft Auto: San Andreas n'a été détectée.$\r$\nCependant, l'installation va continuer.$\r$\nVeuillez réinstaller si vous rencontrez des problèmes plus tard."
LangString INST_SEC_CORE_RESOURCES ${LANG_French} "Ressources principales"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_French} "Ressources facultatives"
LangString INST_SEC_EDITOR ${LANG_French} "Editeur"
LangString INST_SEC_DEVELOPER ${LANG_French} "Developpement"
LangString UNINST_SUCCESS ${LANG_French} "$(^Name) a été désinstallé de votre ordinateur."
LangString UNINST_FAIL ${LANG_French} "La désinstallation a échoué!"
LangString UNINST_REQUEST ${LANG_French} "Êtes-vous sûr de vouloir supprimer complètement $(^Name) et tous ses composants?"
LangString UNINST_REQUEST_NOTE ${LANG_French} "Désinstaller avant la mise à jour?$\r$\nIl n'est pas nécessaire de désinstaller avant d'installer une nouvelle version de MTA:SA$\r$\nExécutez le nouveau programme d'installation pour mettre à niveau en conservant vos paramètres."
LangString UNINST_DATA_REQUEST ${LANG_French} "Voulez-vous conserver vos fichiers de données (tels que ressources, captures d'écran et configuration du serveur)? Si vous cliquez sur Non, les ressources, configurations ou captures d'écran que vous avez créés, seront perdus."
LangString MSGBOX_PATCH_FAIL1 ${LANG_French} "Impossible de télécharger le patch pour votre version de Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_French} "Impossible d'installer le patch pour votre version de Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_French} "Cet installeur nécessite un accès administrateur, veuillez réessayez"
LangString UAC_RIGHTS_UN ${LANG_French} "Ce désinstalleur nécessite un accès administrateur, veuillez réessayez"
LangString UAC_RIGHTS3 ${LANG_French} "Le service Logon n'est pas en cours d'exécution, annulation!"
LangString UAC_RIGHTS4 ${LANG_French} "Impossible d'élever"
LangString INST_MTA_CONFLICT ${LANG_French} "Une version différente de MTA ($1) existe déjà à cet emplacement.$\n$\nMTA est conçu pour installer les versions différentes dans des dossiers différents.$\nÊtes-vous sûr de vouloir remplacer MTA $1 à l'emplacement $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_French} "MTA ne peut pas être installé dans le même répertoire que GTA:SA.$\n$\nVoulez-vous utiliser le répertoire d'installation par défaut$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_French} "L'emplacement sélectionné n'existe pas.$\n$\nVeuillez sélectionner le dossier d'installation de GTA:SA"
LangString INST_GTA_ERROR2 ${LANG_French} "Impossible de trouver GTA:SA à l'emplacement $GTA_DIR $\n$\nÊtes-vous sûr de vouloir continuer?"
LangString INST_CHOOSE_LOC_TOP ${LANG_French} "Choisissez l'emplacement de l'installation"
LangString INST_CHOOSE_LOC ${LANG_French} "Choisissez le dossier dans lequel sera installé ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_French} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} sera installé à l'emplacement suivant.$\nPour installer à un emplacement différent, cliquez sur Parcourir et sélectionnez un autre dossier.$\n$\nCliquez sur Suivant pour continuer."
LangString INST_CHOOSE_LOC3 ${LANG_French} "Dossier de destination"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_French} "Parcourir..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_French} "Par défaut"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_French} "Dernière utilisation"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_French} "Personnalisée"
LangString INST_CHOOSE_LOC4 ${LANG_French} "Sélectionnez le dossier dans lequel sera installé ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} :"
LangString INST_LOC_OW ${LANG_French} "Avertissement: Une version différente de MTA ($1) existe déjà à cet emplacement."
LangString INST_LOC_UPGRADE ${LANG_French} "Type d'installation:  Mise à niveau"
LangString NETTEST_TITLE1 ${LANG_French} "Mise à jour en ligne"
LangString NETTEST_TITLE2 ${LANG_French} "Vérification des informations de mise à jour"
LangString NETTEST_STATUS1 ${LANG_French} "Vérification des informations de mise à jour du programme d'installation..."
LangString NETTEST_STATUS2 ${LANG_French} "Veuillez vous assurer que votre pare-feu ne bloque pas"
LangString GET_XPVISTA_PLEASE ${LANG_French} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_French} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString DESC_DirectX ${LANG_French} "Install or update DirectX (if required)."
LangString INST_DIRECTX ${LANG_French} "Install DirectX"
!insertmacro MUI_LANGUAGE "Norwegian"
LangString LANGUAGE_CODE ${LANG_Norwegian} "nb"
LangString WELCOME_TEXT ${LANG_Norwegian} "Denne veiviseren vil guide deg gjennom installasjonen eller oppdateringen av $(^Name) ${REVISION_TAG}\n\nDet anbefales at du lukker alle andre programmer før du starter installasjonen.\n\n[Administrator tilgang kan kreves for Vista og nyere]\n\nKlikk Neste for å fortsette."
LangString HEADER_Text ${LANG_Norwegian} "Grand Theft Auto: San Andreas plassering"
LangString DIRECTORY_Text_Dest ${LANG_Norwegian} "Grand Theft Auto: San Andreas mappe"
LangString DIRECTORY_Text_Top ${LANG_Norwegian} "Vennligst velg din Grand Theft Auto: San Andreas mappe.$\n$\nDu MÅ ha Grand Theft Auto: San Andreas 1.0 installert for å bruke MTA:SA, den støtter ingen andre versjoner.$\n$\nTrykk Installer for å begynne installasjonen."
LangString DESC_Section10 ${LANG_Norwegian} "Opprett en Start Meny gruppe for installerte programmer"
LangString DESC_Section11 ${LANG_Norwegian} "Opprett en snarvei på skrivebordet for MTA:SA klienten."
LangString DESC_Section12 ${LANG_Norwegian} "Registrer mtasa:// protokoll for nettleser klikkbar-somhet."
LangString DESC_Section13 ${LANG_Norwegian} "Legg til i Windows Spill Utforsker (hvis den finnes)."
LangString DESC_Section1 ${LANG_Norwegian} "Grunnkomponentene som trenges for å kjøre Multi Theft Auto."
LangString DESC_Section2 ${LANG_Norwegian} "MTA:SA modifikasjonen tillater deg å spille på nettet."
LangString DESC_SectionGroupServer ${LANG_Norwegian} "Multi Theft Auto server. Denne tillater deg å opprette spill fra din datamaskin. Dette krever en rask Internett tilkobling."
LangString DESC_Section4 ${LANG_Norwegian} "Multi Theft Auto server. Dette er en nødvendig komponent."
LangString DESC_Section5 ${LANG_Norwegian} "MTA:SA modifikasjonen for serveren."
LangString DESC_Section6 ${LANG_Norwegian} "Dette er et sett av nødvendige ressurser for serveren din."
LangString DESC_Section7 ${LANG_Norwegian} "Dette er ett sett av valgfrie spillmoduler og kart for serveren din."
LangString DESC_Section8 ${LANG_Norwegian} "MTA:SA 1.0 Kart Editor.  Denne kan bli brukt til å skape dine helt egne kart for bruk i spillmoduser for MTA."
LangString DESC_Section9 ${LANG_Norwegian} "Dette er SDK'en for å lage binære moduler for MTA serveren. Bare installere hvis du har en god forståelse for C++!"
LangString DESC_SectionGroupDev ${LANG_Norwegian} "Utviklings kode og verktøy som kan benyttes for å skape modifikasjoner for Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_Norwegian} "Klienten er programmet du kjører for å spille på en Multi Theft Auto server"
LangString INST_CLIENTSERVER ${LANG_Norwegian} "Klient og Server"
LangString INST_SERVER ${LANG_Norwegian} "Kun server"
LangString INST_STARTMENU_GROUP ${LANG_Norwegian} "Start meny gruppe"
LangString INST_DESKTOP_ICON ${LANG_Norwegian} "Skrivebordsikon"
LangString INST_PROTOCOL ${LANG_Norwegian} "Registrer mtasa:// protokoll"
LangString INST_GAMES_EXPLORER ${LANG_Norwegian} "Legg til i Spill Utforsker"
LangString INST_SEC_CLIENT ${LANG_Norwegian} "Spill klient"
LangString INST_SEC_SERVER ${LANG_Norwegian} "Dedikert server"
LangString INST_SEC_CORE ${LANG_Norwegian} "Kjernekomponenter"
LangString INST_SEC_GAME ${LANG_Norwegian} "Spill modul"
LangString INFO_INPLACE_UPGRADE ${LANG_Norwegian} "Utfører direkte oppgradering..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Norwegian} "Oppdaterer tillatelser. Dette kan ta noen minutter..."
LangString MSGBOX_INVALID_GTASA ${LANG_Norwegian} "En gyldig Windows versjon av Grand Theft Auto: San Andreas ble ikke funnet.$\r$\nInstallasjonen vill fortsette uansett.$\r$\nVennligst installer på nytt om problemer oppstår senere."
LangString INST_SEC_CORE_RESOURCES ${LANG_Norwegian} "Kjerne Ressurser"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Norwegian} "Valgfrie Ressurser"
LangString INST_SEC_EDITOR ${LANG_Norwegian} "Redigerings verktøy"
LangString INST_SEC_DEVELOPER ${LANG_Norwegian} "Utvikling"
LangString UNINST_SUCCESS ${LANG_Norwegian} "$(^Name) ble fjernet fra din datamaskin."
LangString UNINST_FAIL ${LANG_Norwegian} "Avinstallasjonen har feilet!"
LangString UNINST_REQUEST ${LANG_Norwegian} "Er du sikker på at du vill fullstendig fjerne $(^Name) og alle dens komponenter?"
LangString UNINST_REQUEST_NOTE ${LANG_Norwegian} "Avinstallere før oppdatering?$\r$\nDet er ikke nødvendig å avinstallere før du installerer en nyere versjon av MTA:SA$\r$\nKjør det nye installasjonsprogrammet for å oppgradere og bevare dine innstillinger."
LangString UNINST_DATA_REQUEST ${LANG_Norwegian} "Ville du like å beholde alle dine data filer (Slikt som ressurser, skjermdumper og server konfigurasjon)? Om du trykker nei, vil alle ressurser, konfigureringer og skjermdumper du har laget bli slettet."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Norwegian} "Kunne ikke laste ned patch filen for din versjon av Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Norwegian} "Kunne ikke installere patch filen for din versjon av Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_Norwegian} "Dette installasjons verktøyet krever admin tilgang, prøv igjen"
LangString UAC_RIGHTS_UN ${LANG_Norwegian} "Dette avinstallasjonsverktøyet krever admin tilgang, prøv igjen"
LangString UAC_RIGHTS3 ${LANG_Norwegian} "Logon-tjenesten kjører ikke, avbryter!"
LangString UAC_RIGHTS4 ${LANG_Norwegian} "Kunne ikke oppheve"
LangString INST_MTA_CONFLICT ${LANG_Norwegian} "En annen stor versjon av MTA ($1) finnes allerede i denne banen.$\n$\nMTA er utviklet slik at store versjoner installeres på forskjellige baner. $\n Er du sikker på at du vil overskrive MTA $1 på $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_Norwegian} "MTA kan ikke installeres i samme mappe som GTA:SA.$\n$\nØnsker du å bruke standard installasjons mappe$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Norwegian} "Den valgte destinasjonen finnes ikke.$\n$\nVennligst velg GTA:SA installasjons målmappe"
LangString INST_GTA_ERROR2 ${LANG_Norwegian} "Kunne ikke finne GTA:SA installert i $GTA_DIR $\n$\nEr du sikker på at du vill fortsette ?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Norwegian} "Velg Målmappe"
LangString INST_CHOOSE_LOC ${LANG_Norwegian} "Velg mappe hvor ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} skal installeres"
LangString INST_CHOOSE_LOC2 ${LANG_Norwegian} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} vill bli installert i følgende mappe.$\nFor å installere i en annen mappe, klikk Bla og velg en annen mappe.$\n$\n Klikk Neste for å fortsette."
LangString INST_CHOOSE_LOC3 ${LANG_Norwegian} "Målmappe"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Norwegian} "Bla gjennom..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Norwegian} "Standard"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Norwegian} "Sist brukt"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Norwegian} "Tilpasset"
LangString INST_CHOOSE_LOC4 ${LANG_Norwegian} "Velg mappe for å installere ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} i:"
LangString INST_LOC_OW ${LANG_Norwegian} "Advarsel: En annen stor versjon av MTA ($1) finnes allerede i den banen."
LangString INST_LOC_UPGRADE ${LANG_Norwegian} "Installasjon type: Oppgrader"
LangString NETTEST_TITLE1 ${LANG_Norwegian} "Nettoppdatering"
LangString NETTEST_TITLE2 ${LANG_Norwegian} "Ser etter oppdaterings informasjon"
LangString NETTEST_STATUS1 ${LANG_Norwegian} "Ser etter oppdaterings informasjon for installasjonsprogrammet..."
LangString NETTEST_STATUS2 ${LANG_Norwegian} "Vennligst sikre at brannmuren ikke blokkerer"
LangString GET_XPVISTA_PLEASE ${LANG_Norwegian} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Norwegian} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString DESC_DirectX ${LANG_Norwegian} "Install or update DirectX (if required)."
LangString INST_DIRECTX ${LANG_Norwegian} "Install DirectX"
!insertmacro MUI_LANGUAGE "Russian"
LangString LANGUAGE_CODE ${LANG_Russian} "ru"
LangString GET_XPVISTA_PLEASE ${LANG_Russian} "Версия MTA:SA, которую вы скачали, не поддерживает Windows XP или Vista.\n\nПожалуйста, скачайте другую версию с www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Russian} "Версия MTA:SA предназначена для старых версий Windows. \n \n Пожалуйста, скачайте новую версию с www.mtasa.com."
LangString WELCOME_TEXT ${LANG_Russian} "Этот установщик будет сопровождать вас во время установки или обновления $(^Name) ${REVISION_TAG}\n\nРекомендуется закрыть все другие приложения перед началом установки.\n\n[Права администратора могут быть запрошены для системы Vista и выше]\n\nНажмите Далее для продолжения."
LangString HEADER_Text ${LANG_Russian} "Расположение Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_Russian} "Путь до папки Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Top ${LANG_Russian} "Пожалуйста, выберите папку Grand Theft Auto: San Andreas.$\n$\nДля использования MTA:SA необходима Grand Theft Auto: San Andreas версии 1.0, другие версии не поддерживаются.$\n$\nНажмите Установить для начала установки."
LangString DESC_Section10 ${LANG_Russian} "Добавить пункт в меню $\"Пуск$\""
LangString DESC_Section11 ${LANG_Russian} "Создать ярлык на рабочем столе."
LangString DESC_Section12 ${LANG_Russian} "Зарегистрировать протокол mtasa:// для подключения с помощью интернет-браузера."
LangString DESC_Section13 ${LANG_Russian} "Добавить в папку $\"Игры$\" (Если имеется)."
LangString DESC_DirectX ${LANG_Russian} "Установите или обновите DirectX (если требуется)."
LangString DESC_Section1 ${LANG_Russian} "Основные компоненты, необходимые для запуска Multi Theft Auto."
LangString DESC_Section2 ${LANG_Russian} "Модификация MTA:SA, позволяющая играть по сети."
LangString DESC_SectionGroupServer ${LANG_Russian} "Сервер Multi Theft Auto. Позволяет запустить свой сервер для подключения к нему других игроков. Требуется быстрое интернет-соединение."
LangString DESC_Section4 ${LANG_Russian} "Сервер Multi Theft Auto. Это необходимый компонент."
LangString DESC_Section5 ${LANG_Russian} "Модификация MTA:SA для сервера."
LangString DESC_Section6 ${LANG_Russian} "Это список рекомендованных ресурсов для вашего сервера."
LangString DESC_Section7 ${LANG_Russian} "Это список необязательных игровых режимов и карт для вашего сервера."
LangString DESC_Section8 ${LANG_Russian} "Редактор карт MTA:SA 1.0. Используется для создания своих собственных карт, используемых в игровых режимах для MTA."
LangString DESC_Section9 ${LANG_Russian} "SDK для создания модулей для MTA сервера. Устанавливайте, если имеете опыт работы с C++!"
LangString DESC_SectionGroupDev ${LANG_Russian} "Программный код и средства, которые помогут в создании модификаций для Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_Russian} "Клиент - это программа, которую вы запускаете для игры на Multi Theft Auto серверах"
LangString INST_CLIENTSERVER ${LANG_Russian} "Клиент и Сервер"
LangString INST_SERVER ${LANG_Russian} "Только сервер"
LangString INST_STARTMENU_GROUP ${LANG_Russian} "Меню $\"Пуск$\""
LangString INST_DESKTOP_ICON ${LANG_Russian} "Ярлык на рабочем столе"
LangString INST_PROTOCOL ${LANG_Russian} "Зарегистрировать протокол mtasa://"
LangString INST_GAMES_EXPLORER ${LANG_Russian} "Добавить в папку $\"Игры$\""
LangString INST_DIRECTX ${LANG_Russian} "Установите DirectX"
LangString INST_SEC_CLIENT ${LANG_Russian} "Игровой клиент"
LangString INST_SEC_SERVER ${LANG_Russian} "Выделенный сервер"
LangString INST_SEC_CORE ${LANG_Russian} "Основные компоненты"
LangString INST_SEC_GAME ${LANG_Russian} "Игровой модуль"
LangString INFO_INPLACE_UPGRADE ${LANG_Russian} "Обновление текущей установки..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Russian} "Обновление прав. Это может занять несколько минут..."
LangString MSGBOX_INVALID_GTASA ${LANG_Russian} "Допустимая Windows-версия Grand Theft Auto: San Andreas не найдена.$\r$\nОднако установка будет продолжена.$\r$\nПожалуйста, выполните переустановку, если появятся проблемы."
LangString INST_SEC_CORE_RESOURCES ${LANG_Russian} "Основные ресурсы"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Russian} "Необязательные Ресурсы"
LangString INST_SEC_EDITOR ${LANG_Russian} "Редактор"
LangString INST_SEC_DEVELOPER ${LANG_Russian} "Разработка"
LangString UNINST_SUCCESS ${LANG_Russian} "$(^Name) успешно удалена с вашего компьютера."
LangString UNINST_FAIL ${LANG_Russian} "Ошибка удаления!"
LangString UNINST_REQUEST ${LANG_Russian} "Вы уверены, что хотите полностью удалить $(^Name) и все её компоненты?"
LangString UNINST_REQUEST_NOTE ${LANG_Russian} "Удалить перед обновлением?$\r$\nУдаление старой версии необязательно перед установкой новой версии MTA:SA$\r$\nЗапустите новый файл установки для обновления и сохранения ваших данных."
LangString UNINST_DATA_REQUEST ${LANG_Russian} "Желаете сохранить ваши данные (ресурсы, скриншоты и настройки сервера)? Если нет, то все ваши ресурсы, настройки и скриншоты будут утеряны."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Russian} "Не удается загрузить патч для вашей версии Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Russian} "Не удается установить патч на вашу версию Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_Russian} "Для установки необходимы права администратора, повторите еще раз"
LangString UAC_RIGHTS_UN ${LANG_Russian} "Для унинсталлер требует права администратора, повторите еще раз"
LangString UAC_RIGHTS3 ${LANG_Russian} "Сервис авторизации не запущен, завершение!"
LangString UAC_RIGHTS4 ${LANG_Russian} "Запуск невозможен"
LangString INST_MTA_CONFLICT ${LANG_Russian} "Версия новее MTA ($1) уже установлена по этому адресу.$\n$\nMTA предусматривает возможность установки нескольких копий в разные директории.$\nВы уверены, что хотите перезаписать MTA $1 в $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_Russian} "MTA не может быть установлено в той же директории что и GTA:SA.$\n$\nВы хотите использовать директорию по умолчанию$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Russian} "Выбранной директории не существует.$\n$\nПожалуйста, выберите директорию с GTA:SA"
LangString INST_GTA_ERROR2 ${LANG_Russian} "GTA:SA не найдена по адресу $GTA_DIR $\n$\nВы уверены, что хотите продолжить?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Russian} "Выберите директорию установки"
LangString INST_CHOOSE_LOC ${LANG_Russian} "Выберите папку для установки ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Russian} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} будет установлена в выбранную папку.$\nДля установки в другую папку нажмите Выбрать и выберите нужную папку.$\n$\nНажмите Далее для продолжения."
LangString INST_CHOOSE_LOC3 ${LANG_Russian} "Директория Установки"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Russian} "Обзор…"
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Russian} "По умолчанию"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Russian} "Последняя использованная"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Russian} "Другой"
LangString INST_CHOOSE_LOC4 ${LANG_Russian} "Выберите папку для установки ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}:"
LangString INST_LOC_OW ${LANG_Russian} "Предупреждение: Более свежая версия MTA ($1) уже установлена сюда же."
LangString INST_LOC_UPGRADE ${LANG_Russian} "Тип установки: Обновление"
LangString NETTEST_TITLE1 ${LANG_Russian} "Онлайн обновление"
LangString NETTEST_TITLE2 ${LANG_Russian} "Проверить обновления"
LangString NETTEST_STATUS1 ${LANG_Russian} "Проверка обновлений установщика..."
LangString NETTEST_STATUS2 ${LANG_Russian} "Пожалуйста, убедитесь, что ваш брандмауэр не блокирует"
!insertmacro MUI_LANGUAGE "Croatian"
LangString LANGUAGE_CODE ${LANG_Croatian} "hr"
LangString WELCOME_TEXT ${LANG_Croatian} "Čarobnjak će Vas voditi kroz instalaciju ili ažuriranje $(^Name) ${REVISION_TAG}\n\nPreporuča se da se zatvore sve ostale aplikacije prije početka instalacije.\n\n[Administratorski pristup mogao bi biti zatražen za Windows Vistu i novije]\n\nPritisnite Dalje za nastavak."
LangString HEADER_Text ${LANG_Croatian} "Mjesto instalacije Grand Theft Auto: San Andreasa"
LangString DIRECTORY_Text_Dest ${LANG_Croatian} "Grand Theft Auto: San Andreas datoteka"
LangString DIRECTORY_Text_Top ${LANG_Croatian} "Molimo izaberite direktorij gdje je Grand Theft Auto: San Andreas instaliran.$\n$\nMORATE imati Grand Theft Auto: San Andreas 1.0 instaliran da biste koristili MTA:SA, druge verzije nisu podržane.$\n$\nPritisnite Instaliraj da započnete instalaciju."
LangString DESC_Section10 ${LANG_Croatian} "Stvori Start Menu grupu za instalirane aplikacije"
LangString DESC_Section11 ${LANG_Croatian} "Stvori Desktop prečac za MTA:SA klijent."
LangString DESC_Section12 ${LANG_Croatian} "Registriraj mtasa:// protokol za selekciju pretraživača."
LangString DESC_Section13 ${LANG_Croatian} "Dodaj u Windows Games Explorer (ako prisutno)."
LangString DESC_Section1 ${LANG_Croatian} "Osnovne komponente potrebne za pokretanje Multi Theft Auto-a."
LangString DESC_Section2 ${LANG_Croatian} "MTA:SA modifikacija, omogućava vam igranje na mreži."
LangString DESC_SectionGroupServer ${LANG_Croatian} "Multi Theft Auto Server. Omogućava Vam da budete domaćin igara sa vlastitog računala. Zahtijeva brzu internet povezanost."
LangString DESC_Section4 ${LANG_Croatian} "Multi Theft Auto server. Potrebna komponenta."
LangString DESC_Section5 ${LANG_Croatian} "MTA:SA modifikacija za server."
LangString DESC_Section6 ${LANG_Croatian} "Ovo je set potrebnih resursa za Vaš server."
LangString DESC_Section7 ${LANG_Croatian} "Ovo je neobavezan set igara i mapa za tvoj server."
LangString DESC_Section8 ${LANG_Croatian} "MTA:SA 1.0 Uređivač Mapa. Ovo može biti korisno za izradu vlastitih mapa za korištenje u MTA serverima."
LangString DESC_Section9 ${LANG_Croatian} "Ovo je SDK za izradu binarnih modula za MTA server. Instalacija istog podrazumijeva dobro razumijevanje C++ programskog jezika!"
LangString DESC_SectionGroupDev ${LANG_Croatian} "Razvojni kod i alati koji pomažu u izradi modova za Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_Croatian} "Ovaj program se koristi za mogućnost igranja na Multi Theft Auto serveru"
LangString INST_CLIENTSERVER ${LANG_Croatian} "Klijent i Server"
LangString INST_SERVER ${LANG_Croatian} "Samo server"
LangString INST_STARTMENU_GROUP ${LANG_Croatian} "Grupa početnog izbornika"
LangString INST_DESKTOP_ICON ${LANG_Croatian} "Ikona radne površine"
LangString INST_PROTOCOL ${LANG_Croatian} "Registriraj mtasa:// protokol"
LangString INST_GAMES_EXPLORER ${LANG_Croatian} "Dodaj u Games Explorer"
LangString INST_SEC_CLIENT ${LANG_Croatian} "Klijent za igranje"
LangString INST_SEC_SERVER ${LANG_Croatian} "Samostalni server"
LangString INST_SEC_CORE ${LANG_Croatian} "Osnovne komponente"
LangString INST_SEC_GAME ${LANG_Croatian} "Modul igre"
LangString INFO_INPLACE_UPGRADE ${LANG_Croatian} "Izvršavanje ažuriranja..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Croatian} "Nadograđivanje dozvola. Ovo bih moglo potrajati par minuta..."
LangString MSGBOX_INVALID_GTASA ${LANG_Croatian} "Važeća Windows verzija Grand Theft Auto: San Andreas-a nije pronađena.$\r$\nMeđutim, instalacija će se nastaviti.$\r$\nMolimo instalirajte ponovno ako bude ikakvih problema kasnije."
LangString INST_SEC_CORE_RESOURCES ${LANG_Croatian} "Osnovni resursi"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Croatian} "Dodatni Resursi"
LangString INST_SEC_EDITOR ${LANG_Croatian} "Uređivač"
LangString INST_SEC_DEVELOPER ${LANG_Croatian} "Razvoj"
LangString UNINST_SUCCESS ${LANG_Croatian} "$(^Name) uspješno je uklonjen s računala."
LangString UNINST_FAIL ${LANG_Croatian} "Deinstalacija nije uspjela!"
LangString UNINST_REQUEST ${LANG_Croatian} "Jeste li sigurni da želite u potpunosti ukloniti $(^Name) i sve njegove komponente?"
LangString UNINST_REQUEST_NOTE ${LANG_Croatian} "De-instalacija prije ažuriranja?$\r$\nNije potrebno de-instalirati prije instalacije nove verzije MTA:SA$\r$\nPokrenite novi installer da biste ažurirali i sačuvali svoje postavke."
LangString UNINST_DATA_REQUEST ${LANG_Croatian} "Želite li ostaviti podatke (kao što su skripte, fotografije i server konfiguracija)? Ako ne, sve skripte, konfiguracije ili fotografije bit će uklonjene."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Croatian} "Zakrpu za vašu verziju Grand Theft Auto: San Andreasa nije bilo moguće skinuti."
LangString MSGBOX_PATCH_FAIL2 ${LANG_Croatian} "Nije bilo moguće instalirati zakrpu za Vašu verziju Grand Theft Auto: San Andreasa."
LangString UAC_RIGHTS1 ${LANG_Croatian} "Ova instalacija zahtijeva pristup administratora, pokušajte ponovno"
LangString UAC_RIGHTS_UN ${LANG_Croatian} "Ova deinstalacija zahtijeva pristup administratora, pokušajte ponovno"
LangString UAC_RIGHTS3 ${LANG_Croatian} "Usluga prijave nije pokrenuta, prekidanje!"
LangString UAC_RIGHTS4 ${LANG_Croatian} "Ne mogu podići"
LangString INST_MTA_CONFLICT ${LANG_Croatian} "Druga verzija MTA ($1) već je instalirana u tome direktoriju.$\n$\nRazličite verzije moraju se instalirati u različite direktorije.$\nJeste li sigurni da želite instalirati preko stare verzije MTA $1 u $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_Croatian} "MTA ne može biti instaliran u isti direktorij kao i GTA:SA.$\n$\nŽelite li koristiti default direktorij instalacije$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Croatian} "Izabran direktorij ne postoji.$\n$\nMolimo odaberite GTA:SA instalacijski direktorij"
LangString INST_GTA_ERROR2 ${LANG_Croatian} "Nije moguće pronaći GTA:SA instaliran u $GTA_DIR $\n$\nJeste li sigurni da želite nastaviti?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Croatian} "Izaberi Instalacijsku Lokaciju"
LangString INST_CHOOSE_LOC ${LANG_Croatian} "Izaberi mapu u koju ćeš instalirati ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Croatian} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} će biti instaliran u sljedećem folderu.$\nDa instalirate u drugačiju mapu, pritisnite Traži i izaberite drugu mapu.$\n$\nPritisnite Dalje za nastavak."
LangString INST_CHOOSE_LOC3 ${LANG_Croatian} "Odredišni Direktorij"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Croatian} "Pretraži…"
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Croatian} "Uobičajeno"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Croatian} "Zadnje korišteno"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Croatian} "Prilagođeno"
LangString INST_CHOOSE_LOC4 ${LANG_Croatian} "Izaberite direktorij za instalaciju ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} :"
LangString INST_LOC_OW ${LANG_Croatian} "Upozorenje: Drugačija glavna verzija MTA ($1) već postoji na tom mjestu."
LangString INST_LOC_UPGRADE ${LANG_Croatian} "Tip instalacije: Nadogradnja"
LangString NETTEST_TITLE1 ${LANG_Croatian} "Online nadogradnja"
LangString NETTEST_TITLE2 ${LANG_Croatian} "Provjeravanje zakrpa"
LangString NETTEST_STATUS1 ${LANG_Croatian} "Provjeravanje zakrpa za instalaciju"
LangString NETTEST_STATUS2 ${LANG_Croatian} "Provjerite da vatrozid ne blokira"
LangString GET_XPVISTA_PLEASE ${LANG_Croatian} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Croatian} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString DESC_DirectX ${LANG_Croatian} "Install or update DirectX (if required)."
LangString INST_DIRECTX ${LANG_Croatian} "Install DirectX"
!insertmacro MUI_LANGUAGE "Indonesian"
LangString LANGUAGE_CODE ${LANG_Indonesian} "id"
LangString GET_XPVISTA_PLEASE ${LANG_Indonesian} "Versi MTA:SA yang telah anda unduh tidak mendukung Windows XP atau Vista.  Silakan unduh versi alternatif dari www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Indonesian} "Versi MTA:SA ini dirancang untuk versi lama dari Windows.  Silakan unduh versi terbaru dari www.mtasa.com."
LangString WELCOME_TEXT ${LANG_Indonesian} "Wizard ini akan memandu Anda melalui instalasi atau update $(^Name) ${REVISION_TAG}\n\nDianjurkan agar anda menutup semua aplikasi lain sebelum memulai Setup.\n\n[Akses admin mungkin diminta untuk Vista keatas]\n\nKlik Selanjutnya untuk melanjutkan."
LangString HEADER_Text ${LANG_Indonesian} "Lokasi Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_Indonesian} "Folder Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Top ${LANG_Indonesian} "Silahkan pilih folder Grand Theft Auto: San Andreas anda.$\n$\nAnda HARUS mempunyai Grand Theft Auto: San Andreas 1.0 yang terpasang untuk menggunakan MTA:SA, tidak mendukung versi lainnya.$\n$\nKlik Pasang untuk memulai pemasangan."
LangString DESC_Section10 ${LANG_Indonesian} "Buat grup Start Menu untuk aplikasi yang terpasang"
LangString DESC_Section11 ${LANG_Indonesian} "Buat Pintasan Desktop untuk Klien MTA:SA."
LangString DESC_Section12 ${LANG_Indonesian} "Daftar protokol mtasa:// agar dapat di-klik di browser."
LangString DESC_Section13 ${LANG_Indonesian} "Tambahkan ke Windows Games Explorer (jika tersedia)."
LangString DESC_DirectX ${LANG_Indonesian} "Pasang atau perbarui DirectX (jika diperlukan)."
LangString DESC_Section1 ${LANG_Indonesian} "Komponen inti diperlukan untuk menjalankan Multi Theft Auto."
LangString DESC_Section2 ${LANG_Indonesian} "Modifikasi MTA:SA, memungkinkan anda untuk bermain secara daring."
LangString DESC_SectionGroupServer ${LANG_Indonesian} "Server Multi Theft Auto. Hal ini memungkinkan anda untuk mengelola permainan dari komputer anda. Hal ini memerlukan koneksi internet yang cepat."
LangString DESC_Section4 ${LANG_Indonesian} "Server Multi Theft Auto. Ini adalah komponen yang diperlukan."
LangString DESC_Section5 ${LANG_Indonesian} "Modifikasi MTA:SA untuk server."
LangString DESC_Section6 ${LANG_Indonesian} "Ini adalah satu set sumber daya yang diperlukan untuk server anda."
LangString DESC_Section7 ${LANG_Indonesian} "Ini adalah satu set opsional dari mode game dan peta untuk server anda."
LangString DESC_Section8 ${LANG_Indonesian} "Penyunting Peta MTA:SA 1.0.  Ini bisa digunakan untuk membuat peta anda sendiri untuk digunakan di mode permainan untuk MTA."
LangString DESC_Section9 ${LANG_Indonesian} "Ini adalah SDK untuk membuat modul biner untuk server MTA. Hanya pasang apabila anda mempunyai pemahaman yang baik tentang C++!"
LangString DESC_SectionGroupDev ${LANG_Indonesian} "Kode dan alat-alat pengembangan yang membantu dalam penciptaan mod untuk Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_Indonesian} "Klien adalah program yang anda jalankan untuk bermain di server Multi Theft Auto"
LangString INST_CLIENTSERVER ${LANG_Indonesian} "Klien dan Server"
LangString INST_SERVER ${LANG_Indonesian} "Hanya server"
LangString INST_STARTMENU_GROUP ${LANG_Indonesian} "Grup start menu"
LangString INST_DESKTOP_ICON ${LANG_Indonesian} "Ikon desktop"
LangString INST_PROTOCOL ${LANG_Indonesian} "Daftarkan protokol mtasa://"
LangString INST_GAMES_EXPLORER ${LANG_Indonesian} "Tambahkan ke Games Explorer"
LangString INST_DIRECTX ${LANG_Indonesian} "Pasang DirectX"
LangString INST_SEC_CLIENT ${LANG_Indonesian} "Klien permainan"
LangString INST_SEC_SERVER ${LANG_Indonesian} "Server terdedikasi"
LangString INST_SEC_CORE ${LANG_Indonesian} "Komponen inti"
LangString INST_SEC_GAME ${LANG_Indonesian} "Modul permainan"
LangString INFO_INPLACE_UPGRADE ${LANG_Indonesian} "Menjalankan peningkatan di tempat..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Indonesian} "Memperbarui izin. Ini dapat memakan beberapa menit..."
LangString MSGBOX_INVALID_GTASA ${LANG_Indonesian} "Versi Windows yang valid dari Grand Theft Auto: San Andreas tidak terdeteksi.$\r$\nNamun pemasangan akan dilanjutkan.$\r$\nSilakan pasang ulang apabila ada masalah nantinya."
LangString INST_SEC_CORE_RESOURCES ${LANG_Indonesian} "Sumber Inti"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Indonesian} "Sumber Opsional"
LangString INST_SEC_EDITOR ${LANG_Indonesian} "Penyunting"
LangString INST_SEC_DEVELOPER ${LANG_Indonesian} "Pengembangan"
LangString UNINST_SUCCESS ${LANG_Indonesian} "$(^Name) telah berhasil dihapus dari komputer anda."
LangString UNINST_FAIL ${LANG_Indonesian} "Penghapusan telah gagal!"
LangString UNINST_REQUEST ${LANG_Indonesian} "Apakah anda yakin untuk menghapus $(^Name) secara lengkap dan semua komponennya?"
LangString UNINST_REQUEST_NOTE ${LANG_Indonesian} "Menghapus sebelum update?$\r$\nPenghapusan tidak diperlukan sebelum memasang versi baru dari MTA:SA$\r$\nJalankan pemasang baru untuk meningkatkan dan mempertahankan pengaturan anda."
LangString UNINST_DATA_REQUEST ${LANG_Indonesian} "Apakah anda ingin menyimpan data (seperti sumber, tangkapan layar, dan konfigurasi server)? Jika anda klik tidak, semua sumber, konfigurasi, atau tangkapan layar yang telah anda buat akan hilang."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Indonesian} "Tidak dapat mengunduh berkas tambalan untuk versi dari Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Indonesian} "Tidak dapat memasang berkas tambalan untuk versi dari Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_Indonesian} "Pemasang ini membutuhkan akses admin, coba lagi"
LangString UAC_RIGHTS_UN ${LANG_Indonesian} "Penghapus ini membutuhkan akses admin, coba lagi"
LangString UAC_RIGHTS3 ${LANG_Indonesian} "Layanan masuk tidak berjalan, batalkan!"
LangString UAC_RIGHTS4 ${LANG_Indonesian} "Tidak dapat meningkatkan"
LangString INST_MTA_CONFLICT ${LANG_Indonesian} "Sebuah versi utama dari MTA ($1) sudah ada pada direktori itu.$\n$\nMTA dirancang untuk versi utama yang akan dipasang di direktori yang berbeda.$\n Apakah anda yakin ingin menimpa MTA $1 dengan $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_Indonesian} "MTA tidak dapat dipasang ke dalam direktori yang sama dengan GTA:SA.$\n$\nApakah anda ingin menggunakan direktori pemasangan default$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Indonesian} "Direktori yang dipilih tidak ada.$\n$\nSilakan pilih direktori pemasangan GTA:SA"
LangString INST_GTA_ERROR2 ${LANG_Indonesian} "Tidak dapat menemukan GTA:SA terpasang di $GTA_DIR $\n$\nApakah anda yakin ingin melanjutkan ?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Indonesian} "Pilih Lokasi Pemasangan"
LangString INST_CHOOSE_LOC ${LANG_Indonesian} "Pilih folder yang akan dipasangkan ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Indonesian} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} akan dipasang di folder berikut.$\nUntuk memasang di folder yang berbeda, klik Telusuri dan pilih folder lainnya.$\n$\n Klik Selanjutnya untuk melanjutkan."
LangString INST_CHOOSE_LOC3 ${LANG_Indonesian} "Folder Tujuan"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Indonesian} "Telusuri..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Indonesian} "Default"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Indonesian} "Terakhir digunakan"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Indonesian} "Khusus"
LangString INST_CHOOSE_LOC4 ${LANG_Indonesian} "Pilih folder untuk memasang ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} di:"
LangString INST_LOC_OW ${LANG_Indonesian} "Peringatan: Sebuah versi utama yang berbeda dari MTA ($1) sudah ada di direktori tersebut."
LangString INST_LOC_UPGRADE ${LANG_Indonesian} "Jenis Pemasangan:  Meningkatkan"
LangString NETTEST_TITLE1 ${LANG_Indonesian} "Pemutakhir daring"
LangString NETTEST_TITLE2 ${LANG_Indonesian} "Sedang memeriksa informasi pembaruan"
LangString NETTEST_STATUS1 ${LANG_Indonesian} "Sedang memeriksa pemasang informasi pembaruan..."
LangString NETTEST_STATUS2 ${LANG_Indonesian} "Pastikan firewall anda tidak memblokir"
!insertmacro MUI_LANGUAGE "Greek"
LangString LANGUAGE_CODE ${LANG_Greek} "el"
LangString GET_XPVISTA_PLEASE ${LANG_Greek} "Η έκδοση του MTA: SA που έχετε κάνει λήψη δεν υποστηρίζει τα Windows XP ή Vista. Παρακαλώ κάντε λήψη μια εναλλακτική έκδοση από το www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Greek} "Η έκδοση του MTA:SA έχει σχεδιαστεί από παλαιότερες εκδόσεις Windows.  Παρακαλώ κατεβάστε την νεότερη έκδοση από το www.mtasa.com."
LangString WELCOME_TEXT ${LANG_Greek} "Αυτός ο οδηγός θα σας καθοδηγήσει μέσα από την εγκατάσταση ή την ενημέρωση των $(^Name) ${REVISION_TAG}\n\nΣυνιστάται να κλείσετε όλες τις άλλες εφαρμογές πριν ξεκινήσετε την εγκατάσταση.\n\n[Η άδεια διαχειριστή μπορεί να ζητηθεί για τις εκδόσεις Vista και πάνω]\n\nΚάντε κλικ στο Επόμενο για να συνεχίσετε."
LangString HEADER_Text ${LANG_Greek} "Grand Theft Auto: San Andreas τοποθεσία"
LangString DIRECTORY_Text_Dest ${LANG_Greek} "Grand Theft Auto: San Andreas φάκελος"
LangString DIRECTORY_Text_Top ${LANG_Greek} "Παρακαλώ επιλέξτε τον φάκελο του Grand Theft Auto: San Andreas.$\n$\nΠΡΕΠΕΙ να έχετε το Grand Theft Auto: San Andreas 1.0 εγκαταστημένο για να χρησιμοποιήσετε το MTA:SA, δεν υποστηρίζει άλλες εκδόσεις.$\n$\nΠατήστε Εγκατάσταση για να αρχίσετε την εγκατάσταση."
LangString DESC_Section10 ${LANG_Greek} "Δημιουργήστε μια ομάδα στο μενού έναρξης για εγκατεστημένες εφαρμογές"
LangString DESC_Section11 ${LANG_Greek} "Δημιουργήστε μια συντόμευση στην επιφάνεια εργασίας για το MTA:SA πρόγραμμα-πελάτης."
LangString DESC_Section12 ${LANG_Greek} "Εγγραφή mtasa:// protocol για την ικανότητα κλικ του περιηγητή."
LangString DESC_Section13 ${LANG_Greek} "Προσθήκη στο Windows Games Explorer (Εάν υπάρχει)."
LangString DESC_DirectX ${LANG_Greek} "Εγκαταστήστε ή ενημερώστε το DirectX (αν απαιτείται)."
LangString DESC_Section1 ${LANG_Greek} "Τα βασικά στοιχεία απαιτούνται για να τρέξεις το Multi Theft Auto."
LangString DESC_Section2 ${LANG_Greek} "Το MTA:SA, σε αφήνει να παίζεις στο διαδίκτυο."
LangString DESC_SectionGroupServer ${LANG_Greek} "Ο διακομιστής του Multi Theft Auto. Αυτός σε αφήνει να διοργανώνεις παιχνίδια από τον υπολογιστή σου. Αυτό προϋποθέτει μια γρήγορη σύνδεση στο διαδίκτυο."
LangString DESC_Section4 ${LANG_Greek} "Ο διακομιστής του Multi Theft Auto. Αυτό είναι ένα απαραίτητο στοιχείο."
LangString DESC_Section5 ${LANG_Greek} "Η MTA:SA μετατροπή για τον διακομιστή."
LangString DESC_Section6 ${LANG_Greek} "Αυτή είναι μία ομάδα απαραίτητων βοηθημάτων για τον διακομιστή."
LangString DESC_Section7 ${LANG_Greek} "Αυτή είναι μία ομάδα προαιρετικών τύπων παιχνιδιών και χαρτών για τον διακομιστή."
LangString DESC_Section8 ${LANG_Greek} "Ο MTA:SA 1.0 Επεξεργαστής Χάρτη. Αυτό μπορεί να χρησιμοποιηθεί για την δημιουργία δικών σου χαρτών για την χρήση τους σε τύπους παιχνιδιών του MTA."
LangString DESC_Section9 ${LANG_Greek} "Αυτό είναι το SDK (Εργαλειοθήκη Ανάπτυξης Λογισμικού) για την δημιουργία δυαδικών δομοστοιχείων για το MTA server. Εγκαταστήστε μόνο εάν έχετε καλή κατανόηση της C++!"
LangString DESC_SectionGroupDev ${LANG_Greek} "Ο κώδικας και τα εργαλεία ανάπτυξης που σε βοηθούν στη δημιουργία μετατροπών για το Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_Greek} "To πρόγραμμα-πελάτης είναι ένα πρόγραμμα που τρέχει έναν Multi Theft Auto διακομιστή"
LangString INST_CLIENTSERVER ${LANG_Greek} "Πρόγραμμα-πελάτης και Διακομιστής"
LangString INST_SERVER ${LANG_Greek} "Διακομιστής μόνο"
LangString INST_STARTMENU_GROUP ${LANG_Greek} "Ομάδα μενού έναρξης"
LangString INST_DESKTOP_ICON ${LANG_Greek} "εικόνα Επιφάνειας εργασίας"
LangString INST_PROTOCOL ${LANG_Greek} "Εγγραφή mtasa:// protocol"
LangString INST_GAMES_EXPLORER ${LANG_Greek} "Προσθήκη στο Games Explorer"
LangString INST_DIRECTX ${LANG_Greek} "Εγκαταστήστε το DirectX"
LangString INST_SEC_CLIENT ${LANG_Greek} "Πρόγραμμα-πελάτης παιχνιδιού"
LangString INST_SEC_SERVER ${LANG_Greek} "Αφοσιωμένος διακομιστής"
LangString INST_SEC_CORE ${LANG_Greek} "Βασικά στοιχεία"
LangString INST_SEC_GAME ${LANG_Greek} "Δομοστοιχεία παιχνιδιού"
LangString INFO_INPLACE_UPGRADE ${LANG_Greek} "αναβάθμιση επί τόπου"
LangString INFO_UPDATE_PERMISSIONS ${LANG_Greek} "Ενημέρωση αδειών. Αυτό μπορεί να διαρκέσει μερικά λεπτά..."
LangString MSGBOX_INVALID_GTASA ${LANG_Greek} "Δεν βρέθηκε έγκυρη έκδοση των Windows του Grand Theft Auto: San Andreas.$\r$\nΩστόσο η εγκατάσταση θα συνεχίσει.$\r$\nΠαρακαλώ επανεγκαταστήστε αν υπάρξουν προβλήματα αργότερα."
LangString INST_SEC_CORE_RESOURCES ${LANG_Greek} "Βασικά βοηθήματα"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Greek} "Προαιρετικά βοηθήματα"
LangString INST_SEC_EDITOR ${LANG_Greek} "Επεξεργαστής"
LangString INST_SEC_DEVELOPER ${LANG_Greek} "Ανάπτυξη"
LangString UNINST_SUCCESS ${LANG_Greek} "$(^Name) επιτυχώς αφαιρέθηκε από τον υπολογιστή σας."
LangString UNINST_FAIL ${LANG_Greek} "Η απεγκατάσταση απέτυχε!"
LangString UNINST_REQUEST ${LANG_Greek} "Είσαι σίγουρος ότι θες να αφαιρέσεις εντελώς $(^Name) και όλα τα στοιχεία του;"
LangString UNINST_REQUEST_NOTE ${LANG_Greek} "Απεγκατάσταση πριν την ενημέρωση;$\r$\nΔεν είναι απαραίτητη η απεγκατάσταση πριν την εγκατάσταση μιας νεότερης έκδοσης του MTA:SA$\r$\nΤρέξτε το νέο πρόγραμμα εγκατάστασης για την αναβάθμιση και την διατήρηση των ρυθμίσεων σας."
LangString UNINST_DATA_REQUEST ${LANG_Greek} "Θα θέλατε να διατηρήσετε όλα τα αρχεία σας (όπως βοηθήματα, αρχεία εικόνας στιγμιοτύπων οθόνης και ρύθμιση παραμέτρων διακοσμητή); Εάν κάνετε κλικ στο όχι, οποιοδήποτε βοήθημα, ρύθμιση ή αρχείο στιγμιότυπου οθόνης που δημιουργήσατε θα χαθεί."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Greek} "Δεν είναι δυνατή η λήψη του λογισμικό ενημέρωσης για την έκδοση του Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Greek} "Δεν είναι δυνατή η εγκατάσταση του λογισμικό ενημέρωσης για την έκδοση του Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_Greek} "Αυτό το πρόγραμμα εγκατάστασης απαιτεί άδεια διαχειριστή, προσπαθήστε πάλι"
LangString UAC_RIGHTS_UN ${LANG_Greek} "Αυτό το πρόγραμμα απεγκατάστασης απαιτεί άδεια διαχειριστή, προσπαθήστε πάλι"
LangString UAC_RIGHTS3 ${LANG_Greek} "Η Εξυπηρέτηση σύνδεσης δεν τρέχει, ματαίωση!"
LangString UAC_RIGHTS4 ${LANG_Greek} "Δεν είναι δυνατή η ανύψωση"
LangString INST_MTA_CONFLICT ${LANG_Greek} "Μια διαφορετική σημαντική έκδοση του MTA ($1) υπάρχει ήδη σε αυτόν τον προορισμό.$\n$\nΤο MTA έχει σχεδιαστεί ώστε οι σημαντικές εκδόσεις να είναι εγκατεστημένες σε διαφορετικούς προορισμούς.$\nΕίσαι σίγουρος ότι θες να αντικαταστήσεις MTA $1 στο $INSTDIR ;"
LangString INST_GTA_CONFLICT ${LANG_Greek} "Το MTA δεν μπορεί να εγκατασταθεί στον ίδιο προορισμό με το GTA:SA.$\n$\nΘες να χρησιμοποιήσεις τον προεπιλεγμένο προορισμό εγκατάστασης$\n$DEFAULT_INSTDIR ;"
LangString INST_GTA_ERROR1 ${LANG_Greek} "Ο επιλεγμένος προορισμός δεν υπάρχει$\n$\nΠαρακαλώ επιλέξτε το προορισμό εγκατάστασης του GTA:SA"
LangString INST_GTA_ERROR2 ${LANG_Greek} "Δεν είναι δυνατή η εύρεση του GTA:SA εγκατεστημένο στο $GTA_DIR $\n$\nΕίστε σίγουρος ότι θέλετε να συνεχίσετε;"
LangString INST_CHOOSE_LOC_TOP ${LANG_Greek} "Επιλέξτε τοποθεσία εγκατάστασης"
LangString INST_CHOOSE_LOC ${LANG_Greek} "Επιλέξτε τον φάκελο στον οποίο θα γίνει εγκατάσταση ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Greek} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} θα εγκατασταθεί στο ακόλουθο φάκελο.$\nΓια να εγκαταστήσετε σε έναν διαφορετικό φάκελο, πατήστε Περιήγηση και επιλέξτε άλλον φάκελο.$\n$\n Πατήστε Επόμενο για να συνεχίσετε."
LangString INST_CHOOSE_LOC3 ${LANG_Greek} "Προορισμός φακέλου"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Greek} "Περιήγηση..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Greek} "Προεπιλογή"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Greek} "Τελευταία χρήση"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Greek} "Προτίμηση"
LangString INST_CHOOSE_LOC4 ${LANG_Greek} "Επιλέξτε τον φάκελο εγκατάστασης ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} στο:"
LangString INST_LOC_OW ${LANG_Greek} "Προειδοποιήση: Μια διαφορετική σημαντική έκδοση του MTA ($1) υπάρχει ήδη σε αυτόν το προορισμό."
LangString INST_LOC_UPGRADE ${LANG_Greek} "Τύπος εγκατάστασης: Αναβάθμιση"
LangString NETTEST_TITLE1 ${LANG_Greek} "Ενημέρωση σε σύνδεση"
LangString NETTEST_TITLE2 ${LANG_Greek} "Έλεγχος για πληροφορίες ενημέρωσης"
LangString NETTEST_STATUS1 ${LANG_Greek} "Έλεγχος για πληροφορίες προγράμματος ενημέρωσης..."
LangString NETTEST_STATUS2 ${LANG_Greek} "Παρακαλώ εξασφαλίστε ότι το πρόγραμμα προστασίας σας δεν εμποδίζει"
!insertmacro MUI_LANGUAGE "SimpChinese"
LangString LANGUAGE_CODE ${LANG_SimpChinese} "zh_CN"
LangString GET_XPVISTA_PLEASE ${LANG_SimpChinese} "您下载的MTA:SA并不支持 Windows XP or Vista. 请在www.mtasa.com下载相应版本."
LangString GET_MASTER_PLEASE ${LANG_SimpChinese} "您下载的MTA:SA的版本是针对老系统专用的版本. 请在www.mtasa.com下载相应的系统版本."
LangString WELCOME_TEXT ${LANG_SimpChinese} "本向导将会引导您安装或更新 $(^Name) ${REVISION_TAG}\n\n我们建议您在安装前关闭其他软件。\n\n[Vista 及以上版本可能需要使用管理员身份运行]\n\n点击下一步继续。"
LangString HEADER_Text ${LANG_SimpChinese} "侠盗猎车手: 圣安地列斯的安装路径"
LangString DIRECTORY_Text_Dest ${LANG_SimpChinese} "侠盗猎车手: 圣安地列斯所在的文件夹"
LangString DIRECTORY_Text_Top ${LANG_SimpChinese} "请选择你的侠盗猎车手: 圣安地列斯所在的文件夹。$\n$\nMTA:SA 需要 1.0 版本的侠盗猎车手: 圣安地列斯，MTA:SA 不支持其他版本的侠盗猎车手: 圣安地列斯。$\n$\n请点击安装按钮开始安装。"
LangString DESC_Section10 ${LANG_SimpChinese} "为程序创建开始菜单组"
LangString DESC_Section11 ${LANG_SimpChinese} "为 MTA:SA 客户端创建桌面快捷方式。"
LangString DESC_Section12 ${LANG_SimpChinese} "为浏览器注册 mtasa:// 超链接协议。"
LangString DESC_Section13 ${LANG_SimpChinese} "增加到 Windows 游戏管理器 (如果存在的话)。"
LangString DESC_DirectX ${LANG_SimpChinese} "安装或更新 DirectX （如果需要）"
LangString DESC_Section1 ${LANG_SimpChinese} "运行 Multi Theft Auto 需要核心组件。"
LangString DESC_Section2 ${LANG_SimpChinese} "MTA:SA MOD 允许您在线与其他玩家一同游玩。"
LangString DESC_SectionGroupServer ${LANG_SimpChinese} "Multi Theft Auto 服务器。您可以在自己的电脑上创建游戏服务器主机。这将需要足够带宽的互联网连接。"
LangString DESC_Section4 ${LANG_SimpChinese} "Multi Theft Auto 服务器。这是必须安装的组件。"
LangString DESC_Section5 ${LANG_SimpChinese} "服务器的 MTA:SA Mod 支持模块。"
LangString DESC_Section6 ${LANG_SimpChinese} "这是游戏服务器需求的资源文件集合。"
LangString DESC_Section7 ${LANG_SimpChinese} "这是一个可选的服务器端游戏模式和地图包。"
LangString DESC_Section8 ${LANG_SimpChinese} "MTA:SA 1.0 地图编辑器。它可以用来创建您自己的地图，将在 MTA 游戏模式里被使用。"
LangString DESC_Section9 ${LANG_SimpChinese} "这是用于开发 MTA 服务器端二进制模块的软件开发工具包(SDK)。仅供熟悉 C++ 的用户安装。"
LangString DESC_SectionGroupDev ${LANG_SimpChinese} "帮助您开发 MTA Mod 的开发代码和工具包"
LangString DESC_SectionGroupClient ${LANG_SimpChinese} "让你可以在 Multi Theft Auto 服务器上游玩的客户端程序。"
LangString INST_CLIENTSERVER ${LANG_SimpChinese} "客户端及服务器端"
LangString INST_SERVER ${LANG_SimpChinese} "仅安装服务器端"
LangString INST_STARTMENU_GROUP ${LANG_SimpChinese} "创建开始菜单组"
LangString INST_DESKTOP_ICON ${LANG_SimpChinese} "创建桌面快捷方式"
LangString INST_PROTOCOL ${LANG_SimpChinese} "注册 mtasa:// 协议"
LangString INST_GAMES_EXPLORER ${LANG_SimpChinese} "加入游戏管理器菜单"
LangString INST_DIRECTX ${LANG_SimpChinese} "安装 DIrectX"
LangString INST_SEC_CLIENT ${LANG_SimpChinese} "游戏客户端"
LangString INST_SEC_SERVER ${LANG_SimpChinese} "专用服务器"
LangString INST_SEC_CORE ${LANG_SimpChinese} "核心组件"
LangString INST_SEC_GAME ${LANG_SimpChinese} "游戏模块"
LangString INFO_INPLACE_UPGRADE ${LANG_SimpChinese} "正在升级中…"
LangString INFO_UPDATE_PERMISSIONS ${LANG_SimpChinese} "更新权限中。这将可能花费一些时间..."
LangString MSGBOX_INVALID_GTASA ${LANG_SimpChinese} "没有检测到可用的 Windows 版本的 侠盗猎车手: 圣安地列斯 游戏文件。$\r$\n安装程序仍将继续。$\r$\n如果 MTA 安装后出现问题，请重新安装 GTA:SA 。"
LangString INST_SEC_CORE_RESOURCES ${LANG_SimpChinese} "核心资源"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_SimpChinese} "可选资源"
LangString INST_SEC_EDITOR ${LANG_SimpChinese} "编辑器"
LangString INST_SEC_DEVELOPER ${LANG_SimpChinese} "开发包"
LangString UNINST_SUCCESS ${LANG_SimpChinese} "$(^Name) 已成功从您的电脑中卸载。"
LangString UNINST_FAIL ${LANG_SimpChinese} "卸载失败!"
LangString UNINST_REQUEST ${LANG_SimpChinese} "你确定要完全删除 $(^Name) 和相关组件吗?"
LangString UNINST_REQUEST_NOTE ${LANG_SimpChinese} "在安装更新前卸载旧版本?$\r$\n安装新版本 MTA:SA 时没有必要卸载旧版本$\r$\n运行新版本的安装程序以升级和你的数据."
LangString UNINST_DATA_REQUEST ${LANG_SimpChinese} "您要保留您的个人数据 (例如资源，游戏截图和服务器配置文件) 吗? 如果你选择否，所有资源、配置文件或截图都将会被删除。"
LangString MSGBOX_PATCH_FAIL1 ${LANG_SimpChinese} "无法下载适用于您的侠盗猎车手: 圣安地列斯对应版本的补丁文件"
LangString MSGBOX_PATCH_FAIL2 ${LANG_SimpChinese} "无法安装适用于您的侠盗猎车手: 圣安地列斯对应版本的补丁文件"
LangString UAC_RIGHTS1 ${LANG_SimpChinese} "此安装程序需要以系统管理员身份执行，请重试"
LangString UAC_RIGHTS_UN ${LANG_SimpChinese} "此卸载程序需要以系统管理员身份执行，请重试"
LangString UAC_RIGHTS3 ${LANG_SimpChinese} "Logon 服务没有运行，异常终止!"
LangString UAC_RIGHTS4 ${LANG_SimpChinese} "无法提升"
LangString INST_MTA_CONFLICT ${LANG_SimpChinese} "不同主版本的 MTA ($1) 已安装在该目录里。$\n$\nMTA 特意设计成不同版本可以在不同路径中同时共存。$\n您确定要覆盖 MTA $1 到目录 $INSTDIR 吗?"
LangString INST_GTA_CONFLICT ${LANG_SimpChinese} "MTA 无法与 GTA:SA 安装在同一目录.$\n$\n你想要把它安装在默认安装目录.$\n$DEFAULT_INSTDIR 吗?"
LangString INST_GTA_ERROR1 ${LANG_SimpChinese} "所选的目录不存在。$\n$\n请选择 GTA:SA 的安装目录"
LangString INST_GTA_ERROR2 ${LANG_SimpChinese} "无法在 $GTA_DIR 中找到 GTA:SA 的游戏文件 $\n$\n您确定要继续安装吗 ?"
LangString INST_CHOOSE_LOC_TOP ${LANG_SimpChinese} "选择安装的位置"
LangString INST_CHOOSE_LOC ${LANG_SimpChinese} "请选择用于安装 ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} 的目录"
LangString INST_CHOOSE_LOC2 ${LANG_SimpChinese} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} 将会被安装到以下目录。$\n如想要安装到其他目录，请点击“浏览”按钮并且选择其他的目录。$\n$\n点击下一步继续。"
LangString INST_CHOOSE_LOC3 ${LANG_SimpChinese} "目标文件夹"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_SimpChinese} "浏览..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_SimpChinese} "默认"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_SimpChinese} "上次使用的"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_SimpChinese} "自定义"
LangString INST_CHOOSE_LOC4 ${LANG_SimpChinese} "请选择将要安装 ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} 的文件夹:"
LangString INST_LOC_OW ${LANG_SimpChinese} "警告: 一个不同主版本的 MTA ($1) 已安装在该目录。"
LangString INST_LOC_UPGRADE ${LANG_SimpChinese} "安装类型: 升级"
LangString NETTEST_TITLE1 ${LANG_SimpChinese} "在线更新"
LangString NETTEST_TITLE2 ${LANG_SimpChinese} "正在检查更新信息"
LangString NETTEST_STATUS1 ${LANG_SimpChinese} "正在检查安装包更新信息..."
LangString NETTEST_STATUS2 ${LANG_SimpChinese} "请确认您的防火墙没有阻止连接"
!insertmacro MUI_LANGUAGE "Latvian"
LangString LANGUAGE_CODE ${LANG_Latvian} "lv"
LangString WELCOME_TEXT ${LANG_Latvian} "Šī instalācija palīdzēs Jums uzinstalēt vai atjaunināt $(^Name) ${REVISION_TAG}\n\nIeteicams aizvērt visas citas aplikācijas, pirms uzsākat instalāciju.\n\n[Administratora piekļuve var tikt pieprasīta priekš Windows Vista un jaunākām OS]\n\nSpiediet Tālāk, lai turpinātu."
LangString HEADER_Text ${LANG_Latvian} "Grand Theft Auto: San Andreas atrašanās vieta"
LangString DIRECTORY_Text_Dest ${LANG_Latvian} "Grand Theft Auto: San Andreas mape"
LangString DIRECTORY_Text_Top ${LANG_Latvian} "Lūdzu izvēlieties Grand Theft Auto: San Andreas mapi.$\n$\nJums IR jābūt uzinstalētam Grand Theft Auto: San Andreas 1.0 lai varētu izmantot MTA:SA, MTA:SA neatbalsta citas versijas.$\n$\nSpiediet Instalēt lai uzsāktu instalāciju."
LangString DESC_Section10 ${LANG_Latvian} "Izveidot Start Menu grupu priekš instalētajām aplikācijām"
LangString DESC_Section11 ${LANG_Latvian} "Izveidot darbvirsmas saīsni priekš MTA:SA Klienta."
LangString DESC_Section12 ${LANG_Latvian} "Reģistrēt mtasa:// protokolu priekš interneta pārlūka."
LangString DESC_Section13 ${LANG_Latvian} "Pievienot pie Windows Spēļu Pārlūkotāja (ja tāds ir)."
LangString DESC_Section1 ${LANG_Latvian} "Galvenie elementi, kuri nepieciešami, lai palaistu Multi Theft Auto."
LangString DESC_Section2 ${LANG_Latvian} "MTA:SA modifikācija ļauj Jums spēlēt tiešsaistē."
LangString DESC_SectionGroupServer ${LANG_Latvian} "Multi Theft Auto Serveris. Šis ļaus Jums izveidot serveri uz Jūsu datora. Pieprasa ātru interneta savienojumu."
LangString DESC_Section4 ${LANG_Latvian} "Multi Theft Auto serveris. Šī ir nepieciešama sastāvdaļa."
LangString DESC_Section5 ${LANG_Latvian} "MTA:SA modifikācija priekš servera."
LangString DESC_Section6 ${LANG_Latvian} "Šie ir nepieciešamie resursi priekš jūsu servera."
LangString DESC_Section7 ${LANG_Latvian} "Šie ir nepieciešamie spēļu veidi un mapes priekš jūsu servera."
LangString DESC_Section8 ${LANG_Latvian} "MTA:SA 1.0 Map Editors.   Šo var izmantot, lai izveidotu pats savas mapes un izmantotu tos MTA serveros."
LangString DESC_Section9 ${LANG_Latvian} "Šis ir SDK rīks, lai izveidotu bināros moduļus priekš MTA servera. Instalēt tikai tad, ja Jūs saprotat C++!"
LangString DESC_SectionGroupDev ${LANG_Latvian} "Izstrādātāja kodi un rīki, kuri ir nepieciešami, lai izstrādātu Multi Theft Auto modifikācijas"
LangString DESC_SectionGroupClient ${LANG_Latvian} "Klients ir programma, kuru Jūs izmantojat, lai spēlēti iekš Multi Theft Auto serveriem"
LangString INST_CLIENTSERVER ${LANG_Latvian} "Klients un Serveris"
LangString INST_SERVER ${LANG_Latvian} "Tikai serveris"
LangString INST_STARTMENU_GROUP ${LANG_Latvian} "Izvēlnes sākt grupa"
LangString INST_DESKTOP_ICON ${LANG_Latvian} "Darbvirsmas ikona"
LangString INST_PROTOCOL ${LANG_Latvian} "Reģistrēt mtasa:// protokolu"
LangString INST_GAMES_EXPLORER ${LANG_Latvian} "Pievienot pie Spēļu Pārlukotāja"
LangString INST_SEC_CLIENT ${LANG_Latvian} "Spēles klients"
LangString INST_SEC_SERVER ${LANG_Latvian} "Serveris"
LangString INST_SEC_CORE ${LANG_Latvian} "Kodola komponenti"
LangString INST_SEC_GAME ${LANG_Latvian} "Spēles modulis"
LangString INFO_INPLACE_UPGRADE ${LANG_Latvian} "Veicina ievietošanas atjauninājumu..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Latvian} "Atjauno atļaujas. Tas var aizņemt pāris minūtes..."
LangString MSGBOX_INVALID_GTASA ${LANG_Latvian} "Derīga Windows versija priekš Grand Theft Auto: San Andreas netika atrasta.$\r$\nJebkurā ziņā, instalācija tiks turpināta.$\r$\nLūdzu pārinstalējiet, ja ir kaut kādas problēmas."
LangString INST_SEC_CORE_RESOURCES ${LANG_Latvian} "Kodola Resursi"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Latvian} "Ieteicamie Resursi"
LangString INST_SEC_EDITOR ${LANG_Latvian} "Editors"
LangString INST_SEC_DEVELOPER ${LANG_Latvian} "Izstrādāšana"
LangString UNINST_SUCCESS ${LANG_Latvian} "$(^Name) tikai sekmīgi noņemts no jūsu datora."
LangString UNINST_FAIL ${LANG_Latvian} "Atinstalēšana neizdevās!"
LangString UNINST_REQUEST ${LANG_Latvian} "Vai Jūs tik tiešām vēlaties noņemt $(^Name) un visus tā komponentus?"
LangString UNINST_REQUEST_NOTE ${LANG_Latvian} "Attisntelēšana atjauninājuma laikā?$\r$\nMēs Jums neiesakam attinstalēt spēli, laikā kad tiek instalēta jaunā MTA:SA versija.$\r$\nStartējiet jaunu instalāciju, un saglabājat arī savus iestatijumus."
LangString UNINST_DATA_REQUEST ${LANG_Latvian} "Vai Jūs vēlaties paturēt datu failus (tādus kā resursu, ekrānšāviņus un servera konfigurācijas)? Ja nospiedīsiet nē, jebkuri resursi, konfigurācijas, vai ekrānšāviņi tiks dzēsti."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Latvian} "Neizdevās lejupielādēt ielāpa failu priekš Jūsu Grand Theft Auto: San Andreas versijas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Latvian} "Neizdevās uzinstalēt ielāpa failu uz Jūsu Grand Theft Auto: San Andreas versiju"
LangString UAC_RIGHTS1 ${LANG_Latvian} "Instalācija pieprasa administratora piekļuvi, mēģiniet vēlreiz"
LangString UAC_RIGHTS_UN ${LANG_Latvian} "Atinstalators pieprasa administratora piekļuvi, mēģiniet vēlreiz"
LangString UAC_RIGHTS3 ${LANG_Latvian} "Logon pakalpojums nedarbojās, atceļ!"
LangString UAC_RIGHTS4 ${LANG_Latvian} "Nespēj pacelt"
LangString INST_MTA_CONFLICT ${LANG_Latvian} "Cita MTA ($1) versija jau eksistē šajā ceļā.$\n$\nMTA ir veidots tā, lai katra versija būtu instalēta savā, attiecīgajā ceļā..$\nVai Jūs tik tiešām vēlaties pārrakstīt MTA $1 iekš $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_Latvian} "MTA nevar būt instalēts tajā pašā vietā, kur atrodas GTA:SA.$\n$\nVai vēlaties izmantot standarta instalācijas vietu$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Latvian} "Izvēlētā mape neeksitē.$\n$\nLūdzu izvēlieties GTA:SA instalācijas mapi"
LangString INST_GTA_ERROR2 ${LANG_Latvian} "Nespēj atrast GTA:SA instalāciju iekš $GTA_DIR $\n$\nVai esat pārliecināts ka vēlaties turpināt ?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Latvian} "Izvēlēties Instalācijas Atrašanās Vietu"
LangString INST_CHOOSE_LOC ${LANG_Latvian} "Izvēlieties mapi, kurā tiks instalēts ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Latvian} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} tiks instalēdz sekojošā mapē.$\nLai instalētu citā mapē, spiediet pārlūkot un izvēlieties citu mapi.$\n$\nSpiediet tālāk, lai turpinātu."
LangString INST_CHOOSE_LOC3 ${LANG_Latvian} "Mērķa Mape"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Latvian} "Pārmeklēt..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Latvian} "Sākotnējs"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Latvian} "Pēdējais izmantotais"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Latvian} "Pielāgots"
LangString INST_CHOOSE_LOC4 ${LANG_Latvian} "Izvēlieties mapi, lai uzinstalētu ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} in:"
LangString INST_LOC_OW ${LANG_Latvian} "Brīdinājums: Cita MTA ($1) jau eksistē šajā ceļā."
LangString INST_LOC_UPGRADE ${LANG_Latvian} "Instalācijas tips:   Atjauninājums"
LangString NETTEST_TITLE1 ${LANG_Latvian} "Tiešsaistes atjauninājums"
LangString NETTEST_TITLE2 ${LANG_Latvian} "Pārbauda atjauninājumu informāciju"
LangString NETTEST_STATUS1 ${LANG_Latvian} "Pārbauda instalācijas informācijas atjaunošanu"
LangString GET_XPVISTA_PLEASE ${LANG_Latvian} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Latvian} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString DESC_DirectX ${LANG_Latvian} "Install or update DirectX (if required)."
LangString INST_DIRECTX ${LANG_Latvian} "Install DirectX"
LangString NETTEST_STATUS2 ${LANG_Latvian} "Please ensure your firewall is not blocking"
!insertmacro MUI_LANGUAGE "PortugueseBR"
LangString LANGUAGE_CODE ${LANG_PortugueseBR} "pt_BR"
LangString GET_XPVISTA_PLEASE ${LANG_PortugueseBR} "A versão do MTA:SA que você baixou não suporta o Windows XP ou Vista. Por favor, baixe uma versão alternativa em www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_PortugueseBR} "Esta versão do MTA:SA foi projetada para versões antigas do Windows. Por favor, baixe a versão mais recente em www.mtasa.com."
LangString WELCOME_TEXT ${LANG_PortugueseBR} "Este assistente irá lhe guiar durante a instalação ou atualização do $(^Name) ${REVISION_TAG}\n\nÉ recomendado fechar todos os programas abertos antes de prosseguir.\n\nLembrando que o acesso de administrador poderá ser necessário no Windows Vista ou superior.\n\nClique em Próximo para continuar."
LangString HEADER_Text ${LANG_PortugueseBR} "Diretório de Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_PortugueseBR} "Pasta do Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Top ${LANG_PortugueseBR} "Selecione a pasta onde Grand Theft Auto: San Andreas foi instalado.$\n $\nVocê DEVE ter a versão 1.0 do Grand Theft Auto: San Andreas para usar o MTA:SA, outras versões não são suportadas.$\n $\nClique em Instalar para iniciar a instalação."
LangString DESC_Section10 ${LANG_PortugueseBR} "Criar um grupo no Meu Iniciar para os aplicativos instalados"
LangString DESC_Section11 ${LANG_PortugueseBR} "Criar um atalho do MTA:SA na Área de Trabalho."
LangString DESC_Section12 ${LANG_PortugueseBR} "Registrar o protocolo mtasa:// para os navegadores redirecionarem algum link contendo este prefixo."
LangString DESC_Section13 ${LANG_PortugueseBR} "Adicionar ao Explorador de Jogos do Windows (se disponível)."
LangString DESC_DirectX ${LANG_PortugueseBR} "Instalar ou atualizar o DirectX (se necessário)."
LangString DESC_Section1 ${LANG_PortugueseBR} "Componentes necessários para executar o Multi Theft Auto."
LangString DESC_Section2 ${LANG_PortugueseBR} "A Modificação MTA:SA, que te permitirá jogar on-line."
LangString DESC_SectionGroupServer ${LANG_PortugueseBR} "O Servidor do Multi Theft Auto. Ele permite hospedar um jogo a partir do seu computador. É necessário ter uma boa conexão com a internet."
LangString DESC_Section4 ${LANG_PortugueseBR} "O Servidor do Multi Theft Auto. Este é um componente necessário."
LangString DESC_Section5 ${LANG_PortugueseBR} "A modificação MTA:SA para o servidor."
LangString DESC_Section6 ${LANG_PortugueseBR} "Scripts fundamentais para o funcionamento correto do servidor."
LangString DESC_Section7 ${LANG_PortugueseBR} "Pacote opcional de scripts e mapas para seu servidor."
LangString DESC_Section8 ${LANG_PortugueseBR} "O Editor de Mapas do MTA:SA 1.0. Ele é utilizado para criar seus próprios mapas para o seu modo de jogo do MTA."
LangString DESC_Section9 ${LANG_PortugueseBR} "O SDK (Kit de Desenvolvimento de Software) permite desenvolver módulos para o servidor do MTA. É recomendado para aqueles com conhecimento em C++."
LangString DESC_SectionGroupDev ${LANG_PortugueseBR} "Contém códigos e ferramentas com finalidade de auxiliar na criação de extensões para o Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_PortugueseBR} "Programa que lhe permite jogar em um servidor de MTA."
LangString INST_CLIENTSERVER ${LANG_PortugueseBR} "Cliente e Servidor"
LangString INST_SERVER ${LANG_PortugueseBR} "Somente Servidor"
LangString INST_STARTMENU_GROUP ${LANG_PortugueseBR} "Atalhos no Menu Iniciar"
LangString INST_DESKTOP_ICON ${LANG_PortugueseBR} "Ícone na Área de Trabalho"
LangString INST_PROTOCOL ${LANG_PortugueseBR} "Registrar o protocolo mtasa://"
LangString INST_GAMES_EXPLORER ${LANG_PortugueseBR} "Atalho na pasta Jogos do Windows"
LangString INST_DIRECTX ${LANG_PortugueseBR} "Instale o DirectX"
LangString INST_SEC_CLIENT ${LANG_PortugueseBR} "Cliente"
LangString INST_SEC_SERVER ${LANG_PortugueseBR} "Servidor"
LangString INST_SEC_CORE ${LANG_PortugueseBR} "Componentes essenciais"
LangString INST_SEC_GAME ${LANG_PortugueseBR} "Módulo do Jogo"
LangString INFO_INPLACE_UPGRADE ${LANG_PortugueseBR} "Realizando uma atualização..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_PortugueseBR} "Atualizando permissões. Isto pode levar alguns minutos..."
LangString MSGBOX_INVALID_GTASA ${LANG_PortugueseBR} "Uma versão válida do Grand Theft Auto: San Andreas para Windows não foi encontrada.$\r$\nPorém, a instalação continuará mesmo assim.$\r$\nPor favor, reinstale caso houver problemas após a instalação."
LangString INST_SEC_CORE_RESOURCES ${LANG_PortugueseBR} "Recursos Principais"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_PortugueseBR} "Recursos Opcionais"
LangString INST_SEC_EDITOR ${LANG_PortugueseBR} "Editor"
LangString INST_SEC_DEVELOPER ${LANG_PortugueseBR} "Desenvolvimento"
LangString UNINST_SUCCESS ${LANG_PortugueseBR} "$(^Name) foi removido com sucesso de seu computador."
LangString UNINST_FAIL ${LANG_PortugueseBR} "A desinstalação falhou!"
LangString UNINST_REQUEST ${LANG_PortugueseBR} "Você tem certeza que deseja remover completamente o $(^Name) e todos os seus componentes?"
LangString UNINST_REQUEST_NOTE ${LANG_PortugueseBR} "Desinstalar antes de atualizar?$\r$\nNão é necessário desinstalar a versão anterior antes de instalar uma nova versão do MTA:SA$\r$\nExecute o novo instalador para atualizar e preservar as suas configurações."
LangString UNINST_DATA_REQUEST ${LANG_PortugueseBR} "Você gostaria de manter os seus dados, como scripts, captura de tela e configurações do servidor? Se optar por não manter, todos os scripts, configurações ou capturas de tela serão apagados."
LangString MSGBOX_PATCH_FAIL1 ${LANG_PortugueseBR} "Não foi possível baixar o patch para sua versão do Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_PortugueseBR} "Não foi possível instalar o patch para sua versão do Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_PortugueseBR} "Este instalador necessita de acesso do administrador, tente novamente."
LangString UAC_RIGHTS_UN ${LANG_PortugueseBR} "Este desinstalador necessita de acesso do administrador, tente novamente."
LangString UAC_RIGHTS3 ${LANG_PortugueseBR} "O serviço 'Logon' não está em execução, a instalação será abortada!"
LangString UAC_RIGHTS4 ${LANG_PortugueseBR} "Não foi possível obter o direito de execução necessário"
LangString INST_MTA_CONFLICT ${LANG_PortugueseBR} "A versão $1 do MTA já existe neste diretório.$\n$\nO MTA foi projetado para que versões diferentes sejam instaladas em diretórios separados.$\nVocê tem certeza que deseja substituir o MTA $1 em $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_PortugueseBR} "O MTA:SA não pode ser instalado no mesmo diretório do GTA:SA.$\n$\nDeseja utilizar o diretório de instalação padrão$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_PortugueseBR} "O diretório selecionado não existe.$\n$\nSelecione o diretório onde o GTA:SA está instalado"
LangString INST_GTA_ERROR2 ${LANG_PortugueseBR} "Não foi possível encontrar o GTA:SA em $GTA_DIR $\n$\nVocê tem certeza que deseja continuar?"
LangString INST_CHOOSE_LOC_TOP ${LANG_PortugueseBR} "Selecione o local da Instalação"
LangString INST_CHOOSE_LOC ${LANG_PortugueseBR} "Selecione a pasta em que será instalado o ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_PortugueseBR} "O ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} será instalado na pasta selecionada.$\nPara instalá-lo em uma outra pasta, vá em Procurar e selecione uma outra pasta.$\n$\nClique em Seguinte para continuar."
LangString INST_CHOOSE_LOC3 ${LANG_PortugueseBR} "Pasta de Destino"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_PortugueseBR} "Procurar..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_PortugueseBR} "Padrão"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_PortugueseBR} "Usado recentemente"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_PortugueseBR} "Customizado"
LangString INST_CHOOSE_LOC4 ${LANG_PortugueseBR} "Selecione a pasta onde será instalado o ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} :"
LangString INST_LOC_OW ${LANG_PortugueseBR} "Atenção: Uma outra versão do MTA ($1) já está instalada neste diretório."
LangString INST_LOC_UPGRADE ${LANG_PortugueseBR} "Tipo de instalação: Atualização"
LangString NETTEST_TITLE1 ${LANG_PortugueseBR} "Atualização on-line"
LangString NETTEST_TITLE2 ${LANG_PortugueseBR} "Verificando informações da atualização"
LangString NETTEST_STATUS1 ${LANG_PortugueseBR} "Verificando informações do instalador..."
LangString NETTEST_STATUS2 ${LANG_PortugueseBR} "Certifique-se que o seu firewall não esteja bloqueando este processo"
!insertmacro MUI_LANGUAGE "Italian"
LangString LANGUAGE_CODE ${LANG_Italian} "it"
LangString WELCOME_TEXT ${LANG_Italian} "Questo wizard ti guiderà attraverso l'installazione o l'aggiornamento di $(^Name) ${REVISION_TAG}\n\nSi raccomanda di chiudere tutte le applicazioni prima di avviare il Setup.\n\n[L'avvio come amministratore potrebbe essere richiesto per Vista o superiori]\n\nClicca su avanti per continuare."
LangString HEADER_Text ${LANG_Italian} "Location di Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_Italian} "Folder di Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Top ${LANG_Italian} "Per favore seleziona la cartella principale di Grand Theft Auto: San Andreas .$\n$\nÈ OBBLIGATORIO utilizzare la versione 1.0 di Grand Theft Auto: San Andreas, MTA:SA non supporta nessuna altra versione$\n$\nClicca su installa per iniziare l'installazione."
LangString DESC_Section10 ${LANG_Italian} "Crea un menu di gruppo di Start per le applicazioni installate"
LangString DESC_Section11 ${LANG_Italian} "Crea un collegamento sul Desktop per MTA:SA Client"
LangString DESC_Section12 ${LANG_Italian} "Registra il protocollo mtasa:// per un ness clickabile del browser."
LangString DESC_Section13 ${LANG_Italian} "Aggiungi a Windows Game Explorer (se presente)."
LangString DESC_Section1 ${LANG_Italian} "I componenti principali richiesti per utilizzare Multi Theft Auto."
LangString DESC_Section2 ${LANG_Italian} "Le opzioni di MTA:SA, permettendoti di giocare online."
LangString DESC_SectionGroupServer ${LANG_Italian} "Il server di Multi Theft Auto. Questo componente permette di ospitare le partite dal proprio computer. Questo componente richiede una connessione ad internet veloce."
LangString DESC_Section4 ${LANG_Italian} "Il server di Multi Theft Auto. Questo è un componente obbligatorio."
LangString DESC_Section5 ${LANG_Italian} "Le opzioni di MTA:SA per il server."
LangString DESC_Section6 ${LANG_Italian} "Questo è un insieme di risorse richieste per il tuo server."
LangString DESC_Section7 ${LANG_Italian} "Questo è un set opzionale di modalità e mappe per il tuo server."
LangString DESC_Section8 ${LANG_Italian} "L'editor di mappe di MTA:SA 1.0. Può essere usato per creare le proprie mappe da utilizzare nelle modalità di MTA."
LangString DESC_Section9 ${LANG_Italian} "Questo è l'SDK per creare moduli binari per il server di MTA. Installazione consigliata a chi possiede una buona conoscenza del C++!"
LangString DESC_SectionGroupDev ${LANG_Italian} "Codici di sviluppo e strumenti che aiutano nella creazione di mods per Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_Italian} "Il client è il programma da utilizzare per giocare su un server di Multi Theft Auto"
LangString INST_CLIENTSERVER ${LANG_Italian} "Client e Server"
LangString INST_SERVER ${LANG_Italian} "Solo server"
LangString INST_STARTMENU_GROUP ${LANG_Italian} "Gruppo di menu Start"
LangString INST_DESKTOP_ICON ${LANG_Italian} "Icona del Desktop"
LangString INST_PROTOCOL ${LANG_Italian} "Registra il protocollo mtasa://"
LangString INST_GAMES_EXPLORER ${LANG_Italian} "Aggiungi a Games Explorer"
LangString INST_SEC_CLIENT ${LANG_Italian} "Client di gioco"
LangString INST_SEC_SERVER ${LANG_Italian} "Server dedicato"
LangString INST_SEC_CORE ${LANG_Italian} "Componenti principali"
LangString INST_SEC_GAME ${LANG_Italian} "Modulo di gioco"
LangString INFO_INPLACE_UPGRADE ${LANG_Italian} "Esecuzione sul posto di un aggiornamento..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Italian} "Aggiornamento delle autorizzazioni. Questo potrebbe richiedere qualche minuto..."
LangString MSGBOX_INVALID_GTASA ${LANG_Italian} "Una versione di Windows valida di Grand Theft Auto: San Andreas non è stata trovata.$\r$\nL'installazione continuerà ugualmente.$\r$\nIn caso di problemi è consigliato ripetere l'installazione."
LangString INST_SEC_CORE_RESOURCES ${LANG_Italian} "Risorse principali"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Italian} "Risorse opzionali "
LangString INST_SEC_EDITOR ${LANG_Italian} "Editor"
LangString INST_SEC_DEVELOPER ${LANG_Italian} "Sviluppo "
LangString UNINST_SUCCESS ${LANG_Italian} "$(^Name) è stato rimosso con successo dal tuo computer."
LangString UNINST_FAIL ${LANG_Italian} "La disinstallazione è fallita!"
LangString UNINST_REQUEST ${LANG_Italian} "Sei sicuro di voler rimuovere completamente $(^Name) e tutti i suoi componenti?"
LangString UNINST_DATA_REQUEST ${LANG_Italian} "Vuoi mantenere tutti i tuoi file dati (come risorse, screenshot e configurazioni del server)? Se clicchi no, qualsiasi risorsa, configurazione o screenshot creato sarà perso."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Italian} "Impossibile scaricare i file della patch per la tua versione di Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Italian} "Impossibile installare i file della patch per la tua versione di Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_Italian} "Questo programma d'installazione richiede l'accesso come amministratore, prova di nuovo"
LangString UAC_RIGHTS_UN ${LANG_Italian} "Questo programma di disinstallazione richiede l'accesso come amministratore, prova di nuovo"
LangString UAC_RIGHTS3 ${LANG_Italian} "Servizio di Logon non funzionante, interruzione!"
LangString UAC_RIGHTS4 ${LANG_Italian} "Impossibile elevare "
LangString INST_MTA_CONFLICT ${LANG_Italian} "Una versione maggiore differente di MTA ($1) esiste già in quel percorso.$\n$\nMTA è progettato per installare le versioni maggiori in un percorso differente.$\nSei sicuro di voler sovrascrivere MTA $1 in $INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Italian} "La directory selezionata non esiste$\n$\nPer favore seleziona la directory di installazione di GTA:SA"
LangString INST_GTA_ERROR2 ${LANG_Italian} "Impossibile trovare GTA:SA installato in$GTA_DIR $\n$\nSei sicuro di voler continuare?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Italian} "Scegliere la location di installazione"
LangString INST_CHOOSE_LOC ${LANG_Italian} "Scegliere la cartella di installazione per ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Italian} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} verrà installato nella seguente cartella.$\nPer installare in una cartella differente, clicca su Sfoglia e seleziona un'altra cartella.$\n$\nClicca su Avanti per continuare."
LangString INST_CHOOSE_LOC3 ${LANG_Italian} "Cartella di destinazione"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Italian} "Sfoglia..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Italian} "Predefinito"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Italian} "Ultimo utilizzo"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Italian} "Personalizzato"
LangString INST_CHOOSE_LOC4 ${LANG_Italian} "Scegli la cartella di installazione per ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}:"
LangString INST_LOC_OW ${LANG_Italian} "Attenzione: una versione maggiore diversa di MTA ($1) è già presente in quel percorso."
LangString INST_LOC_UPGRADE ${LANG_Italian} "Tipo di installazione: Aggiornamento"
LangString GET_XPVISTA_PLEASE ${LANG_Italian} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Italian} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString DESC_DirectX ${LANG_Italian} "Install or update DirectX (if required)."
LangString INST_DIRECTX ${LANG_Italian} "Install DirectX"
LangString UNINST_REQUEST_NOTE ${LANG_Italian} "Uninstalling before update?$\r$\nIt is not necessary to uninstall before installing a new version of MTA:SA$\r$\nRun the new installer to upgrade and preserve your settings."
LangString INST_GTA_CONFLICT ${LANG_Italian} "MTA cannot be installed into the same directory as GTA:SA.$\n$\nDo you want to use the default install directory$\n$DEFAULT_INSTDIR ?"
LangString NETTEST_TITLE1 ${LANG_Italian} "Online update"
LangString NETTEST_TITLE2 ${LANG_Italian} "Checking for update information"
LangString NETTEST_STATUS1 ${LANG_Italian} "Checking for installer update information..."
LangString NETTEST_STATUS2 ${LANG_Italian} "Please ensure your firewall is not blocking"
!insertmacro MUI_LANGUAGE "Czech"
LangString LANGUAGE_CODE ${LANG_Czech} "cs"
LangString GET_XPVISTA_PLEASE ${LANG_Czech} "Verze MTA:SA, kterou jste stáhl nepodporuje Windows XP nebo Vista. Prosím, stáhněte si alternativní verzi z www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Czech} "Tato verze MTA:SA byla vytvořena pro starší verze systému Windows. Prosím, stáhněte si nejnovější verzi z www.mtasa.com."
LangString WELCOME_TEXT ${LANG_Czech} "Tento průvodce tě provede instalací nebo aktualizací $(^Name) ${REVISION_TAG}\n\nDoporučujeme vypnout všechny ostatní aplikace před spouštěním instalace.\n\n[Administrátorská oprávnění mohou být vyžadována u systémů Vista a novější]\n\nKlikni na Další pro pokračování."
LangString HEADER_Text ${LANG_Czech} "Umístění Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_Czech} "Grand Theft Auto: San Andreas složka"
LangString DIRECTORY_Text_Top ${LANG_Czech} "Prosím zvol tvou Grand Theft Auto: San Andreas složku.$\n$\nMusíš mít verzi Grand Theft Auto: San Andreas 1.0 pro použití MTA:SA, jiné verze nejsou podporovány.$\n$\nKlikni na Instalovat pro zahájení instalace."
LangString DESC_Section10 ${LANG_Czech} "Vytvořit skupinu v Nabídce Start pro nainstalované aplikace"
LangString DESC_Section11 ${LANG_Czech} "Vytvořit zástupce na ploše pro MTA:SA klient."
LangString DESC_Section12 ${LANG_Czech} "Registrovat protokol mtasa:// pro prohlížeče."
LangString DESC_Section13 ${LANG_Czech} "Přidat do Prohlížeče her Windows (je-li k dispozici)."
LangString DESC_DirectX ${LANG_Czech} "Nainstalovat nebo aktualizovat DirectX (pokud je potřeba)."
LangString DESC_Section1 ${LANG_Czech} "Jádrové komponenty potřebné pro chod Multi Theft Auto."
LangString DESC_Section2 ${LANG_Czech} "MTA:SA modifikace, umožňující ti hrát online."
LangString DESC_SectionGroupServer ${LANG_Czech} "Multi Theft Auto Server. Toto ti umožňuje hostovat hry z tvého počítače. Je zapotřebí rychlé internetové připojení."
LangString DESC_Section4 ${LANG_Czech} "Multi Theft Auto server. Toto je potřebná součást."
LangString DESC_Section5 ${LANG_Czech} "MTA:SA modifikace pro server."
LangString DESC_Section6 ${LANG_Czech} "Skupina potřebných resources pro tvůj server."
LangString DESC_Section7 ${LANG_Czech} "Toto je sada volitelných herních módů a map pro tvůj server."
LangString DESC_Section8 ${LANG_Czech} "MTA:SA 1.0 Map Editor.   Může být použit pro vytvoření tvých vlastních map pro herní módy v MTA."
LangString DESC_Section9 ${LANG_Czech} "Toto je SDK pro vytváření binárních modulů pro MTA server. Instaluj pouze pokud máš dobrou znalost C++!"
LangString DESC_SectionGroupDev ${LANG_Czech} "Vývojářský kód a nástroje které můžou pomoci při vývoji módu pro Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_Czech} "Klient je program který spustíš pro hraní na Multi Theft Auto serveru"
LangString INST_CLIENTSERVER ${LANG_Czech} "Client a Server"
LangString INST_SERVER ${LANG_Czech} "Pouze server"
LangString INST_STARTMENU_GROUP ${LANG_Czech} "Start menu skupina"
LangString INST_DESKTOP_ICON ${LANG_Czech} "Ikona na ploše"
LangString INST_PROTOCOL ${LANG_Czech} "Zaregistrovat mtasa:// protokol"
LangString INST_GAMES_EXPLORER ${LANG_Czech} "Přidat do Prohlížeče her"
LangString INST_DIRECTX ${LANG_Czech} "Nainstalovat DirectX"
LangString INST_SEC_CLIENT ${LANG_Czech} "Herní klient"
LangString INST_SEC_SERVER ${LANG_Czech} "Dedikovaný server"
LangString INST_SEC_CORE ${LANG_Czech} "Jádrové komponenty"
LangString INST_SEC_GAME ${LANG_Czech} "Herní modul"
LangString INFO_INPLACE_UPGRADE ${LANG_Czech} "Provádím místní aktualizaci..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Czech} "Aktualizuji oprávnění. To může trvát pár minut..."
LangString MSGBOX_INVALID_GTASA ${LANG_Czech} "Platná verze hry Grand Theft Auto: San Andreas nebyla nalezena.$\r$\nInstalace bude i přesto pokračovat.$\r$\nPřeinstalujte MTA v případě pozdějších problémů."
LangString INST_SEC_CORE_RESOURCES ${LANG_Czech} "Hlavní Resources"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Czech} "Volitelné Resources"
LangString INST_SEC_EDITOR ${LANG_Czech} "Editor"
LangString INST_SEC_DEVELOPER ${LANG_Czech} "Vývoj"
LangString UNINST_SUCCESS ${LANG_Czech} "$(^Name) byl úspěšně smazán z tvého počítače."
LangString UNINST_FAIL ${LANG_Czech} "Odinstalace selhala!"
LangString UNINST_REQUEST ${LANG_Czech} "Jsi si jist že chceš kompletně smazat $(^Name) a všechny jeho součásti?"
LangString UNINST_REQUEST_NOTE ${LANG_Czech} "Odinstalovat před aktualizací?$\r$\nOdstranění předchozí instalace není nutné při instalace nové verze MTA:SA$\r$\nSpusť nový instalátor pro aktualizaci a zachování nastavení."
LangString UNINST_DATA_REQUEST ${LANG_Czech} "Chceš ponechat tvoje osobní soubory (jako skripty, screenshoty a nastavení serveru)? Pokud klikneš na ne, všechny skripty, nastavení a screenshoty, které jsi vytvořil budou ztraceny."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Czech} "Chyba při stahování patche pro tvoji verzi Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Czech} "Chyba při instalaci aktualizace pro tvoji verzi Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_Czech} "Tento instalátor vyžaduje admin. oprávnění, zkus to znovu"
LangString UAC_RIGHTS_UN ${LANG_Czech} "Tento odinstalátor vyžaduje admin. oprávnění, zkus to znovu"
LangString UAC_RIGHTS3 ${LANG_Czech} "Přihlašovací služba neběží, ukončuji!"
LangString UAC_RIGHTS4 ${LANG_Czech} "Nelze povýšit"
LangString INST_MTA_CONFLICT ${LANG_Czech} "Jiná hlavní verze MTA ($1) již existuje v daném umístění.$\n$\nMTA je navrhnuto tak aby byli hlavní verze instalovány do jiných umístění.$\nJsi si jist že chceš přepsat MTA $1 v $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_Czech} "MTA nemůže být nainstalováno do stejného adresáře, jako je GTA:SA.$\n$\nChceš místo toho použít výchozí adresář pro instalaci$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Czech} "Vybraný adresář neexistuje.$\n$\nProsím zvol adresář s hrou GTA:SA"
LangString INST_GTA_ERROR2 ${LANG_Czech} "Nemožné najít GTA:SA v $GTA_DIR $\n$\nJsi si jist že chceš pokračovat ?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Czech} "Vyber umístění instalace"
LangString INST_CHOOSE_LOC ${LANG_Czech} "Vyber složku do které chceš nainstalovat ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Czech} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} bude nainstalován v následujícím adresáři.$\nPro instalaci do jiného adresáře klikni na Procházet a zvol jiný adresář.$\n$\nKlikni na Další pro pokračování."
LangString INST_CHOOSE_LOC3 ${LANG_Czech} "Cílový adresář"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Czech} "Procházet..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Czech} "Výchozí"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Czech} "Naposledy použité"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Czech} "Vlastní"
LangString INST_CHOOSE_LOC4 ${LANG_Czech} "Vyber složku pro instalaci ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}:"
LangString INST_LOC_OW ${LANG_Czech} "Varování: Jiná hlavní verze MTA ($1) již existuje v daném adresáři."
LangString INST_LOC_UPGRADE ${LANG_Czech} "Typ instalace:   Upgrade"
LangString NETTEST_TITLE1 ${LANG_Czech} "Online aktualizace"
LangString NETTEST_TITLE2 ${LANG_Czech} "Zjišťuji informace o aktualizaci"
LangString NETTEST_STATUS1 ${LANG_Czech} "Kontroluji informace o aktualizacích instalátoru..."
LangString NETTEST_STATUS2 ${LANG_Czech} "Prosím, ujisti se, že firewall něco neblokuje"
!insertmacro MUI_LANGUAGE "Ukrainian"
LangString LANGUAGE_CODE ${LANG_Ukrainian} "uk"
LangString GET_XPVISTA_PLEASE ${LANG_Ukrainian} "Версія МТА:SA, які ви завантажили, не підтримує Windows XP або Vista. Будь ласка, завантажте альтернативну версію www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Ukrainian} "Версія МТА:SA призначена для старих версій Windows. Будь ласка, завантажте нову версію з www.mtasa.com."
LangString WELCOME_TEXT ${LANG_Ukrainian} "Цей інсталятор буде супроводжувати вас під час інсталяції або оновлення $(^Name) ${REVISION_TAG}\n\nРекомендуємо закрити всі інші додатки перед початком інсталяції.\n\n[Права адміністратора можуть бути запитані для системи Vista і вище]\n\nНатисніть кнопку Далі, щоб продовжити."
LangString HEADER_Text ${LANG_Ukrainian} "Розташування Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_Ukrainian} "Шлях до теки Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Top ${LANG_Ukrainian} "Будь ласка, виберіть теку Grand Theft Auto: San Andreas.$\n$\nДля використання MTA:SA необхідна Grand Theft Auto: San Andreas версії 1.0, інші версії не підтримуються.$\n$\nНатисніть Інсталювати для начала встановлення."
LangString DESC_Section10 ${LANG_Ukrainian} "Додати пункт в меню $\"Пуск$\""
LangString DESC_Section11 ${LANG_Ukrainian} "Створити ярлик на робочому столі."
LangString DESC_Section12 ${LANG_Ukrainian} "Зареєструвати протокол mtasa:// для підключення за допомогою веб-браузера."
LangString DESC_Section13 ${LANG_Ukrainian} "Додати в теку $\"Ігри$\" (Якщо у вас є)."
LangString DESC_DirectX ${LANG_Ukrainian} "Інсталювати або оновити DirectX (якщо потрібно)"
LangString DESC_Section1 ${LANG_Ukrainian} "Основні компоненти, необхідні для запуску Multi Theft Auto."
LangString DESC_Section2 ${LANG_Ukrainian} "Модифікація MTA:SA, що дозволяє грати по мережі."
LangString DESC_SectionGroupServer ${LANG_Ukrainian} "Сервер Multi Theft Auto. Дозволяє запустити свій сервер для під'єднання до нього інших гравців. Потрібне швидке інтернет-з'єднання."
LangString DESC_Section4 ${LANG_Ukrainian} "Сервер Multi Theft Auto. Це необхідний компонент."
LangString DESC_Section5 ${LANG_Ukrainian} "Модифікація MTA:SA для сервера."
LangString DESC_Section6 ${LANG_Ukrainian} "Це список рекомендованих ресурсів для вашого сервера."
LangString DESC_Section7 ${LANG_Ukrainian} "Це перелік необов'язкових ігрових режимів і карт для вашого сервера."
LangString DESC_Section8 ${LANG_Ukrainian} "Редактор карт MTA:SA 1.0. Використовується для створення своїх власних карт, використовуваних в ігрових режимах для MTA."
LangString DESC_Section9 ${LANG_Ukrainian} "SDK для створення модулів для MTA сервера. Інсталюйте, якщо маєте досвід роботи з C++!"
LangString DESC_SectionGroupDev ${LANG_Ukrainian} "Програмний код і засоби, які допоможуть у створенні модифікацій для Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_Ukrainian} "Клієнт - це програма, яку ви запускаєте для гри на Multi Theft Auto серверах"
LangString INST_CLIENTSERVER ${LANG_Ukrainian} "Клієнт і Сервер"
LangString INST_SERVER ${LANG_Ukrainian} "Тільки сервер"
LangString INST_STARTMENU_GROUP ${LANG_Ukrainian} "Меню $\"Пуск$\""
LangString INST_DESKTOP_ICON ${LANG_Ukrainian} "Ярлик на робочому столі"
LangString INST_PROTOCOL ${LANG_Ukrainian} "Зареєструвати протокол mtasa://"
LangString INST_GAMES_EXPLORER ${LANG_Ukrainian} "Додати в теку $\"Ігри$\""
LangString INST_DIRECTX ${LANG_Ukrainian} "Інсталяція DirectX"
LangString INST_SEC_CLIENT ${LANG_Ukrainian} "Ігровий клієнт"
LangString INST_SEC_SERVER ${LANG_Ukrainian} "Виділений сервер"
LangString INST_SEC_CORE ${LANG_Ukrainian} "Основні компоненти"
LangString INST_SEC_GAME ${LANG_Ukrainian} "Ігровий модуль"
LangString INFO_INPLACE_UPGRADE ${LANG_Ukrainian} "Оновлення поточної інсталяції..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Ukrainian} "Оновлення прав. Це може зайняти кілька хвилин..."
LangString MSGBOX_INVALID_GTASA ${LANG_Ukrainian} "Допустима Windows-версія Grand Theft Auto: San Andreas не знайдена.$\r$\nОднак, інсталяція буде як і раніше.$\r$\nБудь ласка, виконайте переінсталювання, якщо з'являться проблеми."
LangString INST_SEC_CORE_RESOURCES ${LANG_Ukrainian} "Основні ресурси"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Ukrainian} "Необов'язкові Ресурси"
LangString INST_SEC_EDITOR ${LANG_Ukrainian} "Редактор"
LangString INST_SEC_DEVELOPER ${LANG_Ukrainian} "Розробка"
LangString UNINST_SUCCESS ${LANG_Ukrainian} "$(^Name) успішно видалено з вашого комп'ютера."
LangString UNINST_FAIL ${LANG_Ukrainian} "Помилка видалення!"
LangString UNINST_REQUEST ${LANG_Ukrainian} "Ви впевнені, що хочете повністю видалити $(^Name) і всі її компоненти?"
LangString UNINST_REQUEST_NOTE ${LANG_Ukrainian} "Видалити перед оновленням?$\r$\nВидалення старої версії необов'язково перед інсталяцією нової версії MTA:SA$\r$\nЗапустіть новий файл інсталяції для оновлення та збереження ваших даних."
LangString UNINST_DATA_REQUEST ${LANG_Ukrainian} "Бажаєте зберегти ваші дані (ресурси, знімки та налаштування сервера)? Якщо ні, то всі ваші ресурси, налаштування і знімки буде втрачено."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Ukrainian} "Не вдалося завантажити патч для вашої версії Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Ukrainian} "Неможливо інсталювати патч на вашу версію Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_Ukrainian} "Для інсталяції необхідно мати права адміністратора, повторіть ще раз"
LangString UAC_RIGHTS_UN ${LANG_Ukrainian} "Цей уністалер вимагає права адміністратора, повторіть ще раз"
LangString UAC_RIGHTS3 ${LANG_Ukrainian} "Сервіс авторизації не запущено, завершення!"
LangString UAC_RIGHTS4 ${LANG_Ukrainian} "Запуск неможливий"
LangString INST_MTA_CONFLICT ${LANG_Ukrainian} "Версія новіше MTA ($1) вже інстальовано ​​за цією адресою.$\n$\nMTA передбачає можливість інсталяції декількох копій в різні директорії.$\nВи впевнені, що хочете перезаписати MTA $1 в $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_Ukrainian} "MTA не може бути встановлено в тій же директорії що і GTA:SA.$\n$\nВи хочете використовувати директорію за промовчанням$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Ukrainian} "Вибраної директорії не існує.$\n$\nБудь ласка, виберіть директорію з GTA:SA"
LangString INST_GTA_ERROR2 ${LANG_Ukrainian} "GTA:SA не знайдено за адресою $GTA_DIR $\n$\nВи впевнені, що хочете продовжити?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Ukrainian} "Виберіть директорію інсталяції"
LangString INST_CHOOSE_LOC ${LANG_Ukrainian} "Виберіть теку для інсталяції ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Ukrainian} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} буде встановлена ​​в обрану теку.$\nДля інсталяції в іншу теку натисніть Вибрати і виберіть потрібну теку.$\n$\nНатисніть Далі для продовження."
LangString INST_CHOOSE_LOC3 ${LANG_Ukrainian} "Директорія Інсталяції"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Ukrainian} "Огляд..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Ukrainian} "За промовчанням"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Ukrainian} "Останнє використання"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Ukrainian} "Інший"
LangString INST_CHOOSE_LOC4 ${LANG_Ukrainian} "Виберіть теку, щоб інсталювати ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}:"
LangString INST_LOC_OW ${LANG_Ukrainian} "Попередження: Більш свіжа версія MTA ($1) вже встановлена ​​сюди ж."
LangString INST_LOC_UPGRADE ${LANG_Ukrainian} "Тип інсталяції: Оновлення"
LangString NETTEST_TITLE1 ${LANG_Ukrainian} "Онлайн оновлення"
LangString NETTEST_TITLE2 ${LANG_Ukrainian} "Перевірити оновлення"
LangString NETTEST_STATUS1 ${LANG_Ukrainian} "Перевірка оновлень інсталятора..."
LangString NETTEST_STATUS2 ${LANG_Ukrainian} "Будь ласка, переконайтеся, що ваш брандмауер не блокує"
!insertmacro MUI_LANGUAGE "Japanese"
LangString LANGUAGE_CODE ${LANG_Japanese} "ja"
LangString GET_XPVISTA_PLEASE ${LANG_Japanese} "ダウンロードしたMTA：SA版はWindows XP、またVistaをサポートしません。別のバーションをwww.mtasa.comでダウンロードしてくさい。"
LangString GET_MASTER_PLEASE ${LANG_Japanese} "このMTA:SAバーションは古いWindows OS向きです。新しいバーションをwww.mtasa.comでダウンロードしてください。"
LangString WELCOME_TEXT ${LANG_Japanese} "このウィザードは、ご使用のコンピュータへ$(^Name) ${REVISION_TAG}をインストールやアップデートします。\n\nインストールの前にすべてのアプリケションを閉めるのは推奨されています。\n\n[ヴィスタからの場合はアドミンアクセスは必要かもしれません] \n\n「次へ」にクリックして、続行してください。"
LangString HEADER_Text ${LANG_Japanese} "Grand Theft Auto: San Andreas のインストールフォルダー"
LangString DIRECTORY_Text_Dest ${LANG_Japanese} "Grand Theft Auto: San Andreas のフォルダー"
LangString DIRECTORY_Text_Top ${LANG_Japanese} "Grand Theft Auto: San Andreasを選んでください。$\n$\nMTA:SAはGTA: San Andreas 1.0のインストールだけにサポートしています。それ以外サポートしていませ。$\n$\n「インストール」にクリックして、始めてください。"
LangString DESC_Section10 ${LANG_Japanese} "インストールしたアプリケーションにスタートメニューグループを作る"
LangString DESC_Section11 ${LANG_Japanese} "MTA:SAクライエントのデスクトップショートカットを作る"
LangString DESC_Section12 ${LANG_Japanese} "「mtasa://」プロトコールをブラウザに登録してください。 これはブラウザでサーバに参加するためです。"
LangString DESC_Section13 ${LANG_Japanese} "Windows Games Explorerに追加 （存在している場合）"
LangString DESC_DirectX ${LANG_Japanese} "DirectXをインストール/アップデートする（必要なら）。"
LangString DESC_Section1 ${LANG_Japanese} "MTA:San Andreasを実行するため、コアのコンポネントが必要です。"
LangString DESC_Section2 ${LANG_Japanese} "MTA:SA 、オンラインで遊べるMOD。"
LangString DESC_SectionGroupServer ${LANG_Japanese} "MTA Server。これで自分のゲームをホストするのはできます。快速インターネットが必要です。"
LangString DESC_Section4 ${LANG_Japanese} "MTA Server。 必要コンポーネント。"
LangString DESC_Section5 ${LANG_Japanese} "サーバーのためのMTA:SA MOD。 必要コンポーネント。"
LangString DESC_Section6 ${LANG_Japanese} "これはサーバのデフォルト資源です。"
LangString DESC_Section7 ${LANG_Japanese} "これはサーバのデフォルトマップとゲームモッドです。"
LangString DESC_Section8 ${LANG_Japanese} "MTA:SA 1.0 マップエディター。この道具で自分のマップが作れます。"
LangString DESC_Section9 ${LANG_Japanese} "これはSDKモジュール、これでバイナリモジュールがMTA Serverのために作られます。C++の知識がある者以外はインストールしなくても大丈夫です。"
LangString DESC_SectionGroupDev ${LANG_Japanese} "MTA:SAのMODを作るためにの発展コードや道具です。"
LangString DESC_SectionGroupClient ${LANG_Japanese} "これはMTA:SAのクライエント。サーバにプレイするのに使います。"
LangString INST_CLIENTSERVER ${LANG_Japanese} "クライアントとサーバー"
LangString INST_SERVER ${LANG_Japanese} "サーバのみ"
LangString INST_STARTMENU_GROUP ${LANG_Japanese} "スタートメニューグループ"
LangString INST_DESKTOP_ICON ${LANG_Japanese} "デスクトップアイコン"
LangString INST_PROTOCOL ${LANG_Japanese} "「mtasa://」プロトコルを登録する"
LangString INST_GAMES_EXPLORER ${LANG_Japanese} "ゲームエクスプローラーに追加"
LangString INST_DIRECTX ${LANG_Japanese} "DirectXをインストールする"
LangString INST_SEC_CLIENT ${LANG_Japanese} "ゲームクライアント"
LangString INST_SEC_SERVER ${LANG_Japanese} "専用サーバー"
LangString INST_SEC_CORE ${LANG_Japanese} "コアコンポーネント"
LangString INST_SEC_GAME ${LANG_Japanese} "ゲームモジュール"
LangString INFO_INPLACE_UPGRADE ${LANG_Japanese} "アップデート中。。。"
LangString INFO_UPDATE_PERMISSIONS ${LANG_Japanese} "許可アップデート中。 しばらくお待ちください。。。"
LangString MSGBOX_INVALID_GTASA ${LANG_Japanese} "Grand Theft Auto: San Andreasは発見されませんでした。$\r$\nところが、インストールは続きますが、$\r$\n問題が発生したら、再インストールしてください。"
LangString INST_SEC_CORE_RESOURCES ${LANG_Japanese} "コアリソース"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Japanese} "オプションりソース"
LangString INST_SEC_EDITOR ${LANG_Japanese} "エディター"
LangString INST_SEC_DEVELOPER ${LANG_Japanese} "開発"
LangString UNINST_SUCCESS ${LANG_Japanese} "$(^Name) は成功に削除されました。"
LangString UNINST_FAIL ${LANG_Japanese} "アンインストールが失敗しました！"
LangString UNINST_REQUEST ${LANG_Japanese} "$(^Name)とともにコンポーネントを削除したいですか。"
LangString UNINST_REQUEST_NOTE ${LANG_Japanese} "アップデートする前にアンインストールしますか?$\r$\n新しいMTA:SAバージョンをインストールする時はアンインストールする必要がありません$\r$\nインストーラを実行すると自動的にアップデートできます。"
LangString UNINST_DATA_REQUEST ${LANG_Japanese} "個人的なものを保ったいですか。（資源、スクリーンショットとサーバーコンフィグレーション）？「いいえ」にクリックしたら、個人的なものを失います。"
LangString MSGBOX_PATCH_FAIL1 ${LANG_Japanese} "あなたのGTA：San Andreasのバーションのパｯチファイルはダウンロードできませんでした。"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Japanese} "あなたのGTA：San Andreasのバーションのパｯチファイルはインストールできませんでした。"
LangString UAC_RIGHTS1 ${LANG_Japanese} "このインストーラはアドミンアクセスが必要です、もう一度始めてください"
LangString UAC_RIGHTS_UN ${LANG_Japanese} "このアンインストーラはアドミンアクセスが必要です、もう一度試してください。"
LangString UAC_RIGHTS3 ${LANG_Japanese} "Logonサービスは実行していません、中止します！"
LangString UAC_RIGHTS4 ${LANG_Japanese} "上げることができません"
LangString INST_MTA_CONFLICT ${LANG_Japanese} "そのパスに最新MTAバーションがあります。$\n$\nMTAは最新バーションを違うところにインストールするとしてデザインされました。$\n$\n$INSTDIRのMTA $1に上書きしますか？"
LangString INST_GTA_CONFLICT ${LANG_Japanese} "MTAはGTA:SAと同じインストールフォルダーでインストールすることはできません$\n$\nデフォルトのインストールフォルダーにしますか？$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Japanese} "そのパスは存在していません。$\n$\nGTA：SAのインストールフォルダーを選んでください"
LangString INST_GTA_ERROR2 ${LANG_Japanese} "$GTA_DIRにGTA:SAが見つかりませんでした。$\n$\nとりあえず、続けますか。"
LangString INST_CHOOSE_LOC_TOP ${LANG_Japanese} "インストールフォルダーを選んでください"
LangString INST_CHOOSE_LOC ${LANG_Japanese} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}のインストールしたいフォルダーを選んでください"
LangString INST_CHOOSE_LOC2 ${LANG_Japanese} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}は次のフォルダにインストールします。$\n他のフォルダーでインストールする場合は、「ブラウズ」にクリックして、他のフォルダを選んでください。$\n$\n　「次へ」にクリックして、続行してください。"
LangString INST_CHOOSE_LOC3 ${LANG_Japanese} "宛先フォルダー"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Japanese} "ブラウズ..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Japanese} "デフォルト"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Japanese} "前回利用"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Japanese} "カスタム"
LangString INST_CHOOSE_LOC4 ${LANG_Japanese} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}のインストールフォルダを選んでください："
LangString INST_LOC_OW ${LANG_Japanese} "警告：このパスにMTA ($1) 最新バーションが存在しています。"
LangString INST_LOC_UPGRADE ${LANG_Japanese} "インストールタイプ： アップデート"
LangString NETTEST_TITLE1 ${LANG_Japanese} "オンライン更新"
LangString NETTEST_TITLE2 ${LANG_Japanese} "更新情報を確認しています"
LangString NETTEST_STATUS1 ${LANG_Japanese} "インストーラの更新情報を確認しています…"
LangString NETTEST_STATUS2 ${LANG_Japanese} "ファイアウォールにブロックされていないのを確認してください"
!insertmacro MUI_LANGUAGE "German"
LangString LANGUAGE_CODE ${LANG_German} "de"
LangString WELCOME_TEXT ${LANG_German} "Dieses Installationsprogramm wird dich durch die Installation oder das Update von $(^Name) ${REVISION_TAG} führen\n\nEs wird empfohlen, dass du alle anderen Anwendungen schließt, bevor du fortfährst.\n\n[Administratorberechtigungen könnten benötigt sein]\n\nKlicke auf Weiter um fortzufahren."
LangString HEADER_Text ${LANG_German} "Installationsort von Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_German} "Installationsort von Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Top ${LANG_German} "Bitte wähle deinen Installationspfad von Grand Theft Auto: San Andreas aus.$\n$\nUm MTA:SA zu verwenden, MUSST du Grand Theft Auto: San Andreas 1.0 installiert haben, andere Versionen werden nicht unterstützt.$\n$\nKlicke auf Installieren um die Installation zu beginnen."
LangString DESC_Section10 ${LANG_German} "Einen Startmenüeintrag für die installierte Anwendung erstellen"
LangString DESC_Section11 ${LANG_German} "Eine Desktopverknüpfung für den MTA:SA Client erstellen."
LangString DESC_Section12 ${LANG_German} "Das mtasa:// Protokoll für Weblinks hinzufügen."
LangString DESC_Section13 ${LANG_German} "Dem Windows Spieleexplorer hinzufügen (sofern vorhanden)."
LangString DESC_Section1 ${LANG_German} "Die Grundkomponenten, die zur Ausführung von Multi Theft Auto benötigt werden."
LangString DESC_Section2 ${LANG_German} "Die MTA:SA Modifikation, die es dir ermöglicht online zu spielen."
LangString DESC_SectionGroupServer ${LANG_German} "Der Multi Theft Auto Server. Dieser ermöglicht dir ein Spiel von deinem Computer aus zu hosten. Dies erfordert eine schnelle Internetverbindung."
LangString DESC_Section4 ${LANG_German} "Der Mutli Theft Auto Server ist eine benötigte Komponente."
LangString DESC_Section5 ${LANG_German} "Die MTA:SA Modifikation für den Server."
LangString DESC_Section6 ${LANG_German} "Dies ist ein Paket der benötigten Resourcen für deinen Server."
LangString DESC_Section7 ${LANG_German} "Dies ist ein optionales Paket an Spielmodi und Karten für deinen Server."
LangString DESC_Section8 ${LANG_German} "Der MTA:SA 1.0 Map Editor.  Dieser kann dazu verwendet werden, deine eigenen Karten für MTA Gamemodes zu erstellen."
LangString DESC_Section9 ${LANG_German} "Dies ist das SDK um Module für den MTA-Server zu erstellen. Dies erfordert erweiterte C++ Kenntnisse!"
LangString DESC_SectionGroupDev ${LANG_German} "Entwicklungscode und Hilfsprogramme, die bei der Erstellung von Mods für Multi Theft Auto helfen"
LangString DESC_SectionGroupClient ${LANG_German} "Der Client ist das Programm, welches du verwendest um auf einem Multi Theft Auto server zu spielen"
LangString INST_CLIENTSERVER ${LANG_German} "Client und Server"
LangString INST_SERVER ${LANG_German} "Nur Server"
LangString INST_STARTMENU_GROUP ${LANG_German} "Startmenügruppe"
LangString INST_DESKTOP_ICON ${LANG_German} "Desktop-Symbol"
LangString INST_PROTOCOL ${LANG_German} "mtasa:// Protokoll registrieren"
LangString INST_GAMES_EXPLORER ${LANG_German} "Dem Spiele-Explorer hinzufügen"
LangString INST_SEC_CLIENT ${LANG_German} "Spielclient"
LangString INST_SEC_SERVER ${LANG_German} "Dedizierter Server"
LangString INST_SEC_CORE ${LANG_German} "Grundkomponenten"
LangString INST_SEC_GAME ${LANG_German} "Spielmodul"
LangString INFO_INPLACE_UPGRADE ${LANG_German} "Update wird ausgeführt..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_German} "Berechtigungen werden aktualisiert. Dies kann mehrere Minuten dauern..."
LangString MSGBOX_INVALID_GTASA ${LANG_German} "Es konnte keine Grand Theft Auto: San Andreas Installation gefunden werden.$\r$\nDennoch wird die Installation fortgesetzt.$\r$\nFühre bitte eine Neuinstallation durch, falls später Probleme auftreten."
LangString INST_SEC_CORE_RESOURCES ${LANG_German} "Basisressourcen"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_German} "Optionale Resourcen"
LangString INST_SEC_EDITOR ${LANG_German} "Editor"
LangString INST_SEC_DEVELOPER ${LANG_German} "Entwicklung"
LangString UNINST_SUCCESS ${LANG_German} "$(^Name) wurde erfolgreich von deinem Computer entfernt."
LangString UNINST_FAIL ${LANG_German} "Die Deinstallation ist fehlgeschlagen!"
LangString UNINST_REQUEST ${LANG_German} "Bist du sicher, dass du $(^Name) und alle Komponenten entfernen möchtest?"
LangString UNINST_REQUEST_NOTE ${LANG_German} "Vor dem Update deinstallieren?$\r$\nDie Deinstallation ist nicht nötig vor dem Installieren einer neuen Version von MTA:SA$\r$\nFühre den neuen Installer zum Upgraden aus und behalte deine Einstellungen."
LangString UNINST_DATA_REQUEST ${LANG_German} "Möchtest du deine Spieldaten (beispielsweise Resourcen, Screenshots und Serverkonfigurationen) behalten? Wenn du Nein auswählst, gehen alle Resourcen, Konfigurationen und Screenshots verloren."
LangString MSGBOX_PATCH_FAIL1 ${LANG_German} "Konnte das Spielupdate für deine Version von Grand Theft Auto: San Andreas nicht herunterladen"
LangString MSGBOX_PATCH_FAIL2 ${LANG_German} "Konnte das Spielupdate für deine Version von Grand Theft Auto: San Andreas nicht installieren"
LangString UAC_RIGHTS1 ${LANG_German} "Das Installationsprogramm erfordert Administratorberechtigungen, bitte versuche es erneut"
LangString UAC_RIGHTS_UN ${LANG_German} "Das Deinstallationsprogramm erfordert Administratorberechtigungen, bitte versuche es erneut"
LangString UAC_RIGHTS3 ${LANG_German} "Logindienst läuft nicht, abbruch!"
LangString UAC_RIGHTS4 ${LANG_German} "Konnte das Zugriffslevel nicht erhöhen"
LangString INST_MTA_CONFLICT ${LANG_German} "Eine andere Hauptversion von MTA ($1) existiert bereits am ausgewählten Pfad.$\n$\nMTA ist dafür ausgelegt, dass verschiedene Hauptversionen in verschiedenen Pfaden installiert werden.$\nBist du sicher, dass du MTA $1 in $INSTDIR überschreiben möchtest?"
LangString INST_GTA_CONFLICT ${LANG_German} "MTA kann nicht in das GTA:SA Verzeichnis installiert werden. $\r$\nSoll MTA in den Standardinstallationspfad$\n$DEFAULT_INSTDIR installiert werden?"
LangString INST_GTA_ERROR1 ${LANG_German} "Der ausgewählte Pfad existiert nicht.$\n$\nBitte wähle den GTA:SA Installationsort"
LangString INST_GTA_ERROR2 ${LANG_German} "Konnte GTA:SA nicht in $GTA_DIR finden $\n$\nDennoch fortfahren?"
LangString INST_CHOOSE_LOC_TOP ${LANG_German} "Wähle den Installationspfad"
LangString INST_CHOOSE_LOC ${LANG_German} "Wähle den Pfad, in welchen ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} installiert werden soll"
LangString INST_CHOOSE_LOC2 ${LANG_German} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} wird im folgenden Pfad installiert.$\nUm an einem anderen Ort zu installieren, klicke auf Durchsuchen.$\n$\n Klicke auf Weiter um fortzufahren."
LangString INST_CHOOSE_LOC3 ${LANG_German} "Zielordner"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_German} "Durchsuchen..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_German} "Standard"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_German} "Zuletzt genutzt"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_German} "Benutzerdefiniert"
LangString INST_CHOOSE_LOC4 ${LANG_German} "Wähle den Ordner, in welchen ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} installiert werden soll:"
LangString INST_LOC_OW ${LANG_German} "Warnung: Eine andere Hauptversion von MTA ($1) existiert bereits am ausgewählten Pfad."
LangString INST_LOC_UPGRADE ${LANG_German} "Installationstyp: Upgrade"
LangString NETTEST_TITLE1 ${LANG_German} "Online Update"
LangString NETTEST_TITLE2 ${LANG_German} "Suche nach Updateinformationen"
LangString NETTEST_STATUS1 ${LANG_German} "Suche nach Installer Updateinformationen"
LangString NETTEST_STATUS2 ${LANG_German} "Bitte stelle sicher, dass deine Firewall nicht blockiert"
LangString GET_XPVISTA_PLEASE ${LANG_German} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_German} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString DESC_DirectX ${LANG_German} "Install or update DirectX (if required)."
LangString INST_DIRECTX ${LANG_German} "Install DirectX"
!insertmacro MUI_LANGUAGE "Slovak"
LangString LANGUAGE_CODE ${LANG_Slovak} "sk"
LangString WELCOME_TEXT ${LANG_Slovak} "Tento sprievodca Vás povedie počas inštalácie alebo aktualizácie $(^Name) ${REVISION_TAG}\n\nOdporúča sa zavrieť všetky ostatné aplikácie pred začatím Inštalácie.\n\n[Administrátorský prístup je požadovaný pre Windows Vista a vyššie systémy]\n\nKliknite na Ďalej pre pokračovanie."
LangString HEADER_Text ${LANG_Slovak} "Umiestnenie Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_Slovak} "Priečinok s Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Top ${LANG_Slovak} "Prosím vyberte priečinok s Grand Theft Auto: San Andreas.$\n$\nPre inštaláciu MTA:SA MUSÍTE mať Grand Theft Auto: San Andreas vo verzií 1.0, iné verzie nie sú podporované.$\n$\nPre začatie inštalácie kliknite na Inštalovať."
LangString DESC_Section10 ${LANG_Slovak} "Pridať zástupcu do menu Štart"
LangString DESC_Section11 ${LANG_Slovak} "Pridať odkaz na plochu."
LangString DESC_Section12 ${LANG_Slovak} "Zaregistrovať protokol mtasa:// v prehliadačoch."
LangString DESC_Section13 ${LANG_Slovak} "Pridať do Hier Windows (ak sú k dispozícií)."
LangString DESC_Section1 ${LANG_Slovak} "Hlavné súčasti potrebné k fungovaniu Multi Theft Auto."
LangString DESC_Section2 ${LANG_Slovak} "Súčasť MTA:SA pre server"
LangString DESC_SectionGroupServer ${LANG_Slovak} "Multi Theft Auto Server. Umožňuje vytvoriť server spustený z Vášho počítača. Vyžaduje sa rýchle internetové pripojenie."
LangString DESC_Section4 ${LANG_Slovak} "Multi Theft Auto server. Toto je potrebná súčasť."
LangString DESC_Section5 ${LANG_Slovak} "Súčasť MTA:SA pre server."
LangString DESC_Section6 ${LANG_Slovak} "Toto je zoznam vyžadovaných doplnkov pre Váš server."
LangString DESC_Section7 ${LANG_Slovak} "Toto je voliteľný zoznam herných módov a máp pre Váš server."
LangString DESC_Section8 ${LANG_Slovak} "MTA:SA 1.0 mapový editor. Môžete ho použiť na vytvorenie vlastnej mapy ktorú použijete v niektorom hernom móde MTA."
LangString DESC_Section9 ${LANG_Slovak} "Toto je SDK - sada nástrojov pre vývojára. Inštalujte iba ak máte dobré znalosti C++!"
LangString DESC_SectionGroupDev ${LANG_Slovak} "Vývojový kód a nástroje ktoré pomáhajú pri vytváraní módov pre Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_Slovak} "Klient je program ktorý spustíte pre hranie na Multi Theft Auto serveri"
LangString INST_CLIENTSERVER ${LANG_Slovak} "Klient a Server"
LangString INST_SERVER ${LANG_Slovak} "Len Server"
LangString INST_STARTMENU_GROUP ${LANG_Slovak} "Zástupca v menu Štart"
LangString INST_DESKTOP_ICON ${LANG_Slovak} "Ikona na ploche"
LangString INST_PROTOCOL ${LANG_Slovak} "Zaregistrovať mtasa:// protokol"
LangString INST_GAMES_EXPLORER ${LANG_Slovak} "Pridať do Hier Windows"
LangString INST_SEC_CLIENT ${LANG_Slovak} "Herný klient"
LangString INST_SEC_SERVER ${LANG_Slovak} "Dedikovaný server"
LangString INST_SEC_CORE ${LANG_Slovak} "Hlavné súčasti"
LangString INST_SEC_GAME ${LANG_Slovak} "Herný modul"
LangString INFO_INPLACE_UPGRADE ${LANG_Slovak} "Prevedenie miestnej aktualizácie..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Slovak} "Aktualizácia oprávnení. Toto môže trvať niekoľko minút..."
LangString MSGBOX_INVALID_GTASA ${LANG_Slovak} "Platná Windows verzia hry Grand Theft Auto: San Andreas nebola nájdená.$\r$\nInštalácia bude napriek tomu pokračovať.$\r$\nPreinštalujte MTA v prípade neskorších problémov."
LangString INST_SEC_CORE_RESOURCES ${LANG_Slovak} "Hlavné Súčasti"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Slovak} "Voliteľné Súčasti"
LangString INST_SEC_EDITOR ${LANG_Slovak} "Mapový editor"
LangString INST_SEC_DEVELOPER ${LANG_Slovak} "Vývoj"
LangString UNINST_SUCCESS ${LANG_Slovak} "$(^Name) bol úspešne odstránený z Vášho počítača."
LangString UNINST_FAIL ${LANG_Slovak} "Odinštalácia neúspešná!"
LangString UNINST_REQUEST ${LANG_Slovak} "Ste si istý že chcete kompletne odstrániť $(^Name) a všetky jeho súčasti?"
LangString UNINST_DATA_REQUEST ${LANG_Slovak} "Chcete ponechať Vaše osobné súbory (ako doplnky, screenshoty a nastavenie servera)? Ak kliknete na nie, všetky doplnky, nastavenia a screenshoty ktoré ste vytvorili budú zmazané."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Slovak} "Nemožno stiahnuť korekčný súbor pre Vašu verziu hry Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Slovak} "Nemožno nainštalovať korekčný súbor pre Vašu verziu hry Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_Slovak} "Tento inštalátor vyžaduje administrátorský prístup, skúste to znovu"
LangString UAC_RIGHTS_UN ${LANG_Slovak} "Tento odinštalátor vyžaduje administrátorský prístup, skúste to znovu"
LangString UAC_RIGHTS3 ${LANG_Slovak} "Prihlasovacia služba nie je spustená, ukončenie!"
LangString UAC_RIGHTS4 ${LANG_Slovak} "Nemožno povýšiť"
LangString INST_MTA_CONFLICT ${LANG_Slovak} "Odlišná hlavná verzia MTA ($1) existuje v danom umiestnení.$\n$\nMTA je navrhnutý tak, aby boli hlavné verzie inštalované do rozličných umiestnení.$\nSte si istý, že chcete nahradiť MTA $1 v $INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Slovak} "Vybratý priečinok neexistuje.$\n$\nProsím zvoľte priečinok s hrou GTA:SA"
LangString INST_GTA_ERROR2 ${LANG_Slovak} "Nemožno nájsť hru GTA:SA nainštalovanú v $GTA_DIR $\n$\nSte si istý že chcete pokračovať?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Slovak} "Vyberte umiestnenie inštalácie"
LangString INST_CHOOSE_LOC ${LANG_Slovak} "Vyberte priečinok do ktorého chcete nainštalovať ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Slovak} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} bude nainštalovaný do nasledujúceho priečinka.$\nPre inštaláciu do iného priečinka kliknite na Prehľadávať a zvoľte iný priečinok.$\n$\nKliknite na Ďalej pre pokračovanie."
LangString INST_CHOOSE_LOC3 ${LANG_Slovak} "Cieľový priečinok"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Slovak} "Prehľadávať..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Slovak} "Predvolené"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Slovak} "Naposledy použité"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Slovak} "Pokročilé"
LangString INST_CHOOSE_LOC4 ${LANG_Slovak} "Vyberte priečinok pre inštaláciu ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}:"
LangString INST_LOC_OW ${LANG_Slovak} "Varovanie: Odlišná hlavná verzia MTA ($1) existuje v danom umiestnení."
LangString INST_LOC_UPGRADE ${LANG_Slovak} "Typ inštalácie: Aktualizácia"
LangString GET_XPVISTA_PLEASE ${LANG_Slovak} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Slovak} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString DESC_DirectX ${LANG_Slovak} "Install or update DirectX (if required)."
LangString INST_DIRECTX ${LANG_Slovak} "Install DirectX"
LangString UNINST_REQUEST_NOTE ${LANG_Slovak} "Uninstalling before update?$\r$\nIt is not necessary to uninstall before installing a new version of MTA:SA$\r$\nRun the new installer to upgrade and preserve your settings."
LangString INST_GTA_CONFLICT ${LANG_Slovak} "MTA cannot be installed into the same directory as GTA:SA.$\n$\nDo you want to use the default install directory$\n$DEFAULT_INSTDIR ?"
LangString NETTEST_TITLE1 ${LANG_Slovak} "Online update"
LangString NETTEST_TITLE2 ${LANG_Slovak} "Checking for update information"
LangString NETTEST_STATUS1 ${LANG_Slovak} "Checking for installer update information..."
LangString NETTEST_STATUS2 ${LANG_Slovak} "Please ensure your firewall is not blocking"
!insertmacro MUI_LANGUAGE "Spanish"
LangString LANGUAGE_CODE ${LANG_Spanish} "es"
LangString GET_XPVISTA_PLEASE ${LANG_Spanish} "La versión de MTA:SA que has descargado que no soporta Windows XP o Vista. Por favor descarga una versión alternativa desde www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Spanish} "Esta versión de MTA:SA esta diseñada para versiones antiguas de Windows. Por favor descarga la nueva versión desde www.mtasa.com."
LangString WELCOME_TEXT ${LANG_Spanish} "Este asistente te guiará durante la instalación o actualización de $(^Name) ${REVISION_TAG}\n\nTe recomendamos que cierres todas las demás aplicaciones antes de iniciar la instalación.\n\n[En caso de tener Windows Vista o superior, podría ser necesaria una cuenta con privilegios de administrador]\n\nHaga clic en Siguiente para continuar."
LangString HEADER_Text ${LANG_Spanish} "Ubicación de Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_Spanish} "Carpeta de Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Top ${LANG_Spanish} "Por favor selecciona la carpeta donde está instalado Grand Theft Auto: San Andreas.$\n$\nDEBES tener Grand Theft Auto: San Andreas 1.0 instalado para utilizar MTA:SA, ya que no soporta otras versiones.$\n$\nHaga clic en Instalar para iniciar el proceso de instalación."
LangString DESC_Section10 ${LANG_Spanish} "Crear un grupo en el Menú Inicio para las aplicaciones instaladas"
LangString DESC_Section11 ${LANG_Spanish} "Crear un Acceso Directo en el escritorio para el cliente de MTA:SA."
LangString DESC_Section12 ${LANG_Spanish} "Registrar el protocolo mtasa:// para el acceso a servidores vía hipervínculos. "
LangString DESC_Section13 ${LANG_Spanish} "Agregar a Windows Games Explorer (si está presente)"
LangString DESC_DirectX ${LANG_Spanish} "Instalar o actualizar DirectX (si es requerido)."
LangString DESC_Section1 ${LANG_Spanish} "Los componentes principales necesarios para ejecutar Multi Theft Auto."
LangString DESC_Section2 ${LANG_Spanish} "La modificación MTA:SA, te permite jugar en-línea."
LangString DESC_SectionGroupServer ${LANG_Spanish} "El servidor de Multi Theft Auto. Te permite hospedar un servidor desde tu computadora. Requiere una buena conexión a internet."
LangString DESC_Section4 ${LANG_Spanish} "El servidor de Multi Theft Auto. Este es un componente requerido."
LangString DESC_Section5 ${LANG_Spanish} "La modificación de MTA:SA para el servidor."
LangString DESC_Section6 ${LANG_Spanish} "Este es un conjunto de recursos necesarios para tu servidor."
LangString DESC_Section7 ${LANG_Spanish} "Este es un conjunto opcional de modos de juego y mapas para tu servidor."
LangString DESC_Section8 ${LANG_Spanish} "El editor de mapas 1.0 de MTA:SA. Puede ser usado para crear tus propios mapas y posteriormente usarlos en modos de juego de MTA."
LangString DESC_Section9 ${LANG_Spanish} "Este es el SDK para la creación de módulos binarios para el servidor de MTA. ¡Instálalo sólo si tienes una buena comprensión de C++!"
LangString DESC_SectionGroupDev ${LANG_Spanish} "Código y herramientas de desarrollo que ayudan en la creación de modificaciones para Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_Spanish} "El cliente es el programa que ejecutas para jugar en un servidor de Multi Theft Auto"
LangString INST_CLIENTSERVER ${LANG_Spanish} "Cliente y Servidor"
LangString INST_SERVER ${LANG_Spanish} "Solo servidor"
LangString INST_STARTMENU_GROUP ${LANG_Spanish} "Grupo en el menú inicio"
LangString INST_DESKTOP_ICON ${LANG_Spanish} "Icono en el escritorio"
LangString INST_PROTOCOL ${LANG_Spanish} "Registrar el protocolo mtasa://"
LangString INST_GAMES_EXPLORER ${LANG_Spanish} "Agregar al Explorador de Juegos"
LangString INST_DIRECTX ${LANG_Spanish} "Instalar DirectX"
LangString INST_SEC_CLIENT ${LANG_Spanish} "Cliente del juego"
LangString INST_SEC_SERVER ${LANG_Spanish} "Servidor dedicado"
LangString INST_SEC_CORE ${LANG_Spanish} "Componentes principales"
LangString INST_SEC_GAME ${LANG_Spanish} "Modulo del Juego"
LangString INFO_INPLACE_UPGRADE ${LANG_Spanish} "Realizando actualización en la misma ubicación..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Spanish} "Actualizando permisos. Esto podría tardar un par de minutos..."
LangString MSGBOX_INVALID_GTASA ${LANG_Spanish} "No se ha detectado una versión válida de Grand Theft Auto: San Andrea para Windows.$\r$\nNo obstante, la instalación continuará.$\r$\nPor favor reinstale la aplicación en caso de problemas más adelante."
LangString INST_SEC_CORE_RESOURCES ${LANG_Spanish} "Recursos Primarios"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Spanish} "Recursos opcionales"
LangString INST_SEC_EDITOR ${LANG_Spanish} "Editor"
LangString INST_SEC_DEVELOPER ${LANG_Spanish} "Desarrollo"
LangString UNINST_SUCCESS ${LANG_Spanish} "$(^Name) fue removido satisfactoriamente de tu computadora."
LangString UNINST_FAIL ${LANG_Spanish} "¡La desinstalación ha fallado!"
LangString UNINST_REQUEST ${LANG_Spanish} "¿Estás seguro de que quieres remover $(^Name) y todos sus componentes?"
LangString UNINST_REQUEST_NOTE ${LANG_Spanish} "¿Desinstalando antes de actualizar?$\r$\nNo es necesario desinstalar MTA:SA antes de instalar una nueva versión.$\r$\nEjecute el nuevo instalador para actualizarlo y conservar su configuración."
LangString UNINST_DATA_REQUEST ${LANG_Spanish} "¿Le gustaría preservar sus archivos de datos (como los recursos, capturas de pantalla y la configuración del servidor)? Si hace clic en no, se perderán los recursos, configuraciones o capturas de pantalla que haya creado."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Spanish} "No se ha podido descargar el parche para tu versión de Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Spanish} "No se ha podido instalar el parche para tu versión de Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_Spanish} "Este instalador necesita privilegios de administrador, inténtelo de nuevo."
LangString UAC_RIGHTS_UN ${LANG_Spanish} "Este desinstalador necesita privilegios de administrador, inténtelo de nuevo."
LangString UAC_RIGHTS3 ${LANG_Spanish} "¡El servicio de inicio de sesión no está en ejecución, abortando!"
LangString UAC_RIGHTS4 ${LANG_Spanish} "No es posible elevar"
LangString INST_MTA_CONFLICT ${LANG_Spanish} "Una versión diferente y más reciente de MTA ($1) ya existe en ese directorio.$\n$\nMTA está diseñado para que las versiones más recientes sean instaladas en diferentes destinos.$\n ¿Está seguro de que quiere sobrescribir MTA $1 en $INSTDIR?"
LangString INST_GTA_CONFLICT ${LANG_Spanish} "MTA no puede ser instalado en el mismo directorio que GTA:SA.$\n$\n¿Quieres usar el directorio por defecto$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Spanish} "El directorio seleccionado no existe.$\n$\nPor favor seleccione el directorio donde está instalado GTA:SA"
LangString INST_GTA_ERROR2 ${LANG_Spanish} "No se pudo encontrar GTA:SA instalado en $GTA_DIR $\n$\n¿Está seguro de continuar?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Spanish} "Seleccione la Ubicación de Instalación"
LangString INST_CHOOSE_LOC ${LANG_Spanish} "Seleccione la carpeta en la cual instalará ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Spanish} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} se instalará en la siguiente carpeta.$\nPara instalar en otra carpeta, haga clic en Explorar y seleccione otra carpeta.$\n$\n Haga clic en Siguiente para continuar."
LangString INST_CHOOSE_LOC3 ${LANG_Spanish} "Carpeta de destino"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Spanish} "Examinar..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Spanish} "Predeterminado"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Spanish} "Usado por última vez"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Spanish} "Personalizado"
LangString INST_CHOOSE_LOC4 ${LANG_Spanish} "Seleccione la carpeta en la que instalará ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}:"
LangString INST_LOC_OW ${LANG_Spanish} "Advertencia: Una versión diferente y más reciente de MTA ($1) ya existe en esa ubicación."
LangString INST_LOC_UPGRADE ${LANG_Spanish} "Tipo de instalación: Actualización"
LangString NETTEST_TITLE1 ${LANG_Spanish} "Actualización en línea"
LangString NETTEST_TITLE2 ${LANG_Spanish} "Comprobando información de actualización"
LangString NETTEST_STATUS1 ${LANG_Spanish} "Comprobando información de actualización del instalador..."
LangString NETTEST_STATUS2 ${LANG_Spanish} "Por favor asegúrate que tu cortafuegos no este bloqueando"
!insertmacro MUI_LANGUAGE "Polish"
LangString LANGUAGE_CODE ${LANG_Polish} "pl"
LangString WELCOME_TEXT ${LANG_Polish} "Ten instalator pozwoli Ci przejść przez proces instalacji lub aktualizacji $(^Name) ${REVISION_TAG}\n\nZaleca się zamknięcie innych uruchomionych aplikacji na czas działania Instalatora.\n\n[Mogą być wymagane prawa administratora dla systemów Vista i nowszych]\n\nKliknij przycisk Dalej aby kontynuować."
LangString HEADER_Text ${LANG_Polish} "Lokalizacja Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Dest ${LANG_Polish} "Folder zawierający grę Grand Theft Auto: San Andreas"
LangString DIRECTORY_Text_Top ${LANG_Polish} "Wskaż folder, w którym zainstalowano grę Grand Theft Auto: San Andreas.$\n$\nMTA:SA WYMAGA gry GTA:SA w wersji 1.0, aczkolwiek jeśli posiadasz inną wersję, instalator spróbuje ją przystosować do działania z modyfikacją.$\n$\nKliknij przycisk Zainstaluj aby rozpocząć instalację."
LangString DESC_Section10 ${LANG_Polish} "Tworzy grupę dla instalowanej aplikacji w Menu Start"
LangString DESC_Section11 ${LANG_Polish} "Umieszcza skrót do Klienta MTA:SA na Pulpicie."
LangString DESC_Section12 ${LANG_Polish} "Rejestruje obsługę protokołu mtasa:// aby umożliwić szybkie podłączanie się do serwerów MTA poprzez linki w przeglądarce."
LangString DESC_Section13 ${LANG_Polish} "Dodaje odnośnik do funkcji Eksploratora Gier w Windows (o ile dostępna)."
LangString DESC_Section1 ${LANG_Polish} "Podstawowe komponenty wymagane do uruchomienia Multi Theft Auto."
LangString DESC_Section2 ${LANG_Polish} "Modyfikacja MTA:SA pozwala Ci grać online."
LangString DESC_SectionGroupServer ${LANG_Polish} "Serwer Multi Theft Auto. Pozwala na uruchomienie serwera do gry na Twoim komputerze. Wymaga szybkiego połączenia z internetem."
LangString DESC_Section4 ${LANG_Polish} "Serwer Multi Theft Auto. Ten komponent jest wymagany."
LangString DESC_Section5 ${LANG_Polish} "Modyfikacja MTA:SA dla serwera."
LangString DESC_Section6 ${LANG_Polish} "Zestaw zasobów udostępniający podstawową funkcjonalność dla serwera."
LangString DESC_Section7 ${LANG_Polish} "Opcjonalny zestaw zasobów, zawierający standardowe tryby gry i mapy dla serwera."
LangString DESC_Section8 ${LANG_Polish} "Edytor Map dla MTA:SA.  Można go użyć do tworzenia lub edycji map dla rozmaitych trybów gry w MTA."
LangString DESC_Section9 ${LANG_Polish} "Zestaw SDK do tworzenia modułów dla serwera MTA. Zainstaluj go tylko wtedy, gdy dobrze znasz język C++!"
LangString DESC_SectionGroupDev ${LANG_Polish} "Pomocniczy kod oraz narzędzia pomagające w tworzeniu modyfikacji do Multi Theft Auto"
LangString DESC_SectionGroupClient ${LANG_Polish} "Klient jest programem, który służy do gry w Multi Theft Auto"
LangString INST_CLIENTSERVER ${LANG_Polish} "Klient i serwer"
LangString INST_SERVER ${LANG_Polish} "Tylko serwer"
LangString INST_STARTMENU_GROUP ${LANG_Polish} "Utwórz grupę w Menu Start"
LangString INST_DESKTOP_ICON ${LANG_Polish} "Utwórz skrót na Pulpicie"
LangString INST_PROTOCOL ${LANG_Polish} "Zarejestruj protokół mtasa://"
LangString INST_GAMES_EXPLORER ${LANG_Polish} "Dodaj do Eksploratora Gier"
LangString INST_SEC_CLIENT ${LANG_Polish} "Klient gry"
LangString INST_SEC_SERVER ${LANG_Polish} "Serwer dedykowany"
LangString INST_SEC_CORE ${LANG_Polish} "Podstawowe komponenty"
LangString INST_SEC_GAME ${LANG_Polish} "Moduł gry"
LangString INFO_INPLACE_UPGRADE ${LANG_Polish} "Przeprowadzam proces uaktualnienia..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Polish} "Aktualizuję uprawnienia. Może to zająć kilka minut..."
LangString MSGBOX_INVALID_GTASA ${LANG_Polish} "Nie wykryto poprawnie zainstalowanej gry Grand Theft Auto: San Andreas.$\r$\nInstalator będzie jednak kontynuował pracę.$\r$\nW razie problemów - zainstaluj moda jeszcze raz."
LangString INST_SEC_CORE_RESOURCES ${LANG_Polish} "Podstawowe Zasoby"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Polish} "Opcjonalne Zasoby"
LangString INST_SEC_EDITOR ${LANG_Polish} "Edytor Map"
LangString INST_SEC_DEVELOPER ${LANG_Polish} "Narzędzia dla programistów"
LangString UNINST_SUCCESS ${LANG_Polish} "$(^Name) zostało poprawnie usunięte z komputera."
LangString UNINST_FAIL ${LANG_Polish} "Odinstalowywanie nie powiodło się!"
LangString UNINST_REQUEST ${LANG_Polish} "Czy na pewno chcesz usunąć $(^Name) i wszystkie jego składniki?"
LangString UNINST_REQUEST_NOTE ${LANG_Polish} "Czy próbujesz odinstalować moda przed jego aktualizacją?$\r$\nNie ma potrzeby odinstalowywania MTA:SA przed instalacją nowej wersji$\r$\nWystarczy uruchomić instalator nowej wersji moda, żeby dokonać uaktualnienia i zachować swoje ustawienia."
LangString UNINST_DATA_REQUEST ${LANG_Polish} "Czy chcesz zachować utworzone pliki (takie jak Zasoby, zrzuty ekranu i ustawienia serwera)? Jeśli klikniesz Nie, wszystkie Zasoby, pliki konfiguracyjne i zrzuty ekranu jakie stworzyłeś zostaną usunięte."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Polish} "Nie można pobrać łatki dla Twojej wersji Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Polish} "Nie można zainstalować łatki dla Twojej wersji Grand Theft Auto: San Andreas"
LangString UAC_RIGHTS1 ${LANG_Polish} "Ten Instalator wymaga praw administratora do działania, spróbuj ponownie."
LangString UAC_RIGHTS_UN ${LANG_Polish} "Ten Deinstalator wymaga praw administratora do działania, spróbuj ponownie."
LangString UAC_RIGHTS3 ${LANG_Polish} "Usługa Logon nie jest włączona, anulowanie instalacji!"
LangString UAC_RIGHTS4 ${LANG_Polish} "Nie udało się uzyskać praw administratora."
LangString INST_MTA_CONFLICT ${LANG_Polish} "We wskazanym folderze zainstalowano już inną wersję główną MTA ($1).$\n$\nMTA działa prawidłowo tylko wtedy, gdy różne wersje główne moda znajdują się w osobnych folderach.$\nCzy jesteś pewien, że chcesz nadpisać MTA $1 w folderze $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_Polish} "MTA nie może być zainstalowane w tym samym folderze co GTA:SA.$\n$\nCzy chcesz użyć domyślnego folderu instalacji$\n$DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_Polish} "Wskazany folder nie istnieje.$\n$\nProszę wskazać folder, gdzie zainstalowano grę GTA:SA"
LangString INST_GTA_ERROR2 ${LANG_Polish} "Nie znaleziono gry GTA:SA we wskazanym folderze $GTA_DIR $\n$\nCzy jesteś pewien, że chcesz kontynuować instalację?"
LangString INST_CHOOSE_LOC_TOP ${LANG_Polish} "Wybierz miejsce instalacji"
LangString INST_CHOOSE_LOC ${LANG_Polish} "Wybierz folder, gdzie zainstalować ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Polish} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} zostanie zainstalowane w następującym folderze.$\nAby zainstalować je w innym miejscu, kliknij przycisk Przeglądaj i wybierz inny folder.$\n$\n Kliknij przycisk Dalej aby kontynuować."
LangString INST_CHOOSE_LOC3 ${LANG_Polish} "Folder docelowy"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Polish} "Przeglądaj..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Polish} "Domyślny"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Polish} "Ostatnio używany"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Polish} "Niestandardowy"
LangString INST_CHOOSE_LOC4 ${LANG_Polish} "Wybierz folder, gdzie ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} ma zostać zainstalowane:"
LangString INST_LOC_OW ${LANG_Polish} "Uwaga: W wybranym folderze znajduje się już inna główna wersja MTA ($1)."
LangString INST_LOC_UPGRADE ${LANG_Polish} "Typ instalacji:  Aktualizacja"
LangString NETTEST_TITLE1 ${LANG_Polish} "Aktualizacja Online"
LangString NETTEST_TITLE2 ${LANG_Polish} "Sprawdzanie dostępności aktualizacji"
LangString NETTEST_STATUS1 ${LANG_Polish} "Sprawdzanie dostępności aktualizacji dla Instalatora..."
LangString NETTEST_STATUS2 ${LANG_Polish} "Upewnij się, że Twoja zapora sieciowa (firewall) nie blokuje Instalatora"
LangString GET_XPVISTA_PLEASE ${LANG_Polish} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Polish} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString DESC_DirectX ${LANG_Polish} "Install or update DirectX (if required)."
LangString INST_DIRECTX ${LANG_Polish} "Install DirectX"
!insertmacro MUI_LANGUAGE "Arabic"
LangString LANGUAGE_CODE ${LANG_Arabic} "ar"
LangString LANGUAGE_RTL ${LANG_Arabic} "1"
LangString WELCOME_TEXT ${LANG_Arabic} " معالج و مرشد التثبيت او التحديث من $(^Name) ${REVISION_TAG}\n\n  ننصح بـ اغلاق جميع البرامج قبل بدء التثبيت .\n\n [ ربما يتم طلب صلاحيات المسؤول لـ نظام فيستا و مافوق .]\n\nاضغط التالي للمتابعة.."
LangString HEADER_Text ${LANG_Arabic} "مكان لعبة Grand Theft Auto: San Andreas "
LangString DIRECTORY_Text_Dest ${LANG_Arabic} "مجلد : Grand Theft Auto: San Andreas "
LangString DIRECTORY_Text_Top ${LANG_Arabic} "الرجاء اختيار مجلد لعبة Grand Theft Auto: San Andreas.$\n $\n يجب ان تكون لديك نسخة من اللعبة Grand Theft Auto: San Andreas v.1.0 ( MTA ) لا تدعم اي نسخة اخرى .$\n $\nانقر فوق تثبيت لـ بدء التركيب ."
LangString DESC_Section10 ${LANG_Arabic} "إنشاء مجموعة في قائمة ابدأ للتطبيقات المثبتة"
LangString DESC_Section11 ${LANG_Arabic} "انشاء اختصار في سطح المكتب لـ [ MTA : SA ]"
LangString DESC_Section12 ${LANG_Arabic} "تسجيل بروتوكول mtasa:$\\ في المتصفح قابل للنقر ."
LangString DESC_Section13 ${LANG_Arabic} "أضف الى مستكشف العاب ويندوز ( اذا كان موجوداَ ) ."
LangString DESC_Section1 ${LANG_Arabic} "العناصراللازمة لـ تشغيل Multi Theft Auto."
LangString DESC_Section2 ${LANG_Arabic} "في MTA:SA التعديل , يسمح لك اللعب اون لاين ."
LangString DESC_SectionGroupServer ${LANG_Arabic} "يمكنك استضافة سيرفر MTA من جهازك * يتطلب اتصال انترنت سريع ."
LangString DESC_Section4 ${LANG_Arabic} "الشيء المطلوب من MTA هو انشاء سيرفر و التمكن من اللعب فية اون لاين ."
LangString DESC_Section5 ${LANG_Arabic} "MTA:SA تعديلها للسيرفر ."
LangString DESC_Section6 ${LANG_Arabic} "هذهـ بعض المودات المطلوبة للسيرفر ."
LangString DESC_Section7 ${LANG_Arabic} "هذا اختياري لـ وضع اغلب القيمات و المابات لـ سيرفركـ ."
LangString DESC_Section8 ${LANG_Arabic} "الـ MTA:SA Map Editor يمكنك من انشاء ماب خاص بك يستخدم في قيم مود معين لـ MTA ."
LangString DESC_Section9 ${LANG_Arabic} "  SDK لـ انشاء وحدات ثنائية للخادم الخاص بـ MTA اذا كانت لديك اللغة الجيدهـ في برمجة C++ فقط !"
LangString DESC_SectionGroupDev ${LANG_Arabic} "كود التطوير و الادوات تساعد الاعبين على الدخول لـ MTA ."
LangString DESC_SectionGroupClient ${LANG_Arabic} "البرنامج الرئيسي الذي تم تثبيتة هو الذي يمكنك من تشغيل الـ MTA للعب !"
LangString INST_CLIENTSERVER ${LANG_Arabic} "كلنت - سيرفر ( خادم - للاعب نفسة ( عميل ) ) "
LangString INST_SERVER ${LANG_Arabic} "للخادم فقط ( سيرفر )"
LangString INST_STARTMENU_GROUP ${LANG_Arabic} "تشغيل قائمة المجموعه "
LangString INST_DESKTOP_ICON ${LANG_Arabic} "ايقونة سطح المكتب"
LangString INST_PROTOCOL ${LANG_Arabic} "تسجيل mtasa:$\\ البروتوكول "
LangString INST_GAMES_EXPLORER ${LANG_Arabic} "اضافتة الى مستكشف الالعاب"
LangString INST_SEC_CLIENT ${LANG_Arabic} "لعبة كلنت ( عميل )"
LangString INST_SEC_SERVER ${LANG_Arabic} "خادم خاص"
LangString INST_SEC_CORE ${LANG_Arabic} "المكونات الاساسية"
LangString INST_SEC_GAME ${LANG_Arabic} "لعبة وحدة"
LangString INFO_INPLACE_UPGRADE ${LANG_Arabic} "جاري الترقية في نفس المكان ..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_Arabic} "تحديث الاذونات .. قد يستغرق دقائق معدودهـ ..."
LangString MSGBOX_INVALID_GTASA ${LANG_Arabic} "لم يتم العثور على : Grand Theft Auto: San Andreas  في النظام$\r $\nمع ذلك التثبيت سوف يستمر $\r $\nرجاءَ قم باعادهـ التثبيت اذا كان هناك مشكلة لاحقاَ ."
LangString INST_SEC_CORE_RESOURCES ${LANG_Arabic} "المودات الاساسية"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_Arabic} "المودات الاختيارية"
LangString INST_SEC_EDITOR ${LANG_Arabic} "المحرر ( التعديل )"
LangString INST_SEC_DEVELOPER ${LANG_Arabic} "تطوير"
LangString UNINST_SUCCESS ${LANG_Arabic} "$(^Name) تم ازالة بنجاح من كمبيوتركـ ."
LangString UNINST_FAIL ${LANG_Arabic} "فشل الغاء التثبيت !"
LangString UNINST_REQUEST ${LANG_Arabic} "هل انت متأكد انك تريد ازالة $(^Name) و جميع المكونات الخاصة بة ؟"
LangString UNINST_DATA_REQUEST ${LANG_Arabic} "هل تود حفظ بياناتك مثل ( المودات , الصور لقطات الشاشة و جميع اعدادات السيرفر الخاص بـ جهازك ) ؟ اذا قمت باختيار لا اي مود موجود او اعداد او لقطات للشاشة من قبل سوف تذهب و تزال نهائيا ."
LangString MSGBOX_PATCH_FAIL1 ${LANG_Arabic} "غير قادر على تحميل ملف التصحيح للإصدار الخاص بك من  : MTA SA"
LangString MSGBOX_PATCH_FAIL2 ${LANG_Arabic} "غير قادر على تثبيت ملف التصحيح للإصدار الخاص بك من  : MTA SA"
LangString UAC_RIGHTS1 ${LANG_Arabic} "هذا التثبيت يحتاج الى صلاحيات مسؤول حاول مرة اخرى "
LangString UAC_RIGHTS_UN ${LANG_Arabic} "حاول ازالة التثبيت بـ صلاحيات مسؤول حاول مرة اخرى"
LangString UAC_RIGHTS3 ${LANG_Arabic} "خدمة تسجيل الدخول لا تعمل! احباط!"
LangString UAC_RIGHTS4 ${LANG_Arabic} "غير قادر على الرفع !"
LangString INST_MTA_CONFLICT ${LANG_Arabic} "هناك نسخة سابقة من MTA ($1) في هذا المسار.$\n $\nMTA تم اعدادها للاصدارات الرئيسية لم يتم التثبيت في مسار مختلف $\nهل انت متأكد انك تريد تبديل وكتابة الملفات  $1 في $INSTDIR ؟"
LangString INST_GTA_ERROR1 ${LANG_Arabic} "  المسار المختار غير موجود .$\n $\n الرجاء اختيار مسار GTA:SA الخاص بك !"
LangString INST_GTA_ERROR2 ${LANG_Arabic} "لم يتم العثور على GTA:SA مثبتة في $GTA_DIR $\n $\nهل انت متأكد انك تريد المتابعة ؟"
LangString INST_CHOOSE_LOC_TOP ${LANG_Arabic} "اختر مسار التثبيت"
LangString INST_CHOOSE_LOC ${LANG_Arabic} "اختيار المجلد الذي سيتم فيه تثبيت ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_Arabic} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} سيتم تثبيتة في المجلد التالي :$\nلـ التثبيت في مجلد اخر انقر فوق استعراض .$\n $\nانقر فوق التالي للاستكمال ."
LangString INST_CHOOSE_LOC3 ${LANG_Arabic} "وجهة الملف ( المسار )"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_Arabic} "استعراض"
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_Arabic} "افتراضي"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_Arabic} "اخر استخدام"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_Arabic} "مخصص"
LangString INST_CHOOSE_LOC4 ${LANG_Arabic} "اختر المجلد لـ تثبيت ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} في:"
LangString INST_LOC_OW ${LANG_Arabic} "تحذير : هناك نسخة مثبتة من MTA  ($1) في هذا المسار مسبقا!"
LangString INST_LOC_UPGRADE ${LANG_Arabic} "نوع الثبيت : ترقية"
LangString GET_XPVISTA_PLEASE ${LANG_Arabic} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString GET_MASTER_PLEASE ${LANG_Arabic} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString DESC_DirectX ${LANG_Arabic} "Install or update DirectX (if required)."
LangString INST_DIRECTX ${LANG_Arabic} "Install DirectX"
LangString UNINST_REQUEST_NOTE ${LANG_Arabic} "Uninstalling before update?$\r$\nIt is not necessary to uninstall before installing a new version of MTA:SA$\r$\nRun the new installer to upgrade and preserve your settings."
LangString INST_GTA_CONFLICT ${LANG_Arabic} "MTA cannot be installed into the same directory as GTA:SA.$\n$\nDo you want to use the default install directory$\n$DEFAULT_INSTDIR ?"
LangString NETTEST_TITLE1 ${LANG_Arabic} "Online update"
LangString NETTEST_TITLE2 ${LANG_Arabic} "Checking for update information"
LangString NETTEST_STATUS1 ${LANG_Arabic} "Checking for installer update information..."
LangString NETTEST_STATUS2 ${LANG_Arabic} "Please ensure your firewall is not blocking"

LangString	GET_XPVISTA_PLEASE	${LANG_ENGLISH} "The version of MTA:SA you've downloaded does not support Windows XP or Vista.  Please download an alternative version from www.mtasa.com."
LangString  GET_MASTER_PLEASE	${LANG_ENGLISH} "The version of MTA:SA is designed for old versions of Windows.  Please download the newest version from www.mtasa.com."
LangString  WELCOME_TEXT  ${LANG_ENGLISH}   "This wizard will guide you through the installation or update of $(^Name) ${REVISION_TAG}\n\n\
It is recommended that you close all other applications before starting Setup.\n\n\
[Admin access may be requested for Vista and up]\n\n\
Click Next to continue."
LangString  HEADER_Text         ${LANG_ENGLISH} "Grand Theft Auto: San Andreas location"
LangString  DIRECTORY_Text_Dest ${LANG_ENGLISH} "Grand Theft Auto: San Andreas folder"
LangString  DIRECTORY_Text_Top  ${LANG_ENGLISH} "Please select your Grand Theft Auto: San Andreas folder.$\n$\nYou MUST have Grand Theft Auto: San Andreas 1.0 installed to use MTA:SA, it does not support any other versions.$\n$\nClick Install to begin installing."

; Language files
LangString  DESC_Section10          ${LANG_ENGLISH} "Create a Start Menu group for installed applications"
LangString  DESC_Section11          ${LANG_ENGLISH} "Create a Desktop Shortcut for the MTA:SA Client."
LangString  DESC_Section12          ${LANG_ENGLISH} "Register mtasa:// protocol for browser clickable-ness."
LangString  DESC_Section13          ${LANG_ENGLISH} "Add to Windows Games Explorer (if present)."
LangString  DESC_DirectX            ${LANG_ENGLISH} "Install or update DirectX (if required)."
LangString  DESC_Section1           ${LANG_ENGLISH} "The core components required to run Multi Theft Auto."
LangString  DESC_Section2           ${LANG_ENGLISH} "The MTA:SA modification, allowing you to play online."
;LangString DESC_Section3           ${LANG_ENGLISH} "The Multi Theft Auto:Editor for MTA:SA, allowing you to create and edit maps."
;LangString DESC_SectionGroupMods   ${LANG_ENGLISH} "Modifications for Multi Theft Auto. Without at least one of these, you cannot play Multi Theft Auto."
LangString  DESC_SectionGroupServer  ${LANG_ENGLISH}    "The Multi Theft Auto Server. This allows you to host games from your computer. This requires a fast internet connection."
LangString  DESC_Section4           ${LANG_ENGLISH} "The Multi Theft Auto server. This is a required component."
LangString  DESC_Section5           ${LANG_ENGLISH} "The MTA:SA modification for the server."
LangString  DESC_Section6           ${LANG_ENGLISH} "This is a set of required resources for your server."
LangString  DESC_Section7           ${LANG_ENGLISH} "This is an optional set of gamemodes and maps for your server."
LangString  DESC_Section8           ${LANG_ENGLISH} "The MTA:SA 1.0 Map Editor.  This can be used to create your very own maps for use in gamemodes for MTA."
LangString  DESC_Section9           ${LANG_ENGLISH} "This is the SDK for creating binary modules for the MTA server. Only install if you have a good understanding of C++!"
;LangString DESC_Blank          ${LANG_ENGLISH} ""
LangString  DESC_SectionGroupDev        ${LANG_ENGLISH} "Development code and tools that aid in the creation of mods for Multi Theft Auto"
LangString  DESC_SectionGroupClient  ${LANG_ENGLISH}    "The client is the program you run to play on a Multi Theft Auto server"


Function LaunchLink
    SetOutPath "$INSTDIR"
    # Problem: 'non-admin nsis' and 'admin nsis' run at the same time and can have different values for $INSTDIR
    # Fix: Copy to temp variable
    StrCpy $1 "$INSTDIR\Multi Theft Auto.exe"
    !insertmacro UAC_AsUser_ExecShell "" "$1" "" "" ""
FunctionEnd

Function .onInstFailed
    ${LogText} "+Function begin - .onInstFailed"
FunctionEnd

Function .onInit

    ${IfNot} ${UAC_IsInnerInstance}
        !insertmacro MUI_LANGDLL_DISPLAY  # Only display our language selection in the outer (non-admin) instance
    ${Else}
        !insertmacro UAC_AsUser_GetGlobalVar $LANGUAGE # Copy our selected language from the outer to the inner instance
    ${EndIf}
    
	
	${If} ${AtMostWinVista}
		MessageBox MB_OK "$(GET_XPVISTA_PLEASE)"
		ExecShell "open" "http://mtasa.com"
		Quit
	${EndIf}

    File /oname=$TEMP\image.bmp "connect.bmp"
    
    ; #############################################
    ; Remove old shortcuts put in rand(user,admin) startmenu by previous installers (shortcuts now go in all users)
    SetShellVarContext current
    ; Delete shortcuts
    Delete "$SMPROGRAMS\\MTA San Andreas ${0.0}\MTA San Andreas.lnk"
    Delete "$SMPROGRAMS\\MTA San Andreas ${0.0}\Uninstall MTA San Andreas.lnk"
    Delete "$DESKTOP\MTA San Andreas ${0.0}.lnk"

    ; Delete shortcuts
    Delete "$SMPROGRAMS\\MTA San Andreas ${0.0}\MTA Server.lnk"
    Delete "$SMPROGRAMS\\MTA San Andreas ${0.0}\Uninstall MTA San Andreas Server.lnk"
    RmDir /r "$SMPROGRAMS\\MTA San Andreas ${0.0}"
    ; #############################################

    SetShellVarContext all

    ${LogSetFileName} "$APPDATA\MTA San Andreas All\Common\Installer" "nsis.log"
    ${LogText} "${PRODUCT_VERSION} ${REVISION_TAG}"
    ${LogText} "+Function begin - .onInit"

    ; Try to find previously saved MTA:SA install path
    ReadRegStr $Install_Dir HKLM "SOFTWARE\Multi Theft Auto: San Andreas All\${0.0}" "Last Install Location"
    ${If} $Install_Dir == "" 
        ReadRegStr $Install_Dir HKLM "SOFTWARE\Multi Theft Auto: San Andreas ${0.0}" "Last Install Location"
    ${EndIf}
    ${If} $Install_Dir != "" 
        Call NoteMTAWasPresent
    ${EndIf}

    ${If} $Install_Dir == "" 
        strcpy $Install_Dir "$PROGRAMFILES\MTA San Andreas ${0.0}"
    ${EndIf}
    strcpy $INSTDIR $Install_Dir
    ${LogText} "Using install directory:'$INSTDIR'"

    ; Setup for install dir dialog
    strcpy $DEFAULT_INSTDIR "$PROGRAMFILES\MTA San Andreas ${0.0}"
    strcpy $LAST_INSTDIR $Install_Dir
    strcpy $CUSTOM_INSTDIR $DEFAULT_INSTDIR
    ${If} $DEFAULT_INSTDIR == $LAST_INSTDIR 
        StrCpy $WhichRadio "default"
        StrCpy $ShowLastUsed "0"
    ${Else}
        Push $LAST_INSTDIR 
        Call GetInstallType
        Pop $0
        Pop $1
        ${If} $0 == "overwrite"
            # Ignore last used if it contains different major MTA version
            StrCpy $WhichRadio "default"
            StrCpy $ShowLastUsed "0"
        ${Else}
            StrCpy $WhichRadio "last"
            StrCpy $ShowLastUsed "1"
        ${EndIf}
    ${EndIf}

    ; Try to find previously saved GTA:SA install path
    ReadRegStr $2 HKLM "SOFTWARE\Multi Theft Auto: San Andreas All\Common" "GTA:SA Path"
    ${If} $2 == "" 
        ReadRegStr $2 HKCU "SOFTWARE\Multi Theft Auto: San Andreas" "GTA:SA Path"
    ${EndIf}
    ${If} $2 == "" 
        ReadRegStr $2 HKLM "SOFTWARE\Rockstar Games\GTA San Andreas\Installation" "ExePath"
    ${EndIf}
    ${If} $2 == "" 
        ReadRegStr $2 HKLM "SOFTWARE\Multi Theft Auto: San Andreas" "GTA:SA Path"
    ${EndIf}
    ${If} $2 == "" 
        ReadRegStr $3 HKCU "Software\Valve\Steam\Apps\12120" "Installed"
        StrCpy $3 $3 1
        ${If} $3 == "1"
            ReadRegStr $3 HKCU "Software\Valve\Steam" "SteamPath"
            StrCpy $2 "$3\steamapps\common\grand theft auto san andreas"
        ${EndIf}
    ${EndIf}
    ${If} $2 == "" 
        ReadRegStr $2 HKCU "SOFTWARE\Multi Theft Auto: San Andreas ${0.0}" "GTA:SA Path Backup"
    ${EndIf}

    ; Report previous install status
    ${If} $2 != "" 
        Call NoteGTAWasPresent
    ${EndIf}

    ; Remove exe name from path
    !insertmacro ReplaceSubStr $2 "gta_sa.exe" ""
    ; Conform slash types
    !insertmacro ReplaceSubStr $MODIFIED_STR "/" "\"
    ; Remove quotes
    strcpy $3 '"'
    !insertmacro ReplaceSubStr $MODIFIED_STR $3 ""
    ; Store result 
    strcpy $GTA_DIR $MODIFIED_STR

    ; Default to standard path if nothing defined
    ${If} $GTA_DIR == "" 
        strcpy $GTA_DIR "$PROGRAMFILES\Rockstar Games\GTA San Andreas\"
    ${EndIf}

    ${LogText} "Default GTA install directory:'$GTA_DIR'"

    InitPluginsDir
    ;File /oname=$PLUGINSDIR\serialdialog.ini "serialdialog.ini"

    # Set Windows SID to use for permissions fixing
    Call SetPermissionsGroup
    ${LogText} "-Function end - .onInit"
FunctionEnd

Function .onInstSuccess
    ${LogText} "+Function begin - .onInstSuccess"
    SetShellVarContext all

    WriteRegStr HKLM "SOFTWARE\Multi Theft Auto: San Andreas All\Common" "GTA:SA Path" $GTA_DIR
    WriteRegStr HKLM "SOFTWARE\Multi Theft Auto: San Andreas All\${0.0}" "Last Install Location" $INSTDIR
    
    ; Start menu items
    ${If} $CreateSMShortcuts == 1
        CreateDirectory "$SMPROGRAMS\MTA San Andreas ${0.0}"

        IfFileExists "$INSTDIR\Multi Theft Auto.exe" 0 skip1
        SetOutPath "$INSTDIR"
        Delete "$SMPROGRAMS\\MTA San Andreas ${0.0}\Play MTA San Andreas.lnk"
        CreateShortCut "$SMPROGRAMS\\MTA San Andreas ${0.0}\MTA San Andreas.lnk" "$INSTDIR\Multi Theft Auto.exe" \
            "" "$INSTDIR\Multi Theft Auto.exe" 0 SW_SHOWNORMAL \
            "" "Play Multi Theft Auto: San Andreas ${0.0}"
        skip1:
        
        IfFileExists "$INSTDIR\Server\MTA Server.exe" 0 skip2
        SetOutPath "$INSTDIR\Server"
        CreateShortCut "$SMPROGRAMS\\MTA San Andreas ${0.0}\MTA Server.lnk" "$INSTDIR\Server\MTA Server.exe" \
            "" "$INSTDIR\Server\MTA Server.exe" 2 SW_SHOWNORMAL \
            "" "Run the Multi Theft Auto: San Andreas ${0.0} Server"
        skip2:
        
        IfFileExists "$INSTDIR\Uninstall.exe" 0 skip3
        SetOutPath "$INSTDIR"
        CreateShortCut "$SMPROGRAMS\\MTA San Andreas ${0.0}\Uninstall MTA San Andreas.lnk" "$INSTDIR\Uninstall.exe" \
            "" "$INSTDIR\Uninstall.exe" 0 SW_SHOWNORMAL \
            "" "Uninstall Multi Theft Auto: San Andreas ${0.0}"
        skip3:
    ${EndIf}
    
    ${If} $CreateDesktopIcon == 1
        IfFileExists "$INSTDIR\Multi Theft Auto.exe" 0 skip4
        SetOutPath "$INSTDIR"
        Delete "$DESKTOP\Play MTA San Andreas ${0.0}.lnk"
        CreateShortCut "$DESKTOP\MTA San Andreas ${0.0}.lnk" "$INSTDIR\Multi Theft Auto.exe" \
            "" "$INSTDIR\Multi Theft Auto.exe" 0 SW_SHOWNORMAL \
            "" "Play Multi Theft Auto: San Andreas ${0.0}"
        AccessControl::GrantOnFile "$DESKTOP\MTA San Andreas ${0.0}.lnk" "($PermissionsGroup)" "FullAccess"

        skip4:
    ${EndIf}

    ${If} $RegisterProtocol == 1
        ; Add the protocol handler
        WriteRegStr HKCR "mtasa" "" "URL:MTA San Andreas Protocol"
        WriteRegStr HKCR "mtasa" "URL Protocol" ""
        WriteRegStr HKCR "mtasa\DefaultIcon" "" "$INSTDIR\Multi Theft Auto.exe"
        WriteRegStr HKCR "mtasa\shell\open\command" "" '"$INSTDIR\Multi Theft Auto.exe"%1'
    ${EndIf}

    ;UAC::Unload ;Must call unload!
    ${LogText} "-Function end - .onInstSuccess"
FunctionEnd

LangString INST_CLIENTSERVER ${LANG_ENGLISH}    "Client and Server"
LangString INST_SERVER ${LANG_ENGLISH}  "Server only"


InstType "$(INST_CLIENTSERVER)"
InstType "$(INST_SERVER)"

Name "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
OutFile "${INSTALL_OUTPUT}"

;InstallDir "$PROGRAMfiles San Andreas"
InstallDirRegKey HKLM "SOFTWARE\Multi Theft Auto: San Andreas All\${0.0}" "Last Install Location"
ShowInstDetails show
ShowUnInstDetails show

LangString INST_STARTMENU_GROUP     ${LANG_ENGLISH} "Start menu group"
LangString INST_DESKTOP_ICON        ${LANG_ENGLISH} "Desktop icon"
LangString INST_PROTOCOL            ${LANG_ENGLISH} "Register mtasa:// protocol"
LangString INST_GAMES_EXPLORER      ${LANG_ENGLISH} "Add to Games Explorer"
LangString INST_DIRECTX             ${LANG_ENGLISH} "Install DirectX"

Section "$(INST_STARTMENU_GROUP)" SEC10
    SectionIn 1 2
    StrCpy $CreateSMShortcuts 1
SectionEnd

Section "$(INST_DESKTOP_ICON)" SEC11
    SectionIn 1 2
    StrCpy $CreateDesktopIcon 1
SectionEnd

Section "$(INST_PROTOCOL)" SEC12
    SectionIn 1 2
    StrCpy $RegisterProtocol 1
SectionEnd

Section "$(INST_GAMES_EXPLORER)" SEC13
    SectionIn 1 2
    StrCpy $AddToGameExplorer 1
SectionEnd

Section "$(INST_DIRECTX)" SEC_DIRECTX
    SectionIn 1 2
    SetOutPath "$TEMP"
    File "${FILES_ROOT}\redist\dxwebsetup.exe"
    DetailPrint "Running DirectX Setup..."
    ExecWait '"$TEMP\dxwebsetup.exe" /Q'
    DetailPrint "Finished DirectX Setup"
    Delete "$TEMP\dxwebsetup.exe"
    SetOutPath "$INSTDIR"
SectionEnd


LangString INST_SEC_CLIENT      ${LANG_ENGLISH} "Game client"
LangString INST_SEC_SERVER      ${LANG_ENGLISH} "Dedicated server"
LangString INST_SEC_CORE            ${LANG_ENGLISH} "Core components"
LangString INST_SEC_GAME            ${LANG_ENGLISH} "Game module"

LangString INFO_INPLACE_UPGRADE ${LANG_ENGLISH} "Performing in-place upgrade..."
LangString INFO_UPDATE_PERMISSIONS ${LANG_ENGLISH}  "Updating permissions. This could take a few minutes..."
LangString MSGBOX_INVALID_GTASA ${LANG_ENGLISH} "A valid Windows version of Grand Theft Auto: San Andreas was not detected.\
$\r$\nHowever installation will continue.\
$\r$\nPlease reinstall if there are problems later."
LangString INST_SEC_CORE_RESOURCES ${LANG_ENGLISH}  "Core Resources"
LangString INST_SEC_OPTIONAL_RESOURCES ${LANG_ENGLISH}  "Optional Resources"
LangString INST_SEC_EDITOR ${LANG_ENGLISH}  "Editor"

SectionGroup /e "$(INST_SEC_CLIENT)" SECGCLIENT
    Section "$(INST_SEC_CORE)" SEC01
        SectionIn 1 RO ; section is required
        ${LogText} "+Section begin - CLIENT CORE"

        SetShellVarContext all

        #############################################################
        # Show that upgrade is catered for
        Push $INSTDIR 
        Call GetInstallType
        Pop $0
        Pop $1

        ${If} $0 == "upgrade"
            DetailPrint "$(INFO_INPLACE_UPGRADE)"
            Sleep 1000
        ${EndIf}
        #############################################################

        WriteRegStr HKLM "SOFTWARE\Multi Theft Auto: San Andreas All\Common" "GTA:SA Path" $GTA_DIR
        WriteRegStr HKLM "SOFTWARE\Multi Theft Auto: San Andreas All\${0.0}" "Last Install Location" $INSTDIR

        # Create fixed path data directories
        CreateDirectory "$APPDATA\MTA San Andreas All\Common"
        CreateDirectory "$APPDATA\MTA San Andreas All\${0.0}"

        # Ensure install dir exists so the permissions can be set
        SetOutPath "$INSTDIR\MTA"
        SetOverwrite on

        #############################################################
        # Make the directory "$INSTDIR" read write accessible by all users
        # Make the directory "$APPDATA\MTA San Andreas All" read write accessible by all users
        # Make the directory "$GTA_DIR" read write accessible by all users

        ${If} ${AtLeastWinVista}
            DetailPrint "$(INFO_UPDATE_PERMISSIONS)"

            # Fix permissions for MTA install directory

            # Check if install path begins with "..Program Files (x86)\M" or "..Program Files\M"
            StrCpy $3 "0"
            StrCpy $0 "$PROGRAMFILES\M"
            StrLen $2 $0
            StrCpy $1 "$INSTDIR" $2
            ${If} $0 == $1
                StrCpy $3 "1"
            ${EndIf}

            StrCpy $0 "$PROGRAMFILES64\M"
            StrLen $2 $0
            StrCpy $1 "$INSTDIR" $2
            ${If} $0 == $1
                StrCpy $3 "1"
            ${EndIf}

            ${LogText} "FullAccess $INSTDIR"
            ${If} $3 == "1"
                FastPerms::FullAccessPlox "$INSTDIR" "($PermissionsGroup)"
            ${Else}
                # More conservative permissions blat if install directory it too different from default
                CreateDirectory "$INSTDIR\mods"
                CreateDirectory "$INSTDIR\screenshots"
                CreateDirectory "$INSTDIR\server"
                CreateDirectory "$INSTDIR\skins"
                FastPerms::FullAccessPlox "$INSTDIR\mods" "($PermissionsGroup)"
                FastPerms::FullAccessPlox "$INSTDIR\MTA" "($PermissionsGroup)"
                FastPerms::FullAccessPlox "$INSTDIR\screenshots" "($PermissionsGroup)"
                FastPerms::FullAccessPlox "$INSTDIR\server" "($PermissionsGroup)"
                FastPerms::FullAccessPlox "$INSTDIR\skins" "($PermissionsGroup)"
            ${EndIf}
            ${LogText} "FullAccess $APPDATA\MTA San Andreas All"
            FastPerms::FullAccessPlox "$APPDATA\MTA San Andreas All" "($PermissionsGroup)"

            # Remove MTA virtual store
            StrCpy $0 $INSTDIR
            !insertmacro UAC_AsUser_Call Function RemoveVirtualStore ${UAC_SYNCREGISTERS}
            StrCpy $0 $INSTDIR
            Call RemoveVirtualStore

            Push $GTA_DIR 
            Call IsGtaDirectory
            Pop $0
            ${If} $0 == "gta"
                # Fix permissions for GTA install directory
                FastPerms::FullAccessPlox "$GTA_DIR" "($PermissionsGroup)"

                # Remove GTA virtual store
                StrCpy $0 $GTA_DIR
                !insertmacro UAC_AsUser_Call Function RemoveVirtualStore ${UAC_SYNCREGISTERS}
                StrCpy $0 $GTA_DIR
                Call RemoveVirtualStore
            ${EndIf}
        ${EndIf}
        #############################################################

        # Handle "Grand Theft Auto San Andreas.exe" being present instead of gta_sa.exe
        IfFileExists "$GTA_DIR\gta_sa.exe" noCopyReq
            IfFileExists "$GTA_DIR\Grand Theft Auto San Andreas.exe" 0 noCopyReq
                CopyFiles "$GTA_DIR\Grand Theft Auto San Andreas.exe" "$GTA_DIR\gta_sa.exe"
        noCopyReq:

        #############################################################
        # Patch our San Andreas .exe if it is required
            nsArray::SetList array "gta_sa.exe" "gta-sa.exe" "testapp.exe" /end
            ${ForEachIn} array $0 $1
                IfFileExists $GTA_DIR\$1 0 TryNextExe
                ${GetSize} "$GTA_DIR" "/M=$1 /S=0M /G=0" $0 $3 $4
                StrCmp "$0" "0" TryNextExe
                !insertmacro GetMD5 $GTA_DIR\$1 $ExeMD5
                DetailPrint "$1 successfully detected ($ExeMD5)"
                ${LogText} "GetMD5 $GTA_DIR\$1 $ExeMD5"
                ${Switch} $ExeMD5
                    ${Case} "bf25c28e9f6c13bd2d9e28f151899373" #US 2.00
                    ${Case} "7fd5f9436bd66af716ac584ff32eb483" #US 1.01
                    ${Case} "d84326ba0e0ace89f87288ffe7504da4" #EU 3.00 Steam Mac
                    ${Case} "4e99d762f44b1d5e7652dfa7e73d6b6f" #EU 2.00
                    ${Case} "2ac4b81b3e85c8d0f9846591df9597d3" #EU 1.01
                    ${Case} "d0ad36071f0e9bead7bddea4fbda583f" #EU 1.01 GamersGate
                    ${Case} "25405921d1c47747fd01fd0bfe0a05ae" #EU 1.01 DEViANCE
                    ${Case} "9effcaf66b59b9f8fb8dff920b3f6e63" #DE 2.00
                    ${Case} "fa490564cd9811978085a7a8f8ed7b2a" #DE 1.01
                    ${Case} "49dd417760484a18017805df46b308b8" #DE 1.00
                    ${Case} "185f0970f5913d0912a89789af175ffe" #?? ?.?? 4,496,063 bytes
                    ${Case} "0fd315d1af41e26e536a78b4d4556488" #EU 3.00 Steam                   2007-12-04 11:50:50     5697536
                    ${Case} "2ed36a3cee7b77da86a343838e3516b6" #EU 3.01 Steam (2014 Nov update) 2014-10-14 21:58:05     5971456
                    ${Case} "5bfd4dd83989a8264de4b8e771f237fd" #EU 3.02 Steam (2014 Dec update) 2014-12-01 20:43:21     5971456
                    ${Case} "d9cb35c898d3298ca904a63e10ee18d7" #DE 3.02 Steam (2014 Dec update) 2016-08-11 20:57:22     5971456
                    ${Case} "c29d96e0c063cd4568d977bcf273215f" #?? ?.?? 5,719,552 bytes
                        #Copy to gta_sa.exe and commence patching process
                        CopyFiles "$GTA_DIR\$1" "$GTA_DIR\gta_sa.exe.bak"
                        Call InstallPatch
                        ${If} $PatchInstalled == "1"
                            Goto CompletePatchProc
                        ${EndIf}
                        Goto TryNextExe
                        ${Break}
                    ${Default}
                        ${If} $1 == "gta_sa.exe"
                            Goto CompletePatchProc #This gta_sa.exe doesn't need patching, let's continue
                        ${EndIf}
                        ${Break}
                ${EndSwitch}
                TryNextExe:
            ${Next}

        NoExeFound:
            MessageBox MB_ICONSTOP "$(MSGBOX_INVALID_GTASA)"
        CompletePatchProc:

        #############################################################
        # Fix missing or incorrect VS2013 redist files
        SetOutPath $SYSDIR
        Push $SYSDIR\msvcp120.dll
        Call IsDll32Bit
        Pop $0
        ${If} $0 != 1
            File "${FILES_ROOT}\redist\msvcp120.dll"
        ${EndIf}

        Push $SYSDIR\msvcr120.dll
        Call IsDll32Bit
        Pop $0
        ${If} $0 != 1
            File "${FILES_ROOT}\redist\msvcr120.dll"
        ${EndIf}
        #############################################################

        #############################################################
        # For XP, install Microsoft Internationalized Domain Names (IDN) Mitigation APIs
        SetOutPath "$TEMP"
        ${If} ${AtMostWinXP}
            ${IfNot} ${FileExists} $SYSDIR\normaliz.dll
                ${LogText} "Did not find $SYSDIR\normaliz.dll"
                File "${FILES_ROOT}\redist\idndl.x86.exe"
                ExecWait '"$TEMP\idndl.x86.exe" /passive'
            ${EndIf}
        ${EndIf}
        #############################################################

        #############################################################
        # Install SHA2 support for older Win7 x64
        ${If} ${IsWin7}
            ${If} ${RunningX64}
                ${GetDLLVersionNumbers} "$SYSDIR\crypt32.dll" $0 $1 $2 $3
                ${If} $2 == 7601
                    ${If} $3 < 18741
                        ${InstallKB} "KB3035131" "Windows6.1-KB3035131-x64" "http://download.microsoft.com/download/3/D/F/3DF6B0B1-D849-4272-AA98-3AA8BB456CCC/Windows6.1-KB3035131-x64.msu"
                        ${InstallKB} "KB3033929" "Windows6.1-KB3033929-x64" "http://download.microsoft.com/download/C/8/7/C87AE67E-A228-48FB-8F02-B2A9A1238099/Windows6.1-KB3033929-x64.msu"
                    ${EndIf}
                ${EndIf}
            ${EndIf}
        ${EndIf}
        #############################################################

        SetOutPath "$INSTDIR\MTA"
        SetOverwrite on

        # Make some keys in HKLM read write accessible by all users
        AccessControl::GrantOnRegKey HKLM "SOFTWARE\Multi Theft Auto: San Andreas All" "($PermissionsGroup)" "FullAccess"

        SetOutPath "$INSTDIR\MTA"
        File "${FILES_ROOT}\mta\cgui.dll"
        File "${FILES_ROOT}\mta\core.dll"
        File "${FILES_ROOT}\mta\xmll.dll"
        File "${FILES_ROOT}\mta\game_sa.dll"
        File "${FILES_ROOT}\mta\multiplayer_sa.dll"
        File "${FILES_ROOT}\mta\netc.dll"
        File "${FILES_ROOT}\mta\loader.dll"
        File "${FILES_ROOT}\mta\pthread.dll"
        File "${FILES_ROOT}\mta\cefweb.dll"
        File "${FILES_ROOT}\mta\libwow64.dll"
        File "${FILES_ROOT}\mta\wow64_helper.exe"

        File "${FILES_ROOT}\mta\bass.dll"
        File "${FILES_ROOT}\mta\bass_aac.dll"
        File "${FILES_ROOT}\mta\bass_ac3.dll"
        File "${FILES_ROOT}\mta\bass_fx.dll"
        File "${FILES_ROOT}\mta\bassflac.dll"
        File "${FILES_ROOT}\mta\bassmidi.dll"
        File "${FILES_ROOT}\mta\bassmix.dll"
        File "${FILES_ROOT}\mta\bassopus.dll"
        File "${FILES_ROOT}\mta\basswma.dll"
        File "${FILES_ROOT}\mta\tags.dll"

        SetOutPath "$INSTDIR\MTA"
		File "${FILES_ROOT}\mta\chrome_elf.dll"
        File "${FILES_ROOT}\mta\libcef.dll"
        File "${FILES_ROOT}\mta\icudtl.dat"
        File "${FILES_ROOT}\mta\libEGL.dll"
        File "${FILES_ROOT}\mta\libGLESv2.dll"
        File "${FILES_ROOT}\mta\natives_blob.bin"
        File "${FILES_ROOT}\mta\snapshot_blob.bin"
        File "${FILES_ROOT}\mta\v8_context_snapshot.bin"
        
        SetOutPath "$INSTDIR\MTA\CEF"
        File "${FILES_ROOT}\mta\CEF\CEFLauncher.exe"
        File "${FILES_ROOT}\mta\CEF\CEFLauncher_DLL.dll"
        File "${FILES_ROOT}\mta\CEF\cef.pak"
        File "${FILES_ROOT}\mta\CEF\cef_100_percent.pak"
        File "${FILES_ROOT}\mta\CEF\cef_200_percent.pak"
        File "${FILES_ROOT}\mta\CEF\devtools_resources.pak"
        #File "${FILES_ROOT}\mta\CEF\cef_extensions.pak"
        
        SetOutPath "$INSTDIR\MTA\CEF\locales"
        File "${FILES_ROOT}\mta\CEF\locales\en-US.pak"


        ${If} "$(LANGUAGE_CODE)" != ""
            # Write our language to registry
            WriteRegStr HKLM "SOFTWARE\Multi Theft Auto: San Andreas All\${0.0}\Settings\general" "locale" "$(LANGUAGE_CODE)"
        ${EndIf}

        !ifndef LIGHTBUILD

            SetOutPath "$INSTDIR\MTA"
            File "${FILES_ROOT}\mta\d3dx9_42.dll"
            File "${FILES_ROOT}\mta\D3DCompiler_42.dll"
            File "${FILES_ROOT}\mta\sa.dat"
            File "${FILES_ROOT}\mta\vea.dll"
            File "${FILES_ROOT}\mta\vog.dll"
            File "${FILES_ROOT}\mta\vvo.dll"
            File "${FILES_ROOT}\mta\vvof.dll"
            File "${FILES_ROOT}\mta\XInput9_1_0_mta.dll"
            File "${FILES_ROOT}\mta\xinput1_3_mta.dll"

            File "${FILES_ROOT}\mta\d3dcompiler_43.dll"
            File "${FILES_ROOT}\mta\d3dcompiler_47.dll"

            SetOutPath "$INSTDIR\MTA\config"
            File "${FILES_ROOT}\mta\config\chatboxpresets.xml"

            SetOutPath "$INSTDIR\skins\Classic"
            File "${FILES_ROOT}\skins\Classic\CGUI.is.xml"
            File "${FILES_ROOT}\skins\Classic\CGUI.lnf.xml"
            File "${FILES_ROOT}\skins\Classic\CGUI.png"
            File "${FILES_ROOT}\skins\Classic\CGUI.xml"
            
            SetOutPath "$INSTDIR\skins\Default"
            File "${FILES_ROOT}\skins\Default\CGUI.is.xml"
            File "${FILES_ROOT}\skins\Default\CGUI.lnf.xml"
            File "${FILES_ROOT}\skins\Default\CGUI.png"
            File "${FILES_ROOT}\skins\Default\CGUI.xml"
            
            SetOutPath "$INSTDIR\skins\Lighter black"
            File "${FILES_ROOT}\skins\Lighter black\CGUI.is.xml"
            File "${FILES_ROOT}\skins\Lighter black\CGUI.lnf.xml"
            File "${FILES_ROOT}\skins\Lighter black\CGUI.png"
            File "${FILES_ROOT}\skins\Lighter black\CGUI.xml"

            SetOutPath "$INSTDIR\MTA\cgui"
            File "${FILES_ROOT}\mta\cgui\Falagard.xsd"
            File "${FILES_ROOT}\mta\cgui\Font.xsd"
            File "${FILES_ROOT}\mta\cgui\GUIScheme.xsd"
            File "${FILES_ROOT}\mta\cgui\Imageset.xsd"
            File "${FILES_ROOT}\mta\cgui\pricedown.ttf"
            File "${FILES_ROOT}\mta\cgui\sabankgothic.ttf"
            File "${FILES_ROOT}\mta\cgui\sagothic.ttf"
            File "${FILES_ROOT}\mta\cgui\saheader.ttf"
            File "${FILES_ROOT}\mta\cgui\sans.ttf"
            File "${FILES_ROOT}\mta\cgui\unifont-5.1.20080907.ttf"

            SetOutPath "$INSTDIR\MTA\cgui\images"
            File "${FILES_ROOT}\mta\cgui\images\*.png"
            File "${FILES_ROOT}\mta\cgui\images\*.jpg"

            SetOutPath "$INSTDIR\MTA\cgui\images\radarset"
            File "${FILES_ROOT}\mta\cgui\images\radarset\*.png"

            SetOutPath "$INSTDIR\MTA\cgui\images\transferset"
            File "${FILES_ROOT}\mta\cgui\images\transferset\*.png"

            SetOutPath "$INSTDIR\MTA\cgui\images\serverbrowser"
            File "${FILES_ROOT}\mta\cgui\images\serverbrowser\*.png"

        !endif
            
        SetOutPath "$INSTDIR\MTA\locale\"
        File /r "${FILES_ROOT}\mta\locale\*.png"
        File /r "${FILES_ROOT}\mta\locale\*.po"

        SetOutPath "$INSTDIR"
        File "${FILES_ROOT}\Multi Theft Auto.exe"

        # Ensure exe file can be updated without admin
        AccessControl::GrantOnFile "$INSTDIR\Multi Theft Auto.exe" "($PermissionsGroup)" "FullAccess"

        ${If} $AddToGameExplorer == 1
            ${GameExplorer_UpdateGame} ${GUID}
            ${If} ${Errors}
                ${GameExplorer_AddGame} all "$INSTDIR\Multi Theft Auto.exe" "$INSTDIR" "$INSTDIR\Multi Theft Auto.exe" ${GUID}
                CreateDirectory $APPDATA\Microsoft\Windows\GameExplorer\${GUID}\SupportTasks\0
                CreateShortcut "$APPDATA\Microsoft\Windows\GameExplorer\$0\SupportTasks\0\Client Manual.lnk" \ "http://wiki.multitheftauto.com/wiki/Client_Manual"
            ${EndIf}
        ${EndIf}

        Call DoServiceInstall
        ${LogText} "-Section end - CLIENT CORE"
    SectionEnd

    Section "$(INST_SEC_GAME)" SEC02
        ${LogText} "+Section begin - CLIENT GAME"
        SectionIn 1 RO
        SetOutPath "$INSTDIR\mods\deathmatch"
        File "${FILES_ROOT}\mods\deathmatch\Client.dll"
        File "${FILES_ROOT}\mods\deathmatch\pcre3.dll"
        SetOutPath "$INSTDIR\mods\deathmatch\resources"
        ${LogText} "-Section end - CLIENT GAME"
    SectionEnd
SectionGroupEnd

SectionGroup /e "$(INST_SEC_SERVER)" SECGSERVER
    Section "$(INST_SEC_CORE)" SEC04
        ${LogText} "+Section begin - SERVER CORE"
        SectionIn 1 2 RO ; section is required
        
        SetOutPath "$INSTDIR\server"
        SetOverwrite on
        File "${SERVER_FILES_ROOT}\core.dll"
        File "${FILES_ROOT}\mta\xmll.dll"
        File "${SERVER_FILES_ROOT}\MTA Server.exe"
        File "${SERVER_FILES_ROOT}\net.dll"
        File "${FILES_ROOT}\mta\pthread.dll"
        ${LogText} "-Section end - SERVER CORE"
    SectionEnd

    Section "$(INST_SEC_GAME)" SEC05
        ${LogText} "+Section begin - SERVER GAME"
        SectionIn 1 2 RO ; section is required
        SetOutPath "$INSTDIR\server\mods\deathmatch"
        
        SetOverwrite on
        File "${SERVER_FILES_ROOT}\mods\deathmatch\deathmatch.dll"
        File "${SERVER_FILES_ROOT}\mods\deathmatch\lua5.1.dll"
        File "${FILES_ROOT}\mods\deathmatch\pcre3.dll"
        File "${SERVER_FILES_ROOT}\mods\deathmatch\dbconmy.dll"
        !ifndef LIGHTBUILD
            File "${SERVER_FILES_ROOT}\mods\deathmatch\libmysql.dll"
        !endif
        
        ;Only overwrite the following files if previous versions were bugged and explicitly need replacing
        !insertmacro FileIfMD5 "${SERVER_FILES_ROOT}\mods\deathmatch\editor_acl.xml" "711185d8f4ebb355542053ce408b82b3"
        !insertmacro FileIfMD5 "${SERVER_FILES_ROOT}\mods\deathmatch\editor_acl.xml" "706869E53F508919F987A2F7F2653AD2"

        SetOverwrite off
        File "${SERVER_FILES_ROOT}\mods\deathmatch\acl.xml"
        File "${SERVER_FILES_ROOT}\mods\deathmatch\editor_acl.xml"
        File "${SERVER_FILES_ROOT}\mods\deathmatch\banlist.xml"
        File "${SERVER_FILES_ROOT}\mods\deathmatch\mtaserver.conf"
        File "${SERVER_FILES_ROOT}\mods\deathmatch\local.conf"
        File "${SERVER_FILES_ROOT}\mods\deathmatch\editor.conf"
        File "${SERVER_FILES_ROOT}\mods\deathmatch\vehiclecolors.conf"

        !ifndef LIGHTBUILD
            File "${SERVER_FILES_ROOT}\mods\deathmatch\local.conf"
            
            SetOutPath "$INSTDIR\server\mods\deathmatch\resources"
            SetOutPath "$INSTDIR\server\mods\deathmatch\resource-cache"
            SetOutPath "$INSTDIR\server\mods\deathmatch\logs"
        !endif
        ${LogText} "-Section end - SERVER GAME"
    SectionEnd

    !ifndef LIGHTBUILD
        Section "$(INST_SEC_CORE_RESOURCES)" SEC06
            ${LogText} "+Section begin - SERVER CORE_RESOURCES"
            SectionIn 1 2 ; RO section is now optional
            SetOutPath "$INSTDIR\server\mods\deathmatch\resources\"
            File "${SERVER_FILES_ROOT}\mods\deathmatch\resources\Directory layout readme.txt"

            SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[admin]"
            SetOverwrite ifnewer
            File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[admin]\admin.zip"
            File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[admin]\runcode.zip"
            File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[admin]\acpanel.zip"
            File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[admin]\ipb.zip"
            SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[gamemodes]\[play]"
            File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[gamemodes]\[play]\*.zip"
            SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[gameplay]"
            File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[gameplay]\*.zip"
            SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[managers]"
            File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[managers]\*.zip"
            SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[web]"
            File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[web]\*.zip"
            ${LogText} "-Section end - SERVER CORE_RESOURCES"
        SectionEnd
    !endif

    !ifndef LIGHTBUILD
        SectionGroup "$(INST_SEC_OPTIONAL_RESOURCES)" SEC07
            Section "AMX Emulation package"
            SectionIn 1 2
                SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[gamemodes]\[amx]"
                SetOverwrite ifnewer
                File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[gamemodes]\[amx]\amx"
            SectionEnd
            Section "Assault Gamemode"
            SectionIn 1 2
                SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[gamemodes]\[assault]"
                SetOverwrite ifnewer
                File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[gamemodes]\[assault]\*.zip"
            SectionEnd
            Section "Briefcase Race Gamemode"
            SectionIn 1 2
                SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[gamemodes]\[briefcaserace]"
                SetOverwrite ifnewer
                File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[gamemodes]\[briefcaserace]\*.zip"
            SectionEnd
            Section "Classic Deathmatch Gamemode"
            SectionIn 1 2
                SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[gamemodes]\[cdm]"
                SetOverwrite ifnewer
                File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[gamemodes]\[cdm]\*.zip"
            SectionEnd
            Section "Capture the Flag Gamemode"
            SectionIn 1 2
                SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[gamemodes]\[ctf]"
                SetOverwrite ifnewer
                File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[gamemodes]\[ctf]\*.zip"
            SectionEnd
            Section "Capture the Vehicle Gamemode"
            SectionIn 1 2
                SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[gamemodes]\[ctv]"
                SetOverwrite ifnewer
                File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[gamemodes]\[ctv]\*.zip"
            SectionEnd
            Section "Deathmatch Gamemode"
            SectionIn 1 2
                SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[gamemodes]\[deathmatch]"
                SetOverwrite ifnewer
                File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[gamemodes]\[deathmatch]\*.zip"
            SectionEnd
            Section "Fallout Gamemode"
            SectionIn 1 2
                SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[gamemodes]\[fallout]"
                SetOverwrite ifnewer
                File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[gamemodes]\[fallout]\*.zip"
            SectionEnd
            Section "Hay Gamemode"
            SectionIn 1 2
                SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[gamemodes]\[hay]"
                SetOverwrite ifnewer
                File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[gamemodes]\[hay]\*.zip"
            SectionEnd
            Section "Race Gamemode"
            SectionIn 1 2
                SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[gamemodes]\[race]"
                SetOverwrite ifnewer
                File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[gamemodes]\[race]\*.zip"
            SectionEnd
            Section "Stealth Gamemode"
            SectionIn 1 2
                SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[gamemodes]\[stealth]"
                SetOverwrite ifnewer
                File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[gamemodes]\[stealth]\*.zip"
            SectionEnd
            Section "Team Deathmatch Arena Gamemode"
            SectionIn 1 2
                SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[gamemodes]\[tdm]"
                SetOverwrite ifnewer
                File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[gamemodes]\[tdm]\*.zip"
            SectionEnd
        SectionGroupEnd
    !endif
    
    !ifdef INCLUDE_EDITOR
        Section "$(INST_SEC_EDITOR)" SEC08
            SectionIn 1 2
            SetOutPath "$INSTDIR\server\mods\deathmatch\resources\[editor]"
            SetOverwrite ifnewer
            File /r "${SERVER_FILES_ROOT}\mods\deathmatch\resources\[editor]\*.zip"
        SectionEnd
    !endif

SectionGroupEnd

LangString INST_SEC_DEVELOPER ${LANG_ENGLISH}   "Development"
!ifdef INCLUDE_DEVELOPMENT
    SectionGroup /e "$(INST_SEC_DEVELOPER)" SECGDEV
        Section /o "Module SDK" SEC09
            SetOutPath "$INSTDIR\development\module SDK"
            SetOverwrite ifnewer
            File /r "${FILES_MODULE_SDK}\"
        SectionEnd
    SectionGroupEnd
!endif

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC10} $(DESC_Section10)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC11} $(DESC_Section11)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC12} $(DESC_Section12)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC13} $(DESC_Section13)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC_DIRECTX} $(DESC_DirectX)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC01} $(DESC_Section1)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC02} $(DESC_Section2)
    ;!insertmacro MUI_DESCRIPTION_TEXT ${SEC03} $(DESC_Section3)
    ;!insertmacro MUI_DESCRIPTION_TEXT ${SECGMODS} $(DESC_SectionGroupMods)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC04} $(DESC_Section4)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC05} $(DESC_Section5)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC06} $(DESC_Section6)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC07} $(DESC_Section7)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC08} $(DESC_Section8)
    !insertmacro MUI_DESCRIPTION_TEXT ${SEC09} $(DESC_Section9)
    ;!insertmacro MUI_DESCRIPTION_TEXT ${SECBLANK} $(DESC_Blank)
    !insertmacro MUI_DESCRIPTION_TEXT ${SECGSERVER} $(DESC_SectionGroupServer)
    !insertmacro MUI_DESCRIPTION_TEXT ${SECGDEV} $(DESC_SectionGroupDev)
    !insertmacro MUI_DESCRIPTION_TEXT ${SECGCLIENT} $(DESC_SectionGroupClient)
!insertmacro MUI_FUNCTION_DESCRIPTION_END


Section -Post
    ${LogText} "+Section begin - -Post"
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    ;WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\Multi Theft Auto.exe"

    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\Multi Theft Auto.exe"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
    ${LogText} "-Section end - -Post"
SectionEnd

LangString UNINST_SUCCESS ${LANG_ENGLISH}   "$(^Name) was successfully removed from your computer."
Function un.onUninstSuccess
    HideWindow
    MessageBox MB_ICONINFORMATION|MB_OK "$(UNINST_SUCCESS)"
    ;UAC::Unload ;Must call unload! ; #3017 fix
FunctionEnd

LangString UNINST_FAIL ${LANG_ENGLISH}  "Uninstallation has failed!"
Function un.OnUnInstFailed
    HideWindow
    MessageBox MB_ICONSTOP|MB_OK "$(UNINST_FAIL)"
    ;UAC::Unload ;Must call unload! ; #3017 fix
FunctionEnd

 
LangString UNINST_REQUEST ${LANG_ENGLISH}   "Are you sure you want to completely remove $(^Name) and all of its components?"
LangString UNINST_REQUEST_NOTE ${LANG_ENGLISH}  "Uninstalling before update?\
$\r$\nIt is not necessary to uninstall before installing a new version of MTA:SA\
$\r$\nRun the new installer to upgrade and preserve your settings."

Function un.onInit
    Call un.DoRightsElevation
    SetShellVarContext all
        MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "$(UNINST_REQUEST_NOTE)$\r$\n$\r$\n$\r$\n$(UNINST_REQUEST)" IDYES +2
        Abort
        
    !insertmacro MUI_UNGETLANGUAGE
FunctionEnd

LangString UNINST_DATA_REQUEST ${LANG_ENGLISH}  "Would you like to keep your data files (such as resources, screenshots and server configuration)? If you click no, any resources, configurations or screenshots you have created will be lost."
Section Uninstall
    IfFileExists "$INSTDIR\server\mods\deathmatch\resources\*.*" ask 0 ;no maps folder, so delete everything
    IfFileExists "$INSTDIR\screenshots\*.*" ask 0 ;no maps folder, so delete everything
    IfFileExists "$INSTDIR\mods\deathmatch\resources\*.*" ask deleteall ;no maps folder, so delete everything
    ask:
    MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "$(UNINST_DATA_REQUEST)" IDYES preservemapsfolder

    deleteall:
    Call un.DoServiceUninstall
    RmDir /r "$INSTDIR\mods"
    RmDir /r "$INSTDIR\MTA"

    RmDir /r "$INSTDIR\server"

    !ifdef INCLUDE_DEVELOPMENT ; start of fix for #3889
        RmDir /r "$INSTDIR\development\module sdk\publicsdk"
        RmDir "$INSTDIR\development\module sdk"
        RmDir "$INSTDIR\development"
    !endif ; end of fix for #3889

    preservemapsfolder:
    Call un.DoServiceUninstall
    ; server CORE FILES
    Delete "$INSTDIR\server\core.dll"
    Delete "$INSTDIR\server\xmll.dll"
    Delete "$INSTDIR\server\MTA Server.exe"
    Delete "$INSTDIR\server\net.dll"
    Delete "$INSTDIR\server\libcurl.dll"

    ; server files
    Delete "$INSTDIR\server\mods\deathmatch\deathmatch.dll"
    Delete "$INSTDIR\server\mods\deathmatch\lua5.1.dll"
    Delete "$INSTDIR\server\mods\deathmatch\pcre3.dll"
    Delete "$INSTDIR\server\mods\deathmatch\pthreadVC2.dll"
    Delete "$INSTDIR\server\mods\deathmatch\pthread.dll"
    Delete "$INSTDIR\server\mods\deathmatch\sqlite3.dll"
    Delete "$INSTDIR\server\mods\deathmatch\dbconmy.dll"
    Delete "$INSTDIR\server\mods\deathmatch\libmysql.dll"

    Delete "$INSTDIR\Multi Theft Auto.exe"
    Delete "$INSTDIR\Multi Theft Auto.exe.dat"
    Delete "$INSTDIR\Uninstall.exe"

    Delete "$INSTDIR\mods\deathmatch\Client.dll"
    Delete "$INSTDIR\mods\deathmatch\lua5.1c.dll"
    Delete "$INSTDIR\mods\deathmatch\pcre3.dll"

    RmDir /r "$INSTDIR\MTA\cgui"
    RmDir /r "$INSTDIR\MTA\data"
    RmDir /r "$INSTDIR\MTA\CEF"
    RmDir /r "$INSTDIR\MTA\locale"
    Delete "$INSTDIR\MTA\*.dll"
    Delete "$INSTDIR\MTA\*.exe"
    Delete "$INSTDIR\MTA\*.dmp"
    Delete "$INSTDIR\MTA\*.log"
    Delete "$INSTDIR\MTA\*.dat"
    Delete "$INSTDIR\MTA\*.bin"

    RmDir /r "$APPDATA\MTA San Andreas All\${0.0}"
    ; TODO if $APPDATA\MTA San Andreas All\Common is the only one left, delete it

    DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
    DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
    DeleteRegKey HKLM "SOFTWARE\Multi Theft Auto: San Andreas ${0.0}"
    DeleteRegKey HKCU "SOFTWARE\Multi Theft Auto: San Andreas ${0.0}"
    DeleteRegKey HKLM "SOFTWARE\Multi Theft Auto: San Andreas All\${0.0}"
    ; TODO if HKLM "SOFTWARE\Multi Theft Auto: San Andreas All\Common is the only one left, delete it
    
    ${GameExplorer_RemoveGame} ${GUID}
    
    ; Delete client shortcuts
    Delete "$SMPROGRAMS\\MTA San Andreas ${0.0}\MTA San Andreas.lnk"
    Delete "$SMPROGRAMS\\MTA San Andreas ${0.0}\Uninstall MTA San Andreas.lnk"
    Delete "$DESKTOP\MTA San Andreas ${0.0}.lnk"

    RmDir "$INSTDIR" ; fix for #3898

    ; Delete server shortcuts
    Delete "$SMPROGRAMS\\MTA San Andreas ${0.0}\MTA Server.lnk"
    Delete "$SMPROGRAMS\\MTA San Andreas ${0.0}\Uninstall MTA San Andreas Server.lnk"
    RmDir /r "$SMPROGRAMS\\MTA San Andreas ${0.0}"
    
    SetAutoClose true
SectionEnd

; Function that skips the game directory page if client is not selected
Function SkipDirectoryPage
    SectionGetFlags ${SEC01} $R0
    IntOp $R0 $R0 & ${SF_SELECTED}
    IntCmp $R0 ${SF_SELECTED} +2 0
    Abort
FunctionEnd


;====================================================================================
; Patcher related functions
;====================================================================================
Var PATCHFILE

LangString MSGBOX_PATCH_FAIL1 ${LANG_ENGLISH}   "Unable to download the patch file for your version of Grand Theft Auto: San Andreas"
LangString MSGBOX_PATCH_FAIL2 ${LANG_ENGLISH}   "Unable to install the patch file for your version of Grand Theft Auto: San Andreas"
Function InstallPatch
    ${LogText} "+Function begin - InstallPatch"
    DetailPrint "Incompatible version of San Andreas detected.  Patching executable..."
    StrCpy $PATCHFILE "$TEMP\$ExeMD5.GTASAPatch"
    NSISdl::download "http://mirror.multitheftauto.com/gdata/$ExeMD5.GTASAPatch" $PATCHFILE
    Pop $0
    ${If} $0 != "success"
        DetailPrint "* Download of patch file failed:"
        DetailPrint "* $0"
        DetailPrint "* Installation continuing anyway"
        MessageBox MB_ICONSTOP "$(MSGBOX_PATCH_FAIL1)"
        StrCpy $PatchInstalled "0"
    ${Else}
        DetailPrint "Patch download successful.  Installing patch..."
        vpatch::vpatchfile "$PATCHFILE" "$GTA_DIR\gta_sa.exe.bak" "$GTA_DIR\gta_sa.exe"
        Pop $R0
        ${If} $R0 == "OK"
            StrCpy $PatchInstalled "1"
        ${ElseIf} $R0 == "OK, new version already installed"
            StrCpy $PatchInstalled "1"
        ${Else}
            StrCpy $PatchInstalled "0"
            DetailPrint "* Some error occured installing the patch for Grand Theft Auto: San Andreas:"
            DetailPrint "* $R0"
            DetailPrint "* It is required in order to run Multi Theft Auto : San Andreas"
            DetailPrint "* Installation continuing anyway"
            MessageBox MB_ICONSTOP MSGBOX_PATCH_FAIL2
        ${EndIf}
    ${EndIf}
    ${LogText} "-Function end - InstallPatch"
FunctionEnd

;====================================================================================
; UAC related functions
;====================================================================================
LangString UAC_RIGHTS1 ${LANG_ENGLISH}  "This installer requires admin access, try again"
LangString UAC_RIGHTS_UN ${LANG_ENGLISH}    "This uninstaller requires admin access, try again"
LangString UAC_RIGHTS3 ${LANG_ENGLISH}  "Logon service not running, aborting!"
LangString UAC_RIGHTS4 ${LANG_ENGLISH}  "Unable to elevate"
!macro RightsElevation AdminError
    uac_tryagain:
    !insertmacro UAC_RunElevated
    #MessageBox mb_TopMost "0=$0 1=$1 2=$2 3=$3"
    ${Switch} $0
        ${Case} 0
            ${IfThen} $1 = 1 ${|} Quit ${|}         ; we are the outer process, the inner process has done its work, we are done
            ${IfThen} $3 <> 0 ${|} ${Break} ${|}    ; we are admin, let the show go on
            ${If} $1 = 3                            ; RunAs completed successfully, but with a non-admin user
                MessageBox mb_IconExclamation|mb_TopMost|mb_SetForeground "${AdminError}" /SD IDNO IDOK uac_tryagain IDNO 0
            ${EndIf}
            ;fall-through and die
        ${Case} 1223
            MessageBox mb_IconStop|mb_TopMost|mb_SetForeground "${AdminError}"
            Quit
        ${Case} 1062
            MessageBox mb_IconStop|mb_TopMost|mb_SetForeground "$(UAC_RIGHTS3)"
            Quit
        ${Default}
            MessageBox mb_IconStop|mb_TopMost|mb_SetForeground "$(UAC_RIGHTS4), error $0"
            Quit
    ${EndSwitch}
!macroend

Function DoRightsElevation
    ${LogText} "+Function begin - RightsElevation"
    !insertmacro RightsElevation "$(UAC_RIGHTS1)"
    ${LogText} "-Function end - RightsElevation"
FunctionEnd

Function un.DoRightsElevation
    !insertmacro RightsElevation "$(UAC_RIGHTS_UN)"
FunctionEnd


;****************************************************************
;
; Functions relating to the resizing of the 'Components' dialog.
;
;****************************************************************

Var HWND
Var RECT_X
Var RECT_Y
Var RECT_W
Var RECT_H

; In: $HWND $RECT_X $RECT_Y
; Out: $RECT_X $RECT_Y
Function ScreenToClient
    ;Save existing register values to the stack
    Push $1
    Push $2
    Push $3

    ; Allocate a 2 int struct in $1
    System::Call "*(i $RECT_X, i $RECT_Y) i.r1"
    ${If} $1 == 0
        DetailPrint "Memory problem"
    ${Else}
        ; Call ScreenToClient
        System::Call "User32::ScreenToClient(i, i) i ($HWND, r1r1) .r5"
        System::Call "*$1(i .r2, i .r3)"

        ; Set return values
        StrCpy $RECT_X $2
        StrCpy $RECT_Y $3

        ; Free 2 int struct
        System::Free $1
    ${EndIf}
    
    ;Restore register values from the stack
    Pop $3
    Pop $2
    Pop $1
    
FunctionEnd


; In: $HWND
; Out: $RECT_X $RECT_Y $RECT_W $RECT_D
Function GetWindowRect
    ;Save existing register values to the stack
    Push $1
    Push $2
    Push $3
    Push $4
    Push $5

    ; Allocate a 4 int struct in $1
    System::Call "*(i 0, i 0, i 0, i 0) i.r1"
    ${If} $1 == 0
        DetailPrint "Memory problem"
    ${Else}
        ; Call GetWindowRect
        System::Call "User32::GetWindowRect(i, i) i ($HWND, r1) .r5"
        System::Call "*$1(i .r2, i .r3, i .r4, i .r5)"

        ; Set return values
        StrCpy $RECT_X $2
        StrCpy $RECT_Y $3
        IntOp $RECT_W $4 - $2
        IntOp $RECT_H $5 - $3

        ; Free 4 int struct
        System::Free $1
    ${EndIf}
    
    ;Restore register values from the stack
    Pop $5
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    
FunctionEnd


; In: $HWND
; Out: $RECT_X $RECT_Y $RECT_W $RECT_D
Function GetChildRect
    ;Save existing register values to the stack
    Push $1

    Call GetWindowRect

    System::Call "User32::GetParent(i) i ($HWND) .r1"
    StrCpy $HWND $1

    Call ScreenToClient

    ;Restore register values from the stack
    Pop $1
FunctionEnd


Var ITEM_HWND
Var ITEM_PARENT
Var ITEM_ID
Var X
Var Y
Var CX
Var CY

; Input:
;   $ITEM_PARENT - Parent window
;   $ITEM_ID     - Dialog ID
;   $X $Y        - Position change
;   $CX $CY      - Size change
Function MoveDialogItem
    ;Save existing register values to the stack
    Push $1
    Push $2
    Push $3
    Push $4

    ; Get item handle
    GetDlgItem $ITEM_HWND $ITEM_PARENT $ITEM_ID

    StrCpy $HWND $ITEM_HWND
    Call GetChildRect
    
    ; Calculate new dims
    IntOp $1 $RECT_X + $X
    IntOp $2 $RECT_Y + $Y
    IntOp $3 $RECT_W + $CX
    IntOp $4 $RECT_H + $CY 
    
    ; Set new dims
    System::Call "User32::MoveWindow(i, i, i, i, i, b) b ($ITEM_HWND, $1, $2, $3, $4, true)"

    ;Restore register values from the stack
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    
FunctionEnd


Var HWND_DIALOG
Var RESIZE_X
Var RESIZE_Y


Function HideBackButton
    GetDlgItem $ITEM_HWND $HWNDPARENT 3
    ShowWindow $ITEM_HWND ${SW_HIDE}
FunctionEnd


; Input:
;   $RESIZE_X $RESIZE_Y     - Resize amount
Function ResizeComponentsDialogContents

    FindWindow $HWND_DIALOG "#32770" "" $HWNDPARENT

    ;Move description right and stretch down
    StrCpy $X $RESIZE_X
    StrCpy $Y 0
    StrCpy $CX 0
    StrCpy $CY $RESIZE_Y
    ${If} "$(LANGUAGE_RTL)" == "1"
        StrCpy $X 0
    ${EndIf}

    StrCpy $ITEM_PARENT $HWND_DIALOG
    StrCpy $ITEM_ID 1043    ; Static - "Position your mouse over a component to see its description."
    Call MoveDialogItem
    
    StrCpy $ITEM_PARENT $HWND_DIALOG
    StrCpy $ITEM_ID 1042    ; Button - Description
    Call MoveDialogItem
    
    ${If} "$(LANGUAGE_RTL)" == "1"
        StrCpy $X $RESIZE_X
        StrCpy $Y 0
        StrCpy $CX 0
        StrCpy $CY 0

        StrCpy $ITEM_PARENT $HWND_DIALOG
        StrCpy $ITEM_ID 1021    ; Static - "Select the type of install."
        Call MoveDialogItem

        StrCpy $ITEM_PARENT $HWND_DIALOG
        StrCpy $ITEM_ID 1022    ; Static - "Or, select the optional components you wish to install."
        Call MoveDialogItem

        StrCpy $ITEM_PARENT $HWND_DIALOG
        StrCpy $ITEM_ID 1023    ; Static - "Space required: XX MB."
        Call MoveDialogItem
    ${EndIf}

    ;Middle zone bigger
    StrCpy $X 0
    StrCpy $Y 0
    StrCpy $CX $RESIZE_X
    StrCpy $CY $RESIZE_Y
    StrCpy $ITEM_PARENT $HWNDPARENT
    StrCpy $ITEM_ID 0       ; Sub dialog
    Call MoveDialogItem

    ;Make tree view bigger
    StrCpy $X 0
    StrCpy $Y 0
    StrCpy $CX $RESIZE_X
    StrCpy $CY $RESIZE_Y
    StrCpy $ITEM_PARENT $HWND_DIALOG
    StrCpy $ITEM_ID 1032    ; Tree view
    Call MoveDialogItem
    
    ;Stretch combo box to the right
    StrCpy $X 0
    StrCpy $Y 0
    StrCpy $CX $RESIZE_X
    StrCpy $CY 0
    
    StrCpy $ITEM_PARENT $HWND_DIALOG
    StrCpy $ITEM_ID 1017    ; Combo box
    Call MoveDialogItem
    
    ;Move space required text down
    StrCpy $X 0
    StrCpy $Y $RESIZE_Y
    StrCpy $CX 0
    StrCpy $CY 0
    
    StrCpy $ITEM_PARENT $HWND_DIALOG
    StrCpy $ITEM_ID 1023    ; Static
    Call MoveDialogItem

FunctionEnd


; Input:
;   $RESIZE_X $RESIZE_X     - Resize amount
Function ResizeSharedDialogContents

    ;Move buttons down and right
    StrCpy $X $RESIZE_X
    StrCpy $Y $RESIZE_Y
    StrCpy $CX 0
    StrCpy $CY 0

    StrCpy $ITEM_PARENT $HWNDPARENT
    StrCpy $ITEM_ID 1   ; Button - Next
    Call MoveDialogItem

    StrCpy $ITEM_PARENT $HWNDPARENT
    StrCpy $ITEM_ID 2   ; Button - Cancel
    Call MoveDialogItem

    StrCpy $ITEM_PARENT $HWNDPARENT
    StrCpy $ITEM_ID 3 ; Button - Back
    Call MoveDialogItem
    
    ;Move branding text down
    StrCpy $X 0
    StrCpy $Y $RESIZE_Y
    StrCpy $CX 0
    StrCpy $CY 0
    
    StrCpy $ITEM_PARENT $HWNDPARENT
    StrCpy $ITEM_ID 1256    ; Static - "Nullsoft Install System..."
    Call MoveDialogItem

    StrCpy $ITEM_PARENT $HWNDPARENT
    StrCpy $ITEM_ID 1028    ; Static - "Nullsoft Install System..."
    Call MoveDialogItem

    ;Move lower horizontal line down and stretch to the right
    StrCpy $X 0
    StrCpy $Y $RESIZE_Y
    StrCpy $CX $RESIZE_X
    StrCpy $CY 0
    StrCpy $ITEM_PARENT $HWNDPARENT
    StrCpy $ITEM_ID 1035    ; Static - Line
    Call MoveDialogItem

    ;Stretch header to the right
    StrCpy $X 0
    StrCpy $Y 0
    StrCpy $CX $RESIZE_X
    StrCpy $CY 0
    StrCpy $ITEM_PARENT $HWNDPARENT
    StrCpy $ITEM_ID 1034    ; Static - White bar
    Call MoveDialogItem

    StrCpy $ITEM_PARENT $HWNDPARENT
    StrCpy $ITEM_ID 1036    ; Static - Line
    Call MoveDialogItem
    
    ;Move header text to the right
    StrCpy $X $RESIZE_X
    StrCpy $Y 0
    StrCpy $CX 0
    StrCpy $CY 0
    StrCpy $ITEM_PARENT $HWNDPARENT
    StrCpy $ITEM_ID 1037    ; Static - "Choose Components"
    Call MoveDialogItem

    StrCpy $ITEM_PARENT $HWNDPARENT
    StrCpy $ITEM_ID 1038    ; Static - "Choose which features of MTA:SA v1.0 you want to install."
    Call MoveDialogItem
    
    ${If} "$(LANGUAGE_RTL)" == "1"
        ;Move image to the right most end if RTL
        StrCpy $X $RESIZE_X
        StrCpy $Y 0
        StrCpy $CX 0
        StrCpy $CY 0

        StrCpy $ITEM_PARENT $HWNDPARENT
        StrCpy $ITEM_ID 1046    ; Static - mta_install_header_rtl.bmp
        Call MoveDialogItem
    ${EndIf}
    
FunctionEnd


!define SWP_NOOWNERZORDER       0x0200

; Input:
;   $RESIZE_X $RESIZE_X     - Resize amount
Function ResizeMainWindow
    ;Save existing register values to the stack
    Push $0
    Push $1
    Push $2
    Push $3
    Push $4
 
    StrCpy $HWND $HWNDPARENT
    Call GetWindowRect

    IntOp $0 $RESIZE_X / 2
    IntOp $1 $RECT_X - $0
    
    IntOp $0 $RESIZE_Y / 2
    IntOp $2 $RECT_Y - $0
    
    IntOp $3 $RECT_W + $RESIZE_X
    IntOp $4 $RECT_H + $RESIZE_Y

    System::Call "User32::SetWindowPos(i, i, i, i, i, i, i) b ($HWNDPARENT, 0, $1, $2, $3, $4, ${SWP_NOOWNERZORDER})"

    ;Restore register values from the stack
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0

FunctionEnd


Var COMPONENTS_EXPAND_STATUS

Function "WelcomePreProc"
    ${LogText} "+Function begin - WelcomePreProc"
    !insertmacro UAC_IsInnerInstance
    ${If} ${UAC_IsInnerInstance} 
        ; If switched to admin, don't show welcome window again
        ${LogText} "-Function end - WelcomePreProc (IsInnerInstance)"
        Abort
    ${EndIf}
    ${LogText} "-Function end - WelcomePreProc"
FunctionEnd

Function "WelcomeShowProc"
    ${LogText} "+Function begin - WelcomeShowProc"
    BringToFront
    ${LogText} "-Function end - WelcomeShowProc"
FunctionEnd

Function "WelcomeLeaveProc"
    ${LogText} "+Function begin - WelcomeLeaveProc"
    HideWindow
    ; Maybe switch to admin after welcome window
    Call DoRightsElevation
    ShowWindow $HWNDPARENT ${SW_SHOW}
    ${LogText} "-Function end - WelcomeLeaveProc"
FunctionEnd


Function "LicenseShowProc"
    ${LogText} "+Function begin - LicenseShowProc"
    Call UnexpandComponentsPage
    Call HideBackButton
    BringToFront
    ${LogText} "-Function end - LicenseShowProc"
FunctionEnd

Function "LicenseLeaveProc"
    ${LogText} "+Function begin - LicenseLeaveProc"
    ${LogText} "-Function end - LicenseLeaveProc"
FunctionEnd


Function "ComponentsShowProc"
    ${LogText} "+Function begin - ComponentsShowProc"
    Call ExpandComponentsPage
    ${LogText} "-Function end - ComponentsShowProc"
FunctionEnd

Function "ComponentsLeaveProc"
    ${LogText} "+Function begin - ComponentsLeaveProc"
    ${LogText} "-Function end - ComponentsLeaveProc"
FunctionEnd


Function "ExpandComponentsPage"
    ${LogText} "+Function begin - ExpandComponentsPage"
    ${If} $COMPONENTS_EXPAND_STATUS != 1
        ${LogText} "Doing expand"
        StrCpy $COMPONENTS_EXPAND_STATUS 1
        IntOp $RESIZE_X 0 + ${EXPAND_DIALOG_X}
        IntOp $RESIZE_Y 0 + ${EXPAND_DIALOG_Y}
        Call ResizeComponentsDialogContents
        Call ResizeSharedDialogContents
        Call ResizeMainWindow
    ${Endif}
    ${LogText} "-Function end - ExpandComponentsPage"
FunctionEnd

Function "UnexpandComponentsPage"
    ${LogText} "+Function begin - UnexpandComponentsPage"
    ${If} $COMPONENTS_EXPAND_STATUS == 1
        ${LogText} "Doing unexpand"
        StrCpy $COMPONENTS_EXPAND_STATUS 0
        IntOp $RESIZE_X 0 - ${EXPAND_DIALOG_X}
        IntOp $RESIZE_Y 0 - ${EXPAND_DIALOG_Y}
        Call ResizeSharedDialogContents
        Call ResizeMainWindow
    ${Endif}
    ${LogText} "-Function end - UnexpandComponentsPage"
FunctionEnd


;****************************************************************
;
; Remove virtual store version of path
;
;****************************************************************
; In $0 = install path
Function RemoveVirtualStore
    StrCpy $2 $0 "" 3     # Skip first 3 chars
    StrCpy $3 "$LOCALAPPDATA\VirtualStore\$2"
    StrCpy $4 "$0\FromVirtualStore"
    IfFileExists $3 0 NoVirtualStore
        ${LogText} "Moving VirtualStore files from $3 to $4"
        CopyFiles $3\*.* $4
        RmDir /r "$3"
        Goto done
    NoVirtualStore:
        ${LogText} "NoVirtualStore detected at $3"
    done:
FunctionEnd


;****************************************************************
;
; Returns 1 if file exists and is 32 bit.
;
;****************************************************************
Function IsDll32Bit
    Pop $3
    StrCpy $2 ""
    ClearErrors
    FileOpen $0 $3 r
    IfErrors done
    FileSeek $0 60    ;   IMAGE_DOS_HEADER->e_lfanew
    FileReadWord $0 $1
    FileSeek $0 $1    ;   IMAGE_NT_HEADERS
    FileSeek $0 4 CUR ;   IMAGE_FILE_HEADER->Machine
    FileReadWord $0 $2  ; $2 = Machine
    FileClose $0
done:
    StrCpy $1 "0"
    ${If} $2 == 332     ; 0x014c IMAGE_FILE_MACHINE_I386
        StrCpy $1 "1"
    ${EndIf}
    ${LogText} "IsDll32Bit($3) result:$1"
    Push $1
FunctionEnd


;****************************************************************
;
; Determine if install/upgrade  this version/previous version
;
;****************************************************************

; In <stack> = install path
; Out <stack> = "new" - New install
;          "upgrade" - In place copy with same Major.Minor
;          "overwrite" - In place copy different Major.Minor
;     <stack> = "Maj.Min"
Function GetInstallType
    ${LogText} "+Function begin - GetInstallType"
    Pop $0
    Push $0
    Call GetVersionAtLocation
    StrCpy $1 $0 3  # First 3 chars

    ${If} $1 == "0.0"
        StrCpy $2 "new"
    ${ElseIf} $1 == ${0.0}
        StrCpy $2 "upgrade"
    ${Else}
        StrCpy $2 "overwrite"
    ${EndIf}
    Pop $0
    ${LogText} "GetInstallType($0) result:$1,$2"
    Push $1
    Push $2
    ${LogText} "-Function end - GetInstallType"
FunctionEnd


; In $0 = install path
; Out $0 = "1.1.0.3306"
;          "0.0.0.0" if no file
Function GetVersionAtLocation
    ; Check installed version at this location
    StrCpy $5 "$0\MTA\core.dll"

    ClearErrors
    GetDLLVersion $5 $R0 $R1
    IfErrors 0 cont
        IntOp $R0 0 + 0x00000000
        IntOp $R1 0 + 0x00000000
        IfFileExists $5 cont
            IntOp $R0 0 + 0x00000000
            IntOp $R1 0 + 0x00000000
    cont:
    IntOp $R2 $R0 >> 16
    IntOp $R2 $R2 & 0x0000FFFF ; $R2 now contains major version
    IntOp $R3 $R0 & 0x0000FFFF ; $R3 now contains minor version
    IntOp $R4 $R1 >> 16
    IntOp $R4 $R4 & 0x0000FFFF ; $R4 now contains release
    IntOp $R5 $R1 & 0x0000FFFF ; $R5 now contains build
    StrCpy $0 "$R2.$R3.$R4.$R5" ; $0 now contains string like "1.2.0.192"
FunctionEnd


LangString INST_MTA_CONFLICT ${LANG_ENGLISH}    "A different major version of MTA ($1) already exists at that path.$\n$\n\ 
            MTA is designed for major versions to be installed in different paths.$\n \
            Are you sure you want to overwrite MTA $1 at \
            $INSTDIR ?"
LangString INST_GTA_CONFLICT ${LANG_ENGLISH}    "MTA cannot be installed into the same directory as GTA:SA.$\n$\n\ 
            Do you want to use the default install directory$\n\
            $DEFAULT_INSTDIR ?"
LangString INST_GTA_ERROR1 ${LANG_ENGLISH} "The selected directory does not exist.$\n$\n\
            Please select the GTA:SA install directory"
LangString INST_GTA_ERROR2 ${LANG_ENGLISH} "Could not find GTA:SA installed at $GTA_DIR $\n$\n\
            Are you sure you want to continue ?"
            
Function "CustomDirectoryPageLeave"
    ${LogText} "+Function begin - CustomDirectoryPageLeave"
    Call CustomDirectoryPageUpdateINSTDIR

    # Check if user is trying to install MTA into GTA directory
    Push $INSTDIR 
    Call IsGtaDirectory
    Pop $0
    ${If} $0 == "gta"

        # Don't allow install into GTA directory unless MTA is already there
        Push $INSTDIR 
        Call GetInstallType
        Pop $0
        Pop $1
        ${If} $0 != "upgrade"
            MessageBox MB_OKCANCEL|MB_ICONQUESTION|MB_TOPMOST|MB_SETFOREGROUND \
                "$(INST_GTA_CONFLICT)" \
                IDOK cont2
                ${LogText} "-Function end - CustomDirectoryPageLeave (GTA_CONFLICT)"
                Abort
            cont2:
            StrCpy $INSTDIR $DEFAULT_INSTDIR
        ${Endif}
    ${Endif}

    # Check if user is trying to install over a different major version of MTA
    Push $INSTDIR 
    Call GetInstallType
    Pop $0
    Pop $1
    ${If} $0 == "overwrite"
        MessageBox MB_OKCANCEL|MB_ICONQUESTION|MB_TOPMOST|MB_SETFOREGROUND \
            "$(INST_MTA_CONFLICT)" \
            IDOK cont
            ${LogText} "-Function end - CustomDirectoryPageLeave (MTA_CONFLICT)"
            Abort
        cont:
    ${Endif}
    ${LogText} "-Function end - CustomDirectoryPageLeave"
FunctionEnd


Function "GTADirectoryLeaveProc"
    ${LogText} "+Function begin - GTADirectoryLeaveProc"

    ; Directory must exist
    IfFileExists "$GTA_DIR\*.*" hasdir
        MessageBox MB_ICONEXCLAMATION|MB_TOPMOST|MB_SETFOREGROUND \
            "$(INST_GTA_ERROR1)"
            ${LogText} "-Function end - GTADirectoryLeaveProc (GTA_ERROR1)"
            Abort
    hasdir:

    ; data subdirectory should exist
    IfFileExists "$GTA_DIR\data\*.*" cont
        MessageBox MB_OKCANCEL|MB_ICONQUESTION|MB_TOPMOST|MB_SETFOREGROUND \
            "$(INST_GTA_ERROR2)" \
            IDOK cont1
            ${LogText} "-Function end - GTADirectoryLeaveProc (GTA_ERROR2)"
            Abort
        cont1:
    cont:
    ${LogText} "-Function end - GTADirectoryLeaveProc"
FunctionEnd

;****************************************************************
;
; Determine if gta is installed at supplied directory path
;
;****************************************************************

; In <stack> = directory path
; Out <stack> = "" - gta not detected at path
;               "gta" - gta detected at path
Function IsGtaDirectory
    Pop $0
    StrCpy $1 "gta"

    ; gta_sa.exe or gta-sa.exe should exist
    IfFileExists "$0\gta_sa.exe" cont1
        IfFileExists "$0\gta-sa.exe" cont1
            IfFileExists "$0\Grand Theft Auto San Andreas.exe" cont1
                StrCpy $1 ""
    cont1:

    ; data subdirectory should exist
    IfFileExists "$0\data\*.*" cont2
        StrCpy $1 ""
    cont2:

    Push $1
FunctionEnd

;****************************************************************
;
; Custom MTA directory page
;
; To make sure the directory exists when 'Browse...' is clicked
;
;****************************************************************
Var Dialog
Var UpgradeLabel
Var BrowseButton
Var SetDefaultButton
Var DirRequest
Var RadioDefault
Var LabelDefault
Var RadioLastUsed
Var LabelLastUsed
Var RadioCustom
Var Length
Var SizeX
Var SizeY
Var PosX
Var PosY
!define LT_GREY "0xf0f0f0"
!define MID_GREY "0xb0b0b0"
!define BLACK "0x000000"
!define MID_GREY2K "0x808080"
!define LT_GREY2K "0xD1CEC9"

LangString INST_CHOOSE_LOC_TOP ${LANG_ENGLISH}  "Choose Install Location"
LangString INST_CHOOSE_LOC ${LANG_ENGLISH}  "Choose the folder in which to install ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION}"
LangString INST_CHOOSE_LOC2 ${LANG_ENGLISH} "${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} will be installed in the following folder.$\n\
To install in a different folder, click Browse and select another folder.$\n$\n Click Next to continue."
LangString INST_CHOOSE_LOC3 ${LANG_ENGLISH} "Destination Folder"
LangString INST_CHOOSE_LOC_BROWSE ${LANG_ENGLISH}   "Browse..."
LangString INST_CHOOSE_LOC_DEFAULT ${LANG_ENGLISH} "Default"
LangString INST_CHOOSE_LOC_LAST_USED ${LANG_ENGLISH} "Last used"
LangString INST_CHOOSE_LOC_CUSTOM ${LANG_ENGLISH} "Custom"
Function CustomDirectoryPage
    ${LogText} "+Function begin - CustomDirectoryPage"

    nsDialogs::Create 1018
    Pop $Dialog
    ${If} $Dialog == error
        ${LogText} "-Function end - CustomDirectoryPage (error)"
        Abort
    ${EndIf}
    ${LogText} "nsDialogs::Create success"

    GetDlgItem $0 $HWNDPARENT 1037
    ${NSD_SetText} $0 "$(INST_CHOOSE_LOC)"
    GetDlgItem $0 $HWNDPARENT 1038
    ${NSD_SetText} $0 "$(INST_CHOOSE_LOC)"

    ${NSD_CreateLabel} 0 0 100% 50u "$(INST_CHOOSE_LOC2)"
    Pop $0
    ${LogText} "Did CreateLabel"

    # Calculate size and position of install dir options
    IntOp $SizeY 27 + 90    # 27 + 30 + 30 + 30
    ${If} $ShowLastUsed == "0"
        IntOp $SizeY $SizeY - 30
    ${EndIf}
    IntOp $PosY 187 - $SizeY

    # Add group box
    ${NSD_CreateGroupBox} 0 $PosY 100% $SizeY "$(INST_CHOOSE_LOC3)"
    Pop $0
    IntOp $PosY $PosY + 24
    
    # Pick the longest string and use that as SizeX
    !insertmacro GetTextExtent "$(INST_CHOOSE_LOC_DEFAULT)" $SizeX
    !insertmacro GetTextExtent "$(INST_CHOOSE_LOC_LAST_USED)" $Length
    !insertmacro Max $SizeX $Length
    !insertmacro GetTextExtent "$(INST_CHOOSE_LOC_CUSTOM)" $Length
    !insertmacro Max $SizeX $Length
    
    IntOp $SizeX $SizeX + 6 # Take into account the radio button itself
    IntOp $PosX $SizeX + 20 # Take into account the x padding of 10, plus spacing of 15
    IntOp $Length ${DIALOG_X} - $PosX # [Total width] - [radio button width]
    IntOp $Length $Length - 10 # [Total width] - [radio button width] - [padding]
    # Add default option
    ${NSD_CreateRadioButton} 10 $PosY $SizeX 12u "$(INST_CHOOSE_LOC_DEFAULT)"
    Pop $RadioDefault
    ${NSD_CreateText} $PosX $PosY $Length 12u $DEFAULT_INSTDIR
    Pop $LabelDefault
    SendMessage $LabelDefault ${EM_SETREADONLY} 1 0
    ${LogText} "Did SendMessage"
    IntOp $PosY $PosY + 30

    # Add last used option
    ${If} $ShowLastUsed != "0"
        ${NSD_CreateRadioButton} 10 $PosY $SizeX 12u "$(INST_CHOOSE_LOC_LAST_USED)"
        Pop $RadioLastUsed
        ${NSD_CreateText} $PosX $PosY $Length 12u $LAST_INSTDIR
        Pop $LabelLastUsed
        SendMessage $LabelLastUsed ${EM_SETREADONLY} 1 0
        IntOp $PosY $PosY + 30
    ${EndIf}

    # Add custom option
    ${NSD_CreateRadioButton} 10 $PosY $SizeX 12u "$(INST_CHOOSE_LOC_CUSTOM)"
    Pop $RadioCustom
    
    !insertmacro GetTextExtent "$(INST_CHOOSE_LOC_BROWSE)" $R9
    IntOp $R9 $R9 + 5 # Add spacing for the button on top of text
    IntOp $Length $Length - $R9
    ${NSD_CreateDirRequest} $PosX $PosY $Length 12u $CUSTOM_INSTDIR
    Pop $DirRequest
    IntOp $PosY $PosY - 1
    IntOp $PosX ${DIALOG_X} - $R9
    IntOp $PosX $PosX - 10
    ${NSD_CreateBrowseButton} $PosX $PosY $R9 13u "$(INST_CHOOSE_LOC_BROWSE)"
    Pop $BrowseButton
    IntOp $PosY $PosY + 31

    ${NSD_OnClick} $RadioDefault CustomDirectoryPageRadioClick
    ${NSD_OnClick} $RadioLastUsed CustomDirectoryPageRadioClick
    ${NSD_OnClick} $RadioCustom CustomDirectoryPageRadioClick
    ${NSD_OnClick} $BrowseButton CustomDirectoryPageBrowseButtonClick
    ${NSD_OnClick} $SetDefaultButton CustomDirectoryPageSetDefaultButtonClick
    ${NSD_OnChange} $DirRequest CustomDirectoryPageDirRequestChange
    ${LogText} "Did Ons"

    # Install type message
    ${NSD_CreateLabel} 0 203 100% 12u ""
    Pop $UpgradeLabel
    Call CustomDirectoryPageSetUpgradeMessage

    Call CustomDirectoryPageShowWhichRadio

    Call UnexpandComponentsPage
    nsDialogs::Show
    ${LogText} "-Function end - CustomDirectoryPage"
FunctionEnd

# Called when radion button is clicked
Function CustomDirectoryPageRadioClick
    Pop $0
    ${Switch} $0
        ${Case} $RadioDefault
            StrCpy $WhichRadio "default"
            ${Break}
        ${Case} $RadioLastUsed
            StrCpy $WhichRadio "last"
            ${Break}
        ${Case} $RadioCustom
            StrCpy $WhichRadio "custom"
            ${Break}
    ${EndSwitch}
    Call CustomDirectoryPageShowWhichRadio
FunctionEnd

# Ensure GUI reflects $WhichRadio
Function CustomDirectoryPageShowWhichRadio
    # Set all options as not selected
    Call IsWindowsClassicTheme
    Pop $0
    ${If} $0 == 1
        SetCtlColors $LabelDefault ${MID_GREY2K} ${LT_GREY2K}
        SetCtlColors $LabelLastUsed ${MID_GREY2K} ${LT_GREY2K}
        SetCtlColors $DirRequest ${MID_GREY2K} ${LT_GREY2K}
    ${Else}
        SetCtlColors $LabelDefault ${MID_GREY} ${LT_GREY}
        SetCtlColors $LabelLastUsed ${MID_GREY} ${LT_GREY}
        SetCtlColors $DirRequest ${MID_GREY} ${LT_GREY}
    ${EndIf}

    SendMessage $DirRequest ${EM_SETREADONLY} 1 0
    EnableWindow $BrowseButton 0

    # Highlight selected option
    ${Switch} $WhichRadio
        ${Case} "default"
            StrCpy $INSTDIR $DEFAULT_INSTDIR
            ${NSD_SetState} $RadioDefault ${BST_CHECKED}
            SetCtlColors $LabelDefault ${BLACK}
            ${Break}
        ${Case} "last"
            StrCpy $INSTDIR $LAST_INSTDIR
            ${NSD_SetState} $RadioLastUsed ${BST_CHECKED}
            SetCtlColors $LabelLastUsed ${BLACK}
            ${Break}
        ${Case} "custom"
            StrCpy $INSTDIR $CUSTOM_INSTDIR
            ${NSD_SetState} $RadioCustom ${BST_CHECKED}
            SetCtlColors $DirRequest ${BLACK}
            SendMessage $DirRequest ${EM_SETREADONLY} 0 0
            EnableWindow $BrowseButton 1
            ${Break}
    ${EndSwitch}

    # Redraw controls
    ${NSD_GetText} $LabelDefault $0
    ${NSD_SetText} $LabelDefault $0
    ${NSD_GetText} $LabelLastUsed $0
    ${NSD_SetText} $LabelLastUsed $0
    ${NSD_GetText} $DirRequest $0
    ${NSD_SetText} $DirRequest $0
FunctionEnd

Function CustomDirectoryPageDirRequestChange
    ${NSD_GetText} $DirRequest $0
    ${If} $0 != error
        StrCpy $CUSTOM_INSTDIR $0
        Call CustomDirectoryPageSetUpgradeMessage
    ${EndIf}
FunctionEnd

Function CustomDirectoryPageSetDefaultButtonClick
    StrCpy $INSTDIR "$PROGRAMFILES\MTA San Andreas ${0.0}"
    ${NSD_SetText} $DirRequest $INSTDIR
    Call CustomDirectoryPageSetUpgradeMessage
FunctionEnd

LangString INST_CHOOSE_LOC4 ${LANG_ENGLISH} "Select the folder to install ${PRODUCT_NAME_NO_VER} ${PRODUCT_VERSION} in:"

Function CustomDirectoryPageBrowseButtonClick
    ${NSD_GetText} $DirRequest $0

    Call CreateDirectoryAndRememberWhichOnesWeDid
    nsDialogs::SelectFolderDialog "$(INST_CHOOSE_LOC4)" $0
    Pop $0

    Call RemoveDirectoriesWhichWeDid

    ${If} $0 != error
        StrCpy $CUSTOM_INSTDIR $0
        ${NSD_SetText} $DirRequest $0
        Call CustomDirectoryPageSetUpgradeMessage
    ${EndIf}
FunctionEnd

LangString INST_LOC_OW ${LANG_ENGLISH}  "Warning: A different major version of MTA ($1) already exists at that path."
LangString INST_LOC_UPGRADE ${LANG_ENGLISH} "Installation type:  Upgrade"
Function CustomDirectoryPageSetUpgradeMessage
    Call CustomDirectoryPageUpdateINSTDIR
    Push $INSTDIR 
    Call GetInstallType
    Pop $0
    Pop $1

    ${NSD_SetText} $UpgradeLabel ""
    ${If} $0 == "overwrite"
        ${NSD_SetText} $UpgradeLabel "$(INST_LOC_OW)"
    ${Endif}
    ${If} $0 == "upgrade"
        ${NSD_SetText} $UpgradeLabel "$(INST_LOC_UPGRADE)"
    ${Endif}
FunctionEnd

# Make absolutely sure $INSTDIR is correct
Function CustomDirectoryPageUpdateINSTDIR
    ${Switch} $WhichRadio
        ${Case} "default"
            StrCpy $INSTDIR $DEFAULT_INSTDIR
            ${Break}
        ${Case} "last"
            StrCpy $INSTDIR $LAST_INSTDIR
            ${Break}
        ${Case} "custom"
            StrCpy $INSTDIR $CUSTOM_INSTDIR
            ${Break}
    ${EndSwitch}
FunctionEnd

Function IsWindowsClassicTheme
; Out <stack> = "1" - Is Windows Classic
    System::Call "UxTheme::IsThemeActive() i .r3"
    StrCpy $1 "1"
    ${If} $3 == 1
        StrCpy $1 "0"
    ${EndIf}
    Push $1
FunctionEnd

;****************************************************************
;
; Keep track of temp directories created
;
;****************************************************************
Var SAVED_PATH_TO
Var SAVED_CREATE_DEPTH

; In $0 = path
Function CreateDirectoryAndRememberWhichOnesWeDid
    Push $0
    Push $1
    Push $2
    Push $8
    StrCpy $8 $0

    StrCpy $0 $8
    Call HowManyDepthsNotExist

    StrCpy $SAVED_PATH_TO $8
    StrCpy $SAVED_CREATE_DEPTH $2

    #MessageBox mb_TopMost "CreateDirectoryAndRememberWhichOnesWeDid $\n\
    #        path-to=$SAVED_PATH_TO $\n\
    #        create-depth=$SAVED_CREATE_DEPTH $\n\
    #        "

    CreateDirectory $SAVED_PATH_TO

    Pop $8
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

; In $0 = path
; Out $2 = result
Function HowManyDepthsNotExist
    Push $0
    Push $1
    Push $8
    Push $9
    StrCpy $8 $0
    StrCpy $9 0
    ${Do}
        StrCpy $0 $8
        StrCpy $1 $9
        Call RemoveEndsFromPath

        StrCpy $0 $2
        Call DoesDirExist

        #MessageBox mb_TopMost "HowManyDepthsNotExist $\n\
        #        8-path=$8 $\n\
        #        9-count=$9 $\n\
        #        2-path-shrunk=$2 $\n\
        #        1-dir-exist=$1 $\n\
        #        "

        IntOp $9 $9 + 1
    ${LoopUntil} $1 = 1

    IntOp $2 $9 - 1
    Pop $9
    Pop $8
    Pop $1
    Pop $0
FunctionEnd

Function RemoveDirectoriesWhichWeDid
    Push $0
    Push $1
    Push $2
    Push $3

    ${If} $SAVED_PATH_TO != ""

        #MessageBox mb_TopMost "RemoveDirectoriesWhichWeDid $\n\
        #        path=$SAVED_PATH_TO $\n\
        #        depth=$SAVED_CREATE_DEPTH $\n\
        #        "

        IntOp $3 $SAVED_CREATE_DEPTH - 1
        ${ForEach} $2 0 $3 + 1
            StrCpy $0 $SAVED_PATH_TO
            StrCpy $1 $2
            Call RemoveDirectoryAtNegDepth

        ${Next}

    ${EndIf}

    StrCpy $SAVED_PATH_TO ""
    StrCpy $SAVED_CREATE_DEPTH ""

    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

; In $0 = path
; In $1 = how many end bits to remove
Function RemoveDirectoryAtNegDepth
    Push $2
        Call RemoveEndsFromPath

        #MessageBox mb_TopMost "RemoveDirectoryAtNegDepth $\n\
        #        2-result=$2 $\n\
        #       "

        RmDir $2
    Pop $2
FunctionEnd

; In $0 = path
; In $1 = how many end bits to remove
; Out $2 = result
Function RemoveEndsFromPath
    nsArray::Clear my_array
    nsArray::Split my_array $0 \ /noempty

    ${ForEach} $2 1 $1 + 1
        nsArray::Remove my_array /at=-1
    ${Next}

    nsArray::Join my_array \ /noempty
    Pop $2
FunctionEnd

; In $0 = path
; Out $0 = result
Function ConformDirectoryPath
    nsArray::Clear my_array
    nsArray::Split my_array $0 \ /noempty
    nsArray::Join my_array \ /noempty
    Pop $0
FunctionEnd

; In $0 = path
; Out $1 = result 0/1
Function DoesDirExist
    StrCpy $1 1
    IfFileExists "$0\*.*" alreadyexists
        StrCpy $1 0
    alreadyexists:
FunctionEnd


;****************************************************************
;
; Service maintenance
;
;****************************************************************
Var ServiceModified

Function DoServiceInstall
    ${If} $ServiceModified != 1
        ; Check loader can do command
        GetDLLVersion "$INSTDIR\mta\loader.dll" $R0 $R1
        IntOp $R5 $R1 & 0x0000FFFF ; $R5 now contains build
        ${If} $R5 > 4909
            Exec '"$INSTDIR\Multi Theft Auto.exe" /nolaunch /kdinstall'
            StrCpy $ServiceModified 1
        ${EndIf}
    ${EndIf}
FunctionEnd

Function un.DoServiceUninstall
    ${If} $ServiceModified != 2
        ; Check loader can do command
        GetDLLVersion "$INSTDIR\mta\loader.dll" $R0 $R1
        IntOp $R5 $R1 & 0x0000FFFF ; $R5 now contains build
        ${If} $R5 > 4909
            Exec '"$INSTDIR\Multi Theft Auto.exe" /nolaunch /kduninstall'
            StrCpy $ServiceModified 2
        ${EndIf}
    ${EndIf}
FunctionEnd


;****************************************************************
;
; CustomNetMessagePage
;
; Show message to get user to unblock installer from firewall or similar
;
;****************************************************************
Var NetDialog
Var NetStatusLabel1
Var NetStatusLabel2
Var NetTryCount
Var NetDone
Var NetImage
Var NetImageHandle
Var NetMsgURL
Var NetPrevInfo
Var NetEnableNext
Var NetOtherSuccessCount
Var NetMirror
!define NEXT_BUTTON_ID 1
LangString NETTEST_TITLE1   ${LANG_ENGLISH} "Online update"
LangString NETTEST_TITLE2   ${LANG_ENGLISH} "Checking for update information"
LangString NETTEST_STATUS1  ${LANG_ENGLISH} "Checking for installer update information..."
LangString NETTEST_STATUS2  ${LANG_ENGLISH} "Please ensure your firewall is not blocking"

Function CustomNetMessagePage
    ${LogText} "+Function begin - CustomNetMessagePage"
    # Initial try with blank page
    Call TryToSendInfo
    ${If} $NetDone == 1
        # If it works, then skip this page
        ${LogText} "-Function end - CustomNetMessagePage (NetDone)"
        Return
    ${EndIf}

    # Setup page
    nsDialogs::Create 1018
    Pop $NetDialog
    ${If} $NetDialog == error
        ${LogText} "-Function end - CustomNetMessagePage (error)"
        Abort
    ${EndIf}

    GetDlgItem $0 $HWNDPARENT 1037
    ${NSD_SetText} $0 "$(NETTEST_TITLE1)"

    GetDlgItem $0 $HWNDPARENT 1038
    ${NSD_SetText} $0 "$(NETTEST_TITLE2)"

    ${NSD_CreateLabel} 0 20 100% 15 "$(NETTEST_STATUS1)"
    Pop $NetStatusLabel1
    ${NSD_AddStyle} $NetStatusLabel1 ${SS_CENTER}

    ${NSD_CreateLabel} 0 155 100% 15 "$(NETTEST_STATUS2)"
    Pop $NetStatusLabel2
    ${NSD_AddStyle} $NetStatusLabel2 ${SS_CENTER}

    ${NSD_CreateBitmap} 155 71 100% 100% ""
    Pop $NetImage
    ${NSD_SetImage} $NetImage $TEMP\image.bmp $NetImageHandle

    # Disable Next button maybe
    ${If} $NetEnableNext != 1
        GetDlgItem $0 $HWNDPARENT ${NEXT_BUTTON_ID}
        EnableWindow $0 0
    ${EndIf}

    Call UnexpandComponentsPage
    ${NSD_CreateTimer} NetFuncTimer 1000
    nsDialogs::Show
    ${NSD_FreeImage} $NetImageHandle
    ${LogText} "-Function end - CustomNetMessagePage"
FunctionEnd

Function CustomNetMessagePageLeave
    ${LogText} "+Function begin - CustomNetMessagePageLeave"
    ${NSD_KillTimer} NetFuncTimer
    Call TryToSendInfo
    Call UnexpandComponentsPage
    ${LogText} "-Function end - CustomNetMessagePageLeave"
FunctionEnd

Function NetFuncTimer
    ${LogText} "+Function begin - NetFuncTimer"
    ${NSD_KillTimer} NetFuncTimer
    IntOp $NetTryCount $NetTryCount + 1
    Call TryToSendInfo

    # Allow Next button after a number of tries
    ${If} $NetTryCount > 3
        StrCpy $NetEnableNext 1
    ${EndIf}

    ${If} $NetEnableNext == 1
        GetDlgItem $0 $HWNDPARENT ${NEXT_BUTTON_ID}
        EnableWindow $0 1
    ${EndIf}

    ${If} $NetDone == 1
        # If it works now, then proceed to the next page
        SendMessage $HWNDPARENT "0x408" "1" ""      # GotoNextPage
    ${Else}
        # Otherwise, try again in a second
        ${NSD_CreateTimer} NetFuncTimer 1000
    ${EndIf}
    ${LogText} "-Function end - NetFuncTimer"
FunctionEnd

;--------------------------
; Out $NetDone = result   (1 = success)
Function TryToSendInfo
    # Check if already done
    ${If} $NetDone == 1
        Return
    ${EndIf}

    ${LogText} "+Function begin - TryToSendInfo"

    # Do attempt
    Call NetComposeURL
    StrCpy $0 $NetMsgURL
    StrCpy $1 3000
    Call DoSendInfo

    # Set result
    ${If} $0 == 1
        StrCpy $NetDone 1
    ${Else}
        # Check if anything else is contactable
        StrCpy $0 "http://www.google.com/"
        StrCpy $1 1000
        Call DoSendInfo
        ${If} $0 == 1
            StrCpy $NetEnableNext 1
            IntOp $NetOtherSuccessCount $NetOtherSuccessCount + 1
            ${If} $NetOtherSuccessCount > 3
                StrCpy $NetDone 1
            ${EndIf}
        ${EndIf}
    ${EndIf}
    ${LogText} "-Function end - TryToSendInfo"
FunctionEnd

;--------------------------
; In $0 = URL
; In $1 = Timeout
; Out $0 = result   (1 = success)
Function DoSendInfo
    ${LogText} "+Function begin - DoSendInfo($0,$1)"
    NSISdl::download_quiet /TIMEOUT=$1 "$0" "$TEMP\prev_install"
    Pop $R0
    ${LogText} "NSISdl::download_quiet result:$R0"

    # Allow for server errors #1
    StrCpy $0 $R0 14
    ${If} $0 == "Server did not"
        StrCpy $R0 "success"
    ${EndIf}

    # Allow for server errors #2
    StrCpy $0 $R0 4
    ${If} $0 == "HTTP"
        StrCpy $R0 "success"
    ${EndIf}

    # Set result
    StrCpy $0 0
    ${If} $R0 == "success"
        StrCpy $0 1
    ${EndIf}
    ${LogText} "-Function end - DoSendInfo result:$0"
FunctionEnd

;--------------------------
; Out $NetMsgURL = URL
Function NetComposeURL
    ${If} $NetMsgURL == ""  
        IfFileExists "$APPDATA\MTA San Andreas All" 0 skip
            StrCpy $NetPrevInfo "$NetPrevInfo&pp=1"
        skip:
        StrCpy $NetPrevInfo "$NetPrevInfo&ver=${0.0.0}"
    !ifndef LIGHTBUILD
        StrCpy $NetPrevInfo "$NetPrevInfo&n=1"
    !endif
    !ifdef REVISION
        StrCpy $NetPrevInfo "$NetPrevInfo&rev=${REVISION}"
    !endif
    ${EndIf}

    IntOp $NetMirror $NetMirror + 1
    IntOp $NetMirror $NetMirror % 2
    ${Switch} $NetMirror
        ${Case} 0
            StrCpy $NetMsgURL "http://updatesa.multitheftauto.com/sa/install/1/?x=0"
            ${Break}
        ${Default}
            StrCpy $NetMsgURL "http://updatesa.mtasa.com/sa/install/1/?x=0"
            ${Break}
    ${EndSwitch}
    StrCpy $NetMsgURL "$NetMsgURL$NetPrevInfo"
    StrCpy $NetMsgURL "$NetMsgURL&try=$NetTryCount"
    StrCpy $NetMsgURL "$NetMsgURL&other=$NetOtherSuccessCount"
    ${LogText} "NetComposeURL result:$NetMsgURL"
FunctionEnd

Function NoteMTAWasPresent
    StrCpy $NetPrevInfo "$NetPrevInfo&pm=1"
FunctionEnd

Function NoteGTAWasPresent
    StrCpy $NetPrevInfo "$NetPrevInfo&pg=1"
FunctionEnd

# Find valid Windows SID to use for permissions fixing
Function SetPermissionsGroup
    #   BU      = BUILTIN\Users
    #   S-1-2-0 = \LOCAL
    #   S-1-1-0 = \Everyone
    nsArray::SetList array "BU" "S-1-2-0" "S-1-1-0" /end
    ${ForEachIn} array $0 $1
        AccessControl::SidToName $1
        Pop $2  # Domain
        Pop $3  # Name
        StrLen $0 $2
        ${If} $0 < 20   # HACK: Error message is longer than this
            StrCpy $PermissionsGroup "$1"
            ${LogText} "SetPermissionsGroup using '$PermissionsGroup'"
            Return
        ${EndIf}
        ${LogText} "AccessControl::SidToName failed with '$1': '$2' '$3'"
    ${Next}
    ; Default to \LOCAL
    StrCpy $PermissionsGroup "S-1-2-0"
    ${LogText} "SetPermissionsGroup using '$PermissionsGroup'"
FunctionEnd

