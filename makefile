
# Manual Build 1nvader
# 
# The Mads build from WUDSN/Eclipse is perfectly fine, so 
# what are you doing poking aabout in here?

all: ata_invader.xex


clean:
	rm -f *.lab *.lst *.xex


ata_invader.xex: $(*.asm) 
	mads ata_1nvader.asm -o:ata_1nvader.xex -p -t:ata_1nvader.lab -l:ata_1nvader.lst 

