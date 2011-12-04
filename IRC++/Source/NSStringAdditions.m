#import "NSStringAdditions.h"

#import "NSCharacterSetAdditions.h"
#import "NSScannerAdditions.h"

#import <sys/time.h>

struct EmojiEmoticonPair {
	const unichar emoji;
	CFStringRef emoticon;
};

static const struct EmojiEmoticonPair emojiToEmoticonList[] = {
	{ 0xe00e, CFSTR("(Y)") },
	{ 0xe022, CFSTR("<3") },
	{ 0xe023, CFSTR("</3") },
	{ 0xe032, CFSTR("@};-") },
	{ 0xe048, CFSTR(":^)") },
	{ 0xe04e, CFSTR("O:)") },
	{ 0xe056, CFSTR(":)") },
	{ 0xe057, CFSTR(":D") },
	{ 0xe058, CFSTR(":(") },
	{ 0xe059, CFSTR(">:(") },
	{ 0xe05a, CFSTR("~<:)") },
	{ 0xe105, CFSTR(";P") },
	{ 0xe106, CFSTR("(<3") },
	{ 0xe107, CFSTR(":O") },
	{ 0xe108, CFSTR("-_-'") },
	{ 0xe11a, CFSTR(">:)") },
	{ 0xe401, CFSTR(":'(") },
	{ 0xe402, CFSTR(":j") },
	{ 0xe403, CFSTR(":|") },
	{ 0xe404, CFSTR(":-!") },
	{ 0xe405, CFSTR(";)") },
	{ 0xe406, CFSTR("><") },
	{ 0xe407, CFSTR(":X") },
	{ 0xe408, CFSTR(";'(") },
	{ 0xe409, CFSTR(":P") },
	{ 0xe40a, CFSTR(":->") },
	{ 0xe40b, CFSTR(":o") },
	{ 0xe40c, CFSTR(":-&") },
	{ 0xe40d, CFSTR("O.O") },
	{ 0xe40e, CFSTR(":/") },
	{ 0xe40f, CFSTR(":'o") },
	{ 0xe410, CFSTR("x_x") },
	{ 0xe411, CFSTR(":\"o") },
	{ 0xe412, CFSTR(":'D") },
	{ 0xe413, CFSTR(";(") },
	{ 0xe414, CFSTR(":[") },
	{ 0xe415, CFSTR("^-^") },
	{ 0xe416, CFSTR("}:(") },
	{ 0xe417, CFSTR(":-*") },
	{ 0xe418, CFSTR(";-*") },
	{ 0xe421, CFSTR("(N)") },
	{ 0xe445, CFSTR("(~~)") },
	{ 0xe50c, CFSTR("**==") },
	{ 0, nil }
};

