/******************************************************************************\
* Copyright (C) 2012-2013 Leap Motion, Inc. All rights reserved.               *
* Leap Motion proprietary and confidential. Not for distribution.              *
* Use subject to the terms of the Leap Motion SDK Agreement available at       *
* https://developer.leapmotion.com/sdk_agreement, or another agreement         *
* between Leap Motion and you, your company or other organization.             *
\******************************************************************************/

#import "PIXLeapInputManager.h"
#import "LeapObjectiveC.h"


@interface PIXLeapInputManager( )<LeapListener, LeapDelegate>

@property (strong) LeapController *controller;
@property NSMutableArray * leapResponders;
@property NSRect screenRect;

@property BOOL swipeGestureFlag;

@property CGFloat pinchStartWidth;
@property CGFloat pinchStartDepth;
@property NSPoint pinchStartPosition;

@end

@implementation PIXLeapInputManager



+(PIXLeapInputManager *)sharedInstance
{
    __strong static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)run
{
    // hard coded screen position:
    
    self.screenRect = CGRectMake(-120, 130, 240, 200);
    
    self.controller = [[LeapController alloc] init];
    [self.controller addListener:self];

    NSLog(@"running");
    //[[NSRunLoop currentRunLoop] run]; // required for performSelectorOnMainThread:withObject
}

- (void)addResponder:(id<leapResponder>)aResponder
{
    if(aResponder == nil)return;
    
    if(self.leapResponders == nil)
    {
        self.leapResponders = [NSMutableArray new];
    }
    
    [self.leapResponders insertObject:aResponder atIndex:0];
}

- (void)removeResponder:(id<leapResponder>)aResponder
{
    NSUInteger index = [self.leapResponders indexOfObject:aResponder];
    while(index != NSNotFound)
    {
        [self.leapResponders removeObjectAtIndex:index];
        index = [self.leapResponders indexOfObject:aResponder];
    }
}

#pragma mark - SampleListener Callbacks

- (void)onInit:(NSNotification *)notification
{
    DLog(@"Leap Initialized");
}

- (void)onConnect:(NSNotification *)notification;
{
    DLog(@"Leap Connected");
    LeapController *aController = (LeapController *)[notification object];
    [aController enableGesture:LEAP_GESTURE_TYPE_CIRCLE enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_KEY_TAP enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_SCREEN_TAP enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_SWIPE enable:YES];
}

- (void)onDisconnect:(NSNotification *)notification;
{
    DLog(@"Leap Disconnected");
}

- (void)onExit:(NSNotification *)notification;
{
    DLog(@"Leap Exited");
}

