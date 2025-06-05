#NoEnv
#SingleInstance, Force
DllCall("SetProcessDPIAware")  ; ✅ 避免 DPI 縮放導致座標錯位
SetWorkingDir %A_ScriptDir%
#Include Gdip_All.ahk

; ───── 全域變數 ─────
global testPaused := false
global testLogFile := A_ScriptDir "\TestLog.txt"
global runIndex := 1        ; ✅ 執行中目前第幾輪
global runTotal := 1        ; ✅ 設定總共要跑幾輪

; ───── 啟用 GDI+，初始化失敗則退出 ─────
if !pToken := Gdip_Startup()
{
    MsgBox, 16, 啟動失敗, ❌ GDI+ 初始化失敗，腳本即將退出！
    ExitApp
}

; ───── 確保錯誤截圖資料夾存在 ─────
FileCreateDir, %A_ScriptDir%\FailShots

; ───── LOG 測試寫入 ─────
FileAppend, [初始化測試] 測試 LOG 寫入成功於 %A_ScriptDir%`n, %testLogFile%
if !FileExist(testLogFile)
{
    MsgBox, 16, 錯誤, ❌ 無法寫入 LOG 檔案於：`n%A_ScriptDir%`n請檢查資料夾權限或以系統管理員身份執行。
    ExitApp
}

; ───── GUI 介面 ─────
Gui, Add, Text,, 請選擇執行模式：
Gui, Add, Radio, vSelectedMode Checked, 僅執行一次
Gui, Add, Radio,, 自訂執行次數：
Gui, Add, Edit, vCustomCount w50, 1
Gui, Add, Button, gStartTest, 開始測試
Gui, Show,, 自動化測試選單
return

CheckImage(imagePath, ByRef outX, ByRef outY, retries := 5, delay := 200) {
    CoordMode, Pixel, Screen
    Loop, %retries%
    {
        ImageSearch, outX, outY, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *80 %imagePath%
        if (ErrorLevel = 0)
            return true
        Sleep, delay
    }
    return false
}

GuiClose:
    Gdip_Shutdown(pToken)
ExitApp

; ───── 按下「開始測試」後的邏輯 ─────
StartTest:
    Gui, Submit, NoHide
    runCount := (SelectedMode = 1) ? 1 : CustomCount
    runTotal := runCount  ; ✅ 紀錄總執行次數

    ; ✅ 英文輸入法只切一次
    SetEnglishIME()

    Loop, %runCount%
    {
        runIndex := A_Index  ; ✅ 當前第幾輪

        if (testPaused) {
            MsgBox, 測試已暫停，請按 F12 恢復
            return
        }

        ; ✅ 執行測試模組
        testHealthSync()
        inputBloodPressure()
        inputBodyTemperature()
        inputWeight()
        inputHeartRate()
        inputHealthEvent()
        inputBloodOxygen()
        clearBloodPressure()
        clearBodyTemperature()
        clearWeight()
        clearBloodOxygen()
        clearHealthEvent()
        clearHeartRate()
        clearAllHealthData()
    }

    MsgBox, 64, 執行完成, ✅ 所有流程執行完畢！
return

F8::
    Gdip_Shutdown(pToken)
    ExitApp ; 🛑 快捷鍵：結束腳本
F12:: ; ⏸ 暫停/恢復執行
    testPaused := !testPaused
    TrayTip, 測試狀態, % testPaused ? "已暫停" : "已恢復", 1
return

; ───── 🧠 強制切換至英文輸入法（含備援 Alt+Shift 模擬）─────
SetEnglishIME() {
    ; 嘗試切換到美式英文 (語系代碼：0x04090409)
    PostMessage, 0x50, 0, 0x04090409,, A
    Sleep, 200

    ; 備用方案：模擬按鍵切換（有些情況比較穩）
    Send, {LAlt down}{Shift down}{Shift up}{LAlt up}
    Sleep, 500
}
; ───── 🧪 模組：健康同步畫面進入確認 ─────
testHealthSync() {
    global

    ; ✅ Step 0：確保 scrcpy 視窗是前景，滑鼠點擊才有效
    WinActivate, msm8953 for arm64
    WinWaitActive, msm8953 for arm64
    Sleep, 300

    TimeStamp := A_Now
    FormatTime, timeStr, %TimeStamp%, yyyy-MM-dd HH:mm:ss

    ; ✅ Step 1：點擊 Health Book 圖示（依照實際 UI 調整）
    Click, 645, 353
    Sleep, 4000  ; ⏳ 等待頁面進入（視裝置反應速度）

    ; ✅ Step 2：使用 ImageSearch 比對進入畫面是否成功
    WhichStep := "進入 Health Book 畫面"
    ImageSearch, ix, iy, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\health_check.bmp

    ; ✅ Step 3：成功則記錄 PASS，失敗截圖並顯示通知
    if (ErrorLevel = 0) {
        FileAppend, [健康同步] PASS - %timeStr%`n, %testLogFile%
    } else {
        failName := "Fail_Health_" . TimeStamp . ".bmp"
        Send, !{PrintScreen}
        Sleep, 500
        SaveClipboardImage(A_ScriptDir . "\FailShots\" . failName)
        MsgBox, 16, 錯誤通知, ⚠ %WhichStep% 比對失敗！已截圖 %failName%
        FileAppend, [健康同步] FAIL - %timeStr%`n, %testLogFile%
    }
}
; ───── 💉 模組：血壓資料輸入與畫面驗證 ─────
inputBloodPressure() {
    global

    ; ✅ Step 0：確保 scrcpy 視窗為前景
    WinActivate, msm8953 for arm64
    WinWaitActive, msm8953 for arm64
    Sleep, 300

    TimeStamp := A_Now
    FormatTime, timeStr, %TimeStamp%, yyyy-MM-dd HH:mm:ss

    ; ✅ Step 1：點擊 Blood Pressure 加號進入輸入畫面
    Click, 195, 380
    Sleep, 2000

    ; ✅ Step 2：點擊 systolic（收縮壓）欄位並輸入數值
    Click, 223, 216
    Sleep, 300
    SendInput, 120
    Sleep, 200

    ; ✅ Step 3：點擊 diastolic（舒張壓）欄位並輸入數值
    Click, 558, 218
    Sleep, 300
    SendInput, 90
    Sleep, 200

    ; ✅ Step 4：點擊右下角箭頭按鈕送出資料
    Click, 1127, 714
    Sleep, 1000

    ; ✅ Step 5：點擊 SAVE 鈕儲存輸入值
    Click, 759, 685
    Sleep, 1000

    ; ✅ Step 6：畫面比對是否成功進入血壓紀錄頁
    WhichStep := "血壓畫面確認"
    ImageSearch, bx, by, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\blood_pressure_check.bmp

    ; ✅ Step 7：記錄結果，失敗就截圖並警示
    if (ErrorLevel = 0) {
        FileAppend, [血壓輸入] PASS - %timeStr%`n, %testLogFile%
    } else {
        failName := "Fail_BP_" . TimeStamp . ".bmp"
        Send, !{PrintScreen}
        Sleep, 500
        SaveClipboardImage(A_ScriptDir . "\FailShots\" . failName)
        MsgBox, 16, 錯誤通知, ⚠ %WhichStep% 比對失敗！已截圖 %failName%
        FileAppend, [血壓輸入] FAIL - %timeStr%`n, %testLogFile%
    }
}
; ───── 🌡️ 模組：體溫資料輸入與畫面確認 ─────
inputBodyTemperature() {
    global

    ; ✅ Step 0：強制切換到 scrcpy 視窗，確保滑鼠點擊生效
    WinActivate, msm8953 for arm64
    WinWaitActive, msm8953 for arm64
    Sleep, 300

    TimeStamp := A_Now
    FormatTime, timeStr, %TimeStamp%, yyyy-MM-dd HH:mm:ss

    ; ✅ Step 1：點擊 Body Temperature 加號進入輸入頁面
    Click, 525, 381
    Sleep, 2000

    ; ✅ Step 2：點擊輸入欄位並輸入體溫（預設 36）
    Click, 276, 221
    Sleep, 300
    SendInput, 36
    Sleep, 200

    ; ✅ Step 3：點擊右下箭頭送出資料
    Click, 1127, 714
    Sleep, 1000

    ; ✅ Step 4：點擊 SAVE 鈕儲存資料
    Click, 759, 685
    Sleep, 1000

    ; ✅ Step 5：畫面比對，確認是否成功跳轉頁面
    WhichStep := "體溫畫面確認"
    ImageSearch, tx, ty, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\body_temperature_check.bmp

    ; ✅ Step 6：記錄結果，失敗就截圖並通知
    if (ErrorLevel = 0) {
        FileAppend, [體溫輸入] PASS - %timeStr%`n, %testLogFile%
    } else {
        failName := "Fail_BT_" . TimeStamp . ".bmp"
        Send, !{PrintScreen}
        Sleep, 600
        SaveClipboardImage(A_ScriptDir . "\FailShots\" . failName)
        MsgBox, 16, 錯誤通知, ⚠ %WhichStep% 比對失敗！已截圖 %failName%
        FileAppend, [體溫輸入] FAIL - %timeStr%`n, %testLogFile%
    }
}
; ───── ⚖️ 模組：體重資料輸入與畫面驗證 ─────
inputWeight() {
    global

    ; ✅ Step 0：重新聚焦 scrcpy 視窗，防止點擊失效
    WinActivate, msm8953 for arm64
    WinWaitActive, msm8953 for arm64
    Sleep, 300

    TimeStamp := A_Now
    FormatTime, timeStr, %TimeStamp%, yyyy-MM-dd HH:mm:ss

    ; ✅ Step 1：點擊 Weight 加號進入輸入頁面
    Click, 851, 380
    Sleep, 2000

    ; ✅ Step 2：點擊輸入欄（點兩次避免無法聚焦），輸入 60
    Click, 275, 222
    Sleep, 200
    Click, 275, 222
    Sleep, 300
    SendInput, 60
    Sleep, 300

    ; ✅ Step 3：點擊右下角箭頭送出資料
    Click, 1127, 714
    Sleep, 1000

    ; ✅ Step 4：點擊 SAVE 儲存資料
    Click, 759, 685
    Sleep, 1000

    ; ✅ Step 5：畫面比對，確認是否成功
    WhichStep := "體重畫面確認"
    ImageSearch, wx, wy, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\weight_check.bmp

    ; ✅ Step 6：紀錄與截圖處理（僅失敗截圖）
    if (ErrorLevel = 0) {
        FileAppend, [體重輸入] PASS - %timeStr%`n, %testLogFile%
    } else {
        failName := "Fail_Weight_" . TimeStamp . ".bmp"
        Send, !{PrintScreen}
        Sleep, 600
        SaveClipboardImage(A_ScriptDir . "\FailShots\" . failName)
        MsgBox, 16, 錯誤通知, ⚠ %WhichStep% 比對失敗！已截圖 %failName%
        FileAppend, [體重輸入] FAIL - %timeStr%`n, %testLogFile%
    }
}
; ───── ❤️ 模組：心跳資料輸入與畫面確認 ─────
inputHeartRate() {
    global

    ; ✅ Step 0：切換至 scrcpy 視窗，確保滑鼠點擊有效
    WinActivate, msm8953 for arm64
    WinWaitActive, msm8953 for arm64
    Sleep, 4000

    TimeStamp := A_Now
    FormatTime, timeStr, %TimeStamp%, yyyy-MM-dd HH:mm:ss

    ; ✅ Step 1：點擊 Heart Rate +號按鈕，進入輸入畫面
    Click, 195, 684
    Sleep, 2000

    ; ✅ Step 2：點擊欄位兩次（加強穩定）並輸入預設值 80
    Click, 269, 226
    Sleep, 200
    Click, 269, 226
    Sleep, 300
    SendInput, 80
    Sleep, 300

    ; ✅ Step 3：點擊箭頭按鈕送出
    Click, 1127, 714
    Sleep, 1000

    ; ✅ Step 4：點擊 SAVE 按鈕，儲存輸入值
    Click, 759, 685
    Sleep, 1000

    ; ✅ Step 5：比對畫面是否成功回主頁（心跳圖像）
    WhichStep := "心跳畫面確認"
    ImageSearch, hx, hy, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\heart_rate_check.bmp

    ; ✅ Step 6：只在失敗時截圖、提示與寫入 LOG
    if (ErrorLevel = 0) {
        FileAppend, [心跳輸入] PASS - %timeStr%`n, %testLogFile%
    } else {
        failName := "Fail_HeartRate_" . TimeStamp . ".bmp"
        Send, !{PrintScreen}
        Sleep, 500
        SaveClipboardImage(A_ScriptDir . "\FailShots\" . failName)
        MsgBox, 16, 錯誤通知, ⚠ %WhichStep% 比對失敗！已截圖 %failName%
        FileAppend, [心跳輸入] FAIL - %timeStr%`n, %testLogFile%
    }
}
; ───── 🩹 模組：健康事件資料輸入與畫面確認 ─────
inputHealthEvent() {
    global

   ; ✅ Step 0：切換至 scrcpy 視窗，確保模擬滑鼠點擊有效
    WinActivate, msm8953 for arm64
    WinWaitActive, msm8953 for arm64
    Sleep, 4000

    TimeStamp := A_Now
    FormatTime, timeStr, %TimeStamp%, yyyy-MM-dd HH:mm:ss

    ; ✅ Step 1：點擊 Health Event 加號進入事件新增頁
    Click, 523, 684
    Sleep, 4000

    ; ✅ Step 2：點擊下拉式欄位，展開選項
    Click, 537, 201
    Sleep, 500

    ; ✅ Step 3：選擇 "injury" 項目（根據實際排序調整）
    Click, 205, 280
    Sleep, 800

    ; ✅ Step 4：點擊 SAVE 儲存事件
    Click, 759, 685
    Sleep, 1000

    ; ✅ Step 5：畫面比對是否成功新增（使用事件確認圖）
    Sleep, 700
    Send, {Esc}
    WhichStep := "健康事件畫面確認"
    ImageSearch, ex, ey, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\health_event_check.bmp

    ; ✅ Step 6：只在失敗時截圖、提示與寫入 LOG
    if (ErrorLevel = 0) {
        FileAppend, [健康事件] PASS - %timeStr%`n, %testLogFile%
    } else {
        failName := "Fail_Event_" . TimeStamp . ".bmp"
        Send, !{PrintScreen}
        Sleep, 500
        SaveClipboardImage(A_ScriptDir . "\FailShots\" . failName)
        MsgBox, 16, 錯誤通知, ⚠ %WhichStep% 比對失敗！已截圖 %failName%
        FileAppend, [健康事件] FAIL - %timeStr%`n, %testLogFile%
    }
}
; ───── 🩸 模組：血氧資料輸入與畫面驗證 ─────
inputBloodOxygen() {
    global

    ; ✅ Step 0：聚焦 scrcpy 確保滑鼠輸入有效
    WinActivate, msm8953 for arm64
    WinWaitActive, msm8953 for arm64
    Sleep, 4000

    TimeStamp := A_Now
    FormatTime, timeStr, %TimeStamp%, yyyy-MM-dd HH:mm:ss

    ; ✅ Step 1：點擊 Blood Oxygen +號進入輸入畫面
    Click, 850, 685
    Sleep, 4000

    ; ✅ Step 2：輸入 SPO2 數值（預設為 98）
    Click, 275, 220
    Sleep, 300
    SendInput, 98
    Sleep, 300
    Click, 1127, 714  ; 點擊右下角箭頭送出 SPO2
    Sleep, 1000

    ; ✅ Step 3：輸入 Pulse 數值（預設為 80）
    Click, 215, 337
    Sleep, 300
    SendInput, 80
    Sleep, 300
    Click, 1127, 714  ; 點擊右下角箭頭送出 Pulse
    Sleep, 1000

    ; ✅ Step 4：點擊 SAVE 儲存資料
    Click, 759, 685
    Sleep, 1000

    ; ✅ Step 5：比對是否成功進入紀錄畫面
    Sleep, 700
    Send, {Esc}
    WhichStep := "血氧畫面確認"
    ImageSearch, ox, oy, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\blood_oxygen_check.bmp

    ; ✅ Step 6：結果紀錄與失敗處理
    if (ErrorLevel = 0) {
        FileAppend, [血氧輸入] PASS - %timeStr%`n, %testLogFile%
    } else {
        failName := "Fail_Oxygen_" . TimeStamp . ".bmp"
        Send, !{PrintScreen}
        Sleep, 500
        SaveClipboardImage(A_ScriptDir . "\FailShots\" . failName)
        MsgBox, 16, 錯誤通知, ⚠ %WhichStep% 比對失敗！已截圖 %failName%
        FileAppend, [血氧輸入] FAIL - %timeStr%`n, %testLogFile%
    }
}
; ───── 💉 模組：刪除血壓資料並驗證清除 ─────
clearBloodPressure() {
    global

    ; ✅ Step 0：切到 scrcpy 視窗，避免點擊失效
    WinActivate, msm8953 for arm64
    WinWaitActive, msm8953 for arm64
    Sleep, 300

    TimeStamp := A_Now
    FormatTime, timeStr, %TimeStamp%, yyyy-MM-dd HH:mm:ss

    ; ✅ Step 1：點選血壓圖示進入紀錄頁
    Click, 189, 184
    Sleep, 3000

    ; ✅ Step 2：展開紀錄（向下箭頭）
    Click, 647, 713
    Sleep, 1000

    ; ✅ Step 3：選取第一筆血壓資料
    Click, 588, 583
    Sleep, 1000

    ; ✅ Step 4：點選垃圾桶圖示進行刪除
    ToolTip, 正在點擊垃圾桶
    Click, 1157, 584
    Sleep, 300
    Click, 1157, 584
    ToolTip
    Sleep, 1000

    ; ✅ Step 5：點選 YES 確認刪除
    Click, 720, 452
    Sleep, 2000

    ; ✅ Step 6：點擊返回鍵返回主頁
    Click, 49, 71
    Sleep, 2000

    ; ✅ Step 7：確認血壓畫面已清空
    Sleep, 700
    Send, {Esc}
    WhichStep := "血壓刪除畫面確認"
    ImageSearch, cx, cy, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\blood_pressure_clear.bmp

    ; ✅ Step 8：比對結果紀錄
    if (ErrorLevel = 0) {
        FileAppend, [血壓清除] PASS - %timeStr%`n, %testLogFile%
    } else {
        failName := "Fail_Clear_BP_" . TimeStamp . ".bmp"
        Send, !{PrintScreen}
        Sleep, 500
        SaveClipboardImage(A_ScriptDir . "\FailShots\" . failName)
        MsgBox, 16, 錯誤通知, ⚠ %WhichStep% 比對失敗！已截圖 %failName%
        FileAppend, [血壓清除] FAIL - %timeStr%`n, %testLogFile%
    }
}
; ───── 🌡️ 模組：刪除體溫資料並驗證清除 ─────
clearBodyTemperature() {
    global

    ; ✅ Step 0：聚焦 scrcpy 確保點擊有效
    WinActivate, msm8953 for arm64
    WinWaitActive, msm8953 for arm64
    Sleep, 300

    TimeStamp := A_Now
    FormatTime, timeStr, %TimeStamp%, yyyy-MM-dd HH:mm:ss

    ; ✅ Step 1：點擊體溫圖示進入紀錄頁
    Click, 502, 170
    Sleep, 3000
    
    ; ✅ Step 2：展開紀錄（向下箭頭）
    Click, 647, 713
    Sleep, 1000

    ; ✅ Step 3：點選已有的體溫資料
    Click, 534, 587
    Sleep, 1000

    ; ✅ Step 4：點擊垃圾桶圖示刪除資料
    Click, 1157, 584
    Sleep, 500

    ; ✅ Step 5：點擊 YES 確認刪除
    Click, 720, 452
    Sleep, 2000

    ; ✅ Step 6：返回主頁
    Click, 49, 71
    Sleep, 2000

    ; ✅ Step 7：比對確認體溫紀錄是否清除
    Sleep, 700
    Send, {Esc}
    WhichStep := "體溫刪除畫面確認"
    ImageSearch, tx, ty, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\body_temperature_clear.bmp

    if (ErrorLevel = 0) {
        FileAppend, [體溫清除] PASS - %timeStr%`n, %testLogFile%
    } else {
        failName := "Fail_Clear_BT_" . TimeStamp . ".bmp"
        Send, !{PrintScreen}
        Sleep, 500
        SaveClipboardImage(A_ScriptDir . "\FailShots\" . failName)
        MsgBox, 16, 錯誤通知, ⚠ %WhichStep% 比對失敗！已截圖 %failName%
        FileAppend, [體溫清除] FAIL - %timeStr%`n, %testLogFile%
    }
}
; ───── ⚖️ 模組：刪除體重資料並驗證清除 ─────
clearWeight() {
    global

    ; ✅ Step 0：聚焦 scrcpy 確保模擬點擊有效
    WinActivate, msm8953 for arm64
    WinWaitActive, msm8953 for arm64
    Sleep, 300

    TimeStamp := A_Now
    FormatTime, timeStr, %TimeStamp%, yyyy-MM-dd HH:mm:ss

    ; ✅ Step 1：點擊體重圖示進入紀錄頁
    Click, 849, 176
    Sleep, 3000
    
    ; ✅ Step 2：展開紀錄（向下箭頭）
    Click, 647, 713
    Sleep, 1000

    ; ✅ Step 3：點選體重資料
    Click, 486, 583
    Sleep, 1000

    ; ✅ Step 4：點擊垃圾桶圖示
    Click, 1157, 584
    Sleep, 500

    ; ✅ Step 5：點擊 YES 確認刪除
    Click, 720, 452
    Sleep, 2000

    ; ✅ Step 6：返回主頁
    Click, 49, 71
    Sleep, 2000

    ; ✅ Step 7：比對是否清除成功
    Sleep, 700
    Send, {Esc}
    WhichStep := "體重刪除畫面確認"
    ImageSearch, wx, wy, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\weight_clear.bmp

    if (ErrorLevel = 0) {
        FileAppend, [體重清除] PASS - %timeStr%`n, %testLogFile%
    } else {
        failName := "Fail_Clear_Weight_" . TimeStamp . ".bmp"
        Send, !{PrintScreen}
        Sleep, 500
        SaveClipboardImage(A_ScriptDir . "\FailShots\" . failName)
        MsgBox, 16, 錯誤通知, ⚠ %WhichStep% 比對失敗！已截圖 %failName%
        FileAppend, [體重清除] FAIL - %timeStr%`n, %testLogFile%
    }
}
; ───── 🩸 模組：刪除血氧資料並驗證清除 ─────
clearBloodOxygen() {
    global

    ; ✅ Step 0：聚焦 scrcpy 確保點擊生效
    WinActivate, msm8953 for arm64
    WinWaitActive, msm8953 for arm64
    Sleep, 300

    TimeStamp := A_Now
    FormatTime, timeStr, %TimeStamp%, yyyy-MM-dd HH:mm:ss

    ; ✅ Step 1：點擊血氧圖示進入紀錄頁
    Click, 811, 513
    Sleep, 3000
    
    ; ✅ Step 2：展開紀錄（向下箭頭）
    Click, 647, 713
    Sleep, 1000

    ; ✅ Step 3：點擊血氧資料項目
    Click, 552, 584
    Sleep, 1000

    ; ✅ Step 4：點擊垃圾桶圖示
    Click, 1157, 584
    Sleep, 500

    ; ✅ Step 5：點擊 YES 確認刪除
    Click, 720, 452
    Sleep, 2000

    ; ✅ Step 6：返回主畫面
    Click, 49, 71
    Sleep, 2000

    ; ✅ Step 7：畫面比對確認是否刪除成功
    Sleep, 700
    Send, {Esc}
    WhichStep := "血氧刪除畫面確認"
    ImageSearch, ox, oy, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\blood_oxygen_clear.bmp

    if (ErrorLevel = 0) {
        FileAppend, [血氧清除] PASS - %timeStr%`n, %testLogFile%
    } else {
        failName := "Fail_Clear_Oxygen_" . TimeStamp . ".bmp"
        Send, !{PrintScreen}
        Sleep, 500
        SaveClipboardImage(A_ScriptDir . "\FailShots\" . failName)
        MsgBox, 16, 錯誤通知, ⚠ %WhichStep% 比對失敗！已截圖 %failName%
        FileAppend, [血氧清除] FAIL - %timeStr%`n, %testLogFile%
    }
}
; ───── 🩹 模組：刪除健康事件資料並驗證清除 ─────
clearHealthEvent() {
    global

    ; ✅ Step 0：切換至 scrcpy 確保模擬輸入有效
    WinActivate, msm8953 for arm64
    WinWaitActive, msm8953 for arm64
    Sleep, 300

    TimeStamp := A_Now
    FormatTime, timeStr, %TimeStamp%, yyyy-MM-dd HH:mm:ss

    ; ✅ Step 1：點擊健康事件圖示進入列表
    Click, 496, 517
    Sleep, 3000
    
    ; ✅ Step 2：展開紀錄（向下箭頭）
    Click, 647, 713
    Sleep, 1000

    ; ✅ Step 3：點選健康事件紀錄項目
    Click, 581, 586
    Sleep, 1000

    ; ✅ Step 4：點擊垃圾桶圖示刪除
    Click, 1205, 585
    Sleep, 500

    ; ✅ Step 5：點擊 YES 確認刪除
    Click, 720, 452
    Sleep, 2000

    ; ✅ Step 6：點選返回按鈕
    Click, 49, 71
    Sleep, 2000

    ; ✅ Step 7：比對畫是否已清除事件
    Sleep, 700
    Send, {Esc}
    WhichStep := "健康事件刪除畫面確認"
    ImageSearch, ex, ey, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\health_event_clear.bmp

    if (ErrorLevel = 0) {
        FileAppend, [健康事件清除] PASS - %timeStr%`n, %testLogFile%
    } else {
        failName := "Fail_Clear_Event_" . TimeStamp . ".bmp"
        Send, !{PrintScreen}
        Sleep, 500
        SaveClipboardImage(A_ScriptDir . "\FailShots\" . failName)
        MsgBox, 16, 錯誤通知, ⚠ %WhichStep% 比對失敗！已截圖 %failName%
        FileAppend, [健康事件清除] FAIL - %timeStr%`n, %testLogFile%
    }
}
; ───── ❤️ 模組：刪除心跳資料並驗證清除 ─────
clearHeartRate() {
    global

    ; ✅ Step 0：聚焦 scrcpy
    WinActivate, msm8953 for arm64
    WinWaitActive, msm8953 for arm64
    Sleep, 300

    TimeStamp := A_Now
    FormatTime, timeStr, %TimeStamp%, yyyy-MM-dd HH:mm:ss

    ; ✅ Step 1：點擊心跳圖示進入紀錄頁
    Click, 154, 487
    Sleep, 3000
    
    ; ✅ Step 2：展開紀錄（向下箭頭）
    Click, 647, 713
    Sleep, 1000

    ; ✅ Step 3：選擇紀錄資料
    Click, 545, 586
    Sleep, 1000

    ; ✅ Step 4：點擊垃圾桶
    Click, 1157, 584
    Sleep, 500

    ; ✅ Step 5：點擊 YES 確認刪除
    Click, 720, 452
    Sleep, 2000

    ; ✅ Step 6：返回主頁
    Click, 49, 71
    Sleep, 2000

    ; ✅ Step 7：比對是否清除成功
    Sleep, 700
    Send, {Esc}
    WhichStep := "心跳刪除畫面確認"
    ImageSearch, hx, hy, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\heart_rate_clear.bmp

    if (ErrorLevel = 0) {
        FileAppend, [心跳清除] PASS - %timeStr%`n, %testLogFile%
    } else {
        failName := "Fail_Clear_Heart_" . TimeStamp . ".bmp"
        Send, !{PrintScreen}
        Sleep, 500
        SaveClipboardImage(A_ScriptDir . "\FailShots\" . failName)
        MsgBox, 16, 錯誤通知, ⚠ %WhichStep% 比對失敗！已截圖 %failName%
        FileAppend, [心跳清除] FAIL - %timeStr%`n, %testLogFile%
    }
}
; ───── 🧼 主控模組：清除所有模組並做 7+1 檢查點 ─────
clearAllHealthData() {
    global
    TimeStamp := A_Now
    FormatTime, timeStr, %TimeStamp%, yyyy-MM-dd HH:mm:ss

    ; 清除模組清單與對應圖檔設定
    modules := ["BloodPressure", "BodyTemperature", "Weight", "BloodOxygen", "HeartRate", "HealthEvent"]
    checks := ["blood_pressure_check", "body_temperature_check", "weight_check", "blood_oxygen_check", "heart_rate_check", "health_event_check"]
    clears := ["clearBloodPressure", "clearBodyTemperature", "clearWeight", "clearBloodOxygen", "clearHeartRate", "clearHealthEvent"]

    Loop, % modules.MaxIndex()
    {
        mod := modules[A_Index]
        img := checks[A_Index]
        func := clears[A_Index]

        ImageSearch, dx, dy, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\%img%.bmp
        if (ErrorLevel != 0) {
            FileAppend, [%mod% 清除] 略過（無資料） - %timeStr%`n, %testLogFile%
            continue
        }

        ; 呼叫模組清除
        %func%()
    }

    ; ✅ Step 7：總驗證所有資料皆清除
    Sleep, 1000
    Send, {Esc}
    WhichStep := "總清除結果驗證"
    ImageSearch, fx, fy, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\final_clear_check.bmp

    if (ErrorLevel = 0) {
        FileAppend, [總清除驗證] PASS - %timeStr%`n, %testLogFile%
    } else {
        failName := "Fail_Clear_Final_" . TimeStamp . ".bmp"
        Send, !{PrintScreen}
        Sleep, 500
        SaveClipboardImage(A_ScriptDir . "\FailShots\" . failName)
        MsgBox, 16, 錯誤通知, ⚠ %WhichStep% 比對失敗！已截圖 %failName%
        FileAppend, [總清除驗證] FAIL - %timeStr%`n, %testLogFile%
        return
    }

    ; ✅ Step 8：點擊返回主頁面按鈕
    Click, 48, 69
    Sleep, 2000

    ; ✅ Step 9：確認是否已返回主畫面
    WhichStep := "主頁畫面確認"
    ImageSearch, mx, my, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *90 %A_ScriptDir%\Images\main_home_check.bmp

    if (ErrorLevel = 0) {
        FileAppend, [主頁確認] PASS - %timeStr%`n, %testLogFile%
        
        ; ✅ 只在最後一輪顯示完成訊息
        if (runIndex = runTotal)
            MsgBox, 64, 流程結束, ✅ 所有項目已完成清除流程，成功返回主畫面！
    } else {
        failName := "Fail_Main_Return_" . TimeStamp . ".bmp"
        Send, !{PrintScreen}
        Sleep, 500
        SaveClipboardImage(A_ScriptDir . "\FailShots\" . failName)
        MsgBox, 16, 錯誤通知, ⚠ %WhichStep% 失敗！已截圖 %failName%
        FileAppend, [主頁確認] FAIL - %timeStr%`n, %testLogFile%
    }

}

; ───── 📷 剪貼簿圖片儲存為 BMP ─────
SaveClipboardImage(SavePath) {
    ; ✅ 從剪貼簿取得 Bitmap 資料並儲存成檔案
    if !DllCall("OpenClipboard", "ptr", 0)
        return false
    hBitmap := DllCall("GetClipboardData", "uint", 2, "ptr")
    DllCall("CloseClipboard")
    if !hBitmap
        return false
    pBitmap := Gdip_CreateBitmapFromHBITMAP(hBitmap)
    Gdip_SaveBitmapToFile(pBitmap, SavePath)
    Gdip_DisposeImage(pBitmap)
    return true
}
