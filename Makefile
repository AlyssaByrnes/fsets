##############################################################################
##                 The Calculus of Inductive Constructions                  ##
##                                                                          ##
##                                Projet Coq                                ##
##                                                                          ##
##                     INRIA                        ENS-CNRS                ##
##              Rocquencourt                        Lyon                    ##
##                                                                          ##
##                                  Coq V7                                  ##
##                                                                          ##
##                                                                          ##
##############################################################################

# WARNING
#
# This Makefile has been automagically generated by coq_makefile
# Edit at your own risks !
#
# END OF WARNING

#
# This Makefile was generated by the command line :
# coq_makefile -f Make -o Makefile 
#

##########################
#                        #
# Variables definitions. #
#                        #
##########################

CAMLP4LIB=`camlp4 -where`
COQSRC=-I $(COQTOP)/kernel -I $(COQTOP)/lib \
  -I $(COQTOP)/library -I $(COQTOP)/parsing \
  -I $(COQTOP)/pretyping -I $(COQTOP)/interp \
  -I $(COQTOP)/proofs -I $(COQTOP)/syntax -I $(COQTOP)/tactics \
  -I $(COQTOP)/toplevel -I $(COQTOP)/contrib/correctness \
  -I $(COQTOP)/contrib/extraction -I $(COQTOP)/contrib/field \
  -I $(COQTOP)/contrib/fourier -I $(COQTOP)/contrib/graphs \
  -I $(COQTOP)/contrib/interface -I $(COQTOP)/contrib/jprover \
  -I $(COQTOP)/contrib/omega -I $(COQTOP)/contrib/romega \
  -I $(COQTOP)/contrib/ring -I $(COQTOP)/contrib/xml \
  -I $(CAMLP4LIB)
ZFLAGS=$(OCAMLLIBS) $(COQSRC)
OPT=
COQFLAGS=-q $(OPT) $(COQLIBS) $(OTHERFLAGS) $(COQ_XML)
COQC=$(COQBIN)coqc
GALLINA=gallina
COQDOC=coqdoc
CAMLC=ocamlc -c
CAMLOPTC=ocamlopt -c
CAMLLINK=ocamlc
CAMLOPTLINK=ocamlopt
COQDEP=$(COQBIN)coqdep -c
GRAMMARS=grammar.cma
CAMLP4EXTEND=pa_extend.cmo pa_ifdef.cmo q_MLast.cmo
PP=-pp "camlp4o -I . -I $(COQTOP)/parsing $(CAMLP4EXTEND) $(GRAMMARS) -impl"

#########################
#                       #
# Libraries definition. #
#                       #
#########################

OCAMLLIBS=-I .
COQLIBS=-I .

###################################
#                                 #
# Definition of the "all" target. #
#                                 #
###################################

VFILES=MoreList.v\
  Lib.v\
  OrderedType.v\
  DecidableType.v\
  Int.v\
  FSetBridge.v\
  FSetInterface.v\
  FSetList.v\
  FSetFacts.v\
  FSetEqProperties.v\
  FSetProperties.v\
  FSetWeakInterface.v\
  FSetWeakList.v\
  FMapInterface.v\
  FMapList.v\
  FMapAVL.v\
  FMapWeakInterface.v\
  FMapWeakList.v\
  FSetRBT.v\
  FSetAVL.v\
  FSetAVL_nodep.v\
  FSetAVL_int.v\
  FSet.v\
  extract.v
VOFILES=$(VFILES:.v=.vo)
VIFILES=$(VFILES:.v=.vi)
GFILES=$(VFILES:.v=.g)
HTMLFILES=$(VFILES:.v=.html)
GHTMLFILES=$(VFILES:.v=.g.html)

all: MoreList.vo\
  Lib.vo\
  OrderedType.vo\
  DecidableType.vo\
  Int.vo\
  FSetBridge.vo\
  FSetInterface.vo\
  FSetList.vo\
  FSetFacts.vo\
  FSetEqProperties.vo\
  FSetProperties.vo\
  FSetWeakInterface.vo\
  FSetWeakList.vo\
  FMapInterface.vo\
  FMapList.vo\
  FMapAVL.vo\
  FMapWeakInterface.vo\
  FMapWeakList.vo\
  FSetRBT.vo\
  FSetAVL.vo\
  FSetAVL_nodep.vo\
  FSetAVL_int.vo\
  FSet.vo\
  extract.vo\
  PrecedenceGraph

spec: $(VIFILES)

gallina: $(GFILES)

html: $(HTMLFILES)

gallinahtml: $(GHTMLFILES)

all.ps: $(VFILES)
	$(COQDOC) -ps -o $@ `$(COQDEP) -sort -suffix .v $(VFILES)`

all-gal.ps: $(VFILES)
	$(COQDOC) -ps -g -o $@ `$(COQDEP) -sort -suffix .v $(VFILES)`



###################
#                 #
# Subdirectories. #
#                 #
###################

PrecedenceGraph:
	cd PrecedenceGraph ; $(MAKE) all

####################
#                  #
# Special targets. #
#                  #
####################

.PHONY: all opt byte archclean clean install depend html PrecedenceGraph

.SUFFIXES: .v .vo .vi .g .html .tex .g.tex .g.html

.v.vo:
	$(COQC) $(COQDEBUG) $(COQFLAGS) $*

.v.vi:
	$(COQC) -i $(COQDEBUG) $(COQFLAGS) $*

.v.g:
	$(GALLINA) $<

.v.tex:
	$(COQDOC) -latex $< -o $@

.v.html:
	$(COQDOC) -html $< -o $@

.v.g.tex:
	$(COQDOC) -latex -g $< -o $@

.v.g.html:
	$(COQDOC) -html -g $< -o $@

byte:
	$(MAKE) all "OPT="

opt:
	$(MAKE) all "OPT=-opt"

include .depend

.depend depend:
	rm -f .depend
	$(COQDEP) -i $(COQLIBS) $(VFILES) *.ml *.mli >.depend
	$(COQDEP) $(COQLIBS) -suffix .html $(VFILES) >>.depend
	(cd PrecedenceGraph ; $(MAKE) depend)

install:
	mkdir -p `$(COQC) -where`/user-contrib
	cp -f $(VOFILES) `$(COQC) -where`/user-contrib
	(cd PrecedenceGraph ; $(MAKE) install)

Makefile: Make
	mv -f Makefile Makefile.bak
	$(COQBIN)coq_makefile -f Make -o Makefile

	(cd PrecedenceGraph ; $(MAKE) Makefile)

clean:
	rm -f *.cmo *.cmi *.cmx *.o $(VOFILES) $(VIFILES) $(GFILES) *~
	rm -f all.ps all-gal.ps $(HTMLFILES) $(GHTMLFILES)
	(cd PrecedenceGraph ; $(MAKE) clean)

archclean:
	rm -f *.cmx *.o
	(cd PrecedenceGraph ; $(MAKE) archclean)

html:
	(cd PrecedenceGraph ; $(MAKE) html)

# WARNING
#
# This Makefile has been automagically generated by coq_makefile
# Edit at your own risks !
#
# END OF WARNING