- (void)onFrame:(NSNotification *)notification;
{
    LeapController *aController = (LeapController *)[notification object];

    // Get the most recent frame and report some basic information
    LeapFrame *frame = [aController frame:0];
    
    NSPoint normalizedPoint = CGPointZero;
    
    NSMutableArray *fingers = [NSMutableArray new];
    

    
    for(LeapHand * hand in [frame hands])
    {
        [fingers addObjectsFromArray:[hand fingers]];
    }
    
    
    if ([fingers count] != 0) {
        
        // Calculate the hand's average finger tip position
        LeapVector *avgPos = [[LeapVector alloc] init];
        for (int i = 0; i < [fingers count]; i++) {
            LeapFinger *finger = [fingers objectAtIndex:i];
            avgPos = [avgPos plus:[finger tipPosition]];
        }
        
        avgPos = [avgPos divide:[fingers count]];
        
        
        
                     
        // normalize the point so it's between 0 and 1 in both directions
        
        normalizedPoint.x = (avgPos.x - self.screenRect.origin.x)/self.screenRect.size.width;
        normalizedPoint.y = (avgPos.y - self.screenRect.origin.y)/self.screenRect.size.height;
        
        if(normalizedPoint.x < 0.0) normalizedPoint.x = 0.0;
        if(normalizedPoint.y < 0.0) normalizedPoint.y = 0.0;
        if(normalizedPoint.x > 1.0) normalizedPoint.x = 1.0;
        if(normalizedPoint.y > 1.0) normalizedPoint.y = 1.0;
        
        
        // handle two finger pinch
        if([fingers count] == 2)
        {
            LeapFinger *finger1 = [fingers objectAtIndex:0];
            LeapFinger *finger2 = [fingers objectAtIndex:1];
            
            CGFloat deltax= finger2.tipPosition.x - finger1.tipPosition.x;
            CGFloat deltay= finger2.tipPosition.y - finger1.tipPosition.y;
            CGFloat deltaz= finger2.tipPosition.z - finger1.tipPosition.z;
            
            CGFloat pinchDistance = sqrt((deltax*deltax)+(deltay*deltay)+(deltaz*deltaz));
            CGFloat pinchDepth = avgPos.z;
           
            // if this is mid pinch, call the responder with the deltas
            if(self.pinchStartWidth > 0)
            {
                // scale change in depth:
                CGFloat distanceChange = pinchDistance / self.pinchStartWidth;
                
                // make this a bit less sensitive
                //distanceChange = ((distanceChange - 1.0) / 10.0)+1.0;
                
                CGFloat depthChange = pinchDepth - self.pinchStartDepth;
                
                depthChange = (-depthChange / 200.0) + 1;
                
                
                // 
                
                
                CGFloat scaleDelta =  distanceChange * depthChange;
                
                NSPoint positionDelta = NSMakePoint(normalizedPoint.x - self.pinchStartPosition.x,
                                                    normalizedPoint.y - self.pinchStartPosition.y);
                
                // loop through the responders
                for(id<leapResponder> responder in self.leapResponders)
                {
                    if([responder respondsToSelector:@selector(twoFingerPinchPosition:andScale:)])
                    {
                        [responder twoFingerPinchPosition:positionDelta andScale:scaleDelta];
                        break; // do nothing else after we hit the first responder
                    }
                }
                
            }
            
            // this will always be called at the start
            else
            {
                self.pinchStartWidth = pinchDistance;
                self.pinchStartDepth = pinchDepth;
                self.pinchStartPosition = normalizedPoint;
                
                // loop through the responders
                for(id<leapResponder> responder in self.leapResponders)
                {
                    if([responder respondsToSelector:@selector(twoFingerPinchStart)])
                    {
                        [responder twoFingerPinchStart];
                        break; // do nothing else after we hit the first responder
                    }
                }
            }
            
        }
        
        else
        {
            // clear out any pinch gesture values
            self.pinchStartWidth = -1;
            self.pinchStartDepth = -1;
            self.pinchStartPosition = NSZeroPoint;
        }
        
        // handle the single finger point
        if([fingers count] == 1)
        {
            // loop through the responders
            for(id<leapResponder> responder in self.leapResponders)
            {
                if([responder respondsToSelector:@selector(singleFingerPoint:)])
                {
                    [responder singleFingerPoint:normalizedPoint];
                    break; // do nothing else after we hit the first responder
                }
            }
        }
        
        
    }
  
    
    
    NSArray *gestures = [frame gestures:nil];
    for (int g = 0; g < [gestures count]; g++) {
        LeapGesture *gesture = [gestures objectAtIndex:g];
        switch (gesture.type) {
            case LEAP_GESTURE_TYPE_CIRCLE: {
                LeapCircleGesture *circleGesture = (LeapCircleGesture *)gesture;
                // Calculate the angle swept since the last frame
                float sweptAngle = 0;
                if(circleGesture.state != LEAP_GESTURE_STATE_START) {
                    //LeapCircleGesture *previousUpdate = (LeapCircleGesture *)[[aController frame:1] gesture:gesture.id];
                    //sweptAngle = (circleGesture.progress - previousUpdate.progress) * 2 * LEAP_PI;
                }
                
//                NSLog(@"Circle id: %d, %@, progress: %f, radius %f, angle: %f degrees",
//                      circleGesture.id, [PIXLeapInputManager stringForState:gesture.state],
//                      circleGesture.progress, circleGesture.radius, sweptAngle * LEAP_RAD_TO_DEG);
                
                if(circleGesture.progress > 0.7 && circleGesture.radius < 10.0 && circleGesture.state == LEAP_GESTURE_STATE_STOP)
                {
                    // loop through the responders
                    for(id<leapResponder> responder in self.leapResponders)
                    {
                        if([responder respondsToSelector:@selector(singleFingerSelect:)])
                        {
                            [responder singleFingerSelect:normalizedPoint];
                            break; // no need to keep going down the responder chain
                        }
                    }
                }
                
                return;
                break;
            }
            case LEAP_GESTURE_TYPE_SWIPE: {
                LeapSwipeGesture *swipeGesture = (LeapSwipeGesture *)gesture;
//                NSLog(@"Swipe id: %d, %@, position: %@, direction: %@, speed: %f",
//                      swipeGesture.id, [PIXLeapInputManager stringForState:swipeGesture.state],
//                      swipeGesture.position, swipeGesture.direction, swipeGesture.speed);
                
                
                
                if (swipeGesture.state == LEAP_GESTURE_STATE_START) {

                    
                    if(!self.swipeGestureFlag)
                    {
                        [self handleSwipe:(LeapSwipeGesture *)swipeGesture];
                        
                    }
                    
                    
                }
                
                if(swipeGesture.state == LEAP_GESTURE_STATE_STOP || swipeGesture.state == LEAP_GESTURE_STATE_INVALID)
                {
                    //self.swipeGestureFlag = NO;
                }
                
                
                break;
            }
            case LEAP_GESTURE_TYPE_KEY_TAP: {
                LeapKeyTapGesture *keyTapGesture = (LeapKeyTapGesture *)gesture;
//                NSLog(@"Key Tap id: %d, %@, position: %@, direction: %@",
//                      keyTapGesture.id, [PIXLeapInputManager stringForState:keyTapGesture.state],
//                      keyTapGesture.position, keyTapGesture.direction);
                
                break;
            }
            case LEAP_GESTURE_TYPE_SCREEN_TAP: {
                LeapScreenTapGesture *screenTapGesture = (LeapScreenTapGesture *)gesture;
                //NSLog(@"Screen Tap id: %d, %@, position: %@, direction: %@",
//                      screenTapGesture.id, [PIXLeapInputManager stringForState:screenTapGesture.state],
//                      screenTapGesture.position, screenTapGesture.direction);
                
                if(screenTapGesture.state == LEAP_GESTURE_STATE_STOP)
                {
                    // loop through the responders
                    for(id<leapResponder> responder in self.leapResponders)
                    {
                        if([responder respondsToSelector:@selector(singleFingerSelect:)])
                        {
                            [responder singleFingerSelect:normalizedPoint];
                            break; // no need to keep going down the responder chain
                        }
                    }
                }
                
                break;
            }
            default:
                //NSLog(@"Unknown gesture type");
                break;
        }
    }
    
    
    
    

}

