#!/bin/zsh -f


# shell script name: nyquist.zsh  
# shell script function: Match Audio MIDI sampling frequency to that of
# the current track in iTunes, and if a change is required, restart iTunes
# track at the beginning in the original playlist.

# Many thanks to "red menace" of the Apple bulletin board community and
# many others for helpful suggestions and input.

version="0.0.3"

# revision 0.0.3 addresses a problem created by the use of commas as
# decimal points in Audio MIDI (eg: hiface).

# Put this file in /Library/iTunes/etc
# and the accompanying Plug-in into /Library/iTunes/iTunes Plug-ins 
# or ~/Library/iTunes/iTunes Plug-ins
#  Open iTunes and set the visualizer to use "iTunesPlugIn".


###############################################################################
 
#  Created by William G. Scott on Sept 15, 2010.
#  Copyright (c) . All rights reserved.


#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
#    USA
#    
#    cf. URL:   http://www.fsf.org/licensing/licenses/gpl.html
#
###############################################################################


osascript <<-eof
property upArrow : ASCII character 30
property downArrow : ASCII character 31

if application "iTunes" is not running then return -- 10.5 + (doesn't launch application)
-- no point in running this script if iTunes is not playing a track.
tell application "iTunes"
	if player state is not playing then return
	set desiredRate to sample rate of current track -- get the sample frequency (sample rate) of current track
	set playlistID to get persistent ID of current playlist -- remember it so we can restart iTunes and play
	set trackID to get persistent ID of current track -- it again from the beginning
end tell

tell application "Audio MIDI Setup" to activate
tell application "System Events"
	
	tell application process "Audio MIDI Setup"
		try -- make sure window is there
			click menu item "Show Audio Window" of menu "Window" of menu bar item "Window" of menu bar 1
		end try
		set comboBox to combo box 1 of group 1 of tab group 1 of group 1 of window "Audio Devices"
		set currentRate to (text 1 thru -3 of first word of (get value of comboBox)) as number
		-- strip off Hz and the decimal point which can sometimes be a comma (.0 and ,0 are removed)
		if desiredRate is not currentRate then
			tell application "iTunes" to pause -- avoid listening to clicking when sampling frequency changes
			click button 1 of comboBox -- perform action "AXPress" to drop the list
			set theChoices to value of text fields of list 1 of scroll area 1 of comboBox -- get all the values
			keystroke upArrow using {option down} -- up to the top
			repeat with anItem in theChoices -- step down through the combo box menu
				set anItem to (text 1 thru -3 of first word of anItem) as number
				if anItem ≥ desiredRate then exit repeat
				keystroke downArrow -- down arrow
			end repeat
			keystroke return -- select and dismiss the list
			tell application "iTunes" to quit -- we have to quit and restart iTunes for it to use the new sample freq
			delay 5 -- iTunes reopens automatically (why?), but we need to give it a chance to get going
			tell application "iTunes"
				activate
				set thePlaylist to some playlist whose persistent ID is playlistID
				play (some track of thePlaylist whose persistent ID is trackID)
				-- start replaying the same track from the same playlist 
			end tell
		end if
		set visible to false -- hiding window will bring it to view when activated
	end tell
	
end tell

eof