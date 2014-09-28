;DirectoryWatch
;Password protect a given Folder
;Autor: D. K. Nana aka Mahanaïm
 
;========================Header
#SingleInstance Force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
applicationname = DW
delai = 60
StringCaseSense, On
Gosub,TRAYMENU
;======================== Script
; Read saved configuration

Gosub,READINI 
	SplashTextOn,300,50,Configuration State,is %etatConf%.
	Sleep 2000
	SplashTextOff
; MsgBox, etatConf is %etatConf%

etat = OFF
; Charge start configuration
IfInString, etatConf, %etat%
{
SplashTextOn,300,50,Configuration State,is %etatConf%. It seems we need to set up the protection
Sleep 2000
SplashTextOff
; GUI here
Gosub, SETTINGS
sleep,1000
WinWaitClose, DW Settings
MsgBox,We are done Click Ok to continue
}
else 
{
if (dossierCible = "")
{
SplashTextOn,300,50,CAUTION, Configuration uncomplete!!!
	Sleep 2000
	SplashTextOff	
Gosub, SETTINGS
sleep,1000
WinWaitClose, DW Settings
MsgBox,We are done Click Ok to continue
}
}

	; if configured, charge et decode P.W
	todecode = %encpw%
	Gosub,STRDECODER
	Monmotdepasse = %decodedpw%
	Loop, %dossierCible%, 2, 1
	titleCible = %A_LoopFileName%

delai := delai*60
bloque = 1	
casOp = 0
stopCpy = 0
;=======================Leaving Config
VEILLE:
while bloque = 1
{
; Open Hook to prevent renaming, cutting or deleting target folder
file := FileOpen(Hooklkd, "r",0)
; FileSetAttrib, +H+S, %dossierCible%,0, 1 -->searching for a better way to prevent from searching in Folder.

; Verify if target windows opened
Gosub, WINMONITOR
if casOp = 1
{
 Gosub,VERROUILLE
 casOp = 0
 }
else 
	{
	; check if target windows copied
	Gosub, CPMONITOR	
	}
	
IfInString, stopCpy, %dossierCible%
	{ 
		clipboard =
		casCpy =1
		Gosub,VERROUILLE
	}
	casCpy = 0
}
Return

;========================Protections routines
VERROUILLE: 
sleep, 500
IfWinExist, %titleCible%
sleep, 500
WinClose, %titleCible%

; Password asking Dialog
Loop, 3
{
InputBox,  motdepasseClient, Stop: Enter Password first, (Password will be hidden), hide,270,130
if Monmotdepasse = %motdepasseClient% 
	{
	; Cas de copie
	IfInString, stopCpy, %dossierCible%
	{
		; clipboard = %stopCpy%	
		casCpy = 1 ; specify which by Unlocking
		bloque = 0
		Gosub, DEVERROUILLE
	}
	else{
		run %dossierCible%
		heureOuvert = %A_TickCount%
		bloque = 0
		casCpy = 0 
		Gosub, DEVERROUILLE
		}
	break
	}
	else
	{
	stopCpy =
	SplashTextOn,300,50, Password issue ,%A_Index% Try: false password, please retry!!!
	Sleep 2000
	SplashTextOff
	bloque = 1
	}
}
return

;----------------------DEVERROUILLE
DEVERROUILLE:
while bloque = 0
{
if casCpy = 1
	{
	MsGBox, 4, Need Confirmation, Do you want to copy the folder?
	; Confirm copy
	IfMsgBox Yes
	{
		file.Close()
		; FileSetAttrib,-H-S, %dossierCible%,0, 1 
		MsgBox,0,waiting for Confirmation, Retry Copy and click me afterward
		clipboard =
		stopCpy =
		casCpy = 0
		bloque = 1
	}
	IfMsgBox No
	{
		clipboard =
		stopCpy =
		casCpy = 0
		bloque = 1
	}
	}
; Exploring case
else
{
	; MsgBox, delai is %delai%
Loop, %delai%
	{
	sleep, 1000
	file.Close() 
    IfWinNotExist, %titleCible%
			{
				ControlGetText, Chemin2, A
				IfNotInString, Chemin2, %dossierCible%
				{
				bloque = 1
				break
				}
			}
		   else
			{
			WinWaitActive, ahk_class CabinetWClass
			ControlGetText, Chemin, A
			; Opened folder in underground.
			IfNotInString, Chemin, %titleCible%
				{
				duree := A_TickCount - heureOuvert
				delaims := delai * 1000
				; MsgBox, delai is %delaims% duree is %duree%
				if delaims < %duree%
					{
					; delai depassÃ©
					MsgBox, 0, Confirmation of presence, Locking in 30 seconde Click to cancel,30
					IfMsgBox Timeout
					{
					WinClose, %titleCible%
					; No reation. Lock anew.
					bloque = 1
					break
					}
					else 
						{
						; User present, reinitialise the timing.
						heureOuvert:= A_TickCount
						}
					}
				}
				else
				{  
				; target folder on top. reinitialise the timing.
				heureOuvert:= A_TickCount
				sleep, 500
				}
			}
	
		}
	}
}
Return

