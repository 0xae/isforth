.ONESHELL:

ASSEMBLER = nasm  -felf32 

all: 
	make kernel

kernel.o:
	cd src/kernel
	$(ASSEMBLER) isforth.asm -o ../kernel.o

kernel: kernel.o
	cd src/kernel
	ld -O2 -m elf_i386 ldscript -o../../kernel.com ../kernel.o &&\
	strip -R .comment ../../kernel.com			   

clean:
	@
	rm -f src/kernel.o  &&\
	rm -f kernel.com    &&\
	rm -f isforth       &&\
	rm -f *~ */*~ */*/*~ */*/*/*~	 */*/*/*/*~    &&\
	echo -e "\E[33;1m [ok] clean directory \E[0m"
