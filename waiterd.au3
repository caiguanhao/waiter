AutoItSetOption("TrayIconHide", 1)

While 1
  If Not ProcessExists("waiter.exe") Then
    Sleep(3000)
    Run(@ComSpec & ' /c "waiter.exe"', "", @SW_HIDE)
    Sleep(3000)
  EndIf
  Sleep(3000)
Wend
