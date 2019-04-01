




whitespace ([\r\n\t ])
hexadecimal_number ([\+\-]?0x[0-9a-fA-F]+)
printable_char ([\x20-\x7E\x09\x0A\x0D])




%%
/\*{printable_char}*\*/ showToken("comment")

