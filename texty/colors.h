#ifndef texty_colors_h
#define texty_colors_h
#define DIRECTION_LEFT 1
#define DIRECTION_RIGHT 2
#define DEFAULT_OPEN_DIR @"Code"
#define DEFAULT_EXECUTE_TIMEOUT 1
#define FONT [NSFont fontWithName:@"Monaco" size:12]
#define LINE_80_COLOR RGB(150, 150, 150) 
#define TEXT_COLOR RGB(0xE0,0xE2,0xE4)
#define BG_COLOR RGB(0x00,0x00,0x00)

#define CURSOR_COLOR RGB(255,255,255)

#define TEXT_COLOR_IDX 0
#define KEYWORD_COLOR RGB(0x93,0xC7,0x63)
#define KEYWORD_COLOR_IDX 1
#define VARTYPE_COLOR RGB(0x77,0x9C,0xC1)
#define VARTYPE_COLOR_IDX 2
#define VALUE_COLOR RGB(0xFF,0xCD,0x22)
#define VALUE_COLOR_IDX 3
#define STRING1_COLOR RGB(0xaa,0x96,0x50)
#define STRING1_COLOR_IDX 4
#define STRING2_COLOR RGB(0xEC,0x76,0x00)
#define STRING2_COLOR_IDX 5
#define PREPROCESS_COLOR RGB(0xa8,0xa2,0x97)
#define PREPROCESS_COLOR_IDX 6
#define COMMENT_COLOR RGB(0x7D,0x8C,0x93)
#define COMMENT_COLOR_IDX 7
#define CONSTANT_COLOR RGB(0xA0,0x82,0xBD)
#define CONSTANT_COLOR_IDX 9
#define CONDITION_COLOR RGB(0xFF,0x8B,0xFF)
#define CONDITION_COLOR_IDX 10
#define BRACKET_COLOR_IDX 11
#define NOBRACKET_COLOR_IDX 12

#define EXECUTE_LINE	3
//#define EXECUTE_COMMAND @"TEXTY_EXECUTE"
#define RGB(r, g, b) [NSColor colorWithSRGBRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]
extern NSDictionary *colorAttr[20];
#endif