;-----------------------clipboardwatch
; CPMONITOR:
CPMONITOR:

; stopCpy =
OnClipboardChange:
; critical
content = %A_EventInfo%
if content = 1
{
sleep, 600
stopCpy = %clipboard%
}
return
Return

;------------------------WINMONITOR
WINMONITOR:
WinGetClass, class, A

If class contains CabinetWClass
	{
	; check if target folder opened
	WinWaitActive, ahk_class CabinetWClass
	; record pfad of activ folder.
	ControlGetText, Chemin, A
	IfInString, Chemin, %dossierCible%
		{
		WinClose
		casOp = 1
		}
	}
	else casOp = 0
return

;=======================Subroutines
;-----------------------INIREAD
READINI:
IfNotExist,%applicationname%.ini
{
  etatConf = OFF
  encpw = 
  dossierCible = 
  Hooklkd =
  delai = 1
  Gosub,WRITEINI
}
else
{
IniRead,etatConf,%applicationname%.ini,Settings,etatConf
IniRead,encpw,%applicationname%.ini,Settings,encpw
IniRead,dossierCible,%applicationname%.ini,Settings,dossierCible
IniRead,Hooklkd,%applicationname%.ini,Settings,Hooklkd
IniRead,delai,%applicationname%.ini,Settings,delai
}
Return

;-------------------------- INIWRITE
WRITEINI:
IniWrite,%etatConf%,%applicationname%.ini,Settings,etatConf
IniWrite,%encpw%,%applicationname%.ini,Settings,encpw
IniWrite,%dossierCible%,%applicationname%.ini,Settings,dossierCible
IniWrite,%Hooklkd%,%applicationname%.ini,Settings,Hooklkd
IniWrite,%delay%,%applicationname%.ini,Settings,delai
Return