static const struct EmojiEmoticonPair emoticonToEmojiList[] = {
// Most Common
	{ 0xe056, CFSTR(":)") },
	{ 0xe056, CFSTR("=)") },
	{ 0xe058, CFSTR(":(") },
	{ 0xe058, CFSTR("=(") },
	{ 0xe405, CFSTR(";)") },
	{ 0xe409, CFSTR(":P") },
	{ 0xe409, CFSTR(":p") },
	{ 0xe409, CFSTR("=P") },
	{ 0xe409, CFSTR("=p") },
	{ 0xe105, CFSTR(";p") },
	{ 0xe105, CFSTR(";P") },
	{ 0xe057, CFSTR(":D") },
	{ 0xe057, CFSTR("=D") },
	{ 0xe403, CFSTR(":|") },
	{ 0xe403, CFSTR("=|") },
	{ 0xe40e, CFSTR(":/") },
	{ 0xe40e, CFSTR(":\\") },
	{ 0xe40e, CFSTR("=/") },
	{ 0xe40e, CFSTR("=\\") },
	{ 0xe414, CFSTR(":[") },
	{ 0xe414, CFSTR("=[") },
	{ 0xe056, CFSTR(":]") },
	{ 0xe056, CFSTR("=]") },
	{ 0xe40b, CFSTR(":o") },
	{ 0xe107, CFSTR(":O") },
	{ 0xe40b, CFSTR("=o") },
	{ 0xe107, CFSTR("=O") },
	{ 0xe107, CFSTR(":0") },
	{ 0xe107, CFSTR("=0") },
	{ 0xe04e, CFSTR("O:)") },
	{ 0xe04e, CFSTR("0:)") },
	{ 0xe04e, CFSTR("o:)") },
	{ 0xe04e, CFSTR("O=)") },
	{ 0xe04e, CFSTR("0=)") },
	{ 0xe04e, CFSTR("o=)") },
	{ 0xe022, CFSTR("<3") },
	{ 0xe023, CFSTR("</3") },
	{ 0xe023, CFSTR("<\3") },
	{ 0xe406, CFSTR("><") },
	{ 0xe40d, CFSTR("O.O") },
	{ 0xe40d, CFSTR("o.o") },
	{ 0xe40d, CFSTR("O.o") },
	{ 0xe40d, CFSTR("o.O") },
	{ 0xe409, CFSTR("XD") },
	{ 0xe409, CFSTR("xD") },
	{ 0xe407, CFSTR(":X") },
	{ 0xe407, CFSTR(":x") },
	{ 0xe407, CFSTR("=X") },
	{ 0xe407, CFSTR("=x") },
	{ 0xe059, CFSTR(">:(") },
	{ 0xe11a, CFSTR(">:)") },
	{ 0xe415, CFSTR("^.^") },
	{ 0xe415, CFSTR("^-^") },
	{ 0xe415, CFSTR("^_^") },

// Less Common
	{ 0xe056, CFSTR("(:") },
	{ 0xe056, CFSTR("(=") },
	{ 0xe056, CFSTR("[:") },
	{ 0xe056, CFSTR("[=") },
	{ 0xe058, CFSTR("):") },
	{ 0xe058, CFSTR(")=") },
	{ 0xe058, CFSTR("]=") },
	{ 0xe058, CFSTR("]:") },
	{ 0xe056, CFSTR(":-)") },
	{ 0xe056, CFSTR("=-)") },
	{ 0xe058, CFSTR(":-(") },
	{ 0xe409, CFSTR(":-P") },
	{ 0xe409, CFSTR(":-p") },
	{ 0xe409, CFSTR("=-P") },
	{ 0xe409, CFSTR("=-p") },
	{ 0xe105, CFSTR(";-p") },
	{ 0xe105, CFSTR(";-P") },
	{ 0xe405, CFSTR(";-)") },
	{ 0xe057, CFSTR(":-D") },
	{ 0xe057, CFSTR("=-D") },
	{ 0xe058, CFSTR("=-(") },
	{ 0xe059, CFSTR(">=(") },
	{ 0xe11a, CFSTR(">=)") },
	{ 0xe414, CFSTR(":-[") },
	{ 0xe414, CFSTR("=-[") },
	{ 0xe107, CFSTR(":-0") },
	{ 0xe107, CFSTR("=-0") },
	{ 0xe04e, CFSTR("O=-)") },
	{ 0xe04e, CFSTR("o=-)") },
	{ 0xe108, CFSTR("-_-'") },
	{ 0xe403, CFSTR("-_-") },
	{ 0xe409, CFSTR("Xd") },
	{ 0xe409, CFSTR("xd") },
	{ 0xe409, CFSTR(";D") },
	{ 0xe409, CFSTR("D:") },
	{ 0xe409, CFSTR("D:<") },
	{ 0xe406, CFSTR(">_<") },
	{ 0xe410, CFSTR("X_X") },
	{ 0xe410, CFSTR("x_x") },
	{ 0xe410, CFSTR("X_x") },
	{ 0xe410, CFSTR("x_X") },
	{ 0xe410, CFSTR("x.x") },
	{ 0xe410, CFSTR("X.X") },
	{ 0xe410, CFSTR("X.x") },
	{ 0xe410, CFSTR("x.X") },
	{ 0xe417, CFSTR(":*") },
	{ 0xe417, CFSTR(":-*") },
	{ 0xe417, CFSTR("=*") },
	{ 0xe417, CFSTR("=-*") },
	{ 0xe418, CFSTR(";*") },
	{ 0xe418, CFSTR(";-*") },
	{ 0xe401, CFSTR(":'(") },
	{ 0xe401, CFSTR("='(") },
	{ 0xe404, CFSTR(":!") },
	{ 0xe404, CFSTR(":-!") },
	{ 0xe404, CFSTR("=!") },
	{ 0xe404, CFSTR("=-!") },
	{ 0xe40c, CFSTR(":&") },
	{ 0xe40c, CFSTR(":-&") },
	{ 0xe40c, CFSTR("=&") },
	{ 0xe40c, CFSTR("=-&") },
	{ 0xe40c, CFSTR(":#") },
	{ 0xe40c, CFSTR(":-#") },
	{ 0xe40c, CFSTR("=#") },
	{ 0xe40c, CFSTR("=-#") },
	{ 0xe411, CFSTR(":\"o") },
	{ 0xe411, CFSTR("=\"o") },
	{ 0xe411, CFSTR(":\"O") },
	{ 0xe411, CFSTR("=\"O") },
	{ 0xe412, CFSTR(":'D") },
	{ 0xe412, CFSTR("='D") },
	{ 0xe413, CFSTR(";(") },
	{ 0xe408, CFSTR(";'(") },
	{ 0xe40f, CFSTR(":'o") },
	{ 0xe40f, CFSTR(":'O") },
	{ 0xe40f, CFSTR("='o") },
	{ 0xe40f, CFSTR("='O") },
	{ 0xe40e, CFSTR(":-/") },
	{ 0xe40e, CFSTR(":-\\") },
	{ 0xe40e, CFSTR("=-/") },
	{ 0xe40e, CFSTR("=-\\") },
	{ 0xe40b, CFSTR(":-o") },
	{ 0xe107, CFSTR(":-O") },
	{ 0xe40b, CFSTR("=-o") },
	{ 0xe107, CFSTR("=-O") },
	{ 0xe402, CFSTR(":j") },
	{ 0xe402, CFSTR(":-j") },
	{ 0xe402, CFSTR("=j") },
	{ 0xe402, CFSTR("=-j") },
	{ 0xe40a, CFSTR(":>") },
	{ 0xe40a, CFSTR(":->") },
	{ 0xe40a, CFSTR("=>") },
	{ 0xe40a, CFSTR("=->") },
	{ 0xe416, CFSTR("}:(") },
	{ 0xe416, CFSTR("}:-(") },
	{ 0xe416, CFSTR("}=(") },
	{ 0xe416, CFSTR("}=-(") },
	{ 0xe059, CFSTR(">:-(") },
	{ 0xe11a, CFSTR(">:-)") },
	{ 0xe059, CFSTR(">=-(") },
	{ 0xe11a, CFSTR(">=-)") },
	{ 0xe04e, CFSTR("O:-)") },
	{ 0xe04e, CFSTR("o:-)") },

// Rare
	{ 0xe05a, CFSTR("~<:)") },
	{ 0xe048, CFSTR(":^)") },
	{ 0xe048, CFSTR(";^)") },
	{ 0xe048, CFSTR("=^)") },
	{ 0xe032, CFSTR("@};-") },
	{ 0xe032, CFSTR("@>-") },
	{ 0xe032, CFSTR("-;{@") },
	{ 0xe032, CFSTR("-<@") },
	{ 0xe445, CFSTR("(~~)") },
	{ 0xe50c, CFSTR("**==") },
	{ 0xe00e, CFSTR("(Y)") },
	{ 0xe00e, CFSTR("(y)") },
	{ 0xe421, CFSTR("(N)") },
	{ 0xe421, CFSTR("(n)") },
	{ 0xe106, CFSTR("(<3") },
	{ 0xe409, CFSTR("d:") },
	{ 0xe409, CFSTR("d=") },
	{ 0xe409, CFSTR("d-:") },
	{ 0xe056, CFSTR("(-:") },
	{ 0xe056, CFSTR("(-=") },
	{ 0xe058, CFSTR(")-:") },
	{ 0xe058, CFSTR(")-=") },
	{ 0xe058, CFSTR("]-:") },
	{ 0xe058, CFSTR("]-=") },
	{ 0xe401, CFSTR(")':") },
	{ 0xe401, CFSTR(")'=") },
	{ 0xe404, CFSTR("!:") },
	{ 0xe404, CFSTR("!-:") },
	{ 0xe404, CFSTR("!-=") },
	{ 0xe40b, CFSTR("o:") },
	{ 0xe107, CFSTR("O:") },
	{ 0xe40b, CFSTR("o-:") },
	{ 0xe107, CFSTR("O-:") },
	{ 0xe40b, CFSTR("o=") },
	{ 0xe107, CFSTR("O=") },
	{ 0xe40b, CFSTR("o-=") },
	{ 0xe107, CFSTR("O-=") },
	{ 0xe107, CFSTR("0:") },
	{ 0xe107, CFSTR("0-:") },
	{ 0xe107, CFSTR("0=") },
	{ 0xe107, CFSTR("0-=") },
	{ 0xe418, CFSTR("*;") },
	{ 0xe418, CFSTR("*-;") },
	{ 0xe417, CFSTR("*:") },
	{ 0xe417, CFSTR("*-:") },
	{ 0xe417, CFSTR("*=") },
	{ 0xe417, CFSTR("*-=") },
	{ 0xe11a, CFSTR("(:<") },
	{ 0xe059, CFSTR("):<") },
	{ 0xe11a, CFSTR("(-:<") },
	{ 0xe059, CFSTR(")-:<") },
	{ 0xe11a, CFSTR("(=<") },
	{ 0xe059, CFSTR(")=<") },
	{ 0xe11a, CFSTR("(-=<") },
	{ 0xe059, CFSTR(")-=<") },
	{ 0xe04e, CFSTR("(:O") },
	{ 0xe04e, CFSTR("(:o") },
	{ 0xe04e, CFSTR("(-:O") },
	{ 0xe04e, CFSTR("(-:o") },
	{ 0xe04e, CFSTR("(=O") },
	{ 0xe04e, CFSTR("(=o") },
	{ 0xe04e, CFSTR("(-=O") },
	{ 0xe04e, CFSTR("(-=o") },

	{ 0, nil }
};

