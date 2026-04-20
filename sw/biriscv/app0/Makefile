
#Taget Binary Name
TARGET      = proj0

# List all the source files here
C_SOURCES    += main.c
C_SOURCES    += syscalls.c
C_SOURCES    += vector_table.c
S_SOURCES    += start.s
#S_SOURCES    += vector.s

#SOURCES  = $(wildcard src/*.c)

# Includes are located in the Include directory
INCLUDES    = -Isrc/include -I../

# Path to the root of your ARM toolchain
TOOL        = /opt/riscv/

# Location of a loader script, doesnt matter which one, they're the same
LD_SCRIPT   = linker.ld

# Object File Directory, keeps things tidy
C_OBJECTS   = $(patsubst %.o, .build/%.o,$(C_SOURCES:.c=.o))
S_OBJECTS   = $(patsubst %.o, .build/%.o,$(S_SOURCES:.s=.o))
ASMS        = $(patsubst %.s, .build/%.s,$(C_SOURCES:.c=.s))



# Remove # to enable verbose
VERBOSE     = #1


# Flag Definitions
###############################################################################
CFLAGS     += -Os
CFLAGS     += -ffunction-sections
CFLAGS     += -fdata-sections
CFLAGS     += -march=rv32im_zicsr
CFLAGS     += -mabi=ilp32
CFLAGS     += -MD
#CFLAGS     += -std=c99
#CFLAGS     += -Wall
#CFLAGS     += -pedantic
CFLAGS     += -Dgcc
CFLAGS     += $(INCLUDES)


LIBS        += /opt/riscv/riscv64-unknown-elf/lib/rv32im/ilp32/libc_nano.a
LIBS        += /opt/riscv/riscv64-unknown-elf/lib/rv32im/ilp32/libm_nano.a

LDFLAGS    += -T $(LD_SCRIPT)
LDFLAGS    += --entry _start
#LDFLAGS    += --gc-sections
LDFLAGS    += -Map .build/$(TARGET).map
LDFLAGS    += --cref
#LDFLAGS    += -nostdlib
LDFLAGS    += -A rv32im
LDFLAGS    += -b elf32-littleriscv

###############################################################################

# elf64-littleriscv
# elf32-littleriscv
# elf32-bigriscv
# elf64-bigriscv
# pei-riscv64-little
# elf64-little
# elf64-big
# elf32-little
# elf32-big
# srec
# symbolsrec
# verilog
# tekhex
# binary
# ihex
# plugin

# Tool Definitions
###############################################################################
CC          = $(TOOL)/bin/riscv64-unknown-elf-gcc
LD          = $(TOOL)/bin/riscv64-unknown-elf-ld
AR          = $(TOOL)/bin/riscv64-unknown-elf-ar
AS          = $(TOOL)/bin/riscv64-unknown-elf-as
NM          = $(TOOL)/bin/riscv64-unknown-elf-nm
OBJCOPY     = $(TOOL)/bin/riscv64-unknown-elf-objcopy
OBJDUMP     = $(TOOL)/bin/riscv64-unknown-elf-objdump
RANLIB      = $(TOOL)/bin/riscv64-unknown-elf-ranlib
STRIP       = $(TOOL)/bin/riscv64-unknown-elf-strip
SIZE        = $(TOOL)/bin/riscv64-unknown-elf-size
READELF     = $(TOOL)/bin/riscv64-unknown-elf-readelf
DEBUG       = $(TOOL)/bin/riscv64-unknown-elf-gdb

CP          = cp -p
RM          = rm -rf
MV          = mv
MKDIR       = mkdir -p
###############################################################################


# Command Definitions, Leave it alone unless you hate yourself.
###############################################################################
all: dirs $(ASMS) .build/$(TARGET).elf size

asm: $(ASMS)

# Compiler Command
.build/%.o: src/%.c
	@if [ 'x${VERBOSE}' = x ];                                                \
	 then                                                                     \
		 echo "CC           ${<}";                                            \
	 else                                                                     \
		 echo $(CC) -c $(CFLAGS) -o $@ $<;                                    \
	 fi
	@$(MKDIR) $(dir $@)
	@$(CC) -c $(CFLAGS) -o $@ $<

.build/%.o: src/%.s
	@if [ 'x${VERBOSE}' = x ];                                                \
	 then                                                                     \
		 echo "CC           ${<}";                                            \
	 else                                                                     \
		 echo $(CC) -c $(CFLAGS) -o $@ $<;                                    \
	 fi
	@$(MKDIR) $(dir $@)
	@$(CC) -c $(CFLAGS) -o $@ $<

# Create Assembly
.build/%.s: src/%.c
	@if [ 'x${VERBOSE}' = x ];                                                \
	 then                                                                     \
		 echo "CC -S        ${<}";                                            \
	 else                                                                     \
		 echo $(CC) -S -c $(CFLAGS) -o $@ $<;                                 \
	 fi
	@$(MKDIR) $(dir $@)
	@$(CC) -S -c $(CFLAGS) -o $@ $<

# Linker Command
.build/$(TARGET).elf: $(C_OBJECTS) $(S_OBJECTS) $(LD_SCRIPT)
	@if [ 'x${VERBOSE}' = x ];                                                \
	 then                                                                     \
		 echo "LD           $@";                                              \
	 else                                                                     \
		 echo $(LD) $(LDFLAGS) -o $@ $(C_OBJECTS) $(S_OBJECTS) $(LIBS);		  \
	 fi
	@$(LD) $(LDFLAGS) -o $@ $(C_OBJECTS) $(S_OBJECTS) $(LIBS);

# Create the Final Image
.build/$(TARGET).bin: .build/$(TARGET).elf
	@if [ 'x${VERBOSE}' = x ];                                                \
	 then                                                                     \
		 echo "OBJCOPY      ${<} $@";                                         \
	 else                                                                     \
		 echo $(OBJCOPY) -O binary .build/$(TARGET).elf .build/$(TARGET).bin; \
	 fi
	@$(OBJCOPY) -O binary .build/$(TARGET).elf .build/$(TARGET).bin

# Calculate the Size of the Image
size: .build/$(TARGET).elf
	@if [ 'x${VERBOSE}' = x ];                                                \
	 then                                                                     \
		 echo "SIZE      ${<}";                                               \
	 else                                                                     \
		 echo $(SIZE) $<;                                                     \
	 fi
	@$(SIZE) $<


# Create the Directories we need
dirs:
	@$(MKDIR) .build

# Cleanup
clean:
	-$(RM) -rf .build

# Flash The Board
install: all
	@if [ 'x${VERBOSE}' = x ];                                                \
	 then                                                                     \
		 echo "  FLASH    .build/$(TARGET).bin";                              \
	 else                                                                     \
		 echo sudo $(FLASH) .build/$(TARGET).bin;                             \
	 fi
	@sudo $(FLASH) .build/$(TARGET).bin

# Redo, Clean->Compile Fresh Image, and Install It.
redo: clean all install
###############################################################################