;----------------------------------------------------------------------------------Hook Creation
; creating a hook invisible and temporary
LINK:
HOOKpfad = %dossierCible%\HOOK.tmp
FileAppend, schibolet.`n, %HOOKpfad%
FileSetAttrib, +R+H+S+T, %HOOKpfad%, 0 
Return

;--------------------------- Encode PW 
STRENCODER:
  AutoTrim, OFF
  
; Let's get Random!
  Random, ,%A_now%
  Random, pe_rand1, 2, 6
  Random, pe_rand2, 4, 7
  Random, pe_rand3, 10, 90

; Store pe_rand3 Substitute!
  stringleft, pr3_L1, pe_rand3, 1
  stringright, pr3_R1, pe_rand3, 1
  pr3_L1 +=64
  pr3_R1 +=64
  pr3_L2 := chr(pr3_L1)
  pr3_R2 := chr(pr3_R1)

; Begin final String, adding the first Random #!
  allstr := pe_rand1

; Get the Password and split it!
  stringsplit, sngltr, toencode

; Change to numbers & Encode!
  Loop, parse, toencode
  {
    nxtltr := sngltr%a_index%
    asc_numb := asc(nxtltr)
    chngd%a_index% := asc_numb+pe_rand1
    chngd%a_index% *= pe_rand2
    chngd%a_index% += pe_rand3

    tempor := chngd%a_index%
    allstr = %allstr%%tempor%
  }

; Add the 2nd/3rd Random #'s!'
  allstr = %allstr%%pe_rand2%%pr3_L2%
  allstr = %pr3_R2%%allstr%
  ; could go on Top of code
  cryptedpw = %allstr%
Return

;-----------------------------------------------------------------------------------------------Decode PW Works fine
STRDECODER:
  AutoTrim, OFF

; Get the Decryptors!
  allstr = %todecode%
  StringLeft, pr3_R2, allstr, 1
  StringRight, pr3_L2, allstr, 1
  StringTrimLeft, tempor, allstr, 1
  allstr = %tempor%
  StringTrimRight, tempor, allstr, 1
  allstr = %tempor%
  StringLeft, pd_rand1, allstr, 1
  StringTrimLeft, tempor, allstr, 1
  allstr = %tempor%
  StringRight, pd_rand2, allstr, 1
  StringTrimRight, tempor, allstr, 1
  allstr = %tempor%

; Fix Decryptor 3!
  pr3_L1 := asc(pr3_L2)
  pr3_R1 := asc(pr3_R2)
  pr3_L1 -= 64
  pr3_R1 -= 64
  pd_rand3 = %pr3_L1%%pr3_R1%

  numb := strlen(allstr)/3

; Decrypt and change to Letters then to Password!
   ps_word =
  loop, %numb%
  {
    StringLeft, tmpltr, allstr, 3
    StringTrimLeft, tempor, allstr, 3
    allstr = %tempor%
    tmpltr -= pd_rand3
    tmpltr /= pd_rand2
    tmpltr -= pd_rand1
    tmpwrd := chr(tmpltr)
    ps_word = %ps_word%%tmpwrd%
  }
  decodedpw = %ps_word%
Return

;============================GUI
SETTINGS:
Gui,destroy
Gui,+AlwaysOnTop
Gui,Add,Tab2, x4 y5 w280 h220,Settings|About
Gui, Tab,1
Gui,Add,GroupBox,x111 y28 w170 h150 0x2000,Password settings
Gui,Add,Edit,x134 y57 w120 h21 Password vpw1,password1
Gui,Add,Edit,x135 y98 w120 h21 Password vpw2,password2
Gui,Add,Button,x120 y139 w150 h25 vMonmotdepasse gPwMatching,Check password matching
Gui,Add,Button,x7 y61 w100 h25 vMondossierCible gChooseDir, Choose a directory
Gui,Add,Slider,x7 y120 w100 h33 0x40 Center ToolTip vdelay ,Delay Time
Gui,Add,Button,x78 y190 w100 h25 gGuiClose,Finished
Gui,Tab,2
; Gui,Add,Tab,x40 y5 w280 h220,About
Gui,Add,GroupBox,x14 y28 w260 h150 0x2000,Directory brought to you by 8p1t1h
Gui, Add, Text, x40 y60 w230 h140 , Autor: K. D. Nana`n @:konwendsida_nana@yahoo.fr `nand remember:`nthere is nothing covered, `nthat shall not be revealed; and hid, `nthat shall not be known.`nMatthew 10, 26
Gui,Show,x429 y99 w288 h230 ,DW Settings
return
Return

PwMatching:
Gui, submit, NoHide
if pw1 = %pw2%
{
Monmotdepasse = %pw1%
SplashTextOn,300,50,Info, Great passwords do match!!!
	Sleep 2000
	SplashTextOff
}
else
{
SplashTextOn,300,50,CAUTION, Passwords didnt match retry!!!
	Sleep 2000
	SplashTextOff
}
Return
; Gui, submit, NoHide
ChooseDir:
Gui,+OwnDialogs 
FileSelectFolder, MondossierCible, ,  , Select Source folder  ; allow edit field for direct entry
Return


GuiClose:
Gui, submit,NoHide
if (dossierCible = "") or Monmotdepasse = "" 
{
SplashTextOn,300,50,CAUTION, Configuration uncomplete!!!
	Sleep 2000
	SplashTextOff	
Gui,Show,x429 y99 w288 h230 ,DW Settings
}
else Gui,destroy
	etatConf = ON

dossierCible = %MondossierCible%
delai = %delay%
; extract title of activ window
Loop, %dossierCible%, 2, 1
titleCible := A_LoopFileName
; InputBox, Monmotdepasse, Entrez le mot2passe, (your input will be hidden), hide
toencode = %Monmotdepasse%
Gosub, STRENCODER
encpw = %cryptedpw%
; create a hook in target folder
Gosub, LINK
Hooklkd = %HOOKpfad%
Gosub, WRITEINI
Return

;--------------------------Settings check!
SETTINGSCHECK:
if etatConf = ON
{
; password verification check
Loop, 3
{
InputBox,  motdepasseClient, Stop: Enter Password first, (Password will be hidden), hide, 270, 130
if Monmotdepasse = %motdepasseClient% 
	{
		Gui,1:Destroy
		Gosub, SETTINGS
		break
	}
	; rank := A_Index +1
	SplashTextOn,300,50,Password issue ,%A_Index% .Try: false password , retry!
	Sleep 2000
	SplashTextOff
	bloque = 1
}
}
else
{
Gui,1:Destroy
Gosub, SETTINGS
}
Return

;==================================Menu
TRAYMENU:
Menu,Tray,NoStandard
Menu,Tray,DeleteAll
Menu,Tray,Add,%applicationname%,SETTINGS
Menu,Tray,Add
Menu,Tray,Add
Menu,Tray,Add,&Settings,SETTINGSCHECK
Menu,Tray,Add,&About,ABOUT
Menu,Tray,Add,E&xit,EXIT
Menu,Tray,Default,%applicationname%
Menu,Tray,Tip,%applicationname%
Return

ABOUT:
Gui,1:Destroy
Gui,+AlwaysOnTop
Gui,Add,GroupBox,x14 y28 w260 h150 0x2000,Directory brought to you by 8p1t1h
Gui, Add, Text, x40 y60 w230 h140 , Autor: K. D. Nana`n @: konwendsida_nana@yahoo.fr `nand remember:`nthere is nothing covered, `nthat shall not be revealed; and hid, `nthat shall not be known.`nMatthew 10, 26`nplease please Note carefully your Password
Gui,Show,x429 y99 w288 h230 ,DW About
Return

EXIT:
Loop, 3
{
InputBox,  motdepasseClient, Stop:Enter Password first, (Password will be hidden), hide, 270, 130
if Monmotdepasse = %motdepasseClient% 
	{
		ExitApp
		break
	}
	;rank := A_Index +1
	SplashTextOn,300,50,Password issue ,%A_Index%. Try: false password , retry!
	Sleep 2000
	SplashTextOff
	bloque = 1
}
return