BOOL isValidUTF8( const char *s, NSUInteger len ) {
	BOOL only7bit = YES;

	for( NSUInteger i = 0; i < len; ++i ) {
		const unsigned char ch = s[i];

		if( is7Bit( ch ) )
			continue;

		if( only7bit )
			only7bit = NO;

		if( isUTF8Tupel( ch ) ) {
			if( len - i < 1 ) // too short
				return NO;
			if( isUTF8LongTupel( ch ) ) // not minimally encoded
				return NO;
			if( ! isUTF8Cont( s[i + 1] ) )
				return NO;
			i += 1;
		} else if( isUTF8Triple( ch ) ) {
			if( len - i < 2 ) // too short
				return NO;
			if( isUTF8LongTriple( ch, s[i + 1] ) ) // not minimally encoded
				return NO;
			if( ! isUTF8Cont( s[i + 1] ) || ! isUTF8Cont( s[i + 2] ) )
				return NO;
			i += 2;
		} else if( isUTF8Quartet( ch ) ) {
			if( len - i < 3 ) // too short
				return NO;
			if( isUTF8LongQuartet( ch, s[i + 1] ) ) // not minimally encoded
				return NO;
			if( ! isUTF8Cont( s[i + 1] ) || ! isUTF8Cont( s[i + 2] ) || ! isUTF8Cont( s[i + 3] ) )
				return NO;
			i += 3;
		} else if( isUTF8Quintet( ch ) ) {
			if( len - i < 4 ) // too short
				return NO;
			if( isUTF8LongQuintet( ch, s[i + 1] ) ) // not minimally encoded
				return NO;
			if( ! isUTF8Cont( s[i + 1] ) || ! isUTF8Cont( s[i + 2] ) || ! isUTF8Cont( s[i + 3] ) || ! isUTF8Cont( s[i + 4] ) )
				return NO;
			i += 4;
		} else if( isUTF8Sextet( ch ) ) {
			if( len - i < 5 ) // too short
				return NO;
			if( isUTF8LongSextet( ch, s[i + 1] ) ) // not minimally encoded
				return NO;
			if( ! isUTF8Cont( s[i + 1] ) || ! isUTF8Cont( s[i + 2] ) || ! isUTF8Cont( s[i + 3] ) || ! isUTF8Cont( s[i + 4] ) || ! isUTF8Cont( s[i + 5] ) )
				return NO;
			i += 5;
		} else return NO;
	}

	if( only7bit )
		return NO; // technically it can be UTF8, but it might be another 7-bit encoding
	return YES;
}

