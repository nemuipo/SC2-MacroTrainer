﻿pSend(Sequence := "", newKeyDelay := "", newClickDelay := "")
{
	Global GameIdentifier
	static WM_KEYDOWN := 0x100, WM_KEYUP := 0x101, WM_CHAR := 0x102, pKeyDelay := -1, pClickDelay := -1

	if newKeyDelay is integer
		pKeyDelay :=  newKeyDelay
	if newClickDelay is integer
		pClickDelay :=  newClickDelay

	SetFormat, IntegerFast, hex
	aSend := []
	C_Index := 1
;	StringReplace, Sequence, Sequence, %A_Space% ,, All ;stuffs up {shift down}
	StringReplace, Sequence, Sequence, `t , %A_Space%, All 
	Currentmodifiers := []
	length := strlen(Sequence) 
	while (C_Index <= length)
	{
		char := SubStr(Sequence, C_Index, 1)
		if (char = " ")
		{
			C_Index++
			continue
		}
		if char in +,^,!
		{		
			if (char = "+")
				Modifier := GetKeyVK("Shift"), ModiferSc := GetKeySC("Shift")
			else if (char = "^")
				Modifier := GetKeyVK("Ctrl"), ModiferSc := GetKeySC("Ctrl")
			else if (char = "!")
				Modifier := GetKeyVK("Alt"), ModiferSc := GetKeySC("Alt")

			CurrentmodifierString .= char
			Currentmodifiers.insert( {"wParam": Modifier 
							, "sc": ModiferSc})
				

			aSend.insert({	  "message": WM_KEYDOWN
							, "sc": ModiferSc
							, "wParam": Modifier})
			C_Index++
			continue
			
		}
		if (char = "{") 							; send {}} will fail with this test but cant use that
		{ 												; hotkey anyway in program would be ]
			if (Position := instr(Sequence, "}", False, C_Index, 1)) ; lets find the closing bracket) n
			{
				key := trim(substr(Sequence, C_Index+1, Position -  C_Index - 1))
				C_Index := Position ;PositionOfClosingBracket
				while (if instr(key, A_space A_space))
					StringReplace, key, key, %A_space%%A_space%, %A_space%, All
							
				if instr(key, "click")
				{
				   	StringSplit, clickOutput, key, %A_space%, %A_Space%%A_Tab%`,
				    numbers := []
				    SetFormat, IntegerFast, d ; otherwise A_Index is 0x and doesnt work with var%A_Index%
				    loop, % clickOutput0
				    {
				    	command := clickOutput%A_index% 
				        if command is integer
				            numbers.insert(command)    
				    }
				   
				    if (!numbers.maxindex() || numbers.maxindex() = 1)
				    {
				        MouseGetPos, x, y  ; will cause problems if send hex number to insertpClickObject
				        clickCount := numbers.maxindex() = 1 ? numbers.1 : 1
				    }
				    else if (numbers.maxindex() = 2 || numbers.maxindex() = 3)
				        x := numbers.1, y := numbers.2, clickCount := numbers.maxindex() = 3 ? numbers.3 : 1
				    else 
				    {
				    	SetFormat, IntegerFast, hex
				    	continue ; error
				    }	 
				    SetFormat, IntegerFast, hex

			;	   msgbox % key "`n" x ", " y "`n" clickCount

				    insertpClickObject(aSend, key, x, y, clickCount, CurrentmodifierString)
				}
				else 
				{
					StringSplit, outputKey, key, %A_Space%
					if (outputKey0 = 2)
					{

						if instr(outputKey2, "Down")
							aSend.insert({	  "message": WM_KEYDOWN
											, "sc": GetKeySC(outputKey1)
											, "wParam": GetKeyVK(outputKey1)})
						else if instr(outputKey2, "Up")
							aSend.insert({	  "message": WM_KEYUP
											, "sc": GetKeySC(outputKey1)
											, "wParam": GetKeyVK(outputKey1)})					
					}
					else 
					{				
						aSend.insert({	  "message": WM_KEYDOWN
										, "sc": GetKeySC(outputKey1)
										, "wParam": GetKeyVK(outputKey1)})

						aSend.insert({	  "message": WM_KEYUP
										, "sc": GetKeySC(outputKey1)
										, "wParam": GetKeyVK(outputKey1)})
					}
				}
			}
		}
		Else
		{
			aSend.insert({	  "message": WM_KEYDOWN
							, "sc": GetKeySC(char)
							, "wParam": GetKeyVK(char)})


			aSend.insert({	  "message": WM_KEYUP
							, "sc": GetKeySC(char)
							, "wParam": GetKeyVK(char)})
		}
	
		if Modifier
		{
			for index, modifier in Currentmodifiers
				aSend.insert({	  "message": WM_KEYUP
								, "sc": modifier.sc
								, "wParam": modifier.wParam})
			Modifier := False
			CurrentmodifierString := ""
		}
		C_Index++
	}
	SetFormat, IntegerFast, d

	for index, message in aSend
	{
		
		if (WM_KEYDOWN = message.message)
		{
			 ; repeat code | (scan code << 16)
			lparam := 1 | (message.sc << 16)
			postmessage, message.message, message.wParam, lparam,, % GameIdentifier

		}
		else if (WM_KEYUP = message.message)
		{
			lparam := 1 | (message.sc << 16) | (1 << 31) ; transition state
			postmessage, message.message, message.wParam, lparam,, % GameIdentifier
		}
		else 
		{
			postmessage, message.message, message.wParam, message.lparam,, % GameIdentifier
			if (pClickDelay != -1)
				DllCall("Sleep", Uint, pClickDelay)
			continue
		}
		if (pKeyDelay != -1)
			DllCall("Sleep", Uint, pKeyDelay)
	}
	return aSend
}

