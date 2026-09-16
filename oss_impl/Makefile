synth.json: synth.ys
	yosys -l synth.log synth.ys

pnr.json: synth.json
	nextpnr-himbaechel --json synth.json --write pnr.json --report pnr_rpt.json --detailed-timing-report --device GW2A-LV18PG256C8/I7 --vopt cst=CGoL.cst --vopt family=GW2A-18C  

pack.fs: pnr.json
	gowin_pack ./pnr.json  --device GW2A-18C --sspi_as_gpio


.PHONY: synth
synth: synth.json

.PHONY: pnr
pnr: pnr.json

.PHONY: all
all: synth pnr pack.fs

.PHONY: flash
flash: pack.fs
	openFPGALoader -f -btangprimer20k ./pack.fs 

.PHONY: clean
clean:
	rm -f pnr_rpt.json pnr.json synth.json pack.fs synth.log