static const unsigned char mIRCColors[][3] = {
	{ 0xff, 0xff, 0xff },  /* 00) white */
	{ 0x00, 0x00, 0x00 },  /* 01) black */
	{ 0x00, 0x00, 0x7b },  /* 02) blue */
	{ 0x00, 0x94, 0x00 },  /* 03) green */
	{ 0xff, 0x00, 0x00 },  /* 04) red */
	{ 0x7b, 0x00, 0x00 },  /* 05) brown */
	{ 0x9c, 0x00, 0x9c },  /* 06) purple */
	{ 0xff, 0x7b, 0x00 },  /* 07) orange */
	{ 0xff, 0xff, 0x00 },  /* 08) yellow */
	{ 0x00, 0xff, 0x00 },  /* 09) bright green */
	{ 0x00, 0x94, 0x94 },  /* 10) cyan */
	{ 0x00, 0xff, 0xff },  /* 11) bright cyan */
	{ 0x00, 0x00, 0xff },  /* 12) bright blue */
	{ 0xff, 0x00, 0xff },  /* 13) bright purple */
	{ 0x7b, 0x7b, 0x7b },  /* 14) gray */
	{ 0xd6, 0xd6, 0xd6 }   /* 15) light gray */
};

static const unsigned char CTCPColors[][3] = {
	{ 0x00, 0x00, 0x00 },  /* 0) black */
	{ 0x00, 0x00, 0x7f },  /* 1) blue */
	{ 0x00, 0x7f, 0x00 },  /* 2) green */
	{ 0x00, 0x7f, 0x7f },  /* 3) cyan */
	{ 0x7f, 0x00, 0x00 },  /* 4) red */
	{ 0x7f, 0x00, 0x7f },  /* 5) purple */
	{ 0x7f, 0x7f, 0x00 },  /* 6) brown */
	{ 0xc0, 0xc0, 0xc0 },  /* 7) light gray */
	{ 0x7f, 0x7f, 0x7f },  /* 8) gray */
	{ 0x00, 0x00, 0xff },  /* 9) bright blue */
	{ 0x00, 0xff, 0x00 },  /* A) bright green */
	{ 0x00, 0xff, 0xff },  /* B) bright cyan */
	{ 0xff, 0x00, 0x00 },  /* C) bright red */
	{ 0xff, 0x00, 0xff },  /* D) bright magenta */
	{ 0xff, 0xff, 0x00 },  /* E) yellow */
	{ 0xff, 0xff, 0xff }   /* F) white */
};

static BOOL scanOneOrTwoDigits( NSScanner *scanner, NSUInteger *number ) {
	NSCharacterSet *characterSet = [NSCharacterSet decimalDigitCharacterSet];
	NSString *chars = nil;

	if( ! [scanner scanCharactersFromSet:characterSet maxLength:2 intoString:&chars] )
		return NO;

	*number = [chars intValue];
	return YES;
}

static NSString *colorForHTML( unsigned char red, unsigned char green, unsigned char blue ) {
	return [NSString stringWithFormat:@"#%02X%02X%02X", red, green, blue];
}

@interface NSString (NewInLeopard)
- (NSArray *) componentsSeparatedByCharactersInSet:(NSCharacterSet *) characters;
@end

@implementation NSString (NSStringAdditions)
+ (NSString *) locallyUniqueString {
	struct timeval tv;
	gettimeofday( &tv, NULL );

	NSUInteger m = 36; // base (denominator)
	NSUInteger q = [[NSProcessInfo processInfo] processIdentifier] ^ tv.tv_usec; // input (quotient)
	NSUInteger r = 0; // remainder

	NSMutableString *uniqueId = [[NSMutableString alloc] initWithCapacity:10];
	[uniqueId appendFormat:@"%c", 'A' + ( random() % 26 )]; // always have a random letter first (more ambiguity)

	#define baseConvert	do { \
		r = q % m; \
		q = q / m; \
		if( r >= 10 ) r = 'A' + ( r - 10 ); \
		else r = '0' + r; \
		[uniqueId appendFormat:@"%c", r]; \
	} while( q ) \

	baseConvert;

	q = ( tv.tv_sec - 1104555600 ); // subtract 35 years, we only care about post Jan 1 2005

	baseConvert;

	#undef baseConvert

	return [uniqueId autorelease];
}

#pragma mark -

