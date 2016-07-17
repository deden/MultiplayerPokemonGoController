tell application "System Events" to tell process "Xcode"
	click menu item -3 of menu 1 of menu bar item "Window" of menu bar 1
    click menu item "pokemonLocation" of menu 1 of menu item "Simulate Location" of menu 1 of menu bar item "Debug" of menu bar 1

	delay 0.1

	click menu item -1 of menu 1 of menu bar item "Window" of menu bar 1
    click menu item "pokemonLocation" of menu 1 of menu item "Simulate Location" of menu 1 of menu bar item "Debug" of menu bar 1
    delay 0.1
end tell