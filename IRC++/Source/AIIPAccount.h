//
//  AIIPAccount.h
//  IRC++
//
//  Created by Thijs Alkemade on 04-12-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIAccount.h>
#import <ChatCore/MVChatConnection.h>

#define KEY_IRC_USE_SSL @"IRC: Use SSL"
#define KEY_IRC_USE_SASL @"IRC: Use SASL"
#define KEY_IRC_COMMANDS @"IRC: Commands"
#define KEY_IRC_USERNAME @"IRC: Username"
#define KEY_IRC_REALNAME @"IRC: Real name"

@interface AIIPAccount : AIAccount {
	MVChatConnection *connection;
}

- (NSString *)defaultUsername;
- (NSString *)defaultRealname;

@end
