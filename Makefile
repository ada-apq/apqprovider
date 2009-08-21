# Makefile for the APQ_Provider
#
# @author Marcelo Coraça de Freitas <marcelo@kow.com.br> 

VERSION=0.1.0

ifndef ($(PREFIX))
	PREFIX=/usr/local
endif
INCLUDE_PREFIX=$(PREFIX)/include/apqprovider
LIB_PREFIX=$(PREFIX)/lib
GPR_PREFIX=$(LIB_PREFIX)/gnat



projectFile="apq_provider.gpr"


all: libs 


libs:
	gnatprep "-Dversion=\"$(version)\"" ${projectFile}{.in,}
	VERSION=$(VERSION) gnatmake -P ${projectFile}


clean: gprclean
	gnatclean -P ${projectFile}
	@echo "All clean"

docs:
	@-./gendoc.sh
	@echo "The documentation is generated by a bash script. Then it might fail in other platforms"


gprfile:
	@echo "Preparing GPR file.."
	@echo version:=\"$(VERSION)\" > gpr/apq.def
	@echo prefix:=\"$(PREFIX)\" >> gpr/apq.def
	@gnatprep gpr/apq_provider.gpr.in gpr/apq_provider.gpr gpr/apq.def

gprclean:
	@rm -f gpr/*gpr
	@rm -f gpr/*.def


install: gprfile
	@echo "Installing files"
	install -d $(INCLUDE_PREFIX)
	install -d $(LIB_PREFIX)
	install -d $(GPR_PREFIX)
	install src*/* -t $(INCLUDE_PREFIX)
	install lib/* -t $(LIB_PREFIX)
	install gpr/*.gpr -t $(GPR_PREFIX)
	make gprclean