- (id) initWithChatData:(NSData *) data encoding:(NSStringEncoding) encoding {
	if( ! encoding ) encoding = NSISOLatin1StringEncoding;

	// Search for CTCP/2 encoding tags and act on them
	NSMutableData *newData = [NSMutableData dataWithCapacity:data.length];
	NSStringEncoding currentEncoding = encoding;

	const char *bytes = [data bytes];
	NSUInteger length = data.length;
	NSUInteger i = 0, j = 0, start = 0, end = 0;
	for( i = 0, start = 0; i < length; i++ ) {
		if( bytes[i] == '\006' ) {
			end = i;
			j = ++i;

			for( ; i < length && bytes[i] != '\006'; i++ );
			if( i >= length ) break;
			if( i == j ) continue;

			if( bytes[j++] == 'E' ) {
				NSString *encodingStr = [[NSString alloc] initWithBytes:( bytes + j ) length:( i - j ) encoding:NSASCIIStringEncoding];
				NSStringEncoding newEncoding = 0;
				if( ! encodingStr.length ) { // if no encoding is declared, go back to user default
					newEncoding = encoding;
				} else if( [encodingStr isEqualToString:@"U"] ) {
					newEncoding = NSUTF8StringEncoding;
				} else {
					NSUInteger enc = [encodingStr intValue];
					switch( enc ) {
						case 1:
							newEncoding = NSISOLatin1StringEncoding;
							break;
						case 2:
							newEncoding = NSISOLatin2StringEncoding;
							break;
						case 3:
							newEncoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatin3 );
							break;
						case 4:
							newEncoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatin4 );
							break;
						case 5:
							newEncoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatinCyrillic );
							break;
						case 6:
							newEncoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatinArabic );
							break;
						case 7:
							newEncoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatinGreek );
							break;
						case 8:
							newEncoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatinHebrew );
							break;
						case 9:
							newEncoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatin5 );
							break;
						case 10:
							newEncoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatin6 );
							break;
					}
				}

				[encodingStr release];

				if( newEncoding && newEncoding != currentEncoding ) {
					if( ( end - start ) > 0 ) {
						NSData *subData = nil;
						if( currentEncoding != NSUTF8StringEncoding ) {
							NSString *tempStr = [[NSString alloc] initWithBytes:( bytes + start ) length:( end - start ) encoding:currentEncoding];
							NSData *utf8Data = [tempStr dataUsingEncoding:NSUTF8StringEncoding];
							if( utf8Data ) subData = [utf8Data retain];
							[tempStr release];
						} else {
							subData = [[NSData alloc] initWithBytesNoCopy:(void *)( bytes + start ) length:( end - start )];
						}

						if( subData ) [newData appendData:subData];
						[subData release];
					}

					currentEncoding = newEncoding;
					start = i + 1;
				}
			}
		}
	}

	if( newData.length > 0 || currentEncoding != encoding ) {
		if( start < length ) {
			NSData *subData = nil;
			if( currentEncoding != NSUTF8StringEncoding ) {
				NSString *tempStr = [[NSString alloc] initWithBytes:( bytes + start ) length:( length - start ) encoding:currentEncoding];
				NSData *utf8Data = [tempStr dataUsingEncoding:NSUTF8StringEncoding];
				if( utf8Data ) subData = [utf8Data retain];
				[tempStr release];
			} else {
				subData = [[NSData alloc] initWithBytesNoCopy:(void *)( bytes + start ) length:( length - start )];
			}

			if( subData ) [newData appendData:subData];
			[subData release];
		}

		encoding = NSUTF8StringEncoding;
		data = newData;
	}

	if( encoding != NSUTF8StringEncoding && isValidUTF8( [data bytes], data.length ) )
		encoding = NSUTF8StringEncoding;

	NSString *message = [[NSString alloc] initWithData:data encoding:encoding];
	if( ! message ) {
		[self release];
		return nil;
	}

	NSCharacterSet *formatCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\002\003\006\026\037\017"];

	// if the message dosen't have any formatting chars just init as a plain string and return quickly
	if( [message rangeOfCharacterFromSet:formatCharacters].location == NSNotFound ) {
		self = [self initWithString:[message stringByEncodingXMLSpecialCharactersAsEntities]];
		[message release];
		return self;
	}

	NSMutableString *ret = [NSMutableString string];
	NSScanner *scanner = [NSScanner scannerWithString:message];
	[scanner setCharactersToBeSkipped:nil]; // don't skip leading whitespace!

	NSUInteger boldStack = 0, italicStack = 0, underlineStack = 0, strikeStack = 0, colorStack = 0;

	while( ! [scanner isAtEnd] ) {
		NSString *cStr = nil;
		if( [scanner scanCharactersFromSet:formatCharacters maxLength:1 intoString:&cStr] ) {
			unichar c = [cStr characterAtIndex:0];
			switch( c ) {
			case '\017': // reset all
				if( boldStack )
					[ret appendString:@"</b>"];
				if( italicStack )
					[ret appendString:@"</i>"];
				if( underlineStack )
					[ret appendString:@"</u>"];
				if( strikeStack )
					[ret appendString:@"</strike>"];
				for( NSUInteger i = 0; i < colorStack; ++i )
					[ret appendString:@"</span>"];

				boldStack = italicStack = underlineStack = strikeStack = colorStack = 0;
				break;
			case '\002': // toggle bold
				boldStack = ! boldStack;

				if( boldStack ) [ret appendString:@"<b>"];
				else [ret appendString:@"</b>"];
				break;
			case '\026': // toggle italic
				italicStack = ! italicStack;

				if( italicStack ) [ret appendString:@"<i>"];
				else [ret appendString:@"</i>"];
				break;
			case '\037': // toggle underline
				underlineStack = ! underlineStack;

				if( underlineStack ) [ret appendString:@"<u>"];
				else [ret appendString:@"</u>"];
				break;
			case '\003': // color
			{
				NSUInteger fcolor = 0;
				if( scanOneOrTwoDigits( scanner, &fcolor ) ) {
					fcolor %= 16;

					NSString *foregroundColor = colorForHTML(mIRCColors[fcolor][0], mIRCColors[fcolor][1], mIRCColors[fcolor][2]);
					[ret appendFormat:@"<span style=\"color: %@;", foregroundColor];

					NSUInteger bcolor = 0;
					if( [scanner scanString:@"," intoString:NULL] && scanOneOrTwoDigits( scanner, &bcolor ) && bcolor != 99 ) {
						bcolor %= 16;

						NSString *backgroundColor = colorForHTML(mIRCColors[bcolor][0], mIRCColors[bcolor][1], mIRCColors[bcolor][2]);
						[ret appendFormat:@" background-color: %@;", backgroundColor];
					}

					[ret appendString:@"\">"];

					++colorStack;
				} else { // no color, reset both colors
					for( NSUInteger i = 0; i < colorStack; ++i )
						[ret appendString:@"</span>"];
					colorStack = 0;
				}
				break;
			}
			case '\006': // ctcp 2 formatting (http://www.lag.net/~robey/ctcp/ctcp2.2.txt)
				if( ! [scanner isAtEnd] ) {
					BOOL off = NO;

					unichar formatChar = [message characterAtIndex:[scanner scanLocation]];
					[scanner setScanLocation:[scanner scanLocation]+1];

					switch( formatChar ) {
					case 'B': // bold
						if( [scanner scanString:@"-" intoString:NULL] ) {
							if( boldStack >= 1 ) boldStack--;
							off = YES;
						} else { // on is the default
							[scanner scanString:@"+" intoString:NULL];
							boldStack++;
						}

						if( boldStack == 1 && ! off )
							[ret appendString:@"<b>"];
						else if( ! boldStack )
							[ret appendString:@"</b>"];
						break;
					case 'I': // italic
						if( [scanner scanString:@"-" intoString:NULL] ) {
							if( italicStack >= 1 ) italicStack--;
							off = YES;
						} else { // on is the default
							[scanner scanString:@"+" intoString:NULL];
							italicStack++;
						}

						if( italicStack == 1 && ! off )
							[ret appendString:@"<i>"];
						else if( ! italicStack )
							[ret appendString:@"</i>"];
						break;
					case 'U': // underline
						if( [scanner scanString:@"-" intoString:NULL] ) {
							if( underlineStack >= 1 ) underlineStack--;
							off = YES;
						} else { // on is the default
							[scanner scanString:@"+" intoString:NULL];
							underlineStack++;
						}

						if( underlineStack == 1 && ! off )
							[ret appendString:@"<u>"];
						else if( ! underlineStack )
							[ret appendString:@"</u>"];
						break;
					case 'S': // strikethrough
						if( [scanner scanString:@"-" intoString:NULL] ) {
							if( strikeStack >= 1 ) strikeStack--;
							off = YES;
						} else { // on is the default
							[scanner scanString:@"+" intoString:NULL];
							strikeStack++;
						}

						if( strikeStack == 1 && ! off )
							[ret appendString:@"<strike>"];
						else if( ! strikeStack )
							[ret appendString:@"</strike>"];
						break;
					case 'C': // color
						if( [message characterAtIndex:[scanner scanLocation]] == '\006' ) { // reset colors
							for( NSUInteger i = 0; i < colorStack; ++i )
								[ret appendString:@"</span>"];
							colorStack = 0;
							break;
						}

						// scan for foreground color
						NSCharacterSet *hexSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF"];
						NSString *colorStr = nil;
						BOOL foundForeground = YES;
						if( [scanner scanString:@"#" intoString:NULL] ) { // rgb hex color
							if( [scanner scanCharactersFromSet:hexSet maxLength:6 intoString:&colorStr] ) {
								[ret appendFormat:@"<span style=\"color: %@;", colorStr];
							} else foundForeground = NO;
						} else if( [scanner scanCharactersFromSet:hexSet maxLength:1 intoString:&colorStr] ) { // indexed color
							NSUInteger index = [colorStr characterAtIndex:0];
							if( index >= 'A' ) index -= ( 'A' - '9' - 1 );
							index -= '0';

							NSString *foregroundColor = colorForHTML(CTCPColors[index][0], CTCPColors[index][1], CTCPColors[index][2]);
							[ret appendFormat:@"<span style=\"color: %@;", foregroundColor];
						} else if( [scanner scanString:@"." intoString:NULL] ) { // reset the foreground color
							[ret appendString:@"<span style=\"color: initial;"];
						} else if( [scanner scanString:@"-" intoString:NULL] ) { // skip the foreground color
							// Do nothing - we're skipping
							// This is so we can have an else clause that doesn't fire for @"-"
						} else {
							// Ok, no foreground color
							foundForeground = NO;
						}

						if( foundForeground ) {
							// scan for background color
							if( [scanner scanString:@"#" intoString:NULL] ) { // rgb hex color
								if( [scanner scanCharactersFromSet:hexSet maxLength:6 intoString:&colorStr] )
									[ret appendFormat:@" background-color: %@;", colorStr];
							} else if( [scanner scanCharactersFromSet:hexSet maxLength:1 intoString:&colorStr] ) { // indexed color
								NSUInteger index = [colorStr characterAtIndex:0];
								if( index >= 'A' ) index -= ( 'A' - '9' - 1 );
								index -= '0';

								NSString *backgroundColor = colorForHTML(CTCPColors[index][0], CTCPColors[index][1], CTCPColors[index][2]);
								[ret appendFormat:@" background-color: %@;", backgroundColor];
							} else if( [scanner scanString:@"." intoString:NULL] ) { // reset the background color
								[ret appendString:@" background-color: initial;"];
							} else [scanner scanString:@"-" intoString:NULL]; // skip the background color

							[ret appendString:@"\">"];

							++colorStack;
						} else {
							// No colors - treat it like ..
							for( NSUInteger i = 0; i < colorStack; ++i )
								[ret appendString:@"</span>"];
							colorStack = 0;
						}
					case 'F': // font size
					case 'E': // encoding
						// We actually handle this above, but there could be some encoding tags
						// left over. For instance, ^FEU^F^FEU^F will leave one of the two tags behind.
					case 'K': // blinking
					case 'P': // spacing
						// not supported yet
						break;
					case 'N': // normal (reset)
						if( boldStack )
							[ret appendString:@"</b>"];
						if( italicStack )
							[ret appendString:@"</i>"];
						if( underlineStack )
							[ret appendString:@"</u>"];
						if( strikeStack )
							[ret appendString:@"</strike>"];
						for( NSUInteger i = 0; i < colorStack; ++i )
							[ret appendString:@"</span>"];

						boldStack = italicStack = underlineStack = strikeStack = colorStack = 0;
					}

					[scanner scanUpToString:@"\006" intoString:NULL];
					[scanner scanString:@"\006" intoString:NULL];
				}
			}
		}

		NSString *text = nil;
 		[scanner scanUpToCharactersFromSet:formatCharacters intoString:&text];

		if( text.length )
			[ret appendString:[text stringByEncodingXMLSpecialCharactersAsEntities]];
	}

	[message release];

	return [self initWithString:ret];
}

