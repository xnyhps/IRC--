//
//  AIIPService.m
//  IRC++
//
//  Created by Thijs Alkemade on 04-12-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AIIPService.h"
#import "AIIPAccount.h"
#import "AIIPAccountViewController.h"
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AICharacterSetAdditions.h>

@implementation AIIPService

- (Class)accountClass{
	return [AIIPAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [AIIPAccountViewController accountViewController];
}

//- (DCJoinChatViewController *)joinChatView{
//	return [ESIRCJoinChatViewController joinChatView];
//}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"chatcore-IRC";
}
- (NSString *)serviceID{
	return @"IRC";
}
- (NSString *)serviceClass{
	return @"IRC";
}
- (NSString *)shortDescription{
	return @"IRC";
}
- (NSString *)longDescription{
	return NSLocalizedStringFromTableInBundle(@"IRC (Internet Relay Chat)", @"", [NSBundle bundleForClass:[self class]] , nil);
}
- (NSCharacterSet *)allowedCharacters{
	//Per RFC-2812: http://www.ietf.org/rfc/rfc2812.txt
	NSMutableCharacterSet	*allowedCharacters = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
	NSCharacterSet			*returnSet;
	
	[allowedCharacters addCharactersInString:@"[]\\`_^{|}-"];
	returnSet = [allowedCharacters immutableCopy];
	[allowedCharacters release];
	
	return [returnSet autorelease];
}
- (BOOL)caseSensitive{
	return NO;
}
- (BOOL)canCreateGroupChats{
	return YES;
}
- (BOOL)supportsPassword{
	return YES;
}
//Passwords are supported but optional
- (BOOL)requiresPassword
{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServiceUnsupported;
}
/*!
 * @brief Placeholder string for the UID field
 */
- (NSString *)UIDPlaceholder
{
	return NSLocalizedStringFromTableInBundle(@"nickname", @"", [NSBundle bundleForClass:[self class]] , nil);
}
/*!
 * @brief Username label
 */
- (NSString *)userNameLabel
{
	return NSLocalizedStringFromTableInBundle(@"Nickname", @"", [NSBundle bundleForClass:[self class]] , nil);
}

/*!
 * @brief Default icon
 *
 * Service Icon packs should always include images for all the built-in Adium services.  This method allows external
 * service plugins to specify an image which will be used when the service icon pack does not specify one.  It will
 * also be useful if new services are added to Adium itself after a significant number of Service Icon packs exist
 * which do not yet have an image for this service.  If the active Service Icon pack provides an image for this service,
 * this method will not be called.
 *
 * The service should _not_ cache this icon internally; multiple calls should return unique NSImage objects.
 *
 * @param iconType The AIServiceIconType of the icon to return. This specifies the desired size of the icon.
 * @return NSImage to use for this service by default
 */
- (NSImage *)defaultServiceIconOfType:(AIServiceIconType)iconType
{
	if ((iconType == AIServiceIconSmall) || (iconType == AIServiceIconList)) {
		return [NSImage imageNamed:@"irc-small" forClass:[self class] loadLazily:YES];
	} else {
		return [NSImage imageNamed:@"irc" forClass:[self class] loadLazily:YES];
	}
}

/*!
 * @brief Path for default icon
 *
 * For use in message views, this is the path to a default icon as described above.
 *
 * @param iconType The AIServiceIconType of the icon to return.
 * @return The path to the image, otherwise nil.
 */
- (NSString *)pathForDefaultServiceIconOfType:(AIServiceIconType)iconType
{
	if ((iconType == AIServiceIconSmall) || (iconType == AIServiceIconList)) {
		return [[NSBundle bundleForClass:[self class]] pathForImageResource:@"irc-small"];
	} else {
		return [[NSBundle bundleForClass:[self class]] pathForImageResource:@"irc"];
	}
}


@end
