void c_conputstr(char *string)
{
	__asm__ __volatile__ (
		"move.l	%0, %%a0\n" \
		"bsr conputstr\n"
		:
		: "g" (string)
	);
}
    