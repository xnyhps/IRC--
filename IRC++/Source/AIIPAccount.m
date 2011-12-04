//
//  AIIPAccount.m
//  IRC++
//
//  Created by Thijs Alkemade on 04-12-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AIIPAccount.h"
#import <Adium/AISharedAdium.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <ChatCore/MVChatRoom.h>
#import <ChatCore/MVChatUser.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentEvent.h>
#import <Adium/ESDebugAILog.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>

AIGroupChatFlags convertFlags(NSUInteger flags, MVChatUserStatus status);

@implementation AIIPAccount

- (NSString *)defaultUsername
{
	return @"Adium";
}

- (NSString *)defaultRealname
{
	return NSLocalizedStringFromTableInBundle(@"Adium User", @"", [NSBundle bundleForClass:[self class]] , nil);
}

- (void)didConnect:(NSNotification *)notification
{
	[super didConnect];
}

- (void)gotImportantMessage:(NSNotification *)notification
{
	AILog(@"(IRC++) %@ (important): %@", self.UID, [[notification userInfo] valueForKey:@"message"]);
}

- (void)gotInformationalMessage:(NSNotification *)notification
{
	AILog(@"(IRC++) %@ (info): %@", self.UID, [[notification userInfo] valueForKey:@"message"]);
}

- (void)gotRawMessage:(NSNotification *)notification
{
	AILog(@"(IRC++) %@ (raw): %@", self.UID, [[notification userInfo] valueForKey:@"message"]);
}

- (void)connect
{
	connection = [[MVChatConnection alloc] initWithServer:self.host type:MVChatConnectionIRCType port:self.port user:self.UID];
	
	connection.secure = [[self preferenceForKey:KEY_IRC_USE_SSL
										  group:GROUP_ACCOUNT_STATUS] boolValue];
	connection.requestsSASL = [[self preferenceForKey:KEY_IRC_USE_SASL
												group:GROUP_ACCOUNT_STATUS] boolValue];
	connection.username = [self preferenceForKey:KEY_IRC_USERNAME
										   group:GROUP_ACCOUNT_STATUS] ?: [self defaultUsername];
	connection.realName = [self preferenceForKey:KEY_IRC_REALNAME
										   group:GROUP_ACCOUNT_STATUS] ?: [self defaultRealname];
	connection.password = self.passwordWhileConnected;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(didConnect:)
												 name:MVChatConnectionDidConnectNotification
											   object:connection];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(gotImportantMessage:)
												 name:MVChatConnectionGotImportantMessageNotification
											   object:connection];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(gotInformationalMessage:)
												 name:MVChatConnectionGotInformationalMessageNotification
											   object:connection];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(gotRawMessage:)
												 name:MVChatConnectionGotRawMessageNotification
											   object:connection];
	
	[connection connect];
}

- (void)disconnect
{
	[connection disconnect];
	[connection release]; connection = nil;
}

AIGroupChatFlags convertFlags(NSUInteger flags, MVChatUserStatus status) {
	AIGroupChatFlags adiumFlags = 0;
	
	if (flags & MVChatRoomMemberVoicedMode) {
		adiumFlags |= AIGroupChatVoice;
	}
	if (flags & MVChatRoomMemberHalfOperatorMode) {
		adiumFlags |= AIGroupChatHalfOp;
	}
	if (flags & MVChatRoomMemberOperatorMode) {
		adiumFlags |= AIGroupChatOp;
	}
	if ((flags & MVChatRoomMemberAdministratorMode) || (flags & MVChatRoomMemberFounderMode)) {
		adiumFlags |= AIGroupChatFounder;
	}
	if (status & MVChatUserAwayStatus) {
		adiumFlags |= AIGroupChatAway;
	}
	
	return adiumFlags;
}

- (void)roomJoined:(NSNotification *)notification
{
	MVChatRoom *room = [notification object];
	AIChat *chat = [room attributeForKey:@"AIChat"];
	
	[adium.interfaceController openChat:chat];
	
	[chat setValue:[NSNumber numberWithBool:YES]
	   forProperty:@"accountJoined"
			notify:NotifyNow];
	
	NSMutableArray *newListObjects = [NSMutableArray array];
	
	for (MVChatUser *user in room.memberUsers) {
		
		AIListContact *contact = [self contactWithUID:[user displayName]];
		
		[contact setOnline:YES notify:NotifyNever silently:YES];
		
		[newListObjects addObject:contact];
	}
	
	[chat addParticipatingListObjects:newListObjects notify:NO];
	
	for (MVChatUser *user in room.memberUsers) {
		
		AIListContact *contact = [self contactWithUID:[user displayName]];
		
		[chat setAlias:[user displayName] forContact:contact];
		
		[chat setFlags:convertFlags([room modesForMemberUser:user], [user status])
			forContact:contact];
		
		[contact setServersideAlias:[user displayName] silently:NO];
		[contact setValue:[user realName] forProperty:@"Real Name" notify:NotifyNever];
		[contact setValue:[NSString stringWithFormat:@"%@@%@", [user username], [user address]] forProperty:@"User Host" notify:NotifyNever];
	}
	
	// Post an update notification now that we've modified the flags and names.
	[[NSNotificationCenter defaultCenter] postNotificationName:Chat_ParticipatingListObjectsChanged
														object:chat];
}

