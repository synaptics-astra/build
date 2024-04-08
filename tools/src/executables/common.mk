#
# Compiling and linking flags
#
CC := gcc
CFLAGS += -g -I.

#
# Object files
#
OBJECTS := $(patsubst %.c,$(OBJDIR)/%.o,$(SOURCES))

#
# Update target file
#
TARGET := $(OBJDIR)/$(TARGET)

#
# Makefiles
#
MK_FILES := Makefile ../common.mk

#
# Rules
#
.PHONY: pre_build

all: pre_build $(TARGET)

pre_build:
	mkdir -p $(OBJDIR)

clean:
	rm -f $(OBJECTS)
	rm -f $(TARGET)
	rm -f $(OBJECTS:.o=.d)

$(TARGET): $(OBJECTS)
	$(CC) -o $@ $^ $(LDFLAGS)

$(OBJDIR)/%.o: %.c $(OBJDIR)/%.d $(MK_FILES)
	$(CC) $(CFLAGS) -c -MMD -o $@ $<

$(OBJDIR)/%.d: ;
.PRECIOUS: $(OBJDIR)/%.d

-include $(OBJECTS:.o=.d)
