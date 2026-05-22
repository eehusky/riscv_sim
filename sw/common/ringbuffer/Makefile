

all:
	peakrdl \
		c-header                                    \
		../../rtl/ringbuffer/ringbuffer_addrmap.rdl \
		--rename ringbuffer                         \
		-o ringbuffer_addrmap.h                     \
		-i                                          \
		--inst-offset 0xA0000000                    \
		--type-style hier
	peakrdl \
		c-header                                    \
		../../rtl/ringbuffer/ringbuffer_addrmap.rdl \
		--rename ringbuffer                     \
		-o ringbuffer_explode.h                     \
		-x                                          \
		--inst-offset 0xA0000000                    \
		--type-style hier
