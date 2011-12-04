//
//  AIIPAccount.h
//  IRC++
//
//  Created by Thijs Alkemade on 04-12-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIAccount.h>
#import <ChatCore/MVChatConnection.h>

@interface AIIPAccount : AIAccount {
	MVChatConnection *connection;
}

@end
