//
//  AIIPAccount.m
//  IRC++
//
//  Created by Thijs Alkemade on 04-12-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AIIPAccount.h"
#import "NSAttributedStringAdditions.h"
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

- (BOOL)groupChatsSupportTopic
{
	return YES;
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
	connection.alternateNicknames = [self preferenceForKey:KEY_IRC_ALTNICKS
													 group:GROUP_ACCOUNT_STATUS];
	
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

- (NSString *)displayName
{
	if (connection) {
		return connection.nickname;
	}
	
	return self.formattedUID;
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
		if ([user username] && [user address]) {
			[contact setValue:[NSString stringWithFormat:@"%@@%@", [user username], [user address]] forProperty:@"User Host" notify:NotifyNever];
		}
		[contact setOnline:TRUE notify:NotifyNever silently:YES];
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
	NSData *reason = [[notification userInfo] valueForKey:@"reason"];
	
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
	
	NSAttributedString *message;
	
	if (reason) {
		message = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ left the room (", @"", [NSBundle bundleForClass:[self class]], nil), [user displayName]]] autorelease];
		[(NSMutableAttributedString *)message appendAttributedString:[NSAttributedString attributedStringWithChatFormat:reason options:nil]];
		[(NSMutableAttributedString *)message appendAttributedString:[[[NSAttributedString alloc] initWithString:@")."] autorelease]];
	} else {
		message = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ left the room.", @"", [NSBundle bundleForClass:[self class]], nil), [user displayName]]] autorelease];
	}
	
	AIContentEvent *event = [AIContentEvent eventInChat:chat
											 withSource:nil
											destination:self
												   date:[NSDate date]
												message:message
											   withType:@"IRC++"];
	
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
	
	NSString *userHost = nil;
	
	if ([user address] && [user username]) {
		userHost = [NSString stringWithFormat:@"%@@%@", [user username], [user address]];
	}
	
	[contact setServersideAlias:[user displayName] silently:NO];
	[contact setValue:[user realName] forProperty:@"Real Name" notify:NotifyNever];
	[contact setValue:userHost forProperty:@"User Host" notify:NotifyNever];
	[contact setOnline:TRUE notify:NotifyNever silently:YES];
	
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
	
	[chat setTopic:[[NSAttributedString attributedStringWithChatFormat:[room topic] options:nil] string]];
}

- (void)roomModeChanged:(NSNotification *)notification
{
	AILogWithSignature(@"%@", notification);
}

- (void)memberModeChanged:(NSNotification *)notification
{
	MVChatRoom *room = [notification object];
	AIChat *chat = [room attributeForKey:@"AIChat"];
	
	AILogWithSignature(@"%@", notification);
	
	AIListContact *user = [self contactWithUID:[[[notification userInfo] objectForKey:@"who"] displayName]];
	
	NSUInteger mode = [[[notification userInfo] objectForKey:@"mode"] unsignedLongValue];
    BOOL on = [[[notification userInfo] objectForKey:@"enabled"] boolValue];
	
	AIGroupChatFlags newFlag = convertFlags(mode, 0);
	
	AIGroupChatFlags flags = [chat flagsForContact:user];
	
	if (on) {
		flags |= newFlag;
	} else {
		flags &= ~newFlag;
	}
	
	[chat setFlags:flags forContact:user];
	
	MVChatUser *_user = [[notification userInfo] objectForKey:@"who"];
	MVChatUser *_byUser = [[notification userInfo] objectForKey:@"by"];
	
	NSString *message = nil;
	
	if( mode == MVChatRoomMemberFounderMode && enabled ) {
		if( [_user isLocalUser] && [_byUser isLocalUser] ) { // only server oppers would ever see this
			message = NSLocalizedString( @"You promoted yourself to room founder.", "we gave ourself the chat room founder privilege status message" );
		} else if( [_user isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"You were promoted to room founder by %@.", "we are now a chat room founder status message" ), [_byUser nickname]];
		} else if( [_byUser isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was promoted to room founder by you.", "we gave user chat room founder status message" ), [_user nickname]];
		} else {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was promoted to room founder by %@.", "user is now a chat room founder status message" ), [_user nickname], [_byUser nickname]];
		}
	} else if( mode == MVChatRoomMemberFounderMode && ! enabled ) {
		if( [_user isLocalUser] && [_byUser isLocalUser] ) {
			message = NSLocalizedString( @"You demoted yourself from room founder.", "we removed our chat room founder privilege status message" );
		} else if( [_user isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"You were demoted from room founder by %@.", "we are no longer a chat room founder status message" ), [_byUser nickname]];
		} else if( [_byUser isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was demoted from room founder by you.", "we removed user's chat room founder status message" ), [_user nickname]];
		} else {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was demoted from room founder by %@.", "user is no longer a chat room founder status message" ), [_user nickname], [_byUser nickname]];
		}
	} else if( mode == MVChatRoomMemberAdministratorMode && enabled ) {
		if( [_user isLocalUser] && [_byUser isLocalUser] ) { // only server oppers would ever see this
			message = NSLocalizedString( @"You promoted yourself to Administrator.", "we gave ourself the chat room administrator privilege status message" );
		} else if( [_user isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"You were promoted to administrator by %@.", "we are now a chat room administrator status message" ), [_byUser nickname]];
		} else if( [_byUser isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was promoted to administrator by you.", "we gave user chat room administrator status message" ), [_user nickname]];
		} else {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was promoted to administrator by %@.", "user is now a chat room administrator status message" ), [_user nickname], [_byUser nickname]];
		}
	} else if( mode == MVChatRoomMemberAdministratorMode && ! enabled ) {
		if( [_user isLocalUser] && [_byUser isLocalUser] ) {
			message = NSLocalizedString( @"You demoted yourself from administrator.", "we removed our chat room administrator privilege status message" );
		} else if( [_user isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"You were demoted from administrator by %@.", "we are no longer a chat room administrator status message" ), [_byUser nickname]];
		} else if( [_byUser isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was demoted from administrator by you.", "we removed user's chat room administrator status message" ), [_user nickname]];
		} else {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was demoted from administrator by %@.", "user is no longer a chat room administrator status message" ), [_user nickname], [_byUser nickname]];
		}
	} else if( mode == MVChatRoomMemberOperatorMode && enabled ) {
		if( [_user isLocalUser] && [_byUser isLocalUser] ) { // only server oppers would ever see this
			message = NSLocalizedString( @"You promoted yourself to operator.", "we gave ourself the chat room operator privilege status message" );
		} else if( [_user isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"You were promoted to operator by %@.", "we are now a chat room operator status message" ), [_byUser nickname]];
		} else if( [_byUser isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was promoted to operator by you.", "we gave user chat room operator status message" ), [_user nickname]];
		} else {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was promoted to operator by %@.", "user is now a chat room operator status message" ), [_user nickname], [_byUser nickname]];
		}
	} else if( mode == MVChatRoomMemberOperatorMode && ! enabled ) {
		if( [_user isLocalUser] && [_byUser isLocalUser] ) {
			message = NSLocalizedString( @"You demoted yourself from operator.", "we removed our chat room operator privilege status message" );
		} else if( [_user isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"You were demoted from operator by %@.", "we are no longer a chat room operator status message" ), [_byUser nickname]];
		} else if( [_byUser isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was demoted from operator by you.", "we removed user's chat room operator status message" ), [_user nickname]];
		} else {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was demoted from operator by %@.", "user is no longer a chat room operator status message" ), [_user nickname], [_byUser nickname]];
		}
	} else if( mode == MVChatRoomMemberHalfOperatorMode && enabled ) {
		if( [_user isLocalUser] && [_byUser isLocalUser] ) { // only server oppers would ever see this
			message = NSLocalizedString( @"You promoted yourself to half-operator.", "we gave ourself the chat room half-operator privilege status message" );
		} else if( [_user isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"You were promoted to half-operator by %@.", "we are now a chat room half-operator status message" ), [_byUser nickname]];
		} else if( [_byUser isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was promoted to half-operator by you.", "we gave user chat room half-operator status message" ), [_user nickname]];
		} else {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was promoted to half-operator by %@.", "user is now a chat room half-operator status message" ), [_user nickname], [_byUser nickname]];
		}
	} else if( mode == MVChatRoomMemberHalfOperatorMode && ! enabled ) {
		if( [_user isLocalUser] && [_byUser isLocalUser] ) {
			message = NSLocalizedString( @"You demoted yourself from half-operator.", "we removed our chat room half-operator privilege status message" );
		} else if( [_user isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"You were demoted from half-operator by %@.", "we are no longer a chat room half-operator status message" ), [_byUser nickname]];
		} else if( [_byUser isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was demoted from half-operator by you.", "we removed user's chat room half-operator status message" ), [_user nickname]];
		} else {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was demoted from half-operator by %@.", "user is no longer a chat room half-operator status message" ), [_user nickname], [_byUser nickname]];
		}
	} else if( mode == MVChatRoomMemberVoicedMode && enabled ) {
		if( [_user isLocalUser] && [_byUser isLocalUser] ) {
			message = NSLocalizedString( @"You gave yourself voice.", "we gave ourself special voice status to talk in moderated rooms status message" );
		} else if( [_user isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"You were granted voice by %@.", "we now have special voice status to talk in moderated rooms status message" ), [_byUser nickname]];
		} else if( [_byUser isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was granted voice by you.", "we gave user special voice status to talk in moderated rooms status message" ), [_user nickname]];
		} else {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was granted voice by %@.", "user now has special voice status to talk in moderated rooms status message" ), [_user nickname], [_byUser nickname]];
		}
	} else if( mode == MVChatRoomMemberVoicedMode && ! enabled ) {
		if( [_user isLocalUser] && [_byUser isLocalUser] ) {
			message = NSLocalizedString( @"You removed voice from yourself.", "we removed our special voice status to talk in moderated rooms status message" );
		} else if( [_user isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"You had voice removed by %@.", "we no longer has special voice status and can't talk in moderated rooms status message" ), [_byUser nickname]];
		} else if( [_byUser isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ had voice removed by you.", "we removed user's special voice status and can't talk in moderated rooms status message" ), [_user nickname]];
		} else {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ had voice removed by %@.", "user no longer has special voice status and can't talk in moderated rooms status message" ), [_user nickname], [_byUser nickname]];
		}
	} else if( mode == MVChatRoomMemberQuietedMode && enabled ) {
		if( [_user isLocalUser] && [_byUser isLocalUser] ) {
			message = NSLocalizedString( @"You quieted yourself.", "we quieted and can't talk ourself status message" );
		} else if( [_user isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"You were quieted by %@.", "we are now quieted and can't talk status message" ), [_byUser nickname]];
		} else if( [_byUser isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was quieted by you.", "we quieted someone else in the room status message" ), [_user nickname]];
		} else {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ was quieted by %@.", "user was quieted by someone else in the room status message" ), [_user nickname], [_byUser nickname]];
		}
	} else if( mode == MVChatRoomMemberQuietedMode && ! enabled ) {
		if( [_user isLocalUser] && [_byUser isLocalUser] ) {
			message = NSLocalizedString( @"You made yourself no longer quieted.", "we are no longer quieted and can talk ourself status message" );
		} else if( [_user isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"You are no longer quieted, thanks to %@.", "we are no longer quieted and can talk status message" ), [_byUser nickname]];
		} else if( [_byUser isLocalUser] ) {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ is no longer quieted because of you.", "a user is no longer quieted because of us status message" ), [_user nickname]];
		} else {
			message = [NSString stringWithFormat:NSLocalizedString( @"%@ is no longer quieted because of %@.", "user is no longer quieted because of someone else in the room status message" ), [_user nickname], [_byUser nickname]];
		}
	}
	
	AIContentEvent *event = [AIContentEvent eventInChat:chat
											 withSource:nil
											destination:self
												   date:[NSDate date]
												message:[[[NSAttributedString alloc] initWithString:message] autorelease]
											   withType:@"IRC++"];
	
	event.filterContent = YES;
	
	[adium.contentController receiveContentObject:event];
}

- (void)memberBanned:(NSNotification *)notification
{
	AILogWithSignature(@"%@", notification);
}

- (void)memberBanRemoved:(NSNotification *)notification
{
	AILogWithSignature(@"%@", notification);
}

- (void)membersSynced:(NSNotification *)notification
{
	AILogWithSignature(@"%@", notification);
}

- (void)bannedMembersSynced:(NSNotification *)notification
{
	AILogWithSignature(@"%@", notification);
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
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(roomModeChanged:)
												 name:MVChatRoomModesChangedNotification
											   object:room];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(memberModeChanged:)
												 name:MVChatRoomUserModeChangedNotification
											   object:room];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(memberBanned:)
												 name:MVChatRoomUserBannedNotification
											   object:room];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(memberBanRemoved:)
												 name:MVChatRoomUserBanRemovedNotification
											   object:room];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(membersSynced:) 
												 name:MVChatRoomMemberUsersSyncedNotification
											   object:room];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(bannedMembersSynced:)
												 name:MVChatRoomBannedUsersSyncedNotification
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