#pragma mark -

- (BOOL) isCaseInsensitiveEqualToString:(NSString *) string {
	return [self compare:string options:NSCaseInsensitiveSearch range:NSMakeRange( 0, self.length )] == NSOrderedSame;
}

- (BOOL) hasCaseInsensitivePrefix:(NSString *) prefix {
	return [self rangeOfString:prefix options:( NSCaseInsensitiveSearch | NSAnchoredSearch ) range:NSMakeRange( 0, self.length )].location != NSNotFound;
}

- (BOOL) hasCaseInsensitiveSuffix:(NSString *) suffix {
	return [self rangeOfString:suffix options:( NSCaseInsensitiveSearch | NSBackwardsSearch | NSAnchoredSearch ) range:NSMakeRange( 0, self.length )].location != NSNotFound;
}

- (BOOL) hasCaseInsensitiveSubstring:(NSString *) substring {
	return [self rangeOfString:substring options:NSCaseInsensitiveSearch range:NSMakeRange( 0, self.length )].location != NSNotFound;
}

#pragma mark -

+ (NSString *) stringByReversingString:(NSString *) normalString {
	NSMutableString *reversedString = [[NSMutableString alloc] initWithCapacity:normalString.length];

	for (NSInteger index = normalString.length - 1; index >= 0; index--)
		[reversedString appendString:[normalString substringWithRange:NSMakeRange(index, 1)]];

	return [reversedString autorelease];
}

