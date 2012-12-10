//
//  BorderedImageView.m
//  Unbound
//
//  Created by Scott Sykora on 11/18/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "BorderedImageView.h"
 #import <QuartzCore/QuartzCore.h>

@interface BorderedImageView ()
{
    
}

@property (strong, nonatomic) CALayer * borderLayer;
@property (strong, nonatomic) CALayer * shadowLayer;

@end

@implementation BorderedImageView





-(void)setObjectValue:(id<NSCopying>)obj
{
    [super setObjectValue:obj];
    
    if(self.image == nil)
    {
        self.image = [NSImage imageNamed:@"temp-portrait"];
        return;
    }
    
    [self setupBorder];
        
}

-(void)setImage:(NSImage *)newImage
{
    [super setImage:newImage];
    [self setupBorder];
}

-(void)setupBorder
{
    // make this a layer hosting view, not a layer backed view
    //self.layer = [CALayer layer];
    [self setWantsLayer:YES];
    
    // calculate the proportional image frame
    CGSize imageSize = [self.image size];
    
    CGRect imageFrame = CGRectMake(0, 0, imageSize.width, imageSize.height);
    
    if(imageSize.width > 0 && imageSize.height > 0)
    {
        if(imageSize.width / imageSize.height > self.bounds.size.width / self.bounds.size.height)
        {
            float mulitplier = self.bounds.size.width / imageSize.width;
            
            imageFrame.size.width = mulitplier * imageFrame.size.width;
            imageFrame.size.height = mulitplier * imageFrame.size.height;
            
            imageFrame.origin.y = (self.bounds.size.height - imageFrame.size.height)/2;
        }
        
        else
        {
            float mulitplier = self.bounds.size.height / imageSize.height;
            
            imageFrame.size.width = mulitplier * imageFrame.size.width;
            imageFrame.size.height = mulitplier * imageFrame.size.height;
            
            imageFrame.origin.x = (self.bounds.size.width - imageFrame.size.width)/2;
        }
    }
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    
    imageFrame = CGRectInset(imageFrame, -2, -2);
    
    // do your sublayer rearrangement here
    [self.borderLayer setFrame:imageFrame];
    [self.shadowLayer setFrame:imageFrame];
    _shadowLayer.contents = self.image;
    
    [CATransaction commit];
    
    //[self.layer setShouldRasterize:YES];
    

}

-(void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    if(_selected)
    {
        self.borderLayer.borderColor = CGColorCreateGenericRGB(0.189, 0.657, 0.859, 1.000);
        self.borderLayer.cornerRadius = 4.0;
        self.shadowLayer.cornerRadius = 4.0;
    }
    
    else
    {
        self.borderLayer.borderColor = [[NSColor whiteColor] CGColor];
        self.borderLayer.cornerRadius = 0;
        self.shadowLayer.cornerRadius = 0;
    }
}


-(CALayer *)borderLayer
{
    if(_borderLayer != nil) return _borderLayer;
    
    _borderLayer = [CALayer layer];
    
    _borderLayer.borderColor = [[NSColor whiteColor] CGColor];
    _borderLayer.borderWidth = 6;
    _borderLayer.zPosition = 1;
    
    //[self setWantsLayer:YES];
    [self.layer addSublayer:_borderLayer];
    
    return _borderLayer;
}


-(void)drawRect:(NSRect)dirtyRect
{
    // do nothing here, everything is drawn using layers

}


-(CALayer *)shadowLayer
{
    if(_shadowLayer != nil) return _shadowLayer;
    
    _shadowLayer = [CALayer layer];
    
    
    CGColorRef color = CGColorCreateGenericGray(1.0, 1.0);
    [_shadowLayer setBackgroundColor:color];
    [_shadowLayer setShadowOpacity:0.5];
    CFRelease(color);
    
    /*
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, _shadowLayer.bounds);
    
    [photoBackgroundLayer setShadowPath:path];
    CGPathRelease(path);*/
    
    _shadowLayer.zPosition = 0;
    
    //[self setWantsLayer:YES];
    [self.layer addSublayer:_shadowLayer];
    
    return _shadowLayer;
}


@end
