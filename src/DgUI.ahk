; mnu : menu
; smnu : sub menu
; dlg : dialog box
class DgUI extends DgObject
{
    __New()
    {
        _Logger.BEGIN(  A_ThisFunc )

        this.capsLockAlertEnabled   := true
        this.numLockAlertEnabled    := true

        this.pausedTaskColorSwitch := 0 ; on off

        _Logger.END(  A_ThisFunc )

    }
    ;------------------------------------------------------------------------------
    init()
    {
        _Logger.BEGIN(  A_ThisFunc )
        
        this.mTray := new DgMenu( { name: "Tray"} )     ; contructed without childern to show the icon early. children will be added later in this method
        iconFile := PathCombine( A_WorkingDir,  "..\img\DigiHotkey.ico")
        this.mTray.setIcon( iconFile )

        this.lang              := new DgLang()
        langFile := PathCombine( A_WorkingDir, "..\config\lang.json")
        this.lang.loadFromJson( langFile )
        this.setActiveLanguage( _App.config.languageName )
      
        mSeparator              := new DgMenu( { name: "-"})

        this.mExit              := new DgMenu( { name: "Exit", caption: this.lang.mnuExit, func: Func("OnMenu_Exit")})
        this.mTaskMan           := new DgMenu( { name: "TaskMan",  caption: this.lang.mnuTaskMan, func: Func("OnMenu_TaskMan") } )
       

        this.miCapsLockAlert     := new DgMenu( { name: "CapsLockAlert",     caption: this.lang.mnuAlert,     func: Func("OnMenu_CapsLockAlert") } )
        this.miCapsLockAlwaysOff := new DgMenu( { name: "CapsLockAlwaysOff", caption: this.lang.mnuAlwaysOff, func: Func("OnMenu_CapsLockAlwaysOff") } )
        this.miCapsLockAlwaysOn  := new DgMenu( { name: "CapsLockAlwaysOn",  caption: this.lang.mnuAlwaysOn,  func: Func("OnMenu_CapsLockAlwaysOn") } )
        this.mCapsLock          := new DgMenu( { name: "CapsLock", caption: this.lang.mnuCapsLock, children: [this.miCapsLockAlert, mSeparator, this.miCapsLockAlwaysOff, this.miCapsLockAlwaysOn] } )

        this.miNumLockAlert      := new DgMenu( { name: "NumLockAlert"    , caption: this.lang.mnuAlert,      func: Func("OnMenu_NumLockAlert") } )
        this.miNumLockAlwaysOff  := new DgMenu( { name: "NumLockAlwaysOff", caption: this.lang.mnuAlwaysOff,  func: Func("OnMenu_NumLockAlwaysOff") } )
        this.miNumLockAlwaysOn   := new DgMenu( { name: "NumLockAlwaysOn" , caption: this.lang.mnuAlwaysOn,   func: Func("OnMenu_NumLockAlwaysOn") } )
        this.mNumLock           := new DgMenu( { name: "NumLock",  caption: this.lang.mnuNumLock,  children: [this.miNumLockAlert, mSeparator, this.miNumLockAlwaysOff, this.miNumLockAlwaysOn] } )

        this.miInsEnable    := new DgMenu( { name: "InsertEnable", caption: this.lang.mnuEnable, func: Func("OnMenu_InsKeyEnable") } )
        this.miInsDisable   := new DgMenu( { name: "InsertDisable", caption: this.lang.mnuDisable, func: Func("OnMenu_InsKeyDisable") } )
        this.miInsert       := new DgMenu( { name: "Insert", caption: this.lang.mnuInsert , children: [this.miInsEnable, this.miInsDisable] } )

        this.mKeyboard         := new DgMenu( { name: "Keyboard",    caption: this.lang.mnuKeyboard, children: [this.mCapsLock, this.mNumLock, this.miInsert] })
    
        this.mSound         := new DgMenu( { name: "Sound",    caption: this.lang.mnuSound })

        this.mPower         := new DgMenu( { name: "Power",  caption: this.lang.mnuPower    })
        this.mActionGroups  := new DgMenu( { name: "ActionGroups",  caption: this.lang.mnuHotkeys  })
        this.mLanguage      := new DgMenu( { name: "Language", caption: this.lang.mnuLanguage})
        
        this.mSettings      := new DgMenu( { name: "Settings", caption: this.lang.mnuSettings, func: Func("OnMenu_Settings")})
        this.mAbout         := new DgMenu( { name: "About", caption: this.lang.mnuAbout, func: Func("OnMenu_About")})
        this.mHelp          := new DgMenu( { name: "Help", caption: this.lang.mnuHelp, func: Func("OnMenu_Help")})
        this.mTools         := new DgMenu( { name: "Tools", caption: this.lang.mnuTools, children: [this.mLanguage,this.mSettings, this.mHelp, this.mAbout]})

        for profileName, powerProfile in _App.powerMan {

            item := new DgMenu(  { name: profileName, caption: profileName, func:  Func("OnMenu_PowerProfileSelect") } )
            this.mPower.addItem( item )
        }

        for profileName, soundProfile in _App.audio.profiles {

            item := new DgMenu( { name: profileName, caption: profileName, func:  Func("OnMenu_SoundProfileSelect")} )
            this.mSound.addItem( item )
        }

        for groupName, actionGroup in _App.keyboard.actionGroups {

            item  := new DgMenu( { name: groupName, caption: groupName, func:  Func("OnMenu_ActionGroupSelect") } )
            item.checked := actionGroup.Enabled
            this.mActionGroups.addItem( item )
        }

        for languageName, language in _App.ui.lang.languages {

            item := new DgMenu(  { name: languageName, caption: languageName, func:  Func("OnMenu_LanguageSelect") } )
            this.mLanguage.addItem( item )
        }

        menuItems :=  [ this.mActionGroups, this.mSound, this.mPower, this.mKeyboard, this.mTools, this.mTaskMan, this.mExit ]

        for _, menuItem in menuItems {
            this.mTray.addItem( menuItem )
        }

        this.mTray.Build() ; generate Autohotkey menu commands

        ; Tray menu should not be shown until wanted to be

        this.mTaskMan.setDefault()
        this.mTray.setDefaultClickCount( clickCount := 2 ) ; double click to show the default menu ( mntTaskMan for now )
        this.mTray.removeStandardMenus()

        args               := { timeoutSec : _App.config.infoTipTimeoutSec, width: 120, height: 60 ,  winColor: enumColor.Azure4 }

        texts                 := [ { content: "Caps", x:10, y:05, size: 15, font: "Verdana", style: "Regular", color: enumColor.LedOn }
                                ,  { content: "Lock", x:10, y:30, size: 15, font: "Verdana", style: "Regular", color: enumColor.LedOn } ]
        this.capsLockOnTip    := new DgInfoTip( args, texts )

        texts                 := [ { content: "Caps", x:10, y:05, size: 15, font: "Verdana", style: "Regular", color: enumColor.LedOff }
                                 , { content: "Lock", x:10, y:30, size: 15, font: "Verdana", style: "Regular", color: enumColor.LedOff } ]
        this.capsLockOffTip   := new DgInfoTip( args,  texts )

        args               := { timeoutSec : _App.config.infoTipTimeoutSec, width: 60, height: 60 ,  winColor: enumColor.Azure4 }
        texts                 := [ { content: "Num", x:10, y:05, size: 15, font: "Verdana", style: "Regular", color: enumColor.LedOn }
                                 , { content: "Lock", x:10, y:24, size: 15, font: "Verdana", style: "Regular", color: enumColor.LedOn }  ]
        this.numLockOnTip     := new DgInfoTip( args,  texts  )

        texts                 := [ { content: "Num", x:05, y:05, size: 11, font: "Verdana", style: "Regular", color: enumColor.LedOff}
                                 , { content: "Lock", x:05, y:20, size: 11, font: "Verdana", style: "Regular", color: enumColor.LedOff }  ]

        this.numLockOffTip    := new DgInfoTip( args,  texts )

        args               := { timeoutSec :  _App.config.volumeTipTimeoutSec, width: 160, height: 20 , textSize: 30 }
        this.volumeTip        := new DgProgressTip( args )

        this.taskbarHeight          := GetTaskbarHeight( default := 50)
        ;activePowerPlanName := _App.powerMan.getActivePlanName()
        
        this.applyConfig()

        _Logger.END(  A_ThisFunc )
    }
    ;------------------------------------------------------------------------------
    createDialogs() 
    {
        _Logger.BEGIN( A_ThisFunc )
        
        this.dlgTimer    := new DgTimerDialog()
        this.dlgReminder := new DgReminderDialog()
        this.dlgTaskMan  := new DgTaskManDialog()
        this.dlgInsomnia := new DgInsomniaDialog()
        this.dlgAbout    := new DgAboutDialog()
        
        _Logger.END(  A_ThisFunc )
    }    
    ;------------------------------------------------------------------------------
    applyConfig()
    {
        this.setCapsLockAlert( _App.config.capsLockAlertEnabled )
        
        this.setNumLockAlert( _App.config.numLockAlertEnabled  )

        this.setCapsLockBehaviour( _App.config.capsLockBehaviour )

        this.setNumLockBehaviour(_ App.config.numLockBehaviour )

        this.setActiveSoundProfile( _App.config.soundProfile )

        this.updateActiveLanguageMenu( _App.config.languageName, showInfoMessage := false ) 

    }
    ;------------------------------------------------------------------------------
    setActiveLanguage( languageName_ ) 
    {
        this.lang.setLanguage( languageName_ ) 
        this.languageName := languageName_
    }
    ;------------------------------------------------------------------------------
    updateActiveLanguageMenu( languageName_ , showInfoMessage) 
    {

        _Logger.BEGIN(  A_ThisFunc )

        for _, languageMenu in this.mLanguage.children {

            if( languageMenu.caption == languageName_ ) {

                languageMenu.setChecked( true )

            } else {
                languageMenu.setChecked( false )
            }
        }

        if( showInfoMessage ) {
            this.showInfoMessage( _App.name, this.lang.msgLanguageChange )
        }
        _Logger.END(  A_ThisFunc )
    }
    ;------------------------------------------------------------------------------
    showVolumeTip( value_ , color_, text_ := "" )
    {
        this.capsLockOnTip.destroy()
        this.capsLockOffTip.destroy()

        this.numLockOnTip.destroy()
        this.numLockOffTip.destroy()
        this.volumeTip.show( value_, color_, text_ )
    }
    ;------------------------------------------------------------------------------
    showNotification( title , message := "" )
    {
        _Logger.BEGIN( A_ThisFunc )

        args     := { timeoutSec : _App.config.notifyTipTimeoutSec }

        notification   := new DgNotification( args )
        notification.show( title, message )

        _Logger.END(  A_ThisFunc )
    }
    ;------------------------------------------------------------------------------
    showTimerNotification( task_ )
    {
        args                         := { timeoutSec: _App.config.timerNotifyTimeoutSec }

        if( task_.uiElements.timerNotification ) {
            task_.uiElements.timerNotification.destroy( animate := false )
        }

        task_.uiElements.timerNotification               := new DgNotification( args )
        task_.uiElements.timerNotification.linkText      := this.lang.lnkDismiss
        ;next, the first bound parameter is supposed to be "this" in the class 
        task_.uiElements.timerNotification.linkCallback  := _App.dismissTimerNotification.bind( _App, task_ )

        title   := _App.name . " " . this.lang.msgTimer
        message :=  task_.message

        task_.uiElements.timerNotification.show( title , message )
    }
    ;------------------------------------------------------------------------------
    addTask( task_ )
    {
        _Logger.BEGIN(  A_ThisFunc )

        if( task_.type == enumTaskType.Timer ) {
            message  := this.lang.msgTimerStartPrefix . " '" . task_.name . "' " . this.lang.msgTimerStartSuffix
        } else if( task_.type == enumTaskType.Reminder ) {
            message := this.lang.msgReminderStartPrefix . " '" . task_.name . "' " . this.lang.msgReminderStartSuffix
        } else if( task_.type == enumTaskType.Insomnia) {
            message := this.lang.msgInsomniaStart
        } 
        else {
            _Logger.ERROR(  A_ThisFunc, " task type is neither timer nor reminder ")
            return
        }

        if( this.dlgTaskMan.isVisible() ) { ; updateStatusDialog
            this.dlgTaskMan.show( redraw := true, animate := false ) ; redraw entire window
        }

        this.showNotification( _App.name, message )
        _App.audio.sounds.Start.play()

        _Logger.END(  A_ThisFunc )
    }
    ;------------------------------------------------------------------------------
    removeTask( task_ )
    {
        _Logger.BEGIN(  A_ThisFunc )

        if( task_.type == enumTaskType.Timer ) {

            if( task_.uiElements.timerNotification.isVisible()) {
                 task_.uiElements.timerNotification.destroy( animate := false)
            }
                                                        ; if timer notification is running , close it ...
            _App.audio.sounds.Timer.stop()                                                                              ; ... and stop notification sound
            message := this.lang.msgTimerDeletePrefix . " '" . task_.name . "' " . this.lang.msgTimerDeleteSuffix
            this.showNotification( _App.name , message )
            _App.audio.sounds.Stop.play()

        } else if( task_.type == enumTaskType.Reminder ) {
            message := this.lang.msgReminderDeletePrefix . " '" . task_.name . "' " . this.lang.msgReminderDeleteSuffix
            this.showNotification( _App.name , message )
            _App.audio.sounds.Stop.play()

        } else if( task_.type == enumTaskType.Insomnia ) {
            message := 	this.lang.msgInsomniaStop 	
            this.showNotification( _App.name , message )
            _App.audio.sounds.Stop.play()		
        } else {
            _Logger.ERROR(  A_ThisFunc, " task type is neither timer nor reminder ! ")
             return
        }

        if( this.dlgTaskMan.isVisible() ) {

            this.dlgTaskMan.show( redraw := true, animate := false)                                                   ; redraw entire window
        }

        _Logger.END(  A_ThisFunc )
    }
    ;------------------------------------------------------------------------------
    updateTasksProgress()
    {
        _Logger.BEGIN(  A_ThisFunc )
        
        this.pausedTaskColorSwitch  := ! this.pausedTaskColorSwitch

        if( this.dlgTaskMan.isVisible() )
        {
            for name, task in _App.taskMan.tasks {
                this.updateTaskProgress( task )
            }
        }

        _Logger.END(  A_ThisFunc )
    }
    ;------------------------------------------------------------------------------
    updateTaskProgress( task_ ) ; update task status in the dashboard
    {
        _Logger.BEGIN(  A_ThisFunc )
        
        if( ! task_.HasKey( "uiElements" ) ) {
            return
        }

        remainingTime       := task_.getRemainingTime()
        totalTime           := task_.getTotalTime()

        remainingTimeStr         := FormatSeconds( remainingTime )
        remainingTimeProgress    := task_.isPaused ? 0 : 1 - remainingTime / totalTime

        if( task_.isPaused ) {

            remainingTimeProgress := 0
            textColor        := this.pausedTaskColorSwitch ? enumColor.DarkSlateGray : enumColor.LightGray

        } else {

            remainingTimeProgress :=   100*( 1 - remainingTime / totalTime )
            textColor        :=  enumColor.DarkSlateGray
        }

        GuiControl, ,       % task_.uiElements.hProgress , % Round( remainingTimeProgress )

        GuiControl, Text,   % task_.uiElements.hTextName, % task_.name
        GuiControl, Text,   % task_.uiElements.hTextTime, % remainingTimeStr
        GuiControl, % "+c" textColor, % task_.uiElements.hTextTime

        pauseResumeBtnCaption := task_.isPaused ? enumUnicode.Play : enumUnicode.Pause

        GuiControl, , % task_.uiElements.hPauseResumeBtn, % pauseResumeBtnCaption

        _Logger.END(  A_ThisFunc )
    }
    ;--------------------CAPS LOCK-------------------------------------------------
    setCapsLockBehaviour( enLockBehavior_)
    {
        _Logger.BEGIN(  A_ThisFunc, "enLockBehavior_", enLockBehavior_ )

        if( enLockBehavior_ == enumLockBehaviour.AlwaysOn ) {

            this.miCapsLockAlwaysOn.setChecked( true )
            this.miCapsLockAlwaysOff.setChecked( false )

        }  else if( enLockBehavior_ == enumLockBehaviour.AlwaysOff ) {

            this.miCapsLockAlwaysOn.setChecked( false )
            this.miCapsLockAlwaysOff.setChecked( true )

        }  else if( enLockBehavior_ == enumLockBehaviour.Free ) {

            this.miCapsLockAlwaysOn.setChecked( false )
            this.miCapsLockAlwaysOff.setChecked( false )
        }

        _Logger.END(  A_ThisFunc )
    }
    ;------------------------------------------------------------------------------
    setCapsLockAlert( state_ )
    {
        _Logger.BEGIN(  A_ThisFunc , "state_", state_)

        this.capsLockAlertEnabled    := state_
        this.miCapsLockAlert.setChecked( state_ )

        _Logger.END(  A_ThisFunc )
    }
    ;------------------------------------------------------------------------------
    destroyTips()
    {
        this.volumeTip.destroy()

        this.capsLockOnTip.destroy()
        this.capsLockOffTip.destroy()

        this.numLockOnTip.destroy()
        this.numLockOffTip.destroy()
    }
    ;------------------------------------------------------------------------------
    notifyCapsLockState( bState )
    {
        _Logger.BEGIN(  A_ThisFunc,  "bState", bState)

        if( ! this.capsLockAlertEnabled ) {
            return
        }

        animateLockOn  := ! this.capsLockOffTip.isVisible()
        animateLockOff := ! this.capsLockOnTip.isVisible()

        this.destroyTips()

        if( bState ) {

            this.capsLockOnTip.show( animateLockOn )
            SoundBeep, 600, 100
            _App.audio.sounds.SwitchOn.play()

        } else {

            this.capsLockOffTip.show( animateLockOff )
             SoundBeep, 2000, 100
            _App.audio.sounds.SwitchOff.play()
        }

        _Logger.END(  A_ThisFunc )
    }
    ;-----------------NUM LOCK------------------------------------------------------
    setNumLockBehaviour( enLockBehavior_ )
    {
        _Logger.BEGIN(  A_ThisFunc, "enLockBehavior_", enLockBehavior_ )

        if( enLockBehavior_ == enumLockBehaviour.AlwaysOn) {

            this.miNumLockAlwaysOn.setChecked( true )
            this.miNumLockAlwaysOff.setChecked( false )

        } else if( enLockBehavior_ == enumLockBehaviour.AlwaysOff ) {

            this.miNumLockAlwaysOn.setChecked( false )
            this.miNumLockAlwaysOff.setChecked( true )

        } else if( enLockBehavior_ == enumLockBehaviour.Free)  {

            this.miNumLockAlwaysOn.setChecked( false )  :=
            this.miNumLockAlwaysOff.setChecked( false ) :=
        }

        _Logger.END(  A_ThisFunc )
    }
    ;------------------------------------------------------------------------------
    setNumLockAlert( state_ )
    {
        _Logger.BEGIN(  A_ThisFunc , "state_", state_)

        this.numLockAlertEnabled    := state_
        this.miNumLockAlert.setChecked( state_ )

        _Logger.END(  A_ThisFunc)
    }
    ;------------------------------------------------------------------------------
    notifyNumLockState( bState )
    {
        _Logger.BEGIN(  A_ThisFunc,  "enNotifyLock_", enNotifyLock_ )

        if( ! this.numLockAlertEnabled ) {
             return
        }

        animateLockOn  := ! this.numLockOffTip.isVisible()
        animateLockOff := ! this.numLockOnTip.isVisible()

        this.destroyTips()

        if( bState ) {

            this.numLockOnTip.show( animateLockOn )
            _App.audio.sounds.SwitchOn.play()

        } else {

            this.numLockOffTip.show( animateLockOff )
            _App.audio.sounds.SwitchOff.play()
        }

        _Logger.END(  A_ThisFunc)
    }
    ;------------------------------------------------------------------------------
    setActiveSoundProfile( profileName_ ) ; nota: verbose code for easy code review and debug ( AHK has a basic debugger  )
    {
        _Logger.BEGIN(  A_ThisFunc )

        for _, profileMenu in this.mSound.children {

            if( profileMenu.caption == profileName_ ) {

                profileMenu.setChecked( true )

            } else {
                profileMenu.setChecked( false )
            }
        }

        _Logger.END(  A_ThisFunc )
    }
    ;------------------------------------------------------------------------------
    setActivePowerPlan( planName_ )
    {
        _Logger.BEGIN(  A_ThisFunc, "planName", planName_ )

        for planMenu in this.mPower {
            if( planMenu.name == planName_ ) {
                planMenu.setChecked( true )
            } else {
                planMenu.setChecked( false )
            }
        }

        message := this.lang.msgPowerChanged . "'" . planName_ . "'"

        this.showNotification( _App.name ,  message )

        Sleep, 100

        _Logger.END( A_ThisFunc )
    }
    ;------------------------------------------------------------------------------
    updateActionGroupState( groupName_ , state_ )
    {
        _Logger.BEGIN( A_ThisFunc )

        menuItem     := this.mActionGroups.getMenuItemByCaption( groupName_ )

        if( menuItem ) {
            menuItem.setChecked( state_ )
        } else {
            _Logger.ERROR( A_ThisFunc, "something went wrong! clicked menuItem was not found!")
        }

        _Logger.END( A_ThisFunc )
    }
   
    ;------------------------------------------------------------------------------
    yesNoQuestion( title, message )
    {
        options := 4 + 32 + 8192 ; Yes/No + Icon Question + System Modal

        MsgBox, % options, % title, % message

        IfMsgBox Yes
        {
            return true
        }

        return false
    }
    ;------------------------------------------------------------------------------
    showInfoMessage( title, message )
    {
        options := 0 + 64 + 8192 ; OK + Icon Asterisk (info) + System Modal
        MsgBox,  % options, % title, % message
        
    }
    ;------------------------------------------------------------------------------
    showAlertMessage( title, message )
    {
        options := 0 + 48 + 8192 ; OK + Icon Exclamation + System Modal
        MsgBox,  % options, % title, % message
    }
}
;==============================================================================