#pragma mark -

- (NSString *) stringByEncodingXMLSpecialCharactersAsEntities {
	NSCharacterSet *special = [NSCharacterSet characterSetWithCharactersInString:@"&<>\"'"];
	NSRange range = [self rangeOfCharacterFromSet:special options:NSLiteralSearch];
	if( range.location == NSNotFound )
		return self;

	NSMutableString *result = [self mutableCopy];
	[result encodeXMLSpecialCharactersAsEntities];
	return [result autorelease];
}

- (NSString *) stringByDecodingXMLSpecialCharacterEntities {
	NSRange range = [self rangeOfString:@"&" options:NSLiteralSearch];
	if( range.location == NSNotFound )
		return self;

	NSMutableString *result = [self mutableCopy];
	[result decodeXMLSpecialCharacterEntities];
	return [result autorelease];
}

#pragma mark -

- (NSString *) stringByEscapingCharactersInSet:(NSCharacterSet *) set {
	NSRange range = [self rangeOfCharacterFromSet:set];
	if( range.location == NSNotFound )
		return self;

	NSMutableString *result = [self mutableCopy];
	[result escapeCharactersInSet:set];
	return [result autorelease];
}

- (NSString *) stringByReplacingCharactersInSet:(NSCharacterSet *) set withString:(NSString *) string {
	NSRange range = [self rangeOfCharacterFromSet:set];
	if( range.location == NSNotFound )
		return self;

	NSMutableString *result = [self mutableCopy];
	[result replaceCharactersInSet:set withString:string];
	return [result autorelease];
}

#pragma mark -

- (NSString *) stringByEncodingIllegalURLCharacters {
	return [(NSString *)CFURLCreateStringByAddingPercentEscapes( NULL, (CFStringRef)self, NULL, CFSTR( ",;:/?@&$=|^~`\{}[]" ), kCFStringEncodingUTF8 ) autorelease];
}

- (NSString *) stringByDecodingIllegalURLCharacters {
	return [(NSString *)CFURLCreateStringByReplacingPercentEscapes( NULL, (CFStringRef)self, CFSTR( "" ) ) autorelease];
}

#pragma mark -

- (NSString *) stringByStrippingIllegalXMLCharacters {
	NSRange range = [self rangeOfCharacterFromSet:[NSCharacterSet illegalXMLCharacterSet]];

	if( range.location == NSNotFound )
		return self;

	NSMutableString *result = [self mutableCopy];
	[result stripIllegalXMLCharacters];
	return [result autorelease];
}

- (NSString *) stringByStrippingXMLTags {
	if( [self rangeOfString:@"<"].location == NSNotFound )
		return self;

	NSMutableString *result = [self mutableCopy];
	[result stripXMLTags];
	return [result autorelease];
}

#pragma mark -

- (NSString *) stringWithDomainNameSegmentOfAddress {
	NSString *ret = self;
	unsigned ip = 0;
	BOOL ipAddress = ( sscanf( [self UTF8String], "%u.%u.%u.%u", &ip, &ip, &ip, &ip ) == 4 );

	if( ! ipAddress ) {
		NSArray *parts = [self componentsSeparatedByString:@"."];
		NSUInteger count = parts.count;
		if( count > 2 )
			ret = [NSString stringWithFormat:@"%@.%@", [parts objectAtIndex:(count - 2)], [parts objectAtIndex:(count - 1)]];
	}

	return ret;
}

#pragma mark -

- (NSArray *) componentsSeparatedByCharactersInSet:(NSCharacterSet *) separator limit:(NSUInteger) limit {
	return [self componentsSeparatedByCharactersInSet:separator limit:limit remainingString:NULL];
}

