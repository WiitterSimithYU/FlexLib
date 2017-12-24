/**
 * Copyright (c) 2017-present, zhenglibao, Inc.
 * email: 798393829@qq.com
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */



#import "FlexRootView.h"
#import "YogaKit/UIView+Yoga.h"
#import "FlexNode.h"
#import "FlexModalView.h"
#import "ViewExt/UIView+Flex.h"
#import "FlexUtils.h"
#import "FlexStyleMgr.h"

static void* gObserverHidden    = (void*)1;
static void* gObserverText      = (void*)2;
static void* gObserverAttrText  = (void*)3;

static NSInteger _compareInputView(UIView * _Nonnull f,
                                   UIView * _Nonnull s,
                                   void * _Nullable context)
{
    CGPoint pt1 = f.viewAttrs.originInRoot;
    CGPoint pt2 = s.viewAttrs.originInRoot;
    if(pt1.y < pt2.y)
        return NSOrderedAscending;
    if(pt1.y > pt2.y)
        return NSOrderedDescending;
    if(pt1.x < pt2.x)
        return NSOrderedAscending;
    if(pt1.x > pt2.x)
        return NSOrderedDescending;
    return NSOrderedSame;
}

@implementation UIView(FlexPublic)

-(void)markDirty
{
    UIView* parent = self.superview;
    while(parent!=nil){
        if([parent isKindOfClass:[FlexRootView class]]){
            [(FlexRootView*)parent markChildDirty:self];
            break;
        }
        parent = parent.superview;
    }
}

-(void)markYogaDirty
{
    [self.yoga markDirty];
}
-(void)enableFlexLayout:(BOOL)enable
{
    self.yoga.isIncludedInLayout = enable;
}

-(BOOL)isFlexLayoutEnable{
    return self.yoga.isIncludedInLayout;
}

-(void)setViewAttr:(NSString*) name
             Value:(NSString*) value
{
    FlexSetViewAttr(self, name, value);
}
-(void)setViewAttrs:(NSArray<FlexAttr*>*)attrs
{
    for (FlexAttr* attr in attrs) {
        FlexSetViewAttr(self, attr.name, attr.value);
    }
}

-(void)setLayoutAttr:(NSString*) name
               Value:(NSString*) value
{
    FlexApplyLayoutParam(self.yoga, name, value);
}
-(void)setLayoutAttrs:(NSArray<FlexAttr*>*)attrs
{
    [self configureLayoutWithBlock:^(YGLayout* layout){
        for (FlexAttr* attr in attrs) {
            FlexApplyLayoutParam(layout, attr.name, attr.value);
        }
    }];
}
-(UIView*)findByName:(NSString*)name
{
    if([name compare:self.viewAttrs.name options:NSLiteralSearch]==NSOrderedSame)
        return self;
    
    for (UIView* sub in self.subviews) {
        UIView* find = [sub findByName:name];
        if(find != nil)
            return find;
    }
    return nil;
}
-(void)findAllViews:(NSMutableArray*)result Type:(Class)type
{
    for (UIView* sub in self.subviews) {
        if([sub isKindOfClass:type]){
            [result addObject:sub];
        }else if(sub.subviews.count>0){
            [sub findAllViews:result Type:type];
        }
    }
}
-(NSArray<UIView*>*)findAllInputs
{
    NSMutableArray<UIView*>* ary = [NSMutableArray array];
    
    [self findAllViews:ary Type:[UITextField class]];
    [self findAllViews:ary Type:[UITextView class]];
    
    for (UIView* sub in ary) {
        CGPoint pt = [self convertPoint:sub.frame.origin fromView:sub.superview];
        sub.viewAttrs.originInRoot = pt;
    }
    
    [ary sortUsingFunction:_compareInputView context:NULL];
    return [ary copy];
}
-(UIView*)findFirstResponder
{
    if(self.isFirstResponder)
        return self;
    
    for (UIView* sub in self.subviews) {
        if(sub.isFirstResponder)
            return sub;
        UIView* first = [sub findFirstResponder];
        if(first != nil)
            return first;
    }
    return nil;
}
@end

@interface FlexRootView()
{
    BOOL _bInLayouting;
    NSMutableSet<UIView*>* _observedViews;
    
    CGRect _lastConfigFrame;
    CGRect _thisConfigFrame;
    BOOL _bChildDirty;
 }
@end
@implementation FlexRootView

- (instancetype)init
{
    self = [super init];
    if (self) {
        _bInLayouting = NO ;
        _observedViews = [NSMutableSet set];
        _safeArea = UIEdgeInsetsMake(0, 0, 0, 0);
        _lastConfigFrame = CGRectZero;
        _bChildDirty = NO;
        self.yoga.isEnabled = YES;
    }
    return self;
}

-(UIView*)topSubView
{
    if(self.subviews.count>0){
        return self.subviews[0];
    }
    return nil;
}
+(FlexRootView*)loadWithNodeData:(NSData*)data
                           Owner:(NSObject*)owner
{
    FlexRootView* root = [[FlexRootView alloc]init];
    FlexNode* node = [FlexNode loadNodeData:data];
    if(node != nil){
        UIView* sub = [node buildViewTree:owner
                                 RootView:root];
        
        if(sub != nil && ![sub isKindOfClass:[FlexModalView class]])
        {
            [root addSubview:sub];
        }
    }
    root.yoga.isEnabled = YES;
    return root;
}
+(FlexRootView*)loadWithNodeFile:(NSString*)resName
                           Owner:(NSObject*)owner
{
    if(resName==nil){
        resName = NSStringFromClass([owner class]);
    }
    
    FlexRootView* root = [[FlexRootView alloc]init];
    FlexNode* node = [FlexNode loadNodeFromRes:resName];
    if(node != nil){
        UIView* sub = [node buildViewTree:owner
                                 RootView:root];
        
        if(sub != nil && ![sub isKindOfClass:[FlexModalView class]])
        {
            [root addSubview:sub];
        }
    }
    root.yoga.isEnabled = YES;
    return root;
}