-(void)handleSwipe:(LeapSwipeGesture *)swipeGesture
{
    LeapVector * direction = swipeGesture.direction;
    BOOL didswipe = NO;
    
    // figure out the gesture direction
    if(direction.y > 0.7) // this is the up direction
    {
        // loop through the responders
        for(id<leapResponder> responder in self.leapResponders)
        {
            if([responder respondsToSelector:@selector(multiFingerSwipeUp)])
            {
                [responder multiFingerSwipeUp];
                break; // no need to keep going down the responder chain
            }
        }
        
        didswipe = YES;
    }
    
    else if(direction.y < -0.7) // this is the down direction
    {
        // loop through the responders
        for(id<leapResponder> responder in self.leapResponders)
        {
            if([responder respondsToSelector:@selector(multiFingerSwipeDown)])
            {
                [responder multiFingerSwipeDown];
                break; // no need to keep going down the responder chain
            }
        }
        
        didswipe = YES;
    }
    
    else if(direction.x > 0.7) // this is the right direction
    {
        // loop through the responders
        for(id<leapResponder> responder in self.leapResponders)
        {
            if([responder respondsToSelector:@selector(multiFingerSwipeRight)])
            {
                [responder multiFingerSwipeRight];
                break; // no need to keep going down the responder chain
            }
        }
        
        didswipe = YES;
    }
    
    else if(direction.x < -0.7) // this is the left direction
    {
        // loop through the responders
        for(id<leapResponder> responder in self.leapResponders)
        {
            if([responder respondsToSelector:@selector(multiFingerSwipeLeft)])
            {
                [responder multiFingerSwipeLeft];
                break; // no need to keep going down the responder chain
            }
        }
        
        didswipe = YES;
    }
    
    
    if(didswipe)
    {
        self.swipeGestureFlag = YES;
        
        double delayInSeconds = 0.7;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.swipeGestureFlag = NO;
        });
    }
}

+ (NSString *)stringForState:(LeapGestureState)state
{
    switch (state) {
        case LEAP_GESTURE_STATE_INVALID:
            return @"STATE_INVALID";
        case LEAP_GESTURE_STATE_START:
            return @"STATE_START";
        case LEAP_GESTURE_STATE_UPDATE:
            return @"STATE_UPDATED";
        case LEAP_GESTURE_STATE_STOP:
            return @"STATE_STOP";
        default:
            return @"STATE_INVALID";
    }
}


@end
