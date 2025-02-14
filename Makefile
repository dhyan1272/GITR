.SUFFIXES:
.SUFFIXES: .c .cpp .cu

USECUDA := 1
USEMPI := 0

USE_BOOST := 0

USEIONIZATION := 1
USERECOMBINATION := 0
USEPERPDIFFUSION := 0
USECOULOMBCOLLISIONS := 0
USETHERMALFORCE := 0
USESURFACEMODEL :=0
USESHEATHEFIELD := 1
USEPRESHEATHEFIELD :=0

#Interpolators 0=Constant 1=Analytic Equation 2=2dInterpolation 3=3dInterpolation 
# 4=Combination of 2d interpolation and analytic functions
BFIELD_INTERP :=2
EFIELD_INTERP :=1
PRESHEATH_INTERP :=2
DENSITY_INTERP :=0
TEMP_INTERP :=0
GRADT_INTERP :=2
FLOWV_INTERP :=4
#ode integrator 0=Boris 1=RK4
ODEINT :=0
#hold random number generator seeds the same across runs (defined in gitrInput.cfg)
FIXEDSEEDS :=1

#Set all above operators to 0 to trace Geometry
GEOM_TRACE :=0

#Set USECUDA = 0 to use PARTICLE_TRACKS
PARTICLE_TRACKS :=0

#Particle Source 0 = puffing 1=Line Boundary segments
PARTICLE_SOURCE :=1

#Set periodic = 0 in gitrGeometry.cfg to use cylindrical symmetry
USECYLSYMM = 1

NAME := bin/GITR

INCLUDEFLAGS :=  
LIBS :=  

CC := gcc
CPP := g++
NVCC := nvcc

MODULES := src include

#CFLAGS += $(INCLUDEFLAGS) -g
#CXXFLAGS += $(INCLUDEFLAGS) -g
#NVCCFLAGS += $(INCLUDEFLAGS) -g -G

# Machine specific makefile settings

ThisMachine := $(shell uname -n)
include makefiles/Makefile.$(ThisMachine)

CPPFLAGS:=
CPPFLAGS+= -DUSEMPI=${USEMPI}
CPPFLAGS+= -DUSEIONIZATION=${USEIONIZATION}
CPPFLAGS+= -DUSERECOMBINATION=${USERECOMBINATION}
CPPFLAGS+= -DUSEPERPDIFFUSION=${USEPERPDIFFUSION}
CPPFLAGS+= -DUSECOULOMBCOLLISIONS=${USECOULOMBCOLLISIONS}
CPPFLAGS+= -DUSETHERMALFORCE=${USETHERMALFORCE}
CPPFLAGS+= -DUSESURFACEMODEL=${USESURFACEMODEL}
CPPFLAGS+= -DUSESHEATHEFIELD=${USESHEATHEFIELD}
CPPFLAGS+= -DUSEPRESHEATHEFIELD=${USEPRESHEATHEFIELD}
CPPFLAGS+= -DUSECYLSYMM=${USECYLSYMM}
CPPFLAGS+= -DGEOM_TRACE=${GEOM_TRACE}
CPPFLAGS+= -DPARTICLE_TRACKS=${PARTICLE_TRACKS}
CPPFLAGS+= -DBFIELD_INTERP=${BFIELD_INTERP}
CPPFLAGS+= -DEFIELD_INTERP=${EFIELD_INTERP}
CPPFLAGS+= -DPRESHEATH_INTERP=${PRESHEATH_INTERP}
CPPFLAGS+= -DTEMP_INTERP=${TEMP_INTERP}
CPPFLAGS+= -DDENSITY_INTERP=${DENSITY_INTERP}
CPPFLAGS+= -DFLOWV_INTERP=${FLOWV_INTERP}
CPPFLAGS+= -DGRADT_INTERP=${GRADT_INTERP}
CPPFLAGS+= -DODEINT=${ODEINT}
CPPFLAGS+= -DFIXEDSEEDS=${FIXEDSEEDS}
CPPFLAGS+= -DPARTICLE_SOURCE=${PARTICLE_SOURCE}
CPPFLAGS+= -std=c++11
CPPFLAGS+= -DUSE_BOOST=${USE_BOOST}

#CPPFLAGS+= -DTHRUST_DEBUG

# You shouldn't have to go below here
#
# DLG: 	Added the -x c to force c file type so that 
# 		the .cu files will work too :)

DIRNAME = `dirname $1`
MAKEDEPS = gcc -MM -MG $2 -x c $3 | sed -e "s@^\(.*\)\.o:@.dep/$1/\1.d obj/$1/\1.o:@"
#MAKEDEPS = ${CC} -MM -MG $2 -x c $3 | sed -e "s@^\(.*\)\.o:@.dep/$1/\1.d obj/$1/\1.o:@"

.PHONY : all

all : $(NAME)

# look for include files in each of the modules
INCLUDEFLAGS += $(patsubst %, -I%, $(MODULES))

CFLAGS += $(INCLUDEFLAGS)
CXXFLAGS += $(INCLUDEFLAGS) 
NVCCFLAGS += $(INCLUDEFLAGS) 

# determine the object files
SRCTYPES := c cpp cu
LINK := $(CPP) ${CXXFLAGS} ${LFLAGS}

ifeq ($(USECUDA),1)
LINK := $(NVCC) ${NVCCFLAGS} ${LFLAGS}
else
NVCCFLAGS+= --x c++
endif

OBJ := $(foreach srctype, $(SRCTYPES), $(patsubst %.$(srctype), obj/%.o, $(wildcard $(patsubst %, %/*.$(srctype), $(MODULES)))))

# link the program
$(NAME) : $(OBJ)
	$(LINK) -o $@ $(OBJ) $(LIBS)

# calculate include dependencies
.dep/%.d : %.cpp
	@mkdir -p `echo '$@' | sed -e 's|/[^/]*.d$$||'`
	$(call MAKEDEPS,$(call DIRNAME, $<), $(INCLUDEFLAGS), $<) > $@

obj/%.o : %.cpp
	@mkdir -p `echo '$@' | sed -e 's|/[^/]*.o$$||'`
	$(CPP) $(CXXFLAGS) ${CPPFLAGS} -c -o $@ $<

.dep/%.d : %.c
	@mkdir -p `echo '$@' | sed -e 's|/[^/]*.d$$||'`
	$(call MAKEDEPS,$(call DIRNAME, $<), $(CFLAGS), $<) > $@

obj/%.o : %.c
	@mkdir -p `echo '$@' | sed -e 's|/[^/]*.o$$||'`
	$(CC) $(CFLAGS) -c -o $@ $<

.dep/%.d : %.cu
	@mkdir -p `echo '$@' | sed -e 's|/[^/]*.d$$||'`
	$(call MAKEDEPS,$(call DIRNAME, $<), $(INCLUDEFLAGS), $<) > $@

obj/%.o : %.cu
	@mkdir -p `echo '$@' | sed -e 's|/[^/]*.o$$||'`
	$(NVCC) $(NVCCFLAGS) ${CPPFLAGS} -dc -o $@ $<


# include the C include dependencies
DEP := $(patsubst obj/%.o, .dep/%.d, $(OBJ))

ifneq ($(MAKECMDGOALS),clean)
include $(DEP)
endif

clean:
	-@rm $(NAME) $(OBJ) $(DEP) .dep/src/*

