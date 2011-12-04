//
//  AIIPPlugin.m
//  IRC++
//
//  Created by Thijs Alkemade on 04-12-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AIIPPlugin.h"
#import "AIIPService.h"

@implementation AIIPPlugin

- (void)installPlugin
{
	[AIIPService registerService];
}

@end