- (void)dealloc
{
    for(UIView* subview in _observedViews)
    {
        [self removeWatchView:subview];
    }
}
-(void)registSubView:(UIView*)subView
{
    if([_observedViews containsObject:subView])
        return;
    
    [_observedViews addObject:subView];
    
    [subView addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:gObserverHidden];
    [subView addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:gObserverText];
    [subView addObserver:self forKeyPath:@"attributedText" options:0 context:gObserverAttrText];
}
-(void)removeWatchView:(UIView*)view
{
    if(view==nil)
        return;
    
    [view removeObserver:self forKeyPath:@"hidden"];
    [view removeObserver:self forKeyPath:@"text"];
    [view removeObserver:self forKeyPath:@"attributedText"];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(UIView*)object change:(NSDictionary *)change context:(void *)context
{
    if(_bInLayouting||object == nil)
        return;
    
    if( context == gObserverHidden ){
        BOOL n = [[change objectForKey:@"new"] boolValue];
        BOOL o = [[change objectForKey:@"old"] boolValue];
        if(n!=o){
            object.yoga.isIncludedInLayout = !n;
            [self markChildDirty:object];
        }
    }else if( context == gObserverText ){
        NSString* n = [change objectForKey:@"new"];
        NSString* o = [change objectForKey:@"old"];
        if([n compare:o options:NSLiteralSearch]!=NSOrderedSame){
            [self markChildDirty:object];
        }
    }else if( context == gObserverAttrText ){
        [self markChildDirty:object];
    }
}
-(void)markChildDirty:(UIView*)child
{
    [child.yoga markDirty];
    _bChildDirty = YES;
    [self setNeedsLayout];
}

#pragma mark - layout methods

-(void)configureLayout:(CGRect)safeArea
{
    [self configureLayoutWithBlock:^(YGLayout* layout){
        
        layout.left = YGPointValue(safeArea.origin.x) ;
        layout.top = YGPointValue(safeArea.origin.y);
        
        if(self.flexibleWidth)
            layout.width = YGPointValue(NAN);
        else
            layout.width = YGPointValue(safeArea.size.width) ;
        
        if(self.flexibleHeight)
            layout.height = YGPointValue(NAN);
        else
            layout.height = YGPointValue(safeArea.size.height) ;
        
        _thisConfigFrame = CGRectMake(layout.left.value, layout.top.value, layout.width.value, layout.height.value);
    }];
}

-(CGRect)getSafeArea
{
    CGRect rcSafeArea = self.superview.frame ;
    
    return UIEdgeInsetsInsetRect(rcSafeArea,self.safeArea);
}
-(BOOL)isConfigSame
{
    return memcmp(&_thisConfigFrame, &_lastConfigFrame, sizeof(CGRect))==0;
}

-(void)layoutSubviews
{
    if(_bInLayouting)
        return;
    
    [self configureLayout: [self getSafeArea]];
    BOOL configsame = [self isConfigSame];
    
    if(!_bChildDirty && configsame)
    {
        return;
    }
    
    //NSLog(@"Flexbox: FlexRootView layouting");

    _bInLayouting = YES;
    _lastConfigFrame = _thisConfigFrame;
    
    YGDimensionFlexibility option = 0 ;
    if(self.flexibleWidth)
        option |= YGDimensionFlexibilityFlexibleWidth ;
    if(self.flexibleHeight)
        option |= YGDimensionFlexibilityFlexibleHeigth ;
    
    CGRect rcOld = self.frame;
    
    if(self.beginLayout != nil)
        self.beginLayout();
    self.beginLayout = nil;
    
    // 布局前事件
    if(self.onWillLayout != nil){
        self.onWillLayout();
    }
    
    [self.yoga applyLayoutPreservingOrigin:NO dimensionFlexibility:option];
    
    // 布局后事件
    if(self.onDidLayout != nil){
        self.onDidLayout();
    }
    
    if(!CGRectEqualToRect(rcOld, self.frame)){
        [self.superview subFrameChanged:self Rect:self.frame];
    }
    
    if(self.endLayout !=nil)
        self.endLayout();
    self.endLayout = nil;
    
    _bInLayouting = NO ;
    _bChildDirty = NO;
}

-(CGSize)calculateSize:(CGSize)szLimit
{
    CGRect rc ;
    rc.origin = CGPointMake(0, 0);
    rc.size = szLimit;
    [self configureLayout:rc];
    
    if(self.flexibleWidth)
        szLimit.width = NAN ;
    if(self.flexibleHeight)
        szLimit.height = NAN ;
    
    CGSize sz=[self.yoga calculateLayoutWithSize:szLimit];
    return sz;
}
-(CGSize)calculateSize
{
    CGRect rc = self.superview.frame ;
    return [self calculateSize:rc.size];
}


-(void)layoutAnimation:(NSTimeInterval)duration
{
    self.beginLayout = ^{
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
    };
    
    self.endLayout = ^{
        [UIView commitAnimations];
    };
}

@end
