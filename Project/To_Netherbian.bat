for /r %%v in (*.pl) do (
	scp "%%v" eqemu@192.168.56.3:server/quests/netherbian/
)

pause