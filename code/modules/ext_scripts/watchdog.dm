var/global/datum/watchdog/watchdog = new

/datum/watchdog
	var/waiting=0 // Waiting for the server to end round or empty.
	var/const/update_signal_file="data/UPDATE_READY.txt"
	var/const/server_signal_file="data/SERVER_READY.txt"
	var/map_path

/datum/watchdog/proc/check_for_update()
	if(waiting)
		return
	if(fexists(update_signal_file) == 1)
		waiting=1
		testing("[time_stamp()] - Watchdog has detected an update.")
		to_chat(world, "<span class='notice'>\[AUTOMATIC ANNOUNCEMENT\] Update received.  Server will restart automatically after the round ends.</span>")
		send2mainirc("Update received.  Server will restart automatically after the round ends.")
		send2maindiscord("**Update received.**  Server will restart automatically after the round ends.")

/datum/watchdog/proc/signal_ready() //This apparently uses some magic non-DM thing that kills the server process directly.
	world.pre_shutdown()
	testing("[time_stamp()] - Watchdog has sent the 'ready' signal. Bye!")
	var/signal = file(server_signal_file)
	fdel(signal)
	signal << map_path

/client/proc/watchdog_force_restart()
	set name = "Panic Restart"
	set category = "Watchdog"

	log_admin("[key] has restarted the server using the watchdog function")
	message_admins("[key] has restarted the server using the watchdog function")
	force_restart = 1
