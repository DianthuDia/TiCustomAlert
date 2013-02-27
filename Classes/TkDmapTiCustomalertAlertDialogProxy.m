/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2013年 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TkDmapTiCustomalertAlertDialogProxy.h"
#import "TiUtils.h"

static NSCondition* alertCondition;
static BOOL alertShowing = NO;

    // copy from TiUIAlertDialogProxy.m
@implementation TkDmapTiCustomalertAlertDialogProxy
-(void)_destroy
{
    if (alert != nil) {
        [alertCondition lock];
        alertShowing = NO;
        [alertCondition broadcast];
        [alertCondition unlock];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	RELEASE_TO_NIL(alert);
	[super _destroy];
}

-(NSMutableDictionary*)langConversionTable
{
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"title",@"titleid",
			@"ok",@"okid",
			@"message",@"messageid",
			nil];
}

-(void) cleanup
{
	if(alert != nil)
        {
		[alertCondition lock];
		alertShowing = NO;
		[alertCondition broadcast];
		[alertCondition unlock];
		[self forgetSelf];
		[self autorelease];
		RELEASE_TO_NIL(alert);
		[[NSNotificationCenter defaultCenter] removeObserver:self];
        }
}

-(void)hide:(id)args
{
	ENSURE_SINGLE_ARG_OR_NIL(args,NSDictionary);
	ENSURE_UI_THREAD_1_ARG(args);
	
	if (alert!=nil)
        {
            //On IOS5 sometimes the delegate does not get called when hide is called soon after show
            //So we do the cleanup here itself
		
            //Remove ourselves as the delegate. This ensures didDismissWithButtonIndex is not called on dismissWithClickedButtonIndex
		[alert setDelegate:nil];
		BOOL animated = [TiUtils boolValue:@"animated" properties:args def:YES];
		[alert dismissWithClickedButtonIndex:[alert cancelButtonIndex] animated:animated];
		[self cleanup];
        }
}

-(void)show:(id)args
{
	if (alertCondition==nil)
        {
		alertCondition = [[NSCondition alloc] init];
        }
	
        // prevent more than one JS thread from showing an alert box at a time
	if ([NSThread isMainThread]==NO)
        {
		[self rememberSelf];
		
		[alertCondition lock];
		if (alertShowing)
            {
			[alertCondition wait];
            }
		alertShowing = YES;
		[alertCondition unlock];
            // alert show should block the JS thread like the browser
		TiThreadPerformOnMainThread(^{[self show:args];}, YES);
        }
	else
        {
		RELEASE_TO_NIL(alert);
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(suspended:) name:kTiSuspendNotification object:nil];
		
		NSMutableArray *buttonNames = [self valueForKey:@"buttonNames"];
		if (buttonNames==nil || (id)buttonNames == [NSNull null])
            {
			buttonNames = [[[NSMutableArray alloc] initWithCapacity:2] autorelease];
			NSString *ok = [self valueForUndefinedKey:@"ok"];
			if (ok==nil)
                {
				ok = @"OK";
                }
			[buttonNames addObject:ok];
            }
		
		alert = [[UIAlertView alloc] initWithTitle:[TiUtils stringValue:[self valueForKey:@"title"]]
                                           message:[TiUtils stringValue:[self valueForKey:@"message"]]
                                          delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
		for (id btn in buttonNames)
            {
			NSString * thisButtonName = [TiUtils stringValue:btn];
			[alert addButtonWithTitle:thisButtonName];
            }
        
		[alert setCancelButtonIndex:[TiUtils intValue:[self valueForKey:@"cancel"] def:-1]];
		
            // 'iOSView' property
        TiViewProxy* iOSViewProxy = [self valueForKey:@"iOSView"];
        if (iOSViewProxy != nil)
            {
            [alert addSubview:[iOSViewProxy view]];
            }
        
		[self retain];
		[alert show];
        }
}

-(void)suspended:(NSNotification*)note
{
	[self hide:[NSDictionary dictionaryWithObject:NUMBOOL(NO) forKey:@"animated"]];
}

#pragma mark AlertView Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	[self cleanup];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if ([self _hasListeners:@"click"])
        {
		NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithInt:buttonIndex],@"index",
							   [NSNumber numberWithInt:[alertView cancelButtonIndex]],@"cancel",
							   nil];
		[self fireEvent:@"click" withObject:event];
        }
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
        // Find "TiUIView" and "UILabel"
    CGFloat tiHeight = 0;
    UIView* tiView = nil;
    UIView* lastLabelView = nil;
    for (UIView* subView in alertView.subviews)
        {
        if ([subView isKindOfClass:NSClassFromString(@"TiUIView")])
            {
            tiView = subView;
            tiHeight = tiView.frame.size.height;
            }
        if ([subView isKindOfClass:NSClassFromString(@"UILabel")])
            {
            lastLabelView = subView;
            }
        }

        // Expand UIAlertView
    CGRect frame = alertView.frame;
    alertView.frame = CGRectMake(frame.origin.x, frame.origin.y - tiHeight/2,
                                 frame.size.width, frame.size.height + tiHeight);

        // Move buttonView
    for (UIView* subView in alertView.subviews)
        {
        if ([subView isKindOfClass:NSClassFromString(@"UIThreePartButton")] ||  // 4.x
            [subView isKindOfClass:NSClassFromString(@"UIAlertButton")])    // > 5.x
            {
            CGRect frame = subView.frame;
            subView.frame = CGRectMake(frame.origin.x, frame.origin.y + tiHeight,
                                       frame.size.width, frame.size.height);
            }
    }
    
        // Move TiUIView
    if (tiView != nil)
        {
        CGRect frame = tiView.frame;
        CGFloat y = (lastLabelView==nil)? 0:
            lastLabelView.frame.origin.y + lastLabelView.frame.size.height; // bottom of frame of label
        tiView.frame = CGRectMake(frame.origin.x, frame.origin.y+y, frame.size.width, frame.size.height);
        }
}

@end