- (NSArray *) componentsSeparatedByCharactersInSet:(NSCharacterSet *) separator limit:(NSUInteger) limit remainingString:(NSString **) remainder {
	if( ! limit && ! remainder && [self respondsToSelector:@selector(componentsSeparatedByCharactersInSet:)] )
		return [self componentsSeparatedByCharactersInSet:separator];

	if( [self rangeOfCharacterFromSet:separator].location == NSNotFound )
		return [NSArray arrayWithObject:self];

	if( ! limit ) limit = ULONG_MAX;

	NSScanner *scanner = [[NSScanner alloc] initWithString:self];
	[scanner setCharactersToBeSkipped:nil];

	NSMutableArray *result = [[NSMutableArray alloc] init];

	NSUInteger count = 0;
	NSString *component = @"";
	while( ! [scanner isAtEnd] ) {
		[scanner scanUpToCharactersFromSet:separator intoString:&component];
		[scanner scanCharactersFromSet:separator intoString:NULL];

		[result addObject:component];

		if (++count >= limit)
			break;
	}

	if( remainder )
		*remainder = [self substringFromIndex:[scanner scanLocation]];

	[scanner release];

	return [result autorelease];
}

#pragma mark -

- (NSString *) fileName {
	NSString *fileName = [self lastPathComponent];
	NSString *fileExtension = [NSString stringWithFormat:@".%@", [self pathExtension]];

	return [fileName stringByReplacingOccurrencesOfString:fileExtension withString:@""];
}

@end

#pragma mark -

@implementation NSMutableString (NSMutableStringAdditions)
- (void) encodeXMLSpecialCharactersAsEntities {
	NSCharacterSet *special = [NSCharacterSet characterSetWithCharactersInString:@"&<>\"'"];
	NSRange range = [self rangeOfCharacterFromSet:special options:NSLiteralSearch];
	if( range.location == NSNotFound )
		return;

	[self replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange( 0, self.length )];
	[self replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange( 0, self.length )];
	[self replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:NSMakeRange( 0, self.length )];
	[self replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange( 0, self.length )];
	[self replaceOccurrencesOfString:@"'" withString:@"&apos;" options:NSLiteralSearch range:NSMakeRange( 0, self.length )];
}

- (void) decodeXMLSpecialCharacterEntities {
	NSRange range = [self rangeOfString:@"&" options:NSLiteralSearch];
	if( range.location == NSNotFound )
		return;

	[self replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSLiteralSearch range:NSMakeRange( 0, self.length )];
	[self replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSLiteralSearch range:NSMakeRange( 0, self.length )];
	[self replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSLiteralSearch range:NSMakeRange( 0, self.length )];
	[self replaceOccurrencesOfString:@"&apos;" withString:@"'" options:NSLiteralSearch range:NSMakeRange( 0, self.length )];
	[self replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSLiteralSearch range:NSMakeRange( 0, self.length )];
}

#pragma mark -

- (void) escapeCharactersInSet:(NSCharacterSet *) set {
	NSRange range = [self rangeOfCharacterFromSet:set];
	if( range.location == NSNotFound )
		return;

	NSScanner *scanner = [[NSScanner alloc] initWithString:self];

	NSUInteger offset = 0;
	while( ! [scanner isAtEnd] ) {
		[scanner scanUpToCharactersFromSet:set intoString:nil];
		if( ! [scanner isAtEnd] ) {
			[self insertString:@"\\" atIndex:[scanner scanLocation] + offset++];
			[scanner setScanLocation:[scanner scanLocation] + 1];
		}
	}

	[scanner release];
}

- (void) replaceCharactersInSet:(NSCharacterSet *) set withString:(NSString *) string {
	NSRange range = NSMakeRange(0, self.length);
	NSUInteger stringLength = string.length;

	NSRange replaceRange;
	while( ( replaceRange = [self rangeOfCharacterFromSet:set options:NSLiteralSearch range:range] ).location != NSNotFound ) {
		[self replaceCharactersInRange:replaceRange withString:string];

		range.location = replaceRange.location + stringLength;
		range.length = self.length - replaceRange.location;
	}
}

#pragma mark -

- (void) encodeIllegalURLCharacters {
	[self setString:[self stringByEncodingIllegalURLCharacters]];
}

- (void) decodeIllegalURLCharacters {
	[self setString:[self stringByDecodingIllegalURLCharacters]];
}

#pragma mark -

- (void) stripIllegalXMLCharacters {
	NSCharacterSet *illegalSet = [NSCharacterSet illegalXMLCharacterSet];
	NSRange range = [self rangeOfCharacterFromSet:illegalSet];
	while( range.location != NSNotFound ) {
		[self deleteCharactersInRange:range];
		range = [self rangeOfCharacterFromSet:illegalSet];
	}
}

- (void) stripXMLTags {
	NSRange searchRange = NSMakeRange(0, self.length);
	while (1) {
		NSRange tagStartRange = [self rangeOfString:@"<" options:NSLiteralSearch range:searchRange];
		if (tagStartRange.location == NSNotFound)
			break;

		NSRange tagEndRange = [self rangeOfString:@">" options:NSLiteralSearch range:NSMakeRange(tagStartRange.location, (self.length - tagStartRange.location))];
		if (tagEndRange.location == NSNotFound)
			break;

		[self deleteCharactersInRange:NSMakeRange(tagStartRange.location, (NSMaxRange(tagEndRange) - tagStartRange.location))];

		searchRange = NSMakeRange(tagStartRange.location, (self.length - tagStartRange.location));
	}
}

@end