- (void)userParted:(NSNotification *)notification
{
	MVChatRoom *room = [notification object];
	AIChat *chat = [room attributeForKey:@"AIChat"];
	MVChatUser *user = [[notification userInfo] valueForKey:@"user"];
	NSString *reason = [[notification userInfo] valueForKey:@"reason"];
	
	AIListContact *contact = [self contactWithUID:[user displayName]];
	[chat removeObject:contact];
	
	if (contact.isStranger && 
		![adium.chatController allGroupChatsContainingContact:contact.parentContact].count &&
		[adium.chatController existingChatWithContact:contact.parentContact]) {
		// The contact is a stranger, not in any more group chats, but we have a message with them open.
		// Set their status to unknown.
		
		//		[contact setStatusWithName:nil
		//						statusType:AIOfflineStatusType
		//							notify:NotifyLater];
		//		
		//		[contact setValue:nil
		//			  forProperty:@"isOnline"
		//				   notify:NotifyLater];
		//		
		//		[contact notifyOfChangedPropertiesSilently:NO];
	}
	
	NSString *messageStr;
	
	if (reason) {
		messageStr = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ left the room (%@).", @"", [NSBundle bundleForClass:[self class]] , nil),
					  [user displayName]];
	} else {
		messageStr = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ left the room.", @"", [NSBundle bundleForClass:[self class]] , nil),
					  [user displayName], reason];
	}
	
	AIContentEvent *event = [AIContentEvent eventInChat:chat
											 withSource:nil
											destination:self
												   date:[NSDate date]
												message:[[[NSAttributedString alloc] initWithString:messageStr] autorelease]
											   withType:@"ChatCore"];
	
	event.filterContent = YES;
	
	[adium.contentController receiveContentObject:event];
}


- (void)userJoined:(NSNotification *)notification
{
	MVChatRoom *room = [notification object];
	AIChat *chat = [room attributeForKey:@"AIChat"];
	MVChatUser *user = [[notification userInfo] valueForKey:@"user"];
	
	AIListContact *contact = [self contactWithUID:[user displayName]];
	
	[chat addParticipatingListObject:contact notify:YES];
	
	[chat setAlias:[user displayName] forContact:contact];
	[chat setFlags:convertFlags([room modesForMemberUser:user], [user status])
		forContact:contact];
	
	NSString *userHost = [NSString stringWithFormat:@"%@@%@", [user username], [user address]];
	
	[contact setServersideAlias:[user displayName] silently:NO];
	[contact setValue:[user realName] forProperty:@"Real Name" notify:NotifyNever];
	[contact setValue:userHost forProperty:@"User Host" notify:NotifyNever];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:Chat_ParticipatingListObjectsChanged
														object:chat];
	
	NSString *messageStr = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ [%@] entered the room.", @"", [NSBundle bundleForClass:[self class]] , nil),
							[user displayName], userHost];
	
	AIContentEvent *event = [AIContentEvent eventInChat:chat
											 withSource:nil
											destination:self
												   date:[NSDate date]
												message:[[[NSAttributedString alloc] initWithString:messageStr] autorelease]
											   withType:@"ChatCore"];
	
	event.filterContent = NO;
	
	[adium.contentController receiveContentObject:event];
}

- (void)messageReceived:(NSNotification *)notification
{
	MVChatRoom *room = [notification object];
	AIChat *chat = [room attributeForKey:@"AIChat"];
	NSDictionary *userInfo = [notification userInfo];
	AIListContact *sourceContact = [self contactWithUID:[[userInfo valueForKey:@"user"] displayName]];
	NSData *message = [userInfo valueForKey:@"message"];
	
	if (!message) {
		return;
	}
	
	NSString *messageStr = [NSString stringWithUTF8String:[message bytes]];
	
	if (!messageStr) {
		return;
	}
	
	AIContentMessage *messageObject = [AIContentMessage messageInChat:chat
														   withSource:[[sourceContact UID] isEqualToString:[self UID]]? (AIListObject *)self : (AIListObject *)sourceContact
														  destination:self
																 date:[NSDate date]
															  message:[[[NSAttributedString alloc] initWithString:messageStr] autorelease]
															autoreply:NO];
	[adium.contentController receiveContentObject:messageObject];
}

- (void)topicChanged:(NSNotification *)notification
{
	MVChatRoom *room = [notification object];
	AIChat *chat = [room attributeForKey:@"AIChat"];
	
	[chat setTopic:[NSString stringWithUTF8String:[[room topic] bytes]]];
}

- (BOOL)openChat:(AIChat *)chat
{
	NSDictionary *chatCreationDict = [chat valueForProperty:@"chatCreationInfo"];
	NSString *name = [chatCreationDict objectForKey:@"channel"];
	
	[connection joinChatRoomNamed:name withPassphrase:[chatCreationDict objectForKey:@"password"]];
	
	MVChatRoom *room = [connection chatRoomWithName:name];
	
	[chat setIdentifier:room];
	[room setAttribute:chat forKey:@"AIChat"];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(roomJoined:)
												 name:MVChatRoomJoinedNotification
											   object:room];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(messageReceived:)
												 name:MVChatRoomGotMessageNotification
											   object:room];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(userJoined:)
												 name:MVChatRoomUserJoinedNotification
											   object:room];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(userParted:)
												 name:MVChatRoomUserPartedNotification
											   object:room];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(topicChanged:)
												 name:MVChatRoomTopicChangedNotification
											   object:room];
	
	chat.hideUserIconAndStatus = YES;
	
	return TRUE;
}

- (BOOL)sendMessageObject:(AIContentMessage *)inContentMessage
{
	MVChatRoom *room = (MVChatRoom *)[inContentMessage.chat identifier];
	NSString *messageString = inContentMessage.message.string;
	
	[room sendMessage:inContentMessage.message asAction:([messageString rangeOfString:@"/me " options:(NSCaseInsensitiveSearch | NSAnchoredSearch)].location == 0)];
	
	return YES;
}

@end
