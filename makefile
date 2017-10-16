default: build

build: 
	flex shermank.l
	bison shermank.y
	g++ shermank.tab.c -o mfpl_parser
